//
//  NowPlayingViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 10/07/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit
import StoreKit

class NowPlayingViewController: UIViewController, ArtistTransitionable, AlbumTransitionable, AlbumArtistTransitionable, GenreTransitionable, ComposerTransitionable, PreviewTransitionable, InteractivePresenter, TimerBased, SingleItemActionable, Boldable, EntityVerifiable, Peekable, BackgroundHideable, ArtworkModifying, ArtworkModifierContaining {

    @IBOutlet var songName: MELButton!
    @IBOutlet var artistButton: MELButton!
    @IBOutlet var albumButton: MELButton!
    @IBOutlet var albumArt: UIImageView!
    @IBOutlet var albumArtContainer: UIView!
    @IBOutlet var closeButtonBorder: UIView! {
        
        didSet {
            
            closeButtonBorder.superview?.isHidden = !showCloseButton
            UniversalMethods.addShadow(to: closeButtonBorder, radius: 10, opacity: 0.3, path: UIBezierPath.init(roundedRect: .init(x: 0, y: 0, width: 26, height: 26), cornerRadius: 13).cgPath)
        }
    }
    @IBOutlet var divider: MELLabel!
    @IBOutlet var playPauseButton: MELButton!
    @IBOutlet var previous: MELButton!
    @IBOutlet var nextButton: MELButton!
    @IBOutlet var shuffle: MELButton?
    @IBOutlet var startTime: MELLabel!
    @IBOutlet var stopTime: MELLabel!
    @IBOutlet var timeSlider: MELSlider!
    @IBOutlet var queueButton: MELButton!
    @IBOutlet var lyricsButton: MELButton!
    @IBOutlet var lyricsVisualEffectView: MELVisualEffectView!
    @IBOutlet var nowPlayingView: UIView!
    @IBOutlet var horizontalConstraints: [NSLayoutConstraint]!
    @IBOutlet var songNameWidthConstraint: NSLayoutConstraint!
    @IBOutlet var albumWidthConstraint: NSLayoutConstraint!
    @IBOutlet var albumArtContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet var albumArtContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet var nowPlayingViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var detailsView: UIView!
    @IBOutlet var songNameScrollView: UIScrollView!
    @IBOutlet var songDetailsScrollView: UIScrollView!
    @IBOutlet var volumeViewContainer: UIView! {
        
        didSet {
            
            if showVolumeViews {
                
                volumeViewContainer.fill(with: volumeView)
                
            } else {
                
                volumeViewContainer.fill(with: rateShareView)
            }
        }
    }
    @IBOutlet var volumeViewContainerEqualHeightConstraint: NSLayoutConstraint!
    @IBOutlet var volumeViewContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var timeViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var addButtonLeadingConstraint: NSLayoutConstraint?
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var actionsButton: MELButton! {
        
        didSet {
            
            let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(showSettings(with:)))
            gr.minimumPressDuration = longPressDuration
            actionsButton.addGestureRecognizer(gr)
            LongPressManager.shared.gestureRecognisers.append(Weak.init(value: gr))
        }
    }
    @IBOutlet var repeatView: MELBorderView? {
        
        didSet {
            
            repeatView?.layer.setRadiusTypeIfNeeded()
            repeatView?.layer.cornerRadius = 8
        }
    }
    @IBOutlet var repeatButton: MELButton?
    @IBOutlet var statusBarBackground: UIView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var effectView: MELVisualEffectView!
    @IBOutlet var artworkIntermediaryView: UIView!
    @IBOutlet var shuffleView: MELBorderView? {
        
        didSet {
            
            shuffleView?.layer.setRadiusTypeIfNeeded()
            shuffleView?.layer.cornerRadius = 8
        }
    }
    @IBOutlet var queueChevronTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var editButton: MELButton! {
        
        didSet {
            
            editButton.addTarget(songManager, action: #selector(SongActionManager.showActionsForAll(_:)), for: .touchUpInside)
        }
    }
    
    @objc lazy var rateShareView: RateShareView = { RateShareView.instance(container: self) }()
    lazy var volumeView = VolumeView.instance(leadingWith: 25)
    
    override var modalPresentationStyle: UIModalPresentationStyle {
        
        get { return .overFullScreen }
        
        set { }
    }
    
    @objc var actionableSongs: [MPMediaItem] { return [activeItem].compactMap({ $0 }) }
    var applicableActions: [SongAction] {
        
        var actions = [SongAction.collect, .newPlaylist, .addTo, .show(title: activeItem?.validTitle, context: .song(location: .list, at: 0, within: actionableSongs), canDisplayInLibrary: true)/*, .search(unwinder: { [weak self] in self })*/]
        
        if activeItem?.existsInLibrary == false {
            
            actions.append(.library)
        }
        
        return actions
    }
    @objc lazy var songManager: SongActionManager = { return SongActionManager.init(actionable: self) }()
    
    @objc lazy var temporaryImageView: UIImageView = {
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    @objc lazy var temporaryEffectView = MELVisualEffectView()
    
    @objc let animator = NowPlayingAnimationController.init(interactor: NowPlayingInteractionController.init())
    @objc let presenter = PresentationAnimationController.init(interactor: InteractionController())
    
    @objc weak var peeker: UIViewController?
    var oldArtwork: UIImage?
    
    @objc weak var container: ContainerViewController?
    @objc var from3DTouch: Bool { return peeker != nil }
    var alternateItem: MPMediaItem?
    @objc var albumQuery: MPMediaQuery?
    @objc var albumArtistQuery: MPMediaQuery?
    @objc var artistQuery: MPMediaQuery?
    @objc var genreQuery: MPMediaQuery?
    @objc var composerQuery: MPMediaQuery?
    @objc var currentItem: MPMediaItem?
    @objc var currentAlbum: MPMediaItemCollection?
    @objc var viewController: UIViewController?
    var isCurrentlyTopViewController = false
    @objc var lifetimeObservers = Set<NSObject>()
    let playingImage = #imageLiteral(resourceName: "Pause")
    let pausedImage = #imageLiteral(resourceName: "Play")
    let playPauseButtonNeedsAnimation = false
    let prefersBoldOnTap = false
    var updateableView: UIView? { return detailsView }
    var lyricsViewVisibility = VisibilityState.hidden
    var activeItem: MPMediaItem? { return alternateItem ?? musicPlayer.nowPlayingItem }
    
    var artwork: UIImage? {
        
        get { return activeItem?.actualArtwork?.image(at: .artworkSize) }
        
        set { }
    }
    var topArtwork: UIImage?
    var modifier: ArtworkModifying? { return self }
    
    var useContinuousCorners: Bool {
        
        switch cornerRadius {
            
            case .automatic: return fullPlayerCornerRadius != .rounded
            
            default: return cornerRadius != .rounded
        }
    }
    
    var boldableLabels: [TextContaining?] { return [albumButton.titleLabel, songName.titleLabel, artistButton.titleLabel, divider] }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let button = repeatButton {
        
            repeatView?.superview?.bringSubviewToFront(button)
        }
        
        if let button = shuffle {
        
            shuffleView?.superview?.bringSubviewToFront(button)
        }
        
        modalPresentationCapturesStatusBarAppearance = true
        NowPlaying.shared.nowPlayingVC = self
        ArtworkManager.shared.nowPlayingVC = self
        
        animator.interactor.addToVC(self)
        
        if let _ = peeker, let imageView = container?.imageView {
        
            ArtworkManager.shared.currentlyPeeking = self
            UIView.transition(with: imageView, duration: 0.5, options: .transitionCrossDissolve, animations: { imageView.image = self.artworkType.image }, completion: nil)
        }
        
        artworkIntermediaryView.layer.setRadiusTypeIfNeeded(to: useContinuousCorners)
        
        useAlternateAnimation = false
        shouldReturnToContainer = false
        
        updateDetailsView()
        
        prepareViews(animated: false)
        updateSliderDuration()
        updateTimes(setValue: true, seeking: false)
        preparePlaybackGestures()
        updateTitle()
        prepareLifetimeObservers()
        prepareDetailLabels()
        
        modifyShuffleState(changingMusicPlayer: false)
        modifyRepeatButton(changingMusicPlayer: false)
        
        registerForPreviewing(with: self, sourceView: nowPlayingView)
        prepareGestures()
    }
    
    @IBAction func showArtistOptions(_ sender: UILongPressGestureRecognizer) {
        
        guard let _ = activeItem else { return }
        
        if sender.state == .began {
            
            guard artistQuery != nil else {
                
                let newBanner = Banner.init(title: showiCloudItems ? "This artist is not in your library" : "This artist is not available offline", subtitle: nil, image: nil, backgroundColor: .black, didTapBlock: nil)
                newBanner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
                newBanner.show(duration: 0.7)
                
                return
            }
            
            performSegue(withIdentifier: "toArtistOptions", sender: nil)
        }
    }
    
    @objc func showAlbumOptions() {
        
        guard let _ = activeItem else { return }
            
        performSegue(withIdentifier: "toAlbumOptions", sender: nil)
    }
    
    @objc func prepareGestures() {
        
        let artistHold = UILongPressGestureRecognizer.init(target: self, action: #selector(performHold))
        artistHold.minimumPressDuration = longPressDuration
        artistButton.addGestureRecognizer(artistHold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: artistHold))
        
        let albumHold = UILongPressGestureRecognizer.init(target: self, action: #selector(performHold))
        albumHold.minimumPressDuration = longPressDuration
        albumButton.addGestureRecognizer(albumHold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: albumHold))
        
        let mixHold = UILongPressGestureRecognizer.init(target: self, action: #selector(changeArtworkSize(_:)))
        mixHold.minimumPressDuration = longPressDuration
        albumArtContainer.addGestureRecognizer(mixHold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: mixHold))
        
        let songHold = UILongPressGestureRecognizer.init(target: self, action: #selector(performHold))
        songHold.minimumPressDuration = longPressDuration
        songName.addGestureRecognizer(songHold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: songHold))
        
        let edge = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(goToQueue))
        edge.edges = .right
        view.addGestureRecognizer(edge)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(viewLyrics))
        albumArtContainer.addGestureRecognizer(tap)
        
        let doubleTap = UITapGestureRecognizer.init(target: self, action: #selector(changeArtworkSize(_:)))
        doubleTap.numberOfTapsRequired = 2
        albumArtContainer.addGestureRecognizer(doubleTap)
        
        let incrementSkip = UITapGestureRecognizer.init(target: self, action: #selector(skipWithIncrement(_:)))
        incrementSkip.numberOfTapsRequired = 2
        incrementSkip.delegate = self
        incrementSkip.delaysTouchesBegan = true
        nextButton.addGestureRecognizer(incrementSkip)
    }
    
    @objc func skipWithIncrement(_ gr: UITapGestureRecognizer) {
        
        guard let item = musicPlayer.nowPlayingItem else { return }

        musicPlayer.currentPlaybackTime = item.playbackDuration
    }
    
    @objc func performHold(_ sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
            
            case .began:
                
                enum HeldButton {
                    
                    case song, artist, album
                    
                    var entityType: EntityType {
                        
                        switch self {
                            
                            case .song: return .song
                            
                            case .artist: return .artist
                            
                            case .album: return .album
                        }
                    }
                }
                
                let button: HeldButton = {
                    
                    switch sender.view {
                        
                        case let x where x == songName: return .song
                        
                        case let x where x == artistButton: return .artist
                        
                        default: return .album
                    }
                }()
                
                guard let entity: MPMediaEntity = {
                    
                    switch button {
                        
                        case .song: return activeItem
                        
                        case .album: return albumQuery?.collections?.first
                        
                        case .artist: return artistQuery?.collections?.first
                    }
                    
                }() else {
                
                    switch button {
                        
                        case .song: return
                        
                        case .album:
                        
                            let newBanner = Banner.init(title: showiCloudItems ? "This album is not in your library" : "This album is not available offline", subtitle: nil, image: nil, backgroundColor: .black, didTapBlock: nil)
                            newBanner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
                            newBanner.show(duration: 1)
                            
                            return
                        
                        case .artist:
                        
                            let newBanner = Banner.init(title: showiCloudItems ? "This artist is not in your library" : "This artist is not available offline", subtitle: nil, image: nil, backgroundColor: .black, didTapBlock: nil)
                            newBanner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
                            newBanner.show(duration: 1)
                            
                            return
                    }
                }
            
                let info = AlertAction.init(title: "Get Info", style: .default, requiresDismissalFirst: true, handler: { [weak self] in
                    
                    guard let weakSelf = self else { return }
                    
                    switch button {
                        
                        case .song: weakSelf.showOptions(weakSelf)
                        
                        case .album: weakSelf.performSegue(withIdentifier: "toAlbumOptions", sender: nil)
                        
                        case .artist: weakSelf.performSegue(withIdentifier: "toArtistOptions", sender: nil)
                    }
                })
            
                let temp: [SongAction] = {
                    
                    switch button {
                        
                        case .song: return applicableActions
                        
                        case .album: return [SongAction.collect, .show(title: albumButton.title(for: .normal), context: .album(at: 0, within: albumQuery?.collections ?? []), canDisplayInLibrary: true), .newPlaylist, .addTo/*, .search(unwinder: { [weak self] in self })*/]
                        
                        case .artist: return [SongAction.collect, .show(title: artistButton.title(for: .normal), context: .collection(kind: .artist, at: 0, within: artistQuery?.collections ?? []), canDisplayInLibrary: true), .newPlaylist, .addTo/*, .search(unwinder: { [weak self] in self })*/]
                    }
                }()
                
                var array = temp.map({ singleItemAlertAction(for: $0, entityType: button.entityType, using: entity, from: self, useAlternateTitle: false) })
                array.append(info)
                
                showAlert(title: (sender.view as? UIButton)?.title(for: .normal), with: array)
            
            case .changed, .ended:
            
                guard let top = topViewController as? VerticalPresentationContainerViewController else { return }
                
                top.gestureActivated(sender)
            
            default: break
        }
    }
    
    @IBAction func showSongActions() {
        
        guard let item = activeItem else { return }
        
        singleItemActionDetails(for: .show(title: item.validTitle, context: .song(location: .list, at: 0, within: [item]), canDisplayInLibrary: true), entityType: .song, using: item, from: self).handler()
    }
    
    @objc func goToQueue(_ sender: UIGestureRecognizer) {
        
        guard sender.state == .began/*, let _ = musicPlayer.nowPlayingItem*/ else { return }
        
        performSegue(withIdentifier: "toQueue", sender: nil)
    }
    
    @objc func changeArtworkSize(_ gr: UILongPressGestureRecognizer) {
        
        guard gr.state == .began, !isSmallScreen else { return }
        
        prefs.set(!dynamicStatusBar, forKey: .dynamicStatusBar)
        updateArtworkImageView(changingArt: true, animated: true)
    }
    
    @objc func prepareLifetimeObservers() {
        
        lifetimeObservers.insert(notifier.addObserver(forName: .playerChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.unregisterAll(from: weakSelf.lifetimeObservers)
            weakSelf.prepareLifetimeObservers()
            
            weakSelf.prepareViews(animated: true, shouldDismiss: false)
            
            weakSelf.updateSliderDuration()
            weakSelf.updateTimes(setValue: true, seeking: false)
        
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: UIApplication.willEnterForegroundNotification, object: UIApplication.shared, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.modifyShuffleState(changingMusicPlayer: false)
            weakSelf.modifyRepeatButton(changingMusicPlayer: false)
            weakSelf.modifyQueueLabel()
            weakSelf.verifyLibraryStatus(of: weakSelf.activeItem, itemProperty: .song)
            weakSelf.verifyLibraryStatus(of: weakSelf.activeItem, itemProperty: .artist)
            weakSelf.verifyLibraryStatus(of: weakSelf.activeItem, itemProperty: .album)
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .queueModified, object: nil, queue: nil, using: { [weak self] _ in self?.modifyQueueLabel() }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .shuffleInvoked, object: nil, queue: nil, using: { [weak self] _ in self?.modifyQueueLabel() }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateArtworkImageView(changingArt: true, animated: true)
            
        }) as! NSObject)
        
        [Notification.Name.compressOnPauseChanged, .separationMethodChanged, .avoidDoubleHeightBarChanged, UIApplication.didChangeStatusBarFrameNotification, .cornerRadiusChanged].forEach({
            
            lifetimeObservers.insert(notifier.addObserver(forName: $0, object: nil, queue: nil, using: { [weak self] notification in
                
                guard let weakSelf = self else { return }
                
                if notification.name == .cornerRadiusChanged {
                    
                    weakSelf.artworkIntermediaryView.layer.setRadiusTypeIfNeeded(to: weakSelf.useContinuousCorners)
                }
                
                weakSelf.updateArtworkImageView(changingArt: true, animated: true)
                
            }) as! NSObject)
        })
        
        lifetimeObservers.insert(notifier.addObserver(forName: .songsAddedToPlaylists, object: nil, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self, let song = musicPlayer.nowPlayingItem, let songs = notification.userInfo?[.addedSongs] as? [MPMediaItem], Set(songs).contains(song) else { return }
            
            weakSelf.updateAddButton(hidden: true, animated: true)
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .dynamicStatusBarChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateArtworkImageView(changingArt: true, animated: true)
                
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .showNowPlayingSupplementaryViewChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            self?.updateDetailsView(needsArtworkUpdate: false)
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .nowPlayingTextSizesChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.prepareDetailLabels()
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .iCloudVisibilityChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.verifyLibraryStatus(of: weakSelf.activeItem, itemProperty: .song)
            weakSelf.verifyLibraryStatus(of: weakSelf.activeItem, itemProperty: .artist)
            weakSelf.verifyLibraryStatus(of: weakSelf.activeItem, itemProperty: .album)
            
        }) as! NSObject)
        
