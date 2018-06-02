//
//  InfoLoading.swift
//  Melody
//
//  Created by Ezenwa Okoro on 18/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

protocol InfoLoading: class {
    
    var operations: ImageOperations { get set }
    var infoOperations: InfoOperations { get set }
    var imageCache: ImageCache { get }
    var infoCache: InfoCache { get }
    var imageOperationQueue: OperationQueue { get }
}

protocol RecentsInfoLoading: InfoLoading {
    
    var recentsOperations: ImageOperations { get set }
}

extension InfoLoading {
    
    func updateInfoArtwork(with entity: Any?) {
        
        guard let infoVC = self as? InfoViewController else { return }
        
        let operation = BlockOperation()
        operation.addExecutionBlock({
            
            let item: MPMediaItem? = {
                
                if let item = entity as? MPMediaItem {
                    
                    return item
                    
                } else if let collection = entity as? MPMediaItemCollection {
                    
                    if showiCloudItems {
                        
                        return collection.representativeItem
                        
                    } else {
                        
                        return collection.items.first(where: { !$0.isCloudItem && $0.artwork?.bounds.width != 0 })
                    }
                }
                
                return nil
            }()
            
            if let image = (entity as? MPMediaItemCollection)?.customArtwork?.scaled(to: infoVC.artworkImageView.bounds.size, by: 2) ?? item?.actualArtwork?.image(at: infoVC.artworkImageView.bounds.size) {
                
                OperationQueue.main.addOperation({
                    
                    infoVC.artworkImageView.image = image
                })
            
            } else {
                
                OperationQueue.main.addOperation({
                    
                    infoVC.artworkImageView.image = {
                        
                        switch infoVC.context {
                            
                            case .album(let index, let albums): return albums[index].representativeItem?.isCompilation == true ? #imageLiteral(resourceName: "NoCompilation300") : #imageLiteral(resourceName: "NoAlbum300")
                            
                            case .collection(kind: let kind, _, _):
                            
                                switch kind {
                                    
                                    case .albumArtist, .artist: return #imageLiteral(resourceName: "NoArtist300")
                                    
                                    case .composer: return #imageLiteral(resourceName: "NoComposer300")
                                    
                                    case .genre: return #imageLiteral(resourceName: "NoGenre300")
                                }
                            
                            case .song: return #imageLiteral(resourceName: "NoSong300")
                            
                            case .playlist(at: let index, within: let playlists):
                            
                                if playlists[index].playlistAttributes == .smart {
                                    
                                    return #imageLiteral(resourceName: "NoSmart300")
                                    
                                } else if playlists[index].playlistAttributes == .genius {
                                    
                                    return #imageLiteral(resourceName: "NoGenius300")
                                
                                } else {
                                    
                                    return #imageLiteral(resourceName: "NoPlaylist300")
                                }
                        }
                    }()
                })
            }
        })
        
        operation.start()
    }
    
