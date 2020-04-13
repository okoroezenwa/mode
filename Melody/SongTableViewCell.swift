//
//  AltSongTableViewCell.swift
//  Melody
//
//  Created by Ezenwa Okoro on 24/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class EntityTableViewCell: UITableViewCell, ArtworkContainingCell {
    
    @IBOutlet var artworkImageView: UIImageView!
    @IBOutlet var nameLabel: MELLabel!
    @IBOutlet var artistAlbumLabel: MELLabel!
    @IBOutlet var supplemetaryScrollView: UIScrollView!
    @IBOutlet var supplementaryStackView: UIStackView! {
        
        didSet {
            
            prepareSupplementaryView()
        }
    }
    @IBOutlet var playButton: MELButton!
    @IBOutlet var cloudButton: UIImageView!
    @IBOutlet var durationLabel: MELLabel!
    @IBOutlet var trackNumberLabel: MELLabel!
    @IBOutlet var explicitView: UIView!
    @IBOutlet var artworkContainer: UIView!
    @IBOutlet var playingView: UIView!
    @IBOutlet var optionsView: UIView!
    @IBOutlet var infoButton: MELButton!
    @IBOutlet var infoBorderView: MELBorderView!
    @IBOutlet var editingView: UIView!
    @IBOutlet var stackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var mainView: UIView!
    @IBOutlet var editBorderView: MELBorderView!
    @IBOutlet var mainViewInnerViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var textStackView: UIStackView!
    @IBOutlet var textContainingStackView: UIStackView!
    @IBOutlet var editButton: MELButton!
    
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
    
    var preferredEditingStyle = Mode.EditingStyle.select {
        
        didSet {
            
            guard oldValue != preferredEditingStyle else { return }
            
            updateEditingView()
        }
    }
    
    var width: CGFloat { return artworkContainer.frame.width }
    
    @objc lazy var indicator: ESTMusicIndicatorView = {
        
        let indicator = ESTMusicIndicatorView.init(frame: CGRect.zero)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.sizeToFit()
        self.playingView.addSubview(indicator)
        self.playingView.centre(indicator)
        
        return indicator
    }()
    
    var entityType = EntityType.song {
        
        didSet {
            
            guard entityType != oldValue, let _ = artworkContainer, let _ = artworkImageView else { return }
            
            updateCornersAndShadows()
        }
    }
    
    enum DetailsVisibility { case primary, secondary, both }

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        selectedBackgroundView = MELBorderView()
        
        updateCornersAndShadows()
        updateSpacing()
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapCell(_:)))
        supplemetaryScrollView.addGestureRecognizer(tap)
        
//        let editHold = UILongPressGestureRecognizer.init(target: self, action: #selector(performHold(_:)))
//        editHold.minimumPressDuration = longPressDuration
//        editButton.addGestureRecognizer(editHold)
//        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: editHold))
        
