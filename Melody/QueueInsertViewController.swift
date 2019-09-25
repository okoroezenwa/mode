//
//  AddToQueueViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 19/10/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias ApplicableShuffle = String.ShuffleSuffix

class QueueInsertController {
    
    enum Context { case collector(manager: QueueManager?), filterContainer((FilterContainer & UIViewController)?), other }
    enum QueuePosition { case next, after, last }

    var context = Context.other
    var applicableShuffle = ApplicableShuffle.none
    var activeShuffle = ApplicableShuffle.none {
        
        didSet {
            
            alertVC?.tableView.reloadData()
        }
    }
    
    var labelTitle: String { return title ?? singleSongTitle ?? query?.items?.count.fullCountText(for: .song) ?? songs.count.fullCountText(for: .song) }
    
    var singleSongTitle: String? {
        
        guard (query?.items?.count ?? songs.count) == 1 else { return nil }
        
        return (query?.items ?? songs).first?.validTitle
    }
    
    var title: String?
    weak var alertVC: AlertTableViewController?
    
    var kind = MPMusicPlayerController.QueueKind.items([]) {
        
        didSet {
            
            switch kind {
                
                case .items(let items): songs = items
                
                case .queries(let queries): query = queries.first
            }
        }
    }
    
    var query: MPMediaQuery? {
        
        didSet {
            
            applicableShuffle = {
                
                if let query = query?.copy() as? MPMediaQuery, let collections = query.grouped(by: .album).collections, collections.count > 1 {
                    
                    return .albums
                    
                } else if (query?.items ?? []).count > 1 {
                    
                    return .songs
                }
                
                return .none
            }()
        }
    }
    var songs = [MPMediaItem]() {
        
        didSet {
            
            applicableShuffle = {
                
                if songs.canShuffleAlbums {
                    
                    return .albums
                    
                } else if songs.count > 1 {
                    
                    return .songs
                }
                
                return .none
            }()
        }
    }
    
    init(vc: AlertTableViewController) {
        
        switch vc.context {
            
            case .queue(title: let title, kind: let kind, context: let context):
                
                defer {
                    
                    self.kind = kind
                    self.title = title
                    self.context = context
                    
                    vc.verticalPresentedVC?.setTitle(labelTitle)
                }
            
                self.alertVC = vc
            
            default: fatalError("No other context should invoke Queue Insert Controller.")
        }
    }
    
    func addToQueue(_ sender: QueuePosition) {
        
        alertVC?.verticalPresentedVC?.segmentedEffectView.isUserInteractionEnabled = false
        alertVC?.verticalPresentedVC?.staticView.isUserInteractionEnabled = false
        alertVC?.view.isUserInteractionEnabled = false
        
        if sender == .after {
            
            guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
            
            if case .collector(let queueManager) = context, let manager = queueManager {
                
                presentedVC.manager = manager
                presentedVC.queueTVC.shuffleMode = {
                    
                    switch activeShuffle {
                        
                        case .albums: return .albums
                        
                        case .songs: return .songs
                        
                        case .none: return .none
                    }
                }()
                
            } else if let query = query, activeShuffle == .none {

                presentedVC.query = query
                
            } else {
                
                presentedVC.itemsToAdd = requiredSongs()
            }
            
            presentedVC.context = .upNext
            presentedVC.queueTVC.title = labelTitle
            
            alertVC?.present(presentedVC, animated: true, completion: { [weak self] in
                
                self?.alertVC?.verticalPresentedVC?.staticCollectionView.deselectItem(at: .init(item: 1, section: 0), animated: false)
                self?.alertVC?.verticalPresentedVC?.staticView.isUserInteractionEnabled = true
                self?.alertVC?.verticalPresentedVC?.segmentedEffectView.isUserInteractionEnabled = true
                self?.alertVC?.view.isUserInteractionEnabled = true
            })
            
        } else {
            
            let items = requiredSongs()
            
            let kind: MPMusicPlayerController.QueueKind = {
                
                if useMediaItems {
                    
                    return .items(items)
                
                } else if let query = query, activeShuffle == .none {
                    
                    return .queries([query].compactMap({ $0 }))
                
                } else {
                    
                    return .queries(items.map({ MPMediaQuery.init(filterPredicates: [.for(.song, using: $0)]) }))
                }
            }()
            
            let alertType: MPMusicPlayerController.QueueModificationAlert = title?.isEmpty == false ? .entity(name: labelTitle) : .arbitrary(count: items.count)
            
            let alertTitle: String = {
                
                switch activeShuffle {
                    
                    case .none: return "Play"
                    
                    default: return .shuffle(activeShuffle)
                }
            }()
            
            musicPlayer.insert(kind, sender == .next ? .next : .last, alertType: alertType, from: alertVC, withTitle: labelTitle, subtitle: nil, alertTitle: "\(alertTitle) \(sender == .next ? "Next" : "Later")", completionKind: .completion({
                
                if case .collector = self.context {
                    
                    notifier.post(name: .endQueueModification, object: nil)
                    self.alertVC?.performSegue(withIdentifier: "unwind", sender: nil)
                    
                } else {
                    
                    if case .filterContainer(let container) = self.context {
                
                        container?.saveRecentSearch(withTitle: container?.searchBar?.text, resignFirstResponder: false)
                    }
                    
                    self.alertVC?.performSegue(withIdentifier: "unwind", sender: nil)
                }
            }))
        }
    }
    
    func requiredSongs() -> [MPMediaItem] {
        
        switch activeShuffle {
            
            case .albums:
            
                if let query = query?.copy() as? MPMediaQuery, let collections = query.grouped(by: .album).collections?.shuffled() {
                    
                    return collections.reduce([], { $0 + $1.items })
                    
                } else {
                    
                    return songs.albumsShuffled
                }
            
            case .songs: return (query?.items ?? songs).shuffled()
            
            case .none: return (query?.items ?? songs)
        }
    }
}
