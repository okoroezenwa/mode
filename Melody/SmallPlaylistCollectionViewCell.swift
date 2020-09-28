//
//  SmallePlaylistCollectionViewCell.swift
//  Melody
//
//  Created by Ezenwa Okoro on 13/11/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SmallPlaylistCollectionViewCell: UICollectionViewCell, ArtworkContainingCell, ThemeStatusProvider {
    
    @IBOutlet var imageView: InvertIgnoringImageView! {
        
        didSet {
            
            imageView.provider = self
        }
    }
    @IBOutlet var nameLabel: MELLabel!
    @IBOutlet var songCountLabel: MELLabel!
    @IBOutlet var artworkContainer: InvertIgnoringView!
    @IBOutlet var containerView: MELBorderView!
    @IBOutlet var chevron: MELImageView!
    @IBOutlet var containerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var containerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var chevronLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var chevronWidthConstraint: NSLayoutConstraint!
    
    var artworkImageView: (UIImageView & EntityArtworkDisplaying)! {
        
        get { imageView }
        
        set { }
    }
    
    var topConstraint: CGFloat = 0 {
        
        didSet {
            
            guard containerViewTopConstraint.constant != topConstraint else { return }
            
            containerViewTopConstraint.constant = topConstraint
        }
    }
    
    var bottomConstraint: CGFloat = 0 {
        
        didSet {
            
            guard containerViewBottomConstraint.constant != bottomConstraint else { return }
            
            containerViewBottomConstraint.constant = bottomConstraint
        }
    }
    
    override var isSelected: Bool {
        
        didSet {
            
            update(for: isSelected ? .selected : isHighlighted ? .highlighted : .untouched)
        }
    }
    
    override var isHighlighted: Bool {
        
        didSet {
            
            update(for: isSelected ? .selected : isHighlighted ? .highlighted : .untouched)
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        UniversalMethods.addShadow(to: artworkContainer, radius: 2, opacity: 0.35, shouldRasterise: true)
    }
    
    func update(for state: CellState) {
        
        containerView.updateTheme = false
        containerView.bordered = state == .untouched
        containerView.clear = state == .untouched
        containerView.alphaOverride = state == .selected ? 1 : 0
        
        nameLabel.reversed = state == .selected
        songCountLabel.reversed = state == .selected
        
        
        UIView.animate(withDuration: 0.15, animations: {
            
            self.containerView.updateTheme = true
            self.nameLabel.changeThemeColor()
            self.songCountLabel.changeThemeColor()
        })
    }
    
    @objc func prepare(with playlist: MPMediaPlaylist, shouldHideChevron hideChevron: Bool) {
        
        nameLabel.text = playlist.validName
        chevron.isHidden = hideChevron
        chevronLeadingConstraint.constant = hideChevron ? 0 : 8
        chevronWidthConstraint.constant = hideChevron ? 0 : 10
        
        songCountLabel.text = playlist.items.count.fullCountText(for: .song)
        
        let granularType: EntityArtworkType.GranularEntityType = {
            
            if playlist.playlistAttributes == .genius {
                
                return .geniusPlaylist
                
            } else if playlist.playlistAttributes == .smart {
                
                return .smartPlaylist
                
            } else {
                
                return .playlist
            }
        }()
        
        artworkImageView.artworkType = .empty(entityType: granularType, size: .small)
    }
}
