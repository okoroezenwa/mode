//
//  SmallePlaylistCollectionViewCell.swift
//  Melody
//
//  Created by Ezenwa Okoro on 13/11/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SmallPlaylistCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var nameLabel: MELLabel!
    @IBOutlet weak var songCountLabel: MELLabel!
    @IBOutlet weak var artworkContainer: UIView!
    @IBOutlet weak var containerView: UIView!
    
    override var isSelected: Bool {
        
        didSet {
            
            containerView.backgroundColor = (darkTheme ? .white : UIColor.black).withAlphaComponent(isSelected ? 0.1 : 0.05)
        }
    }
    
    override var isHighlighted: Bool {
        
        didSet {
            
            containerView.backgroundColor = (darkTheme ? .white : UIColor.black).withAlphaComponent(isHighlighted ? 0.1 : 0.05)
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        UniversalMethods.addShadow(to: artworkContainer, radius: 2, path: UIBezierPath.init(roundedRect: CGRect.init(x: 0, y: 0, width: 30, height: 30), cornerRadius: 4).cgPath)
    }
    
    @objc func prepare(with playlist: MPMediaPlaylist, count: Int) {
        
        if let title = playlist.name, title != "" {
            
            nameLabel.text = title
            
        } else {
            
            nameLabel.text = "Untitled Playlist"
        }
        
        let count = count
        
        songCountLabel.text = (appDelegate.formatter.numberFormatter.string(from: NSNumber.init(value: count)) ?? "\(count)") + " \(count == 1 ? "song" : "songs")"
        
        if playlist.playlistAttributes == .genius {
            
            artworkImageView.image = #imageLiteral(resourceName: "NoGeniusPlaylistSmall")
            
        } else if playlist.playlistAttributes == .smart {
            
            artworkImageView.image = #imageLiteral(resourceName: "NoSmartPlaylistSmall")
            
        } else {
            
            artworkImageView.image = #imageLiteral(resourceName: "NoPlaylistSmall")
        }
    }
}
