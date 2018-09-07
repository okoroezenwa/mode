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
        
    @IBOutlet weak var label: MarqueeLabel?
    @IBOutlet weak var altLabel: UILabel?
    @IBOutlet weak var artwork: UIImageView?
    @IBOutlet weak var artworkContainer: UIView?
    @IBOutlet weak var likedStateButton: UIButton?
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var likedBorderView: UIView!
    @IBOutlet weak var shuffleBorderView: UIView!
    @IBOutlet weak var repeatBorderView: UIView!
    @IBOutlet weak var infoBorderView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var expandedStackView: UIStackView!
    @IBOutlet weak var titlesStackView: UIStackView!
    @IBOutlet weak var nothingPlayingLabel: UILabel!
    @IBOutlet var artworkConstraints: [NSLayoutConstraint]!
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var ratingStackView: UIStackView?
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView?
    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var elapsedTimeLabel: UILabel?
    @IBOutlet weak var nextLabel: UILabel!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    enum QueueLocation { case upNext, previous }
    
    @objc var loaded = false
    @objc var showingPlayControls = false
//    @objc var timer: Timer?
    @objc var playTimer: Timer?
    lazy var formatter = Formatter.shared
    lazy var itemWidth: CGFloat = { getItemWidth(from: self.view) }()
    lazy var itemSize: CGSize = { getItemSize(from: self.view) }()
    var queueLocation = QueueLocation.upNext {
        
        didSet {
            
            updateQueueLabel()
            updateLocationButtons()
            
            collectionView?.reloadData()
            
            perform(#selector(animateCells), with: nil, afterDelay: 0.01)
            
            updatePreferredSize()
        }
    }
    
    var displayMode: Any? {
        
        if #available(iOS 10, *) {
            
            return extensionContext?.widgetActiveDisplayMode
        }
        
        return nil
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        updateMaxSizes()
        nothingPlayingLabel.textColor = colour
        
        guard musicPlayer.nowPlayingItem != nil else {
            
            let tap = UITapGestureRecognizer.init(target: self, action: #selector(open(_:)))
            view.addGestureRecognizer(tap)
            
            stackView.isHidden = true
            expandedStackView.isHidden = true
            return
        }
        
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        nothingPlayingLabel.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer)
        
        [label, elapsedTimeLabel].forEach({ $0?.textColor = colour })
        ([likedStateButton, shuffleButton, repeatButton] + buttons as [UIButton?]).forEach({ $0?.tintColor = colour })
        [shuffleBorderView, likedBorderView, repeatBorderView, infoBorderView].forEach({ $0?.backgroundColor = alphaColour })
        [altLabel, timeLabel, nextLabel].forEach({ $0?.textColor = colour.withAlphaComponent(0.6) })
        
        prepareRepeatView()
        prepareShuffleView()
        updateLocationButtons()
        
        updateCornersAndShadows()
        
        update(self)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(openQueue))
        stackView.addGestureRecognizer(tap)
        
        let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(open(_:)))
        gr.minimumPressDuration = 0.3
        playButton.addGestureRecognizer(gr)
    }
    
    func updateMaxSizes() {
        
        guard #available(iOSApplicationExtension 10, *) else { return }
        
        extensionContext?.widgetLargestAvailableDisplayMode = musicPlayer.nowPlayingItem != nil ? .expanded : .compact
    }
    
    func updatePreferredSize(activeDisplayMode: Any? = nil) {
        
        guard let collectionView = collectionView else {
            
            preferredContentSize = .init(width: view.frame.width, height: 110)
            return
        }
        
        guard #available(iOSApplicationExtension 10, *), let activeDisplayMode = (activeDisplayMode ?? displayMode) as? NCWidgetDisplayMode else {
            
            let test = (queueLocation == .upNext ? musicPlayer.queueCount() != musicPlayer.nowPlayingItemIndex + 1 : musicPlayer.nowPlayingItemIndex != 0) && musicPlayer.nowPlayingItemIndex != -1
            
            let collectionViewHeight: CGFloat = {
                
                guard test else { return 0 }
                
                return ((itemWidth + (20 - (40/3))) * (collectionView.numberOfItems(inSection: 0) > 5 ? 2 : 1))
            }()
            
            preferredContentSize = .init(width: view.frame.width, height: 110 + 30 + (test ? 0 : 10) + collectionViewHeight + 0.001)
            
            return
        }
        
        let test = (queueLocation == .upNext ? musicPlayer.queueCount() != musicPlayer.nowPlayingItemIndex + 1 : musicPlayer.nowPlayingItemIndex != 0) && musicPlayer.nowPlayingItemIndex != -1
        
        let collectionViewHeight: CGFloat = {
            
            guard test else { return 0 }
            
            return ((itemWidth + (20 - (40/3))) * (collectionView.numberOfItems(inSection: 0) > 5 ? 2 : 1))
        }()
        
        preferredContentSize = .init(width: UIScreen.main.bounds.width, height: activeDisplayMode == .compact ? 110 : 110 + 30 + (test ? 0 : 10) + collectionViewHeight + 0.001)
    }
    
    @objc func open(_ sender: UIGestureRecognizer) {
        
        if sender is UITapGestureRecognizer, let url = URL.init(string: .modeURL) {
            
            extensionContext?.open(url, completionHandler: nil)
        
        } else if let sender = sender as? UILongPressGestureRecognizer, sender.state == .began, let url = URL.init(string: .modeURL + String.URLAction.nowPlaying.rawValue) {
            
            extensionContext?.open(url, completionHandler: nil)
        }
    }
    
    @objc func updateCornersAndShadows(updateShadow: Bool = true) {
        
        guard let artwork = artwork else { return }
        
        let cornerRadius = CornerRadius(rawValue: sharedCornerRadius) ?? .large
        
        (CornerRadius(rawValue: sharedWidgetCornerRadius) ?? cornerRadius).updateCornerRadius(on: artwork.layer, using: artwork.bounds.width, globalRadiusType: cornerRadius)
        
        guard updateShadow else { return }
        
        artworkContainer?.addShadow(radius: 8, opacity: 0, shouldRasterise: true)
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
        
        updateMaxSizes()
        updatePreferredSize()
        
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
        let text = (queueLocation == .upNext ? "up next (" : "previous (") + count.formatted + ")"
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
        
        label?.text = {
            
            let title = musicPlayer.nowPlayingItem?.title ??? .untitledSong
            let artist = musicPlayer.nowPlayingItem?.artist ??? .unknownArtist
            let album = musicPlayer.nowPlayingItem?.albumTitle ??? .untitledAlbum
            
            return [title, artist, album].joined(separator: "  •  ")
        }()
        
        updateCountLabel()
        
        artwork?.image = {
            
            guard let imageView = self.artwork, let artwork = musicPlayer.nowPlayingItem?.artwork, artwork.bounds.size.width != 0 else { return #imageLiteral(resourceName: "NoSong75") }
            
            return artwork.image(at: imageView.bounds.size)
        }()
        
        prepareLikedView()
        prepareRatingView()
        
        timeLabel?.text = "/ " + (musicPlayer.nowPlayingItem?.playbackDuration.nowPlayingRepresentation ?? "--:--")
        
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
                perform(#selector(animateCells), with: nil, afterDelay: 0.01)
            }
            
            updatePreferredSize()
        
        } else {
            
            label?.font = UIFont.init(name: musicPlayer.isPlaying ? "MyriadPro-It" : "MyriadPro-Regular", size: 18)
            artworkContainer?.transform = musicPlayer.isPlaying ? .identity : .init(scaleX: 35/45, y: 35/45)
            artworkContainer?.layer.shadowOpacity = musicPlayer.isPlaying ? 0.25 : 0
            
            if sender is TodayViewController {
                
                collectionView?.reloadData()
                perform(#selector(animateCells), with: nil, afterDelay: 0.01)
            }
        }
    }
    
    @objc func updateElapsedTime() {
        
        elapsedTimeLabel?.text = musicPlayer.currentPlaybackTime.nowPlayingRepresentation
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        
        update(self)
        
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
        repeatButton.setImage(musicPlayer.repeatMode == .one ? #imageLiteral(resourceName: "RepeatOne") : #imageLiteral(resourceName: "Repeat"), for: .normal)
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
        
        for button in subviews {
            
            if button.tag == 0 {
                
                button.isHidden = song.rating < 1
                
            } else {
                
                button.setImage(song.rating >= button.tag ? #imageLiteral(resourceName: "StarFilled15") : #imageLiteral(resourceName: "Dot"), for: .normal)
            }
        }
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
            }
        }()
        
        prepareShuffleView()
        
        updateCountLabel()
        updateQueueLabel()
        updatePreferredSize()
        collectionView?.reloadData()
        perform(#selector(animateCells), with: nil, afterDelay: 0.01)
//        UIView.transition(with: collectionView, duration: 0.3, options: .transitionCrossDissolve, animations: { self.collectionView.reloadData() }, completion: nil)
    }
    
    @IBAction func setRepeat(_ sender: Any) {
        
        musicPlayer.repeatMode = {
            
            switch musicPlayer.repeatMode {
                
                case .none, .default: return .all
                    
                case .one: return .none
                    
                case .all: return .one
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
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard musicPlayer.nowPlayingItemIndex != -1 else { return 0 }
        
        let count = queueLocation == .upNext ? musicPlayer.queueCount() - (musicPlayer.nowPlayingItemIndex + 1) : musicPlayer.nowPlayingItemIndex
        
        return min(5, count)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! WidgetCollectionViewCell
        
        let position: Position = {
            
            switch indexPath.row {
                
                case let x where x % 5 == 0: return .leading
                
                case let x where x % 5 == 4: return .trailing
                
                default: return .middle
            }
        }()
        
        let index = queueLocation == .upNext ? musicPlayer.nowPlayingItemIndex + indexPath.row + 1 : musicPlayer.nowPlayingItemIndex - indexPath.row - 1
        
        cell.prepare(with: musicPlayer.item(at: index), position: position)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard musicPlayer.indexOfNowPlayingItem != -1 else { return }
        
        let index = queueLocation == .upNext ? musicPlayer.nowPlayingItemIndex + indexPath.row + 1 : musicPlayer.nowPlayingItemIndex - indexPath.row - 1
        
        musicPlayer.nowPlayingItem = musicPlayer.item(at: index)
        updateQueueLabel()
        updatePreferredSize()
    }
    
    @objc func animateCells() {
            
        guard let cells = collectionView?.visibleCells else { return }
        
        for cell in cells {
            
            cell.alpha = 0
            cell.transform = .init(translationX: 40, y: 0)
        }
        
        for cell in cells.enumerated() {
            
            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 20, options: [.curveLinear, .allowUserInteraction], animations: {
                
                cell.element.alpha = 1
                cell.element.transform = .identity
                
            }, completion: nil)
        }
    }
}

extension TodayViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return itemSize
    }
}
