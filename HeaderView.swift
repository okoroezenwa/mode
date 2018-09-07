//
//  HeaderView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 11/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class HeaderView: UIView, InfoLoading {

    @IBOutlet weak var descriptionTextView: MELTextView!
    @IBOutlet weak var descriptionTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollStackView: UIStackView!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewHeaderHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var artistView: UIView!
    @IBOutlet weak var artistButton: MELButton!
    @IBOutlet weak var actionsStackView: UIStackView!
    @IBOutlet var likedView: UIView!
    @IBOutlet var insertView: UIView!
    @IBOutlet var infoView: UIView!
    @IBOutlet weak var chevron: MELImageView!
    @IBOutlet weak var chevronBorder: UIView!
    @IBOutlet weak var likedStateButton: MELButton!
    @IBOutlet weak var tableHeaderContainer: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var loadingEffectView: MELVisualEffectView!
    @IBOutlet weak var activityIndicatorView: MELActivityIndicatorView!
    @IBOutlet var buttonsStackView: UIStackView!
    @IBOutlet var addButton: MELButton!
    @IBOutlet var infoButton: MELButton!
    @IBOutlet var scrollStackViewHeightConstraint: NSLayoutConstraint!
    
    enum Context {
        
        case songs([MPMediaItem])
        case albums([MPMediaItemCollection])
        case collections(kind: AlbumBasedCollectionKind, [MPMediaItemCollection])
        case playlists([MPMediaPlaylist])
        
        func infoContext(at indexPath: IndexPath) -> InfoViewController.Context {
            
            switch self {
                
                case .albums(let collections): return .album(at: indexPath.row, within: collections)
                
                case .collections(kind: let kind, let collections): return .collection(kind: kind, at: indexPath.row, within: collections)
                
                case .playlists(let playlists): return .playlist(at: indexPath.row, within: playlists)
                
                case .songs(let songs): return .song(location: .list, at: indexPath.row, within: songs)
            }
        }
    }
    
    lazy var entityType: Entity = {
    
        switch context {
            
            case .albums(let collections): return .album
            
            case .collections(kind: let kind, let collections): return kind.entity
        
            case .playlists(let playlists): return .playlist
        
            case .songs(let songs): return .song
        }
    }()
    var context = Context.playlists([])
    
    let width = screenWidth / 2.75
    lazy var size: CGSize = { return CGSize.init(width: width, height: width + 17 + 4 + 14 - 0.001) }()
    
    @objc lazy var header = TableHeaderView.with(leftButtonVisible: true)
    
    @objc var showTextView = false {
        
        didSet {
            
            if showTextView {
                
                descriptionTextViewHeightConstraint.priority = UILayoutPriority(rawValue: 1)
            }
        }
    }
    
    @objc var showArtistView = false {
        
        didSet {
            
            artistView.isHidden = showArtistView.inverted
            updateScrollStackView()
        }
    }
    
    @objc var showLoved = false {
        
        didSet {
            
            likedView.isHidden = !showLoved
            updateScrollStackView()
        }
    }
    
    @objc var showInsert = false {
        
        didSet {
            
            insertView.isHidden = !showInsert
            updateScrollStackView()
        }
    }
    
    @objc var showInfo = false {
        
        didSet {
            
            infoView.isHidden = !showInfo
            updateScrollStackView()
        }
    }
    
    @objc var showRecents = false {
        
        didSet {
            
            collectionViewHeightConstraint.constant = showRecents ? ((UIScreen.main.bounds.width) / 2.75) + 17 + 4 + 14 : 0
            collectionView.isHidden = !showRecents
            collectionViewHeaderHeightConstraint.constant = showRecents ? .textHeaderHeight : 0
            tableHeaderContainer.isHidden = !showRecents
            
            if header.superview != tableHeaderContainer {
                
                tableHeaderContainer.fill(with: header)
                
                if let label = header.label {
                    
                    label.text = "recent"
                }
            }
        }
    }
    
    @objc class var fresh: HeaderView {
        
        let view = Bundle.main.loadNibNamed("HeaderView", owner: nil, options: nil)?.first as! HeaderView
        
        return view
    }
    
    var playlists: [MPMediaPlaylist] {
        
        get {
            
            guard case .playlists(let playlists) = context else { return [] }
            
            return playlists
        }
        
        set { context = .playlists(newValue) }
    }
    var collections: [MPMediaItemCollection] {
        
        get {
            
            switch context {
                
                case .albums(let albums): return albums
                
                case .collections(kind: _, let collections): return collections
                
                default: return []
            }
        }
        
        set {
            
            switch context {
                
                case .albums: context = .albums(newValue)
                
                case .collections(kind: let kind, _): context = .collections(kind: kind, newValue)
                
                default: break
            }
        }
    }
    var songs: [MPMediaItem] {
        
        get {
            
            guard case .songs(let songs) = context else { return [] }
            
            return songs
        }
        
        set { context = .songs(newValue) }
    }
    @objc var operations = ImageOperations()
    @objc var infoOperations = InfoOperations()
    @objc let infoCache: InfoCache = {
        
        let cache = InfoCache()
        cache.name = "Info Cache"
        cache.countLimit = 2500
        
        return cache
    }()
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
    
    weak var viewController: UIViewController? {
        
        didSet {
            
            if let collectionView = collectionView {
                
                collectionView.register(UINib.init(nibName: "PlaylistCollectionCell", bundle: nil), forCellWithReuseIdentifier: "playlistCell")
                collectionView.delegate = self
                collectionView.dataSource = self
                
                if let collectionsVC = viewController as? CollectionsViewController, collectionsVC.presented {
                    
                    collectionView.allowsMultipleSelection = true
                }
            }
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        updateScrollStackView()
    }
    
    func updateScrollStackView() {
        
        scrollStackView.layoutMargins.left = showArtistView.inverted && showLoved.inverted && showInfo.inverted && showInsert.inverted ? 16 : 0
        buttonsStackView.layoutMargins.left = showArtistView ? 0 : (showLoved || showInfo || showInsert) ? 16 : 0
    }
}

