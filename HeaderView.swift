//
//  HeaderView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 11/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias HeaderButtonDetails = (type: HeaderButtonType, image: UIImage?, text: String?, action: () -> Void)
typealias HeaderPropertyDetails = (text: String, property: SecondaryCategory)

class HeaderView: UIView, InfoLoading {

    @IBOutlet var gradientView: GradientView!
    @IBOutlet var scrollView: MELScrollView!
    @IBOutlet var descriptionTextView: MELTextView!
    @IBOutlet var descriptionTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var scrollStackView: UIStackView!
    @IBOutlet var supplementaryCollectionView: MELCollectionView!
    @IBOutlet var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var collectionViewHeaderHeightConstraint: NSLayoutConstraint!
    @IBOutlet var artistView: UIView!
    @IBOutlet var artistButton: MELButton!
    @IBOutlet var actionsStackView: UIStackView!
    @IBOutlet var likedView: UIView!
    @IBOutlet var insertView: UIView!
    @IBOutlet var infoView: UIView!
    @IBOutlet var groupingView: UIView!
    @IBOutlet var sortView: UIView!
    @IBOutlet var likedStateButton: MELButton!
    @IBOutlet var tableHeaderContainer: UIView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var loadingEffectView: MELVisualEffectView!
    @IBOutlet var activityIndicatorView: MELActivityIndicatorView!
    @IBOutlet var sortActivityIndicatorView: MELActivityIndicatorView!
    @IBOutlet var sortBorderView: MELBorderView!
    @IBOutlet var buttonsStackView: UIStackView!
    @IBOutlet var addButton: MELButton!
    @IBOutlet var infoButton: MELButton!
    @IBOutlet var groupingButton: MELButton!
    @IBOutlet var sortButton: MELButton!
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
    
    lazy var entityType: EntityType = {
    
        switch context {
            
            case .albums(let collections): return .album
            
            case .collections(kind: let kind, let collections): return kind.entityType
        
            case .playlists(let playlists): return .playlist
        
            case .songs(let songs): return .song
        }
    }()
    var context = Context.playlists([])
    
    let width = screenWidth / 2.75
    lazy var size: CGSize = { return CGSize.init(width: width, height: width + FontManager.shared.collectionViewCellConstant - 0.001) }()
    
    @objc lazy var header = TableHeaderView.with(leftButtonVisible: true)
    
    var buttonDetails = [HeaderButtonDetails]()
    var propertyDetails = [HeaderPropertyDetails]()
    
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
    
    @objc var showGrouping = false {
        
        didSet {
            
            groupingView.isHidden = !showGrouping
            updateScrollStackView()
        }
    }
    
    @objc var showSort = true {
        
        didSet {
            
            sortView.isHidden = !showSort
            updateScrollStackView()
        }
    }
    
