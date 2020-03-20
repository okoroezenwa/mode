//
//  LastUsedViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 08/01/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

enum CellSelectionType { case select, deselect }

enum PlaylistModificationLocation { case main, filter, header, history }

enum PlaylistOperation { case get, insert, remove, reset }

typealias PlaylistHistoryDetails = (ids: [MPMediaEntityPersistentID], operation: PlaylistOperation)

class LastUsedController: NSObject, InfoLoading {
    
    weak var collectionsVC: CollectionsViewController?

    lazy var playlists = playlistHistoryDetails.ids.compactMap({ MPMediaQuery.init(filterPredicates: [.for(.playlist, using: $0)]).grouped(by: .playlist).collections?.first as? MPMediaPlaylist })
    @objc var operations = ImageOperations()
    @objc var infoOperations = InfoOperations()
    @objc let imageOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Image Operation Queue"
        
        return queue
    }()
    @objc let imageCache: ImageCache = {
        
        let cache = ImageCache()
        cache.name = "Image Cache"
        cache.countLimit = 500
        
        return cache
    }()
    @objc let infoCache: InfoCache = {
        
        let cache = InfoCache()
        cache.name = "Info Cache"
        cache.countLimit = 2500
        
        return cache
    }()
    
    init(with vc: CollectionsViewController) {
        
        vc.lastUsedCollectionView.allowsMultipleSelection = true
        vc.lastUsedCollectionView.register(.init(nibName: "SmallPlaylistCollectionCell", bundle: nil), forCellWithReuseIdentifier: "playlistCell")
        
        self.collectionsVC = vc
        
        super.init()
        
        vc.lastUsedCollectionView.delegate = self
        vc.lastUsedCollectionView.dataSource = self
        
        if #available(iOS 10, *) {
            
            vc.lastUsedCollectionView.prefetchDataSource = self
        }
        
        notifier.addObserver(self, selector: #selector(updateCell(_:)), name: .playlistSelected, object: nil)
    }
    
    @objc func updateCell(_ sender: Notification) {
        
        guard let location = sender.userInfo?["location"] as? PlaylistModificationLocation, location != .history, let collectionsVC = collectionsVC, let type = sender.userInfo?["type"] as? CellSelectionType, let playlist = sender.userInfo?["playlist"] as? MPMediaPlaylist else { return }
        
        switch type {
            
            case .select:
            
                if let selectedIndexPath = collectionsVC.lastUsedCollectionView.indexPathsForVisibleItems.first(where: { playlists.value(at: $0.row) == playlist }), let cell = collectionsVC.lastUsedCollectionView.cellForItem(at: selectedIndexPath), cell.isSelected.inverted {
                    
                    collectionsVC.lastUsedCollectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: [])
                }
            
            case .deselect:
            
                if let selectedIndexPath = collectionsVC.lastUsedCollectionView.indexPathsForVisibleItems.first(where: { playlists.value(at: $0.row) == playlist }), let indexPaths = collectionsVC.lastUsedCollectionView.indexPathsForSelectedItems, Set(indexPaths).contains(selectedIndexPath) {
                    
                    collectionsVC.lastUsedCollectionView.deselectItem(at: selectedIndexPath, animated: false)
                }
        }
    }
}

