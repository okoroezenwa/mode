//
//  ContainerViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 11/07/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit
import StoreKit

class ContainerViewController: UIViewController, QueueManager, AlbumTransitionable, ArtistTransitionable, AlbumArtistTransitionable, ComposerTransitionable, GenreTransitionable, InteractivePresenter, TimerBased, SingleItemActionable, EntityVerifiable, Detailing, ArtworkModifierContaining, ChildContaining {

    @IBOutlet var effectView: MELVisualEffectView!
    @IBOutlet var effectViewTopSuperviewConstraint: NSLayoutConstraint!
    @IBOutlet var effectViewBottomSuperviewConstraint: NSLayoutConstraint!
    @IBOutlet var effectViewBottomEffectViewConstraint: NSLayoutConstraint!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var altImageView: InvertIgnoringImageView!
    @IBOutlet var nowPlayingView: UIView!
    @IBOutlet var filterViewContainer: FilterViewContainer! {
        
        didSet {
            
            guard let startPoint = StartPoint(rawValue: lastUsedTab) else { return }
            
            switch startPoint {
                
                case .library:
                    
                    filterViewContainer.context = .library
                
                case .search:
                    
                    guard let searchVC = searchNavigationController?.viewControllers.first as? SearchViewController else { return }
                    
                    filterViewContainer.context = .filter(filter: searchVC, container: searchVC)
            }
        }
    }
    @IBOutlet var bottomEffectView: MELVisualEffectView!
    