//        lifetimeObservers.insert(notifier.addObserver(forName: .libraryUpdated, object: appDelegate, queue: nil, using: { [weak self] _ in
//            
//            guard let weakSelf = self, weakSelf.activeItem?.existsInLibrary == false else { return }
//            
//            useAlternateAnimation = true
//            musicPlayer.stop()
//            notifier.post(name: .saveQueue, object: musicPlayer, userInfo: [String.queueItems: []])
//        
//        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .nowPlayingItemChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.updateTitle()
            weakSelf.prepareViews(animated: true)
            weakSelf.updateSliderDuration()
            weakSelf.updateTimes(setValue: true, seeking: false)
            
            if weakSelf.from3DTouch {
                
                weakSelf.oldArtwork = ArtworkManager.shared.activeContainer?.modifier?.artworkType.image
                weakSelf.updateMoveButtons(visible: true)
            }
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .ratingChanged, object: nil, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self, let view = notification.userInfo?[String.sender] as? UIStackView, view != weakSelf.rateShareView.ratingStackView, let id = notification.userInfo?[String.id] as? MPMediaEntityPersistentID, id == weakSelf.activeItem?.persistentID else { return }
            
            weakSelf.rateShareView.setRating()
       
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .likedStateChanged, object: nil, queue: nil, using: { [weak self] notification in
            
            guard let weakSelf = self, let view = notification.userInfo?[String.sender] as? UIStackView, view != weakSelf.rateShareView.ratingStackView, let id = notification.userInfo?[String.id] as? MPMediaEntityPersistentID, id == weakSelf.activeItem?.persistentID else { return }
            
            weakSelf.rateShareView.prepareLikedView()
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .volumeVisibilityChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            if showVolumeViews {
                
                weakSelf.rateShareView.removeFromSuperview()
                weakSelf.volumeViewContainer.fill(with: weakSelf.volumeView)
            
            } else {
                
                weakSelf.volumeView.removeFromSuperview()
                weakSelf.volumeViewContainer.fill(with: weakSelf.rateShareView)
            }
            
        }) as! NSObject)
        
        lifetimeObservers.insert(notifier.addObserver(forName: .showCloseButtonChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.closeButtonBorder.superview?.isHidden = !showCloseButton
        
        }) as! NSObject)
    }
    
    @objc func prepareDetailLabels() {
        
        changeSize(to: nowPlayingBoldTextEnabled ? .regular : .light)
    }
    
    @objc func updateTitle() {
        
        title = {
            
            if let title = activeItem?.validTitle, let artist = activeItem?.validArtist {
                
                return title + " — " + artist
                
            } else {
                
                return "Now Playing"
            }
        }()
    }
    
    @objc func updateMoveButtons(visible: Bool) {
        
        let rated: (Bool, Int) = {
            
            guard let rating = activeItem?.rating else { return (false, 0) }
            
            return (rating > 0, rating)
        }()
        
        if visible {
            
            let rating = rated.0 ? #imageLiteral(resourceName: "StarFilled17") : #imageLiteral(resourceName: "Star17")
            var love: UIImage {
                
                guard let likedState = activeItem?.likedState else { return #imageLiteral(resourceName: "NoLove17") }
                
                switch likedState {
                    
                    case .none: return #imageLiteral(resourceName: "NoLove17")
                        
                    case .liked: return #imageLiteral(resourceName: "Loved17")
                        
                    case .disliked: return #imageLiteral(resourceName: "Unloved17")
                }
            }
            
            playPauseButton.isHidden = true
            previous.setImage(rating, for: .normal)
            previous.setTitle(rated.0 ? rated.1.description : "", for: .normal)
            previous.imageEdgeInsets.right = rated.0 ? 3 : 0
            nextButton.setImage(love, for: .normal)
            
        } else {
            
            playPauseButton.isHidden = false
            previous.setImage(#imageLiteral(resourceName: "Back"), for: .normal)
            previous.setTitle("", for: .normal)
            previous.imageEdgeInsets.right = 0
            nextButton.setImage(#imageLiteral(resourceName: "Forward"), for: .normal)
        }
    }
    
    func updateDetailsView(needsArtworkUpdate: Bool = true) {
        
        if !isSmallScreen {
            
            let doNotShowSupplementaryView = showNowPlayingSupplementaryView.inverted
            
            updateMoveButtons(visible: from3DTouch)
            volumeViewContainer.isHidden = from3DTouch || doNotShowSupplementaryView
            volumeViewContainerEqualHeightConstraint.isActive = !(from3DTouch || doNotShowSupplementaryView)
            volumeViewContainerHeightConstraint.isActive = from3DTouch || doNotShowSupplementaryView
            volumeViewContainerHeightConstraint.priority = UILayoutPriority(rawValue: doNotShowSupplementaryView || from3DTouch ? 999 : 250)
        }
        
        guard needsArtworkUpdate else { return }
        
        updateArtworkImageView(changingArt: false, animated: false)
    }
    
    @objc func updateArtworkImageView(changingArt: Bool, animated: Bool) {
        
        // ratio obtained from 3D Touch Peek screenshot
        let verticalRatio: CGFloat = 1054/1334
        let horizontalRatio: CGFloat = 694/750
        let displayHeight = UIScreen.main.bounds.height * (from3DTouch ? verticalRatio : 1)
        let displayWidth = UIScreen.main.bounds.width * (from3DTouch ? horizontalRatio : 1)
        
        let buttonsSpaceUsed: CGFloat = {
            
            if isSmallScreen {
                
                return 248
                
            } else {
                
                return UIScreen.main.bounds.height - UIScreen.main.bounds.width - (from3DTouch ? heightOfSupplementaryView() : 0)
            }
        }()
        
        let trialConstraints: (top: CGFloat, bottom: CGFloat) = {
            
            if isiPhoneX {
                
                if dynamicStatusBar {
                    
                    return musicPlayer.isPlaying || !compressOnPause ? (0, 0) : (UIApplication.shared.statusBarFrame.height + 40, 40)
                    
                } else {
                    
                    switch separationMethod {
                        
                        case .overlay: return (0, 0)
                        
                        case .below: return (UIApplication.shared.statusBarFrame.height + (musicPlayer.isPlaying || !compressOnPause ? 0 : 40), (musicPlayer.isPlaying || !compressOnPause ? 0 : 40))
                        
                        case .smaller: return (UIApplication.shared.statusBarFrame.height + 20 + (musicPlayer.isPlaying || !compressOnPause ? 0 : 20), 20 + (musicPlayer.isPlaying || !compressOnPause ? 0 : 40))
                    }
                }
            
            } else {
                
                if from3DTouch || isSmallScreen {
                    
                    return musicPlayer.isPlaying || !compressOnPause ? (35, 20) : (55, 40)
                }
                
                let high: CGFloat = 52
                let low: CGFloat = 32
                let higher = high + 20
                
                if dynamicStatusBar {
                    
                    if avoidDoubleHeightBar && UIApplication.shared.statusBarFrame.height == 40 {
                        
                        return (20 + (musicPlayer.isPlaying || !compressOnPause ? 0 : high), musicPlayer.isPlaying || !compressOnPause ? 0 : 40)
                    
                    } else {
                        
                        return (musicPlayer.isPlaying || !compressOnPause ? 0 : higher, musicPlayer.isPlaying || !compressOnPause ? 0 : 40)
                    }
                
                } else {
                    
                    switch separationMethod {
                        
                        case .overlay:
                        
                            if avoidDoubleHeightBar && UIApplication.shared.statusBarFrame.height == 40 {
                                
                                return (20 + (musicPlayer.isPlaying || !compressOnPause ? 0 : higher/* - 20*/), musicPlayer.isPlaying || !compressOnPause ? 0 : 40)
                                
                            } else {
                                
                                return (musicPlayer.isPlaying || !compressOnPause ? 0 : higher, musicPlayer.isPlaying || !compressOnPause ? 0 : 40)
                            }
                        
                        case .below: return (20 + (musicPlayer.isPlaying || !compressOnPause ? 0 : high /*- (UIApplication.shared.statusBarFrame.height == 40 ? 20 : 0)*/), musicPlayer.isPlaying || !compressOnPause ? 0 : 40)
                        
                        case .smaller: return (20 + low + (musicPlayer.isPlaying || !compressOnPause ? 0 : 20 /*- (UIApplication.shared.statusBarFrame.height == 40 ? 20 : 0)*/), 20 + (musicPlayer.isPlaying || !compressOnPause ? 0 : 20))
                    }
                }
            }
        }()
        
        albumArtContainerTopConstraint.constant = trialConstraints.top
        albumArtContainerBottomConstraint.constant = trialConstraints.bottom
        
        let horizontal: CGFloat = {
            
            let constraint = (displayWidth - (displayHeight - buttonsSpaceUsed - trialConstraints.top - trialConstraints.bottom)) / 2
            
            if isiPhoneX {
            
                if dynamicStatusBar {
                    
                    return musicPlayer.isPlaying || !compressOnPause ? 0 : constraint
                    
                } else {
                    
                    switch separationMethod {
                        
                        case .overlay: return 0
                        
                        case .below: return musicPlayer.isPlaying || !compressOnPause ? 0 : constraint
                        
                        case .smaller: return constraint
                    }
                }
            
            } else {
                
                if from3DTouch || isSmallScreen {
                    
                    return constraint
                }
                
                if dynamicStatusBar {
                    
                    if avoidDoubleHeightBar && UIApplication.shared.statusBarFrame.height == 40 {
                        
                        return musicPlayer.isPlaying || !compressOnPause ? 0 : constraint
                    
                    } else {
                        
                        return musicPlayer.isPlaying || !compressOnPause ? 0 : constraint
                    }
                
                } else {
                    
                    switch separationMethod {
                        
                        case .overlay:
                        
                            if avoidDoubleHeightBar && UIApplication.shared.statusBarFrame.height == 40 {
                                
                                return musicPlayer.isPlaying || !compressOnPause ? 0 : constraint
                                
                            } else {
                                
                                return musicPlayer.isPlaying || !compressOnPause ? 0 : constraint
                            }
                        
                        case .below: return musicPlayer.isPlaying || !compressOnPause ? 0 : constraint
                        
                        case .smaller: return constraint
                    }
                }
            }
        }()
        
        horizontalConstraints.forEach({ $0.constant = horizontal })
        
        var radius: CGFloat {
            
            switch cornerRadius {
            
                case .automatic: return fullPlayerCornerRadius?.nowPlayingRadius(width: displayWidth - (horizontal * 2)) ?? 8
            
                default: return cornerRadius.radius(for: .song, width: displayWidth - (horizontal * 2))
            }
        }
        
        if animated {
            
            UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState], animations: {
                
                self.view.layoutIfNeeded()
                self.setNeedsStatusBarAppearanceUpdate()
                self.statusBarBackground.backgroundColor = !dynamicStatusBar && separationMethod == .overlay ? Themer.themeColour(reversed: true, alpha: 0.5) : .clear
            
            }, completion: nil)
            
            artworkIntermediaryView.animateCornerRadius(to: isSmallScreen || (compressOnPause && musicPlayer.isPlaying.inverted) || from3DTouch || (dynamicStatusBar.inverted && separationMethod == .smaller) ? radius : 0, duration: 0.65 / 4)
            albumArtContainer.animateShadowOpacity(to: musicPlayer.isPlaying || !compressOnPause ? 0.5 : 0, duration: 0.65)
            
        } else {
            
            view.layoutIfNeeded()
            
            if albumArtContainer.layer.shadowOpacity < 0.1 {
                
                UniversalMethods.addShadow(to: albumArtContainer, radius: 20, opacity: musicPlayer.isPlaying || !compressOnPause ? 0.5 : 0, shouldRasterise: true)
            }
            
            artworkIntermediaryView.layer.cornerRadius = isSmallScreen || (compressOnPause && musicPlayer.isPlaying.inverted) || from3DTouch || (dynamicStatusBar.inverted && separationMethod == .smaller) ? radius : 0
            statusBarBackground.backgroundColor = !dynamicStatusBar && separationMethod == .overlay ? Themer.themeColour(reversed: true, alpha: 0.5) : .clear
            setNeedsStatusBarAppearanceUpdate()
        }
        
        if changingArt { updateArtwork() }
    }
    
    @objc func perfrom3DTouchCleanup() {
        
        updateDetailsView()
        updateArtwork()
    }
    
    @objc func updateArtwork() {
        
        if let nowPlaying = activeItem {
            
            let image = nowPlaying.actualArtwork?.image(at: .init(width: albumArtContainer.bounds.width, height: albumArtContainer.bounds.height)) ?? #imageLiteral(resourceName: "NoSong900")

            albumArt.image = image
        }
    }
    
    @objc func heightOfSupplementaryView() -> CGFloat {
        // ... - time view - bottom view - details view
        return (UIScreen.main.bounds.height - UIScreen.main.bounds.width - 38 - 46 - 70) / 2
    }
    
    @objc func updateSliderDuration() {
        
        if let nowPlaying = activeItem {
            
            timeSlider.minimumValue = 0
            timeSlider.maximumValue = Float(nowPlaying.playbackDuration)
        }
    }
    
    @objc func clearQueue() {
        
        if let nowPlaying = musicPlayer.nowPlayingItem {
            
            if warnForQueueInterruption && clearGuard {
                #warning("Check if this can use the queue guard booleans")
                let clear = AlertAction.init(title: "Clear Queue", style: .destructive, requiresDismissalFirst: true, handler: {
                    
                    musicPlayer.play([nowPlaying], startingFrom: nowPlaying, respectingPlaybackState: true, from: nil, withTitle: nil, alertTitle: "")
                })
                
                showAlert(title: nil, with: clear)
                
            } else {
                
                musicPlayer.play([nowPlaying], startingFrom: nowPlaying, respectingPlaybackState: true, from: nil, withTitle: nil, alertTitle: "")
            }
        }
    }
    
    @objc func prepareViews(animated: Bool, shouldDismiss: Bool = true) {
        
        if shouldDismiss, activeItem == nil {
            
            performSegue(withIdentifier: "unwind", sender: nil)
            
            return
        }
        
        songNameScrollView.contentOffset = .zero
        songDetailsScrollView.contentOffset = .zero
        
        let albumTitle = activeItem?.validAlbum ?? "Album"
        let artistName = activeItem?.validArtist ?? "Artist"
        let songTitle = activeItem?.validTitle ?? "Song Name"
        let albumImage = activeItem?.actualArtwork?.image(at: self.albumArtContainer.bounds.size)
        let image = activeItem?.actualArtwork?.image(at: .init(width: 20, height: 20))
        
        if animated {
            
            UniversalMethods.performTransitions(withRelevantParameters:
                
                (albumArt, 0.3, { [weak self] in self?.albumArt.image = albumImage ?? #imageLiteral(resourceName: "NoSong900") }, nil),
                (imageView, 0.3, { [weak self] in self?.imageView.image = image ?? #imageLiteral(resourceName: "NoArt") }, nil)
            )
            
            if peeker != nil {
                
                UIView.transition(with: temporaryImageView, duration: 0.3, options: .transitionCrossDissolve, animations: { [weak self] in self?.temporaryImageView.image = image ?? #imageLiteral(resourceName: "NoArt") }, completion: nil)
            }
            
        } else {
            
            albumArt.image = albumImage ?? #imageLiteral(resourceName: "NoSong900")
            imageView.image = image ?? #imageLiteral(resourceName: "NoArt")
            temporaryImageView.image = image ?? #imageLiteral(resourceName: "NoArt")
        }
        
        songName.setTitle(songTitle, for: .normal)
        artistButton.setTitle(artistName, for: .normal)
        albumButton.setTitle(albumTitle, for: .normal)
        
        detailsView.layoutIfNeeded()
        
        if songName.intrinsicContentSize.width < songNameScrollView.bounds.width {
            
            songNameWidthConstraint.constant = songNameScrollView.bounds.width
            songNameWidthConstraint.priority = UILayoutPriority(rawValue: 999)
            
        } else {
            
            songNameWidthConstraint.priority = UILayoutPriority(rawValue: 249)
        }
        
        if albumButton.intrinsicContentSize.width + artistButton.intrinsicContentSize.width < songDetailsScrollView.bounds.width {
            
            albumWidthConstraint.constant = songDetailsScrollView.bounds.width - artistButton.intrinsicContentSize.width
            albumWidthConstraint.priority = UILayoutPriority(rawValue: 999)
            
        } else {
            
            albumWidthConstraint.priority = UILayoutPriority(rawValue: 249)
        }
        
        modifyQueueLabel()
        modifyPlayPauseButton()
        rateShareView.entity = activeItem
        setNeedsStatusBarAppearanceUpdate()
        verifyLibraryStatus(of: activeItem, itemProperty: .song)
        verifyLibraryStatus(of: activeItem, itemProperty: .artist)
        verifyLibraryStatus(of: activeItem, itemProperty: .album)
        
        if let lyricsVC = children.first as? LyricsViewController, lyricsViewVisibility == .visible {
            
            lyricsVC.manager.item = activeItem
        }
    }
    
    func modifyLyricsView(to state: VisibilityState) {
        
        if state == .visible, let lyricsVC = children.first as? LyricsViewController {
            
            lyricsVC.manager.item = activeItem
        }
        
        lyricsViewVisibility = state
        lyricsVisualEffectView.isUserInteractionEnabled = state == .visible
        
        lyricsButton.update(for: state == .hidden ? .unselected : .selected)
        
        UIView.animate(withDuration: 0.3, animations: {
        
            self.lyricsVisualEffectView.effect = state == .hidden ? nil : Themer.vibrancyContainingEffect
            self.lyricsVisualEffectView.alpha = state == .hidden ? 0 : 1
        })
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    @IBAction func viewLyrics() {
        
        modifyLyricsView(to: lyricsViewVisibility == .hidden ? .visible : .hidden)
    }

    @objc func modifyQueueLabel() {
        
        guard musicPlayer.nowPlayingItem != nil else {
            
            queueButton.setTitle("Queue", for: .normal)
            
            return
        }
        
        queueButton.superview?.layoutIfNeeded()
        
        let string = musicPlayer.fullQueueCount(withInitialSpace: false, parentheses: false).uppercased()
        queueButton.setTitle(string, for: .normal)
        queueButton.attributes = [Attributes.init(name: .font, value: .other(UIFont.font(ofWeight: .regular, size: 13)), range: string.nsRange(of: "OF"))]
        
        queueChevronTrailingConstraint.constant = queueButton.intrinsicContentSize.width + 3
        
        UIView.animate(withDuration: 0.3, animations: { self.queueButton.superview?.layoutIfNeeded() })
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        guard /*!useSmallerArt &&*/
            !isSmallScreen &&
            (musicPlayer.isPlaying || !compressOnPause) &&
            dynamicStatusBar &&
            activeItem?.actualArtwork != nil &&
            lyricsViewVisibility == .hidden
            else { return darkTheme ? .lightContent : .default }

        return activeItem?.artwork?.image(at: CGSize.init(width: 20, height: 20))?.crop(within: CGRect.init(x: 5, y: 0, width: 20, height: (UIApplication.shared.statusBarFrame.height / UIScreen.main.bounds.width) * 10))?.statusBarStyle() ?? {
            
            if #available(iOS 13, *) { return .darkContent }
            
            return .default
        }()
    }
    
    @objc func preparePlaybackGestures() {
        
        let seekBackward = UILongPressGestureRecognizer(target: self, action: #selector(seekBackward(_:)))
        previous.addGestureRecognizer(seekBackward)
        
        let seekForward = UILongPressGestureRecognizer(target: self, action: #selector(seekForward(_:)))
        nextButton.addGestureRecognizer(seekForward)
    }
    
    @objc func seekForward(_ gr: UILongPressGestureRecognizer) {
        
        if gr.state == .began {
            
            musicPlayer.beginSeekingForward()
        
        } else if gr.state == .ended || gr.state == .cancelled {
            
            musicPlayer.endSeeking()
        }
    }
    
    @objc func seekBackward(_ gr: UILongPressGestureRecognizer) {
        
        if gr.state == .began {
            
            musicPlayer.beginSeekingBackward()
        
        } else if gr.state == .ended || gr.state == .cancelled {
            
            musicPlayer.endSeeking()
        }
    }
    
    @IBAction func nextSong() {
        
        musicPlayer.skipToNextItem()
    }
    
    @IBAction func previousSong() {
        
        if musicPlayer.currentPlaybackTime < 4 {
            
            musicPlayer.skipToPreviousItem()
            
        } else {
            
            musicPlayer.skipToBeginning()
            NowPlaying.shared.registered.forEach({ $0?.updateTimes(setValue: true, seeking: false) })
        }
    }
    
    @IBAction func goToArtist() {
        
        guard activeItem != nil else { return }
        
        performUnwindSegue(with: .artist, isEntityAvailable: artistQuery != nil, title: EntityType.artist.title())
    }
    
    @IBAction func goToAlbum() {
        
        guard activeItem != nil else { return }
        
        performUnwindSegue(with: .album, isEntityAvailable: albumQuery != nil, title: EntityType.album.title())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        NowPlaying.shared.nowPlayingVC = nil
        ArtworkManager.shared.nowPlayingVC = nil
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismissVC(_ sender: AnyObject) {
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func pop(to vc: UIViewController?, queue: Bool) {
        
        if queue {
            
            guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
                
            presentedVC.qVC = vc as! QueueViewController
            presentedVC.context = .queue
            
            present(presentedVC, animated: false, completion: nil)
        
        } else {
            
            viewController = vc
            
            performSegue(withIdentifier: "preview", sender: nil)
        }
    }
    
    @objc @discardableResult func performTransition(to vc: UIViewController, sender: Any?, perform3DTouchActions: Bool = false) -> UIViewController? {
        
        if let presentedVC = vc as? PresentedContainerViewController {
            
            presentedVC.context = .queue
            
            return presentedVC
        
        } else if let queueVC = vc as? QueueViewController {
            
            queueVC.peeker = self
            queueVC.modifyBackgroundView(forState: .visible)
            
            return queueVC
        }
        
        return nil
    }
    
    @objc func showOptions(_ sender: Any) {
        
        guard let item = activeItem else { return }
        
        if let gr = sender as? UILongPressGestureRecognizer {
            
            guard gr.state == .began else { return }
        }
        
        Transitioner.shared.showInfo(from: self, with: .song(location: .queue(loaded: false, index: item == musicPlayer.nowPlayingItem ? Queue.shared.indexToUse : 0), at: 0, within: [item]))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let id = segue.identifier else { return }
        
        switch id {
            
            case "toOptions":
            
                if let presentedVC = segue.destination as? PresentedContainerViewController {
                    
                    presentedVC.context = .info
                    presentedVC.optionsContext = .song(location: .queue(loaded: false, index: Queue.shared.indexToUse), at: 0, within: [activeItem].compactMap({ $0 }))
                }
            
            case "toArtistOptions":
            
                if let query = artistQuery, let artist = query.collections?.first, let presentedVC = segue.destination as? PresentedContainerViewController {
                    
                    presentedVC.context = .info
                    presentedVC.optionsContext = .collection(kind: .artist, at: 0, within: [artist])
                }
            
            case "toAlbumOptions":
            
                if let query = albumQuery, let album = query.collections?.first, let presentedVC = segue.destination as? PresentedContainerViewController {
                    
                    presentedVC.context = .info
                    presentedVC.optionsContext = .album(at: 0, within: [album])
                }
            
            case "toQueue": performTransition(to: segue.destination, sender: nil)
            
            case "toLibraryOptions":
                
                let options = LibraryOptions.init(fromVC: self, configuration: .nowPlaying, context: .song(location: .queue(loaded: false, index: Queue.shared.indexToUse), at: 0, within: [activeItem].compactMap({ $0 })))
                
                Transitioner.shared.transition(to: segue.destination, using: options, sourceView: actionsButton)
            
            case "toArtistUnwind", "toAlbumUnwind": useAlternateAnimation = true
            
            case "embed":
            
                guard let lyricsVC = segue.destination as? LyricsViewController else { return }
            
                lyricsVC.textAlignment = lyricsTextAlignment
            
            default: break
        }
    }
    
//    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
//
//        switch identifier {
//
//            case "toQueue": return musicPlayer.nowPlayingItem != nil
//
//            default: return true
//        }
//    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) { }
    
    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        
        if action == #selector(unwind(_:)) {
            
            return !shouldReturnToContainer
        }
        
        return false
    }
        
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "NVC going away...").show(for: 0.3)
        }

        if let _ = peeker, let imageView = container?.imageView {
            
            ArtworkManager.shared.currentlyPeeking = nil
            
            UIView.transition(with: imageView, duration: 0.5, options: .transitionCrossDissolve, animations: { imageView.image = ArtworkManager.shared.activeContainer?.modifier?.artworkType.image/*self.oldArtwork*/ }, completion: nil)
        }
        
        notifier.removeObserver(self)
        
        unregisterAll(from: lifetimeObservers)
    }
}

// MARK: - 3D Touch
extension NowPlayingViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        if queueButton.bounds.contains(nowPlayingView.convert(location, to: queueButton)), let _ = musicPlayer.nowPlayingItem {
            
            if let queueVC = presentedChilrenStoryboard.instantiateViewController(withIdentifier: "queueTVC") as? QueueViewController, let vc = performTransition(to: queueVC, sender: nil) {
                
                previewingContext.sourceRect = queueButton.convert(queueButton.bounds, to: nowPlayingView)
                
                return vc
            }
        
        } else if self.albumButton.bounds.contains(nowPlayingView.convert(location, to: self.albumButton)), let album = albumQuery?.collections?.first {
            
            let albumVC = entityStoryboard.instantiateViewController(withIdentifier: "entityItems")
            
            previewingContext.sourceRect = self.albumButton.convert(self.albumButton.bounds, to: nowPlayingView)
            
            return Transitioner.shared.transition(to: .album, vc: albumVC, from: self, sender: album, highlightedItem: currentItem, preview: true, titleOverride: (container?.activeViewController?.topViewController as? Navigatable)?.preferredTitle)
        
        } else if self.artistButton.bounds.contains(nowPlayingView.convert(location, to: self.artistButton)), let artist = artistQuery?.collections?.first {
            
            let entityVC = entityStoryboard.instantiateViewController(withIdentifier: "entityItems")
            
            previewingContext.sourceRect = self.artistButton.convert(self.artistButton.bounds, to: nowPlayingView)
            
            return Transitioner.shared.transition(to: .artist, vc: entityVC, from: self, sender: artist, highlightedItem: currentItem, preview: true, titleOverride: (container?.activeViewController?.topViewController as? Navigatable)?.preferredTitle)
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        performCommitActions(on: viewControllerToCommit)
        
        pop(to: viewControllerToCommit, queue: viewControllerToCommit is QueueViewController)
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        
        guard musicPlayer.nowPlayingItem != nil else { return [] }
        
        let show = UIPreviewAction.init(title: "Show...", style: .default, handler: { [weak self] _, VC in
            
            guard let weakSelf = self, let container = weakSelf.peeker as? ContainerViewController else { return }
            
            container.goTo(container)
        })
        
        let stop = UIPreviewAction.init(title: "Stop Playback", style: .destructive, handler: { [weak self] _, _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.peeker?.guardQueue(with: [.stop], onCondition: warnForQueueInterruption && stopGuard, fallBack: NowPlaying.shared.stopPlayback)
        })
        
        let shuffle = UIPreviewAction.init(title: musicPlayer.shuffleMode == .off ? .shuffle() : "Unshuffle", style: .default, handler: { _, _ in
            
            switch musicPlayer.shuffleMode {
                
                case .off: musicPlayer.shuffleMode = .songs
                
                default: musicPlayer.shuffleMode = .off
            }
        })
        
        let repeatArray: [UIPreviewAction] = {
            
            let off = UIPreviewAction.init(title: "Off", style: .default, handler: { _, _ in musicPlayer.repeatMode = .none; prefs.set(musicPlayer.repeatMode.rawValue, forKey: .repeatMode) })
            
            let one = UIPreviewAction.init(title: "One", style: .default, handler: { _, _ in musicPlayer.repeatMode = .one; prefs.set(musicPlayer.repeatMode.rawValue, forKey: .repeatMode) })
            
            let all = UIPreviewAction.init(title: "All", style: .default, handler: { _, _ in musicPlayer.repeatMode = .all; prefs.set(musicPlayer.repeatMode.rawValue, forKey: .repeatMode) })
            
            return [off, one, all]
        }()
        
        let repeats = UIPreviewActionGroup.init(title: "Repeat...", style: .default, actions: repeatArray)
        
        let first: [UIPreviewActionItem] = [show]
        let second: [UIPreviewActionItem] = Queue.shared.queueCount > 1 ? [shuffle, repeats] : [repeats]
        let third: [UIPreviewActionItem] = [stop]
    
        return first + second + third
    }
}

extension NowPlayingViewController: Detailing {
    
    func goToDetails(basedOn entity: EntityType) -> (entities: [EntityType], albumArtOverride: Bool) {
        
        switch entity {
            
            case .artist: return ([.artist], false)
            
            case .album: return ([.genre, .album, .albumArtist], false)
            
            default: return ([EntityType.artist, .genre, .album, .composer, .albumArtist], true)
        }
    }
}

extension NowPlayingViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer.view == nextButton, let tapGR = gestureRecognizer as? UITapGestureRecognizer, tapGR.numberOfTapsRequired == 2 {
            
            return musicPlayer.nowPlayingItem != nil && allowPlayIncrementingSkip
        }
        
        return true
    }
}
