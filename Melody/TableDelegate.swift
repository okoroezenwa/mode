//
//  TableViewDelegate.swift
//  Melody
//
//  Created by Ezenwa Okoro on 30/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class TableDelegate: NSObject, Detailing {

    enum Location { case playlist, album, artistSongs(withinArtist: Bool), artistAlbums(withinArtist: Bool), collections(kind: CollectionsKind), songs }
    enum QuerySectionsType { case none, items, collections }
    
    let location: Location
    weak var container: TableViewContainer?
    
    lazy var playlistContainers = [PlaylistContainer]()
    lazy var collapsedPlaylistChildren = [Int64: [PlaylistContainer]]()
    
    var querySectionsType: QuerySectionsType {
        
        switch location {
            
            case .playlist, .album: return .none
            
            case .artistSongs, .songs: return .items
            
            case .artistAlbums: return .collections
            
            case .collections(kind: let kind):
            
                guard kind != .playlist else { return .none }
            
                return .collections
        }
    }
    
    init(container: TableViewContainer, location: Location) {
        
        self.container = container
        self.location = location
        
        super.init()
        
        if #available(iOS 10, *) {
            
            container.tableView.prefetchDataSource = self
        }
        
        notifier.addObserver(self, selector: #selector(updateEntityCountVisibility), name: .entityCountVisibilityChanged, object: nil)
        notifier.addObserver(self, selector: #selector(updateNumbersBelowLetters), name: .numbersBelowLettersChanged, object: nil)
        
        switch location {
            
            case .album, .playlist, .songs, .artistSongs: [Notification.Name.likedStateChanged, .ratingChanged].forEach({ notifier.addObserver(self, selector: #selector(updateRatingIfNeeded(_:)), name: $0, object: nil) })
            
            case .artistAlbums(withinArtist: _): notifier.addObserver(self, selector: #selector(updateRatingIfNeeded(_:)), name: .likedStateChanged, object: nil)
            
            case .collections(kind: .playlist): notifier.addObserver(self, selector: #selector(updateRatingIfNeeded(_:)), name: .likedStateChanged, object: nil)
            
            case .collections(kind: .album): notifier.addObserver(self, selector: #selector(updateRatingIfNeeded(_:)), name: .likedStateChanged, object: nil)
            
            default: break
        }
    }
    
    @objc func updateRatingIfNeeded(_ notification: Notification) {
        
        guard let id = notification.userInfo?[String.id] as? MPMediaEntityPersistentID, let indexPath = container?.tableView.indexPathsForVisibleRows?.first(where: { container?.getEntity(at: $0, filtering: container?.filterContainer != nil).persistentID == id }) else { return }
        
        UniversalMethods.performOnMainThread({ self.container?.tableView.reloadRows(at: [indexPath], with: .none) }, afterDelay: 0.3)
    }
    
    @objc func updateEntityCountVisibility() {
        
        guard let indexPaths = container?.tableView.indexPathsForVisibleRows else { return }
        
        container?.tableView.reloadRows(at: indexPaths, with: .none)
    }
    
    @objc func updateNumbersBelowLetters() {
        
        guard let container = container, container.alphaNumericCritieria.contains(container.sortCriteria) else { return }
        
        container.sortItems()
    }
    
    @objc func items(at indexPath: IndexPath, filtering: Bool = false) -> [MPMediaItem] {
        
        switch location {
            
            case .album, .playlist, .songs, .artistSongs: return [container?.getEntity(at: indexPath, filtering: filtering) as! MPMediaItem]
            
            case .artistAlbums, .collections: return (container?.getEntity(at: indexPath, filtering: filtering) as! MPMediaItemCollection).items
        }
    }
    
    @objc func query(at indexPath: IndexPath, filtering: Bool = false) -> MPMediaQuery {
        
        switch location {
            
            case .album, .playlist, .songs, .artistSongs: return MPMediaQuery.init(filterPredicates: [.for(.song, using: container!.getEntity(at: indexPath, filtering: filtering).persistentID)])
            
            case .artistAlbums: return MPMediaQuery.init(filterPredicates: [.for(.album, using: container!.getEntity(at: indexPath, filtering: filtering).persistentID)])
            
            case .collections(let kind): return MPMediaQuery.init(filterPredicates: [.for(kind.entity, using: container!.getEntity(at: indexPath, filtering: filtering).persistentID)])
        }
    }
    
    func entityType() -> Entity {
        
        switch location {
            
            case .album, .playlist, .songs, .artistSongs: return .song
            
            case .artistAlbums: return .album
            
            case .collections(let kind): return kind.entity
        }
    }
    
    @objc func collectFromSection(_ sender: UIButton) {
        
        guard let container = container else { return }
        
        let items = Array(0..<container.tableView.numberOfRows(inSection: sender.tag)).map({ self.items(at: .init(row: $0, section: sender.tag)) }).reduce([], +)

        notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: items])
    }
    
    @objc func viewSections() {
        
        guard let container = container, let vc = container as? UIViewController, let sectionVC = popoverStoryboard.instantiateViewController(withIdentifier: String.init(describing: SectionIndexViewController.self)) as? SectionIndexViewController, let containing = container as? (IndexContaining & UIViewController), let sections = self.sectionIndexTitles(for: container.tableView), !sections.isEmpty else { return }

        sectionVC.array = [.view] + sections.map({ $0 == "." ? .dot : SectionIndexViewController.IndexKind.text($0) })
        sectionVC.container = containing
        containing.sectionIndexViewController = sectionVC
        
        vc.present(sectionVC, animated: true, completion: nil)
    }
    
    func goToDetails(basedOn entity: Entity = .song) -> (entities: [Entity], albumArtOverride: Bool) {
        
        switch location {
            
            case .songs, .playlist, .artistSongs(withinArtist: false): return ([.artist, .genre, .album, .composer, .albumArtist], true)
    
            case .album: return ([albumArtistsAvailable ? .albumArtist : .artist, .genre, .composer], false)
    
            case .artistSongs(withinArtist: true): return ([.genre, .album, .composer], false)
    
            case .artistAlbums(withinArtist: false): return ([albumArtistsAvailable ? .albumArtist : .artist, .genre, .album], false)
    
            case .artistAlbums(withinArtist: true): return ([.genre, .album], false)
    
            case .collections(kind: let kind):
                
                switch kind {
                    
                    case .album, .compilation: return ([albumArtistsAvailable ? .albumArtist : .artist, .genre, .album], false)
                    
                    case .artist: return ([.artist], false)
                    
                    case .albumArtist: return ([.albumArtist], false)
                    
                    case .composer: return ([.composer], false)
                    
                    case .genre: return ([.genre], false)
                    
                    case .playlist: return ([.playlist], false)
                }
        }
    }
    
    func getActionDetails(from action: SongAction, indexPath: IndexPath, vc: UIViewController?, useAlternateTitle alternateTitle: Bool = false) -> ActionDetails? {
        
        guard let container = container, let vc = vc else { return nil }
        
        return container.singleItemActionDetails(for: action, entity: entityType(), using: container.getEntity(at: indexPath, filtering: container.filterContainer != nil), from: vc, useAlternateTitle: alternateTitle)
    }
}

extension TableDelegate: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return numberOfSections(in: tableView, filtering: false)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.tableView(tableView, numberOfRowsInSection: section, filtering: false)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        return self.tableView(tableView, cellForRowAt: indexPath, filtering: false)
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        self.tableView(tableView, didEndDisplaying: cell, forRowAt: indexPath, filtering: false)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.tableView(tableView, didSelectRowAt: indexPath, filtering: false)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        self.tableView(tableView, didDeselectRowAt: indexPath, filtering: false)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return self.tableView(tableView, heightForRowAt: indexPath, filtering: false)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return self.tableView(tableView, heightForHeaderInSection: section, filtering: false)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        return self.tableView(tableView, viewForHeaderInSection: section, filtering: false)
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        return sectionIndexTitles(for: tableView, filtering: false)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        return .insert
    }
    
//    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
//        
//        return false
//    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        self.tableView(tableView, commit: editingStyle, forRowAt: indexPath, filtering: false)
    }
    
    @objc func showOptions(_ sender: Any) {
        
        guard let vc = container?.filterContainer ?? container as? UIViewController else { return }
        
        var indexPath: IndexPath?
        var fromCollectionView = false
        
        if let sender = sender as? UIGestureRecognizer {
            
            guard sender.state == .began else { return }
            
            indexPath = {
                
                if let collectionView = container?.collectionView, let tableView = container?.tableView, let header = tableView.tableHeaderView, header.frame.contains(sender.location(in: tableView)), let indexPath = collectionView.indexPathForItem(at: collectionView.convert(header.convert(sender.location(in: tableView), from: tableView), from: header)) {
                    
                    fromCollectionView = true
                    
                    return indexPath
                }
                
                return container?.tableView.indexPathForRow(at: sender.location(in: container?.tableView))
            }()
            
        } else if let cell = sender as? UITableViewCell {
            
            indexPath = container?.filterContainer?.tableView.indexPath(for: cell) ?? container?.tableView.indexPath(for: cell)
        
        } else if let cell = sender as? UICollectionViewCell {
            
            indexPath = container?.collectionView?.indexPath(for: cell)
        }
        
        if let indexPath = indexPath {
            
            Transitioner.shared.showInfo(from: vc, with: infoContext(from: indexPath, collectionViewOverride: fromCollectionView, filtering: container?.filterContainer != nil))
            
            container?.filterContainer?.saveRecentSearch(withTitle: container?.filterContainer?.searchBar?.text, resignFirstResponder: false)
        }
    }
    
    func getIndex(from indexPath: IndexPath, filtering: Bool) -> Int {
        
        switch container!.sortCriteria {
            
            case .random: return indexPath.row
            
            case .standard:
            
//                if let vc = container as? ArtistSongsViewController, let entityVC = vc.entityVC, Set([AlbumBasedCollectionKind.artist, .albumArtist]).contains(entityVC.kind) {
//
//                    return container!.sections[indexPath.section].startingPoint + indexPath.row
//                }
                
                switch querySectionsType {
                    
                    case .collections:
                        
                        if !container!.entities.isEmpty, let collectionSections = container?.query?.collectionSections {
                            
                            return collectionSections[indexPath.section].range.location + indexPath.row
                            
                        } else {
                            
                            return indexPath.row
                        }
                    
                    case .items:
                        
                        if !container!.entities.isEmpty, let itemSections = container?.query?.itemSections {
                            
                            return itemSections[indexPath.section].range.location + indexPath.row
                            
                        } else {
                            
                            return indexPath.row
                        }
                    
                    case .none:
                        
                        switch location {
                            
                            case .album: return container!.sections[indexPath.section].startingPoint + indexPath.row
                                
                            case .collections(kind: .playlist): return container!.sections[indexPath.section].startingPoint + indexPath.row
                                
                            default: return indexPath.row
                        }
                }
            
            default: return container!.sections[indexPath.section].startingPoint + indexPath.row
        }
    }
    
    func infoContext(from indexPath: IndexPath, collectionViewOverride: Bool = false, filtering: Bool) -> InfoViewController.Context {
        
        switch location {
            
            case .playlist, .album, .artistSongs: return .song(location: .list, at: getIndex(from: indexPath, filtering: filtering), within: relevantEntities(filtering: filtering) as! [MPMediaItem])
            
            case .songs: return .song(location: .list, at: getIndex(from: indexPath, filtering: filtering), within: collectionViewOverride ? (container?.tableView.tableHeaderView as? HeaderView)!.songs : relevantEntities(filtering: filtering) as! [MPMediaItem])
            
            case .artistAlbums(withinArtist: _): return .album(at: getIndex(from: indexPath, filtering: filtering), within: relevantEntities(filtering: filtering) as! [MPMediaItemCollection])
            
            case .collections(kind: .album), .collections(kind: .compilation): return .album(at: getIndex(from: indexPath, filtering: filtering), within: collectionViewOverride ? (container?.tableView.tableHeaderView as? HeaderView)!.collections : relevantEntities(filtering: filtering) as! [MPMediaItemCollection])
            
            case .collections(kind: .playlist): return .playlist(at: getIndex(from: indexPath, filtering: filtering), within: collectionViewOverride && !filtering ? (container?.tableView.tableHeaderView as? HeaderView)!.playlists : relevantEntities(filtering: filtering) as! [MPMediaPlaylist])
            
            case .collections(kind: let kind): return .collection(kind: kind.albumBasedCollectionKind, at: getIndex(from: indexPath, filtering: filtering), within: collectionViewOverride ? (container?.tableView.tableHeaderView as? HeaderView)!.collections : relevantEntities(filtering: filtering) as! [MPMediaItemCollection])
        }
    }
    
    private func relevantEntities(filtering: Bool) -> [MPMediaEntity] {
        
        guard let container = container else { return [] }
        
        return filtering ? container.filteredEntities : container.entities
    }
}

extension TableDelegate: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        
        self.tableView(tableView, prefetchRowsAt: indexPaths, filtering: false)
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        
        self.tableView(tableView, cancelPrefetchingForRowsAt: indexPaths, filtering: false)
    }
}

