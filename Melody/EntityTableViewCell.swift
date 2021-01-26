//
//  AltSongTableViewCell.swift
//  Melody
//
//  Created by Ezenwa Okoro on 24/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias PropertyDictionary = [SecondaryCategory: (image: UIImage, text: String)]

class EntityTableViewCell: UITableViewCell, ArtworkContainingCell, ThemeStatusProvider {
    
    @IBOutlet var entityImageView: InvertIgnoringImageView! {
        
        didSet {
            
            entityImageView.provider = self
        }
    }
    @IBOutlet var nameLabel: MELLabel!
    @IBOutlet var artistAlbumLabel: MELLabel!
    @IBOutlet var supplementaryCollectionView: UICollectionView!
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
    
    var artworkImageView: (UIImageView & EntityArtworkDisplaying)! {
        
        get { entityImageView }
        
        set { }
    }
    
    lazy var properties = SecondaryCategory.allCases.reduce(PropertyDictionary(), {
        
        var dictionary = $0
        dictionary[$1] = ($1.image, "-")
        
        return dictionary
    })
    
    weak var delegate: EntityCellDelegate?
    var shouldPerformLeftSwipeAction = true
    var shouldPerformRightSwipeAction = true
    
    var preferredEditingStyle = Mode.EditingStyle.select {
        
        didSet {
            
            guard oldValue != preferredEditingStyle else { return }
            
            updateEditingView()
        }
    }
    
    var width: CGFloat { return artworkContainer.frame.width }
    lazy var collectionViewWidth = 0 as CGFloat
    
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
            
            guard entityType != oldValue, let _ = artworkContainer, let _ = entityImageView else { return }
            
