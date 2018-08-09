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
    @objc let notification: Notification = .init(name: .nowPlayingItemChanged, object: nil, userInfo: nil)

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
        
        if musicPlayer.nowPlayingItem == nil {
            
            timerBased?.timeSlider.setValue(0, animated: true)
        
        } else if !musicPlayer.isPlaying {
            
            timerBased?.updateTimes(setValue: true, seeking: false)
        }
        
        timerBased?.playPauseButton.addTarget(self, action: #selector(changePlaybackState), for: .touchUpInside)
        timerBased?.altPlayPauseButton??.addTarget(self, action: #selector(changePlaybackState), for: .touchUpInside)
        
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
        
        musicPlayer.isPlaying ? musicPlayer.pause() : musicPlayer.play()
        appDelegate.saveQueue()
    }
    
    @objc func stop(_ gr: UILongPressGestureRecognizer) {
        
        if gr.state == .began {
            
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
        notifier.post(name: .saveQueue, object: musicPlayer, userInfo: [String.queueItems: []])
        
        if #available(iOS 11.3, *) {
            
            musicPlayer.setQueue(with: .init(items: []))
            musicPlayer.prepareToPlay()
        }
    }
    
    deinit {
        
        unregisterAll(from: observers)
    }
}
