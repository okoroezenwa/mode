//
//  LibraryViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 08/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit
import StoreKit

class LibraryViewController: UIViewController, Contained, OptionsContaining, Navigatable, ArtworkModifying, ChildContaining, HighlightedEntityContaining, CentreViewDisplaying {
    
    @IBOutlet var containerView: UIView!
    
    @objc let presenter = NavigationAnimationController()
    @objc var transientObservers = Set<NSObject>()
    @objc var lifetimeObservers = Set<NSObject>()
    var section: LibrarySection { return sectionOverride ?? LibrarySection(rawValue: lastUsedLibrarySection) ?? .artists }
    var sectionOverride: LibrarySection?
    var changeActiveVC = true
    var shouldSetTitles = true
    var highlightedEntities: (song: MPMediaItem?, collection: MPMediaItemCollection?)?
    
    var options: LibraryOptions {
        
        let count: Int = {
            
            switch section {
                
                case .songs: return songsViewController?.songsQuery.items?.count ?? 0
                
                case .playlists: return (activeChildViewController as? CollectionsViewController)?.collections.count ?? 0
                
                default: return (activeChildViewController as? CollectionsViewController)?.collectionsQuery.collections?.count ?? 0
            }
        }()
        
        return LibraryOptions.init(fromVC: activeChildViewController, configuration: .library, count: count)
    }
    
    var isSongsViewControllerInitialised = false
    var isArtistsViewControllerInitialised = false
    var isAlbumArtistsViewControllerInitialised = false
    var isAlbumsViewControllerInitialised = false
    var isGenresViewControllerInitialised = false
    var isCompilationsViewControllerInitialised = false
    var isComposersViewControllerInitialised = false
    var isPlaylistsViewControllerInitialised = false
    
    @objc lazy var songsViewController: SongsViewController? = {
        
        guard let vc = libraryChildrenStoryboard.instantiateViewController(withIdentifier: "songsVC") as? SongsViewController else { return nil }
        
        isSongsViewControllerInitialised = true
        return vc
    }()
    
    @objc lazy var artistsViewController: CollectionsViewController? = {
        
        guard let vc = LibraryViewController.collectionsVC(for: .artist) else { return nil }
        
        isArtistsViewControllerInitialised = true
        return vc
    }()
    
    @objc lazy var albumArtistsViewController: CollectionsViewController? = {
        
        guard let vc = LibraryViewController.collectionsVC(for: .albumArtist) else { return nil }
        
        isAlbumArtistsViewControllerInitialised = true
        return vc
    }()
    
    @objc lazy var albumsViewController: CollectionsViewController? = {
        
        guard let vc = LibraryViewController.collectionsVC(for: .album) else { return nil }
        
        isAlbumsViewControllerInitialised = true
        return vc
    }()
    
    @objc lazy var genresViewController: CollectionsViewController? = {
        
        guard let vc = LibraryViewController.collectionsVC(for: .genre) else { return nil }
        
        isGenresViewControllerInitialised = true
        return vc
    }()
    
    @objc lazy var compilationsViewController: CollectionsViewController? = {
        
        guard let vc = LibraryViewController.collectionsVC(for: .compilation) else { return nil }
        
        isCompilationsViewControllerInitialised = true
        return vc
    }()
    
    @objc lazy var composersViewController: CollectionsViewController? = {
        
        guard let vc = LibraryViewController.collectionsVC(for: .composer) else { return nil }
        
        isComposersViewControllerInitialised = true
        return vc
    }()
    
    @objc lazy var playlistsViewController: CollectionsViewController? = {
        
        guard let vc = LibraryViewController.collectionsVC(for: .playlist) else { return nil }
        
        isPlaylistsViewControllerInitialised = true
        return vc
    }()
    
    @objc var activeChildViewController: UIViewController? {
        
        didSet {
            
            guard changeActiveVC, let oldValue = oldValue else { return }

            changeActiveViewControllerFrom(oldValue)
        }
    }
    
    var viewControllerSnapshot: UIView? { didSet { oldValue?.removeFromSuperview() } }
    
