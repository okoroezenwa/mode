//
//  NowPlaying.swift
//  Melody
//
//  Created by Ezenwa Okoro on 19/01/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class NowPlaying: NSObject {

    @objc var item: MPMediaItem? { return musicPlayer.nowPlayingItem }
    @objc var observers = Set<NSObject>()
    @objc let notification: Notification = .init(name: .nowPlayingItemChanged, object: musicPlayer, userInfo: useSystemPlayer ? nil : [.queueChange: true])

    @objc var timer: Timer?
    @objc var nowPlayingVC: TimerBased? { didSet { prepare(nowPlayingVC) } }
    @objc var container: TimerBased? { didSet { prepare(container) } }
    @objc var cell: TimerBased? { didSet { prepare(cell) } }
    
    var registered: [TimerBased?] { return [cell, container, nowPlayingVC] }
    
    @objc static let shared = NowPlaying()
    
    private override init() {
        
        super.init()
        
        modifyTimerForNotification()
        
        observers.insert(notifier.addObserver(forName: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            notifier.post(weakSelf.notification)
            weakSelf.modifyTimerForNotification()
        
        }) as! NSObject)
        
        observers.insert(notifier.addObserver(forName: UIApplication.willEnterForegroundNotification, object: UIApplication.shared, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
        
            notifier.post(weakSelf.notification)
            weakSelf.modifyTimerForNotification()
            
        }) as! NSObject)
        
        observers.insert(notifier.addObserver(forName: .MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer, queue: nil, using: { [weak self] _ in
            
            self?.modifyTimerForNotification()
            self?.registered.forEach({ $0?.modifyPlayPauseButton() })
            
            if musicPlayer.playbackState == .stopped {
                
                UniversalMethods.performOnMainThread({ self?.modifyTimerForNotification() }, afterDelay: 0.3)
            }
            
        }) as! NSObject)
        
        observers.insert(notifier.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: UIApplication.shared, queue: nil, using: { [weak self] _ in
        
            self?.invalidateTimer()
        
        }) as! NSObject)
        
        observers.insert(notifier.addObserver(forName: UIApplication.didBecomeActiveNotification, object: UIApplication.shared, queue: nil, using: { [weak self] _ in
            
            guard let weakSelf = self else { return }
            
            UniversalMethods.performOnMainThread({ weakSelf.registered.forEach({ $0?.modifyPlayPauseButton() }) }, afterDelay: 1)
            
        }) as! NSObject)
    }
    
    @objc func prepare(_ timerBased: TimerBased?) {
        
//        timerBased?.timeSlider.addTarget(self, action: #selector(beginSlideSeek), for: .touchDown)
        timerBased?.timeSlider.addTarget(self, action: #selector(slideSeek), for: .valueChanged)
        timerBased?.timeSlider.addTarget(self, action: #selector(commitToSeek(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        if timerBased is ContainerViewController, forceOldStyleQueue.inverted && !useSystemPlayer { } else if musicPlayer.nowPlayingItem == nil {
            
            timerBased?.timeSlider.setValue(0, animated: true)
        
        } else if !musicPlayer.isPlaying {
            
            timerBased?.updateTimes(setValue: true, seeking: false)
        }
        
        timerBased?.playPauseButton.addTarget(self, action: #selector(changePlaybackState), for: .touchUpInside)
        timerBased?.altPlayPauseButton??.addTarget(self, action: #selector(changePlaybackState), for: .touchUpInside)
        
        timerBased?.shuffle??.addTarget(self, action: #selector(changeShuffle(_:)), for: .touchUpInside)
        timerBased?.repeatButton??.addTarget(self, action: #selector(setRepeatMode(_:)), for: .touchUpInside)
        
        let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(stop(_:)))
        gr.minimumPressDuration = 1.0
        timerBased?.playPauseButton.addGestureRecognizer(gr)
        
        timerBased?.altPlayPauseButton??.addGestureRecognizer({
            
            let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(stop(_:)))
            gr.minimumPressDuration = 1.0
            
            return gr
        }())
    }
    
    @objc func setTimer() {
        
        invalidateTimer()
        timer = .scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer(_:)), userInfo: nil, repeats: true)
    }
    
    @objc func invalidateTimer() {
        
        timer?.invalidate()
        timer = nil
    }
    
    @objc func modifyTimerForNotification() {
        
        if musicPlayer.isPlaying {
            
            setTimer()
            
        } else {
            
            if musicPlayer.nowPlayingItem == nil {
                
                invalidateTimer()
            }
            
            registered.forEach({ $0?.updateTimes(setValue: true, seeking: false) })
        }
    }
    
    @objc func updateTimer(_ timer: Timer) {
        
        if let _ = musicPlayer.nowPlayingItem {
            
            registered.forEach({ $0?.updateTimes(setValue: true, seeking: false) })
            
        } else {
            
            registered.forEach({ $0?.timeSlider.setValue(0, animated: true) })
        }
    }
    
//    @objc func beginSlideSeek() {
//
//        invalidateTimer()
//    }
    
    @objc func slideSeek() {
        
        invalidateTimer()
        registered.forEach({ $0?.updateTimes(setValue: false, seeking: true) })
    }
    
    @objc func commitToSeek(_ slider: UISlider) {
        
        musicPlayer.currentPlaybackTime = TimeInterval(slider.value)
        registered.forEach({ $0?.updateTimes(setValue: true, seeking: false) })
        setTimer()
    }
    
    @objc func changePlaybackState() {
        
        if musicPlayer.nowPlayingItem == nil {
            
            let playAll = UIAlertAction.init(title: "Play All", style: .default, handler: { _ in appDelegate.perform(.playAll) })
            
            let shuffleSongs = UIAlertAction.init(title: "Shuffle Songs", style: .default, handler: { _ in appDelegate.perform(.shuffleSongs) })
            
            let shuffleAlbums = UIAlertAction.init(title: "Shuffle Albums", style: .default, handler: { _ in appDelegate.perform(.shuffleAlbums) })
            
            topViewController?.present(UIAlertController.withTitle(nil, message: nil, style: .actionSheet, actions: playAll, shuffleSongs, shuffleAlbums, .cancel()), animated: true, completion: nil)
            
            return
        }
        
        musicPlayer.isPlaying ? musicPlayer.pause() : musicPlayer.play()
        Queue.shared.updateIndex(self)
    }
    
    @objc func stop(_ gr: UILongPressGestureRecognizer) {
        
        if gr.state == .began, musicPlayer.nowPlayingItem != nil {
            
            topVC(startingFrom: appDelegate.window?.rootViewController)?
                .guardQueue(using:
                    .withTitle(nil,
                               message: nil,
                               style: .actionSheet,
                               actions: .stop, .cancel()),
                            onCondition: warnForQueueInterruption && stopGuard,
                            fallBack: stopPlayback)
        }
    }
    
    @objc func stopPlayback() {
        
        useAlternateAnimation = true
        shouldReturnToContainer = true
        musicPlayer.stop()
        Queue.shared.updateCurrentQueue(with: [], startingItem: nil, shouldUpdateIndex: false)
        
        if #available(iOS 11.3, *) {
            
            musicPlayer.setQueue(with: .init(items: []))
            musicPlayer.prepareToPlay()
            
            if !useSystemPlayer {
                
                notifier.post(name: .playbackStopped, object: nil)
            }
        }
    }
    
    @objc func setRepeatMode(_ sender: MELButton) {
        
        for timerBased in registered {
            
            if sender == timerBased?.repeatButton {
                
                timerBased?.modifyRepeatButton(changingMusicPlayer: true)
            
            } else {
                
                timerBased?.modifyRepeatButton(changingMusicPlayer: false)
            }
        }
    }
    
    @objc func changeShuffle(_ sender: MELButton) {
        
        for timerBased in registered {
            
            if sender == timerBased?.shuffle {
                
                timerBased?.modifyShuffleState(changingMusicPlayer: true)
                
            } else {
                
                timerBased?.modifyShuffleState(changingMusicPlayer: false)
            }
        }
        
        notifier.post(name: .shuffleInvoked, object: nil)
        
        if #available(iOS 11.3, *) {
            
            UniversalMethods.performOnMainThread({ notifier.post(name: .shuffleInvoked, object: nil) }, afterDelay: 1)
        }
        
        if #available(iOS 10.3, *), !useSystemPlayer, let musicPlayer = musicPlayer as? MPMusicPlayerApplicationController {
            
            musicPlayer.perform(queueTransaction: { _ in }, completionHandler: { controller, _ in Queue.shared.updateCurrentQueue(with: controller.items, startingItem: musicPlayer.nowPlayingItem, shouldUpdateIndex: false) })
        }
    }
    
    deinit {
        
        unregisterAll(from: observers)
    }
}
