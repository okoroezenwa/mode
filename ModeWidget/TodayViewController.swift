//
//  TodayViewController.swift
//  ModeWidget
//
//  Created by Ezenwa Okoro on 26/05/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet var label: MarqueeLabel?
    @IBOutlet var altLabel: UILabel?
    @IBOutlet var artworkContainer: UIView!
    @IBOutlet var likedStateButton: UIButton?
    @IBOutlet var shuffleButton: UIButton!
    @IBOutlet var repeatButton: UIButton!
    @IBOutlet var likedBorderView: UIView!
    @IBOutlet var shuffleBorderView: UIView!
    @IBOutlet var repeatBorderView: UIView!
    @IBOutlet var infoBorderView: UIView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var stackViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var expandedStackView: UIStackView!
    @IBOutlet var titlesStackView: UIStackView!
    @IBOutlet var nothingPlayingLabel: UILabel!
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet var buttonsStackView: UIStackView!
    @IBOutlet var ratingStackView: UIStackView?
    @IBOutlet var playButton: UIButton!
    @IBOutlet var collectionView: UICollectionView?
    @IBOutlet var timeLabel: UILabel?
    @IBOutlet var elapsedTimeLabel: UILabel?
    @IBOutlet var nextLabel: UILabel!
    @IBOutlet var previousButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var ratingBorderView: UIView!
    
    enum QueueLocation { case upNext, previous }
    
    lazy var artwork = InvertIgnoringImageView.init(frame: .zero)
    lazy var artworkConstraints = [
    
        artwork.topAnchor.constraint(equalTo: artworkContainer.topAnchor),
        artwork.leadingAnchor.constraint(equalTo: artworkContainer.leadingAnchor),
        artwork.trailingAnchor.constraint(equalTo: artworkContainer.trailingAnchor),
        artwork.bottomAnchor.constraint(equalTo: artworkContainer.bottomAnchor)
    ]
    
    let queueLimit = 1001
    @objc var loaded = false
    @objc var showingPlayControls = false