extension TableDelegate {
    
    func numberOfSections(in tableView: UITableView, filtering: Bool) -> Int {
        
        if filtering {
            
            return 1
            
        } else {
            
            switch container!.sortCriteria {
                
                case .standard:
                    
//                    if let vc = container as? ArtistSongsViewController, let entityVC = vc.entityVC, Set([AlbumBasedCollectionKind.artist, .albumArtist]).contains(entityVC.kind) {
//
//                        return container!.sections.count
//                    }
                    
                    switch querySectionsType {
                        
                        case .collections: return container!.query?.collectionSections?.count ?? 1
                        
                        case .items: return container!.query?.itemSections?.count ?? 1
                        
                        case .none:
                            
                            switch location {
                                
                                case .album: return container!.sections.count
                                
                                case .collections(kind: .playlist): return container!.sections.count
                                
                                default: return 1
                            }
                    }
                
                case .random: return 1
                
                default: return container!.sections.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int, filtering: Bool) -> Int {
        
        if filtering {
            
            return container!.filteredEntities.count
            
        } else {
            
            switch container!.sortCriteria {
                
                case .standard:
                    
//                    if let vc = container as? ArtistSongsViewController, let entityVC = vc.entityVC, Set([AlbumBasedCollectionKind.artist, .albumArtist]).contains(entityVC.kind) {
//
//                        return container!.sections[section].count
//                    }
                    
                    switch querySectionsType {
                        
                        case .collections: return !container!.entities.isEmpty ? container?.query?.collectionSections?[section].range.length ?? container!.entities.count : container!.entities.count
                        
                        case .items: return !container!.entities.isEmpty ? container?.query?.itemSections?[section].range.length ?? container!.entities.count : container!.entities.count
                        
                        case .none:
                            
                            switch location {
                                
                                case .album: return container!.sections[section].count
                                
                                case .collections(kind: .playlist): return container!.sections[section].count
                                
                                default: return container!.entities.count
                            }
                    }
                
                case .random: return container!.entities.count
                
                default: return container!.sections[section].count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, filtering: Bool) -> UITableViewCell {
        
        let cell = tableView.songCell(for: indexPath)
        
        switch location {
            
            case .playlist, .songs, .album, .artistSongs:
                
                cell.delegate = self
                
                let song = container?.getEntity(at: indexPath, filtering: filtering) as! MPMediaItem
                
                let songNumber: Int = {
                    
                    guard songCountVisible else {
                        
                        if case .album = location, container?.sortCriteria == .standard {
                            
                            return song.albumTrackNumber
                            
                        } else {
                            
                            return 0
                        }
                    }
                    
                    guard !filtering, container?.sortCriteria != .random else { return indexPath.row + 1 }
                    
                    switch location {
                        
                        case .album: return container!.sortCriteria == .standard ? song.albumTrackNumber : container!.sections[indexPath.section].startingPoint + indexPath.row + 1
                        
                        case .playlist: return container!.sortCriteria == .standard ? indexPath.row + 1 : container!.sections[indexPath.section].startingPoint + indexPath.row + 1
                        
                        case .artistSongs:
                            
//                            if let vc = container as? ArtistSongsViewController, let entityVC = vc.entityVC, Set([AlbumBasedCollectionKind.artist, .albumArtist]).contains(entityVC.kind) {
//
//                                return song.albumTrackNumber//container!.sections[indexPath.section].startingPoint + indexPath.row + 1
//                            }
                            
                            return querySectionsType == .items && container!.sortCriteria == .standard ? (container!.query?.itemSections?[indexPath.section].range.location ?? 0) + indexPath.row + 1 : container!.sections[indexPath.section].startingPoint + indexPath.row + 1
                        
                        default: return querySectionsType == .items && container!.sortCriteria == .standard ? (container!.query?.itemSections?[indexPath.section].range.location ?? 0) + indexPath.row + 1 : container!.sections[indexPath.section].startingPoint + indexPath.row + 1
                    }
                }()
                
                cell.prepare(with: song, songNumber: songNumber, highlightedSong: container?.highlightedEntity as? MPMediaItem)
                cell.swipeDelegate = self
                
                let loader: InfoLoading? = filtering ? container?.filterContainer : container
                loader?.updateImageView(using: song, in: cell, indexPath: indexPath, reusableView: tableView)
                
                for category in [SecondaryCategory.loved, .plays, .rating, .lastPlayed, .dateAdded, .genre, .year, .fileSize] {
                    
                    loader?.update(category: category, using: song, in: cell, at: indexPath, reusableView: tableView)
                }
            
            case .artistAlbums(withinArtist: let withinArtist):
                
                if let album: MPMediaItemCollection = {
                    
                    let album = container?.getEntity(at: indexPath, filtering: filtering) as? MPMediaItemCollection
                    
                    if album?.representativeItem?.isCompilation == true, let album = album {
                        
                        let query = MPMediaQuery.init(filterPredicates: [.for(.album, using: album)])
                        query.groupingType = .album
                        
                        if offline(considering: (container as? UIViewController)?.parent as? OnlineOverridable ?? container as? OnlineOverridable) {
                            
                            query.addFilterPredicate(.offline)
                        }
                        
                        return query.collections?.first
                    }
                    
                    return album
                    
                }() {
                    
                    let number: Int = {
                    
                        guard songCountVisible, let container = container else { return 0 }
                        
                        guard !filtering else { return indexPath.row + 1 }
                        
                        switch container.sortCriteria {
                            
                            case .random: return indexPath.row + 1
                            
                            case .standard: return (container.query?.collectionSections?[indexPath.section].range.location ?? 0) + indexPath.row + 1
                            
                            default: return container.sections[indexPath.section].startingPoint + indexPath.row + 1
                        }
                    }()
                    
                    cell.prepare(with: album, withinArtist: album.representativeItem?.isCompilation == true ? false : withinArtist, highlightedAlbum: container?.highlightedEntity as? MPMediaItemCollection, number: number)
                    cell.delegate = self
                    cell.swipeDelegate = self
                    
                    let loader: InfoLoading? = filtering ? container?.filterContainer : container
                    loader?.updateImageView(using: album, in: cell, indexPath: indexPath, reusableView: tableView)
                }
            
            case .collections(let kind):
                
                let collection = container?.getEntity(at: indexPath, filtering: filtering) as! MPMediaItemCollection
                
                let number: Int = {
                    
                    guard songCountVisible, let container = container else { return 0 }
                
                    guard !filtering else { return indexPath.row + 1 }
                
                    switch container.sortCriteria {
                        
                        case .random: return indexPath.row + 1
                        
                        case .standard where kind != .playlist: return (container.query?.collectionSections?[indexPath.section].range.location ?? 0) + indexPath.row + 1
                        
                        default: return container.sections[indexPath.section].startingPoint + indexPath.row + 1
                    }
                }()
                
                switch kind {
                    
                    case .album, .compilation:
                        
                        cell.prepare(with: collection, withinArtist: false, number: number)
                        cell.delegate = self
                        cell.swipeDelegate = self
                        
                        let loader: InfoLoading? = filtering ? container?.filterContainer : container
                        loader?.updateImageView(using: collection, in: cell, indexPath: indexPath, reusableView: tableView)
                    
                    case .artist, .composer, .genre, .albumArtist:
                        
                        cell.prepare(for: kind.albumBasedCollectionKind, with: collection, number: number)
                        cell.delegate = self
                        cell.swipeDelegate = self
                        
                        let loader: InfoLoading? = filtering ? container?.filterContainer : container
                        loader?.updateImageView(using: collection, in: cell, indexPath: indexPath, reusableView: tableView)
                    
                    case .playlist:
                        
                        let playlist = collection as! MPMediaPlaylist
                        cell.prepare(with: playlist, count: collection.count, number: number)
                        
                        if let collectionsVC = container as? CollectionsViewController, collectionsVC.presented {
                            
                            [cell.playButton, cell.infoButton, cell.supplemetaryScrollView].forEach({ $0.isUserInteractionEnabled = false })
                            cell.optionsView.isHidden = true
                            
                            if Set(collectionsVC.selectedPlaylists).contains(playlist), cell.isSelected.inverted {
                                
                                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                                
                            } else if Set(collectionsVC.selectedPlaylists).contains(playlist).inverted, cell.isSelected {
                                
                                tableView.deselectRow(at: indexPath, animated: false)
                            }
                            
                        } else {
                            
                            cell.delegate = self
                        }
                        
                        cell.swipeDelegate = self
                        
                        if showPlaylistFolders, let collectionsVC = container as? CollectionsViewController, filtering.inverted {
                            
                            let index = collectionsVC .sortCriteria == .random ? indexPath.row : (collectionsVC .sections[indexPath.section].startingPoint + indexPath.row)
                            let container = playlistContainers[index]
                            
                            cell.stackViewLeadingConstraint.constant = container.index * 16
    //                        cell.contentView.alpha = container.isExpanded ? 1 : 0
                        
                        } else {
                            
                            cell.stackViewLeadingConstraint.constant = 0
    //                        cell.contentView.alpha = 1
                        }
                        
                        let loader: InfoLoading? = filtering ? container?.filterContainer : container
                        loader?.updateImageView(using: collection, in: cell, indexPath: indexPath, reusableView: tableView, overridable: container as? OnlineOverridable)
                }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath, filtering: Bool) {
        
        let loader: InfoLoading? = filtering ? container?.filterContainer : container
        loader?.operations[indexPath]?.cancel()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath, filtering: Bool) {
        
        if tableView.isEditing {
            
            self.tableView(tableView, commit: self.tableView(tableView, editingStyleForRowAt: indexPath), forRowAt: indexPath, filtering: filtering)
            
        } else {
            
            container?.selectCell(in: tableView, at: indexPath, filtering: filtering)
        }
        
        switch location {
            
            case .artistAlbums, .collections:
                
                if container?.filterContainer?.tableView.isEditing == false {
                    
                    if let collectionsVC = container as? CollectionsViewController, collectionsVC.presented {
                        
                        break
                    }
                    
                    container?.filterContainer?.sender?.wasFiltering = true
                    container?.filterContainer?.dismiss(animated: true, completion: nil)
                }
            
            default: break
        }
        
        if let collectionsVC = container as? CollectionsViewController, collectionsVC.presented {
            
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath, filtering: Bool) {
        
        guard let collectionsVC = container as? CollectionsViewController, collectionsVC.presented else { return }
        
        collectionsVC.deselectCell(in: tableView, at: indexPath, filtering: filtering)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath, filtering: Bool) -> CGFloat {
        
//        if let collectionsVC = container as? CollectionsViewController, case .collections(kind: .playlist) = location, showPlaylistFolders {
//
//            let index = collectionsVC .sortCriteria == .random ? indexPath.row : (collectionsVC .sections[indexPath.section].startingPoint + indexPath.row)
//            let container = playlistContainers[index]
//
//            return cellSizes[container.playlist.id] ?? 72
//        }
        
        return 72
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int, filtering: Bool) -> CGFloat {
        
        if filtering {
            
            return 0.0001
            
        } else {
            
            switch container!.sortCriteria {
                
                case .standard:
                    
                    switch location {
                        
                        case .album: return .textHeaderHeight
                        
                        case .playlist: return 11
                        
                        case .songs, .artistSongs, .artistAlbums(withinArtist: _), .collections(kind: _):
                            
                            switch querySectionsType {
                                
                                case .collections:
                                    
                                    guard let _ = container?.query?.collectionSections else { return .emptyHeaderHeight }
                                    
                                    return .textHeaderHeight
                                
                                case .items:
                                    
                                    guard let _ = container?.query?.items else { return .emptyHeaderHeight }
                                    
                                    return .textHeaderHeight
                                
                                case .none:
                                    
                                    if case .collections(kind: .playlist) = location {
                                        
                                        return .textHeaderHeight
                                    }
                                    
                                    return .emptyHeaderHeight
                            }
                    }
                
                case .random: return .emptyHeaderHeight + {
                
                    switch location {
                        
                        case .songs where showRecentSongs: return 16
                        
                        case .collections(kind: let kind):
                        
                            switch kind {
                                
                                case .album where showRecentAlbums: return 16
                                
                                case .artist where showRecentArtists,
                                     .albumArtist where showRecentArtists: return 16
                                
                                case .compilation where showRecentCompilations: return 16
                                
                                case .composer where showRecentComposers: return 16
                                
                                case .genre where showRecentGenres: return 16
                                
                                case .playlist where showRecentPlaylists: return 16
                                
                                default: return 0
                            }
                        
                        default: return 0
                    }
                }()
                
                default: return .textHeaderHeight
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int, filtering: Bool) -> CGFloat {
        
        return self.tableView(tableView, heightForFooterInSection: section)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int, filtering: Bool) -> UIView? {
        
        guard filtering.inverted, !container!.entities.isEmpty, let header = tableView.sectionHeader else { return nil }
        
        if filtering {
            
            header.label.text = nil
            
        } else {
            
            switch container!.sortCriteria {
                
                case .random: header.label.text = nil
                
                case .standard:
                    
                    let text: String? = {
                        
//                        if let vc = container as? ArtistSongsViewController, let entityVC = vc.entityVC, Set([AlbumBasedCollectionKind.artist, .albumArtist]).contains(entityVC.kind) {
//
//                            return container?.sections[section].title//.capitalized
//                        }
                        
                        switch location {
                            
                            case .album: return container?.sections[section].title//.capitalized
                            
                            case .collections(kind: .playlist): return container?.sections[section].title//.capitalized
                            
                            default: return self.sectionIndexTitles(for: tableView)?[section]
                        }
                    }()
                
                    header.label.text = text?.lowercased()
                
                default: header.label.text = container?.sections[section].title.lowercased()//.capitalized
            }
        }
        
        header.canShowLeftButton = {
            
            switch container!.sortCriteria {
                
                case .standard: return container?.location != .playlist
                
                case .random: return false
                
                default: return true
            }
        }()
        
        let shouldShowLeftButton = header.canShowLeftButton && container!.tableView.isEditing && container!.tableView.numberOfSections > 1 && filtering.inverted
        
        if shouldShowLeftButton.inverted && header.showButton.inverted { } else {
            
            header.showButton = shouldShowLeftButton
            header.updateLabelConstraint(showButton: shouldShowLeftButton)
        }
        
        header.button.tag = section
        header.button.addTarget(self, action: #selector(collectFromSection(_:)), for: .touchUpInside)
        header.altButton.addTarget(self, action: #selector(viewSections), for: .touchUpInside)
        
        let shouldHideRightButton = true
        
        header.rightButtonViewConstraint.constant = shouldHideRightButton ? 0 : 44
        header.rightButton.superview?.alpha = shouldHideRightButton ? 0 : 1
        
        return header
    }
    
    func sectionIndexTitles(for tableView: UITableView, filtering: Bool) -> [String]? {
        
        if filtering {
            
            return nil
            
        } else {
            
            switch container!.sortCriteria {
                
                case .standard:
                    
//                    if let vc = container as? ArtistSongsViewController, let entityVC = vc.entityVC, Set([AlbumBasedCollectionKind.artist, .albumArtist]).contains(entityVC.kind) {
//
//                        return vc.sections.map({ $0.indexTitle })
//                    }
                    
                    let details: (array: [String]?, isCorrectOrder: Bool) = {
                        
                        switch querySectionsType {
                            
                            case .collections: return (container?.query?.collectionSections?.map({ $0.title }), container!.ascending)
                            
                            case .items: return (container?.query?.itemSections?.map({ $0.title }), container!.ascending)
                            
                            case .none:
                                
                                switch location {
                                    
                                    case .album: return (container?.sections.map({ $0.indexTitle }), true)
                                    
                                    case .collections(kind: .playlist): return (container?.sections.map({ $0.indexTitle }), true)
                                    
                                    default: return (nil, true)
                                }
                        }
                    }()
                    
                    return details.isCorrectOrder ? details.array : details.array?.reversed()
                
                case .random: return nil
                
                default: return container?.sections.map({ $0.indexTitle })
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath, filtering: Bool) -> UITableViewCell.EditingStyle {
        
        return self.tableView(tableView, editingStyleForRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath, filtering: Bool) {
        
        guard editingStyle == .insert else { return }
        
        notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: items(at: indexPath, filtering: filtering)])
        
        container?.filterContainer?.saveRecentSearch(withTitle: container?.filterContainer?.searchBar?.text, resignFirstResponder: false)
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath], filtering: Bool) {
        
        indexPaths.forEach({
            
            guard let cell = tableView.cellForRow(at: $0) as? SongTableViewCell, let entity = container?.getEntity(at: $0, filtering: container?.filterContainer != nil) else { return }
            
            switch location {
                
                case .playlist, .songs, .album, .artistSongs:
                    
                    let loader: InfoLoading? = filtering ? container?.filterContainer : container
                    loader?.updateImageView(using: entity as! MPMediaItem, in: cell, indexPath: $0, reusableView: tableView)
                    
                    for category in [SecondaryCategory.loved, .plays, .rating, .lastPlayed, .dateAdded, .genre, .year, .fileSize] {
                        
                        loader?.update(category: category, using: entity as! MPMediaItem, in: cell, at: $0, reusableView: tableView)
                    }
                
                case .collections, .artistAlbums:
                    let loader: InfoLoading? = filtering ? container?.filterContainer : container
                    loader?.updateImageView(using: entity as! MPMediaItemCollection, in: cell, indexPath: $0, reusableView: tableView, overridable: container as? OnlineOverridable)
            }
        })
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath], filtering: Bool) {
        
        let loader: InfoLoading? = filtering ? container?.filterContainer : container
        
        indexPaths.forEach({ loader?.operations[$0]?.cancel() })
        
        guard let container = container else { return }
        
        switch location {
            
            case .playlist, .songs, .album, .artistSongs:
                
                indexPaths.forEach({
                    
                    for category in [SecondaryCategory.loved, .plays, .rating, .lastPlayed, .dateAdded, .genre, .year, .fileSize] {
                        
                        loader?.infoOperations[.init(id: container.getEntity(at: $0, filtering: filtering).persistentID, index: category.rawValue)]?.cancel()
                    }
                })
            
            case .collections, .artistAlbums: break
        }
    }
}

extension TableDelegate: EntityCellDelegate {
    
    func editButtonTapped(in cell: SongTableViewCell) {
        
        scrollViewTapped(in: cell)
    }
    
    func accessoryButtonTapped(in cell: SongTableViewCell) {
        
        guard let container = container as? TableViewContainer & UIViewController, let tableView = container.filterContainer?.tableView ?? container.tableView, let indexPath = tableView.indexPath(for: cell) else { return }
        
        let item = container.getEntity(at: indexPath, filtering: container.filterContainer != nil)
        
        guard let count: Int = {
            
            if let _ = item as? MPMediaItem {
                
                return 1
                
            } else if let collection = item as? MPMediaItemCollection {
                
                return collection.count
            }
            
            return nil
        
        }(), count > 0, let vc: UIViewController = container.filterContainer ?? container, let actionable = vc as? SingleItemActionable else { return }
        
        var actions = [SongAction.collect, .info(context: infoContext(from: indexPath, filtering: container.filterContainer != nil)), .queue(name: cell.nameLabel.text, query: query(at: indexPath, filtering: container.filterContainer != nil)), .newPlaylist, .addTo].map({ actionable.singleItemAlertAction(for: $0, entity: .song, using: item, from: vc) })
        
        if let item = item as? MPMediaItem, item.existsInLibrary.inverted {
            
            actions.insert(actionable.singleItemAlertAction(for: .library, entity: .song, using: item, from: vc), at: 3)
        }
        
        vc.present(UIAlertController.withTitle(nil, message: cell.nameLabel.text, style: .actionSheet, actions: actions + [.cancel()] ), animated: true, completion: nil)
    }
    
    func scrollViewTapped(in cell: SongTableViewCell) {
        
        guard let container = container, let tableView = container.filterContainer?.tableView ?? container.tableView, let indexPath = tableView.indexPath(for: cell) else { return }
        
        if tableView.allowsMultipleSelectionDuringEditing && tableView.isEditing {
            
            if cell.isSelected {
                
                tableView.deselectRow(at: indexPath, animated: false)
                
            } else {
                
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
            
            return
        }
        
        cell.setHighlighted(true, animated: true)
        self.tableView(tableView, didSelectRowAt: indexPath, filtering: container.filterContainer != nil)
        cell.setHighlighted(false, animated: true)
    }
    
    func artworkTapped(in cell: SongTableViewCell) {
        
        guard let container = container, let tableView = container.filterContainer?.tableView ?? container.tableView, let indexPath = tableView.indexPath(for: cell) else { return }
        
        if tableView.isEditing {
            
            cell.setHighlighted(true, animated: true)
            self.tableView(tableView as UITableView, commit: self.tableView(tableView as UITableView, editingStyleForRowAt: indexPath), forRowAt: indexPath, filtering: container.filterContainer != nil)
            cell.setHighlighted(false, animated: true)
            
        } else if allowPlayOnly.inverted {
            
            cell.setHighlighted(true, animated: true)
            self.tableView(tableView, didSelectRowAt: indexPath, filtering: container.filterContainer != nil)
            cell.setHighlighted(false, animated: true)
            
        } else {
            
            let songs = items(at: indexPath, filtering: container.filterContainer != nil)
            
            if songs.count > 1 {
                
                var array = [UIAlertAction]()
                let canShuffleAlbums = songs.canShuffleAlbums
                
                let play = UIAlertAction.init(title: "Play", style: .default, handler: { _ in
                    
                    musicPlayer.play(songs, startingFrom: songs.first, from: container as? UIViewController, withTitle: cell.nameLabel.text, alertTitle: "Play", completion: { [weak self] in
                        
                        guard let weakSelf = self else { return }
                        
                        weakSelf.container?.filterContainer?.saveRecentSearch(withTitle: weakSelf.container?.filterContainer?.searchBar?.text, resignFirstResponder: false)
                    })
                })
                
                array.append(play)
                
                let shuffle = UIAlertAction.init(title: .shuffle(canShuffleAlbums ? .songs : .none), style: .default, handler: { _ in
                    
                    musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: container as? UIViewController, withTitle: cell.nameLabel.text, alertTitle: .shuffle(canShuffleAlbums ? .songs : .none), completion: { [weak self] in
                        
                        guard let weakSelf = self else { return }
                        
                        weakSelf.container?.filterContainer?.saveRecentSearch(withTitle: weakSelf.container?.filterContainer?.searchBar?.text, resignFirstResponder: false)
                    })
                })
                
                array.append(shuffle)
                
                if canShuffleAlbums {
                    
                    let shuffleAlbums = UIAlertAction.init(title: .shuffle(.albums), style: .default, handler: { _ in
                        
                        musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: container as? UIViewController, withTitle: cell.nameLabel.text, alertTitle: .shuffle(.albums), completion: { [weak self] in
                            
                            guard let weakSelf = self else { return }
                            
                            weakSelf.container?.filterContainer?.saveRecentSearch(withTitle: weakSelf.container?.filterContainer?.searchBar?.text, resignFirstResponder: false)
                        })
                    })
                    
                    array.append(shuffleAlbums)
                }
                
                (container.filterContainer ?? container as? UIViewController)?.present(UIAlertController.withTitle(cell.nameLabel.text, message: nil, style: .actionSheet, actions: array + [.cancel()]), animated: true, completion: nil)
                
            } else {
                
                musicPlayer.play(songs, startingFrom: songs.first, from: container.filterContainer ?? container as? UIViewController, withTitle: cell.nameLabel.text, alertTitle: "Play", completion: { [weak self] in
                    
                    guard let weakSelf = self else { return }
                    
                    weakSelf.container?.filterContainer?.saveRecentSearch(withTitle: weakSelf.container?.filterContainer?.searchBar?.text, resignFirstResponder: false)
                })
            }
        }
    }
}

extension TableDelegate: SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        switch orientation {
            
            case .left:
                
                guard let container = container else { return nil }
                
                let actionable = container.filterContainer as? SongActionable ?? container
                
                if let collectionsVC = container as? CollectionsViewController, collectionsVC.presented, collectionsVC.filterContainer == nil {
                    
                    return nil
                }
                
                var array = [SwipeAction]()
                
                let edit = SwipeAction.init(style: .default, title: tableView.isEditing ? "done" : "edit", handler: { action, _ in
                    
                    actionable.songManager.toggleEditing(action)
                })
                
                edit.image = tableView.isEditing ? #imageLiteral(resourceName: "CheckBordered17") : #imageLiteral(resourceName: "Edit17")
                
                array.append(edit)
                
                if musicPlayer.nowPlayingItem != nil, let cell = tableView.cellForRow(at: indexPath) as? SongTableViewCell {
                    
                    let details = getActionDetails(from: .queue(name: cell.nameLabel.text, query: query(at: indexPath, filtering: container.filterContainer != nil)), indexPath: indexPath, vc: container.filterContainer ?? container as? UIViewController)
                    
                    let queue = SwipeAction.init(style: .default, title: details?.title.lowercased(), handler: { _, _ in details?.handler() })
                    
                    queue.image = details?.action.icon
                    
                    array.append(queue)
                }
                
                return array
            
            case .right:
                
                if let collectionsVC = container as? CollectionsViewController, collectionsVC.presented {
                    
                    return nil
                }
                
                var array = [SwipeAction]()
                
                if let cell = tableView.cellForRow(at: indexPath) as? SongTableViewCell {
                    
                    let details = getActionDetails(from: SongAction.show(title: cell.nameLabel.text, context: infoContext(from: indexPath, filtering: container?.filterContainer != nil)), indexPath: indexPath, vc: container?.filterContainer ?? container as? UIViewController, useAlternateTitle: true)
                    
                    let goTo = SwipeAction.init(style: .default, title: details?.title.lowercased(), handler: { _, _ in details?.handler() }, image: details?.action.icon)
                    
                    array.append(goTo)
                }
                
                if let _ = container?.filterContainer {
                    
                    let details = getActionDetails(from: SongAction.reveal(indexPath: indexPath), indexPath: indexPath, vc: container as? UIViewController)
                    
                    let context = SwipeAction.init(style: .default, title: details?.title.lowercased(), handler: { _, _ in details?.handler() }, image: details?.action.icon)
                    
                    if let collectionsVC = container as? CollectionsViewController, collectionsVC.presented {
                        
                        return [context]
                    }
                    
                    array.append(context)
                }
                
                return array
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        
        var options = SwipeTableOptions()
        options.transitionStyle = .drag
        options.expansionStyle = .selection
        
        return options
    }
}

extension TableDelegate {
    
    static func editActions(for searchViewController: SearchViewController, orientation: SwipeActionsOrientation, using entity: MPMediaEntity?, at indexPath: IndexPath) -> [SwipeAction]? {
        
        switch orientation {
            
            case .left:
            
                var array = [SwipeAction]()
                
                let editing = searchViewController.tableView.isEditing
                
                let edit = SwipeAction.init(style: .default, title: editing ? "done" : "edit", handler: { action, _ in
                    
                    editing ? searchViewController.handleLeftSwipe(searchViewController) : searchViewController.handleRightSwipe(searchViewController)
                })
                
                edit.image = editing ? #imageLiteral(resourceName: "CheckBordered17") : #imageLiteral(resourceName: "Edit17")
                
                array.append(edit)
                
                if musicPlayer.nowPlayingItem != nil, let cell = searchViewController.tableView.cellForRow(at: indexPath) as? SongTableViewCell {
                    
                    let details = searchViewController.getActionDetails(from: .queue(name: cell.nameLabel.text, query: nil), indexPath: indexPath, actionable: searchViewController, vc: searchViewController, entityType: .song, entity: searchViewController.getEntity(at: indexPath)!)
                    
                    let queue = SwipeAction.init(style: .default, title: details?.title.lowercased(), handler: { _, _ in details?.handler() }, image: details?.action.icon)
                    
                    array.append(queue)
                }
            
                return array
            
            case .right:
            
                var array = [SwipeAction]()
                
                if let cell = searchViewController.tableView.cellForRow(at: indexPath) as? SongTableViewCell {
                    
                    let details = searchViewController.getActionDetails(from: .show(title: cell.nameLabel.text, context: searchViewController.context(from: indexPath)), indexPath: indexPath, actionable: searchViewController, vc: searchViewController, entityType: searchViewController.sectionDetails[indexPath.section].category.entity, entity: searchViewController.getEntity(at: indexPath)!, useAlternateTitle: true)
                        
                    let goTo = SwipeAction.init(style: .default, title: details?.title.lowercased(), handler: { _, indexPath in details?.handler() }, image: details?.action.icon)
                    
                    array.append(goTo)
                }
                
                return array
        }
    }
    
    static func editActions(for queueViewController: QueueViewController, orientation: SwipeActionsOrientation, using item: MPMediaItem?, at indexPath: IndexPath) -> [SwipeAction]? {
        
        guard !queueViewController.presented else { return nil }
        
        switch orientation {
            
            case .left:
                
                guard musicPlayer.nowPlayingItem != nil, musicPlayer.queueCount() > 1 else { return nil }
            
                var array = [SwipeAction]()
                
                let editing = queueViewController.tableView.isEditing
                
                let edit = SwipeAction.init(style: .default, title: editing ? "done" : "edit", handler: { _, _ in
                    
                    queueViewController.songManager.toggleEditing(queueViewController)
                })
                
                edit.image = editing ? #imageLiteral(resourceName: "CheckBordered17") : #imageLiteral(resourceName: "Edit17")
                
                array.append(edit)
            
                return array
            
            case .right:
            
                var array = [SwipeAction]()
                
                if indexPath.section != 1 {
                    
                    let delete = SwipeAction.init(style: .default, title: "delete", handler: { _, indexPath in
                        
                        queueViewController.removeSelected([indexPath])
                    })
                    
                    delete.image = #imageLiteral(resourceName: "Discard17")
                    
                    array.append(delete)
                }
                
                if let cell = queueViewController.tableView.cellForRow(at: indexPath) as? SongTableViewCell {
                    
                    let details = queueViewController.getActionDetails(from: .show(title: cell.nameLabel.text, context: queueViewController.context(from: indexPath)), indexPath: indexPath, actionable: queueViewController, vc: queueViewController, entityType: .song, entity: queueViewController.getSong(from: indexPath)!, useAlternateTitle: true)
                
                    let goTo = SwipeAction.init(style: .default, title: "show...", handler: { _, indexPath in details?.handler() }, image: details?.action.icon)
                    
                    array.append(goTo)
                }
                
                if isInDebugMode, array.count > 1 {
                    
                    array.append(array.remove(at: 0))
                }
                
                return array
        }
    }
    
    static func editActions(for collectorItemsViewController: CollectorViewController, orientation: SwipeActionsOrientation, using item: MPMediaItem?, at indexPath: IndexPath) -> [SwipeAction]? {
        
        switch orientation {
            
            case .left:
            
                var array = [SwipeAction]()
                
                let editing = collectorItemsViewController.tableView.isEditing
                
                let edit = SwipeAction.init(style: .default, title: editing ? "done" : "edit", handler: { _, _ in
                    
                    collectorItemsViewController.songManager.toggleEditing(collectorItemsViewController.editButton)
                })
                
                edit.image = editing ? #imageLiteral(resourceName: "CheckBordered17") : #imageLiteral(resourceName: "Edit17")
                
                array.append(edit)
                
                return array
            
            case .right:
                
                var array = [SwipeAction]()
            
                let delete = SwipeAction.init(style: .default, title: "delete", handler: { _, indexPath in
                    
                    collectorItemsViewController.tableView(collectorItemsViewController.tableView, commit: .delete, forRowAt: indexPath)
                })
                
                delete.image = #imageLiteral(resourceName: "Discard17")
                
                array.append(delete)
                
                if let cell = collectorItemsViewController.tableView.cellForRow(at: indexPath) as? SongTableViewCell {
                    
                    let details = collectorItemsViewController.getActionDetails(from: .show(title: cell.nameLabel.text, context: .song(location: .list, at: indexPath.row, within: collectorItemsViewController.manager.queue)), indexPath: indexPath, actionable: collectorItemsViewController, vc: collectorItemsViewController, entityType: .song, entity: collectorItemsViewController.manager.queue[indexPath.row], useAlternateTitle: true)
                    
                    let goTo = SwipeAction.init(style: .default, title: details?.title.lowercased(), handler: { _, indexPath in details?.handler() }, image: details?.action.icon)
                    
                    array.append(goTo)
                }
                
                if isInDebugMode, array.count > 1 {
                    
                    array.append(array.remove(at: 0))
                }
            
                return array
        }
    }
    
    static func editActions(for newPlaylistViewController: NewPlaylistViewController, orientation: SwipeActionsOrientation, using item: MPMediaItem?, at indexPath: IndexPath) -> [SwipeAction]? {
        
        switch orientation {
            
        case .left:
            
            var array = [SwipeAction]()
            
            let editing = newPlaylistViewController.tableView.isEditing
            
            let edit = SwipeAction.init(style: .default, title: editing ? "done" : "edit", handler: { _, _ in
                
                newPlaylistViewController.songManager.toggleEditing(newPlaylistViewController)
            })
            
            edit.image = editing ? #imageLiteral(resourceName: "CheckBordered17") : #imageLiteral(resourceName: "Edit17")
            
            array.append(edit)
            
            return array
            
        case .right:
            
            var array = [SwipeAction]()
            
            let delete = SwipeAction.init(style: .default, title: "delete", handler: { _, indexPath in
                
                newPlaylistViewController.updateItems(at: [indexPath], for: .remove)//.removeSelected([indexPath])
            })
            
            delete.image = #imageLiteral(resourceName: "Discard17")
            
            array.append(delete)
            
            return array
        }
    }
}
