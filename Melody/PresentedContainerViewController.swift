//
//  PresentedContainerViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 17/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PresentedContainerViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var effectView: MELVisualEffectView!
    @IBOutlet weak var titleLabel: MELLabel!
    @IBOutlet weak var leftButton: MELButton!
    @IBOutlet weak var rightButton: MELButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet var cornerRadiusView: UIView! {
        
        didSet {
            
            cornerRadiusView.layer.setRadiusTypeIfNeeded()
            cornerRadiusView.layer.cornerRadius = 14
        }
    }
    @IBOutlet weak var rightBorderView: MELBorderView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var parentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var parentViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var largeActivityIndicator: MELActivityIndicatorView!
    
    enum ChildContext { case items, playlists, upNext, newPlaylist, settings, tips, queue, playlistDetails, info, songDetails, queueGuard, theme, gestures, playback, tabBar, background, filter, artwork, icon, fullPlayer, libraryRefresh, recents }
    enum Value: String { case property = "P", selector = "S" }
    
    var context = ChildContext.items
    var valueFor = Value.property {
        
        didSet {
            
            updateRightButton()
        }
    }
    var manager: QueueManager?
    @objc var query: MPMediaQuery?
    @objc var itemsToAdd = [MPMediaItem]()
    @objc var firstLaunch = true
    @objc lazy var fromQueue = true
    @objc lazy var shuffled = false
    @objc weak var container: ContainerViewController?
    @objc weak var newVC: NewPlaylistViewController?
    @objc var index: CGFloat {
        
        get { return modalIndex }
        
        set { }
    }
    @objc lazy var indexPath = IndexPath.init()
    @objc var showLyrics = false
    @objc var useConstraintConstant = false
    var toBeDismissed: Dismissable?
    var transitionStart: (() -> ())?
    var transitionAnimation: (() -> ())?
    var transitionCancellation: (() -> ())?
    lazy var optionsContext = InfoViewController.Context.song(location: .queue(loaded: true, index: musicPlayer.nowPlayingItemIndex), at: 0, within: [musicPlayer.nowPlayingItem].compactMap({ $0 }))
    override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        
        get { return self.altAnimator ?? self.animator }
        
        set { }
    }
    override var modalPresentationStyle: UIModalPresentationStyle {
        
        get { return .overFullScreen }
        
        set { }
    }
    
    @objc var animator = PresentationAnimationController.init(interactor: InteractionController())
    @objc var altAnimator: PresentationAnimationController?
    
    @objc lazy var playlistsVC: LibraryViewController = {
        
        let vc = mainChildrenStoryboard.instantiateViewController(withIdentifier: "libraryVC") as! LibraryViewController
        vc.sectionOverride = .playlists
        vc.playlistsViewController?.presented = true
        vc.playlistsViewController?.manager = self.manager
        vc.playlistsViewController?.fromQueue = self.fromQueue
        if !self.itemsToAdd.isEmpty { vc.playlistsViewController?.itemsToAdd = self.itemsToAdd }
        
        return vc
    }()
    @objc lazy var queueTVC: QueueViewController = {
        
        let vc = presentedChilrenStoryboard.instantiateViewController(withIdentifier: "queueTVC") as! QueueViewController
        if !self.itemsToAdd.isEmpty { vc.itemsToAdd = self.itemsToAdd }
        vc.manager = self.manager
        vc.presented = true
        vc.query = self.query
        
        return vc
    }()
    @objc lazy var queueVC: CollectorViewController = {
        
        let vc = presentedChilrenStoryboard.instantiateViewController(withIdentifier: "queueVC") as! CollectorViewController
        vc.manager = self.manager
        
        return vc
    }()
    @objc lazy var newPlaylistVC: NewPlaylistViewController = {
        
        let vc = presentedChilrenStoryboard.instantiateViewController(withIdentifier: "newPlaylist") as! NewPlaylistViewController
        
        if !self.itemsToAdd.isEmpty { vc.playlistItems = self.itemsToAdd }
        vc.fromQueue = self.fromQueue
        vc.manager = self.manager
        
        return vc
    }()
    @objc lazy var settingsVC: SettingsTableViewController = {
        
        let vc = settingsStoryboard.instantiateViewController(withIdentifier: String.init(describing: SettingsTableViewController.self)) as! SettingsTableViewController
        
        return vc
    }()
    @objc lazy var tipsVC: TipsViewController = {
        
        let vc = tipsStoryboard.instantiateViewController(withIdentifier: "tipsVC") as! TipsViewController
        
        return vc
    }()
    @objc lazy var qVC: QueueViewController = {
        
        let vc = presentedChilrenStoryboard.instantiateViewController(withIdentifier: "queueTVC") as! QueueViewController
        
        return vc
    }()
    @objc lazy var textVC: TextViewController = {
        
        let vc = presentedChilrenStoryboard.instantiateViewController(withIdentifier: "textVC") as! TextViewController
        
        vc.newPlaylistVC = self.newVC
        
        return vc
    }()
    @objc lazy var newOptionsVC: InfoViewController = {
        
        let vc = presentedChilrenStoryboard.instantiateViewController(withIdentifier: "newOptions") as! InfoViewController
        vc.context = self.optionsContext
        vc.showLyrics = self.showLyrics
        
        return vc
    }()
    @objc lazy var songDetailsVC: CellSecondaryDetailsSettingViewController = {
        
        let vc = settingsStoryboard.instantiateViewController(withIdentifier: String.init(describing: CellSecondaryDetailsSettingViewController.self)) as! CellSecondaryDetailsSettingViewController
        
        return vc
    }()
    @objc lazy var queueGuardVC: QueueTableViewController = {
        
        let vc = settingsStoryboard.instantiateViewController(withIdentifier: String.init(describing: QueueTableViewController.self)) as! QueueTableViewController
        
        return vc
    }()
    @objc lazy var themeVC: ThemeViewController = {
        
        let vc = settingsStoryboard.instantiateViewController(withIdentifier: String.init(describing: ThemeViewController.self)) as! ThemeViewController
        
        return vc
    }()
    @objc lazy var gesturesVC: GesturesTableViewController = {
        
        let vc = settingsStoryboard.instantiateViewController(withIdentifier: String.init(describing: GesturesTableViewController.self)) as! GesturesTableViewController
        
        return vc
    }()
    @objc lazy var playbackVC: PlaybackTableViewController = {
        
        let vc = settingsStoryboard.instantiateViewController(withIdentifier: String.init(describing: PlaybackTableViewController.self)) as! PlaybackTableViewController
        
        return vc
    }()
    @objc lazy var tabBarVC: TabBarTableViewController = {
        
        let vc = settingsStoryboard.instantiateViewController(withIdentifier: String.init(describing: TabBarTableViewController.self)) as! TabBarTableViewController
        
        return vc
    }()
    @objc lazy var backgroundVC: BackgroundTableViewController = {
        
        let vc = settingsStoryboard.instantiateViewController(withIdentifier: String.init(describing: BackgroundTableViewController.self)) as! BackgroundTableViewController
        
        return vc
    }()
    @objc lazy var filterVC: FilterViewController = {
        
        let vc = presentedChilrenStoryboard.instantiateViewController(withIdentifier: String.init(describing: FilterViewController.self)) as! FilterViewController
        
        return vc
    }()
    @objc lazy var artworkVC: ArtworkTableViewController = {
        
        let vc = settingsStoryboard.instantiateViewController(withIdentifier: String.init(describing: ArtworkTableViewController.self)) as! ArtworkTableViewController
        
        return vc
    }()
    @objc lazy var iconVC: IconSelectionTableViewController = {
        
        let vc = settingsStoryboard.instantiateViewController(withIdentifier: String.init(describing: IconSelectionTableViewController.self)) as! IconSelectionTableViewController
        
        return vc
    }()
    @objc lazy var fullPlayerVC: FullPlayerTableViewController = {
        
        let vc = settingsStoryboard.instantiateViewController(withIdentifier: String.init(describing: FullPlayerTableViewController.self)) as! FullPlayerTableViewController
        
        return vc
    }()
    @objc lazy var libraryRefreshVC: LibraryRefreshTableViewController = {
        
        let vc = settingsStoryboard.instantiateViewController(withIdentifier: String.init(describing: LibraryRefreshTableViewController.self)) as! LibraryRefreshTableViewController
        
        return vc
    }()
    @objc lazy var recentsVC: RecentsTableViewController = {
        
        let vc = settingsStoryboard.instantiateViewController(withIdentifier: String.init(describing: RecentsTableViewController.self)) as! RecentsTableViewController
        
        return vc
    }()
    @objc var activeViewController: UIViewController? {
        
        didSet {
            
            if firstLaunch {
                
                updateActiveViewController()
                firstLaunch = false
                
            } else {
                
                changeActiveViewControllerFrom(oldValue)
            }
        }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        animator.interactor.add(to: self)
        prepare(animated: false, updateConstraintsAndButtons: true)
        
        modalIndex += 1
        
        if #available(iOS 11, *) {
            
            view.accessibilityIgnoresInvertColors = darkTheme
        }
        
        if useConstraintConstant {
            
            parentViewLeadingConstraint.constant = UIScreen.main.bounds.width * 0.6
            parentViewTrailingConstraint.constant = -UIScreen.main.bounds.width * 0.6
        }
        
        activeViewController = {
            
            switch context {
                
                case .playlists: return playlistsVC
                
                case .upNext: return queueTVC
                
                case .items: return queueVC
                
                case .newPlaylist: return newPlaylistVC
                
                case .settings: return settingsVC
                
                case .tips: return tipsVC
                
                case .queue: return qVC
                
                case .playlistDetails: return textVC
                
                case .info: return newOptionsVC
                
                case .songDetails: return songDetailsVC
                
                case .queueGuard: return queueGuardVC
                
                case .theme: return themeVC
                
                case .gestures: return gesturesVC
                
                case .playback: return playbackVC
                
                case .tabBar: return tabBarVC
                
                case .background: return backgroundVC
                
                case .filter: return filterVC
                
                case .artwork: return artworkVC
                
                case .icon: return iconVC
                
                case .fullPlayer: return fullPlayerVC
                
                case .libraryRefresh: return libraryRefreshVC
                
                case .recents: return recentsVC
            }
        }()
        
        if context == .info, Settings.isInDebugMode {
        
            textField.isHidden = true
            textField.delegate = self
            
            let button = MELButton.init(frame: .init(x: 0, y: 0, width: 30, height: 30))
            button.setImage(#imageLiteral(resourceName: "More13"), for: .normal)
            button.addTarget(self, action: #selector(changeValue), for: .touchUpInside)
            textField.rightView = button
            textField.rightViewMode = .always
        }
        
        notifier.addObserver(self, selector: #selector(unwindToStart), name: .endQueueModification, object: nil)
        notifier.addObserver(self, selector: #selector(updateStatusBar), name: .themeChanged, object: nil)
        
        let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(unwindToMain(_:)))
        gr.minimumPressDuration = longPressDuration
        leftButton.addGestureRecognizer(gr)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: gr))
        
        let edgeGR = UILongPressGestureRecognizer.init(target: self, action: #selector(unwindToMain(_:)))
        edgeGR.minimumPressDuration = longPressDuration
        edgeGR.delegate = self
        view.addGestureRecognizer(edgeGR)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: edgeGR))
    }
    
    @objc func updateTextField() {
        
        textField.isHidden = !textField.isHidden
        titleLabel.isHidden = !titleLabel.isHidden
    }
    
    @objc func updateStatusBar() {
        
        setNeedsStatusBarAppearanceUpdate()
        
        if #available(iOS 11, *) {
            
            view.accessibilityIgnoresInvertColors = darkTheme
        }
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        if toBeDismissed?.needsDismissal == true {
            
            toBeDismissed?.dismiss(animated: true, completion: nil)
        }
        
        modalIndex = max(modalIndex - 1, 0)
    }
    
    @objc func changeValue() {
        
        let oldValue = valueFor
        
        switch oldValue {
            
            case .property: valueFor = .selector
                
            case .selector: valueFor = .property
        }
    }
    
    @objc func unwindToMain(_ gr: UILongPressGestureRecognizer) {
        
        if gr.state == .began {
            
            performSegue(withIdentifier: "unwind", sender: self)
        }
    }
    
    @objc func unwindToStart() {
        
        guard context != .filter else { return }
        
        performSegue(withIdentifier: "unwind", sender: nil)
        
        if context == .settings {
            
            notifier.post(name: .settingsDismissed, object: nil)
        }
    }
    
    @objc func tap(_ sender: UITapGestureRecognizer) {
        
        if sender.state == .ended {
            
            dismissVC()
        }
    }
    
    @IBAction func dismissVC() {

        dismiss(animated: true, completion: {
        
            if self.context == .settings {
                
                notifier.post(name: .settingsDismissed, object: nil)
            }
        })
        
        view.endEditing(true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        return darkTheme ? .lightContent : .default
    }
    
    @objc func prepare(animated: Bool, updateConstraintsAndButtons: Bool = false) {
        
        if updateConstraintsAndButtons {
            
            topConstraint.constant = 12 + (index * 10)
        }
        
        let text: String = {
            
            switch context {
                
                case .items: return "\((self.manager?.queue ?? self.itemsToAdd).count.formatted) Collected \((self.manager?.queue ?? self.itemsToAdd).count.countText(for: .song).capitalized)"
                    
                case .newPlaylist: return self.manager != nil || !itemsToAdd.isEmpty ? "New Playlist " + "(" + (self.manager?.queue ?? self.itemsToAdd).count.formatted + ")" : "New Playlist"
                    
                case .info:
                    
                    let prefix: String = {
                        
                        switch optionsContext {
                        
                            case .song: return "Song"
                            
                            case .collection(kind: let kind, _, _):
                            
                                switch kind {
                                    
                                    case .artist, .albumArtist: return "Artist"
                                    
                                    case .composer: return "Composer"
                                    
                                    case .genre: return "Genre"
                                }
                            
                            case .album: return "Album"
                            
                            case .playlist: return "Playlist"
                        }
                    }()
                    
                    return prefix + " " + "Info"
                    
                case .playlists: return "Add \((self.manager?.queue ?? self.itemsToAdd).count.fullCountText(for: .song)) to..."
                    
                case .queue: return "Queue" + musicPlayer.fullQueueCount(withInitialSpace: true)
                    
                case .settings: return "Settings"
                    
                case .tips: return "Tips"
                
                case .playlistDetails: return "Playlist Details"
                    
                case .upNext: return "\(shuffled ? .shuffle() : "Play") \((self.manager?.queue ?? query?.items ?? self.itemsToAdd).count.fullCountText(for: .song).capitalized) After..."
                
                case .songDetails: return "Secondary Info"
                
                case .queueGuard: return "Queue"
                
                case .theme: return "Theme"
                
                case .gestures: return "Gestures"
                
                case .playback: return "Playback"
                
                case .tabBar: return "Tab Bar"
                
                case .background: return "Background"
                
                case .filter: return "Previous Searches"
                
                case .artwork: return "Artwork"
                
                case .icon: return "App Icon"
                
                case .fullPlayer: return "Fullscreen Player"
                
                case .libraryRefresh: return "Library Refresh"
                
                case .recents: return "Recents"
            }
        }()
        
        if animated {
            
            UIView.transition(with: titleLabel, duration: 0.3, options: .transitionCrossDissolve, animations: { self.titleLabel.text = text }, completion: nil)
            
        } else {
            
            titleLabel.text = text
        }
    
        switch context {
            
            case /*.items, */.upNext: break
            
            case .filter:
            
                if updateConstraintsAndButtons {
                    
                    rightButton.alpha = 0
                    rightBorderView.alpha = 0
                }
            
            case .info:

                if updateConstraintsAndButtons {
                    
                    if isInDebugMode {
                        
                        rightButton.setImage(nil, for: .normal)
                        updateRightButton()
                        
                    } else {
                        
                        rightButton.isHidden = true
                        rightBorderView.isHidden = true
                    }
                }
            
            case .newPlaylist, /*.playlists,*/ .playlistDetails:
                
                if updateConstraintsAndButtons {
                    
                    rightButton.setImage(#imageLiteral(resourceName: "Check"), for: .normal)
                }
            
            case .settings:
                
                if updateConstraintsAndButtons {
                    
                    rightButton.setImage(#imageLiteral(resourceName: "Lightbulb"), for: .normal)
                }
            
            case .tips, .playlists, .songDetails, .queueGuard, .theme, .gestures, .playback, .tabBar, .background, .artwork, .icon, .fullPlayer, .libraryRefresh, .recents, .items:
                
                if updateConstraintsAndButtons {
                    
                    rightButton.isHidden = true
                    rightBorderView.isHidden = true
                }
                        
            case .queue:
                
                if updateConstraintsAndButtons {
                    
                    rightButton.isHidden = !Settings.isInDebugMode
                    rightBorderView.isHidden = !Settings.isInDebugMode
                    rightButton.setImage(#imageLiteral(resourceName: "History13"), for: .normal)
                    rightButton.imageEdgeInsets.left = 1
                    rightButton.imageEdgeInsets.bottom = 1
                }
        }
    }
    
    func updateRightButton() {
        
        rightButton.setTitle(valueFor.rawValue, for: .normal)
    }
    
    private func removeInactiveViewController(inactiveViewController: UIViewController?) {
        
        if let inActiveVC = inactiveViewController {
            
            // call before removing child view controller's view from hierarchy
            inActiveVC.willMove(toParent: nil)
            
            inActiveVC.view.removeFromSuperview()
            
            // call after removing child view controller's view from hierarchy
            inActiveVC.removeFromParent()
        }
    }
    
    private func updateActiveViewController() {
        
        if let activeVC = activeViewController {
            
            // call before adding child view controller's view as subview
            addChild(activeVC)
            
            // call before adding child view controller's view as subview
            activeVC.didMove(toParent: self)
            containerView.addSubview(activeVC.view)
            activeVC.view.frame = containerView.bounds
        }
    }
    
    @objc func changeActiveViewControllerFrom(_ vc: UIViewController?) {
        
        guard let activeVC = activeViewController, let inActiveVC = vc else { return }
        
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
    
    @IBAction func rightButtonTapped() {
        
        switch context {
            
            case .newPlaylist: newPlaylistVC.createPlaylist()
            
            case .settings: settingsVC.performSegue(withIdentifier: "toTips", sender: nil)
            
            case .queue: break
            
            case .playlists: break
            
            case .filter: filterVC.clearRecentSearches()
            
            case .info:
            
                guard isInDebugMode else { break }
            
                updateTextField()
            
            case .playlistDetails:
            
                newVC?.creatorText = textVC.searchBar.text
                newVC?.descriptionText = textVC.textView.text
            
                dismissVC()
            
            case .songDetails, .tips, .queueGuard, .theme, .gestures, .playback, .tabBar, .background, .artwork, .icon, .fullPlayer, .libraryRefresh, .recents, .items: break
            
            case /*.items,*/ .upNext:
                
                let removeItems = UIAlertAction.init(title: "Discard Collected", style: .destructive, handler: { _ in
                    
                    notifier.post(name: .endQueueModification, object: nil)
                })
                
                present(UniversalMethods.alertController(withTitle: nil, message: nil, preferredStyle: .actionSheet, actions: removeItems, UniversalMethods.cancelAlertAction()), animated: true, completion: nil)
        }
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
//            UniversalMethods.banner(withTitle: "PCVC going away...").show(for: 0.3)
        }
        
        notifier.removeObserver(self)
    }
}

extension PresentedContainerViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return gestureRecognizer.location(in: view).x < 44
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return Set([ChildContext.queue, .filter]).contains(context) && otherGestureRecognizer is UILongPressGestureRecognizer
    }
}

extension PresentedContainerViewController: UITextFieldDelegate {
    
    @objc func value() -> String? {
        
        switch valueFor {
            
            case .property: return entity().value(forProperty: textField.text!).debugDescription
            
            case .selector: return entity().responds(to: NSSelectorFromString(textField.text!)) ? String(describing: entity().value(forKey: textField.text!)!) : nil
        }
    }
    
    @objc func entity() -> MPMediaEntity {
        
        switch newOptionsVC.context {
            
            case .song(location: _, at: let index, within: let items): return items[index]
            
            case .album(at: let index, within: let collections): return collections[index]
            
            case .playlist(at: let index, within: let playlists): return playlists[index]
            
            case .collection(kind: _, at: let index, within: let collections): return collections[index]
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        let newBanner = Banner.init(title: value(), subtitle: nil, image: nil, backgroundColor: .black, didTapBlock: {
        
            if let link = URL.init(string: self.value()!) {
                
                UIApplication.shared.openURL(link)
            }
        })
        newBanner.titleLabel.font = UIFont.myriadPro(ofWeight: .regular, size: 15)
        newBanner.show(duration: 0.7)
        
        return true
    }
}