    @objc var showRecents = false {
        
        didSet {
            
            collectionViewHeightConstraint.constant = showRecents ? width + FontManager.shared.collectionViewCellConstant : 0
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
    
    @objc class var instance: HeaderView {
        
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
    
    weak var tapDelegate: HeaderViewTextViewTapDelegate?
    var textViewMinimised = true {
        
        didSet {
            
            descriptionTextView.textContainer.maximumNumberOfLines = textViewMinimised ? 2 : 0
        }
    }
    
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
        updateSpacing(self)
        
        supplementaryCollectionView.register(.init(nibName: "HeaderButtonsCell", bundle: nil), forCellWithReuseIdentifier: "button")
        supplementaryCollectionView.register(UINib.init(nibName: "EntityPropertyCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        supplementaryCollectionView.delegate = self
        supplementaryCollectionView.dataSource = self
        
        descriptionTextView.textContainer.maximumNumberOfLines = textViewMinimised ? 2 : 0
        descriptionTextView.textContainer.lineBreakMode = .byTruncatingTail
        
        let gr = UITapGestureRecognizer.init(target: self, action: #selector(changeTextView))
        descriptionTextView.addGestureRecognizer(gr)
        
        notifier.addObserver(self, selector: #selector(updateSpacing), name: .lineHeightsCalculated, object: nil)
        notifier.addObserver(self, selector: #selector(updateCell(_:)), name: .playlistSelected, object: nil)
    }
    
    @objc func changeTextView() {
        
        tapDelegate?.textViewTapped()
    }
    
    func updateScrollStackView() {
        
        scrollStackView.layoutMargins.left = showArtistView.inverted && showLoved.inverted && showInfo.inverted && showInsert.inverted && showGrouping.inverted && showSort.inverted ? 12 : 0
        buttonsStackView.layoutMargins.left = showGrouping ? 0 : (showLoved || showInfo || showInsert || showArtistView || showSort) ? 12 : 0
    }
    
    @objc func updateSpacing(_ sender: Any) {
        
        collectionViewHeightConstraint.constant = showRecents ? width + FontManager.shared.collectionViewCellConstant : 0
        collectionViewHeaderHeightConstraint.constant = showRecents ? .textHeaderHeight : 0
        
        if sender is Notification, showRecents {
            
            notifier.post(name: .headerHeightCalculated, object: nil)
        }
    }
    
    func updateSortActivityIndicator(to state: VisibilityState) {
        
        sortBorderView.isHidden = state == .visible
        sortButton.imageView?.alpha = state == .visible ? 0 : 1
        
        switch state {
            
            case .hidden: sortActivityIndicatorView.stopAnimating()
            
            case .visible: sortActivityIndicatorView.startAnimating()
        }
    }
    
    @objc func updateCell(_ sender: Notification) {
        
        guard let location = sender.userInfo?["location"] as? PlaylistModificationLocation, location != .header, let collectionsVC = viewController as? CollectionsViewController, collectionsVC.presented, let type = sender.userInfo?["type"] as? CellSelectionType, let playlist = sender.userInfo?["playlist"] as? MPMediaPlaylist else { return }
        
        switch type {
            
            case .select:
            
                if let selectedIndexPath = collectionView.indexPathsForVisibleItems.first(where: { playlists.value(at: $0.row) == playlist }), let cell = collectionView.cellForItem(at: selectedIndexPath), cell.isSelected.inverted {
                    
                    collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: [])
                }
            
            case .deselect:
            
                if let selectedIndexPath = collectionView.indexPathsForVisibleItems.first(where: { playlists.value(at: $0.row) == playlist }), let indexPaths = collectionView.indexPathsForSelectedItems, Set(indexPaths).contains(selectedIndexPath) {
                    
                    collectionView.deselectItem(at: selectedIndexPath, animated: false)
                }
        }
    }
    
//    override func layoutSubviews() {
//
//            super.layoutSubviews()
//    }
}

extension HeaderView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if collectionView == supplementaryCollectionView {
            
            return 2
            
        } else {
            
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == supplementaryCollectionView {
            
            if section == 0 {
                
                return buttonDetails.count
                
            } else {
                
                return propertyDetails.count
            }
        }
        
        switch context {
            
            case .songs(let items): return items.count
            
            case .albums(let collections): return collections.count
            
            case .collections(kind: _, let collections): return collections.count
            
            case .playlists(let playlists): return playlists.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard collectionView == self.collectionView, let cell = cell as? PlaylistCollectionViewCell else { return }
        
        switch context {
            
            case .songs(let songs):
            
                let song = songs[indexPath.row]
            
                updateImageView(using: song, in: cell, indexPath: indexPath, reusableView: collectionView)
            
            case .playlists(let playlists):
            
                let playlist = playlists[indexPath.row]
                
                if let collectionsVC = viewController as? CollectionsViewController, collectionsVC.presented {
                    
                    if Set(collectionsVC.selectedPlaylists).contains(playlist), cell.isSelected.inverted {
                        
                        cell.isSelected = true
                        
                    } else if Set(collectionsVC.selectedPlaylists).contains(playlist).inverted, cell.isSelected {
                        
                        cell.isSelected = false
                    }
                }
                
                updateImageView(using: playlist, entityType: .playlist, in: cell, indexPath: indexPath, reusableView: collectionView, overridable: viewController as? OnlineOverridable)
            
            case .albums(let albums):
            
                let album = albums[indexPath.row]
            
                updateImageView(using: album, entityType: .album, in: cell, indexPath: indexPath, reusableView: collectionView)
            
            case .collections(kind: let kind, let collections):
            
                let collection = collections[indexPath.row]
                
                updateImageView(using: collection, entityType: kind.entityType, in: cell, indexPath: indexPath, reusableView: collectionView)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == supplementaryCollectionView {
            
            if indexPath.section == 0 {
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "button", for: indexPath) as! HeaderButtonsCollectionViewCell
                
                let details = buttonDetails[indexPath.item]
                cell.prepare(with: details.image, text: details.text, index: indexPath.item)
                
                return cell
                
            } else {
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! EntityPropertyCollectionViewCell
                
                let details = propertyDetails[indexPath.item]
                cell.context = .header
                cell.prepare(with: {
                    
                    switch details.property {
                        
                        case .copyright: return nil
                        
                        default: return details.property.largeImage
                    }
                    
                }(), text: details.text, property: details.property)
                
                return cell
            }
        }
        
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
                    cell.details = (.playlist, width)
                }
            
            case .collections(kind: let kind, let collections):
            
                let collection = collections[indexPath.row]
                
                if let collectionsVC = viewController as? CollectionsViewController {
                    
                    cell.delegate = self
                    cell.prepare(with: collection, kind: kind, editing: collectionsVC.tableView.isEditing)
                    cell.details = (.playlist, width)
                }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        
        if collectionView == supplementaryCollectionView {
            
            return indexPath.section == 0
        }
        
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if collectionView == supplementaryCollectionView {
            
            return
        }
        
        operations[indexPath]?.cancel()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == supplementaryCollectionView, indexPath.section == 0 {
            
            buttonDetails[indexPath.item].action()
            
            collectionView.deselectItem(at: indexPath, animated: true)
            
            return
        }
        
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
                    
                    if collectionsVC.selectedPlaylists.firstIndex(of: playlist) == nil/*, let _ = collectionsVC.libraryVC?.parent as? PresentedContainerViewController*/ {
                        
                        collectionsVC.selectedPlaylists.append(playlist)
                        collectionsVC.addButton.setTitle("Add (\(collectionsVC.selectedPlaylists.count.formatted))", for: .normal)
                        
                        notifier.post(name: .playlistSelected, object: nil, userInfo: ["playlist": playlist, "type": CellSelectionType.select, "location": PlaylistModificationLocation.header])
                        
//                        if let selectedIndexPath = collectionsVC.tableView.indexPathsForVisibleRows?.first(where: { collectionsVC.getCollection(from: $0) == playlist }), let cell = collectionsVC.tableView.cellForRow(at: selectedIndexPath), cell.isSelected.inverted {
//
//                            collectionsVC.tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
//                        }
//
//                        if let selectedIndexPath = collectionsVC.lastUsedCollectionView.indexPathsForVisibleItems.first(where: { collectionsVC.lastUsedController?.playlists.value(at: $0.row) == playlist }), let cell = collectionsVC.lastUsedCollectionView.cellForItem(at: selectedIndexPath), cell.isSelected.inverted {
//
//                            collectionsVC.lastUsedCollectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: [])
//                        }
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
        
        if collectionView == self.collectionView, let collectionsVC = viewController as? CollectionsViewController, collectionsVC.presented, let playlist = playlists.value(at: indexPath.row), let index = collectionsVC.selectedPlaylists.firstIndex(of: playlist)/*, let _ = collectionsVC.libraryVC?.parent as? PresentedContainerViewController*/ {
            
            collectionsVC.selectedPlaylists.remove(at: index)
            collectionsVC.addButton.setTitle("Add (\(collectionsVC.selectedPlaylists.count.formatted))", for: .normal)
            
            notifier.post(name: .playlistSelected, object: nil, userInfo: ["playlist": playlist, "type": CellSelectionType.deselect, "location": PlaylistModificationLocation.header])
            
//            if let selectedIndexPath = collectionsVC.tableView.indexPathsForVisibleRows?.first(where: { collectionsVC.getCollection(from: $0) == playlist }), let indexPaths = collectionsVC.tableView.indexPathsForSelectedRows, Set(indexPaths).contains(selectedIndexPath) {
//
//                collectionsVC.tableView.deselectRow(at: selectedIndexPath, animated: false)
//            }
//
//            if let selectedIndexPath = collectionsVC.lastUsedCollectionView.indexPathsForVisibleItems.first(where: { collectionsVC.lastUsedController?.playlists.value(at: $0.row) == playlist }), let indexPaths = collectionsVC.lastUsedCollectionView.indexPathsForSelectedItems, Set(indexPaths).contains(selectedIndexPath) {
//
//                collectionsVC.lastUsedCollectionView.deselectItem(at: selectedIndexPath, animated: false)
//            }
        }
    }
}

extension HeaderView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView == self.collectionView {
        
            return size
        
        } else {
            
            if indexPath.section == 0 {
                
                let details = buttonDetails[indexPath.item]
            
                return .init(width: (indexPath.item == 0 ? 12 : 4) + 24 + (details.text == nil ? 0 : 4) + FontManager.shared.width(for: details.text, style: .body, weight: .semibold) + 16, height: collectionView.frame.height)
                
            } else {
                
                let details = propertyDetails[indexPath.item]
                
                return .init(width: (details.property == .copyright ? 0 : details.property.largeSize) + FontManager.shared.width(for: details.text, style: .body), height: collectionView.frame.height)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        switch section {
            
            case 1: return 16
            
            default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        switch section {
            
            case 1: return 16
            
            default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        switch section {
            
            case 0 where collectionView == self.collectionView: return .init(top: 0, left: 4, bottom: 0, right: 8)
            
            case 1: return .init(top: 0, left: 4, bottom: 0, right: 16)
            
            default: return .zero
        }
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
                        
                        let canShuffleAlbums = songs.canShuffleAlbums
                        
                        var actions = [AlertAction.init(info: AlertInfo.init(title: "Play", accessoryType: .none), requiresDismissalFirst: true, handler: {
                            
                            musicPlayer.play(songs, startingFrom: nil, from: collectionsVC, withTitle: cell.nameLabel.text, alertTitle: "Play")
                            
                        }), AlertAction.init(info: AlertInfo.init(title: .shuffle(canShuffleAlbums ? .songs : .none), accessoryType: .none), requiresDismissalFirst: true, handler: {
                            
                            musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: collectionsVC, withTitle: cell.nameLabel.text, alertTitle: .shuffle(canShuffleAlbums ? .songs : .none))
                        })]
                        
                        if canShuffleAlbums {
                            
                            actions.append(AlertAction.init(info: AlertInfo.init(title: .shuffle(.albums), accessoryType: .none), requiresDismissalFirst: true, handler: {
                                
                                musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: collectionsVC, withTitle: cell.nameLabel.text,  alertTitle: .shuffle(.albums))
                            }))
                        }
                        
                        collectionsVC.showAlert(title: cell.nameLabel.text, context: .other, with: actions)
                        
                    } else {
                        
                        musicPlayer.play(songs, startingFrom: songs.first, from: collectionsVC, withTitle: cell.nameLabel.text, subtitle: nil, alertTitle: "Play")
                    }
                }
        }
    }
    
    func accessoryButtonTapped(in cell: PlaylistCollectionViewCell) {
        
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        
        var entity: MPMediaEntity {
            
            switch context {
                
                case .albums(let collections): return collections[indexPath.row]
                
                case .playlists(let playlists): return playlists[indexPath.row]
                
                case .collections(kind: _, let collections): return collections[indexPath.row]
                
                case .songs(let songs): return songs[indexPath.row]
            }
        }
        
        guard let count: Int = {
            
            if let _ = entity as? MPMediaItem {
                
                return 1
                
            } else if let collection = entity as? MPMediaItemCollection {
                
                return collection.count
            }
            
            return nil
            
        }(), count > 0, let vc = viewController as? UIViewController & SingleItemActionable else { return }
        
        var actions = [
            SongAction.collect,
            .info(context: context.infoContext(at: indexPath)),
            .queue(name: cell.nameLabel.text, query: .init(filterPredicates: [.for(entityType, using: entity)])),
            .show(title: cell.nameLabel.text, context: context.infoContext(at: indexPath), canDisplayInLibrary: true),
            .newPlaylist,
            .addTo/*,
            .search(unwinder: nil)
        */].map({ vc.singleItemAlertAction(for: $0, entityType: entityType, using: entity, from: vc) })
        
//        actions.insert(vc.singleItemAlertAction(for: .show(title: cell.nameLabel.text, context: context.infoContext(at: indexPath), canDisplayInLibrary: true), entity: entityType, using: item, from: vc, useAlternateTitle: true), at: 1)
        
        if let item = entity as? MPMediaItem, item.existsInLibrary.inverted {
            
            actions.append(vc.singleItemAlertAction(for: .library, entityType: .song, using: item, from: vc))
        }
        
        vc.showAlert(title: cell.nameLabel.text, with: actions)
    }
}

protocol HeaderViewTextViewTapDelegate: class {
    
    func textViewTapped()
}
