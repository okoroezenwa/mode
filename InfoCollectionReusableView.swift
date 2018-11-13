//
//  InfoCollectionReusableView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 19/05/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class InfoCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet var containerView: UIView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var artworkImageView: UIImageView!
    @IBOutlet var artworkContainer: UIView!
    @IBOutlet var titleButton: MELButton!
    @IBOutlet var alternateButton1: MELButton!
    @IBOutlet var alternateButton2: MELButton!
    @IBOutlet var alternateButton3: MELButton!
    @IBOutlet var addedLabel: MELLabel!
    @IBOutlet var playedLabel: MELLabel!
    @IBOutlet var genreButton: MELButton!
    @IBOutlet var compilationButton: MELButton!
    @IBOutlet var composerButton: MELButton!
    @IBOutlet var albumArtistButton: MELButton!
    @IBOutlet var copyrightLabel: MELLabel!
    @IBOutlet var lyricsTextView: MELTextView!
    @IBOutlet var groupingLabel: MELLabel!
    @IBOutlet var commentsLabel: MELLabel!
    @IBOutlet var durationLabel: MELLabel!
    @IBOutlet var trackLabel: MELLabel!
    @IBOutlet var playlistsButton: MELButton!
    @IBOutlet var playlistsActivityIndicator: MELActivityIndicatorView!
    @IBOutlet var playlistsBorderView: MELBorderView!
    @IBOutlet var queueStackView: UIStackView!
    @IBOutlet var explicitButton: MELButton!
    @IBOutlet var entityRatingStackView: UIStackView! {
        
        didSet {
            
            entityRatingStackView.addArrangedSubview(rateShareView)
        }
    }
    @IBOutlet var addedTitleLabel: MELLabel! // 'created' for playlists; 'last addition' for other collections
    @IBOutlet var playsTitleLabel: MELLabel! // 'total plays' for collections
    @IBOutlet var bpmLabel: MELLabel!
    @IBOutlet var skipsLabel: MELLabel!
    @IBOutlet var updatedLabel: MELLabel!
    @IBOutlet var skipsTitleLabel: MELLabel!
    @IBOutlet var scrollViews: [UIScrollView]!
    
    @objc let queueView = BorderedButtonView.with(title: "Queue...", image: #imageLiteral(resourceName: "AddSong10"), tapAction: nil)
    @objc let insertView = BorderedButtonView.with(title: "Insert...", image: #imageLiteral(resourceName: "AddToPlaylist10"), tapAction: nil)
    @objc let addToView = BorderedButtonView.with(title: "Add to...", image: #imageLiteral(resourceName: "AddNoBorderSmall"), tapAction: nil)
    @objc let rateShareView = RateShareView.instance()
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        layoutIfNeeded()
        
        [queueView, addToView, insertView].forEach({
            
//            $0.button.contentEdgeInsets.top = 5
            $0.borderViewTopConstraint.constant = 14
            $0.borderViewBottomConstraint.constant = 10
            
            queueStackView.addArrangedSubview($0)
        })
    }
}
