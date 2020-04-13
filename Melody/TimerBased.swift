//
//  TimerBased.swift
//  Mode
//
//  Created by Ezenwa Okoro on 16/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

@objc protocol TimerBased {
    
    var startTime: MELLabel! { get set }
    var stopTime: MELLabel! { get set }
    var playPauseButton: MELButton! { get set }
    var timeSlider: MELSlider! { get set }
    var playingImage: UIImage { get }
    var pausedImage: UIImage { get }
    var playPauseButtonNeedsAnimation: Bool { get }
    @objc optional var playingInset: CGFloat { get }
    @objc optional var pausedInset: CGFloat { get }
    @objc optional var shuffle: MELButton? { get set }
    @objc optional var repeatButton: MELButton? { get set }
    @objc optional var repeatView: MELBorderView? { get set }
    @objc optional var shuffleView: MELBorderView? { get set }
    @objc optional var prefersBoldOnTap: Bool { get }
    @objc optional var playButtonLabel: MELLabel? { get set }
//    @objc optional var queueButtonLabel: MELLabel! { get set }
}

extension TimerBased {
    
    func updateTimes(for item: MPMediaItem? = musicPlayer.nowPlayingItem, to time: TimeInterval = musicPlayer.currentPlaybackTime, setValue: Bool, seeking: Bool) {
        
        if let item = item {
            
            startTime.text = seeking ? TimeInterval(timeSlider.value).nowPlayingRepresentation : time.nowPlayingRepresentation
            stopTime.text = (TimeInterval(seeking ? TimeInterval(timeSlider.value) : time) - item.playbackDuration).nowPlayingRepresentation
            
            if setValue {
                
                timeSlider.setValue(Float(time), animated: false)
            }
            
            if musicPlayer.isPlaying && musicPlayer.currentPlaybackTime < 5 {
                
                modifyPlayPauseButton()
            }
            
        } else {
            
            timeSlider.setValue(0, animated: false)
        }
    }
    
