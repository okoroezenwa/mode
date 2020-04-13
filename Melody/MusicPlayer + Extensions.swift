//
//  MusicPlayer + Extensions.swift
//  Melody
//
//  Created by Ezenwa Okoro on 16/05/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

public extension MPMusicPlayerController {
    
    enum QueuePosition { case next, after(item: MPMediaItem?, index: Int?), last }
    
    enum QueueKind { case items([MPMediaItem]), queries([MPMediaQuery]) }
    
    enum QueueModificationAlert { case none, arbitrary(count: Int), entity(name: String) }
    
    enum QueueCompletionKind { case notification, completion((() -> ())?) }
    
    enum QueueEditReason { case change, move, insert, removal }
    
    enum QueueCompletionCriteria { case unknown }
    
    var nowPlayingItemIndex: Int? { return indexOfNowPlayingItem == NSNotFound ? nil : indexOfNowPlayingItem }
    
    /// whether the musicPlayer is playing, using the playback rate due to a bug
    var isPlaying: Bool {
        
        if #available(iOS 11.3, *) {
            
            return playbackState == .playing || currentPlaybackRate > 0.0
        }
        
        return currentPlaybackRate > 0.0
    }
    
    func fullQueueCount(withInitialSpace: Bool, parentheses: Bool = true) -> String {
        
        guard let index = Queue.shared.indexToUse else { return (withInitialSpace ? " " : "") + (parentheses ? "(" : "") + "? of " + Queue.shared.queueCount.formatted + (parentheses ? ")" : "") }
        
        return (withInitialSpace ? " " : "") + (parentheses ? "(" : "") + (index + 1).formatted + " of " + Queue.shared.queueCount.formatted + (parentheses ? ")" : "")
    }
    
    func play(_ items: [MPMediaItem],
              startingFrom item: MPMediaItem?,
              shuffleMode: MPMusicShuffleMode = keepShuffleState ? musicPlayer.shuffleMode : .off,
              respectingPlaybackState shouldRespectState: Bool = false,
              from vc: UIViewController?,
              withTitle title: String?,
              subtitle: String? = nil,
              alertTitle: String,
              queueGuardCriteria: Bool = warnForQueueInterruption && playGuard,
              completion: (() -> ())? = nil) {
        
//        let startDate = Date()
        
        let play: () -> () = {
            
            let isSameItem = item == self.nowPlayingItem
            let time = self.currentPlaybackTime
            let wasPlaying = self.isPlaying
            
            if shuffleMode == .off {
                
                Queue.shared.updateCurrentQueue(with: items, startingItem: item, shouldUpdateIndex: false)
            }
            
            self.pause()//stop()
            
            let queueBlock: (() -> ()) = {
                
                self.setQueue(with: .init(items: items))
                
                if let start = item {
                    
                    self.nowPlayingItem = start
                }
            }
            
            let descriptorBlock: (() -> ()) = {
                
                guard #available(iOS 10.1, *) else { return }
                
                let descriptor = MPMusicPlayerMediaItemQueueDescriptor.init(itemCollection: .init(items: items))
                descriptor.startItem = item
                
                self.setQueue(with: descriptor)
            }
            
            if #available(iOS 11, *) {
                
                useDescriptor ? descriptorBlock() : queueBlock()
                
            } else if #available(iOS 10.1, *) {

                descriptorBlock()

            } else {
            
                queueBlock()
            }
            
            if shuffleMode != .off {
                
                self.shuffleMode = .off
                self.shuffleMode = shuffleMode
                
            } else {
                
                self.shuffleMode = shuffleMode
            }
            
            if !preserveRepeatState {
                
                self.repeatMode = .none
            }
                
            if shouldRespectState.inverted {
            
                self.play()
            
            } else {
                
                if #available(iOS 11.3, *) {
                    
                    if wasPlaying.inverted {
                    
                        self.pause()
                    
                    } else {
                        
                        self.play()
                    }
                
                } else {
                    
                    self.prepareToPlay()
                }
                
            }
            
            if isSameItem {
                
//                let finish = Date()
//                let interval = finish.timeIntervalSince(startDate)
                self.currentPlaybackTime = time// + interval
            }
            
            completion?()
            notifier.post(name: .queueModified, object: nil)
            
            if shuffleMode != .off, !useSystemPlayer, #available(iOS 10.3, *), let musicPlayer = self as? MPMusicPlayerApplicationController {
                
                musicPlayer.perform(queueTransaction: { _ in }, completionHandler: { controller, _ in
                
                    Queue.shared.updateCurrentQueue(with: controller.items, startingItem: item, shouldUpdateIndex: false)
                })
            }
        }
        
        let useAlert: Bool = {
            
            guard let index = self.nowPlayingItemIndex else { return (self.isPlaying || self.currentPlaybackTime > 0) && queueGuardCriteria }
            
            return (index > 0 || (self.isPlaying || self.currentPlaybackTime > 0)) && queueGuardCriteria
        }()
        
        if let vc = vc, useAlert {
            
            vc.showAlert(title: title, subtitle: subtitle, context: .other, with: .init(info: .init(title: alertTitle, accessoryType: .none), requiresDismissalFirst: true, handler: play))
            
        } else {
            
            play()
        }
    }
    
    func insert(_ queueKind: QueueKind,
                _ position: QueuePosition,
                alertType: QueueModificationAlert,
                from vc: UIViewController?,
                withTitle title: String?,
                subtitle: String? = nil,
                alertTitle: String,
                completionKind: QueueCompletionKind = .completion(nil)) {
        
        let showAlert: (() -> ()) = {
            
            let string: String = {
                
                let suffix: String = {
                    
                    switch position {
                        
                        case .next: return "Next"
                        
                        case .after(item: let item, _): return "After \"\(item?.title ??? "Untitled Song")\""
                        
                        case .last: return "Last"
                    }
                }()
                
                switch alertType {
                    
                    case .none: return ""
                    
                    case .arbitrary: return "Will Play \(suffix)"
                    
                    case .entity(name: let name): return "Will Play \"\(name)\" \(suffix)"
                }
            }()
            
            if !string.isEmpty {
                
                UniversalMethods.banner(withTitle: string).show(for: 0.5)
            }
        }
        
        if !useSystemPlayer, forceOldStyleQueue.inverted, #available(iOS 10.3, *), let musicPlayer = self as? MPMusicPlayerApplicationController {
            
            let addToQueue: () -> () = {
                
                var itemsToInsert = [MPMediaItem]()
                var itemBefore: MPMediaItem?
                
                musicPlayer.perform(queueTransaction: { controller in
                    
                    let checked = Set(controller.items)
                    
                    let item: MPMediaItem? = {
                            
                        switch position {
                            
                            case .next: return musicPlayer.nowPlayingItem
                                
                            case .after(item: let item, _): return item
                                
                            case .last: return controller.items.last
                        }
                    }()
                    
                    DispatchQueue.main.async { itemBefore = item }
                    
                    switch queueKind {
                        
                        case .items(let items):
                            
                            DispatchQueue.main.async { itemsToInsert = items }
                        
                            for song in items {

                                guard song != musicPlayer.nowPlayingItem && song != item else { continue }

                                if checked.contains(song) {

                                    controller.remove(song)
                                }
                            }

                        controller.insert(MPMusicPlayerMediaItemQueueDescriptor.init(itemCollection: .init(items: items)), after: item)
                        
                        case .queries(let queries):
                            
                            DispatchQueue.main.async { itemsToInsert = queries.reduce([], { $0 + ($1.items ?? []) }) }
                        
                            if queries.count > 1 {
                                
                                for query in queries {
                                    
                                    guard query.items?.first != musicPlayer.nowPlayingItem && query.items?.first != item else { continue }
                                    
                                    if let first = query.items?.first, checked.contains(first) {

                                        controller.remove(first)
                                    }
                                    
                                    controller.insert(MPMusicPlayerMediaItemQueueDescriptor.init(query: query), after: item)
                                }
                                
                            } else {
                                
                                guard let query = queries.first else { return }
                                
                                let items = query.items ?? []
                                
                                if checked.intersection(Set(items)).count == 0 {
                                    
                                    controller.insert(MPMusicPlayerMediaItemQueueDescriptor.init(query: query), after: item)
                                    
                                } else {
                                    
                                    let queries = items.map({ MPMediaQuery.init(filterPredicates: [.for(.song, using: $0)]) })
                                    
                                    for query in queries {
                                        
                                        guard query.items?.first != musicPlayer.nowPlayingItem && query.items?.first != item else { continue }
                                        
                                        if let first = query.items?.first, checked.contains(first) {

                                            controller.remove(first)
                                        }
                                        
                                        controller.insert(MPMusicPlayerMediaItemQueueDescriptor.init(query: query), after: item)
                                    }
                                }
                            }
                    }
                    
                }, completionHandler: { controller, error in
                    
//                    notifier.post(name: .saveQueue, object: musicPlayer, userInfo: [String.queueItems: controller.items])
                    
                    if let error = error, isInDebugMode {
                        
                        UniversalMethods.banner(withTitle: error.localizedDescription).show(for: 1)
                    }
                    
                    showAlert()
                    
                    Queue.shared.place(itemsToInsert, after: itemBefore, completion: {
                        
                        notifier.post(name: .queueUpdated, object: musicPlayer, userInfo: [String.musicPlayerController: controller])
                        notifier.post(name: .queueModified, object: [.queueChange: true])
                        
                        switch completionKind {
                            
                            case .notification: break//notifier.post(name: .queueUpdated, object: musicPlayer, userInfo: [String.musicPlayerController: controller])
                            
                            case .completion(let completion): completion?()
                        }
                    })
                    
//                    notifier.post(name: .queueUpdated, object: musicPlayer, userInfo: [String.musicPlayerController: controller])
//                    notifier.post(name: .queueModified, object: nil)
//
//                    switch completionKind {
//
//                        case .notification: break//notifier.post(name: .queueUpdated, object: musicPlayer, userInfo: [String.musicPlayerController: controller])
//
//                        case .completion(let completion): completion?()
//                    }
                })
            }
            
//            let action = UIAlertAction.init(title: alertTitle, style: .default, handler: { _ in
//
//                addToQueue()
//            })
            
            if let vc = vc {
                
                vc.guardQueue(title: title, subtitle: subtitle, with: AlertAction.init(info: AlertInfo.init(title: alertTitle, accessoryType: .none, textAlignment: .center), handler: addToQueue), onCondition: warnForQueueInterruption && addGuard, fallBack: addToQueue)
            
            } else {
                
                addToQueue()
            }
            
            return
        }
        
        let test: Bool = {
            
            if #available(iOS 11.3, *) {
                
                return false
            }
            
            return true
        }()
        
        if #available(iOS 10.3, *), (useSystemPlayer && forceOldStyleQueue.inverted) || (useSystemPlayer.inverted && forceOldStyleQueue && test) {
            
            var descriptor: MPMusicPlayerMediaItemQueueDescriptor? {
                
                switch queueKind {
                    
                    case .items(let items):

                        let itemDesciptor = MPMusicPlayerMediaItemQueueDescriptor.init(itemCollection: .init(items: items))
                        itemDesciptor.startItem = items.first

                        return itemDesciptor
                    
                    case .queries(let queries) where queries.count == 1: return .init(query: queries[0])
                    
                    default: return nil
                }
            }
            
            if let itemDescriptor = descriptor {
                
                if case .next = position {
                    
                    musicPlayer.prepend(itemDescriptor)
                    
                    showAlert()
                    
                    if case .completion(let completion) = completionKind {
                        
                        completion?()
                    }
                    
                    return
                    
                } else if case .last = position {
                    
                    musicPlayer.append(itemDescriptor)
                    
                    showAlert()
                    
                    if case .completion(let completion) = completionKind {
                        
                        completion?()
                    }
                    
                    Queue.shared.updateCurrentQueue(with: itemDescriptor.query.items ?? itemDescriptor.itemCollection.items, startingItem: nil, shouldUpdateIndex: false)
                    
                    return
                }
            }
        }
        
        guard let items: [MPMediaItem] = {
            
            switch queueKind {
                
                case .items(let items): return items
                    
                case .queries(let queries): return queries.reduce([MPMediaItem](), { $0 + ($1.items ?? []) })
            }
            
        }(), let collection = newQueue(using: items, position), case .completion(let completion) = completionKind else { return }
        
        play(collection, startingFrom: nowPlayingItem, shuffleMode: .off, respectingPlaybackState: true, from: vc, withTitle: title, subtitle: subtitle, alertTitle: alertTitle, queueGuardCriteria: warnForQueueInterruption && addGuard, completion: { completion?(); showAlert() })
    }
    
    func newQueue(using songs: [MPMediaItem], _ position: QueuePosition) -> [MPMediaItem]? {
        
        guard let index: Int = {
            
            switch position {
                
                case .next: return nowPlayingItemIndex
                    
                case .after(item: _, index: let index): return index
                    
                case .last: return Queue.shared.queueCount - 1
            }
        
        }() else { return nil }
        
        let array = Array(0...index)
        let endArray: [Int] = {
            
            switch position {
                    
                case .next, .after: return (index + 1) == Queue.shared.queueCount ? [] : Array((index + 1)...(Queue.shared.queueCount - 1))
                    
                case .last: return []
            }
        }()
        
        var startOfQueue = [MPMediaItem]()
        var endOfQueue = [MPMediaItem]()
        
        array.forEach({
            
            if let item = item(at: $0) {
                
                startOfQueue.append(item)
            }
        })
        
        endArray.forEach({
            
            if let item = item(at: $0) {
                
                endOfQueue.append(item)
            }
        })
        
        let items: [MPMediaItem] = {
            
            switch position {
                
                case .next, .after(_): return startOfQueue + songs + endOfQueue
                    
                case .last: return startOfQueue + endOfQueue + songs
            }
        }()
        
        return items
    }
}
