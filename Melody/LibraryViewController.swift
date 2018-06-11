//
//  LibraryViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 08/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit
import StoreKit

class LibraryViewController: UIViewController, Contained, OptionsContaining {
    
    @IBOutlet weak var titleButton: MELButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var emptyStackView: UIStackView!
    @IBOutlet weak var emptyLabel: MELLabel!
    @IBOutlet weak var emptySubLabel: MELLabel! {
        
        didSet {
            
            guard let text = emptySubLabel.text else { return }
            
            let style = NSMutableParagraphStyle.init()
            style.alignment = .center
            style.lineHeightMultiple = 1.2
            
            emptySubLabel.attributes = [Attributes.init(name: .paragraphStyle, value: .other(style), range: text.nsRange())]
        }
    }
    
    @objc let presenter = NavigationAnimationController()
    @objc var transientObservers = Set<NSObject>()
    @objc var lifetimeObservers = Set<NSObject>()
    var section: LibrarySection { return sectionOverride ?? LibrarySection(rawValue: lastUsedLibrarySection) ?? .artists }
    var sectionOverride: LibrarySection?
    
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
    
    @objc lazy var songsViewController: SongsViewController? = {
        
        guard let vc = libraryChildrenStoryboard.instantiateViewController(withIdentifier: "songsVC") as? SongsViewController else { return nil }
        
        return vc
    }()
    
    @objc lazy var artistsViewController = LibraryViewController.collectionsVC(for: albumArtistsAvailable ? .albumArtist : .artist)
    @objc lazy var albumsViewController = LibraryViewController.collectionsVC(for: .album)
    @objc lazy var genresViewController = LibraryViewController.collectionsVC(for: .genre)
    @objc lazy var compilationsViewController = LibraryViewController.collectionsVC(for: .compilation)
    @objc lazy var composersViewController = LibraryViewController.collectionsVC(for: .composer)
    @objc lazy var playlistsViewController = LibraryViewController.collectionsVC(for: .playlist)
    
    @objc var activeChildViewController: UIViewController? {
        
        didSet {
            
            guard let oldValue = oldValue else { return }

            changeActiveViewControllerFrom(oldValue)
        }
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
            
            case .songs: title = "Songs"
            
            case .genres: title = "Genres"
            
            case .composers: title = "Composers"
            
            case .compilations: title = "Compilations"
            
            case .playlists: title = "Playlists"
        }
        
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
                    
                    sectionVC.container?.tableView.setContentOffset(.zero, animated: false)
                    
                } else {
                    
                    sectionVC.container?.tableView.scrollToRow(at: .init(row: NSNotFound, section: indexPath.row - (sectionVC.hasHeader ? 1 : 0)), at: .top, animated: false)
                }
            
            case .ended, .failed/*, .cancelled*/: (activeChildViewController as? IndexContaining)?.sectionIndexViewController?.dismissVC()
            
            default: break
        }
    }
    
    @objc func viewControllerForCurrentSection() -> UIViewController? {
        
        switch section {
            
            case .albums: return albumsViewController
            
            case .artists: return artistsViewController
            
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
        
        container?.shouldUseNowPlayingArt = true
        container?.updateBackgroundWithNowPlaying()
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
            
            if weakSelf.navigationController?.topViewController != weakSelf.viewControllerForCurrentSection() {
                
                weakSelf.navigationController?.popToRootViewController(animated: true)
            }
            
            weakSelf.activeChildViewController = weakSelf.viewControllerForCurrentSection()
            
        }) as! NSObject)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        unregisterAll(from: transientObservers)
    }
    
    func updateEmptyView(forState state: EmptyViewState, subLabelText: String?) {
        
        switch state {
            
        case .completelyHidden: emptyStackView.isHidden = true
            
        case .subLabelHidden:
            
            emptyStackView.isHidden = false
            emptySubLabel.isHidden = true
            
        case .completelyVisible:
            
            emptyStackView.isHidden = false
            emptySubLabel.isHidden = false
            emptySubLabel.attributedText = NSAttributedString.init(string: subLabelText ?? "")
        }
    }
    
    @objc func updateEmptyLabel(withCount count: Int, text: String) {
        
        if count < 1 {
            
            updateEmptyView(forState: .completelyVisible, subLabelText: text)
            
        } else {
            
            updateEmptyView(forState: .completelyHidden, subLabelText: nil)
        }
    }
    
    func updateViews(inSection section: LibrarySection, count: Int, filteredCount: Int? = nil) {
        
        titleButton.setTitle(" " + count.fullCountText(for: section.entity, filteredCount: filteredCount, compilationOverride: section == .compilations, capitalised: true), for: .normal)
        titleButton.setImage(section.image, for: .normal)
        
        title = section.title.capitalized
    }
    
    private func removeInactiveViewController(inactiveViewController: UIViewController?) {
        
        if let inActiveVC = inactiveViewController {
            
            // call before removing child view controller's view from hierarchy
            inActiveVC.willMove(toParent: nil)
            
            UIView.animate(withDuration: 0.3, animations: {
                
                inActiveVC.view.transform = CGAffineTransform.init(translationX: 0, y: 50)
                inActiveVC.view.alpha = 0
                
                }, completion: { _ in
                    
                    inActiveVC.view.transform = CGAffineTransform.identity
                    inActiveVC.view.removeFromSuperview()
                    
                    // call after removing child view controller's view from hierarchy
                    inActiveVC.removeFromParent()
            })
        }
    }
    
    @objc func changeActiveViewControllerFrom(_ vc: UIViewController?, animated: Bool = true) {
        
        guard let activeVC = activeChildViewController, let inActiveVC = vc else { return }
        
        addChild(activeVC)
        activeVC.view.frame = contentView.bounds
        inActiveVC.willMove(toParent: nil)
        
        if animated {
            
            activeVC.view.alpha = 0
            activeVC.view.frame = contentView.bounds.modifiedBy(x: 0, y: 40)
            contentView.addSubview(activeVC.view)
            
            UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: .calculationModeCubic, animations: {
                
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/2, animations: {
                    
                    inActiveVC.view.frame = self.contentView.bounds.modifiedBy(x: 0, y: 40)
                    inActiveVC.view.alpha = 0
                })
                
                UIView.addKeyframe(withRelativeStartTime: 1/2, relativeDuration: 1/2, animations: {
                    
                    activeVC.view.alpha = 1
                    activeVC.view.frame = self.contentView.bounds
                })
                
            }, completion: { _ in inActiveVC.view.removeFromSuperview() })
            
        } else {
            
            activeVC.view.frame = contentView.bounds
            contentView.addSubview(activeVC.view)
        }
        
        inActiveVC.removeFromParent()
        activeVC.didMove(toParent: self)
        (activeVC as? LibrarySectionContainer)?.updateTopLabels(withFilteredCount: nil)
    }
    
    private func updateActiveViewController() {
        
        if let activeVC = activeChildViewController {
            
            addChild(activeVC)
            activeVC.view.frame = contentView.bounds
            activeVC.didMove(toParent: self)
            contentView.addSubview(activeVC.view)
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
    
    func updateTopLabels(withFilteredCount count: Int?)
}