extension LastUsedController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return playlists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "playlistCell", for: indexPath) as! SmallPlaylistCollectionViewCell
        
        let playlist = playlists[indexPath.item]
        
        if let collectionsVC = collectionsVC {
        
            if Set(collectionsVC.selectedPlaylists).contains(playlist), cell.isSelected.inverted {
                
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                
            } else if Set(collectionsVC.selectedPlaylists).contains(playlist).inverted, cell.isSelected {
                
                collectionView.deselectItem(at: indexPath, animated: false)
            }
        }
        
        cell.topConstraint = 6
        cell.bottomConstraint = 0
        cell.prepare(with: playlist, shouldHideChevron: true)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        guard let cell = cell as? SmallPlaylistCollectionViewCell else { return }
        
        let playlist = playlists[indexPath.item]
        
        if let collectionsVC = collectionsVC, collectionsVC.presented {
            
            if Set(collectionsVC.selectedPlaylists).contains(playlist), cell.isSelected.inverted {
                
                cell.isSelected = true
                
            } else if Set(collectionsVC.selectedPlaylists).contains(playlist).inverted, cell.isSelected {
                
                cell.isSelected = false
            }
        }

        updateImageView(using: playlist, entityType: .playlist, in: cell, indexPath: indexPath, reusableView: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        operations[indexPath]?.cancel()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let collectionsVC = collectionsVC else { return }
        
        let playlist = playlists[indexPath.item]
        
        if collectionsVC.selectedPlaylists.firstIndex(of: playlist) == nil/*, let _ = collectionsVC.libraryVC?.parent as? PresentedContainerViewController*/ {
            
            collectionsVC.selectedPlaylists.append(playlist)
            collectionsVC.addButton.setTitle("Add (\(collectionsVC.selectedPlaylists.count.formatted))", for: .normal)
            
            notifier.post(name: .playlistSelected, object: nil, userInfo: ["playlist": playlist, "type": CellSelectionType.select, "location": PlaylistModificationLocation.history])
            
//            if let selectedIndexPath = collectionsVC.tableView.indexPathsForVisibleRows?.first(where: { collectionsVC.getCollection(from: $0) == playlist }), let cell = collectionsVC.tableView.cellForRow(at: selectedIndexPath), cell.isSelected.inverted {
//
//                collectionsVC.tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
//            }
//
//            if let selectedIndexPath = collectionsVC.collectionView?.indexPathsForVisibleItems.first(where: { collectionsVC.headerView.playlists.value(at: $0.row) == playlist }), let cell = collectionsVC.collectionView?.cellForItem(at: selectedIndexPath), cell.isSelected.inverted {
//
//                collectionsVC.collectionView?.selectItem(at: selectedIndexPath, animated: false, scrollPosition: [])
//            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        guard let collectionsVC = collectionsVC else { return }
        
        if let playlist = playlists.value(at: indexPath.row), let index = collectionsVC.selectedPlaylists.firstIndex(of: playlist)/*, let _ = collectionsVC.libraryVC?.parent as? PresentedContainerViewController*/ {
            
            collectionsVC.selectedPlaylists.remove(at: index)
            collectionsVC.addButton.setTitle("Add (\(collectionsVC.selectedPlaylists.count.formatted))", for: .normal)
            
            notifier.post(name: .playlistSelected, object: nil, userInfo: ["playlist": playlist, "type": CellSelectionType.deselect, "location": PlaylistModificationLocation.history])
            
//            if let selectedIndexPath = collectionsVC.tableView.indexPathsForVisibleRows?.first(where: { collectionsVC.getCollection(from: $0) == playlist }), let indexPaths = collectionsVC.tableView.indexPathsForSelectedRows, Set(indexPaths).contains(selectedIndexPath) {
//
//                collectionsVC.tableView.deselectRow(at: selectedIndexPath, animated: false)
//            }
//
//            if let selectedIndexPath = collectionsVC.collectionView?.indexPathsForVisibleItems.first(where: { collectionsVC.headerView.playlists.value(at: $0.row) == playlist }), let indexPaths = collectionsVC.collectionView?.indexPathsForSelectedItems, Set(indexPaths).contains(selectedIndexPath) {
//
//                collectionsVC.collectionView?.deselectItem(at: selectedIndexPath, animated: false)
//            }
        }
    }
}

extension LastUsedController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        .init(width: (screenWidth - 12 - 22 - 9 - 4 - 5) / 2.25, height: 48 - 0.00001)
    }
}

@available(iOS 10, *)
extension LastUsedController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        
        indexPaths.forEach({
            
            guard let cell = collectionView.cellForItem(at: $0) as? SmallPlaylistCollectionViewCell else { return }
            
            updateImageView(using: playlists[$0.item], entityType: .playlist, in: cell, indexPath: $0, reusableView: collectionView)
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        
        indexPaths.forEach({ operations[$0]?.cancel() })
    }
}
