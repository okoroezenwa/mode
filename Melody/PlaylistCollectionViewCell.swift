//
//  PlaylistCollectionViewCell.swift
//  Melody
//
//  Created by Ezenwa Okoro on 05/11/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PlaylistCollectionViewCell: UICollectionViewCell, ArtworkContainingCell, ThemeStatusProvider {
    
    weak var delegate: PlaylistCollectionCellDelegate?
    
    @IBOutlet var imageView: InvertIgnoringImageView! {
        
        didSet {
            
            imageView.provider = self
        }
    }
    @IBOutlet var nameLabel: MELLabel!
    @IBOutlet var songCountLabel: MELLabel!
    @IBOutlet var artworkContainer: UIView!
    @IBOutlet var selectedView: UIView!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var playButtonBorder: UIView!
    @IBOutlet var stackViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var artworkImageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var artworkImageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var artworkImageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var playView: UIView!
    @IBOutlet var accessoryView: UIView!
    @IBOutlet var accessoryBorderView: UIView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var stackViewTopConstraint: NSLayoutConstraint!
    
    var artworkImageView: (UIImageView & EntityArtworkDisplaying)! {
        
        get { imageView }
        
        set { }
    }
    
    var details: (entityType: EntityType, width: CGFloat?) = (.playlist, nil) {

        didSet {

            guard !(details.entityType == oldValue.entityType && details.width == oldValue.width), let _ = artworkContainer, let _ = imageView, let _ = selectedView else { return }
            
            updateCornersAndShadows()
        }
    }
    
    override var isSelected: Bool {
        
        didSet {
            
            selectedView.isHidden = !self.isSelected
        }
    }
    
    override var isHighlighted: Bool {
        
        didSet {
            
            selectedView.isHidden = !self.isHighlighted
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        updateCornersAndShadows()
        updateSpacing()
        
        ([accessoryBorderView, playButtonBorder] as [UIView]).forEach({ UniversalMethods.addShadow(to: $0, radius: 2, opacity: 0.5, path: $0.shadowPath(cornerRadius: 12)) })
        
        notifier.addObserver(self, selector: #selector(modifyInfoButton), name: .infoButtonVisibilityChanged, object: nil)
        notifier.addObserver(self, selector: #selector(updateCornersAndShadows), name: .cornerRadiusChanged, object: nil)
        notifier.addObserver(self, selector: #selector(updateSpacing), name: .lineHeightsCalculated, object: nil)
    }
    
    @objc func updateSpacing() {
        
        stackView.spacing = FontManager.shared.cellSpacing - (activeFont == .myriadPro ? 5 : 0)
        stackViewTopConstraint.constant = FontManager.shared.cellSpacing - (activeFont == .myriadPro ? 3 : 0) + 3
    }
    
    @objc func modifyInfoButton() {
        
        accessoryView.isHidden = delegate == nil || showInfoButtons.inverted
    }
    
    @objc func updateCornersAndShadows() {
        
        [imageView, selectedView].forEach({
            
            (listsCornerRadius ?? cornerRadius).updateCornerRadius(on: $0?.layer, width: (details.width ?? imageView.bounds.width) - 16, entityType: details.entityType, globalRadiusType: cornerRadius)
        })
        
        UniversalMethods.addShadow(to: artworkContainer, radius: 4, opacity: 0.35, shouldRasterise: true)
    }
    
    func prepare(with playlist: MPMediaPlaylist, count: Int, editingMode editing: Bool = false, direction: UICollectionView.ScrollDirection = .horizontal, position: Position = .leading, topConstraint: CGFloat = 0) {
        
        if direction == .vertical {
            
            let insets: UIEdgeInsets = {
                
                switch direction {
                    
                    case .vertical:
                        
                        let smallerExpression: CGFloat = (10/3) - 8
                        let largerExpression: CGFloat = (20/3) - 8
                        
                        switch position {
                            
                            case .leading: return .init(top: topConstraint - 8, left: 10 - 8, bottom: 10, right: smallerExpression)
                                
                            case .middle: return .init(top: topConstraint - 8, left: largerExpression, bottom: 10, right: largerExpression)
                                
                            case .trailing: return .init(top: topConstraint - 8, left: smallerExpression, bottom: 10, right: 10 - 8)
                        }
                    
                    case .horizontal: return .zero
                
                    @unknown default: return .zero
                }
            }()
            
            artworkImageViewTopConstraint.constant = insets.top
            artworkImageViewLeadingConstraint.constant = insets.left
            artworkImageViewTrailingConstraint.constant = insets.right
            stackViewBottomConstraint.constant = insets.bottom
        }
        
        nameLabel.text = playlist.validName
        songCountLabel.text = count.fullCountText(for: .song)
        
        let granularType: EntityArtworkType.GranularEntityType = {
            
            if playlist.playlistAttributes == .genius {
                
                return .geniusPlaylist
                
            } else if playlist.playlistAttributes == .smart {
                
                return .smartPlaylist
                
            } else {
                
                return .playlist
            }
        }()
        
        artworkImageView.artworkType = .empty(entityType: granularType, size: .large)
        
        playView.isHidden = delegate == nil
        modifyInfoButton()
        
        if delegate != nil {
            
            if editing {
                
                playButton.setImage(#imageLiteral(resourceName: "AddNoBorderSmall"), for: .normal)
                playButton.isHidden = false
                playButton.imageEdgeInsets.left = 0
                playButtonBorder.isHidden = false
                
            } else {
                
                playButton.setImage(#imageLiteral(resourceName: "PlayFilledSmall"), for: .normal)
                playButton.isHidden = !allowPlayOnly || delegate == nil
                playButtonBorder.isHidden = !allowPlayOnly || delegate == nil
                playButton.imageEdgeInsets.left = 1
            }
        }
    }
    
    func prepare(with song: MPMediaItem, editing: Bool = false) {
        
        nameLabel.text = song.validTitle
        songCountLabel.text = song.validArtist + " — " + song.validAlbum
        
        artworkImageView.artworkType = .empty(entityType: .song, size: .large)
        
        playView.isHidden = delegate == nil
        modifyInfoButton()
        
        if delegate != nil {
            
            if editing {
                
                playButton.setImage(#imageLiteral(resourceName: "AddNoBorderSmall"), for: .normal)
                playButton.isHidden = false
                playButton.imageEdgeInsets.left = 0
                playButtonBorder.isHidden = false
                
            } else {
                
                playButton.setImage(#imageLiteral(resourceName: "PlayFilledSmall"), for: .normal)
                playButton.isHidden = !allowPlayOnly || delegate == nil
                playButtonBorder.isHidden = !allowPlayOnly || delegate == nil
                playButton.imageEdgeInsets.left = 1
            }
        }
    }
    
    func prepare(with album: MPMediaItemCollection, editing: Bool = false) {
        
        nameLabel.text = album.representativeItem?.validAlbum
        songCountLabel.text = album.representativeItem?.validArtist
        
        artworkImageView.artworkType = .empty(entityType: album.representativeItem?.isCompilation == true ? .compilation : .album, size: .large)
        
        playView.isHidden = delegate == nil
        modifyInfoButton()
        
        if delegate != nil {
            
            if editing {
                
                playButton.setImage(#imageLiteral(resourceName: "AddNoBorderSmall"), for: .normal)
                playButton.isHidden = false
                playButton.imageEdgeInsets.left = 0
                playButtonBorder.isHidden = false
                
            } else {
                
                playButton.setImage(#imageLiteral(resourceName: "PlayFilledSmall"), for: .normal)
                playButton.isHidden = !allowPlayOnly || delegate == nil
                playButtonBorder.isHidden = !allowPlayOnly || delegate == nil
                playButton.imageEdgeInsets.left = 1
            }
        }
    }
    
    func prepare(with collection: MPMediaItemCollection, kind: AlbumBasedCollectionKind, editing: Bool = false) {
        
        nameLabel.text = {
            
            switch kind {
                
                case .artist: return collection.representativeItem?.validArtist
                
                case .albumArtist: return collection.representativeItem?.validAlbumArtist
                
                case .genre: return collection.representativeItem?.validGenre
                
                case .composer: return collection.representativeItem?.validComposer
            }
        }()
        
        var set: Set<String> = []
        
        for item in collection.items {
            
            if let title = item.albumTitle, title != "" {
                
                set.insert(title)
                
            } else {
                
                set.insert(.untitledAlbum)
            }
        }

        songCountLabel.text = set.count.fullCountText(for: .album) + ", " + collection.items.count.fullCountText(for: .song)
        
        let granularType: EntityArtworkType.GranularEntityType = {
            
            switch kind {
                
                case .artist: return .artist
                
                case .albumArtist: return .albumArtist
                
                case .composer: return .composer
                
                case .genre: return .genre
            }
        }()
        
        artworkImageView.artworkType = .empty(entityType: granularType, size: .large)
        
        playView.isHidden = delegate == nil
        modifyInfoButton()
        
        if delegate != nil {
            
            if editing {
                
                playButton.setImage(#imageLiteral(resourceName: "AddNoBorderSmall"), for: .normal)
                playButton.isHidden = false
                playButton.imageEdgeInsets.left = 0
                playButtonBorder.isHidden = false
                
            } else {
                
                playButton.setImage(#imageLiteral(resourceName: "PlayFilledSmall"), for: .normal)
                playButton.isHidden = !allowPlayOnly || delegate == nil
                playButtonBorder.isHidden = !allowPlayOnly || delegate == nil
                playButton.imageEdgeInsets.left = 1
            }
        }
    }
    
    @IBAction func playThrough() {
        
        delegate?.playThrough(in: self)
    }
    
    @IBAction func rightButtonTapped() {
        
        delegate?.accessoryButtonTapped(in: self)
    }
}

protocol PlaylistCollectionCellDelegate: class {
    
    func playThrough(in cell: PlaylistCollectionViewCell)
    func accessoryButtonTapped(in cell: PlaylistCollectionViewCell)
}
