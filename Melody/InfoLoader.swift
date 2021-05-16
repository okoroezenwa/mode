//
//  InfoLoading.swift
//  Melody
//
//  Created by Ezenwa Okoro on 18/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

protocol InfoLoading: AnyObject {
    
    var operations: ImageOperations { get set }
    var infoOperations: InfoOperations { get set }
    var imageCache: ImageCache { get }
    var infoCache: InfoCache { get }
    var imageOperationQueue: OperationQueue { get }
}

/// Was to be used for supplementary info in recents cells
//protocol RecentsInfoLoading: InfoLoading {
//
//    var recentsOperations: ImageOperations { get set }
//}

protocol SupplementaryHeaderInfoLoading: InfoLoading, HeaderViewContaining {
    
    var applicableSupplementaryProperties: [SecondaryCategory] { get set }
    var supplementaryOperation: BlockOperation? { get set }
    var sortOperationQueue: OperationQueue { get }
}

extension SupplementaryHeaderInfoLoading {
    
    var collection: MPMediaItemCollection? {
        
        guard let vc = self as? UIViewController else { return nil }
        
        switch vc.location {
            
            case .collections(kind: let kind) where kind != .playlist:
            
                guard let vc = vc as? CollectionsViewController, let items = vc.collectionsQuery.items else { return nil }
            
                return .init(items: items)
                
            case .collections(kind: let kind) where kind == .playlist: return .init(items: [])
            
            case .songs:
            
                guard let vc = vc as? SongsViewController, let items = vc.songsQuery.items else { return nil }
                
                return .init(items: items)
            
            case .collection(kind: _, point: let startPoint):
            
                switch startPoint {
                    
                    case .songs:
                    
                        guard let vc = vc as? ArtistSongsViewController, let grouping = vc.entityVC?.kind.grouping else { return nil }
                        
                        return (vc.currentArtistQuery?.copy() as? MPMediaQuery)?.grouped(by: grouping).collections?.first
                    
                    case .albums:
                    
                        guard let vc = vc as? ArtistAlbumsViewController, let grouping = vc.entityVC?.kind.grouping else { return nil }
                        
                        return (vc.currentArtistQuery?.copy() as? MPMediaQuery)?.grouped(by: grouping).collections?.first
                }
            
            case .album: return (vc as? AlbumItemsViewController)?.album
            
            case .playlist: return (vc as? PlaylistItemsViewController)?.playlist
            
            default: return nil
        }
    }
    
    var collectionCount: Int? {
        
        guard let vc = self as? UIViewController else { return nil }
        
        switch vc.location {
        
            case .playlist:
                
                guard let vc = vc as? PlaylistItemsViewController else { return nil }
                
                return vc.playlistQuery?.items?.count
                
            default: return collection?.count
        }
    }
    
    @discardableResult func prepare(_ headerButtonType: HeaderButtonType, reload shouldReload: Bool, animateHeader isAnimated: Bool) -> Int? {
        
        guard let collection = collection, let vc = self as? UIViewController, let _ = vc.viewIfLoaded, let index = headerView.buttonDetails.firstIndex(where: { $0.type == headerButtonType }) else { return nil }
        
        let details = headerView.buttonDetails[index]
        
        switch headerButtonType {
            
            case .affinity: headerView.buttonDetails[index] = (details.type, SecondaryCategory.loved.propertyImage(from: collection, context: .header), nil, details.action)
            
            case .grouping:
                
                headerView.buttonDetails[index] = (details.type, details.image, {
                
                    switch vc.location {
                    
                        case .playlist: return collectionCount?.fullCountText(for: .song, capitalised: false)
                        
                        case .album, .collection(kind: _, point: .songs): return collection.count.fullCountText(for: .song, capitalised: false)
                        
                        case .collection(kind: _, point: .albums): return (vc as? ArtistAlbumsViewController)?.currentArtistQuery?.collections?.count.fullCountText(for: .album, capitalised: false)
                        
                        case .collections(kind: .playlist): return (vc as? CollectionsViewController)?.playlistsViewText
                        
                        default: return nil
                    }
                    
                }(), details.action)
            
            case .sort: headerView.buttonDetails[index] = (details.type, details.image, (vc as? Arrangeable)?.arrangementLabelText, details.action)
                
//            case .share: headerView.buttonDetails[index] = (details.type, details.image, "Share", details.action)
            
            case .artist, .info, .insert, .newPlaylist, .share: return nil
        }
        
        if shouldReload {
        
            headerView.supplementaryCollectionView.performBatchUpdates({ [weak self] in self?.headerView.supplementaryCollectionView.reloadItems(at: [.init(row: index, section: 0)]) }, completion: nil)
        }
        
        if isAnimated {
            
            UIView.animate(withDuration: 0.3, animations: { self.headerView.layoutIfNeeded() })
        }
        
        return index
    }
    