extension HeaderView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch context {
            
            case .songs(let items): return items.count
            
            case .albums(let collections): return collections.count
            
            case .collections(kind: _, let collections): return collections.count
            
            case .playlists(let playlists): return playlists.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let cell = cell as? PlaylistCollectionViewCell else { return }
        
        switch context {
            
            case .songs(let songs):
            
                let song = songs[indexPath.row]
            
                updateImageView(using: song, in: cell, indexPath: indexPath, reusableView: collectionView)
            
            case .playlists(let playlists):
            
                let playlist = playlists[indexPath.row]
                
                updateImageView(using: playlist, in: cell, indexPath: indexPath, reusableView: collectionView, overridable: viewController as? OnlineOverridable)
            
            case .albums(let albums):
            
                let album = albums[indexPath.row]
            
                updateImageView(using: album, in: cell, indexPath: indexPath, reusableView: collectionView)
            
            case .collections(kind: _, let collections):
            
                let collection = collections[indexPath.row]
                
                updateImageView(using: collection, in: cell, indexPath: indexPath, reusableView: collectionView)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "playlistCell", for: indexPath) as! PlaylistCollectionViewCell
        
        switch context {
            
            case .songs(let items):
            
                let song = items[indexPath.row]
                
                if let songsVC = viewController as? SongsViewController {
                    
                    cell.delegate = self
                    cell.prepare(with: song, editing: songsVC.tableView.isEditing)
                    cell.details = (.song, width)
                }
            
            case .playlists(let playlists):
            
                let playlist = playlists[indexPath.row]
                
                if let collectionsVC = viewController as? CollectionsViewController {
                    
                    if !collectionsVC.presented {
                        
                        cell.delegate = self
                    
                    } else {
                        
                        if Set(collectionsVC.selectedPlaylists).contains(playlist), cell.isSelected.inverted {
                            
                            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                            
                        } else if Set(collectionsVC.selectedPlaylists).contains(playlist).inverted, cell.isSelected {
                            
                            collectionView.deselectItem(at: indexPath, animated: false)
                        }
                    }
                    
                    cell.prepare(with: playlist, count: playlist.count, editingMode: collectionsVC.tableView.isEditing)
                    cell.details = (.playlist, width)
                }
            
            case .albums(let albums):
            
                let album = albums[indexPath.row]
                
                if let collectionsVC = viewController as? CollectionsViewController {
                    
                    cell.delegate = self
                    cell.prepare(with: album, editing: collectionsVC.tableView.isEditing)
                    cell.details = (.album, width)
                }
            
            case .collections(kind: let kind, let collections):
            
                let collection = collections[indexPath.row]
                
                if let collectionsVC = viewController as? CollectionsViewController {
                    
                    cell.delegate = self
                    cell.prepare(with: collection, kind: kind, editing: collectionsVC.tableView.isEditing)
                    cell.details = (.artist, width)
                }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        operations[indexPath]?.cancel()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch context {
            
            case .songs(let items):
            
                guard let songsVC = viewController as? SongsViewController else { break }
            
                if songsVC.tableView.isEditing {
                    
                    let songs = [items[indexPath.row]]
                    notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: songs])
                
                } else {
                    
                    let song = items[indexPath.row]
                    
                    musicPlayer.play(items, startingFrom: song, from: songsVC, withTitle: "All Songs (Recents)", subtitle: "Starting from \(song.validTitle)", alertTitle: "Play")
                }
            
