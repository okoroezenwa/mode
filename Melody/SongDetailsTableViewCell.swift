//
//  SongDetailsTableViewCell.swift
//  Melody
//
//  Created by Ezenwa Okoro on 05/05/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SongDetailsTableViewCell: UITableViewCell {
    
    @IBOutlet var typeImageView: MELImageView!
    @IBOutlet var label: MELLabel!
    @IBOutlet var checkImageView: MELImageView!

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        selectedBackgroundView = MELBorderView.init()
        
        preservesSuperviewLayoutMargins = false
        contentView.preservesSuperviewLayoutMargins = false
    }

    func prepare(for detail: SecondaryCategory, visible: Bool) {
        
        let details: (text: String, image: UIImage) = {
            
            switch detail {
                
                case .dateAdded: return ("Date Added", #imageLiteral(resourceName: "DateAdded14"))
                    
                case .fileSize: return ("Size", #imageLiteral(resourceName: "FileSize14"))
                    
                case .genre: return ("Genre", #imageLiteral(resourceName: "Genre14"))
                    
                case .lastPlayed: return ("Last Played", #imageLiteral(resourceName: "LastPlayed14"))
                    
                case .loved: return ("Affinity", #imageLiteral(resourceName: "NoLove14"))
                    
                case .plays: return ("Plays", #imageLiteral(resourceName: "Plays14"))
                    
                case .rating: return ("Rating", #imageLiteral(resourceName: "Star14"))
                    
                case .year: return ("Year", #imageLiteral(resourceName: "Year14"))
            }
        }()
        
        label.text = details.text
        typeImageView.image = details.image
        
        checkImageView.isHidden = !visible
    }
}