    func prepareSupplementaryInfo(animated: Bool = true) {
        
        guard let collection = collection, collection.items.isEmpty.inverted, let vc = self as? UIViewController, let _ = vc.viewIfLoaded else { return }
        
        let array = [HeaderButtonType.grouping, .affinity].reduce([IndexPath](), {
            
            guard let index = prepare($1, reload: false, animateHeader: false) else { return $0 }
            
            return $0.appending(.init(row: index, section: 0))
        })
        
        if animated {
            
            UIView.animate(withDuration: 0.3, animations: { self.headerView.layoutIfNeeded() })
            
            headerView.supplementaryCollectionView.performBatchUpdates({ [weak self] in self?.headerView.supplementaryCollectionView.reloadItems(at: array) }, completion: nil)
        
        } else {
            
            headerView.supplementaryCollectionView.reloadItems(at: array)
        }
        
        supplementaryOperation?.cancel()
        supplementaryOperation = BlockOperation()
        supplementaryOperation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self else { return }
            
            let array = weakSelf.applicableSupplementaryProperties.reduce([HeaderPropertyDetails](), {
                
                guard let string = $1.propertyString(from: collection, context: .header, vc: self) else { return $0 }
                
                return $0.appending((string, $1))
            })
            
            guard weakSelf.supplementaryOperation?.isCancelled == false else { return }
            
            OperationQueue.main.addOperation({
                
                weakSelf.headerView.propertyDetails = array
                weakSelf.headerView.supplementaryCollectionView.reloadSections(.init(integer: 1))
            })
        })
        
        sortOperationQueue.addOperation(supplementaryOperation!)
    }
}

extension InfoLoading {
    
    func updateInfoArtwork(with entity: MPMediaEntity?) {
        
        guard let infoVC = self as? InfoViewController else { return }
        
        let operation = BlockOperation()
        operation.addExecutionBlock({
            
            let item: MPMediaItem? = {
                
                if let item = entity as? MPMediaItem {
                    
                    return item
                    
                } else if let collection = entity as? MPMediaItemCollection {
                    
                    return collection.artworkItem
                }
                
                return nil
            }()
            
            if let image = (entity as? MPMediaItemCollection)?.customArtwork(for: infoVC.context.entityType)?.scaled(to: infoVC.artworkImageView.bounds.size, by: 2) ?? item?.actualArtwork?.image(at: infoVC.artworkImageView.bounds.size) {
                
                OperationQueue.main.addOperation({
                    
                    infoVC.artworkImageView.artworkType = .image(image)
                })
            
            } else {
                
                OperationQueue.main.addOperation({
                    
                    infoVC.artworkImageView.artworkType = .empty(entityType: entity?.granularEntityType(basedOn: infoVC.context.entityType) ?? .song, size: .large)
                })
            }
        })
        
        operation.start()
    }
    
    func updateImageView(using song: MPMediaItem, in cell: ArtworkContainingCell, indexPath: IndexPath, reusableView: AnyObject) {
        
        if let image = imageCache.object(forKey: "\(song.persistentID)" as NSString) {
            
            cell.artworkImageView.artworkType = .image(image)
            
        } else {
            
            let size = cell.artworkImageView.frame.size
            
            let operation = BlockOperation()
            operation.addExecutionBlock({ [weak song, weak operation, weak imageCache] in
                
                if let artwork = song?.actualArtwork, let image = artwork.image(at: size) {
                    
                    guard operation?.isCancelled == false, let song = song else { return }
                    
                    imageCache?.setObject(image, forKey: "\(song.persistentID)" as NSString)
                    
                    OperationQueue.main.addOperation({ [weak reusableView, weak operation, weak image] in
                        
                        if let cell: ArtworkContainingCell = {
                            
                            if let tableView = reusableView as? UITableView {
                                
                                return tableView.cellForRow(at: indexPath) as? ArtworkContainingCell
                                
                            } else if let collectionView = reusableView as? UICollectionView {
                                
                                return collectionView.cellForItem(at: indexPath) as? ArtworkContainingCell
                            }
                            
                            return nil
                            
                        }(), operation?.isCancelled == false {
                            
                            cell.artworkImageView.artworkType = .image(image)
                        }
                    })
                }
            })
            
            operations[indexPath] = operation
            imageOperationQueue.addOperation(operation)
        }
    }
    