    func modifyPlayPauseButton(setImageOnly: Bool = false) {
        
        let image: UIImage = {
            
            guard musicPlayer.playbackState != .interrupted else { return pausedImage }
            
            return musicPlayer.isPlaying ? playingImage : pausedImage
        }()
            
        playPauseButton.setImage(image, for: .normal)
        
        if setImageOnly { return }
        
        playButtonLabel??.text = {

            if let _ = musicPlayer.nowPlayingItem {

                return musicPlayer.isPlaying ? "Playing" : "Paused"

            } else {

                return "Stopped"
            }
        }()
        
        playPauseButton.imageEdgeInsets.left = musicPlayer.isPlaying ? playingInset ?? 0 : pausedInset ?? 0
        
        if playPauseButtonNeedsAnimation {
            
            UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .allowUserInteraction, animations: { self.playPauseButton.superview?.layoutIfNeeded() }, completion: nil)
        }
    }
    
    func modifyRepeatButton(changingMusicPlayer: Bool) {
        
        let duration = changingMusicPlayer ? 0.3 : 0
        
        switch musicPlayer.repeatMode {
            
            case .one:
                
                UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
                    
                    if let _ = self as? UITableViewCell { } else {
                        
                        self.repeatButton??.reversed = changingMusicPlayer.inverted
                        self.repeatButton??.changeThemeColor()
                    }
                    
                    self.repeatView??.alpha = changingMusicPlayer ? 0 : 1
                    
                }, completion: nil)
                
                if let repeatButton = repeatButton ?? nil {
                    
                    UIView.transition(with: repeatButton, duration: duration, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
                        
                        repeatButton.setImage(changingMusicPlayer ? #imageLiteral(resourceName: "Repeat") : #imageLiteral(resourceName: self.prefersBoldOnTap == true ? "RepeatOneBold" : "RepeatOne"), for: .normal)
                        
                        if self.prefersBoldOnTap == true {
                            
                            repeatButton.fontWeight = (changingMusicPlayer ? FontWeight.regular : .semibold).rawValue
                        }
                        
                    }, completion: nil)
                }
                
                if changingMusicPlayer {
                    
                    musicPlayer.repeatMode = .none
                }
                
            case .all:
                
                UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
                    
                    if let _ = self as? UITableViewCell { } else {
                        
                        self.repeatButton??.reversed = true
                        self.repeatButton??.changeThemeColor()
                    }
                    
                    self.repeatView??.alpha = 1
                        
                }, completion: nil)
                
                if let repeatButton = repeatButton ?? nil {
                    
                    UIView.transition(with: repeatButton, duration: duration, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
                        
                        repeatButton.setImage(changingMusicPlayer ? #imageLiteral(resourceName: self.prefersBoldOnTap == true ? "RepeatOneBold" : "RepeatOne") : #imageLiteral(resourceName: self.prefersBoldOnTap == true ? "RepeatBold" : "Repeat"), for: .normal)
                        
                        if self.prefersBoldOnTap == true {
                            
                            repeatButton.fontWeight = FontWeight.semibold.rawValue
                        }
                        
                    }, completion: nil)
                }
                
                if changingMusicPlayer {
                    
                    musicPlayer.repeatMode = .one
                }
                
            case .none, .default:
                
                UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
                    
                    if let _ = self as? UITableViewCell { } else {
                        
                        self.repeatButton??.reversed = changingMusicPlayer
                        self.repeatButton??.changeThemeColor()
                    }
                    
                    self.repeatView??.alpha = changingMusicPlayer.inverted ? 0 : 1
                    
                }, completion: nil)
                
                if let repeatButton = repeatButton ?? nil {
                    
                    UIView.transition(with: repeatButton, duration: duration, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
                        
                        repeatButton.setImage(#imageLiteral(resourceName: self.prefersBoldOnTap == true && changingMusicPlayer ? "RepeatBold" : "Repeat"), for: .normal)
                        
                        if self.prefersBoldOnTap == true {
                            
                            repeatButton.fontWeight = (changingMusicPlayer ? FontWeight.semibold : .regular).rawValue
                        }
                        
                    }, completion: nil)
                }
                
                if changingMusicPlayer {
                    
                    musicPlayer.repeatMode = .all
                }
            
            @unknown default: break
        }
        
        if changingMusicPlayer {
            
            prefs.set(musicPlayer.repeatMode.rawValue, forKey: .repeatMode)
        }
    }
    
    func modifyShuffleState(changingMusicPlayer: Bool) {
        
        let duration = changingMusicPlayer ? 0.3 : 0
        
        switch musicPlayer.shuffleMode {
            
            case .default, .off:
                
                UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
                    
                    if let _ = self as? UITableViewCell { } else {
                        
                        self.shuffle??.reversed = changingMusicPlayer
                        self.shuffle??.changeThemeColor()
                    }
                    
                    self.shuffleView??.alpha = changingMusicPlayer ? 1 : 0
                        
                }, completion: nil)
                
                if prefersBoldOnTap == true, let shuffle = shuffle ?? nil {
                    
                    UIView.transition(with: shuffle, duration: duration, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
                        
                        shuffle.fontWeight = (changingMusicPlayer ? FontWeight.semibold : .regular).rawValue
                        shuffle.setImage(#imageLiteral(resourceName: changingMusicPlayer ? "ShuffleBold" : "Shuffle"), for: .normal)
                        
                    }, completion: nil)
                }
                
                if changingMusicPlayer {
                    
                    musicPlayer.shuffleMode = .songs
                }
            
            case .albums, .songs:
                
                UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: {
                    
                    if let _ = self as? UITableViewCell { } else {
                        
                        self.shuffle??.reversed = changingMusicPlayer.inverted
                        self.shuffle??.changeThemeColor()
                    }
                    
                    self.shuffleView??.alpha = changingMusicPlayer ? 0 : 1
                    
                }, completion: nil)
                
                if prefersBoldOnTap == true, let shuffle = shuffle ?? nil {
                    
                    UIView.transition(with: shuffle, duration: duration, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
                        
                        shuffle.fontWeight = (changingMusicPlayer ? FontWeight.regular : .semibold).rawValue
                        shuffle.setImage(#imageLiteral(resourceName: changingMusicPlayer ? "Shuffle" : "ShuffleBold"), for: .normal)
                        
                    }, completion: nil)
                }
                
                if changingMusicPlayer {
                    
                    musicPlayer.shuffleMode = .off
                }
        
            @unknown default: break
        }
    }
}