//        let accessoryHold = UILongPressGestureRecognizer.init(target: self, action: #selector(performHold(_:)))
//        accessoryHold.minimumPressDuration = longPressDuration
//        infoButton.addGestureRecognizer(accessoryHold)
//        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: accessoryHold))
//
//        let artworkHold = UILongPressGestureRecognizer.init(target: self, action: #selector(performHold(_:)))
//        artworkHold.minimumPressDuration = longPressDuration
//        playButton.addGestureRecognizer(artworkHold)
//        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: artworkHold))
        
        notifier.addObserver(self, selector: #selector(modifyPlayOnly), name: .playOnlyChanged, object: nil)
        notifier.addObserver(self, selector: #selector(modifyBackground), name: .themeChanged, object: nil)
        notifier.addObserver(self, selector: #selector(modifyIndicator), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer)
        notifier.addObserver(self, selector: #selector(updateCornersAndShadows), name: .cornerRadiusChanged, object: nil)
        notifier.addObserver(self, selector: #selector(modifyInfoButton), name: .infoButtonVisibilityChanged, object: nil)
        notifier.addObserver(self, selector: #selector(updateSpacing), name: .lineHeightsCalculated, object: nil)
        
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
    
    @objc func performHold(_ sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
            
            case .began:
                
                enum HoldView: String { case artwork, edit, accessory }
                
                let view: HoldView = {
                    
                    switch sender.view {
                        
                        case let x where x == playButton: return .artwork
                        
                        case let x where x == infoButton: return .accessory
                        
                        default: return .edit
                    }
                }()
                
                switch view {
                    
                    case .edit: delegate?.editButtonHeld(in: self)
                    
                    case .accessory: delegate?.accessoryButtonHeld(in: self)
                    
                    case .artwork: delegate?.artworkHeld(in: self)
                }
            
            case .changed, .ended:
            
                guard let topVC = topViewController as? VerticalPresentationContainerViewController else { return }
            
                topVC.gestureActivated(sender)
            
            default: break
        }
    }
    
    @objc func updateSpacing() {
        
        textStackView.spacing = FontManager.shared.cellSpacing
        textContainingStackView.layoutMargins.bottom = FontManager.shared.cellInset
        textContainingStackView.layoutMargins.top = FontManager.shared.cellInset
    }
    
    @objc func prepareSupplementaryView() {
        
        [SecondaryCategory.loved, .plays, .rating, .lastPlayed, .dateAdded, .genre, .year, .fileSize].forEach({ supplementaryStackView.addArrangedSubview(view(for: $0)) })
    }
    
    @objc func updateCornersAndShadows() {
        
        [artworkImageView, playingView].forEach({
            
            (listsCornerRadius ?? cornerRadius).updateCornerRadius(on: $0?.layer, width: width, entityType: entityType, globalRadiusType: cornerRadius)
        })
        
        UniversalMethods.addShadow(to: artworkContainer, radius: 4, opacity: 0.35, shouldRasterise: true)
    }
    
    func updateEditingView() {
        
        editButton.setImage({
            
            switch preferredEditingStyle {
                
                case .insert: return #imageLiteral(resourceName: "AddNoBorderSmall")
                
                case .select: return isSelected ? #imageLiteral(resourceName: "Check") : nil
            }
            
        }(), for: .normal)
        
        editBorderView.alphaOverride = preferredEditingStyle == .select && isSelected.inverted ? 0.1 : (useLighterBorders ? 0 : 0.03)
        editBorderView.layer.borderWidth = preferredEditingStyle == .select && isSelected.inverted ? 1.2 : 0
        editBorderView.bordered = preferredEditingStyle == .select && isSelected.inverted
        editBorderView.clear = preferredEditingStyle == .select && isSelected.inverted
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
        
        playButton.isUserInteractionEnabled = allowPlayOnly && delegate != nil
    }
    
    @objc func modifyBackground() {
        
        if backgroundColor != .clear {
            
            backgroundColor = Themer.textColour(for: .title).withAlphaComponent(0.05)
        }
    }
    
    @objc func modifyIndicator() {
        
        guard !playingView.isHidden else { return }
        
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
        
        delegate?.scrollViewTapped(in: self)
    }

    func prepare(with song: MPMediaItem,
                 songNumber: Int? = nil,
                 highlightedSong: MPMediaItem? = nil,
                 hideOptionsView: Bool = !showInfoButtons) {
        
        entityType = .song
        
        nameLabel.text = song.title ??? .untitledSong
        
        explicitView.isHidden = showExplicit ? !song.isExplicit : true
        
        playingView.isHidden = song != musicPlayer.nowPlayingItem
        
        UniversalMethods.performOnMainThread({ self.indicator.state = musicPlayer.nowPlayingItem == song ? (musicPlayer.isPlaying ? .playing : .paused) : .stopped }, afterDelay: 0.1)
        
        artistAlbumLabel.text = (song.artist ??? .unknownArtist) + " — " + (song.albumTitle ??? .untitledAlbum)
        artistAlbumLabel.attributes = nil
        
        if highlightedSong?.persistentID == song.persistentID {
            
            backgroundColor = Themer.textColour(for: .title).withAlphaComponent(0.05)
            
        } else {
            
            backgroundColor = .clear
        }
        
        durationLabel.text = (song.playbackDuration < 3600 ? appDelegate.formatter.timeMinuteFormatter : appDelegate.formatter.timeHourFormatter).string(from: song.playbackDuration)
        artworkImageView.image = #imageLiteral(resourceName: "NoSong75")
        
        cloudButton.isHidden = !song.isCloudItem
        
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
        
        infoBorderView.alphaOverride = touched ? 0.03 : 0
        playingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        selectedBackgroundView?.backgroundColor = Themer.borderViewColor()
        (explicitView.viewWithTag(1) as? MELBorderView)?.changeThemeColor()
        
        editBorderView.alphaOverride = (preferredEditingStyle == .select && isSelected.inverted ? 0.2 : (touched ? 0.03 : 0)) + (useLighterBorders ? 0 : 0.03)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)
        
        performSelectionOverrides(touched: selected)
        
        if preferredEditingStyle == .select {
            
            updateEditingView()
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        
        super.setHighlighted(highlighted, animated: animated)
        
        performSelectionOverrides(touched: highlighted)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {

        super.setEditing(editing, animated: animated)
        
        if #available(iOS 13, *), preferredEditingStyle == .select { return }
        
        mainViewInnerViewLeadingConstraint.constant = editing ? 0 : 10

        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {

            if editing.inverted && self.editingView.isHidden { } else {

                self.editingView.isHidden = editing.inverted
            }
            
            self.editingView.alpha = editing ? 1 : 0
            self.contentView.layoutIfNeeded()
        })
    }
    
    override func addSubview(_ view: UIView) {

        if view.className.contains("ReorderControl") {
            
            if #available(iOS 13, *) { } else {
                
                view.subviews.forEach({ $0.removeFromSuperview() })

                let imageView = MELImageView.init(image: #imageLiteral(resourceName: "ReorderControl"))

                imageView.translatesAutoresizingMaskIntoConstraints = false
                view.centre(imageView, withOffsets: .init(x: 0, y: 1))
            }
        
        } else if view.className.contains("EditControl") {
            
            if #available(iOS 13, *) {
                
                view.isUserInteractionEnabled = true
            
                let editHold = UILongPressGestureRecognizer.init(target: self, action: #selector(performHold(_:)))
                editHold.minimumPressDuration = longPressDuration
                view.addGestureRecognizer(editHold)
                LongPressManager.shared.gestureRecognisers.append(Weak.init(value: editHold))
                
                let tap = UITapGestureRecognizer.init(target: self, action: #selector(editTap))
                view.addGestureRecognizer(tap)
                
            } else {
                
                view.isHidden = true
            }
        }

        super.addSubview(view)
    }
    
    @objc func editTap() {
        
        if isSelected, let indexPath = delegate?.tableView.indexPath(for: self) {
            
            delegate?.tableView.deselectRow(at: indexPath, animated: false)
            
        } else {
            
            delegate?.tableView.selectRow(at: delegate?.tableView.indexPath(for: self), animated: false, scrollPosition: .none)
        }
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
    
    func prepare(with playlist: MPMediaPlaylist, count: Int, number: Int? = nil) {
        
        entityType = .playlist
        
        nameLabel.text = playlist.name ??? "Untitled Playlist"
        
        let count = count
        
        artistAlbumLabel.text = count.fullCountText(for: .song)
        artistAlbumLabel.attributes = nil
        
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
        
        updateViews(using: playlist, number: number)
    }
    
    func prepare(for kind: AlbumBasedCollectionKind, with collection: MPMediaItemCollection, number: Int? = nil) {
        
        entityType = kind.entityType
        
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
        artistAlbumLabel.attributes = nil
        
        let image: UIImage = {
            
            switch kind {
                
                case .artist, .albumArtist: return #imageLiteral(resourceName: "NoArtist75")
                
                case .composer: return #imageLiteral(resourceName: "NoComposer75")
                
                case .genre: return #imageLiteral(resourceName: "NoGenre75")
            }
        }()
        
        artworkImageView.image = image
        
        backgroundColor = .clear
        
        updateViews(using: collection, number: number)
    }
    
    func prepare(with album: MPMediaItemCollection,
                       withinArtist: Bool,
                       highlightedAlbum: MPMediaItemCollection? = nil,
                       number: Int? = nil) {
        
        guard let item = album.representativeItem else { return }
        
        entityType = .album
        
        nameLabel.text = item.validAlbum
        
        if highlightedAlbum?.persistentID == album.persistentID {
            
            backgroundColor = (darkTheme ? UIColor.white : .black).withAlphaComponent(0.05)
            
        } else {
            
            backgroundColor = .clear
        }
        
        //artistLabel.isHidden = withinArtist
        let text = album.count.fullCountText(for: .song) + "   " + item.validAlbumArtist
        
        artistAlbumLabel.text = text
        artistAlbumLabel.attributes = [.init(kind: .title, range: text.nsRange(of: item.validAlbumArtist))]
        
        artworkImageView.image = album.representativeItem?.isCompilation == true ? #imageLiteral(resourceName: "NoCompilation75") : #imageLiteral(resourceName: "NoAlbum75")
        
        updateViews(using: album, number: number)
    }
    
    func updateViews(using collection: MPMediaItemCollection, number: Int? = nil) {
        
        playButton.isUserInteractionEnabled = allowPlayOnly
        
        durationLabel.text = collection.totalDuration.stringRepresentation(as: .short)
        
        [optionsView, infoButton].forEach({ $0.isHidden = (collection as? MPMediaPlaylist)?.isFolder == true ? true : !showInfoButtons })
        
        explicitView.isHidden = true
        cloudButton.isHidden = true
        supplementaryStackView.isHidden = true
        durationLabel.greyOverride = true
        
        [playingView, indicator].forEach({ $0.isHidden = {
            
            if !(collection is MPMediaPlaylist), let nowPlaying = musicPlayer.nowPlayingItem, Set(collection.items).contains(nowPlaying) {

                UniversalMethods.performOnMainThread({ self.indicator.state = musicPlayer.isPlaying ? .playing : .paused }, afterDelay: 0.1)

                return false
            }
            
            return true
        }() })
        
        if let number = number, number != 0 {
            
            trackNumberLabel.superview?.isHidden = false
            trackNumberLabel.text = "\(number)."
            
        } else {
            
            trackNumberLabel.superview?.isHidden = true
        }
    }
}

extension EntityTableViewCell {
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return gestureRecognizer is UISwipeGestureRecognizer && otherGestureRecognizer == supplemetaryScrollView.panGestureRecognizer
    }
}

protocol EntityCellDelegate: EditControlContaining {
    
    var tableView: MELTableView! { get set }
    func artworkTapped(in cell: EntityTableViewCell)
    func artworkHeld(in cell: EntityTableViewCell)
    func scrollViewTapped(in cell: EntityTableViewCell)
    func accessoryButtonTapped(in cell: EntityTableViewCell)
    func accessoryButtonHeld(in cell: EntityTableViewCell)
    func editButtonTapped(in cell: EntityTableViewCell)
    func editButtonHeld(in cell: EntityTableViewCell)
}