    @IBOutlet var songName: MELLabel!
    @IBOutlet var artistAndAlbum: MELLabel!
    @IBOutlet var albumArt: UIImageView!
    @IBOutlet var collectedButton: MELButton!
    @IBOutlet var altPlayPauseButton: MELButton?
    @IBOutlet var playPauseButton: MELButton!
    @IBOutlet var playPauseButtonBorder: UIView!
    @IBOutlet var playShuffleButton: MELButton!
    @IBOutlet var collectedUpNextButton: MELButton!
    @IBOutlet var upNextButton: MELButton!
    @IBOutlet var nowPlayingButton: UIButton!
    @IBOutlet var timeSlider: MELSlider!
    @IBOutlet var containerView: UIView!
    @IBOutlet var tabView: UIView!
    @IBOutlet var searchButton: MELButton!
    @IBOutlet var libraryButton: MELButton!
    @IBOutlet var collectedView: UIView!
    @IBOutlet var clearButton: MELButton!
    @IBOutlet var altQueueView: UIView!
    @IBOutlet var addButtonLeadingConstraint: NSLayoutConstraint?
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var bottomEffectViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var collectedUpNextViewEqualWidthConstraint: NSLayoutConstraint!
    @IBOutlet var collectedUpNextViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var editButton: MELButton! {
        
        didSet {
            
            editButton.addTarget(songManager, action: #selector(SongActionManager.showActionsForAll(_:)), for: .touchUpInside)
        }
    }
    @IBOutlet var infoViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var infoView: UIView!
    @IBOutlet var altNowPlayingView: UIView!
    @IBOutlet var altAlbumArt: UIImageView!
    @IBOutlet var altNowPlayingButton: MELButton!
    @IBOutlet var altNowPlayingViewSuperview: UIView!
    @IBOutlet var artworkContainer: UIView!
    @IBOutlet var actionsButton: UIButton! {
        
        didSet {
            
            let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(showSettings(with:)))
            gr.minimumPressDuration = longPressDuration
            actionsButton.addGestureRecognizer(gr)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: gr))
        }
    }
    
    enum CollectorActions { case play, queue, shuffleSongs, shuffleAlbums, existingPlaylist, newPlaylist, clear }
    
    lazy var visualEffectNavigationBar = Bundle.main.loadNibNamed("VisualEffectNavigationBar", owner: nil, options: nil)?.first as! VisualEffectNavigationBar
    lazy var effectViewTopEffectViewConstraint: NSLayoutConstraint = {
        
        let constraint = effectView.topAnchor.constraint(equalTo: visualEffectNavigationBar.bottomAnchor)
        constraint.priority = .init(800)
        constraint.isActive = true
        
        return constraint
    }()

    @objc var activeChildViewController: UIViewController? {
        
        get { return activeViewController }
        
        set { activeViewController = newValue as? UINavigationController /* changed from activeChildViewController to newValue in Xcode 11*/ }
    }
    
    var viewControllerSnapshot: UIView? { didSet { oldValue?.removeFromSuperview() } }
    
    @objc var actionableSongs: [MPMediaItem] { return [musicPlayer.nowPlayingItem].compactMap({ $0 }) }
    var applicableActions: [SongAction] {
        
        var actions = [SongAction.collect, .newPlaylist, .addTo]
        
        if musicPlayer.nowPlayingItem?.existsInLibrary == false {
            
            actions.insert(.library, at: 1)
        }
        
        return actions
    }
    @objc lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    
    @objc lazy var queue = [MPMediaItem]()
    var shuffled = false {
        
        didSet {
            
            playShuffleButton.setImage(shuffled ? #imageLiteral(resourceName: "Shuffle") : #imageLiteral(resourceName: "PlayFilled12"), for: .normal)
            playShuffleButton.imageEdgeInsets.left = shuffled ? 0 : 2
            playShuffleButton.contentEdgeInsets.bottom = shuffled ? 0 : 1
        }
    }
    lazy var reverseShuffle = false
    @objc var inset: CGFloat { return (self.nowPlayingView.isHidden ? 0 : 50) + (self.collectedView.isHidden ? 0 : 44) + 51 + (lastUsedTab == StartPoint.library.rawValue || filterViewContainer.filterView.withinSearchTerm ? 36 : 88) }
    @objc var currentItem: MPMediaItem?
    @objc var albumQuery: MPMediaQuery?
    var albumArtistQuery: MPMediaQuery?
    var genreQuery: MPMediaQuery?
    var composerQuery: MPMediaQuery?
    var artistQuery: MPMediaQuery?
    var currentAlbum: MPMediaItemCollection?
    @objc var shouldUseNowPlayingArt = true
    var currentModifier: ArtworkModifying?
    var currentOptionsContaining: OptionsContaining? {
        
        didSet {
            
            guard let options = currentOptionsContaining?.options else { return }
            
            notifier.post(name: .libraryOptionsChanged, object: nil, userInfo: ["options": options])
        }
    }
    var modifier: ArtworkModifying? {
        
        return activeViewController?.topViewController as? ArtworkModifying
    }
    @objc var deferToNowPlayingViewController = false
    @objc var lifetimeObservers = Set<NSObject>()
    @objc let presenter = PresentationAnimationController.init(interactor: InteractionController())
    let playingImage = #imageLiteral(resourceName: "PauseFilled10")
    let pausedImage = #imageLiteral(resourceName: "PlayFilledSmall")
    let pausedInset: CGFloat = 1
    let playPauseButtonNeedsAnimation = true
    var updateableView: UIView? { return nowPlayingView }
    @objc var fromSearchAction = false
    
    @objc lazy var searchNavigationController: UINavigationController? = {
        
        guard let vc = mainChildrenStoryboard.instantiateViewController(withIdentifier: "searchNav") as? UINavigationController else { return nil }
        
        vc.view.clipsToBounds = false
        isSearchNavigationControllerInitialised = true
        
        return vc
    }()
    
    @objc lazy var libraryNavigationController: UINavigationController? = {
        
        guard let vc = mainChildrenStoryboard.instantiateViewController(withIdentifier: "libraryNav") as? UINavigationController else { return nil }
        
        vc.view.clipsToBounds = false
        isLibraryNavigationControllerInitialised = true
        
        return vc
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return darkTheme ? .lightContent : {
        
        if #available(iOS 13, *) { return .darkContent }
        
        return .default
    }() }
    
    @objc var activeViewController: UINavigationController? {
        
        didSet {
            
            guard changeActiveVC else { return }
            
            changeActiveViewControllerFrom(oldValue)
        }
    }
    var changeActiveVC = true
    var isSearchNavigationControllerInitialised = false
    var isLibraryNavigationControllerInitialised = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NowPlaying.shared.container = self
        
        let startPoint = StartPoint(rawValue: lastUsedTab) ?? .library
        
        if startPoint == .search, let searchVC = searchNavigationController?.topViewController as? SearchViewController {
            
            searchVC.animateClearButton = true
        }
        
        activeViewController = viewController(for: startPoint)
        update(button(for: startPoint), to: .selected, animated: false)
        
        updateActiveViewController()
        updateLibraryButtonImage()
        
        updateSliderDuration()
        
        ArtworkManager.shared.container = self
        imageView.image = (activeViewController?.topViewController as? ArtworkModifying)?.artworkType.image
        
        prepareNowPlayingViews(with: musicPlayer.nowPlayingItem, animated: false)
        prepareLifetimeObservers()
        prepareAltAlbumArt()
        
        notifier.addObserver(self, selector: #selector(updateCornersAndShadows), name: .cornerRadiusChanged, object: nil)
        
        infoView.isHidden = !showInfoButtons
        infoViewWidthConstraint.constant = showInfoButtons ? 50 : 0
            
        view.addSubview(visualEffectNavigationBar)
        visualEffectNavigationBar.translatesAutoresizingMaskIntoConstraints = false
        
        visualEffectNavigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        visualEffectNavigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        visualEffectNavigationBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        
        let constraint = visualEffectNavigationBar.stackView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: VisualEffectNavigationBar.Location.main.constant)
        visualEffectNavigationBar.stackViewTopConstraint = constraint
        constraint.isActive = true
        
        visualEffectNavigationBar.prepareArtwork(for: activeViewController?.topViewController as? Navigatable)
        visualEffectNavigationBar.prepareRightButton(for: activeViewController?.topViewController as? Navigatable)
        
        updateEffectViewConstraints(animated: false)
        
        modifyPlayPauseButton()
        updateCollectedUpNextView(animated: false)
        prepareGestures()
        
        registerForPreviewing(with: self, sourceView: bottomEffectView.contentView)
        
        UniversalMethods.addShadow(to: playPauseButtonBorder, path: UIBezierPath.init(roundedRect: playPauseButtonBorder.bounds, cornerRadius: 12).cgPath)
        
        updateCornersAndShadows()
        updateNowPlayingView()
        
        getCollected()
        Queue.shared.verifyQueue()
    }
    
    func updateEffectViewConstraints(animated: Bool) {
        
        effectViewTopEffectViewConstraint.priority = .init(Set([BarBlurBehavour.none, .bottom]).contains(barBlurBehaviour) ? 801 : 799)
        effectViewBottomEffectViewConstraint.priority = .init(Set([BarBlurBehavour.none, .top]).contains(barBlurBehaviour) ? 801 : 799)
        
        if animated { UIView.animate(withDuration: 0.3, animations: { self.view.layoutIfNeeded() }) }
    }
    
    func updateLibraryButtonImage() {
        
        var image: UIImage {
            
            if showiCloudItems {
                
                return lastUsedTab == StartPoint.library.rawValue ? #imageLiteral(resourceName: "CloudSelected24") : #imageLiteral(resourceName: "Cloud24")
                
            } else {
                
                return lastUsedTab == StartPoint.library.rawValue ? #imageLiteral(resourceName: "OfflineSelected22") : #imageLiteral(resourceName: "Offline22")
            }
        }
        
        libraryButton.setImage(image, for: .normal)
        
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            
            self.libraryButton.superview?.layoutIfNeeded()
            
        }, completion: nil)
    }
    
    @objc func getCollected() {
        
        guard let data = prefs.object(forKey: .collectedItems) as? Data, let queue = NSKeyedUnarchiver.unarchiveObject(with: data) as? [MPMediaItem], !queue.isEmpty else { return }
        
        self.queue = queue
        modifyCollectedButton(forState: .invoked)
        updateCollectedText(animated: false)
    }
    
    @objc func updateCollectedText(animated: Bool = true) {
        
        collectedButton.setTitle(queue.count.formatted, for: .normal)
        
        UIView.transition(with: filterViewContainer.filterView.collectedLabel, duration: animated ? 0.3 : 0, options: .transitionCrossDissolve, animations: { self.filterViewContainer.filterView.collectedLabel.text = self.queue.count.formatted }, completion: nil)
        
        if animated {
            
            UIView.animate(withDuration: 0.3, animations: { self.view.layoutIfNeeded() })
        }
    }
    
    @objc func saveCollected() {
        
        let savedData = NSKeyedArchiver.archivedData(withRootObject: queue)
        prefs.set(savedData, forKey: .collectedItems)
    }
    
    @objc func prepareGestures() {
        
        let clear = UILongPressGestureRecognizer.init(target: self, action: #selector(clearItemsImmediately(_:)))
        clear.minimumPressDuration = longPressDuration
        clearButton.addGestureRecognizer(clear)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: clear))
        
        let optionsHold = UILongPressGestureRecognizer.init(target: self, action: #selector(showOptions(_:)))
        optionsHold.minimumPressDuration = longPressDuration
        nowPlayingButton.addGestureRecognizer(optionsHold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: optionsHold))
        
        let altOptionsHold = UILongPressGestureRecognizer.init(target: self, action: #selector(showNowPlayingActions(_:)))
        altOptionsHold.minimumPressDuration = longPressDuration
        altNowPlayingButton.addGestureRecognizer(altOptionsHold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: altOptionsHold))
        
        let swipeLeft = UISwipeGestureRecognizer.init(target: self, action: #selector(goTo))
        swipeLeft.direction = .left
        nowPlayingButton.addGestureRecognizer(swipeLeft)
        
        let altSwipeLeft = UISwipeGestureRecognizer.init(target: self, action: #selector(goTo))
        altSwipeLeft.direction = .left
        altSwipeLeft.delegate = self
        tabView.addGestureRecognizer(altSwipeLeft)
        
        let queueSwipeLeft = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(performAuxillaryNowPlayingAction))
        queueSwipeLeft.edges = .right//direction = .left
        upNextButton.addGestureRecognizer(queueSwipeLeft)
            
        let altQueueSwipeLeft = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(performAuxillaryNowPlayingAction))
        altQueueSwipeLeft.edges = .right//direction = .left
        altNowPlayingButton.addGestureRecognizer(altQueueSwipeLeft)
        
        let swipeUp = UISwipeGestureRecognizer.init(target: self, action: #selector(goToNowPlaying))
        swipeUp.direction = .up
        nowPlayingButton.addGestureRecognizer(swipeUp)
    }
    
    @objc func doubleTap(_ sender: UITapGestureRecognizer) {
        
        guard sender.view != altNowPlayingButton else {
            
            showOptions(self)
            
            return
        }
        
        let expectedNVC: UINavigationController? = {
            
            if sender.view == libraryButton {
                
                return libraryNavigationController
                
            } else {
                
                return searchNavigationController
            }
        }()
        
        if activeViewController != expectedNVC {
            
            changeActiveVC = false
            let oldVC = activeViewController
            switchViewController(button(for: expectedNVC))
            changeActiveViewControllerFrom(oldVC, completion: { UniversalMethods.performOnMainThread({ notifier.post(name: .performSecondaryAction, object: self.activeViewController) }, afterDelay: 0.1) })
            changeActiveVC = true
            
        } else {
            
            notifier.post(name: .performSecondaryAction, object: activeViewController)
        }
    }
    
    @objc func performAuxillaryNowPlayingAction(_ sender: UIGestureRecognizer) {
        
        guard sender.state == .began, let _ = musicPlayer.nowPlayingItem else { return }
        
        performSegue(withIdentifier: "queue", sender: nil)
    }
    
    @objc func showNowPlayingActions(_ sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
            
            case .began: presentActions()
            
            case .changed, .ended:
            
                guard useSystemAlerts.inverted, let verticalPresentedVC = presentedViewController as? VerticalPresentationContainerViewController else { return }
            
                verticalPresentedVC.gestureActivated(sender)
            
            default: break
        }
    }
    
    @objc func presentActions() {
        
        guard let item = musicPlayer.nowPlayingItem else { return }
        
        var actions = [SongAction.collect, .newPlaylist, .addTo].map({ singleItemAlertAction(for: $0, entity: .song, using: item, from: self) })
        
        actions.insert(.init(title: "Get Info", style: .default, requiresDismissalFirst: true, handler: { [weak self] in
            
            guard let weakSelf = self else { return }
            
            Transitioner.shared.showInfo(from: weakSelf, with: .song(location: .list, at: 0, within: [item]))
            
        }), at: 1)
        
        if item.existsInLibrary.inverted {
            
            actions.insert(singleItemAlertAction(for: .library, entity: .song, using: item, from: self), at: 2)
        }
        
        showAlert(title: item.validArtist + " — " + item.validAlbum, with: actions)
    }
    
    @objc func performPlayingItemActions(_ sender: UISwipeGestureRecognizer) {
        
        switch sender.direction {
            
            case UISwipeGestureRecognizer.Direction.right: NowPlaying.shared.changePlaybackState()
            
            case UISwipeGestureRecognizer.Direction.left: showOptions(self)
            
            case UISwipeGestureRecognizer.Direction.up: guardQueue(with: .stop, onCondition: true, fallBack: { NowPlaying.shared.stopPlayback() })
            
            default: break
        }
    }
    
    @objc func goToNowPlaying() {
        
        performSegue(withIdentifier: "nowPlaying", sender: nil)
    }
    
    @objc func updateCollectedUpNextView(animated: Bool = false) {
        
        collectedUpNextViewWidthConstraint.priority = UILayoutPriority(rawValue: musicPlayer.nowPlayingItem == nil ? 999 : 250)
        collectedUpNextViewEqualWidthConstraint.priority = UILayoutPriority(rawValue: musicPlayer.nowPlayingItem == nil ? 250 : 999)

        if animated {
            
            UIView.animate(withDuration: 0.3, animations: {
                
                self.collectedView.layoutIfNeeded()
                self.collectedUpNextButton.superview?.alpha = musicPlayer.nowPlayingItem == nil ? 0 : 1
            })
        
        } else {
            
            collectedUpNextButton.superview?.alpha = musicPlayer.nowPlayingItem == nil ? 0 : 1
        }
    }
    
    func updateNowPlayingView(animated: Bool = false) {
        
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            
            self.nowPlayingView.isHidden = useMicroPlayer || musicPlayer.nowPlayingItem == nil
            self.nowPlayingView.alpha = useMicroPlayer || musicPlayer.nowPlayingItem == nil ? 0 : 1
            self.nowPlayingView.superview?.layoutIfNeeded()
            
            self.altNowPlayingViewSuperview.isHidden = useMicroPlayer.inverted
            self.altNowPlayingViewSuperview.alpha = useMicroPlayer ? 1 : 0
            self.altQueueView.isHidden = useMicroPlayer.inverted
            self.altQueueView.alpha = useMicroPlayer ? 1 : 0
            
        }, completion: { [weak self] _ in
            
            guard let weakSelf = self, let superview = weakSelf.actionsButton.superview, let stackView = superview.superview as? UIStackView else { return }
            
            stackView.insertArrangedSubview(superview, at: useMicroPlayer ? 2 : 1)
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *), appTheme == .system, traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            
            Themer.shared.changeTheme(to: .system, changePreference: false)
        }
    }
    
    func prepareAltAlbumArt() {
        
        altAlbumArt.backgroundColor = Themer.borderViewColor()
    }
    
    @objc func prepareLifetimeObservers() {
        
//        lifetimeObservers.insert(notifier.addObserver(forName: .playerChanged, object: nil, queue: nil, using: { [weak self] _ in
//            
//            guard let weakSelf = self else { return }
//            
//            weakSelf.prepareNowPlayingViews(with: musicPlayer.nowPlayingItem, animated: true)
//
//            weakSelf.updateBackgroundWithNowPlaying()
//            
//            weakSelf.updateSliderDuration()
//            weakSelf.updateTimes(setValue: true, seeking: false)
//            weakSelf.updateCollectedUpNextView(animated: true)
//        
//        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .nowPlayingItemChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.prepareNowPlayingViews(with: musicPlayer.nowPlayingItem, animated: true)
            
            if ArtworkManager.shared.currentlyPeeking == nil {
            
                UIView.transition(with: weakSelf.imageView, duration: 0.3, options: .transitionCrossDissolve, animations: { weakSelf.imageView.image = ArtworkManager.shared.activeContainer?.modifier?.artworkType.image }, completion: nil)
            }
            
            weakSelf.updateSliderDuration()
            weakSelf.updateTimes(setValue: true, seeking: false)
            weakSelf.updateCollectedUpNextView(animated: true)
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .microPlayerChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateNowPlayingView(animated: true)
            
            notifier.post(name: .resetInsets, object: nil)
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .iCloudVisibilityChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
        
            weakSelf.updateLibraryButtonImage()
            
        }) as! NSObject)
        
        if firstAuthorisation {
            
            lifetimeObservers.insert(notifier.addObserver(forName: .updateForFirstLaunch, object: appDelegate, queue: nil, using: { _ in
                
                UniversalMethods.performInMain {
                    
                    guard appDelegate.musicLibraryStatus == .authorized else {
                        
                        return
                    }
                    
                    switch musicPlayer.playbackState {
                        
                    case .stopped: NowPlaying.shared.stopPlayback()
                        
                    default:
                        
                        if musicPlayer.isPlaying {
                            
                            musicPlayer.pause()
                            musicPlayer.play()
                            
                        } else {
                            
                            musicPlayer.pause()
                        }
                    }
                    
                    notifier.post(name: Notification.Name.init("updateSection"), object: nil)
                    
                    self.prepareNowPlayingViews(with: musicPlayer.nowPlayingItem, animated: true)
                    self.updateBackgroundWithNowPlaying()
                    self.updateSliderDuration()
                }
                
            }) as! NSObject)
        }
        
        lifetimeObservers.insert(notifier.addObserver(forName: .endQueueModification, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.modifyCollectedButton(forState: .dismissed)
            weakSelf.queue.removeAll()
            weakSelf.saveCollected()
            weakSelf.shuffled = false
            
            notifier.post(name: .managerItemsChanged, object: nil)
        
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .addedToQueue, object: nil, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self, let items = notification.userInfo?[DictionaryKeys.queueItems] as? [MPMediaItem] else { return }
            
            let wasZero = weakSelf.queue.count == 0
            
            weakSelf.queue += items
            
            if !weakSelf.queue.isEmpty && collectorPreventsDuplicates {
                
                weakSelf.queue.removeDuplicates()
            }
            
            if wasZero && weakSelf.queue.count > 0 {
                
                weakSelf.modifyCollectedButton(forState: .invoked)
            }
            
            notifier.post(name: .managerItemsChanged, object: nil)
            weakSelf.saveCollected()
            
            weakSelf.updateCollectedText()
        
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .removedFromQueue, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            if weakSelf.queue.count == 0 {
                
                weakSelf.modifyCollectedButton(forState: .dismissed)
            }
            
            notifier.post(name: .managerItemsChanged, object: nil)
            
            weakSelf.saveCollected()
            weakSelf.updateCollectedText()
        
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .songsAddedToPlaylists, object: nil, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self, let song = musicPlayer.nowPlayingItem, let songs = notification.userInfo?[String.addedSongs] as? [MPMediaItem], Set(songs).contains(song) else { return }
            
            weakSelf.updateAddButton(hidden: true, animated: true)
        
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: UIApplication.willEnterForegroundNotification, object: UIApplication.shared, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.verifyLibraryStatus(of: musicPlayer.nowPlayingItem, itemProperty: .song, animated: false)
        
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .appleMusicStatusChecked, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.verifyLibraryStatus(of: musicPlayer.nowPlayingItem, itemProperty: .song, animated: true)
        
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .infoButtonVisibilityChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.infoView.isHidden = !showInfoButtons
            weakSelf.infoViewWidthConstraint.constant = showInfoButtons ? 50 : 0
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .themeChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.setNeedsStatusBarAppearanceUpdate()
            
            weakSelf.prepareAltAlbumArt()
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: UIApplication.willChangeStatusBarFrameNotification, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self, let window = appDelegate.window else { return }
            
            weakSelf.view.frame = window.frame
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .collectorSizeChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self, weakSelf.queue.count > 0 else { return }
            
            weakSelf.modifyCollectedButton(forState: .invoked)
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .barBlurBehaviourChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateEffectViewConstraints(animated: true)
            
        }) as! NSObject)
    }
    
    @objc func updateCornersAndShadows() {
        
        ([albumArt, altAlbumArt] as [UIImageView]).forEach({ imageView in
            
            let appropriateRadius = imageView == albumArt ? miniPlayerCornerRadius ?? .square : compactCornerRadius ?? .large
            
            appropriateRadius.updateCornerRadius(on: imageView.layer, width: imageView.bounds.width, entityType: .song, globalRadiusType: cornerRadius)
        })
        
        UniversalMethods.addShadow(to: altNowPlayingView, radius: 6, opacity: 0.25, shouldRasterise: true)
        UniversalMethods.addShadow(to: artworkContainer, shouldRasterise: true)
    }
    
    @IBAction func goToLibraryOptions() {
        
        guard let options = currentOptionsContaining?.options, let vc: UIViewController = {
            
            let vc = popoverStoryboard.instantiateViewController(withIdentifier: "actionsVC")
            vc.modalPresentationStyle = .popover
            
            return Transitioner.shared.transition(to: vc, using: options, sourceView: actionsButton)
            
        }() else { return }
        
        present(vc, animated: true, completion: nil)
    }
    
    func goToDetails(basedOn entity: Entity) -> (entities: [Entity], albumArtOverride: Bool) {
        
        return ([Entity.artist, .genre, .album, .composer, .albumArtist], true)
    }
    
    @objc func goTo(_ sender: Any) {
        
        guard let song = musicPlayer.nowPlayingItem else { return }
        
        singleItemActionDetails(for: .show(title: song.validTitle, context: .song(location: .list, at: 0, within: [song]), canDisplayInLibrary: true), entity: .song, using: song, from: self, useAlternateTitle: true).handler()
    }
    
    func viewController(for startPoint: StartPoint) -> UINavigationController? {
        
        switch startPoint {
            
            case .library: return libraryNavigationController
            
            case .search: return searchNavigationController
        }
    }
    
    func button(for startPoint: StartPoint) -> UIButton {
        
        switch startPoint {
            
            case .library: return libraryButton
            
            case .search: return searchButton
        }
    }
    
    @objc func button(for vc: UINavigationController?) -> UIButton {
        
        switch vc {
            
            case .some(libraryNavigationController!): return libraryButton
            
            case .some(searchNavigationController!): return searchButton
            
            default: fatalError("These should be the only child NVCs")
        }
    }
    
    func controller(for button: UIButton) -> UINavigationController? {
        
        switch button {
            
            case searchButton: return searchNavigationController
            
            case libraryButton: return libraryNavigationController
            
            default: return nil
        }
    }
    
    func startPoint(for button: UIButton) -> StartPoint {
        
        switch button {
            
            case searchButton: return .search
            
            case libraryButton: return .library
            
            default: fatalError("These should be the only start points")
        }
    }
    
    @objc func postNotification() {
        
        notifier.post(name: .performSecondaryAction, object: activeViewController)
    }
    
    @IBAction func showOptions(_ sender: Any) {
        
        if let sender = sender as? UILongPressGestureRecognizer {
            
            guard sender.state == .began else { return }
        }
        
        guard musicPlayer.nowPlayingItem != nil else { return }
        
        Transitioner.shared.showInfo(from: self, with: .song(location: .queue(loaded: false, index: Queue.shared.indexToUse), at: 0, within: [musicPlayer.nowPlayingItem].compactMap({ $0 })))
    }
    
    @IBAction func clearItems(_ sender: Any) {
        
        if let sender = sender as? UILongPressGestureRecognizer {
            
            guard sender.state == .began else { return }
        }
        
        let remove = AlertAction.init(title: "Discard Collected", style: .destructive, handler: { notifier.post(name: .endQueueModification, object: nil) })
        
        showAlert(title: nil, with: remove)
        
//        let alert = UniversalMethods.alertController(withTitle: nil, message: nil, preferredStyle: .actionSheet, actions: removeItems, cancel)
//
//        present(alert, animated: true, completion: nil)
    }

    @IBAction func clearItemsImmediately(_ gr: UILongPressGestureRecognizer) {
        
        if gr.state == .began {
            
            notifier.post(name: .endQueueModification, object: nil)
        }
    }
    
