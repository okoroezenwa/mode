//
//  PlaylistCollectionViewCell.swift
//  Melody
//
//  Created by Ezenwa Okoro on 05/11/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PlaylistCollectionViewCell: UICollectionViewCell, ArtworkContainingCell {
    
    weak var delegate: PlaylistCollectionCellDelegate?
    
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var nameLabel: MELLabel!
    @IBOutlet weak var songCountLabel: MELLabel!
    @IBOutlet weak var artworkContainer: UIView!
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playButtonBorder: UIView!
    @IBOutlet weak var secondaryLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var artworkImageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var artworkImageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var artworkImageViewTopConstraint: NSLayoutConstraint!
    
    var details: (entity: Entity, width: CGFloat?) = (.playlist, nil) {

        didSet {

            guard !(details.entity == oldValue.entity && details.width == oldValue.width), let _ = artworkContainer, let _ = artworkImageView, let _ = selectedView else { return }
            
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
        UniversalMethods.addShadow(to: playButtonBorder, radius: 2, opacity: 0.5, path: playButtonBorder.shadowPath(cornerRadius: 12))
        
        if #available(iOS 11, *) {
            
            artworkImageView.accessibilityIgnoresInvertColors = true
        }
        
        notifier.addObserver(self, selector: #selector(updateCornersAndShadows), name: .cornerRadiusChanged, object: nil)
    }
    
    @objc func updateCornersAndShadows() {
        
        [artworkImageView, selectedView].forEach({
            
            (listsCornerRadius ?? cornerRadius).updateCornerRadius(on: $0?.layer, width: (details.width ?? artworkImageView.bounds.width) - 16, entityType: details.entity, globalRadiusType: cornerRadius)
            
//            $0?.layer.cornerRadius = {
//
//                switch cornerRadius {
//
//                    case .automatic: return (listsCornerRadius ?? cornerRadius).radius(for: details.entity, width: (details.width ?? artworkImageView.bounds.width) - 16)
//
//                    default: return cornerRadius.radius(for: details.entity, width: (details.width ?? artworkImageView.bounds.width) - 16)
//                }
//            }()
        })
        
        UniversalMethods.addShadow(to: artworkContainer, radius: 4, opacity: 0.3, shouldRasterise: true)
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
                }
            }()
            
            artworkImageViewTopConstraint.constant = insets.top
            artworkImageViewLeadingConstraint.constant = insets.left
            artworkImageViewTrailingConstraint.constant = insets.right
            secondaryLabelBottomConstraint.constant = insets.bottom
        }
        
        nameLabel.text = playlist.validName
        songCountLabel.text = count.fullCountText(for: .song)
        let image: UIImage = {
            
            if playlist.playlistAttributes == .genius {
                
                return #imageLiteral(resourceName: "NoGenius300")
                
            } else if playlist.playlistAttributes == .smart {
                
                return #imageLiteral(resourceName: "NoSmart300")
                
            } else {
                
                return #imageLiteral(resourceName: "NoPlaylist300")
            }
        }()
        
        artworkImageView.image = image
        
        [playButton, playButtonBorder].forEach({ $0?.isHidden = delegate == nil })
        
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
        
        artworkImageView.image = #imageLiteral(resourceName: "NoSong300")
        
        [playButton, playButtonBorder].forEach({ $0?.isHidden = delegate == nil })
        
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
        
        artworkImageView.image = album.representativeItem?.isCompilation == true ? #imageLiteral(resourceName: "NoCompilation300") : #imageLiteral(resourceName: "NoAlbum300")
        
        [playButton, playButtonBorder].forEach({ $0?.isHidden = delegate == nil })
        
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
        
        nameLabel.textAlignment = .center
        songCountLabel.textAlignment = .center
        
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
        
        artworkImageView.image = {
            
            switch kind {
                
                case .artist, .albumArtist: return #imageLiteral(resourceName: "NoArtist300")
                
                case .genre: return #imageLiteral(resourceName: "NoGenre300")
                
                case .composer: return #imageLiteral(resourceName: "NoComposer300")
            }
        }()
        
        [playButton, playButtonBorder].forEach({ $0?.isHidden = delegate == nil })
        
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
}

protocol PlaylistCollectionCellDelegate: class {
    
    func playThrough(in cell: PlaylistCollectionViewCell)
}