            default:
            
                guard let collectionsVC = viewController as? CollectionsViewController, let collection: MPMediaItemCollection = {
                    
                    switch context {
                        
                        case .songs: return nil
                        
                        case .playlists: return playlists[indexPath.row]
                        
                        default: return collections[indexPath.row]
                    }
                    
                }(), let identifier: String = {
                        
                    switch context {
                        
                        case .songs: return nil
                        
                        case .playlists: return "toPlaylist"
                        
                        case .albums: return "toAlbum"
                        
                        default: return "toArtist"
                    }
                    
                }() else { break }
                
                if collectionsVC.presented, let playlist = collection as? MPMediaPlaylist {
                    
                    if collectionsVC.selectedPlaylists.firstIndex(of: playlist) == nil, let presentedVC = collectionsVC.libraryVC?.parent as? PresentedContainerViewController {
                        
                        collectionsVC.selectedPlaylists.append(playlist)
                        presentedVC.prompt = collectionsVC.selectedPlaylists.count.formatted + " selected " + collectionsVC.selectedPlaylists.count.countText(for: .playlist)
                        presentedVC.updatePrompt(animated: false)
                        
                        if let selectedIndexPath = collectionsVC.tableView.indexPathsForVisibleRows?.first(where: { collectionsVC.getCollection(from: $0) == playlist }), let cell = collectionsVC.tableView.cellForRow(at: selectedIndexPath), cell.isSelected.inverted {

                            collectionsVC.tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
                        }
                    }

                    return
                    
                } else {
                    
                    if collectionsVC.tableView.isEditing {
                        
                        let items = collection.items
                        notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: items])
                        
                    } else {
                        
                        collectionsVC.performSegue(withIdentifier: identifier, sender: collection)
                    }
                }
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if let collectionsVC = viewController as? CollectionsViewController, collectionsVC.presented, let playlist = playlists.value(at: indexPath.row), let index = collectionsVC.selectedPlaylists.firstIndex(of: playlist), let presentedVC = collectionsVC.libraryVC?.parent as? PresentedContainerViewController {
            
            collectionsVC.selectedPlaylists.remove(at: index)
            presentedVC.prompt = collectionsVC.selectedPlaylists.count.formatted + " selected " + collectionsVC.selectedPlaylists.count.countText(for: .playlist)
            presentedVC.updatePrompt(animated: false)
            
            if let selectedIndexPath = collectionsVC.tableView.indexPathsForVisibleRows?.first(where: { collectionsVC.getCollection(from: $0) == playlist }), let indexPaths = collectionsVC.tableView.indexPathsForSelectedRows, Set(indexPaths).contains(selectedIndexPath) {
                
                collectionsVC.tableView.deselectRow(at: selectedIndexPath, animated: false)
            }
        }
    }
}

extension HeaderView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return size
    }
}

extension HeaderView: PlaylistCollectionCellDelegate {
    
