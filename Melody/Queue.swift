//
//  Queue.swift
//  Melody
//
//  Created by Ezenwa Okoro on 23/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import Foundation

class Queue {
    
    static let shared = Queue()
    
    private init() {
    
        notifier.addObserver(self, selector: #selector(updateIndex), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: musicPlayer)
        
        notifier.addObserver(self, selector: #selector(saveQueue(with:)), name: .saveQueue, object: musicPlayer)
    }
    
    @objc func saveQueue(with notification: Notification) {
        
        guard !useSystemPlayer, #available(iOS 10.3, *), let _ = musicPlayer as? MPMusicPlayerApplicationController, let queue = notification.userInfo?[String.queueItems] as? [MPMediaItem] else { return }
        
        var finalQueue: [MPMediaItem] {
            
            if queue.isEmpty.inverted, forceOldStyleQueue, let data = prefs.object(forKey: .queueItems) as? Data, let items = NSKeyedUnarchiver.unarchiveObject(with: data) as? [MPMediaItem], items.isEmpty.inverted {
                
                return items + queue
            }
            
            return queue
        }
        
        let savedData = NSKeyedArchiver.archivedData(withRootObject: finalQueue)
        prefs.set(savedData, forKey: .queueItems)
        prefs.set(musicPlayer.repeatMode.rawValue, forKey: .repeatMode)
    }
    
    @objc func updateIndex() {
        
        guard !useSystemPlayer, #available(iOS 10.3, *), let _ = musicPlayer as? MPMusicPlayerApplicationController, let index = musicPlayer.nowPlayingItemIndex else { return }
        
        prefs.set(index, forKey: .indexOfNowPlayingItem)
        prefs.set(musicPlayer.currentPlaybackTime, forKey: .currentPlaybackTime)
    }
    
    func verifyQueue() {
        
        guard !useSystemPlayer, #available(iOS 10.3, *), let musicPlayer = musicPlayer as? MPMusicPlayerApplicationController, musicPlayer.nowPlayingItem == nil else {
            
            appDelegate.saveQueue()
            
            if #available(iOS 10.3, *), !useSystemPlayer {
                
                MPMusicPlayerController.applicationQueuePlayer.perform(queueTransaction: { _ in }, completionHandler: { controller, _ in notifier.post(name: .saveQueue, object: nil, userInfo: [String.queueItems: controller.items]) })
            }
            
            return
        }
        
        guard let data = prefs.object(forKey: .queueItems) as? Data, let queue = NSKeyedUnarchiver.unarchiveObject(with: data) as? [MPMediaItem], !queue.isEmpty else { return }
        
        let index = prefs.integer(forKey: .indexOfNowPlayingItem)
        let time = prefs.double(forKey: .currentPlaybackTime)
        
        musicPlayer.repeatMode = MPMusicRepeatMode.init(rawValue: prefs.integer(forKey: .repeatMode)) ?? .none
        
        if useDescriptor {
            
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor.init(itemCollection: .init(items: queue))
            descriptor.startItem = queue[index < queue.count ? index : 0]
            
            musicPlayer.setQueue(with: descriptor)
        
        } else {
            
            musicPlayer.setQueue(with: .init(items: queue))
        }
        
        musicPlayer.nowPlayingItem = queue[index < queue.count ? index : 0]
        musicPlayer.currentPlaybackTime = time
        musicPlayer.prepareToPlay()

        if #available(iOS 11.3, *) { musicPlayer.pause() }
        
        musicPlayer.currentPlaybackTime = time
        musicPlayer.currentPlaybackTime = time
        musicPlayer.currentPlaybackTime = time
        prefs.set(time, forKey: .currentPlaybackTime)
        NowPlaying.shared.registered.forEach({ $0?.updateTimes(setValue: true, seeking: false )})
    }
}