            updateCornersAndShadows()
        }
    }
    
    enum DetailsVisibility { case primary, secondary, both }

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        selectedBackgroundView = MELBorderView()
        
        updateCornersAndShadows()
        updateSpacing()
        
        supplementaryCollectionView.register(UINib.init(nibName: .init(describing: EntityPropertyCollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: "cell")
        supplementaryCollectionView.delegate = self
        supplementaryCollectionView.dataSource = self
        supplementaryCollectionView.allowsSelection = false
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapCell(_:)))
        supplementaryCollectionView.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        supplementaryCollectionView.addGestureRecognizer(pan)
        
        notifier.addObserver(self, selector: #selector(modifyPlayOnly), name: .playOnlyChanged, object: nil)
        notifier.addObserver(self, selector: #selector(modifyBackground), name: .themeChanged, object: nil)
        notifier.addObserver(self, selector: #selector(modifyIndicator), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: /*musicPlayer*/nil)
        notifier.addObserver(self, selector: #selector(updateCornersAndShadows), name: .cornerRadiusChanged, object: nil)
        notifier.addObserver(self, selector: #selector(modifyInfoButton), name: .infoButtonVisibilityChanged, object: nil)
        notifier.addObserver(self, selector: #selector(updateSpacing), name: .lineHeightsCalculated, object: nil)
        
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
    
    @objc func updateCornersAndShadows() {
        
        [entityImageView, playingView].forEach({
            
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
    
    @objc func tapCell(_ gr: UITapGestureRecognizer) {
        
        delegate?.scrollViewTapped(in: self)
    }

    func prepare(with song: MPMediaItem,
                 songNumber: Int? = nil,
                 highlightedSong: MPMediaItem? = nil,
                 hideOptionsView: Bool = !showInfoButtons) {
        
        contentView.alpha = {
            
            if let number = song.value(forProperty: "isPlayable") as? NSNumber, number.boolValue.inverted {
                
                return 0.5
            }
            
            return 1
        }()
        
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
        artworkImageView.artworkType = .empty(entityType: .song, size: .regular)
        
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
        
        contentView.alpha = 1
        
        entityType = .playlist
        
        nameLabel.text = playlist.name ??? "Untitled Playlist"
        
        let count = count
        
        artistAlbumLabel.text = count.fullCountText(for: .song)
        artistAlbumLabel.attributes = nil
        
        let granularType: EntityArtworkType.GranularEntityType = {
            
            if playlist.playlistAttributes == .genius {
                
                return .geniusPlaylist
                
            } else if playlist.playlistAttributes == .smart {
                
                return .smartPlaylist
                
            } else {
                
                return .playlist
            }
        }()
        
        artworkImageView.artworkType = .empty(entityType: granularType, size: .regular)
        
        backgroundColor = .clear
        
        updateViews(using: playlist, number: number)
    }
    
    func prepare(for kind: AlbumBasedCollectionKind, with collection: MPMediaItemCollection, number: Int? = nil) {
        
        contentView.alpha = 1
        
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
        
        let granularType: EntityArtworkType.GranularEntityType = {
            
            switch kind {
                
                case .artist: return .artist
                
                case .albumArtist: return .albumArtist
                
                case .composer: return .composer
                
                case .genre: return .genre
            }
        }()
        
        artworkImageView.artworkType = .empty(entityType: granularType, size: .regular)
        
        backgroundColor = .clear
        
        updateViews(using: collection, number: number)
    }
    
    func prepare(with album: MPMediaItemCollection,
                       withinArtist: Bool,
                       highlightedAlbum: MPMediaItemCollection? = nil,
                       number: Int? = nil) {
        
        contentView.alpha = 1
        
        guard let item = album.representativeItem else { return }
        
        entityType = .album
        
        nameLabel.text = item.validAlbum
        
        if highlightedAlbum?.persistentID == album.persistentID {
            
            backgroundColor = (darkTheme ? UIColor.white : .black).withAlphaComponent(0.05)
            
        } else {
            
            backgroundColor = .clear
        }
        
        let text = album.count.fullCountText(for: .song) + "   " + item.validAlbumArtist
        
        artistAlbumLabel.text = text
        artistAlbumLabel.attributes = [.init(kind: .title, range: text.nsRange(of: item.validAlbumArtist))]
        
        artworkImageView.artworkType = .empty(entityType: album.representativeItem?.isCompilation == true ? .compilation : .album, size: .regular)
        
        updateViews(using: album, number: number)
    }
    
    func updateViews(using collection: MPMediaItemCollection, number: Int? = nil) {
        
        playButton.isUserInteractionEnabled = allowPlayOnly
        
        durationLabel.text = collection.totalDuration.stringRepresentation(as: .short)
        
        [optionsView, infoButton].forEach({ $0.isHidden = (collection as? MPMediaPlaylist)?.isFolder == true ? true : !showInfoButtons })
        
        explicitView.isHidden = true
        cloudButton.isHidden = true
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
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        collectionViewWidth = supplementaryCollectionView.frame.width
    }
}

extension EntityTableViewCell {
    
    @objc func handlePan(_ gr: UIPanGestureRecognizer) {
        
        let translation = gr.translation(in: gr.view)
        let direction = translation.x > 0 ? UISwipeGestureRecognizer.Direction.right : .left
        
        switch gr.state {
            
            case .began, .changed:
                
                if direction == .right, supplementaryCollectionView.contentOffset.x <= 0 {
                    
                    supplementaryCollectionView.bounces = false
                    
                    if shouldPerformLeftSwipeAction {
                        
                        delegate?.handleScrollSwipe(from: gr, direction: .right)
                        shouldPerformLeftSwipeAction = false
                        shouldPerformRightSwipeAction = true
                    }
                
                } else if direction == .left, supplementaryCollectionView.contentOffset.x >= (supplementaryCollectionView.contentSize.width - supplementaryCollectionView.frame.size.width) {
                    
                    supplementaryCollectionView.bounces = false
                    
                    if shouldPerformRightSwipeAction {
                        
                        delegate?.handleScrollSwipe(from: gr, direction: .left)
                        shouldPerformRightSwipeAction = false
                        shouldPerformLeftSwipeAction = true
                    }
                }
            
            case .ended: supplementaryCollectionView.bounces = true
            
            default: break
        }
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let gr = gestureRecognizer as? UIPanGestureRecognizer {
            
            if abs(gr.velocity(in: gr.view).x) < abs(gr.velocity(in: gr.view).y) { return false }
            
            let direction = gr.translation(in: gr.view).x > 0 ? UISwipeGestureRecognizer.Direction.right : .left
            
            if (direction == .right && supplementaryCollectionView.contentOffset.x <= 0) || (direction == .left && supplementaryCollectionView.contentOffset.x >= (supplementaryCollectionView.contentSize.width - supplementaryCollectionView.frame.size.width)) {
                
                supplementaryCollectionView.bounces = false
            }

            shouldPerformLeftSwipeAction = true
            shouldPerformRightSwipeAction = true
        }
        
        return true
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer == supplementaryCollectionView.panGestureRecognizer
    }
}

extension EntityTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { entityType.secondaryCategories.count }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! EntityPropertyCollectionViewCell
        
        let property = entityType.secondaryCategories[indexPath.row]
        let details = properties[property]
        
        cell.prepare(with: details?.image, text: details?.text, property: property)
        
        return cell
    }
}

extension EntityTableViewCell: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let property = entityType.secondaryCategories[indexPath.row]
        let imageProperties = property.imageProperties
        let text = properties[property]?.text
        
        return .init(width: imageProperties.size + (text?.isEmpty == true ? 0 : imageProperties.spacing) + FontManager.shared.width(for: text, style: .secondary), height: collectionView.frame.height)
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
    func handleScrollSwipe(from gr: UIGestureRecognizer, direction: UISwipeGestureRecognizer.Direction)
}
