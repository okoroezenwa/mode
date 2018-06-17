//
//  ItemsContainerViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 08/01/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class EntityItemsViewController: UIViewController, BackgroundHideable, ArtworkModifying, Contained, OptionsContaining, Peekable, ArtistTransitionable, AlbumArtistTransitionable {

    @IBOutlet weak var titleLabel: MELLabel!
    @IBOutlet weak var backLabel: MELLabel!
    @IBOutlet weak var albumsButton: MELButton!
    @IBOutlet weak var songsButton: MELButton!
    @IBOutlet weak var artistItemsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleScrollView: UIScrollView!
    @IBOutlet weak var artistView: UIView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var artworkImageViewContainer: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var topView: UIView!
    
    enum EntityContainerType {
        
        case playlist, collection, album
        
        var entity: Entity {
            
            switch self {
                
                case .playlist: return .playlist
                
                case .album: return .album
                
                case .collection: return .artist
            }
        }
    }
    enum StartPoint: Int { case albums, songs }
    
    var options: LibraryOptions { return LibraryOptions.init(fromVC: activeChildViewController, configuration: .collection, context: contextForContainerType()) }
    
    @objc var collection: MPMediaItemCollection?
    var entityContainerType = EntityContainerType.playlist
    var kind = AlbumBasedCollectionKind.artist
    var startPoint = StartPoint(rawValue: artistItemsStartingPoint) ?? .songs
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
    @objc weak var peeker: UIViewController? {
        
        didSet {
            
            if peeker == nil, let arrangeable = activeChildViewController as? Arrangeable, arrangeable.operation?.isFinished == true, let index = arrangeable.highlightedIndex {
             
                arrangeable.unhighlightRow(with: arrangeable.relevantIndexPath(using: index))
            }
        }
    }
    var highlightedEntities: (song: MPMediaItem?, album: MPMediaItemCollection?)?
    @objc var backLabelText: String?
    @objc var ascending = true
    var sortCriteria = SortCriteria.standard
    @objc var albumAscending = true
    var albumSortCriteria = SortCriteria.standard
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var artistQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    @objc lazy var songCount = 0
    @objc lazy var albumCount = 0
    @objc var firstLaunch = true
    @objc var lifetimeObservers = Set<NSObject>()
    @objc var transientObservers = Set<NSObject>()
    
    @objc var activeChildViewController: UIViewController? {
        
        didSet {
            
            guard !firstLaunch else { return }
            
            changeActiveViewControllerFrom(oldValue)
        }
    }
    
    @objc lazy var temporaryImageView: UIImageView = {
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    @objc lazy var temporaryEffectView = MELVisualEffectView()
    
    @objc lazy var artistSongsViewController: ArtistSongsViewController = {
        
        let vc = entityStoryboard.instantiateViewController(withIdentifier: "artistSongsVC") as!  ArtistSongsViewController
        vc.ascending = self.ascending
        vc.sortCriteria = self.sortCriteria
        return vc
    }()
    
    @objc lazy var artistAlbumsViewController: ArtistAlbumsViewController = {
        
        let vc = entityStoryboard.instantiateViewController(withIdentifier: "artistAlbumsVC") as!  ArtistAlbumsViewController
        vc.ascending = self.albumAscending
        vc.sortCriteria = self.albumSortCriteria
        return vc
    }()
    
    @objc lazy var playlistItemsViewController: PlaylistItemsViewController = {
        
        let vc = entityStoryboard.instantiateViewController(withIdentifier: "playlistItems") as!  PlaylistItemsViewController
        vc.ascending = self.ascending
        vc.sortCriteria = self.sortCriteria
        return vc
    }()
    
    @objc lazy var albumItemsViewController: AlbumItemsViewController = {
        
        let vc = entityStoryboard.instantiateViewController(withIdentifier: "albumItems") as! AlbumItemsViewController
        vc.ascending = self.ascending
        vc.sortCriteria = self.sortCriteria
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
        
        if entityContainerType == .collection {
            
            artistItemsViewHeightConstraint.constant = 44
            artistView.isHidden = false
            updateButton(for: .albums)
            updateButton(for: .songs)
        }
        
        updateActiveViewController()
        prepareTransientObservers()
        prepareLifetimeObservers()
        titleScrollView.scrollsToTop = false
        
        notifier.addObserver(self, selector: #selector(updateCornersAndShadows), name: .cornerRadiusChanged, object: nil)
        
        topView.layoutIfNeeded()
        
        updateCornersAndShadows()
        
        let collectionImage = collection?.customArtwork?.scaled(to: artworkImageView.frame.size, by: 2)
        let image = query?.items?.shuffled().first(where: { $0.actualArtwork != nil })?.actualArtwork?.image(at: artworkImageView.frame.size)
        
        var noImage: UIImage {
            
            switch entityContainerType {
                
                case .album: return collection?.representativeItem?.isCompilation == true ? #imageLiteral(resourceName: "NoCompilation75") : #imageLiteral(resourceName: "NoAlbum75")
                
                case .playlist:
                
                    guard let playlist = collection as? MPMediaPlaylist else { return #imageLiteral(resourceName: "NoPlaylist75") }
                
                    switch playlist.playlistAttributes {
                        
                        case .smart: return #imageLiteral(resourceName: "NoSmart75")
                        
                        case .genius: return #imageLiteral(resourceName: "NoGenius75")
                        
                        default: return #imageLiteral(resourceName: "NoPlaylist75")
                    }
                
                case .collection:
                
                    switch kind {
                        
                        case .albumArtist, .artist: return #imageLiteral(resourceName: "NoArtist75")
                        
                        case .composer: return #imageLiteral(resourceName: "NoComposer75")
                        
                        case .genre: return #imageLiteral(resourceName: "NoGenre75")
                    }
            }
        }
        
        let shouldUseCollectionArtwork: Bool = {
            
            switch entityContainerType {
                
                case .collection: return useArtistCustomBackground
                
                case .playlist: return usePlaylistCustomBackground
                
                case .album: return true
            }
        }()
        
        artwork = (shouldUseCollectionArtwork ? collectionImage ?? image : image)?.at(.init(width: 20, height: 20)) ?? #imageLiteral(resourceName: "NoArt")
        artworkImageView.image = collectionImage ?? image ?? noImage
        
        if peeker != nil, let container = appDelegate.window?.rootViewController as? ContainerViewController {
            
            temporaryImageView.image = artwork
            container.shouldUseNowPlayingArt = false
            container.updateBackgroundViaModifier(with: artwork)
        }
        
        titleLabel.text = title
        backLabel.text = backLabelText
        
        let edge = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(updateSections))
        edge.edges = .right
        view.addGestureRecognizer(edge)
        
        firstLaunch = false
    }
    
    @objc func updateSections(_ gr: UIScreenEdgePanGestureRecognizer) {
        
        guard let tableDelegate = (activeChildViewController as? TableViewContainer)?.tableDelegate else { return }
        
            switch gr.state {
                
            case .began: tableDelegate.viewSections()
                
            case .changed:
                
                guard let sectionVC = (activeChildViewController as? IndexContaining)?.sectionIndexViewController, let view = sectionVC.view, let collectionView = sectionVC.collectionView, let containerView = sectionVC.containerView, let effectView = sectionVC.effectView, let location: CGPoint = {
                    
                    if view.convert(effectView.frame, from: containerView).contains(gr.location(in: view)) {
                        
                        return gr.location(in: collectionView)
                        
                    } else if sectionVC.overflowBahaviour == .squeeze || sectionVC.array.count <= sectionVC.maxRowsAtMaxFontSize, let location: CGPoint = {
                        
                        let height: CGFloat = {
                            
                            if gr.location(in: collectionView).y < 0 {
                                
                                return 1 + 4
                                
                            } else if gr.location(in: collectionView).y > collectionView.frame.height {
                                
                                return collectionView.frame.height - 1 - 3
                            }
                            
                            return gr.location(in: collectionView).y
                        }()
                        
                        return .init(x: collectionView.center.x, y: height)
                        
                    }() {
                        
                        return location
                    }
                    
                    return nil
                    
                }(), let indexPath = collectionView.indexPathForItem(at: location) else { return }
                
                if sectionVC.hasHeader, indexPath.row == 0 {
                    
                    sectionVC.container?.tableView.setContentOffset(.zero, animated: false)
                    
                } else {
                    
                    sectionVC.container?.tableView.scrollToRow(at: .init(row: NSNotFound, section: indexPath.row - (sectionVC.hasHeader ? 1 : 0)), at: .top, animated: false)
                }
                
            case .ended, .failed/*, .cancelled*/: (activeChildViewController as? IndexContaining)?.sectionIndexViewController?.dismissVC()
                
            default: break
        }
    }
    
    @objc func updateCornersAndShadows() {
        
        ([artworkImageView] as [UIImageView]).forEach({ imageView in
            
            (listsCornerRadius ?? cornerRadius).updateCornerRadius(on: imageView.layer, width: imageView.bounds.width, entityType: entityContainerType.entity, globalRadiusType: cornerRadius)
            
//            let details: RadiusDetails = {
//
//                switch cornerRadius {
//
//                    case .automatic: return ((listsCornerRadius ?? cornerRadius).radius(for: entityContainerType.entity, width: imageView.bounds.width), listsCornerRadius != .rounded)
//
//                    default: return (cornerRadius.radius(for: entityContainerType.entity, width: imageView.bounds.width), cornerRadius != .rounded)
//                }
//            }()
//
//            imageView.layer.setRadiusTypeIfNeeded(to: details.useSmoothCorners)
//            imageView.layer.cornerRadius = details.radius
        })
        
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
        
        container?.currentModifier = self
        setCurrentOptions()
        
        if container?.deferToNowPlayingViewController == false, !nowPlayingAsBackground {
            
            if let _ = artwork {
                
                container?.shouldUseNowPlayingArt = false
                container?.updateBackgroundViaModifier()
                
            } else {
                
                container?.shouldUseNowPlayingArt = true
                container?.updateBackgroundWithNowPlaying()
            }
        }
        
        if needsDismissal {
            
            if let vc = presentedViewController {
                
                vc.dismiss(animated: false, completion: nil)
            }
            
            let banner = Banner.init(title: "This artist has no offline music", subtitle: nil, image: nil, backgroundColor: .red, didTapBlock: nil)
            banner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
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
        
        if peeker != nil, let container = appDelegate.window?.rootViewController as? ContainerViewController {
            
            if let _ = container.currentModifier {
                
                container.shouldUseNowPlayingArt = false
                container.updateBackgroundViaModifier()
                
            } else {
                
                container.shouldUseNowPlayingArt = true
                container.updateBackgroundWithNowPlaying()
            }
        }
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
                
                if weakSelf.activeChildViewController == weakSelf.artistSongsViewController {
                    
                    weakSelf.artistAlbumsViewController.currentArtistQuery = weakSelf.query?.copy() as? MPMediaQuery
                    weakSelf.artistAlbumsViewController.updateWithQuery()
                    
                } else if weakSelf.activeChildViewController == weakSelf.artistAlbumsViewController {
                    
                    weakSelf.artistSongsViewController.currentArtistQuery = weakSelf.query?.copy() as? MPMediaQuery
                    weakSelf.artistSongsViewController.updateWithQuery()
                }
            }
            
            if weakSelf.entityContainerType == .collection {
                
                weakSelf.updateButton(for: .albums)
                weakSelf.updateButton(for: .songs)
            }
        })
        
        lifetimeObservers.insert(iCloudObserver as! NSObject)
        
        let libraryObserver = notifier.addObserver(forName: .libraryUpdated, object: appDelegate, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self, weakSelf.query?.collections?.isEmpty == false else {
                
                if let vc = self?.presentedViewController {
                    
                    vc.dismiss(animated: false, completion: nil)
                }
                
                let banner = Banner.init(title: "This entity is no longer in your library", subtitle: nil, image: nil, backgroundColor: .red, didTapBlock: nil)
                banner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                banner.show(duration: 1.5)
                
                _ = self?.navigationController?.popViewController(animated: true)
                
                return
            }
            
            if let updateable = weakSelf.activeChildViewController as? QueryUpdateable {
                
                updateable.updateWithQuery()
            }
            
            if weakSelf.entityContainerType == .collection {
                
                weakSelf.updateButton(for: .albums)
                weakSelf.updateButton(for: .songs)
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
                banner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
                banner.show(weakSelf.view, duration: 1.5)
                
                _ = weakSelf.navigationController?.popViewController(animated: true)
            }
        })
        
        lifetimeObservers.insert(settingsObserver as! NSObject)
    }
    
    @objc func getCurrentQuery() -> MPMediaQuery? {
        
        guard let collection = collection else { return nil }
        
        let query: MPMediaQuery = {
            
            let entity = entityForContainerType()
            
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
            
            let entity = entityForContainerType()
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
    
    func entityForContainerType() -> Entity {
        
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
    
    @objc func cornerRadiusForContainerType() -> CGFloat {
        
        switch entityContainerType {
            
            case .album: return ceil((14/45) * artworkImageViewContainer.bounds.width)
            
            case .playlist: return ceil((6/45) * artworkImageViewContainer.bounds.width)
            
            case .collection: return 33// the width that should always be, as the view is the same across devices //artworkImageViewContainer.bounds.width / 2
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
    
    @objc func selectedArtistButton() -> UIButton {
        
        switch activeChildViewController {
            
            case let x where x == artistSongsViewController: return songsButton
            
            case let x where x == artistAlbumsViewController: return albumsButton
            
            default: fatalError("No other activeVC should use this")
        }
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        
//        guard let identifier = segue.identifier else { return }
//        
//        switch identifier {
//            
//            case "toOptions":
//                
//            
//            
//            default: break
//        }
//    }
//    
//    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
//        
//        switch identifier {
//            
//            case "toOptions": return contextForContainerType() != nil
//            
//            default: return true
//        }
//    }
    
    @IBAction func dismissVC() {
        
        _ = navigationController?.popViewController(animated: true)
    }
    
    @objc func changeActiveViewControllerFrom(_ vc: UIViewController?) {
        
        guard let activeVC = activeChildViewController, let inActiveVC = vc else { return }
        
        inActiveVC.willMove(toParent: nil)
        
        addChild(activeVC)
        
        activeVC.view.alpha = 0
        activeVC.view.frame = containerView.bounds
        activeVC.view.transform = CGAffineTransform.init(translationX: 0, y: 50)
        containerView.addSubview(activeVC.view)
        
        // call before adding child view controller's view as subview
        activeVC.didMove(toParent: self)
        
        UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: .calculationModeCubic, animations: {
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/2, animations: {
                
                inActiveVC.view.transform = CGAffineTransform.init(translationX: 0, y: 50)
                inActiveVC.view.alpha = 0
            })
            
            UIView.addKeyframe(withRelativeStartTime: 1/2, relativeDuration: 1/2, animations: {
                
                activeVC.view.transform = CGAffineTransform.identity
                activeVC.view.alpha = 1
            })
            
        }, completion: { _ in
            
            inActiveVC.view.transform = CGAffineTransform.identity
            inActiveVC.view.removeFromSuperview()
            
            // call after removing child view controller's view from hierarchy
            inActiveVC.removeFromParent()
        })
    }
    
    private func updateActiveViewController() {
        
        if let activeVC = activeChildViewController {
            
            // call before adding child view controller's view as subview
            addChild(activeVC)
            
            activeVC.view.frame = containerView.bounds
            containerView.addSubview(activeVC.view)
            
            // call before adding child view controller's view as subview
            activeVC.didMove(toParent: self)
        }
    }
    
    func updateButton(for startPoint: StartPoint, withCount count: Int? = nil) {
        
        switch startPoint {
            
            case .albums:
                
                guard let albums = query?.collections?.count else { return }
            
                albumsButton.setTitle(albums.fullCountText(for: .album, filteredCount: count).capitalized, for: .normal)
                
                /*if let count = count {
                    
                    albumsButton.setTitle(UniversalMethods.formattedNumber(from: count) + " of " + UniversalMethods.formattedNumber(from: albums) + " \(UniversalMethods.countText(for: albums, entity: .album).capitalized)", for: .normal)
                
                } else {
                    
                    albumsButton.setTitle(UniversalMethods.formattedNumber(from: albums) + " \(UniversalMethods.countText(for: albums, entity: .album).capitalized)", for: .normal)
                }*/
                
            case .songs:
                
                guard let songs = query?.items?.count else { return }
            
                songsButton.setTitle(songs.fullCountText(for: .song, filteredCount: count).capitalized, for: .normal)
                
//                if let count = count {
//                    
//                    songsButton.setTitle(UniversalMethods.formattedNumber(from: count) + " of " + UniversalMethods.formattedNumber(from: songs) + " \(UniversalMethods.countText(for: songs, entity: .song).capitalized)", for: .normal)
//                
//                } else {
//                    
//                    songsButton.setTitle(UniversalMethods.formattedNumber(from: songs) + " \(UniversalMethods.countText(for: songs, entity: .song).capitalized)", for: .normal)
//                }
        }
        
        switch activeChildViewController {
            
            case let x where x == artistSongsViewController: songsButton.update(for: .selected)
            
            case let x where x == artistAlbumsViewController: albumsButton.update(for: .selected)
            
            default: break
        }
    }
    
    @objc @discardableResult func performTransition(to vc: UIViewController, sender: Any?, perform3DTouchActions: Bool = false) -> UIViewController? {
        
        if let presentedVC = vc as? PresentedContainerViewController, let context = contextForContainerType() {
            
            presentedVC.context = .info
            presentedVC.optionsContext = context
        }
        
        return nil
    }
    
    @IBAction func switchSection(_ sender: UIButton) {
        
        guard sender != selectedArtistButton(), entityContainerType == .collection else { return }
        
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        UniversalMethods.performOnMainThread({ UIApplication.shared.endIgnoringInteractionEvents() }, afterDelay: 0.3)
        
        for button in [albumsButton, songsButton] {
            
            if button == sender {
                
                if sender == albumsButton, activeChildViewController != artistAlbumsViewController {
                    
                    button?.update(for: .selected)
                    
                    activeChildViewController = artistAlbumsViewController
                    
                } else if sender == songsButton, activeChildViewController != artistSongsViewController {
                    
                    button?.update(for: .selected)
                    
                    activeChildViewController = artistSongsViewController
                }
            
            } else {
                
                button?.update(for: .unselected, capitalised: true)
            }
        }
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
//            UniversalMethods.banner(withTitle: "EVC going away...").show(for: 0.3)
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
            
                switch startPoint {
                    
                    case .albums: return artistAlbumsViewController.albums.isEmpty ? (query?.items ?? []) : artistAlbumsViewController.albums.reduce([], { $0 + $1.items })
                    
                    case .songs: return artistSongsViewController.songs.isEmpty ? (query?.items ?? []) : artistSongsViewController.songs
                }
            
            case .playlist: return playlistItemsViewController.songs.isEmpty ? (query?.items ?? []) : playlistItemsViewController.songs
        }
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        
        let info = UIPreviewAction(title: "Get Info", style: .default, handler: { [weak self] _, _ in
            
            guard let weakSelf = self, let peeker = weakSelf.peeker, let context = weakSelf.contextForContainerType() else { return }
            
            Transitioner.shared.showInfo(from: peeker, with: context)
        })
        
//        let artist = UIPreviewAction(title: "Show Artist", style: .default, handler: { [weak self] _, _ in
//
//            guard let weakSelf = self, let peeker = weakSelf.peeker, let useAlbumArtist = weakSelf.query?.items?.first?.isCompilation else { return }
//
//            shouldReturnToContainer = true
//            peeker.performSegue(withIdentifier: "unwind", sender: nil)
//
//            weakSelf.verifyLibraryStatus(of: weakSelf.query?.items?.first, itemProperty: useAlbumArtist ? .albumArtist : .artist)
//
//            weakSelf.container?.unwindToArtist(with: useAlbumArtist ? weakSelf.albumArtistQuery : weakSelf.artistQuery, item: weakSelf.currentItem, album: nil, kind: useAlbumArtist ? .albumArtist : .artist)
//        })
        
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
        
        let array: [UIPreviewActionItem] = [play] + shuffleArray + [info] + [queue]// + (entityContainerType == .album ? [artist] : [])
        
        return array
    }
}
