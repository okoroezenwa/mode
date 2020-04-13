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
    @IBOutlet var filterViewContainer: FilterViewContainer! {
        
        didSet {
            
            guard let startPoint = StartPoint(rawValue: lastUsedTab) else { return }
            
            filterViewContainer.filterView.requiresSearchBar = startPoint == .search
        }
    }
    @IBOutlet var bottomEffectView: MELVisualEffectView!
    
    @IBOutlet var songName: MELLabel!
    @IBOutlet var artistAndAlbum: MELLabel!
    @IBOutlet var collectedButton: MELButton!
    @IBOutlet var playPauseButton: MELButton!
    @IBOutlet var playShuffleButton: MELButton!
    @IBOutlet var collectedUpNextButton: MELButton!
    @IBOutlet var nowPlayingButton: UIButton!
    @IBOutlet var timeSlider: MELSlider!
    @IBOutlet var timeSliderSuperview: UIView!
    @IBOutlet var sliderParentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var containerView: UIView!
    @IBOutlet var startTime: MELLabel!
    @IBOutlet var stopTime: MELLabel!
    @IBOutlet var sliderStackViewEdgeConstraints: [NSLayoutConstraint]!
    @IBOutlet var songTitlesStackView: UIStackView!
    @IBOutlet var timeSliderTopConstraint: NSLayoutConstraint!
    @IBOutlet var timeSliderBottomConstraint: NSLayoutConstraint!
    @IBOutlet var miniLabelsTopConstraint: NSLayoutConstraint!
    @IBOutlet var miniLabelsBottomConstraint: NSLayoutConstraint!
    @IBOutlet var artworkContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet var artworkContainerCentreYConstraint: NSLayoutConstraint!
    @IBOutlet var sliderBorderView: MELBorderView!
    @IBOutlet var tabView: UIView!
    @IBOutlet var searchButton: MELButton!
    @IBOutlet var libraryButton: MELButton!
    @IBOutlet var libraryButtonLabel: MELLabel!
    @IBOutlet var searchButtonLabel: MELLabel!
    @IBOutlet var actionsButtonLabel: MELLabel!
    @IBOutlet var playButtonLabel: MELLabel?
    @IBOutlet var queueButtonLabel: MELLabel!
    @IBOutlet var collectedView: UIView!
    @IBOutlet var clearButton: MELButton!
    @IBOutlet var altQueueView: UIView!
    @IBOutlet var bottomEffectViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var collectedUpNextViewEqualWidthConstraint: NSLayoutConstraint!
    @IBOutlet var collectedUpNextViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var altNowPlayingView: UIView!
    @IBOutlet var altAlbumArt: UIImageView!
    @IBOutlet var altNowPlayingButton: MELButton!
    @IBOutlet var altNowPlayingViewSuperview: UIView!
    @IBOutlet var actionsButton: ActionsButton! {
        
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
    
    var editButton: MELButton! = MELButton()

    @objc var activeChildViewController: UIViewController? {
        
        get { return activeViewController }
        
        set { activeViewController = newValue as? UINavigationController /* changed from activeChildViewController to newValue in Xcode 11*/ }
    }
    
    var viewControllerSnapshot: UIView? { didSet { oldValue?.removeFromSuperview() } }
    
    @objc var actionableSongs: [MPMediaItem] { return [musicPlayer.nowPlayingItem].compactMap({ $0 }) }
    var applicableActions: [SongAction] {
        
        guard let song = musicPlayer.nowPlayingItem else { return [] }
        
        var actions = [SongAction.collect, .newPlaylist, .addTo, .show(title: song.validTitle, context: .song(location: .list, at: 0, within: [song]), canDisplayInLibrary: true), .search(unwinder: nil)]
        
        if song.existsInLibrary.inverted {
            
            actions.append(.library)
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
    var collectedViewHeight: CGFloat { collectedView.isHidden ? 0 : 44 }
    var searchViewHeight: CGFloat { lastUsedTab == StartPoint.library.rawValue || filterViewContainer.filterView.requiresSearchBar.inverted ? 0 : 52 + 1 }
    var titlesHeight: CGFloat { musicPlayer.nowPlayingItem == nil ? 0 : showMiniPlayerSongTitles ? 4 + (FontManager.shared.height(for: .secondary) * 2) + (useExpandedSlider ? 5 : 7) : 0 }
    var sliderHeight: CGFloat { musicPlayer.nowPlayingItem == nil ? 0 : useExpandedSlider ? expandedSliderHeight : 0 }
    let expandedSliderHeight: CGFloat = 30
    
    @objc var inset: CGFloat { return collectedViewHeight + 51 + sliderHeight + titlesHeight + searchViewHeight }
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
    var modifier: ArtworkModifying? { activeViewController?.topViewController as? ArtworkModifying }
    @objc var deferToNowPlayingViewController = false
    @objc var lifetimeObservers = Set<NSObject>()
    @objc let presenter = PresentationAnimationController.init(interactor: InteractionController())
    var playingImage: UIImage { showTabBarLabels ? #imageLiteral(resourceName: "Pause16") : #imageLiteral(resourceName: "Pause20") }
    var pausedImage: UIImage { showTabBarLabels ? #imageLiteral(resourceName: "PlayCurved16") : #imageLiteral(resourceName: "PlayCurved19") }
    let pausedInset: CGFloat = 1
    let playPauseButtonNeedsAnimation = true
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
    var allowSwipeAssistedPan = false
    
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
        prepareTabBar(updateImages: false)
        
        updateSliderDuration()
        
        ArtworkManager.shared.container = self
        imageView.image = (activeViewController?.topViewController as? ArtworkModifying)?.artworkType.image
        
        prepareNowPlayingViews(animated: false)
        prepareLifetimeObservers()
        prepareAltAlbumArt()
        
        notifier.addObserver(self, selector: #selector(updateCornersAndShadows), name: .cornerRadiusChanged, object: nil)
        
        updateSecondaryPlayingViews(self)
            
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
        
        updateCornersAndShadows()
        
        getCollected()
        Queue.shared.verifyQueue()
    }
    
    func prepareTabBar(updateImages: Bool) {
        
        if updateImages {
        
            updateLibraryButtonImage()
            updateSearchButtonImage()
            modifyPlayPauseButton(setImageOnly: true)
        }
        
        artworkContainerCentreYConstraint.constant = showTabBarLabels ? -8.5 : 0
        artworkContainerWidthConstraint.constant = showTabBarLabels ? 24 : 28
        
        [playPauseButton, libraryButton, searchButton, actionsButton].forEach({ $0?.contentEdgeInsets.bottom = showTabBarLabels ? 17 : 0 })
        
        [playButtonLabel, libraryButtonLabel, searchButtonLabel, queueButtonLabel, actionsButtonLabel].forEach({ $0?.isHidden = showTabBarLabels.inverted })
    }
    
    func updateSecondaryPlayingViews(_ sender: Any) {
        
        let hasSong = musicPlayer.nowPlayingItem != nil
        let animated = (sender is UIViewController).inverted
        
//        if let stackView = timeSliderSuperview.superview as? UIStackView {
//
//            if (useExpandedSlider && stackView.arrangedSubviews.firstIndex(of: timeSliderSuperview) == 1) || (useExpandedSlider.inverted && stackView.arrangedSubviews.firstIndex(of: timeSliderSuperview) == 0) { } else {
//
//                stackView.removeArrangedSubview(timeSliderSuperview)
//
//                if useExpandedSlider {
//
//                    stackView.insertArrangedSubview(timeSliderSuperview, at: 1)
//
//                } else {
//
//                    stackView.insertArrangedSubview(timeSliderSuperview, at: 0)
//                }
//
//                stackView.layoutIfNeeded()
//            }
//        }
        
        songTitlesStackView.superview?.isHidden = hasSong ? showMiniPlayerSongTitles.inverted : true
        timeSlider.border = hasSong ? useExpandedSlider.inverted : true
        sliderParentViewHeightConstraint.constant = hasSong && useExpandedSlider ? expandedSliderHeight : 1
        
        if useExpandedSlider {
            
            if showMiniPlayerSongTitles {
                
                timeSliderTopConstraint.constant = 0
                timeSliderBottomConstraint.constant = 0
                miniLabelsTopConstraint.constant = 0
                miniLabelsBottomConstraint.constant = hasSong ? 5 : 0
                
            } else {
                
                timeSliderTopConstraint.constant = hasSong ? 3 : 0
                timeSliderBottomConstraint.constant = 0
                miniLabelsTopConstraint.constant = 0
                miniLabelsBottomConstraint.constant = 0
            }
            
        } else {
            
            if showMiniPlayerSongTitles {
                
                timeSliderTopConstraint.constant = 0
                timeSliderBottomConstraint.constant = 0
                miniLabelsTopConstraint.constant = hasSong ? 7 : 0
                miniLabelsBottomConstraint.constant = 0
                
            } else {
                
                timeSliderTopConstraint.constant = 0
                timeSliderBottomConstraint.constant = 0
                miniLabelsTopConstraint.constant = 0
                miniLabelsBottomConstraint.constant = 0
            }
        }
        
        if animated {
        
            UIView.animate(withDuration: 0.3, animations: {
                
                self.sliderBorderView.isHidden = hasSong ? useExpandedSlider.inverted : true
                self.view.layoutIfNeeded()
                
                [self.startTime, self.stopTime].forEach({
                    
                    $0?.alpha = hasSong && useExpandedSlider ? 1 : 0
                    
                    if ((hasSong && useExpandedSlider.inverted) || hasSong.inverted) && $0?.superview?.isHidden == true { } else {
                        
                        $0?.superview?.isHidden = hasSong ? useExpandedSlider.inverted : true
                    }
                })
            })
        
        } else {
            
            sliderBorderView.isHidden = hasSong ? useExpandedSlider.inverted : true
            [startTime, stopTime].forEach({
                
                $0?.alpha = hasSong && useExpandedSlider ? 1 : 0
                $0?.superview?.isHidden = hasSong ? useExpandedSlider.inverted : true
            })
        }
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
                
                if showTabBarLabels {
                    
                    return lastUsedTab == StartPoint.library.rawValue ? #imageLiteral(resourceName: "OfflineSelected20") : #imageLiteral(resourceName: "Offline20")
                    
                } else {
                    
                    return lastUsedTab == StartPoint.library.rawValue ? #imageLiteral(resourceName: "OfflineSelected22") : #imageLiteral(resourceName: "Offline22")
                }
            }
        }
        
        libraryButton.setImage(image, for: .normal)
        
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            
            self.libraryButton.superview?.layoutIfNeeded()
            
        }, completion: nil)
    }
    
    func updateSearchButtonImage() {
        
        let image: UIImage = {
            
            if showTabBarLabels {
                
                return lastUsedTab == StartPoint.search.rawValue ? #imageLiteral(resourceName: "SearchSelected19") : #imageLiteral(resourceName: "Search19")
                
            } else {
                
                return lastUsedTab == StartPoint.search.rawValue ? #imageLiteral(resourceName: "SearchSelected22") : #imageLiteral(resourceName: "Search22")
            }
        }()
        
        searchButton.setImage(image, for: .normal)
    }
    
    @objc func modifyQueueLabel() {
        
        guard musicPlayer.nowPlayingItem != nil else {
            
            queueButtonLabel.text = "Queue"
            
            return
        }
        
        queueButtonLabel.text = musicPlayer.fullQueueCount(withInitialSpace: false, parentheses: false)
    }
    
    @objc func getCollected() {
        
        guard let data = prefs.object(forKey: .collectedItems) as? Data, let queue = NSKeyedUnarchiver.unarchiveObject(with: data) as? [MPMediaItem], !queue.isEmpty else { return }
        
        self.queue = queue
        modifyCollectedButton(forState: .invoked)
        updateCollectedText(animated: false)
    }
    
    @objc func updateCollectedText(animated: Bool = true) {
        
        collectedButton.setTitle(queue.count.formatted, for: .normal)
        
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
        
        [nowPlayingButton, altNowPlayingButton].forEach({
            
            let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(showNowPlayingActions(_:)))
            gr.minimumPressDuration = longPressDuration
            $0?.addGestureRecognizer(gr)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: gr))
        })
        
        [nowPlayingButton, tabView].forEach({
            
            let gr = UISwipeGestureRecognizer.init(target: self, action: #selector(goTo))
            gr.direction = .left
            $0?.addGestureRecognizer(gr)
            
            let pan = UIPanGestureRecognizer.init(target: self, action: #selector(panTest(_:)))
            pan.delegate = self
            $0?.addGestureRecognizer(pan)
        })
            
        let altQueueSwipeLeft = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(performAuxillaryNowPlayingAction))
        altQueueSwipeLeft.edges = .right//direction = .left
        altNowPlayingButton.addGestureRecognizer(altQueueSwipeLeft)
        
//        let swipeUp = UISwipeGestureRecognizer.init(target: self, action: #selector(goToNowPlaying))
//        swipeUp.direction = .up
//        nowPlayingButton.addGestureRecognizer(swipeUp)
        
        [libraryButton, searchButton].forEach({
            
            let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(tabButtonHeld))
            gr.minimumPressDuration = longPressDuration
            $0?.addGestureRecognizer(gr)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: gr))
        })
    }
    
    @objc func panTest(_ sender: UIPanGestureRecognizer) {
        
        guard allowSwipeAssistedPan else { return }
        
        switch sender.state {
            
            case .began, .changed, .ended:
            
                guard let top = topViewController as? VerticalPresentationContainerViewController else { return }
                
                top.gestureActivated(sender)
            
                if sender.state == .ended { allowSwipeAssistedPan = false }
            
            default: break
        }
    }
    
    @objc func tabButtonHeld(_ sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
            
            case .began:
            
                if sender.view == libraryButton {
                    
                    showLibrarySections()
                    
                } else if sender.view == searchButton {
                    
                    showFilterProperties()
                }
            
            case .changed, .ended:
            
                guard let top = topViewController as? VerticalPresentationContainerViewController else { return }
                
                top.gestureActivated(sender)
            
            default: break
        }
    }
    
    func showFilterProperties() {
        
        
    }
    
    func showLibrarySections() {
        
        let sectionHandler: ([LibrarySection]) -> [AlertAction] = { sections in
            
            sections.map({ section in
                
                AlertAction.init(title: section.title, subtitle: nil, style: .default, accessoryType: .check({ LibrarySection(rawValue: lastUsedLibrarySection) == section }), image: section == .compilations ? #imageLiteral(resourceName: "CompilationsLarge") : section.entityType.images.size22, handler: { [weak self] in
                    
                    guard let weakSelf = self, let librarySection = LibrarySection(rawValue: lastUsedLibrarySection) else { return }
                    
                    if weakSelf.activeViewController != weakSelf.libraryNavigationController {
                        
                        if librarySection == section, (weakSelf.libraryNavigationController?.topViewController is LibraryViewController).inverted {

                            weakSelf.libraryNavigationController?.popToRootViewController(animated: false)
                            weakSelf.libraryNavigationController?.topViewController?.view.alpha = 1

                        } else {
                        
                            let rawValue = section.rawValue
            
                            prefs.set(rawValue, forKey: .lastUsedLibrarySection)
                            notifier.post(name: .changeLibrarySection, object: nil, userInfo: ["section": rawValue, "oldSection": librarySection.rawValue, "animated": false])
                        }
                        
                        weakSelf.switchViewController(weakSelf.libraryButton)
                    
                    } else {
                        
                        guard let librarySection = LibrarySection(rawValue: lastUsedLibrarySection) else { return }
                        
                        if librarySection == section, weakSelf.libraryNavigationController?.topViewController != weakSelf.libraryNavigationController?.viewControllers.first {
                            
                            weakSelf.libraryNavigationController?.popToRootViewController(animated: true)
                        
                        } else if librarySection != section, let libraryVC = weakSelf.libraryNavigationController?.viewControllers.first as? LibraryViewController {
                            
                            prefs.set(section.rawValue, forKey: .lastUsedLibrarySection)
                            libraryVC.activeChildViewController = libraryVC.viewControllerForCurrentSection()
                            
                            if libraryVC.navigationController?.topViewController != libraryVC.navigationController?.viewControllers.first {
                                
                                libraryVC.navigationController?.popToRootViewController(animated: true)
                            }
                        }
                    }
                })
            })
            
        }
        
        let title = "Library Section Settings..."
        let handler = { [weak self] in
            
            guard let weakSelf = self else { return }
            
            Transitioner.shared.showPropertySettings(from: weakSelf, with: .library)
        }
        
        var sections = sectionHandler(librarySections.removing(contentsOf: hiddenLibrarySections))
        
        sections.append(.init(title: "Secondary Sections...", image: #imageLiteral(resourceName: "More22"), requiresDismissalFirst: true, handler: { [weak self] in
            
            self?.showAlert(title: "Secondary Sections", subtitle: nil, with: sectionHandler(otherLibrarySections), shouldSortActions: false, rightAction: { _, vc in vc.dismiss(animated: true, completion: handler) }, images: (nil, #imageLiteral(resourceName: "Settings")))
            
        }), if: otherLibrarySections.isEmpty.inverted)
        
        sections.append(.init(title: title, handler: handler), if: useSystemAlerts)
        
        showAlert(title: "Library Sections", subtitle: nil, with: sections, shouldSortActions: false, rightAction: { _, vc in vc.dismiss(animated: true, completion: handler) }, images: (nil, #imageLiteral(resourceName: "Settings")))
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
            
                guard let top = topViewController as? VerticalPresentationContainerViewController else { return }
            
                top.gestureActivated(sender)
            
            default: break
        }
    }
    
    @objc func presentActions() {
        
        guard let item = musicPlayer.nowPlayingItem else { return }
        
        var actions = applicableActions.map({ singleItemAlertAction(for: $0, entityType: .song, using: item, from: self) })
        
        actions.append(.init(title: "Get Info", style: .default, requiresDismissalFirst: true, handler: { [weak self] in
            
            guard let weakSelf = self else { return }
            
            Transitioner.shared.showInfo(from: weakSelf, with: .song(location: .list, at: 0, within: [item]))
        }))
        
        showAlert(title: item.validTitle, subtitle: item.validArtist + " — " + item.validAlbum, with: actions, rightAction: { [weak self] button, vc in
            
            guard musicPlayer.nowPlayingItem != nil else { return }
            
            vc.dismiss(animated: true, completion: { self?.performSegue(withIdentifier: "queue", sender: nil) })
        
        }, images: (nil, #imageLiteral(resourceName: "Queue13")))
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
//            weakSelf.prepareNowPlayingViews(animated: true)
//
//            weakSelf.updateBackgroundWithNowPlaying()
//            
//            weakSelf.updateSliderDuration()
//            weakSelf.updateTimes(setValue: true, seeking: false)
//            weakSelf.updateCollectedUpNextView(animated: true)
//        
//        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: isQueueAvailable ? .indexUpdated : .nowPlayingItemChanged, object: nil, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self else { return }
            
            weakSelf.prepareNowPlayingViews(animated: true)
            weakSelf.updateSecondaryPlayingViews(notification)
            notifier.post(name: .resetInsets, object: nil)
            
            if ArtworkManager.shared.currentlyPeeking == nil {
            
                UIView.transition(with: weakSelf.imageView, duration: 0.3, options: .transitionCrossDissolve, animations: { weakSelf.imageView.image = ArtworkManager.shared.activeContainer?.modifier?.artworkType.image }, completion: nil)
            }
            
            weakSelf.updateSliderDuration()
            weakSelf.updateTimes(setValue: true, seeking: false)
            weakSelf.updateCollectedUpNextView(animated: true)
            
        }) as! NSObject)
        
        [Notification.Name.useExpandedSliderChanged, .showMiniPlayerSongTitlesChanged].forEach({ lifetimeObservers.insert(notifier.addObserver(forName: $0, object: nil, queue: nil, using: { [weak self] notification in
            
            self?.updateSecondaryPlayingViews(notification)
            notifier.post(name: .resetInsets, object: nil)
            
        }) as! NSObject) })
        
        lifetimeObservers.insert(notifier.addObserver(forName: .showMiniPlayerSongTitlesChanged, object: nil, queue: nil, using: { _ in notifier.post(name: .resetInsets, object: nil) }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .showTabBarLabelsChanged, object: nil, queue: nil, using: { [weak self] _ in self?.prepareTabBar(updateImages: true) }) as! NSObject)
        
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
                    
                    self.prepareNowPlayingViews(animated: true)
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
            
            weakSelf.modifyQueueLabel()
            weakSelf.verifyLibraryStatus(of: musicPlayer.nowPlayingItem, itemProperty: .song, animated: false)
        
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .queueModified, object: nil, queue: nil, using: { [weak self] _ in self?.modifyQueueLabel() }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .shuffleInvoked, object: nil, queue: nil, using: { [weak self] _ in self?.modifyQueueLabel() }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .appleMusicStatusChecked, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.verifyLibraryStatus(of: musicPlayer.nowPlayingItem, itemProperty: .song, animated: true)
        
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
        
        let appropriateRadius = miniPlayerCornerRadius ?? .square
        
        appropriateRadius.updateCornerRadius(on: altAlbumArt.layer, width: altAlbumArt.bounds.width, entityType: .song, globalRadiusType: cornerRadius)
        
        UniversalMethods.addShadow(to: altNowPlayingView, radius: 6, opacity: 0.25, shouldRasterise: true)
    }
    
    @IBAction func goToLibraryOptions() {
        
        guard let options = currentOptionsContaining?.options, let vc: UIViewController = {
            
            let vc = popoverStoryboard.instantiateViewController(withIdentifier: "actionsVC")
            vc.modalPresentationStyle = .popover
            
            return Transitioner.shared.transition(to: vc, using: options, sourceView: actionsButton)
            
        }() else { return }
        
        present(vc, animated: true, completion: nil)
    }
    
    func goToDetails(basedOn entity: EntityType) -> (entities: [EntityType], albumArtOverride: Bool) {
        
        return ([EntityType.artist, .genre, .album, .composer, .albumArtist], true)
    }
    
    @objc func goTo(_ sender: Any) {
        
        guard let song = musicPlayer.nowPlayingItem else { return }
        
        if let _ = sender as? UISwipeGestureRecognizer { allowSwipeAssistedPan = true }
        
        singleItemActionDetails(for: .show(title: song.validTitle, context: .song(location: .list, at: 0, within: [song]), canDisplayInLibrary: true), entityType: .song, using: song, from: self, useAlternateTitle: true).handler()
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
            
            case let x where x == libraryNavigationController: return libraryButton
            
            case let x where x == searchNavigationController: return searchButton
            
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
        #warning("Consider still showing the alert but allow interactivity so that space for the delete button can be used for something else")
        if let sender = sender as? UILongPressGestureRecognizer {
            
            guard sender.state == .began else { return }
        }
        
        let remove = AlertAction.init(title: "Discard Collected", style: .destructive, handler: { notifier.post(name: .endQueueModification, object: nil) })
        
        showAlert(title: nil, with: remove)
    }

    @IBAction func clearItemsImmediately(_ gr: UILongPressGestureRecognizer) {
        
        if gr.state == .began {
            
            notifier.post(name: .endQueueModification, object: nil)
        }
    }
    
    func unwindToAlbum(from vc: AlbumTransitionable) {
        
        if let entityVC = activeViewController?.topViewController as? EntityItemsViewController, entityVC.albumItemsVCLoaded,
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
    
    func unwindToArtist(with artistQuery: MPMediaQuery?, item currentItem: MPMediaItem?, album currentAlbum: MPMediaItemCollection?, kind: EntityType) {
        
        if let entityVC = activeViewController?.topViewController as? EntityItemsViewController,
            let collections = artistQuery?.collections,
            collections.first?.persistentID == entityVC.collection?.persistentID {
            
            entityVC.highlightedEntities = (currentItem, currentAlbum)
            
            UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve, animations: { self.imageView.image = entityVC.artworkType.image }, completion: nil)
            
            if entityVC.artistSongsVCLoaded, entityVC.activeChildViewController == entityVC.artistSongsViewController {
                
                let child = entityVC.artistSongsViewController
                
                child.highlightedIndex = child.songs.optionalIndex(of: currentItem)
                child.tableView.reloadData()
                child.animateCells(direction: .vertical, alphaOnly: child.highlightedIndex != nil)
                child.scrollToHighlightedRow()
                
            } else if entityVC.artistAlbumsVCLoaded, entityVC.activeChildViewController == entityVC.artistAlbumsViewController {
                
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
        
        if let entityVC = activeViewController?.topViewController as? EntityItemsViewController, entityVC.playlistItemsVCLoaded,
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
            
            filterViewContainer.filterView.requiresSearchBar = vc is FilterViewController
            
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
        
        present(presentedVC, animated: false, completion: nil)
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
        
        guard let details: (button: MELButton, label: MELLabel) = {
            
            if button == libraryButton {
                
                return (libraryButton, libraryButtonLabel)
                
            } else if button == searchButton {
                
                return (searchButton, searchButtonLabel)
            }
            
            return nil
            
        }() else { return }
        
        UIView.transition(with: details.button, duration: animated ? 0.3 : 0, options: .transitionCrossDissolve, animations: {
            
            if details.button == self.libraryButton {
                
                self.updateLibraryButtonImage()
                
            } else if details.button == self.searchButton {
                
                self.updateSearchButtonImage()
            }
            
            details.label.fontWeight = (state == .selected ? FontWeight.bold : .regular).rawValue
            
        }, completion: nil)
        
        UIView.transition(with: details.label, duration: animated ? 0.3 : 0, options: .transitionCrossDissolve, animations: {
            
            details.label.fontWeight = (state == .selected ? FontWeight.bold : .regular).rawValue
            
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
            
//            if (state == .dismissed || !useCompactCollector) && self.filterViewContainer.filterView.collectedView.isHidden { } else {
//
//                self.filterViewContainer.filterView.collectedView.isHidden = state == .dismissed || !useCompactCollector
//            }
//
//            self.filterViewContainer.filterView.collectedView.alpha = state == .dismissed || !useCompactCollector ? 0 : 1
        
        }, completion: { _ in notifier.post(name: .resetInsets, object: nil) })
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func prepareNowPlayingViews(animated: Bool) {
        
        if let nowPlaying = musicPlayer.nowPlayingItem {
            
            let albumTitle = nowPlaying.validAlbum
            let artistName = nowPlaying.validArtist
            let songTitle = nowPlaying.validTitle
            let albumImage = nowPlaying.actualArtwork?.image(at: .init(width: 20, height: 20)) ?? #imageLiteral(resourceName: "NoSong75")
            
            if animated {
                
                UniversalMethods.performTransitions(withRelevantParameters:
                    (altAlbumArt, 0.3, { self.altAlbumArt.image = albumImage }, nil),
                    (songName, 0.3, { self.songName.text = songTitle }, nil),
                    (artistAndAlbum, 0.3, { self.artistAndAlbum.text = artistName + " — " + albumTitle }, nil)
                )
                
                verifyLibraryStatus(of: nowPlaying, itemProperty: .song)
                
                UIView.animate(withDuration: 0.3, animations: {
                    
                    
                }, completion: { _ in
                    
                    notifier.post(name: .resetInsets, object: nil)
                })
                
            } else {
                
                altAlbumArt.image = albumImage
                songName.text = songTitle
                artistAndAlbum.text = artistName + " — " + albumTitle
                
                verifyLibraryStatus(of: nowPlaying, itemProperty: .song, animated: false)
                
                notifier.post(name: .resetInsets, object: nil)
            }
            
        } else {
            
            if animated {
                
                UIView.transition(with: altAlbumArt, duration: 0.3, options: .transitionCrossDissolve, animations: { self.altAlbumArt.image = UIImage.new(withColour: .clear, size: nil) }, completion: nil)
                
                UIView.animate(withDuration: 0.3, animations: {
                    
                    
                    
                }, completion: { _ in
                        
                    self.songName.text = nil
                    self.artistAndAlbum.text = nil
                    notifier.post(name: .resetInsets, object: nil)
                })
                
            } else {
                
                notifier.post(name: .resetInsets, object: nil)
            }
        }
        
        modifyQueueLabel()
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
        
        let nowPlayingButtonContainsLocation = nowPlayingButton.bounds.contains(bottomEffectView.contentView.convert(location, to: nowPlayingButton))
        
        let altNowPlayingButtonContainsLocation = altNowPlayingButton.bounds.contains(bottomEffectView.contentView.convert(location, to: altNowPlayingButton))
        
        if collectedButton.bounds.contains(bottomEffectView.contentView.convert(location, to: collectedButton)) {
            
            if let collectorVC = presentedChilrenStoryboard.instantiateViewController(withIdentifier: "queueVC") as? CollectorViewController {
                
                collectorVC.manager = self
                collectorVC.peeker = self
                collectorVC.modifyBackgroundView(forState: .visible)
                previewingContext.sourceRect = collectedView.frame
                
                return collectorVC
            }
        
        } else if nowPlayingButtonContainsLocation || altNowPlayingButtonContainsLocation {
            
            if let nowPlaying = nowPlayingStoryboard.instantiateViewController(withIdentifier: "nowPlaying") as? NowPlayingViewController {
                
                previewingContext.sourceRect = altNowPlayingButtonContainsLocation ? bottomEffectView.convert(altNowPlayingViewSuperview.frame, from: tabView) : songTitlesStackView.frame
                
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
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UISwipeGestureRecognizer && otherGestureRecognizer.view == gestureRecognizer.view
    }
}