    var backLabelText: String?
    var artwork: UIImage? {
        
        get { return musicPlayer.nowPlayingItem?.actualArtwork?.image(at: .init(width: 20, height: 20)) }
        
        set { }
    }
    var artworkDetails: NavigationBarArtworkDetails?
    var firstButtonUpdateUsed = false
    var buttonDetails: NavigationBarButtonDetails = (.actions, true) {
        
        didSet {
            
            container?.visualEffectNavigationBar.prepareRightButton(for: self, animated: firstButtonUpdateUsed)
            firstButtonUpdateUsed = true
        }
    }
    var inset: CGFloat { return VisualEffectNavigationBar.Location.main.total }
    lazy var preferredTitle: String? = title
    
    var centreViewGiantImage: UIImage?
    var centreViewTitleLabelText: String?
    var centreViewSubtitleLabelText: String?
    var centreViewLabelsImage: UIImage?
    var currentCentreView = CentreView.CurrentView.none
    var centreView: CentreView? {
        
        get { container?.centreView }
        
        set { }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        activeChildViewController = viewControllerForCurrentSection()
        updateActiveViewController()
        navigationController?.delegate = presenter
        presenter.interactor.add(to: navigationController)
        prepareLifetimeObservers()
        
        switch section {
            
            case .albums: title = "Albums"
            
            case .artists: title = "Artists"
            
            case .albumArtists: title = "Album Artists"
            
            case .songs: title = "Songs"
            
            case .genres: title = "Genres"
            
            case .composers: title = "Composers"
            
            case .compilations: title = "Compilations"
            
            case .playlists: title = "Playlists"
        }

        container?.visualEffectNavigationBar.titleLabel.text = title
        
        let edge = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(updateSections))
        edge.edges = .right
        view.addGestureRecognizer(edge)
        