//    private func removeInactiveViewController(inactiveViewController: UIViewController?) {
//
//        if let inActiveVC = inactiveViewController {
//
//            // call before removing child view controller's view from hierarchy
//            inActiveVC.willMove(toParent: nil)
//
//            UIView.animate(withDuration: 0.3, animations: {
//
//                inActiveVC.view.transform = CGAffineTransform.init(translationX: 0, y: 50)
//                inActiveVC.view.alpha = 0
//
//            }, completion: { _ in
//
//                inActiveVC.view.transform = CGAffineTransform.identity
//                inActiveVC.view.removeFromSuperview()
//
//                // call after removing child view controller's view from hierarchy
//                inActiveVC.removeFromParent()
//            })
//        }
//    }
    
    func unwindToAlbum(from vc: AlbumTransitionable) {
        
        if let entityVC = activeViewController?.topViewController as? EntityItemsViewController,
            let collections = vc.albumQuery?.collections,
            collections.first?.persistentID == entityVC.collection?.persistentID {
            
            let child = entityVC.albumItemsViewController
            
            UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve, animations: { self.imageView.image = entityVC.artworkType.image }, completion: nil)
            
            entityVC.highlightedEntities?.song = vc.currentItem
            child.highlightedIndex = child.songs.optionalIndex(of: vc.currentItem)
            child.tableView.reloadData() // causes crash at points
            child.animateCells(direction: .vertical, alphaOnly: child.highlightedIndex != nil)
            child.scrollToHighlightedRow()
            
            return
        }
        
        guard let albumQuery = vc.albumQuery,
            let collections = albumQuery.collections,
            let album = collections.first,
            let temp = entityStoryboard.instantiateViewController(withIdentifier: "entityItems") as? EntityItemsViewController,
            let entityVC = Transitioner.shared.transition(to: .album, vc: temp, from: activeViewController?.topViewController, sender: album, highlightedItem: vc.currentItem)
            else { return }
        
        activeViewController?.pushViewController(entityVC, animated: true)
    }
    
    func unwindToArtist(with artistQuery: MPMediaQuery?, item currentItem: MPMediaItem?, album currentAlbum: MPMediaItemCollection?, kind: Entity) {
        
        if let entityVC = activeViewController?.topViewController as? EntityItemsViewController,
            let collections = artistQuery?.collections,
            collections.first?.persistentID == entityVC.collection?.persistentID {
            
            entityVC.highlightedEntities = (currentItem, currentAlbum)
            
            UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve, animations: { self.imageView.image = entityVC.artworkType.image }, completion: nil)
            
            if entityVC.activeChildViewController == entityVC.artistSongsViewController {
                
                let child = entityVC.artistSongsViewController
                
                child.highlightedIndex = child.songs.optionalIndex(of: currentItem)
                child.tableView.reloadData()
                child.animateCells(direction: .vertical, alphaOnly: child.highlightedIndex != nil)
                child.scrollToHighlightedRow()
                
            } else if entityVC.activeChildViewController == entityVC.artistAlbumsViewController {
                
                let child = entityVC.artistAlbumsViewController
                
                child.highlightedIndex = child.albums.optionalIndex(of: currentAlbum)
                child.tableView.reloadData()
                child.animateCells(direction: .vertical, alphaOnly: child.highlightedIndex != nil)
                child.scrollToHighlightedRow()
            }
            
            return
        }
        
        guard let artistQuery = artistQuery,
            let collections = artistQuery.collections,
            let collection = collections.first,
            let temp = entityStoryboard.instantiateViewController(withIdentifier: "entityItems") as? EntityItemsViewController,
            let artistVC = Transitioner.shared.transition(to: kind, vc: temp, from: activeViewController?.topViewController, sender: collection, highlightedItem: currentItem, highlightedAlbum: currentAlbum)
            else { return }
        
        activeViewController?.pushViewController(artistVC, animated: true)
    }
    
    func unwindToPlaylist(from vc: PlaylistTransitionable) {
        
        if let entityVC = activeViewController?.topViewController as? EntityItemsViewController,
            let playlists = vc.playlistQuery?.collections as? [MPMediaPlaylist],
            playlists.first?.persistentID == entityVC.collection?.persistentID {
            
            let child = entityVC.playlistItemsViewController
            
            UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve, animations: { self.imageView.image = entityVC.artworkType.image }, completion: nil)
            
            entityVC.highlightedEntities?.song = vc.currentItem
            child.highlightedIndex = child.songs.optionalIndex(of: vc.currentItem)
            child.tableView.reloadData()
            child.animateCells(direction: .vertical, alphaOnly: child.highlightedIndex != nil)
            child.scrollToHighlightedRow()
            
            return
        }
        
        guard let playlistQuery = vc.playlistQuery,
            let playlists = playlistQuery.collections as? [MPMediaPlaylist],
            let playlist = playlists.first,
            let temp = entityStoryboard.instantiateViewController(withIdentifier: "entityItems") as? EntityItemsViewController,
            let playlistVC = Transitioner.shared.transition(to: .playlist, vc: temp, from: activeViewController?.topViewController, sender: playlist, highlightedItem: vc.currentItem)
            else { return }
        
        activeViewController?.pushViewController(playlistVC, animated: true)
    }
    
    @IBAction func artistUnwind(_ segue: UIStoryboardSegue) {
        
        guard let vc = segue.source as? ArtistTransitionable else { return }
        
        unwindToArtist(with: vc.artistQuery, item: vc.currentItem, album: vc.currentAlbum, kind: .artist)
    }
    
    @IBAction func genreUnwind(_ segue: UIStoryboardSegue) {
        
        guard let vc = segue.source as? GenreTransitionable else { return }
        
        unwindToArtist(with: vc.genreQuery, item: vc.currentItem, album: vc.currentAlbum, kind: .genre)
    }
    
    @IBAction func composerUnwind(_ segue: UIStoryboardSegue) {
        
        guard let vc = segue.source as? ComposerTransitionable else { return }
        
        unwindToArtist(with: vc.composerQuery, item: vc.currentItem, album: vc.currentAlbum, kind: .composer)
    }
    
    @IBAction func albumArtistUnwind(_ segue: UIStoryboardSegue) {
        
        guard let vc = segue.source as? AlbumArtistTransitionable else { return }
        
        unwindToArtist(with: vc.albumArtistQuery, item: vc.currentItem, album: vc.currentAlbum, kind: .albumArtist)
    }
    
    @IBAction func albumUnwind(_ segue: UIStoryboardSegue) {
        
        guard let vc = segue.source as? AlbumTransitionable else { return }
        
        unwindToAlbum(from: vc)
    }
    
    @IBAction func playlistUnwind(_ segue: UIStoryboardSegue) {
        
        guard let vc = segue.source as? PlaylistTransitionable else { return }
        
        unwindToPlaylist(from: vc)
    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) { }
    
    @IBAction func previewUnwind(_ segue: UIStoryboardSegue) {
        
        if let previewer = segue.source as? PreviewTransitionable, let vc = previewer.viewController {

            defer {
                
                [bottomEffectView, containerView, visualEffectNavigationBar].forEach({
                    
                    $0?.transform = .identity
                    $0?.alpha = 1
                })
                
                if let keyWindow = UIApplication.shared.keyWindow, !keyWindow.subviews.contains(view) {
                    
                    UIApplication.shared.keyWindow?.addSubview(view)
                    view.frame = keyWindow.frame.modifiedBy(width: 0, height: isiPhoneX ? 0 : -(UIApplication.shared.statusBarFrame.height - 20)).modifiedBy(x: 0, y: isiPhoneX ? 0 : UIApplication.shared.statusBarFrame.height - 20)
                }
                
                notifier.post(name: .resetInsets, object: nil)
            }
            
            filterViewContainer.filterView.withinSearchTerm = activeViewController == searchNavigationController
            
            if let entityVC = activeViewController?.topViewController as? EntityItemsViewController {
                
                if let playlistVC = entityVC.activeChildViewController as? PlaylistItemsViewController, let previewVC = vc as? EntityItemsViewController, let previewPlaylistVC = previewVC.activeChildViewController as? PlaylistItemsViewController, playlistVC.playlist?.persistentID == previewPlaylistVC.playlist?.persistentID {
                    
                    visualEffectNavigationBar.backLabel.text = entityVC.backLabelText
                    playlistVC.highlightedIndex = previewPlaylistVC.highlightedIndex
                    playlistVC.scrollToHighlightedRow()
                    
                    return
                
                } else if let albumVC = entityVC.activeChildViewController as? AlbumItemsViewController, let previewVC = vc as? EntityItemsViewController, let previewAlbumVC = previewVC.activeChildViewController as? AlbumItemsViewController, albumVC.album?.persistentID == previewAlbumVC.album?.persistentID {
                    
                    visualEffectNavigationBar.backLabel.text = entityVC.backLabelText
                    albumVC.highlightedIndex = previewAlbumVC.highlightedIndex
                    albumVC.scrollToHighlightedRow()
                    
                    return
                    
                } else if let artistSongsVC = entityVC.activeChildViewController as? ArtistSongsViewController, let previewVC = vc as? EntityItemsViewController, let previewArtistSongsVC = previewVC.activeChildViewController as? ArtistSongsViewController, artistSongsVC.artist?.persistentID == previewArtistSongsVC.artist?.persistentID {
                    
                    visualEffectNavigationBar.backLabel.text = entityVC.backLabelText
                    artistSongsVC.highlightedIndex = previewArtistSongsVC.highlightedIndex
                    artistSongsVC.scrollToHighlightedRow()
                    
                    return
                
                } else if let artistAlbumsVC = entityVC.activeChildViewController as? ArtistAlbumsViewController, let previewVC = vc as? EntityItemsViewController, let previewArtistAlbumsVC = previewVC.activeChildViewController as? ArtistAlbumsViewController, artistAlbumsVC.artist?.persistentID == previewArtistAlbumsVC.artist?.persistentID {
                    
                    visualEffectNavigationBar.backLabel.text = entityVC.backLabelText
                    artistAlbumsVC.highlightedIndex = previewArtistAlbumsVC.highlightedIndex
                    artistAlbumsVC.scrollToHighlightedRow()
                    
                    return
                    
                } else {
                    
                    activeViewController?.pushViewController(vc, animated: true)
                }
            
            } else {
                
                activeViewController?.pushViewController(vc, animated: true)
            }
        }
    }
        
    func queuePop(using vc: UIViewController, context: PresentedContainerViewController.ChildContext) {
        
        guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
        
        switch context {
            
            case .items:
                
                presentedVC.queueVC = vc as! CollectorViewController
                presentedVC.manager = self
            
            case .queue: presentedVC.qVC = vc as! QueueViewController
            
            default: break
        }
        
        presentedVC.context = context
        presentedVC.container = self
        presentedVC.viewIfLoaded?.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        present(presentedVC, animated: false, completion: { presentedVC.viewIfLoaded?.backgroundColor = UIColor.black.withAlphaComponent(0.2) })
    }
    
    @objc func prepareEffectView(artworkPresent: Bool) {
        
        if artworkPresent {
            
            effectView.backgroundColor = UIDevice.current.isBlurAvailable ? UIColor.white.withAlphaComponent(0.4) : .clear
            imageView.contentMode = .scaleAspectFill
        
        } else {
            
            effectView.backgroundColor = .clear
            imageView.contentMode = .scaleToFill
        }
    }
    
    @objc func updateBackgroundWithNowPlaying(animated: Bool = true) {
        
        guard backgroundArtworkAdaptivity == .nowPlayingAdaptive || shouldUseNowPlayingArt else { return }
        
        UIView.transition(with: imageView, duration: animated ? 0.45 : 0, options: [.transitionCrossDissolve], animations: { self.imageView.image = musicPlayer.nowPlayingItem?.actualArtwork?.image(at: .init(width: 20, height: 20)) ?? #imageLiteral(resourceName: "NoArt") }, completion: { [weak self] finished in
            
            guard finished, let weakSelf = self else { return }
            
            if let _ = weakSelf.currentModifier, !weakSelf.deferToNowPlayingViewController {
                
                weakSelf.shouldUseNowPlayingArt = false
                
                UniversalMethods.performOnMainThread({
                    
                    weakSelf.updateBackgroundViaModifier()
                    
                }, afterDelay: 3)
            }
        })
    }
    
    @objc func updateBackgroundViaModifier(with imageOverride: UIImage? = nil) {
        
        guard backgroundArtworkAdaptivity == .sectionAdaptive && !shouldUseNowPlayingArt else { return }
        
        UIView.transition(with: imageView, duration: 0.45, options: .transitionCrossDissolve, animations: { self.imageView.image = imageOverride ?? self.currentModifier?.artworkType.image }, completion: nil)
    }

    func update(_ button: UIButton?, to state: UIButton.SelectionState, animated: Bool = true) {
        
        guard let button: MELButton = {
            
            if button == libraryButton {
                
                return libraryButton
                
            } else if button == searchButton {
                
                return searchButton
            }
            
            return nil
            
        }() else { return }
        
        UIView.transition(with: button, duration: animated ? 0.3 : 0, options: .transitionCrossDissolve, animations: {
            
            if button == self.libraryButton {
                
                self.updateLibraryButtonImage()
                
            } else if button == self.searchButton {
                
                button.setImage(state == .selected ? #imageLiteral(resourceName: "SearchSelected19") : #imageLiteral(resourceName: "Search19"), for: .normal)
            }
            
        }, completion: nil)
    }
    
    @IBAction func switchViewController(_ sender: UIButton) {
        
        if activeViewController == controller(for: sender) {
            
            switch tabBarTapBehaviour {
                
                case .nothing: break
                
                case .scrollToTop: notifier.post(name: .scrollCurrentViewToTop, object: activeViewController)
                
                case .returnToStart, .returnThenScroll:
                
                    if activeViewController?.topViewController != activeViewController?.viewControllers.first {
                        
                        _ = activeViewController?.popToRootViewController(animated: true)
                    
                    } else if tabBarTapBehaviour == .returnThenScroll {
                        
                        notifier.post(name: .scrollCurrentViewToTop, object: activeViewController)
                    }
            }
            
        } else {
            
            prefs.set(startPoint(for: sender).rawValue, forKey: .lastUsedTab)
            activeViewController = controller(for: sender)
        }
        
        let array = [searchButton, libraryButton]
        
        for button in array {
            
            update(button, to: button == sender ? .selected : .unselected)
        }
    }
    
    @objc func updateSliderDuration() {
        
        if let nowPlaying = musicPlayer.nowPlayingItem {
            
            timeSlider.minimumValue = 0
            timeSlider.maximumValue = Float(nowPlaying.playbackDuration)
        }
    }
    
    @IBAction func showAddOptions() {
        
        let new = AlertAction.init(title: "Create Playlist...", style: .default, requiresDismissalFirst: true, handler: { [weak self] in
            
            guard let weakSelf = self else { return }
            
            weakSelf.performSegue(withIdentifier: "toNewPlaylist", sender: nil)
        })
        
        let add = AlertAction.init(title: "Add to Playlists...", style: .default, requiresDismissalFirst: true, handler: { [weak self] in
            
            guard let weakSelf = self else { return }
            
            weakSelf.performSegue(withIdentifier: "toPlaylists", sender: nil)
        })
        
        showAlert(title: "Collected Songs", with: new, add)
        
//        present(UIAlertController.withTitle("Collected Songs", message: nil, style: .actionSheet, actions: new, add, .cancel()), animated: true, completion: nil)
    }
    
    @IBAction func playQueue(_ sender: Any) {
        
        if queue.count > 1 {
            
            var array = [AlertAction]()
            let canShuffleAlbums = queue.canShuffleAlbums
            
            let play = AlertAction.init(title: "Play", style: .default, requiresDismissalFirst: true, handler: {
                
                musicPlayer.play(self.queue, startingFrom: self.queue.first, from: self, withTitle: self.queue.count.fullCountText(for: .song), alertTitle: "Play", completion: { notifier.post(name: .endQueueModification, object: nil) })
            })
            
            array.append(play)
            
            let shuffle = AlertAction.init(title: .shuffle(canShuffleAlbums ? .songs : .none), style: .default, requiresDismissalFirst: true, handler: {
                
                musicPlayer.play(self.queue, startingFrom: nil, shuffleMode: .songs, from: self, withTitle: self.queue.count.fullCountText(for: .song), alertTitle: .shuffle(canShuffleAlbums ? .songs : .none), completion: { notifier.post(name: .endQueueModification, object: nil) })
            })
            
            array.append(shuffle)
            
            if canShuffleAlbums {
                
                let shuffleAlbums = AlertAction.init(title: .shuffle(.albums), style: .default, requiresDismissalFirst: true, handler: {
                    
                    musicPlayer.play(self.queue.albumsShuffled, startingFrom: nil, from: nil, withTitle: self.queue.count.fullCountText(for: .song), alertTitle: .shuffle(.albums), completion: { notifier.post(name: .endQueueModification, object: nil) })
                })
                
                array.append(shuffleAlbums)
            }
            
            showAlert(title: queue.count.fullCountText(for: .song), with: array)
            
//            present(UIAlertController.withTitle(queue.count.fullCountText(for: .song), message: nil, style: .actionSheet, actions: array + [.cancel()]), animated: true, completion: nil)
            
        } else {
            
            musicPlayer.play(queue, startingFrom: queue.first, from: self, withTitle: queue.count.fullCountText(for: .song), alertTitle: "Play", completion: { notifier.post(name: .endQueueModification, object: nil) })
        }
    }
    
    @IBAction func showUpNextActions(_ sender: Any) {
        
        guard let _ = musicPlayer.nowPlayingItem else { return }
        
        Transitioner.shared.addToQueue(from: self, kind: .items(queue), context: .collector(manager: self))
    }
    
    func modifyCollectedButton(forState state: QueueViewState) {
        
        UIView.animate(withDuration: 0.3, animations: {
            
            if (state == .dismissed || useCompactCollector) && self.collectedView.isHidden { } else {
                
                self.collectedView.isHidden = state == .dismissed || useCompactCollector
            }
            
            self.collectedView.alpha = state == .dismissed || useCompactCollector ? 0 : 1
            
            if (state == .dismissed || !useCompactCollector) && self.filterViewContainer.filterView.collectedView.isHidden { } else {
                
                self.filterViewContainer.filterView.collectedView.isHidden = state == .dismissed || !useCompactCollector
            }
            
            self.filterViewContainer.filterView.collectedView.alpha = state == .dismissed || !useCompactCollector ? 0 : 1
        
        }, completion: { _ in notifier.post(name: .resetInsets, object: nil) })
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func prepareNowPlayingViews(with nowPlaying: MPMediaItem?, animated: Bool) {
        
        if let nowPlaying = nowPlaying {
            
            let albumTitle = nowPlaying.validAlbum
            let artistName = nowPlaying.validArtist
            let songTitle = nowPlaying.validTitle
            let albumImage = nowPlaying.actualArtwork?.image(at: .init(width: 20, height: 20)) ?? #imageLiteral(resourceName: "NoSong75")
            
            if animated {
                
                UniversalMethods.performTransitions(withRelevantParameters:
                    (albumArt, 0.3, { self.albumArt.image = albumImage }, nil),
                    (altAlbumArt, 0.3, { self.altAlbumArt.image = albumImage }, nil),
                    (songName, 0.3, { self.songName.text = songTitle }, nil),
                    (artistAndAlbum, 0.3, { self.artistAndAlbum.text = artistName + " — " + albumTitle }, nil)
                )
                
                verifyLibraryStatus(of: nowPlaying, itemProperty: .song)
                
                UIView.animate(withDuration: 0.3, animations: {
                    
                    if !useMicroPlayer {
                        
                        self.nowPlayingView.isHidden = false
                        self.nowPlayingView.alpha = 1
                        
                    } else {
                        
                        self.nowPlayingView.superview?.layoutIfNeeded()
                    }
                    
                }, completion: { _ in
                    
                    notifier.post(name: .resetInsets, object: nil)
                })
                
            } else {
                
                albumArt.image = albumImage
                altAlbumArt.image = albumImage
                songName.text = songTitle
                artistAndAlbum.text = artistName + " — " + albumTitle
                
                if !useMicroPlayer {
                    
                    nowPlayingView.isHidden = false
                    nowPlayingView.alpha = 1
                }
                
                verifyLibraryStatus(of: nowPlaying, itemProperty: .song, animated: false)
                
                notifier.post(name: .resetInsets, object: nil)
            }
            
        } else {
            
            if animated {
                
                UIView.transition(with: altAlbumArt, duration: 0.3, options: .transitionCrossDissolve, animations: { self.altAlbumArt.image = UIImage.new(withColour: .clear, size: nil) }, completion: nil)
                
                UIView.animate(withDuration: 0.3, animations: {
                    
                    if !useMicroPlayer {
                        
                        self.nowPlayingView.isHidden = true
                        self.nowPlayingView.alpha = 0
                        
                    } else {
                        
                        self.nowPlayingView.superview?.layoutIfNeeded()
                    }
                    
                }, completion: { _ in
                        
                    self.songName.text = nil
                    self.artistAndAlbum.text = nil
                    notifier.post(name: .resetInsets, object: nil)
                })
                
            } else {
                
                if !useMicroPlayer {
                    
                    nowPlayingView.isHidden = true
                    nowPlayingView.alpha = 0
                }
                
                notifier.post(name: .resetInsets, object: nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let id = segue.identifier else { return }
        
        switch id {
            
            case "nowPlaying": moveToNowPlaying(vc: segue.destination, showingQueue: false)
            
            case "manageQueue":
            
                if let presentedVC = segue.destination as? PresentedContainerViewController {
                    
                    presentedVC.manager = self
                    presentedVC.container = self
                }
            
            case "queue":
            
                if let presentedVC = segue.destination as? PresentedContainerViewController {
                    
                    presentedVC.context = .queue
                }
            
            case "toPlaylists":
                
                guard let presentedVC = segue.destination as? PresentedContainerViewController else { return }
                
                presentedVC.manager = self
                presentedVC.context = .playlists
                presentedVC.playlistsVC.sectionOverride = .playlists
            
            case "toNewPlaylist":
                
                guard let presentedVC = segue.destination as? PresentedContainerViewController else { return }
                
                    presentedVC.manager = self
                    presentedVC.context = .newPlaylist
                    presentedVC.fromQueue = true
            
            default: return
        }
    }
    
    @objc @discardableResult func moveToNowPlaying(vc: UIViewController, showingQueue queue: Bool, perform3DTouchActions: Bool = false) -> UIViewController? {
        
        guard let now = vc as? NowPlayingViewController else { return nil }
        
        now.container = self
        now.transitioningDelegate = now.animator
        
        if perform3DTouchActions {
            
            now.peeker = self
            now.modifyBackgroundView(forState: .visible)
        }
        
        return now
    }

    deinit {
        
        notifier.removeObserver(self)
        unregisterAll(from: lifetimeObservers)
    }
}

extension ContainerViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        let queueButtonContainsLocation = upNextButton.bounds.contains(bottomEffectView.contentView.convert(location, to: upNextButton))
        
        let nowPlayingButtonContainsLocation = nowPlayingButton.bounds.contains(bottomEffectView.contentView.convert(location, to: nowPlayingButton))
        
        let altNowPlayingButtonContainsLocation = altNowPlayingButton.bounds.contains(bottomEffectView.contentView.convert(location, to: altNowPlayingButton))
        
        if collectedButton.bounds.contains(bottomEffectView.contentView.convert(location, to: collectedButton)) {
            
            if let queueVC = presentedChilrenStoryboard.instantiateViewController(withIdentifier: "queueVC") as? CollectorViewController {
                
                queueVC.manager = self
                queueVC.peeker = self
                queueVC.modifyBackgroundView(forState: .visible)
                previewingContext.sourceRect = collectedView.frame
                
                return queueVC
            }
        
        } else if queueButtonContainsLocation {
            
            if let queueVC = /*self.queueVC?.queueTVC ?? */presentedChilrenStoryboard.instantiateViewController(withIdentifier: "queueTVC") as? QueueViewController {
                
                queueVC.peeker = self
                queueVC.modifyBackgroundView(forState: .visible)
                previewingContext.sourceRect = bottomEffectView.convert(upNextButton.frame, from: nowPlayingView)
                
                return queueVC
            }
            
        } else if nowPlayingButtonContainsLocation || altNowPlayingButtonContainsLocation {
            
            if let nowPlaying = nowPlayingStoryboard.instantiateViewController(withIdentifier: "nowPlaying") as? NowPlayingViewController {
                
                previewingContext.sourceRect = altNowPlayingButtonContainsLocation ? bottomEffectView.convert(altNowPlayingViewSuperview.frame, from: tabView) : nowPlayingView.frame
                
                return moveToNowPlaying(vc: nowPlaying, showingQueue: false, perform3DTouchActions: true)
            }
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        performCommitActions(on: viewControllerToCommit)
        
        if let vc = viewControllerToCommit as? NowPlayingViewController {
            
            vc.perfrom3DTouchCleanup()
            containerView.alpha = 0
            visualEffectNavigationBar.alpha = 0
            bottomEffectView.alpha = 0
            vc.statusBarBackground.isHidden = dynamicStatusBar
        }
        
        if let qVC = viewControllerToCommit as? QueueViewController {
            
            queuePop(using: qVC, context: .queue)
            
        } else if let qVC = viewControllerToCommit as? CollectorViewController {
            
            queuePop(using: qVC, context: .items)
            
        } else {
            
            present(viewControllerToCommit, animated: true, completion: { NowPlaying.shared.nowPlayingVC = viewControllerToCommit as? NowPlayingViewController })
        }
    }
}

extension ContainerViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if gestureRecognizer.view == tabView {
            
            return useMicroPlayer
        }
        
        if gestureRecognizer is UITapGestureRecognizer {
            
            return filterShortcutEnabled
        }
        
        return true
    }
}
