//
//  InfoCollectionReusableView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 19/05/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class InfoCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var artworkContainer: UIView!
    @IBOutlet weak var titleButton: MELButton!
    @IBOutlet weak var alternateButton1: MELButton!
    @IBOutlet weak var alternateButton2: MELButton!
    @IBOutlet weak var alternateButton3: MELButton!
    @IBOutlet weak var addedLabel: MELLabel!
    @IBOutlet weak var playedLabel: MELLabel!
    @IBOutlet weak var genreButton: MELButton!
    @IBOutlet weak var compilationButton: MELButton!
    @IBOutlet weak var composerButton: MELButton!
    @IBOutlet weak var albumArtistButton: MELButton!
    @IBOutlet weak var copyrightLabel: MELLabel!
    @IBOutlet weak var lyricsTextView: MELTextView!
    @IBOutlet weak var groupingLabel: MELLabel!
    @IBOutlet weak var commentsLabel: MELLabel!
    @IBOutlet weak var durationLabel: MELLabel!
    @IBOutlet weak var trackLabel: MELLabel!
    @IBOutlet weak var playlistsButton: MELButton!
    @IBOutlet weak var playlistsActivityIndicator: MELActivityIndicatorView!
    @IBOutlet weak var playlistsBorderView: MELBorderView!
    @IBOutlet weak var queueStackView: UIStackView!
    @IBOutlet weak var explicitButton: MELButton!
    @IBOutlet weak var entityRatingStackView: UIStackView! {
        
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
    
    @objc let queueView = BorderedButtonView.with(title: "Queue...", image: #imageLiteral(resourceName: "AddSong10"), action: nil, target: nil)
    @objc let insertView = BorderedButtonView.with(title: "Insert...", image: #imageLiteral(resourceName: "AddToPlaylist10"), action: nil, target: nil)
    @objc let addToView = BorderedButtonView.with(title: "Add to...", image: #imageLiteral(resourceName: "AddNoBorderSmall"), action: nil, target: nil)
    @objc let rateShareView = RateShareView.instance()
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        layoutIfNeeded()
        
        [queueView, addToView, insertView].forEach({
            
            $0.button.contentEdgeInsets.top = 5
            $0.borderViewTopConstraint.constant = 14
            $0.borderViewBottomConstraint.constant = 10
            
            queueStackView.addArrangedSubview($0)
        })
    }
}
