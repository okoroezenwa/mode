//
//  ItemsContainerViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 08/01/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class EntityItemsViewController: UIViewController, BackgroundHideable, ArtworkModifying, Contained, OptionsContaining, Peekable, ArtistTransitionable, AlbumArtistTransitionable, Navigatable, ChildContaining, HighlightedEntityContaining, CentreViewDisplaying {

    @IBOutlet var containerView: UIView!
    @IBOutlet var titleEffectView: MELVisualEffectView!
    @IBOutlet var titleLabel: MELLabel!
    @IBOutlet var titleEffectViewHeightConstraint: NSLayoutConstraint!
    
    enum EntityContainerType {
        
        case playlist, collection, album
        
        var entityType: EntityType {
            
            switch self {
                
                case .playlist: return .playlist
                
                case .album: return .album
                
                case .collection: return .artist
            }
        }
    }
    enum StartPoint: Int {
        
        case albums, songs
        
        var title: String {
            
            switch self {
                
                case .albums: return "albums"
                
                case .songs: return "songs"
            }
        }
    }
    
    var options: LibraryOptions { return LibraryOptions.init(fromVC: activeChildViewController, configuration: .collection, context: contextForContainerType()) }
    
    @objc var collection: MPMediaItemCollection?
    var entityContainerType = EntityContainerType.playlist
    var kind = AlbumBasedCollectionKind.artist
    #warning("Understand why I use another property that mirrors this instead of changing it directly")
    var startPoint = StartPoint(rawValue: artistItemsStartingPoint) ?? .songs
    lazy var currentStartPoint = startPoint
    @objc var query: MPMediaQuery? {
        
        didSet {
            
            if !firstLaunch {
                
                if let updateable = activeChildViewController as? QueryUpdateable {
                    
                    updateable.updateWithQuery()
                }
            }
        }
    }
    @objc var needsDismissal = false
    @objc var artwork: UIImage?
    var topArtwork: UIImage? {
        
        didSet {
            
            smallArtwork = topArtwork?.at(.init(width: smallArtworkHeight, height: smallArtworkHeight))
        }
    }
    var smallArtwork: UIImage?
    var oldArtwork: UIImage?
    var buttonDetails: NavigationBarButtonDetails {
        
        get { (.actions, query?.items?.isEmpty != false) }
        
        set { }
    }
    var artworkDetails: NavigationBarArtworkDetails? {
        
        get { return (topArtwork != nil ? EntityArtworkType.image(navBarArtworkMode == .large ? topArtwork : smallArtwork) : .empty(entityType: collection?.granularEntityType(basedOn: entityTypeForContainerType()) ?? .song, size: navBarArtworkMode == .large ? .regular : .small), (listsCornerRadius ?? cornerRadius).radiusDetails(for: entityTypeForContainerType(), width: navBarArtworkMode == .large ? inset - 18 : smallArtworkHeight, globalRadiusType: cornerRadius)) }
        
        set { }
    }
    var smallArtworkHeight: CGFloat { return (FontManager.shared.heightsDictionary[.heading] ?? FontManager.shared.height(for: .heading)) - 4 }
    @objc weak var peeker: UIViewController? {
        
        didSet {
            
            if peeker == nil, let arrangeable = activeChildViewController as? FullySortable, arrangeable.operation?.isFinished == true, let index = arrangeable.highlightedIndex {
             
                arrangeable.unhighlightRow(with: arrangeable.relevantIndexPath(using: index))
            }
        }
    }
    var highlightedEntities: (song: MPMediaItem?, collection: MPMediaItemCollection?)?
    @objc var backLabelText: String?
    @objc lazy var ascending: Bool = {
        
        let details = EntityType.collectionEntityDetails(for: location(for: .songs))
        
        return collectionSortOrders?[details.type.title(matchingPropertyName: true) + details.startPoint.title] ?? true
    }()
    lazy var sortCriteria: SortCriteria = {
        
        let details = EntityType.collectionEntityDetails(for: location(for: .songs))
        
        guard let index = collectionSortCategories?[details.type.title(matchingPropertyName: true) + details.startPoint.title], let criteria = SortCriteria(rawValue: index), SortCriteria.applicableSortCriteria(for: location(for: .songs)).contains(criteria) else { return .standard }
        
        return criteria
    }()
    @objc lazy var albumAscending: Bool = {
        
        let details = EntityType.collectionEntityDetails(for: location(for: .albums))
        
        return collectionSortOrders?[details.type.title(matchingPropertyName: true) + details.startPoint.title] ?? true
    }()
    lazy var albumSortCriteria: SortCriteria = {
        
        let details = EntityType.collectionEntityDetails(for: location(for: .albums))
        
        guard let index = collectionSortCategories?[details.type.title(matchingPropertyName: true) + details.startPoint.title], let criteria = SortCriteria(rawValue: index), SortCriteria.applicableSortCriteria(for: location(for: .albums)).contains(criteria) else { return .standard }
        
        return criteria
    }()
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var artistQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    @objc lazy var songCount = 0
    @objc lazy var albumCount = 0
    @objc var firstLaunch = true
    @objc var lifetimeObservers = Set<NSObject>()
    @objc var transientObservers = Set<NSObject>()
    var changeActiveVC = true
    
    @objc var activeChildViewController: UIViewController? {
        
        didSet {
            
            guard changeActiveVC, !firstLaunch, oldValue != activeChildViewController else { return }
            
            changeActiveViewControllerFrom(oldValue)
        }
    }
    
    var viewControllerSnapshot: UIView? { didSet { oldValue?.removeFromSuperview() } }
    
    @objc lazy var temporaryImageView: UIImageView = {
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    @objc lazy var temporaryEffectView = MELVisualEffectView()
    var inset: CGFloat { return VisualEffectNavigationBar.Location.entity.inset }
    lazy var preferredTitle: String? = title
    var artistSongsVCLoaded = false
    var artistAlbumsVCLoaded = false
    var playlistItemsVCLoaded = false
    var albumItemsVCLoaded = false
    
    var centreViewGiantImage: UIImage?
    var centreViewTitleLabelText: String?
    var centreViewSubtitleLabelText: String?
    var centreViewLabelsImage: UIImage?
    var currentCentreView = CentreView.CurrentView.none
    var centreView: CentreView? {
        
        get { container?.centreView }
        
        set { }
    }
    var passthroughFrames: [CGRect]? {
        
        if let vc = activeChildViewController as? SupplementaryHeaderInfoLoading & TableViewContaining & UIViewController, let tableView = vc.tableView, let header = tableView.tableHeaderView as? HeaderView, let container = appDelegate.window?.rootViewController as? ContainerViewController {
            
            let first = tableView.convert(header.frame, to: vc.view)
            let second = containerView.convert(first, to: container.centreView)
            
            return [second]
        }
        
        return nil
    }
    
    @objc lazy var artistSongsViewController: ArtistSongsViewController = {
        
        let vc = entityStoryboard.instantiateViewController(withIdentifier: "artistSongsVC") as!  ArtistSongsViewController
        artistSongsVCLoaded = true
        vc.ascending = ascending
        vc.staticSortCriteria = sortCriteria
        return vc
    }()
    
    @objc lazy var artistAlbumsViewController: ArtistAlbumsViewController = {
        
        let vc = entityStoryboard.instantiateViewController(withIdentifier: "artistAlbumsVC") as!  ArtistAlbumsViewController
        artistAlbumsVCLoaded = true
        vc.ascending = albumAscending
        vc.staticSortCriteria = albumSortCriteria
        return vc
    }()
    
    @objc lazy var playlistItemsViewController: PlaylistItemsViewController = {
        
        let vc = entityStoryboard.instantiateViewController(withIdentifier: "playlistItems") as!  PlaylistItemsViewController
        playlistItemsVCLoaded = true
        vc.ascending = ascending
        vc.staticSortCriteria = sortCriteria
        return vc
    }()
    
    @objc lazy var albumItemsViewController: AlbumItemsViewController = {
        
        let vc = entityStoryboard.instantiateViewController(withIdentifier: "albumItems") as! AlbumItemsViewController
        albumItemsVCLoaded = true
        vc.ascending = ascending
        vc.staticSortCriteria = sortCriteria
        return vc
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        activeChildViewController = {
            
            switch entityContainerType {
                
                case .album: return albumItemsViewController
                    
                case .collection: return startPoint == .songs ? artistSongsViewController : artistAlbumsViewController
                    
                case .playlist: return playlistItemsViewController
            }
        }()
        
//        if entityContainerType == .playlist {
//
//            container?.centreView.title = "Nothing Here"
//            container?.centreView.subtitle = "Insert a song from your library"
//        }
        
        updateActiveViewController()
        prepareLifetimeObservers()
        
        notifier.addObserver(self, selector: #selector(updateCornersAndShadows), name: .cornerRadiusChanged, object: nil)

        updateCornersAndShadows()
        
        let item: MPMediaItem? = showiCloudItems ? collection?.representativeItem : collection?.items.first(where: { !$0.isCloudItem && $0.actualArtwork != nil })
        
        let size = CGSize.init(width: 100, height: 100)
        let collectionImage = collection?.customArtwork(for: entityTypeForContainerType())?.scaled(to: size, by: 2)
        let image = item?.actualArtwork?.image(at: size)
        
        let shouldUseCollectionArtwork: Bool = {
            
            switch entityContainerType {
                
                case .collection: return useArtistCustomBackground
                
                case .playlist: return usePlaylistCustomBackground
                
                case .album: return true
            }
        }()
        
        artwork = (shouldUseCollectionArtwork ? collectionImage ?? image : image)?.at(.init(width: 20, height: 20))
        topArtwork = collectionImage ?? image //?? noImage
        
        if let _ = peeker, let container = appDelegate.window?.rootViewController as? ContainerViewController {
            
            updateEffectView(to: .visible)
            
            ArtworkManager.shared.currentlyPeeking = self
            
            UIView.transition(with: container.imageView, duration: 0.5, options: .transitionCrossDissolve, animations: { container.imageView.image = self.artworkType.image }, completion: nil)
            
            temporaryImageView.image = artworkType.image
        }
        
        firstLaunch = false
    }
    
    func location(for startPoint: StartPoint) -> Location {
        
        switch entityContainerType {
            
            case .playlist: return .playlist
            
            case .album: return .album
            
            case .collection: return .collection(kind: kind, point: startPoint)
        }
    }
    
    @objc func updateSections(_ gr: UIPanGestureRecognizer) {
        
        guard let tableDelegate = (activeChildViewController as? TableViewContainer)?.tableDelegate else { return }
        
            switch gr.state {
                
            case .began: tableDelegate.viewSections()
                
            case .changed:
                
                guard let sectionVC = (activeChildViewController as? IndexContaining)?.sectionIndexViewController else { return }
                
                sectionVC.changeSection(gr)
                
            case .ended, .failed/*, .cancelled*/: (activeChildViewController as? IndexContaining)?.sectionIndexViewController?.dismissVC()
                
            default: break
        }
    }
    
    func updateEffectView(to state: VisibilityState) {
        
        titleEffectView.isHidden = state == .hidden
        titleEffectViewHeightConstraint.priority = state == .hidden ? .init(rawValue: 999) : .defaultLow
        titleLabel.text = title
    }
    
    @objc func updateCornersAndShadows() {
        
        guard container?.activeViewController?.topViewController == self, let artworkImageView = container?.visualEffectNavigationBar.artworkImageView, let artworkImageViewContainer = container?.visualEffectNavigationBar.artworkContainer else { return }

        (listsCornerRadius ?? cornerRadius).updateCornerRadius(on: artworkImageView.layer, width: artworkImageView.bounds.width, entityType: entityTypeForContainerType(), globalRadiusType: cornerRadius)

        UniversalMethods.addShadow(to: artworkImageViewContainer, radius: 8, opacity: 0.35, shouldRasterise: true)
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func showOptions() {
        
        guard let context = contextForContainerType() else { return }
        
        Transitioner.shared.showInfo(from: self, with: context)
    }
    
    @objc func popToRoot(_ sender: UILongPressGestureRecognizer) {
        
        guard sender.state == .began else { return }
        
        _ = navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        prepareTransientObservers()
        
        container?.currentModifier = self
        setCurrentOptions()
        
        container?.visualEffectNavigationBar.entityTypeLabel.superview?.isHidden = false
        container?.visualEffectNavigationBar.entityTypeLabel.text = entityTypeForContainerType().title().capitalized
        
        if needsDismissal {
            
            if let vc = presentedViewController {
                
                vc.dismiss(animated: false, completion: nil)
            }
            
            let banner = Banner.init(title: "This artist has no offline music", subtitle: nil, image: nil, backgroundColor: .red, didTapBlock: nil)
            banner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
            banner.show(duration: 1.5)
            
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    func setCurrentOptions() {
        
        container?.currentOptionsContaining = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        notifier.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notifier.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
        unregisterAll(from: transientObservers)
    }
    
    @objc func prepareTransientObservers() {
        
        transientObservers.insert(notifier.addObserver(forName: .scrollCurrentViewToTop, object: navigationController, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            (weakSelf.activeChildViewController as? TopScrollable)?.scrollToTop()
            
        }) as! NSObject)
    }
    
    @objc func prepareLifetimeObservers() {
        
        let iCloudObserver = notifier.addObserver(forName: .iCloudVisibilityChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            if showiCloudItems {
                
                weakSelf.query?.removeFilterPredicate(.offline)
                
            } else {
                
                weakSelf.query?.addFilterPredicate(.offline)
            }
            
            guard weakSelf.query?.items?.isEmpty == false else {
                
                weakSelf.needsDismissal = true
                return
            }
            
            if let updateable = weakSelf.activeChildViewController as? QueryUpdateable {
                
                updateable.updateWithQuery()
                
                if weakSelf.artistSongsVCLoaded, weakSelf.activeChildViewController != weakSelf.artistSongsViewController {

                    weakSelf.artistSongsViewController.currentArtistQuery = weakSelf.query?.copy() as? MPMediaQuery
                    weakSelf.artistSongsViewController.updateWithQuery()
                    weakSelf.artistSongsViewController.needsToUpdateHeaderView = true

                } else if weakSelf.artistAlbumsVCLoaded, weakSelf.activeChildViewController != weakSelf.artistAlbumsViewController {

                    weakSelf.artistAlbumsViewController.currentArtistQuery = weakSelf.query?.copy() as? MPMediaQuery
                    weakSelf.artistAlbumsViewController.updateWithQuery()
                    weakSelf.artistAlbumsViewController.needsToUpdateHeaderView = true
                }
            }
        })
        
        lifetimeObservers.insert(iCloudObserver as! NSObject)
        
        let libraryObserver = notifier.addObserver(forName: .libraryUpdated, object: appDelegate, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self, weakSelf.query?.collections?.isEmpty == false else {
                
                if let vc = self?.presentedViewController {
                    
                    vc.dismiss(animated: false, completion: nil)
                }
                
                let banner = Banner.init(title: "This entity is no longer in your library", subtitle: nil, image: nil, backgroundColor: .red, didTapBlock: nil)
                banner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
                banner.show(duration: 1.5)
                
                _ = self?.navigationController?.popViewController(animated: true)
                
                return
            }
            
            if let updateable = weakSelf.activeChildViewController as? QueryUpdateable {
                
                updateable.updateWithQuery()
            }
        })
        
        lifetimeObservers.insert(libraryObserver as! NSObject)
        
        let settingsObserver = notifier.addObserver(forName: .settingsDismissed, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            if weakSelf.needsDismissal {
                
                if let vc = weakSelf.presentedViewController {
                    
                    vc.dismiss(animated: false, completion: nil)
                }
                
                let banner = Banner.init(title: "This artist has no offline music", subtitle: nil, image: nil, backgroundColor: .red, didTapBlock: nil)
                banner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
                banner.show(weakSelf.view, duration: 1.5)
                
                _ = weakSelf.navigationController?.popViewController(animated: true)
            }
        })
        
        lifetimeObservers.insert(settingsObserver as! NSObject)
        
        if peeker != nil {
            
            lifetimeObservers.insert(notifier.addObserver(forName: .MPMusicPlayerControllerNowPlayingItemDidChange, object: /*musicPlayer*/nil, queue: nil, using: { [weak self] _ in
                
                guard let weakSelf = self else { return }
                
                weakSelf.oldArtwork = ArtworkManager.shared.activeContainer?.modifier?.artworkType.image
                
            }) as! NSObject)
        }
    }
    
    @objc func getCurrentQuery() -> MPMediaQuery? {
        
        guard let collection = collection else { return nil }
        
        let query: MPMediaQuery = {
            
            let entity = entityTypeForContainerType()
            
            let query = MPMediaQuery.init(filterPredicates: [.for(entity, using: collection)])
            query.groupingType = groupingTypeForContainerType()
            
            if !showiCloudItems {
                
                query.addFilterPredicate(.offline)
            }
            
            return query
        }()
        
        guard !(query.items ?? []).isEmpty else { return nil }
        
        return query
    }
    
    @objc func verifyValidity() -> MPMediaQuery? {
        
        guard let collection = collection else { return nil }
        
        let query: MPMediaQuery = {
            
            let entity = entityTypeForContainerType()
            let query = MPMediaQuery.init(filterPredicates: [.for(entity, using: collection)])
            query.groupingType = groupingTypeForContainerType()
            
            return query
        }()
        
        guard !(query.collections ?? []).isEmpty else { return nil }
        
        return query
    }
    
    @objc func groupingTypeForContainerType() -> MPMediaGrouping {
        
        switch entityContainerType {
            
            case .album, .collection: return .album
            
            case .playlist: return .playlist
        }
    }
    
    func entityTypeForContainerType() -> EntityType {
        
        switch entityContainerType {
            
            case .playlist: return .playlist
            
            case .album: return .album
            
            case .collection:
            
                switch kind {
                    
                    case .artist: return .artist
                    
                    case .genre: return .genre
                    
                    case .composer: return .composer
                    
                    case .albumArtist: return .albumArtist
                }
        }
    }
    
    func contextForContainerType() -> InfoViewController.Context? {
        
        guard let collection = collection else { return nil }
        
        switch entityContainerType {
            
            case .album: return .album(at: 0, within: [collection])
            
            case .collection: return .collection(kind: kind, at: 0, within: [collection])
            
            case .playlist:
                
                guard let playlist = collection as? MPMediaPlaylist else { return nil }
                
                return .playlist(at: 0, within: [playlist])
        }
    }
    
    @objc func showGroupings() {
        
        let albumCount = query?.collections?.count ?? 0
        let songCount = query?.items?.count ?? 0
        
        let songs = AlertAction.init(title: "Songs", subtitle: songCount.fullCountText(for: .song), style: .default, accessoryType: .check({ [weak self] in self?.activeChildViewController == self?.artistSongsViewController }), image: EntityType.song.images.size23, requiresDismissalFirst: false, handler: { [weak self] in
            
            self?.currentStartPoint = .songs
            self?.activeChildViewController = self?.artistSongsViewController
        })
        
        let albums = AlertAction.init(title: "Albums", subtitle: albumCount.fullCountText(for: .album), style: .default, accessoryType: .check({ [weak self] in self?.activeChildViewController == self?.artistAlbumsViewController }), image: EntityType.album.images.size23, requiresDismissalFirst: false, handler: { [weak self] in
                                        
            self?.currentStartPoint = .albums
            self?.activeChildViewController = self?.artistAlbumsViewController
        })
        
        showAlert(title: title, subtitle: "Group by...", topHeaderMode: .themedImage(name: "Grouping22", height: 22), with: songs, albums)
    }
    
    @IBAction func dismissVC() {
        
        _ = navigationController?.popViewController(animated: true)
    }
    
    @objc @discardableResult func performTransition(to vc: UIViewController, sender: Any?, perform3DTouchActions: Bool = false) -> UIViewController? {
        
        if let presentedVC = vc as? PresentedContainerViewController, let context = contextForContainerType() {
            
            presentedVC.context = .info
            presentedVC.optionsContext = context
        }
        
        return nil
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "EVC going away...").show(for: 0.3)
        }
        
        if let _ = peeker, let container = appDelegate.window?.rootViewController as? ContainerViewController {
            
            ArtworkManager.shared.currentlyPeeking = nil
            UIView.transition(with: container.imageView, duration: 0.5, options: .transitionCrossDissolve, animations: { container.imageView.image = ArtworkManager.shared.activeContainer?.modifier?.artworkType.image/*self.oldArtwork*/ }, completion: nil)
        }
        
        unregisterAll(from: lifetimeObservers)
        notifier.removeObserver(self)
    }
}

