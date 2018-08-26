//
//  TimerBased.swift
//  Mode
//
//  Created by Ezenwa Okoro on 16/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

@objc protocol TimerBased {
    
    @objc optional var startTime: MELLabel? { get set }
    @objc optional var stopTime: MELLabel? { get set }
    var playPauseButton: MELButton! { get set }
    var timeSlider: MELSlider! { get set }
    var playingImage: UIImage { get }
    var pausedImage: UIImage { get }
    var playPauseButtonNeedsAnimation: Bool { get }
    @objc optional var playingInset: CGFloat { get }
    @objc optional var altPlayPauseButton: MELButton? { get set }
    @objc optional var pausedInset: CGFloat { get }
    @objc optional var shuffle: MELButton? { get set }
    @objc optional var repeatButton: MELButton? { get set }
    @objc optional var repeatView: MELBorderView? { get set }
    @objc optional var shuffleView: MELBorderView? { get set }
    @objc optional var prefersBoldOnTap: Bool { get }
}

extension TimerBased {
    
    func updateTimes(setValue: Bool, seeking: Bool) {
        
        if let nowPlaying = musicPlayer.nowPlayingItem {
            
            startTime??.text = seeking ? TimeInterval(timeSlider.value).nowPlayingRepresentation : musicPlayer.currentPlaybackTime.nowPlayingRepresentation
            stopTime??.text = (TimeInterval(seeking ? TimeInterval(timeSlider.value) : musicPlayer.currentPlaybackTime) - nowPlaying.playbackDuration).nowPlayingRepresentation
            
            if setValue {
                
                timeSlider.setValue(Float(musicPlayer.currentPlaybackTime), animated: true)
            }
            
            if musicPlayer.isPlaying && musicPlayer.currentPlaybackTime < 5 {
                
                modifyPlayPauseButton()
            }
            
        } else {
            
            timeSlider.setValue(0, animated: true)
        }
    }
    
    func modifyPlayPauseButton() {
        
        let image: UIImage = {
            
            guard musicPlayer.playbackState != .interrupted else { return pausedImage }
            
            return musicPlayer.isPlaying ? playingImage : pausedImage
        }()
        
        playPauseButton.setImage(image, for: .normal)
        playPauseButton.imageEdgeInsets.left = musicPlayer.isPlaying ? playingInset ?? 0 : pausedInset ?? 0
        altPlayPauseButton??.setImage(musicPlayer.isPlaying ? #imageLiteral(resourceName: "PauseFilled17") : #imageLiteral(resourceName: "PlayFilled17"), for: .normal)
        
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            
            if self.playPauseButtonNeedsAnimation {
                
                self.playPauseButton.superview?.layoutIfNeeded()
            }
            
            self.altPlayPauseButton??.superview?.layoutIfNeeded()
            
        }, completion: nil)
    }
    
    func modifyRepeatButton(changingMusicPlayer: Bool) {
        
        switch musicPlayer.repeatMode {
            
        case .one:
            
            repeatView??.isHidden = changingMusicPlayer
            repeatButton??.setImage(changingMusicPlayer ? #imageLiteral(resourceName: "Repeat") : #imageLiteral(resourceName: prefersBoldOnTap == true ? "RepeatOneBold" : "RepeatOne"), for: .normal)
            
            if prefersBoldOnTap == true {
                
                repeatButton??.titleLabel?.font = UIFont.myriadPro(ofWeight: changingMusicPlayer ? .regular : .semibold, size: 17)
            }
            
            if changingMusicPlayer {
                
                musicPlayer.repeatMode = .none
            }
            
        case .all:
            
            repeatView??.isHidden = false
            repeatButton??.setImage(changingMusicPlayer ? #imageLiteral(resourceName: prefersBoldOnTap == true ? "RepeatOneBold" : "RepeatOne") : #imageLiteral(resourceName: prefersBoldOnTap == true ? "RepeatBold" : "Repeat"), for: .normal)
            
            if prefersBoldOnTap == true {
                
                repeatButton??.titleLabel?.font = UIFont.myriadPro(ofWeight: .semibold, size: 17)
            }
            
            if changingMusicPlayer {
                
                musicPlayer.repeatMode = .one
            }
            
        case .none, .default:
            
            repeatView??.isHidden = !changingMusicPlayer
            repeatButton??.setImage(#imageLiteral(resourceName: prefersBoldOnTap == true && changingMusicPlayer ? "RepeatBold" : "Repeat"), for: .normal)
            
            if prefersBoldOnTap == true {
                
                repeatButton??.titleLabel?.font = UIFont.myriadPro(ofWeight: changingMusicPlayer ? .semibold : .regular, size: 17)
            }
            
            if changingMusicPlayer {
                
                musicPlayer.repeatMode = .all
            }
        }
        
        if changingMusicPlayer {
            
            prefs.set(musicPlayer.repeatMode.rawValue, forKey: .repeatMode)
        }
    }
    
    func modifyShuffleState(changingMusicPlayer: Bool) {
        
        switch musicPlayer.shuffleMode {
            
            case .default, .off:
                
                shuffleView??.isHidden = !changingMusicPlayer
                
                if prefersBoldOnTap == true {
                    
                    shuffle??.titleLabel?.font = UIFont.myriadPro(ofWeight: changingMusicPlayer ? .semibold : .regular, size: 17)
                    shuffle??.setImage(#imageLiteral(resourceName: changingMusicPlayer ? "ShuffleBold" : "Shuffle"), for: .normal)
                }
                
                if changingMusicPlayer {
                    
                    musicPlayer.shuffleMode = .songs
                }
            
            case .albums, .songs:
                
                shuffleView??.isHidden = changingMusicPlayer
                
                if prefersBoldOnTap == true {
                    
                    shuffle??.titleLabel?.font = UIFont.myriadPro(ofWeight: changingMusicPlayer ? .regular : .semibold, size: 17)
                    shuffle??.setImage(#imageLiteral(resourceName: changingMusicPlayer ? "Shuffle" : "ShuffleBold"), for: .normal)
                }
                
                if changingMusicPlayer {
                    
                    musicPlayer.shuffleMode = .off
                }
        }
    }
}
