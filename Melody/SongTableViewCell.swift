//
//  AltSongTableViewCell.swift
//  Melody
//
//  Created by Ezenwa Okoro on 24/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SongTableViewCell: SwipeTableViewCell, ArtworkContainingCell, TimerBased {
    
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var nameLabel: MELLabel!
    @IBOutlet weak var artistAlbumLabel: MELLabel!
    @IBOutlet weak var supplemetaryScrollView: UIScrollView!
    @IBOutlet weak var supplementaryStackView: UIStackView! {
        
        didSet {
            
            prepareSupplementaryView()
        }
    }
    @IBOutlet weak var cloudButton: UIImageView!
    @IBOutlet weak var durationLabel: MELLabel!
    @IBOutlet weak var playButton: MELButton!
    @IBOutlet weak var trackNumberLabel: MELLabel!
    @IBOutlet weak var explicitView: UIView!
    @IBOutlet weak var artworkContainer: UIView!
    @IBOutlet weak var playingView: UIView!
    @IBOutlet weak var startTime: MELLabel!
    @IBOutlet weak var stopTime: MELLabel!
    @IBOutlet weak var timeSlider: MELSlider!
    @IBOutlet weak var playPauseBorder: UIView!
    @IBOutlet weak var optionsView: UIView!
    @IBOutlet weak var infoButton: MELButton!
    @IBOutlet weak var infoBorderView: MELBorderView!
    @IBOutlet var editingView: UIView!
    @IBOutlet var stackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var mainView: UIView!
    @IBOutlet var editBorderView: MELBorderView!
    @IBOutlet var mainViewInnerViewLeadingConstraint: NSLayoutConstraint!
    
    var playPauseButton: MELButton! {
        
        get { return playButton }
        
        set { }
    }
    
    @objc lazy var playsView = ScrollHeaderSubview.forCell(title: "-", image: #imageLiteral(resourceName: "Plays"))
    
    @objc lazy var ratingView = ScrollHeaderSubview.forCell(title: "-", image: #imageLiteral(resourceName: "Star"), imageSize: 13)
    
    @objc lazy var lastPlayedView: ScrollHeaderSubview = .forCell(title: "-", image: #imageLiteral(resourceName: "LastPlayed10"))
    
    @objc lazy var genreView: ScrollHeaderSubview = .forCell(title: "-", image: #imageLiteral(resourceName: "GenresSmaller"), useSmallerDistance: false)
    
    @objc lazy var dateAddedView: ScrollHeaderSubview = .forCell(title: "-", image: #imageLiteral(resourceName: "DateAdded"), imageSize: 13, useSmallerDistance: false)
    
    @objc lazy var likedStatusView: ScrollHeaderSubview = .forCell(title: nil, image: #imageLiteral(resourceName: "NoLove"), imageSize: 14)
    
    @objc lazy var sizeView: ScrollHeaderSubview = .forCell(title: "-", image: #imageLiteral(resourceName: "FileSize10"), imageSize: 13)
    
    @objc lazy var yearView: ScrollHeaderSubview = .forCell(title: "-", image: #imageLiteral(resourceName: "Year"), imageSize: 13, useSmallerDistance: false)
    
    @objc lazy var skipsView: ScrollHeaderSubview = .forCell(title: "-", image: #imageLiteral(resourceName: "Skips14"))
    
    @objc lazy var composerView = ScrollHeaderSubview.forCell(title: "-", image: #imageLiteral(resourceName: "ComposersSmall"))
    
    @objc lazy var albumArtistView = ScrollHeaderSubview.forCell(title: "-", image: #imageLiteral(resourceName: "GenresSmall"))
    
    weak var delegate: EntityCellDelegate?
    let playingImage = #imageLiteral(resourceName: "PauseFilled10")
    let pausedImage = #imageLiteral(resourceName: "PlayFilledSmall")
    let pausedInset: CGFloat = 3
    let playingInset: CGFloat = 2
    @objc var playPauseActive = false
    var width: CGFloat { return artworkContainer.frame.width }
    
    @objc lazy var indicator: ESTMusicIndicatorView = {
        
        let indicator = ESTMusicIndicatorView.init(frame: CGRect.zero)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.sizeToFit()
        self.playingView.addSubview(indicator)
        self.playingView.centre(indicator)
        
        return indicator
    }()
    
    var entity = Entity.song {
        
        didSet {
            
            guard entity != oldValue, let _ = artworkContainer, let _ = artworkImageView else { return }
            
            updateCornersAndShadows()
        }
    }
    
    enum DetailsVisibility { case primary, secondary, both }

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        selectedBackgroundView = MELBorderView()
        
        updateCornersAndShadows()
        UniversalMethods.addShadow(to: playPauseBorder, path: UIBezierPath.init(roundedRect: CGRect.init(x: 0, y: 0, width: 24, height: 24), cornerRadius: 12).cgPath)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapCell(_:)))
        supplemetaryScrollView.addGestureRecognizer(tap)
        
        notifier.addObserver(self, selector: #selector(modifyPlayOnly), name: .playOnlyChanged, object: nil)
        notifier.addObserver(self, selector: #selector(modifyBackground), name: .themeChanged, object: nil)
        notifier.addObserver(self, selector: #selector(modifyIndicator), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer)
        notifier.addObserver(self, selector: #selector(updateCornersAndShadows), name: .cornerRadiusChanged, object: nil)
        notifier.addObserver(self, selector: #selector(modifyInfoButton), name: .infoButtonVisibilityChanged, object: nil)
        
//        let leftSwipe = UISwipeGestureRecognizer.init(target: self, action: #selector(handleLeftSwipe(_:)))
//        leftSwipe.direction = .left
//        leftSwipe.delegate = self
//        supplemetaryScrollView.addGestureRecognizer(leftSwipe)
//        
//        let rightSwipe = UISwipeGestureRecognizer.init(target: self, action: #selector(handleRightSwipe(_:)))
//        rightSwipe.direction = .right
//        rightSwipe.delegate = self
//        supplemetaryScrollView.addGestureRecognizer(rightSwipe)
        
        preservesSuperviewLayoutMargins = false
        contentView.preservesSuperviewLayoutMargins = false
    }
    
    @objc func prepareSupplementaryView() {
        
        [SecondaryCategory.loved, .plays, .rating, .lastPlayed, .dateAdded, .genre, .year, .fileSize].forEach({ supplementaryStackView.addArrangedSubview(view(for: $0)) })
    }
    
    @objc func updateCornersAndShadows() {
        
        [artworkImageView, playingView].forEach({
            
            $0?.layer.cornerRadius = {
                
                switch cornerRadius {
                    
                    case .automatic: return (listsCornerRadius ?? cornerRadius).radius(for: entity, width: width)
                    
                    default: return cornerRadius.radius(for: entity, width: width)
                }
            }()
        })
        
        UniversalMethods.addShadow(to: artworkContainer, shouldRasterise: true)
    }
    
    func view(for category: SecondaryCategory) -> ScrollHeaderSubview {

        switch category {

            case .loved: return likedStatusView

            case .plays: return playsView

            case .rating: return ratingView

            case .lastPlayed: return lastPlayedView

            case .dateAdded: return dateAddedView

            case .genre: return genreView

            case .year: return yearView

            case .fileSize: return sizeView
        }
    }
    
    @objc func modifyPlayOnly() {
        
        playButton.isUserInteractionEnabled = (allowPlayOnly && delegate != nil) || playPauseActive
    }
    
    @objc func modifyBackground() {
        
        if backgroundColor != .clear {
            
            backgroundColor = Themer.textColour(for: .title).withAlphaComponent(0.05)
        }
    }
    
    @objc func modifyIndicator() {
        
        guard !playingView.isHidden, !playPauseActive else { return }
        
        indicator.state = musicPlayer.isPlaying ? .playing : .paused
    }
    
    @objc func modifyInfoButton() {
        
        optionsView.isHidden = !showInfoButtons
        infoButton.isHidden = !showInfoButtons
    }
    
//    @objc func handleLeftSwipe(_ gr: UISwipeGestureRecognizer) {
//
//        if (supplemetaryScrollView.contentSize.width < supplemetaryScrollView.frame.width) || (supplemetaryScrollView.contentSize.width > supplemetaryScrollView.frame.width && (supplemetaryScrollView.frame.width + supplemetaryScrollView.contentOffset.x == supplemetaryScrollView.contentSize.width)) {
//
//            scrollDelegate?.handleScrollSwipe(in: self, from: gr, direction: .left)
//        }
//    }
//
//    @objc func handleRightSwipe(_ gr: UISwipeGestureRecognizer) {
//
//        if supplemetaryScrollView.contentOffset.x == 0.0 {
//
//            scrollDelegate?.handleScrollSwipe(in: self, from: gr, direction: .right)
//        }
//    }
    
    @objc func tapCell(_ gr: UITapGestureRecognizer) {
        
        delegate?.scrollViewTapped(in: self)//scrollDelegate?.handleScrollTap(in: self)
    }

    func prepare(with song: MPMediaItem,
                 songNumber: Int? = nil,
                 highlightedSong: MPMediaItem? = nil,
                 showsTimer: Bool = false,
                 hideOptionsView: Bool = !showInfoButtons) {
        
        entity = .song
        
        nameLabel.text = song.title ??? .untitledSong
        
        explicitView.isHidden = showExplicit ? !song.isExplicit : true
        
        playingView.isHidden = song != musicPlayer.nowPlayingItem
        
        playPauseActive = showsTimer
        
        UniversalMethods.performOnMainThread({ self.indicator.state = musicPlayer.nowPlayingItem == song && !showsTimer ? (musicPlayer.isPlaying ? .playing : .paused) : .stopped }, afterDelay: 0.1)
        
        artistAlbumLabel.text = (song.artist ??? .unknownArtist) + " — " + (song.albumTitle ??? .untitledAlbum)
        
        if highlightedSong?.persistentID == song.persistentID {
            
            backgroundColor = Themer.textColour(for: .title).withAlphaComponent(0.05)
            
        } else {
            
            backgroundColor = .clear
        }
        
        durationLabel.text = (song.playbackDuration < 3600 ? appDelegate.formatter.timeMinuteFormatter : appDelegate.formatter.timeHourFormatter).string(from: song.playbackDuration)
        artworkImageView.image = #imageLiteral(resourceName: "NoSong75")
        
        cloudButton.isHidden = !song.isCloudItem
        
//        durationLabel.isHidden = showsTimer
        ([startTime, stopTime, timeSlider, timeSlider.superview, playPauseBorder] as [UIView?]).forEach({ $0?.isHidden = !showsTimer })
        
        if showsTimer {
            
            updateSliderDuration()
            modifyPlayPauseButton()
            infoButton.imageEdgeInsets.bottom = 32
        
        } else {
            
            playButton.setImage(nil, for: .normal)
            playButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            infoButton.imageEdgeInsets.bottom = 0
        }
        
        indicator.isHidden = showsTimer
        
        modifyPlayOnly()
        
        if let songNumber = songNumber, songNumber != 0 {
            
            trackNumberLabel.superview?.isHidden = false
            trackNumberLabel.text = "\(songNumber)."
        
        } else {
            
            trackNumberLabel.superview?.isHidden = true
        }
        
        modifyInfoButton()
        
        optionsView.isHidden = hideOptionsView
        infoButton.isHidden = hideOptionsView
        
        supplementaryStackView.isHidden = false
        durationLabel.greyOverride = false
    }
    
    func performSelectionOverrides(touched: Bool) {
        
        guard let playingView = playingView else { return }
        
        infoBorderView.alphaOverride = touched ? 0.05 : 0
        playPauseBorder.backgroundColor = .white
        playingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        selectedBackgroundView?.backgroundColor = Themer.borderViewColor()
        (explicitView.viewWithTag(1) as? MELBorderView)?.changeThemeColor()
        editBorderView.alphaOverride = touched ? 0.05 : 0
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)
        
        performSelectionOverrides(touched: selected)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        
        super.setHighlighted(highlighted, animated: animated)
        
        performSelectionOverrides(touched: highlighted)
    }
    
//    override func setEditing(_ editing: Bool, animated: Bool) {
//
//        super.setEditing(editing, animated: animated)
//
//        mainViewInnerViewLeadingConstraint.constant = editing ? 0 : 10
//
//        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
//
//            if editing.inverted && self.editingView.isHidden { } else {
//
//                self.editingView.isHidden = editing.inverted
//            }
//
//            self.contentView.layoutIfNeeded()
//        })
//    }
    
    @objc func updateSliderDuration() {
        
        if let nowPlaying = musicPlayer.nowPlayingItem {
            
            timeSlider.minimumValue = 0
            timeSlider.maximumValue = Float(nowPlaying.playbackDuration)
        }
    }
    
    override func addSubview(_ view: UIView) {

        if view.className.contains("ReorderControl") {

            view.subviews.forEach({ $0.removeFromSuperview() })

            let imageView = MELImageView.init(image: #imageLiteral(resourceName: "ReorderControl"))
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view.centre(imageView, withOffsets: .init(x: 0, y: 1))
        }

        super.addSubview(view)
    }
    
    @objc func modifySecondaryScrollView(withSong song: MPMediaItem) {
        
        guard let array = songSecondaryDetails, !array.isEmpty else { return }
            
        for category in array {
            
            switch category {
                
                case .loved:
                    
                    let image: UIImage = {
                        
                        switch song.likedState {
                            
                            case .disliked: return #imageLiteral(resourceName: "Unloved")
                                
                            case .liked: return #imageLiteral(resourceName: "Loved")
                                
                            case .none: return #imageLiteral(resourceName: "NoLove")
                        }
                    }()
                    
                    likedStatusView.imageView.image = image
                    
                case .plays: playsView.label.text = song.playCount.formatted
                    
                case .rating:
                    
                    ratingView.label.text = String(song.rating)
                    ratingView.imageView.image = song.rating > 0 ? #imageLiteral(resourceName: "StarFilled") : #imageLiteral(resourceName: "Star")
                    
                case .lastPlayed:
                    
                    guard let text = song.lastPlayedDate?.timeIntervalSinceNow.shortStringRepresentation, !text.isEmpty else {
                        
                        lastPlayedView.isHidden = true
                        continue
                    }
                    
                    lastPlayedView.label.text = text
                    
                case .dateAdded: dateAddedView.label.text = song.existsInLibrary ? song.validDateAdded.timeIntervalSinceNow.shortStringRepresentation : "Not in Library"
                    
                case .genre:
                
                    guard let text = song.genre, !text.isEmpty else {
                        
                        genreView.isHidden = true
                        continue
                    }
                    
                    genreView.label.text = text
                    
                case .year:
                    
                    guard song.year != 0 else {
                        
                        yearView.isHidden = true
                        continue
                    }
                    
                    yearView.label.text = String(song.year)
                    
                case .fileSize:
                    
                    let sizer = FileSize.init(actualSize: song.fileSize)
                    
                    sizeView.label.text = String(sizer.size) + sizer.suffix
            }
        }
    }
    
    @IBAction func buttonTapped(_ sender: AnyObject) {
        
        delegate?.artworkTapped(in: self)
    }
    
    @IBAction func accessoryButtonTapped() {
        
        delegate?.accessoryButtonTapped(in: self)
    }
    
    @IBAction func performEditAction() {
        
        delegate?.editButtonTapped(in: self)
    }
    
    /*@objc */func prepare(with playlist: MPMediaPlaylist, count: Int, number: Int? = nil) {
        
        entity = .playlist
        
        nameLabel.text = playlist.name ??? "Untitled Playlist"
        
        let count = count
        
        artistAlbumLabel.text = count.fullCountText(for: .song)
        
        let image: UIImage = {
            
            if playlist.playlistAttributes == .genius {
                
                return #imageLiteral(resourceName: "NoGenius75")
                
            } else if playlist.playlistAttributes == .smart {
                
                return #imageLiteral(resourceName: "NoSmart75")
                
            } else {
                
                return #imageLiteral(resourceName: "NoPlaylist75")
            }
        }()
        
        artworkImageView.image = image
        
        backgroundColor = .clear
        
        updateSongOnlyViews(using: playlist, number: number)
    }
    
    func prepare(for kind: AlbumBasedCollectionKind, with collection: MPMediaItemCollection, number: Int? = nil) {
        
        entity = kind.entity
        
        var set: Set<String> = []
        
        for item in collection.items {
            
            if let title = item.albumTitle, title != "" {
                
                set.insert(title)
                
            } else {
                
                set.insert(.untitledAlbum)
            }
        }
        
        let collectionTitle: String? = {
            
            guard let item = collection.representativeItem else { return nil }
            
            switch kind {
                
                case .artist: return item.validArtist
                
                case .genre: return item.validGenre
                
                case .composer: return item.validComposer
                
                case .albumArtist: return item.validAlbumArtist
            }
        }()
        
        nameLabel.text = (collectionTitle ??? .unknownArtist)
        artistAlbumLabel.text = set.count.fullCountText(for: .album) + ", " + collection.items.count.fullCountText(for: .song)
        
        let image: UIImage = {
            
            switch kind {
                
                case .artist, .albumArtist: return #imageLiteral(resourceName: "NoArtist75")
                
                case .composer: return #imageLiteral(resourceName: "NoComposer75")
                
                case .genre: return #imageLiteral(resourceName: "NoGenre75")
            }
        }()
        
        artworkImageView.image = image
        
        backgroundColor = .clear
        
        updateSongOnlyViews(using: collection, number: number)
    }
    
    /*@objc */func prepare(with album: MPMediaItemCollection,
                       withinArtist: Bool,
                       highlightedAlbum: MPMediaItemCollection? = nil,
                       number: Int? = nil) {
        
        guard let item = album.representativeItem else { return }
        
        entity = .album
        
        nameLabel.text = item.validAlbum
        
        if highlightedAlbum?.persistentID == album.persistentID {
            
            backgroundColor = (darkTheme ? UIColor.white : .black).withAlphaComponent(0.05)
            
        } else {
            
            backgroundColor = .clear
        }
        
        //artistLabel.isHidden = withinArtist
        artistAlbumLabel.text = item.validAlbumArtist
        
//        durationLabel.text = album.items.count.fullCountText(for: .song)
        
        artworkImageView.image = album.representativeItem?.isCompilation == true ? #imageLiteral(resourceName: "NoCompilation75") : #imageLiteral(resourceName: "NoAlbum75")
        
        updateSongOnlyViews(using: album, number: number)
    }
    
    func updateSongOnlyViews(using collection: MPMediaItemCollection, number: Int? = nil) {
        
        playButton.isUserInteractionEnabled = allowPlayOnly
        
        durationLabel.text = collection.totalDuration.stringRepresentation(as: .short)
        
        [optionsView, infoButton].forEach({ $0.isHidden = (collection as? MPMediaPlaylist)?.isFolder == true ? true : !showInfoButtons })
        
        playButton.setImage(nil, for: .normal)
        infoButton.imageEdgeInsets.bottom = 0
        explicitView.isHidden = true
        cloudButton.isHidden = true
        supplementaryStackView.isHidden = true
        durationLabel.greyOverride = true
        
        [playingView, indicator].forEach({ $0.isHidden = {
            
//            if !(collection is MPMediaPlaylist), let nowPlaying = musicPlayer.nowPlayingItem, Set(collection.items).contains(nowPlaying) {
//
//                UniversalMethods.performOnMainThread({ self.indicator.state = musicPlayer.isPlaying ? .playing : .paused }, afterDelay: 0.1)
//
//                return false
//            }
            
            return true
        }() })
        
        ([startTime, stopTime, timeSlider, timeSlider.superview, playPauseBorder] as [UIView?]).forEach({ $0?.isHidden = true })
        
        if let number = number, number != 0 {
            
            trackNumberLabel.superview?.isHidden = false
            trackNumberLabel.text = "\(number)."
            
        } else {
            
            trackNumberLabel.superview?.isHidden = true
        }
    }
}

extension SongTableViewCell {
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return gestureRecognizer is UISwipeGestureRecognizer && otherGestureRecognizer == supplemetaryScrollView.panGestureRecognizer
    }
}

@objc protocol EntityCellDelegate {
    
    func artworkTapped(in cell: SongTableViewCell)
    func scrollViewTapped(in cell: SongTableViewCell)
    func accessoryButtonTapped(in cell: SongTableViewCell)
    func editButtonTapped(in cell: SongTableViewCell)
}
