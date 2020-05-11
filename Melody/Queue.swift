
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
    var currentQueue = [MPMediaItem]()
    var plays = [MPMediaEntityPersistentID: Int]()
    var queueCount: Int { return useSystemPlayer ? musicPlayer.queueCount() : currentQueue.count }
    var indexOfNowPlayingItem: Int?
    var hasSetupApplicationPlayer = false
    var queueWasModifiedWhileInBackground = false // likely will be used if Siri Shortcuts are added.
    var indexToUse: Int? {
        
        if useSystemPlayer {
            
            return musicPlayer.nowPlayingItemIndex
            
        } else {
            
            return musicPlayer.nowPlayingItemIndex == indexOfNowPlayingItem ? musicPlayer.nowPlayingItemIndex : (indexOfNowPlayingItem == nil && musicPlayer.nowPlayingItemIndex != nil ? musicPlayer.nowPlayingItemIndex : indexOfNowPlayingItem)
        }
    }
    
    enum RemovalCompletion { case none(completion: EmptyCompletion), placeAfter(item: MPMediaItem?, completion: EmptyCompletion) }
    
    private init() {
    
        notifier.addObserver(self, selector: #selector(updateIndex), name: .nowPlayingItemChanged, object: nil)
        notifier.addObserver(self, selector: #selector(saveQueue), name: .saveQueue, object: nil)
        notifier.addObserver(self, selector: #selector(verifyQueue), name: .playerChanged, object: nil)
    }
    
    func remove(_ items: [MPMediaItem], completion: RemovalCompletion) {
        
        currentQueue.removeAll(where: { Set(items).contains($0) })
        
        switch completion {
            
            case .none(completion: let completionBlock):
                
                performQueueModificationCompletion()
                completionBlock()
            
            case .placeAfter(item: let item, completion: let completionBlock): place(items, after: item, verifyDuplicates: false, completion: completionBlock)
        }
    }
    
    func place(_ items: [MPMediaItem], after item: MPMediaItem?, verifyDuplicates verify: Bool = true, removeAfterPlayback: Bool = false, completion: EmptyCompletion) {
        
        if verify {
        
            currentQueue.removeAll(where: { Set(items).contains($0) })
        }
        
        let index: Int = {
            
            if let index = currentQueue.firstIndex(where: { $0 == item }) {
                
                return currentQueue.index(after: index)
            }
            
            return 0
        }()
        
        currentQueue.insert(contentsOf: items, at: index)
        performQueueModificationCompletion()
        
        completion()
    }
    
    func clearAllButNowPlaying(completion: EmptyCompletion?) {
        
        currentQueue = [musicPlayer.nowPlayingItem].compactMap({ $0 })
        performQueueModificationCompletion()
        
        completion?()
    }
    
    func performQueueModificationCompletion(with item: MPMediaItem? = musicPlayer.nowPlayingItem, shouldUpdateIndex: Bool = true) {
        
        indexOfNowPlayingItem = item == nil ? nil : (currentQueue.firstIndex(where: { $0 == item }) ?? 0)
        saveQueue()
        
        if shouldUpdateIndex {
            
            updateIndex(self)
        }
    }
    
    @objc func saveQueue() {
        
        guard !useSystemPlayer, #available(iOS 10.3, *), let _ = musicPlayer as? MPMusicPlayerApplicationController else { return }
        
        let savedData = NSKeyedArchiver.archivedData(withRootObject: currentQueue)
        prefs.set(savedData, forKey: .queueItems)
    }
    
    @objc func updateIndex(_ sender: Any) {
        
        guard !useSystemPlayer, #available(iOS 10.3, *), let _ = musicPlayer as? MPMusicPlayerApplicationController else { return }
        
        if queueWasModifiedWhileInBackground.inverted, sender is Notification {
        
            indexOfNowPlayingItem = currentQueue.firstIndex(where: { $0 == musicPlayer.nowPlayingItem })
            
            notifier.post(name: .indexUpdated, object: musicPlayer, userInfo: [.queueChange: true])
        }
        
        prefs.set(musicPlayer.currentPlaybackTime, forKey: .currentPlaybackTime)
        prefs.set(musicPlayer.repeatMode.rawValue, forKey: .repeatMode)
        
        if let index = indexToUse {
            
            prefs.set(index, forKey: .indexOfNowPlayingItem)
        }
    }
    
    func updateCurrentQueue(with items: [MPMediaItem], startingItem item: MPMediaItem?, shouldUpdateIndex: Bool = true) {
        
        guard !useSystemPlayer, #available(iOS 10.3, *), let _ = musicPlayer as? MPMusicPlayerApplicationController else { return }
        
        currentQueue = items
        performQueueModificationCompletion(with: item, shouldUpdateIndex: shouldUpdateIndex)
    }
    
    @objc func verifyQueue() {
        
        guard hasSetupApplicationPlayer.inverted, !useSystemPlayer, #available(iOS 10.3, *), let musicPlayer = musicPlayer as? MPMusicPlayerApplicationController else { return }
        
        guard musicPlayer.nowPlayingItem == nil else {
            
            updateIndex(self)
            
            MPMusicPlayerController.applicationQueuePlayer.perform(queueTransaction: { _ in }, completionHandler: { controller, _ in self.updateCurrentQueue(with: controller.items, startingItem: controller.items.value(at: prefs.integer(forKey: .indexOfNowPlayingItem))) })
            
            return
        }
        
        guard let data = prefs.object(forKey: .queueItems) as? Data, let queue: [MPMediaItem] = {
            
            if let items = NSKeyedUnarchiver.unarchiveObject(with: data) as? [MPMediaItem] {
                
                currentQueue = items//.map({ QueueItem.init(shouldRemoveAfterPlayback: false, item: $0) })
                
                return items
                
            }/* else if let items = NSKeyedUnarchiver.unarchiveObject(with: data) as? [QueueItem] {
                
                currentQueue = items
                
                return items.map({ $0.item })
            }*/
            
            return nil
            
        }(), !queue.isEmpty else { return }
        
        let index = prefs.integer(forKey: .indexOfNowPlayingItem)
        let time = prefs.double(forKey: .currentPlaybackTime)
        
        indexOfNowPlayingItem = index
        
        musicPlayer.repeatMode = MPMusicRepeatMode.init(rawValue: prefs.integer(forKey: .repeatMode)) ?? .none
        
        if useDescriptor {
            
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor.init(itemCollection: .init(items: queue))
            
            musicPlayer.setQueue(with: descriptor)
        
        } else {
            
            musicPlayer.setQueue(with: .init(items: queue))
        }
        
        let item = queue[index < queue.count ? index : 0]
        
        NowPlaying.shared.nowPlayingItem = item
        plays[item.persistentID] = item.playCount
        musicPlayer.nowPlayingItem = item
        musicPlayer.prepareToPlay()
        
        UniversalMethods.performOnMainThread({
            
            musicPlayer.currentPlaybackTime = time
            NowPlaying.shared.container?.updateTimes(for: item, to: time, setValue: true, seeking: false)
            
        }, afterDelay: 1)
    
        prefs.set(time, forKey: .currentPlaybackTime)
        NowPlaying.shared.registered.forEach({ $0?.updateTimes(for: item, to: time, setValue: true, seeking: false )})
        
        hasSetupApplicationPlayer = true
    }
}

//struct QueueItem {
//
//    var shouldRemoveAfterPlayback: Bool
//    let location: String
//    let item: MPMediaItem
//}