    @objc func playThrough(in cell: PlaylistCollectionViewCell) {
        
        switch context {
            
            case .songs(let songs):
            
                guard let songsVC = viewController as? SongsViewController, let indexPath = collectionView.indexPath(for: cell) else { break }
                
                if songsVC.tableView.isEditing {
                    
                    let items = [songs[indexPath.row]]
                    notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: items])
                    
                } else {
                    
                    let items = [songs[indexPath.row]]
                    
                    musicPlayer.play(items, startingFrom: items.first, from: songsVC, withTitle: cell.nameLabel.text, alertTitle: "Play")
                }
            
            default:
            
                guard let collectionsVC = viewController as? CollectionsViewController, let indexPath = collectionView.indexPath(for: cell), let collection: MPMediaItemCollection = {
                    
                    switch context {
                        
                        case Context.songs(_): return nil
                        
                        case Context.playlists(let playlists): return playlists[indexPath.row]
                        
                        default: return collections[indexPath.row]
                    }
                    
                }() else { return }
            
                let songs = collection.items
                
                if collectionsVC.tableView.isEditing {
                    
                    notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: songs])
                    
                } else {
                    
                    guard !songs.isEmpty else { return }
                    
                    if songs.count > 1 {
                        
                        var array = [UIAlertAction]()
                        let canShuffleAlbums = songs.canShuffleAlbums
                        
                        let play = UIAlertAction.init(title: "Play", style: .default, handler: { _ in
                            
                            musicPlayer.play(songs, startingFrom: nil, from: collectionsVC, withTitle: cell.nameLabel.text, alertTitle: "Play")
                        })
                        
                        array.append(play)
                        
                        let shuffle = UIAlertAction.init(title: .shuffle(canShuffleAlbums ? .songs : .none), style: .default, handler: { _ in
                            
                            musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: collectionsVC, withTitle: cell.nameLabel.text, alertTitle: .shuffle(canShuffleAlbums ? .songs : .none))
                        })
                        
                        array.append(shuffle)
                        
                        if canShuffleAlbums {
                            
                            let shuffleAlbums = UIAlertAction.init(title: .shuffle(.albums), style: .default, handler: { _ in
                                
                                musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: collectionsVC, withTitle: cell.nameLabel.text, alertTitle: .shuffle(.albums))
                            })
                            
                            array.append(shuffleAlbums)
                        }
                        
                        collectionsVC.present(UIAlertController.withTitle(cell.nameLabel.text, message: nil, style: .actionSheet, actions: array + [.cancel()]), animated: true, completion: nil)
                        
                    } else {
                        
                        musicPlayer.play(songs, startingFrom: songs.first, from: collectionsVC, withTitle: cell.nameLabel.text, subtitle: nil, alertTitle: "Play")
                    }
                }
        }
    }
    
    func accessoryButtonTapped(in cell: PlaylistCollectionViewCell) {
        
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        
        var item: MPMediaEntity {
            
            switch context {
                
                case .albums(let collections): return collections[indexPath.row]
                
                case .playlists(let playlists): return playlists[indexPath.row]
                
                case .collections(kind: _, let collections): return collections[indexPath.row]
                
                case .songs(let songs): return songs[indexPath.row]
            }
        }
        
        guard let count: Int = {
            
            if let _ = item as? MPMediaItem {
                
                return 1
                
            } else if let collection = item as? MPMediaItemCollection {
                
                return collection.count
            }
            
            return nil
            
        }(), count > 0, let vc = viewController as? UIViewController & SingleItemActionable else { return }
        
        var actions = [SongAction.collect, .info(context: context.infoContext(at: indexPath)), .queue(name: cell.nameLabel.text, query: .init(filterPredicates: [.for(entityType, using: item)])), .newPlaylist, .addTo].map({ vc.singleItemAlertAction(for: $0, entity: entityType, using: item, from: vc) })
        
        actions.insert(vc.singleItemAlertAction(for: .show(title: cell.nameLabel.text, context: context.infoContext(at: indexPath)), entity: entityType, using: item, from: vc, useAlternateTitle: true), at: 1)
        
        if let item = item as? MPMediaItem, item.existsInLibrary.inverted {
            
            actions.insert(vc.singleItemAlertAction(for: .library, entity: .song, using: item, from: vc), at: 4)
        }
        
        vc.present(UIAlertController.withTitle(nil, message: cell.nameLabel.text, style: .actionSheet, actions: actions + [.cancel()] ), animated: true, completion: nil)
    }
}