//    @objc var timer: Timer?
    @objc var playTimer: Timer?
    lazy var formatter = Formatter.shared
    lazy var itemWidth: CGFloat = { getItemWidth(from: self.view) }()
    lazy var itemSize: CGSize = { getItemSize(from: self.view) }()
    var maxHeight: CGFloat?
    var queueLocation = QueueLocation.upNext {
        
        didSet {
            
            updateQueueLabel()
            updateLocationButtons()
            
            collectionView?.reloadData()
            
            updatePreferredSize()
        }
    }
    
    var displayMode: Any? {
        
        if #available(iOS 10, *) {
            
            return extensionContext?.widgetActiveDisplayMode
        }
        
        return nil
    }
    
    var colour: UIColor {
        
        if #available(iOS 13, *) {
            
            return self.traitCollection.userInterfaceStyle == .dark ? .white : .black
        
        } else if #available(iOS 10, *) {

            return .black

        } else {

            return .white
        }
    }
    
    var alphaColour: UIColor {
        
        if #available(iOS 13, *) {
            
            return (self.traitCollection.userInterfaceStyle == .dark ? UIColor.white : .black).withAlphaComponent(sharedUseLighterBorders ? 0.05 : 0.08)
        
        } else if #available(iOS 10, *) {

            return UIColor.black.withAlphaComponent(sharedUseLighterBorders ? 0.05 : 0.08)

        } else {

            return UIColor.white.withAlphaComponent(sharedUseLighterBorders ? 0.05 : 0.08)
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let hasContent: Bool = {
            
            if #available(iOS 10, *) {
                
                return sharedUseSystemPlayer
            }
            
            return false
        }()
        
        if #available(iOS 10, *), let height = extensionContext?.widgetMaximumSize(for: .compact).height {
            
            maxHeight = height
            stackViewHeightConstraint.constant = height
        }
        
        artwork.clipsToBounds = true
        artworkContainer?.addSubview(artwork)
        NSLayoutConstraint.activate(artworkConstraints)
        
        NCWidgetController().setHasContent(hasContent, forWidgetWithBundleIdentifier: Bundle.main.bundleIdentifier ?? (ModeBuild.release.rawValue + ".Widget"))
        
        updateMaxSizes()
        updateNowPlayingLabel()
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(open(_:)))
        tap.delegate = self
        view.addGestureRecognizer(tap)
        
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        updateViewVisibility()
        
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: /*musicPlayer*/nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: /*musicPlayer*/nil)
        
        prepareViewColours()
        
        prepareRepeatView()
        prepareShuffleView()
        updateLocationButtons()
        updateCornersAndShadows()
        
        update(self)
        
        let queueTap = UITapGestureRecognizer.init(target: self, action: #selector(openQueue))
        stackView.addGestureRecognizer(queueTap)
        
        let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(open(_:)))
        gr.minimumPressDuration = 0.3
        playButton.addGestureRecognizer(gr)
    }
    
    func updateViewVisibility() {
        
        if let _ = musicPlayer.nowPlayingItem {
            
            nothingPlayingLabel.isHidden = true
            stackView.isHidden = false
            expandedStackView.isHidden = false
            
        } else {
            
            stackView.isHidden = true
            expandedStackView.isHidden = true
            nothingPlayingLabel.isHidden = false
        }
    }
    
    func prepareViewColours() {
        
        [label, elapsedTimeLabel].forEach({ $0?.textColor = colour })
        ([likedStateButton, shuffleButton, repeatButton] + buttons as [UIButton?]).forEach({ $0?.tintColor = colour })
        [shuffleBorderView, likedBorderView, repeatBorderView, infoBorderView, ratingBorderView].forEach({ $0?.backgroundColor = alphaColour })
        [altLabel, timeLabel, nextLabel].forEach({ $0?.textColor = colour.withAlphaComponent(0.6) })
    }
    
    func updateNowPlayingLabel() {
        
        nothingPlayingLabel.textColor = colour
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        if #available(iOS 13, *), previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            
            updateColours()
        }
    }
    
    func updateColours() {
        
        prepareViewColours()
        updateLocationButtons()
        updateQueueLabel()
        updateNowPlayingLabel()
    }
    
    func updateMaxSizes() {
        
        guard #available(iOSApplicationExtension 10, *) else { return }
        
        extensionContext?.widgetLargestAvailableDisplayMode = musicPlayer.nowPlayingItem != nil ? .expanded : .compact
    }
    
    func updatePreferredSize(activeDisplayMode: Any? = nil) {
        
        let mainHeight = maxHeight ?? 110
        
        guard let collectionView = collectionView else {
            
            preferredContentSize = .init(width: view.frame.width, height: mainHeight)
            return
        }
        
        let sectionIsPopulated = (queueLocation == .upNext ? musicPlayer.queueCount() != musicPlayer.nowPlayingItemIndex + 1 : musicPlayer.nowPlayingItemIndex != 0) && musicPlayer.nowPlayingItemIndex != -1
        
        let collectionViewHeight: CGFloat = {
            
            guard sectionIsPopulated else { return 0 }
            
            return (itemSize.height * (collectionView.numberOfItems(inSection: 0) > 5 ? 2 : 1))
        }()
        
        let bottomInset: CGFloat = sectionIsPopulated ? 0 : 2
        let sectionTitleHeight: CGFloat = 38
        
        guard #available(iOSApplicationExtension 10, *), let activeDisplayMode = (activeDisplayMode ?? displayMode) as? NCWidgetDisplayMode else {
            
            preferredContentSize = .init(width: view.frame.width, height: mainHeight + sectionTitleHeight + bottomInset + collectionViewHeight + 0.001)
            
            return
        }
        
        preferredContentSize = .init(width: UIScreen.main.bounds.width, height: activeDisplayMode == .compact ? mainHeight : mainHeight + sectionTitleHeight + bottomInset + collectionViewHeight + 0.001)
    }
    
    @objc func open(_ sender: UIGestureRecognizer) {
        
        if sender is UITapGestureRecognizer, let url = URL.init(string: .modeURL) {
            
            extensionContext?.open(url, completionHandler: nil)
        
        } else if let sender = sender as? UILongPressGestureRecognizer, sender.state == .began, let url = URL.init(string: .modeURL + String.URLAction.nowPlaying.rawValue) {
            
            extensionContext?.open(url, completionHandler: nil)
        }
    }
    
    @objc func updateCornersAndShadows(updateShadow: Bool = true) {
        
        let cornerRadius = CornerRadius(rawValue: sharedCornerRadius) ?? .large
        
        (CornerRadius(rawValue: sharedWidgetCornerRadius) ?? cornerRadius).updateCornerRadius(on: artwork.layer, using: artwork.bounds.width, globalRadiusType: cornerRadius)
        
        guard updateShadow else { return }
        
        artworkContainer?.addShadow(radius: 8, opacity: 0.25, shouldRasterise: true) // opacity was 0 for some reason on 17/11/2019
    }
    
    @IBAction func openInfo() {
        
        if let url = URL.init(string: .modeURL + String.URLAction.nowPlayingInfo.rawValue) {
            
            extensionContext?.open(url, completionHandler: nil)
        }
    }
    
    @IBAction func openQueue() {
        
        if let url = URL.init(string: .modeURL + String.URLAction.queue.rawValue) {
            
            extensionContext?.open(url, completionHandler: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        performRequiredUpdates()
        
        if sharedDefaults.bool(forKey: .quitWidget) {
            
            sharedDefaults.set(false, forKey: .quitWidget)
            fatalError()
        }
        
//        collectionView?.reloadData()
    }
    
    @objc func updateLocationButtons() {
        
        let upNextAvailable = queueLocation == .upNext
        let musicPlayerAvailable = musicPlayer.nowPlayingItemIndex != -1
        
        nextButton.tintColor = !upNextAvailable && musicPlayerAvailable ? colour : colour.withAlphaComponent(0.2)
        nextButton.isUserInteractionEnabled = !upNextAvailable && musicPlayerAvailable
        
        previousButton.tintColor = upNextAvailable && musicPlayerAvailable ? colour : colour.withAlphaComponent(0.2)
        previousButton.isUserInteractionEnabled = upNextAvailable && musicPlayerAvailable
    }
    
    @objc func updateQueueLabel() {
        
        guard musicPlayer.nowPlayingItemIndex != -1 else {
            
            nextLabel.text = "queue unavailable"
            
            return
        }
        
        let count = queueLocation == .upNext ? musicPlayer.queueCount() - (musicPlayer.nowPlayingItemIndex + 1) : musicPlayer.nowPlayingItemIndex
        let text = (queueLocation == .upNext ? "Up Next (" : "Previous (") + count.formatted + ")"
        let attributed = NSMutableAttributedString.init(string: text)
        attributed.addAttribute(.foregroundColor, value: colour, range: text.nsRange(of: count.formatted))
        
        nextLabel.attributedText = attributed
    }
    
    func updateCountLabel() {
        
        altLabel?.text = {
            
            let index = (musicPlayer.nowPlayingItemIndex + 1).formatted
            let count = musicPlayer.queueCount().formatted
            
            return [index, count].joined(separator: " / ")
        }()
    }
    
    @objc func update(_ sender: Any) {
        
        if let song = musicPlayer.nowPlayingItem {
            
            label?.text = {
                
                let title = song.title ??? .untitledSong
                let artist = song.artist ??? .unknownArtist
                let album = song.albumTitle ??? .untitledAlbum
                
                return [title, artist, album].joined(separator: "  •  ")
            }()
            
            updateCountLabel()
            
            artwork.image = {
                
                guard let artwork = musicPlayer.nowPlayingItem?.artwork, artwork.bounds.size.width != 0 else { return #imageLiteral(resourceName: "NoSong75") }
                
                return artwork.image(at: self.artwork.bounds.size)
            }()
            
            prepareLikedView()
            prepareRatingView()
            
            timeLabel?.text = "/ " + song.playbackDuration.nowPlayingRepresentation
            
            if musicPlayer.isPlaying {
                
                playTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateElapsedTime), userInfo: nil, repeats: true)
                
            } else {
                
                playTimer?.invalidate()
                playTimer = nil
                updateElapsedTime()
            }
            
            updateQueueLabel()
            updateCornersAndShadows()
            
            if let notification = sender as? Notification, let label = label {
                
                UIView.transition(with: label, duration: 0.3, options: .transitionCrossDissolve, animations: { label.font = UIFont.init(name: musicPlayer.isPlaying ? "MyriadPro-It" : "MyriadPro-Regular", size: 18) }, completion: nil)
                artworkContainer?.animateShadowOpacity(to: musicPlayer.isPlaying ? 0.25 : 0, duration: 0.65)
                
                UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [.curveEaseInOut], animations: { self.artworkContainer?.transform = musicPlayer.isPlaying ? .identity : .init(scaleX: 35/45, y: 35/45) }, completion: nil)
                
                if notification.name == .MPMusicPlayerControllerNowPlayingItemDidChange {
                    
                    collectionView?.reloadData()
                }
                
                updatePreferredSize()
            
            } else {
                
                label?.font = UIFont.init(name: musicPlayer.isPlaying ? "MyriadPro-It" : "MyriadPro-Regular", size: 18)
                artworkContainer?.transform = musicPlayer.isPlaying ? .identity : .init(scaleX: 35/45, y: 35/45)
                artworkContainer?.layer.shadowOpacity = musicPlayer.isPlaying ? 0.25 : 0
                
                if sender is TodayViewController {
                    
                    collectionView?.reloadData()
                }
            }
            
        } else {
            
            performRequiredUpdates()
        }
    }
    
    func performRequiredUpdates() {
        
        updateMaxSizes()
        updateViewVisibility()
        updatePreferredSize()
        updateColours()
    }
    
    @objc func updateElapsedTime() {
        
        elapsedTimeLabel?.text = musicPlayer.currentPlaybackTime.nowPlayingRepresentation
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        
        update(self)
        
        if musicPlayer.nowPlayingItem != nil {
            
            performRequiredUpdates()
        }
        
        completionHandler(NCUpdateResult.newData)
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        
        UIView.animate(withDuration: 0.2, animations: { [self.expandedStackView].forEach({ $0.alpha = activeDisplayMode == .compact ? 0 : 1 }) })
        
        updatePreferredSize(activeDisplayMode: activeDisplayMode)
    }
    
    @objc func prepareShuffleView() {
        
        shuffleBorderView.isHidden = [MPMusicShuffleMode.default, .off].contains(musicPlayer.shuffleMode)
    }
    
    @objc func prepareRepeatView() {
        
        repeatBorderView.isHidden = [MPMusicRepeatMode.none, .default].contains(musicPlayer.repeatMode)
        repeatButton.setImage(musicPlayer.repeatMode == .one ? #imageLiteral(resourceName: "RepeatOne15") : #imageLiteral(resourceName: "Repeat15"), for: .normal)
    }
    
    @objc func prepareLikedView() {
        
        guard let item = musicPlayer.nowPlayingItem else { return }
        
        var image: UIImage {
            
            switch item.likedState {
                
                case .none: return #imageLiteral(resourceName: "NoLove14")
                
                case .liked: return #imageLiteral(resourceName: "Loved14")
                
                case .disliked: return #imageLiteral(resourceName: "Unloved14")
            }
        }
        
        likedStateButton?.setImage(image, for: .normal)
    }
    
    @objc func prepareRatingView() {
        
        guard let song = musicPlayer.nowPlayingItem, let subviews = ratingStackView?.arrangedSubviews as? [UIButton] else { return }
        
        subviews.forEach { $0.setImage(song.rating >= $0.tag ? #imageLiteral(resourceName: "StarFilled15") : #imageLiteral(resourceName: "Dot"), for: .normal) }
    }
    
    @IBAction func rate(_ sender: UIButton) {
        
        guard let song = musicPlayer.nowPlayingItem, let ratingStackView = ratingStackView else { return }
        
        song.set(property: MPMediaItemPropertyRating, to: NSNumber.init(value: sender.tag))
        
        UIView.transition(with: ratingStackView, duration: 0.3, options: .transitionCrossDissolve, animations: { self.prepareRatingView() }, completion: nil)
    }
    
    @IBAction func setLiked(_ sender: Any) {
        
        guard let item = musicPlayer.nowPlayingItem, let likedStateButton = likedStateButton else { return }
        
        var value: Int {
            
            switch item.likedState {
                
                case .none: return LikedState.liked.rawValue
                    
                case .liked: return LikedState.disliked.rawValue
                    
                case .disliked: return LikedState.none.rawValue
            }
        }
        
        item.set(property: .likedState, to: NSNumber.init(value: value))
        
        UIView.transition(with: likedStateButton, duration: 0.3, options: .transitionCrossDissolve, animations: { self.prepareLikedView() }, completion: nil)
    }
    
    @IBAction func shuffle(_ sender: Any) {
        
        musicPlayer.shuffleMode = {
            
            switch musicPlayer.shuffleMode {
                
                case .albums, .songs: return .off
                
                case .default, .off: return .songs
                
                @unknown default: return .off
            }
        }()
        
        prepareShuffleView()
        
        updateCountLabel()
        updateQueueLabel()
        updatePreferredSize()
        collectionView?.reloadData()
    }
    
    @IBAction func setRepeat(_ sender: Any) {
        
        musicPlayer.repeatMode = {
            
            switch musicPlayer.repeatMode {
                
                case .none, .default: return .all
                    
                case .one: return .none
                    
                case .all: return .one
            
                @unknown default: return .none
            }
        }()
        
        prepareRepeatView()
    }
    
    @IBAction func playPause() {
        
        musicPlayer.isPlaying ? musicPlayer.pause() : musicPlayer.play()
    }
    
    @IBAction func nextLocation() {
        
        queueLocation = .upNext
    }
    
    @IBAction func previousLocation() {
        
        queueLocation = .previous
    }
    
    deinit {
        
        musicPlayer.endGeneratingPlaybackNotifications()
    }
}

extension TodayViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard musicPlayer.nowPlayingItemIndex != -1 else { return 0 }
        
        let count = queueLocation == .upNext ? musicPlayer.queueCount() - (musicPlayer.nowPlayingItemIndex + 1) : musicPlayer.nowPlayingItemIndex
        
        return min(10, count)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! WidgetCollectionViewCell
        
        let index = queueLocation == .upNext ? musicPlayer.nowPlayingItemIndex + indexPath.row + 1 : musicPlayer.nowPlayingItemIndex + indexPath.row - min(10, musicPlayer.nowPlayingItemIndex)// - (indexPath.row + 1)
        
        cell.prepare(with: musicPlayer.item(at: index), index: indexPath.item % 5)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard musicPlayer.indexOfNowPlayingItem != -1 else { return }
        
        let index = queueLocation == .upNext ? musicPlayer.nowPlayingItemIndex + indexPath.row + 1 : musicPlayer.nowPlayingItemIndex + indexPath.row - min(10, musicPlayer.nowPlayingItemIndex)//- (indexPath.row + 1)
        
        musicPlayer.nowPlayingItem = musicPlayer.item(at: index)
        updateQueueLabel()
        updatePreferredSize()
    }
}

extension TodayViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        itemSize
    }
}

extension TodayViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer is UITapGestureRecognizer, musicPlayer.nowPlayingItem != nil {
            
            return false
        }
        
        return true
    }
}