    func updateImageView(using collection: MPMediaItemCollection, entityType type: EntityType, in cell: ArtworkContainingCell, indexPath: IndexPath, reusableView: AnyObject, overridable: OnlineOverridable? = nil) {
        
        let bool: Bool = {
            
            guard let overridable = overridable else { return showiCloudItems }
            
            return showiCloudItems || overridable.onlineOverride
        }()
        
        guard let persistentID: MPMediaEntityPersistentID = {
            
            if collection.customArtwork(for: type) != nil {
                
                return collection.persistentID
                
            } else {
                
                if bool {
                    
                    return collection.representativeItem?.persistentID
                    
                } else {
                    
                    return collection.items.first(where: { !$0.isCloudItem && $0.actualArtwork != nil })?.persistentID
                }
            }
        
            }() else { return }
        
        let item: MPMediaItem? = {

            if bool {

                return collection.representativeItem

            } else {

                return collection.items.first(where: { !$0.isCloudItem && $0.actualArtwork != nil })
            }
        }()
        
        let width = cell.artworkImageView.bounds.width
        let size = CGSize(width: width, height: width)
        
        if let image = imageCache.object(forKey: "\(persistentID)" as NSString) {
            
            cell.artworkImageView.artworkType = .image(image)
            
        } else {
            
            let operation = BlockOperation()
            operation.addExecutionBlock({ [weak item, weak operation, weak imageCache] in
                
                if bool {
                    
                    if let image = collection.customArtwork(for: type)?.scaled(to: size, by: 2) ?? item?.actualArtwork?.image(at: size) {
                        
                        guard operation?.isCancelled == false else { return }
                        
                        imageCache?.setObject(image, forKey: "\(persistentID)" as NSString)
                        
                        OperationQueue.main.addOperation({ [weak reusableView, weak operation, weak image] in
                            
                            guard let cell: ArtworkContainingCell = {
                                
                                if let tableView = reusableView as? UITableView {
                                    
                                    return tableView.cellForRow(at: indexPath) as? ArtworkContainingCell
                                    
                                } else if let collectionView = reusableView as? UICollectionView {
                                    
                                    return collectionView.cellForItem(at: indexPath) as? ArtworkContainingCell
                                }
                                
                                return nil
                                
                            }(), operation?.isCancelled == false else { return }
                            
                            cell.artworkImageView.artworkType = .image(image)
                        })
                    }
                    
                } else {
                    
                    if let image = collection.customArtwork(for: type)?.scaled(to: size, by: 2) ?? item?.actualArtwork?.image(at: size) {
                        
                        guard operation?.isCancelled == false else { return }
                        
                        imageCache?.setObject(image, forKey: "\(persistentID)" as NSString)
                        
                        OperationQueue.main.addOperation({ [weak reusableView, weak operation, weak image] in
                            
                            guard let cell: ArtworkContainingCell = {
                                
                                if let tableView = reusableView as? UITableView {
                                    
                                    return tableView.cellForRow(at: indexPath) as? ArtworkContainingCell
                                    
                                } else if let collectionView = reusableView as? UICollectionView {
                                    
                                    return collectionView.cellForItem(at: indexPath) as? ArtworkContainingCell
                                }
                                
                                return nil
                                
                            }(), operation?.isCancelled == false else { return }
                            
                            cell.artworkImageView.artworkType = .image(image)
                        })
                    }
                }
            })
            
            operations[indexPath] = operation
            imageOperationQueue.addOperation(operation)
        }
    }
    
    func updateInfo(for entity: MPMediaEntity, ofType type: EntityType, in cell: EntityTableViewCell, at indexPath: IndexPath, within tableView: UITableView) {
        
        let operation = BlockOperation()
        operation.addExecutionBlock({ [weak entity, weak operation] in
            
            let array = type.secondaryCategories
            let dictionary = array.reduce(PropertyDictionary(), { dict, property -> PropertyDictionary in
                
                var dictionary = dict
                
                guard let entity = entity, let string: String = property.propertyString(from: entity, context: .cell, vc: self), let image: UIImage = property.propertyImage(from: entity, context: .cell) else { return dict }
                
                dictionary[property] = (image: image, text: string)
                
                return dictionary
            })
            
            OperationQueue.main.addOperation {
                
                if let cell = tableView.cellForRow(at: indexPath) as? EntityTableViewCell, operation?.isCancelled == false {
                    
                    cell.properties = dictionary
                    cell.supplementaryCollectionView.reloadData()
                }
            }
        })
        
        infoOperations[.init(id: entity.persistentID, index: indexPath.item)] = operation
        imageOperationQueue.addOperation(operation)
    }
}

class InfoKey: NSObject {
    
    var index: Int
    var id: MPMediaEntityPersistentID
    
    init(id: MPMediaEntityPersistentID, index: Int) {
        
        self.index = index
        self.id = id
        
        super.init()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        
        guard let object = object as? InfoKey else { return false }
        
        return id == object.id && index == object.index
    }
    
//    override func hash(into hasher: inout Hasher) {
//
//        hasher.combine(index)
//        hasher.combine(id)
//    }
    
    override var hash: Int { return index.hashValue ^ id.hashValue }
}
