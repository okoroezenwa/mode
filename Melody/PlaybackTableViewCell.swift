//
//  PlaybackTableViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 15/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PlaybackTableViewCell: UITableViewCell, TimerBased {
    
    @IBOutlet var playPauseButton: MELButton!
    @IBOutlet var startTime: MELLabel!
    @IBOutlet var stopTime: MELLabel!
    @IBOutlet var timeSlider: MELSlider!
    @IBOutlet var shuffle: MELButton?
    @IBOutlet var repeatButton: MELButton?
    
    let playingImage = #imageLiteral(resourceName: "PauseFilled14")
    let pausedImage = #imageLiteral(resourceName: "PlayFilled")
    let pausedInset: CGFloat = 3
    let playingInset: CGFloat = 0
    let playPauseButtonNeedsAnimation = true
    let prefersBoldOnTap = true

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        modifyPlayPauseButton()
        updateSpacing()
        
        notifier.addObserver(self, selector: #selector(updateSpacing), name: .lineHeightsCalculated, object: nil)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func updateSliderDuration() {
        
        if let nowPlaying = musicPlayer.nowPlayingItem {
            
            timeSlider.minimumValue = 0
            timeSlider.maximumValue = Float(nowPlaying.playbackDuration)
        }
    }
    
    @objc func updateSpacing() {
        
        repeatButton?.titleEdgeInsets.top = FontManager.shared.buttonInset
        shuffle?.titleEdgeInsets.top = FontManager.shared.buttonInset
    }
}