    func updateImageView(using song: MPMediaItem, in cell: ArtworkContainingCell, indexPath: IndexPath, reusableView: AnyObject) {
        
        if let image = imageCache.object(forKey: "\(song.persistentID)" as NSString) {
            
            cell.artworkImageView.image = image
            
        } else {
            
            let size = cell.artworkImageView.frame.size
            
            let operation = BlockOperation()
            operation.addExecutionBlock({ [weak song, weak operation, weak imageCache] in
                
                if let artwork = song?.artwork, artwork.bounds.width != 0, let image = artwork.image(at: size) {
                    
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
                            
                            cell.artworkImageView.image = image
                        }
                    })
                }
            })
            
            operations[indexPath] = operation
            imageOperationQueue.addOperation(operation)
        }
    }
    
    func updateImageView(using collection: MPMediaItemCollection, in cell: ArtworkContainingCell, indexPath: IndexPath, reusableView: AnyObject, overridable: OnlineOverridable? = nil) {
        
        let bool: Bool = {
            
            guard let overridable = overridable else { return showiCloudItems }
            
            return showiCloudItems || overridable.onlineOverride
        }()
        
        guard let persistentID: MPMediaEntityPersistentID = {
            
            if collection.customArtwork != nil {
                
                return collection.persistentID
                
            } else {
                
                if bool {
                    
                    return collection.representativeItem?.persistentID
                    
                } else {
                    
                    return collection.items.first(where: { !$0.isCloudItem && $0.artwork?.bounds.width != 0 })?.persistentID
                }
            }
        
            }() else { return }
        
        let item: MPMediaItem? = {

            if bool {

                return collection.representativeItem

            } else {

                return collection.items.first(where: { !$0.isCloudItem && $0.artwork?.bounds.width != 0 })
            }
        }()
        
        let width = cell.artworkImageView.bounds.width
        let size = CGSize(width: width, height: width)
        
        if let image = imageCache.object(forKey: "\(persistentID)" as NSString) {
            
            cell.artworkImageView.image = image
            
        } else {
            
            let operation = BlockOperation()
            operation.addExecutionBlock({ [weak item, weak operation, weak imageCache] in
                
                if bool {
                    
                    if let image = collection.customArtwork?.scaled(to: size, by: 2) ?? item?.actualArtwork?.image(at: size) {
                        
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
                            
                            cell.artworkImageView.image = image
                        })
                    }
                    
                } else {
                    
                    if let image = collection.customArtwork?.scaled(to: size, by: 2) ?? item?.actualArtwork?.image(at: size) {
                        
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
                            
                            cell.artworkImageView.image = image
                        })
                    }
                }
            })
            
            operations[indexPath] = operation
            imageOperationQueue.addOperation(operation)
        }
    }
    
    func update(category: SecondaryCategory, using song: MPMediaItem, in cell: SongTableViewCell, at indexPath: IndexPath, reusableView: Any) {
        
        let view = cell.view(for: category)
        
        guard let array = songSecondaryDetails, Set(array).contains(category) else {
            
            view.isHidden = true
            return
        }
        
        view.isHidden = false
        
        if let string = infoCache.object(forKey: .init(id: song.persistentID, index: category.rawValue)) as String? {
            
            view.label.text = {
                
                switch category {
                    
                    case .loved: return nil
                    
                    case .rating: return string.components(separatedBy: ".").value(at: 1)
                    
                    default: return string
                }
            }()
            
            if category == .loved {
                
                view.imageView.image = UIImage.init(imageLiteralResourceName: string)
            
            } else if category == .rating {
                
                view.imageView.image = UIImage.init(imageLiteralResourceName: string.components(separatedBy: ".").first ?? "")
            }
            
        } else {
            
            let operation = BlockOperation()
            operation.addExecutionBlock({ [weak song, weak operation/*, weak infoCache*/] in
                
                if let song = song, let string: String = {
                    
                    switch category {
                        
                        case .plays: return song.playCount.formatted
                        
                        case .fileSize:
                        
                            let sizer = FileSize.init(actualSize: song.fileSize)
                            
                            return String(sizer.size) + sizer.suffix
                        
                        case .dateAdded: return song.existsInLibrary ? song.validDateAdded.timeIntervalSinceNow.shortStringRepresentation : "Not in Library"
                        
                        case .genre: return song.validGenre
                        
                        case .lastPlayed: return song.lastPlayedDate?.timeIntervalSinceNow.shortStringRepresentation
                        
                        case .loved:
                            
                            switch song.likedState {
                                
                                case .disliked: return "Unloved"
                                
                                case .liked: return "Loved"
                                
                                case .none: return "NoLove"
                            }
                        
                        case .rating:
                            
                            switch song.rating {
                                
                                case 0: return "Star" + "." + song.rating.formatted
                                
                                default: return "StarFilled" + "." + song.rating.formatted
                            }
                    
                        case .year: return song.year == 0 ? nil : String(song.year)
                    }
                    
                }(), !string.isEmpty {
                    
                    guard operation?.isCancelled == false else { return }
                    
//                    infoCache?.setObject(string as NSString, forKey: .init(id: song.persistentID, index: category.rawValue))
                    
                    OperationQueue.main.addOperation {
                        
                        if let cell = (reusableView as? UITableView)?.cellForRow(at: indexPath) as? SongTableViewCell, operation?.isCancelled == false {
                            
                            if category == .rating {
                                
                                cell.view(for: category).label.text = string.components(separatedBy: ".").value(at: 1)
                                cell.view(for: category).imageView.image = UIImage.init(imageLiteralResourceName: string.components(separatedBy: ".").first ?? "")
                            
                            } else if category != .loved {
                                
                                cell.view(for: category).label.text = string
                            
                            } else {
                                
                                cell.view(for: category).label.text = nil
                                cell.view(for: category).imageView.image = UIImage.init(imageLiteralResourceName: string)
                            }
                        }
                    }
                    
                } else {
                    
                    OperationQueue.main.addOperation {
                        
                        if let cell = (reusableView as? UITableView)?.cellForRow(at: indexPath) as? SongTableViewCell, operation?.isCancelled == false {
                            
                            cell.view(for: category).isHidden = true
                        }
                    }
                }
            })
            
            infoOperations[.init(id: song.persistentID, index: category.rawValue)] = operation
            imageOperationQueue.addOperation(operation)
        }
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
    
    override var hash: Int { return index.hashValue ^ id.hashValue }
}