extension EntityItemsViewController: EntityVerifiable {
    
    var entityTitle: String {
        
        guard let query = query else { return .unknownEntity }
        
        switch query.groupingType {
            
            case .album: return query.collections?.first?.representativeItem?.albumTitle ??? .untitledAlbum
                
            case .artist: return query.collections?.first?.representativeItem?.artist ??? .unknownArtist
                
            case .composer: return query.collections?.first?.representativeItem?.composer ??? .unknownComposer
                
            case .genre: return query.collections?.first?.representativeItem?.genre ??? .untitledGenre
                
            case .playlist: return (query.collections?.first as? MPMediaPlaylist)?.name ??? .untitledPlaylist
                
            case .title: return query.items?.first?.title ??? .untitledSong
                
            default: return .unknownEntity
        }
    }
    
    var songs: [MPMediaItem] {
        
        switch entityContainerType {
            
            case .album: return albumItemsViewController.songs.isEmpty ? (query?.items ?? []) : albumItemsViewController.songs
            
            case .collection:
                
                if artistSongsVCLoaded, activeChildViewController == artistSongsViewController {
                    
                    return artistSongsViewController.songs.isEmpty ? (query?.items ?? []) : artistSongsViewController.songs
                    
                } else if artistAlbumsVCLoaded, activeChildViewController == artistAlbumsViewController {
                    
                    return artistAlbumsViewController.albums.isEmpty ? (query?.items ?? []) : artistAlbumsViewController.albums.reduce([], { $0 + $1.items })
                }
                
                return []
            
            case .playlist: return playlistItemsViewController.songs.isEmpty ? (query?.items ?? []) : playlistItemsViewController.songs
        }
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        
        let info = UIPreviewAction(title: "Get Info", style: .default, handler: { [weak self] _, _ in
            
            guard let weakSelf = self, let peeker = weakSelf.peeker, let context = weakSelf.contextForContainerType() else { return }
            
            Transitioner.shared.showInfo(from: peeker, with: context)
        })
        
        guard (query?.items ?? []).isEmpty.inverted else { return [info] }
        
        let songs = self.songs
        let canShuffleAlbums = songs.canShuffleAlbums
        
        let play = UIPreviewAction(title: "Play", style: .default, handler: { [weak self] _, _ in
            
            guard let weakSelf = self, let peeker = weakSelf.peeker else { return }
            
            musicPlayer.play(songs, startingFrom: nil, from: peeker, withTitle: weakSelf.title, alertTitle: "Play")
        })
        
        let shuffle = UIPreviewAction.init(title: .shuffle() + (canShuffleAlbums ? " Songs" : ""), style: .default, handler: { [weak self] _, _ in
            
            guard let weakSelf = self, let peeker = weakSelf.peeker else { return }
            
            musicPlayer.play(songs, startingFrom: nil, shuffleMode: .songs, from: peeker, withTitle: weakSelf.title, alertTitle: .shuffle() + (canShuffleAlbums ? " Songs" : ""))
        })
        
        let shuffleAlbums = UIPreviewAction.init(title: .shuffle(.albums), style: .default, handler: { [weak self] _, _ in
            
            guard let weakSelf = self, let peeker = weakSelf.peeker else { return }
            
            musicPlayer.play(songs.albumsShuffled, startingFrom: nil, from: peeker, withTitle: weakSelf.title, alertTitle: .shuffle(.albums))
        })
        
        let shuffleGroup = UIPreviewActionGroup.init(title: "Shuffle...", style: .default, actions: [shuffle, shuffleAlbums])
        
        let queue = UIPreviewAction.init(title: "Queue...", style: .default, handler: { [weak self] _, _ in
            
            guard let weakSelf = self, let peeker = weakSelf.peeker else { return }
            
            Transitioner.shared.addToQueue(from: peeker, kind: .items(songs), context: .other, index: 0, title: weakSelf.title)
        })
        
        let shuffleArray: [UIPreviewActionItem] = (query?.items ?? []).count > 1 ? canShuffleAlbums ? [shuffleGroup] : [shuffle] : []
        
        let array: [UIPreviewActionItem] = [play] + shuffleArray + [info] + (musicPlayer.nowPlayingItem == nil ? [] : [queue])
        
        return array
    }
}

extension EntityItemsViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard let gr = gestureRecognizer as? UIPanGestureRecognizer, (gr is UIScreenEdgePanGestureRecognizer).inverted else { return true }
        
        guard abs(gr.velocity(in: gr.view).y) > abs(gr.velocity(in: gr.view).x), let vc = activeChildViewController as? TableViewContainer, vc.tableDelegate.sectionIndexTitles(for: vc.tableView, filtering: false) != nil else { return false }
        
        return CGRect.init(x: view.frame.size.width - 44, y: 0, width: 44, height: view.bounds.height).contains(gr.location(in: view))
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard (gestureRecognizer is UIScreenEdgePanGestureRecognizer).inverted else { return false }
        
        return otherGestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
}