        if let parent = parent as? PresentedContainerViewController {
            
            let edge = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(updateSections))
            edge.edges = .right
            parent.view.addGestureRecognizer(edge)
        }
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
                    
                    sectionVC.container?.tableView.setContentOffset(.init(x: 0, y: (activeChildViewController as? CollectionsViewController)?.presented == true ? 0 : -inset), animated: false)
                    
                } else {
                    
                    sectionVC.container?.tableView.scrollToRow(at: .init(row: NSNotFound, section: indexPath.row - (sectionVC.hasHeader ? 1 : 0)), at: .top, animated: false)
                }
            
            case .ended, .failed: (activeChildViewController as? IndexContaining)?.sectionIndexViewController?.dismissVC()
            
            default: break
        }
    }
    
    @objc func viewControllerForCurrentSection() -> UIViewController? {
        
        switch section {
            
            case .albums: return albumsViewController
            
            case .artists: return artistsViewController
            
            case .albumArtists: return albumArtistsViewController
            
            case .compilations: return compilationsViewController
            
            case .genres: return genresViewController
            
            case .songs: return songsViewController
            
            case .composers: return composersViewController
            
            case .playlists: return playlistsViewController
        }
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        prepareTransientObservers()
        
        container?.visualEffectNavigationBar.entityTypeLabel.superview?.isHidden = true
        
        container?.currentModifier = nil
        setCurrentOptions()
    }
    
    func setCurrentOptions() {
        
        container?.currentOptionsContaining = self
    }
    
    @objc func prepareTransientObservers() {
        
        let secondaryObserver = notifier.addObserver(forName: .performSecondaryAction, object: navigationController, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            if let vc = weakSelf.activeChildViewController as? SongsViewController, vc.songs.count < 2 {
                
                return
            
            } else if let vc = weakSelf.activeChildViewController as? CollectionsViewController, vc.collections.count < 2 {
                
                return
            }
            
            (weakSelf.activeChildViewController as? Filterable)?.invokeSearch()
        })
        
        transientObservers.insert(secondaryObserver as! NSObject)
        
        transientObservers.insert(notifier.addObserver(forName: .scrollCurrentViewToTop, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            (weakSelf.activeChildViewController as? TopScrollable)?.scrollToTop()
            
        }) as! NSObject)
    }
    
    func prepareLifetimeObservers() {
        
        lifetimeObservers.insert(notifier.addObserver(forName: .changeLibrarySection, object: nil, queue: nil, using: { [weak self] notification in
            
            if let collectionsVC = self?.activeChildViewController as? CollectionsViewController, collectionsVC.presented {
                
                return
            }
            
            guard let weakSelf = self, notification.userInfo?["section"] as? Int != notification.userInfo?["oldSection"] as? Int else { return }
            
            let animated = notification.userInfo?["animated"] as? Bool ?? true
            
            if weakSelf.navigationController?.topViewController != weakSelf.viewControllerForCurrentSection() {
                
                weakSelf.navigationController?.popToRootViewController(animated: animated)
            }
            
            if animated {
            
                weakSelf.activeChildViewController = weakSelf.viewControllerForCurrentSection()
            
            } else {
                
                let old = weakSelf.activeChildViewController
                weakSelf.changeActiveVC = false
                weakSelf.activeChildViewController = weakSelf.viewControllerForCurrentSection()
                weakSelf.changeActiveVC = true
                weakSelf.changeActiveViewControllerFrom(old, animated: false, completion: { weakSelf.view.alpha = 1 })
            }
            
        }) as! NSObject)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        unregisterAll(from: transientObservers)
    }
    
    @objc func updateEmptyLabel(withCount count: Int, text: String) {
        
        centreViewTitleLabelText = {
            
            if let collectionsVC = children.first as? CollectionsViewController {
                
                return "No \(collectionsVC.collectionKind.title)"
            }
            
            return "No Songs"
        }()
        centreViewSubtitleLabelText = text
        centreViewLabelsImage = section.centreViewImage
        updateCurrentView(to: count < 1 ? .labels(components: [.image, .title, .subtitle]) : .none)
    }
    
    func updateViews(inSection section: LibrarySection, count: Int, setTitle: Bool) {
        
        let text = count.fullCountText(for: section.entityType, compilationOverride: section == .compilations, capitalised: true)
        
        title = text
        preferredTitle = section.title.capitalized
        
        if setTitle {
            
            container?.visualEffectNavigationBar.titleLabel.text = title
        }
    }
    
    func isViewControllerInitialised(for section: LibrarySection) -> Bool {
        
        switch section {
            
            case .songs: return isSongsViewControllerInitialised
            
            case .artists: return isArtistsViewControllerInitialised
            
            case .albumArtists: return isAlbumArtistsViewControllerInitialised
            
            case .albums: return isAlbumsViewControllerInitialised
            
            case .genres: return isGenresViewControllerInitialised
            
            case .compilations: return isCompilationsViewControllerInitialised
            
            case .composers: return isComposersViewControllerInitialised
            
            case .playlists: return isPlaylistsViewControllerInitialised
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let id = segue.identifier else { return }
        
        switch id {
            
            case "toNewPlaylist":
                
                if let presentedVC = segue.destination as? PresentedContainerViewController, let playlistsViewController = playlistsViewController {

                    presentedVC.itemsToAdd = playlistsViewController.itemsToAdd
                    presentedVC.manager = playlistsViewController.manager
                    presentedVC.context = .newPlaylist
                    presentedVC.fromQueue = playlistsViewController.fromQueue
                }
            
            case "toSettings":
            
                if let presentedVC = segue.destination as? PresentedContainerViewController {
                    
                    presentedVC.context = .settings
                }
            
            default: break
        }
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "LVC going away...").show(for: 0.3)
        }
        
        unregisterAll(from: lifetimeObservers)
    }
}

extension LibraryViewController {
    
    static func collectionsVC(for collectionKind: CollectionsKind) -> CollectionsViewController? {
        
        guard let vc = libraryChildrenStoryboard.instantiateViewController(withIdentifier: "collectionsVC") as? CollectionsViewController else { return nil }
        
        vc.collectionKind = collectionKind
        
        return vc
    }
}

protocol LibrarySectionContainer {
    
    var libraryVC: LibraryViewController? { get }
    func updateTopLabels(setTitle: Bool)
    func getRecents()
}
