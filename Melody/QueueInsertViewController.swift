//
//  AddToQueueViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 19/10/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class QueueInsertViewController: UIViewController, BorderButtonContaining {

    @IBOutlet var queueStackView: UIStackView!
    @IBOutlet var shuffleLabel: MELLabel!
    @IBOutlet var albumsLabel: MELLabel!
    @IBOutlet var shuffleSwitch: MELSwitchContainer! {
        
        didSet {
            
            shuffleSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.shuffled = !weakSelf.shuffled
                
                UIView.transition(with: weakSelf.albumsLabel, duration: 0.3, options: .transitionCrossDissolve, animations: { weakSelf.updateAlbumsView() }, completion: nil)
            }
        }
    }
    @IBOutlet var albumsSwitch: MELSwitchContainer! {
        
        didSet {
            
            albumsSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.byAlbums = !weakSelf.byAlbums
                weakSelf.albumsSwitch.setOn(weakSelf.byAlbums, animated: true)
            }
        }
    }
    
    enum Context { case collector(manager: QueueManager?), filterContainer((FilterContainer & UIViewController)?), other }
    
    var borderedButtons = [BorderedButtonView?]()
    var shuffled = false
    var byAlbums = false
    var context = Context.other
    
    let nextView = BorderedButtonView.with(title: "Next", image: #imageLiteral(resourceName: "PlayNext"), tapAction: nil)
    let afterView = BorderedButtonView.with(title: "After...", image: #imageLiteral(resourceName: "PlayAfter"), tapAction: nil)
    let laterView = BorderedButtonView.with(title: "Last", image: #imageLiteral(resourceName: "PlayLater"), tapAction: nil)
    
    var labelTitle: String { return title ?? singleSongTitle ?? query?.items?.count.fullCountText(for: .song) ?? songs.count.fullCountText(for: .song) }
    
    var singleSongTitle: String? {
        
        guard (query?.items?.count ?? songs.count) == 1 else { return nil }
        
        return (query?.items ?? songs).first?.validTitle
    }
    
    var verticalPresentedVC: VerticalPresentationContainerViewController? { return parent as? VerticalPresentationContainerViewController }
    
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
            
            canShuffle = (query?.items ?? []).count > 1
            canShuffleAlbums = {
                
                if let query = query?.copy() as? MPMediaQuery, let collections = query.grouped(by: .album).collections {
                    
                    return collections.count > 1
                }
                
                return false
            }()
        }
    }
    var songs = [MPMediaItem]() {
        
        didSet {
            
            canShuffle = songs.count > 1
            canShuffleAlbums = songs.canShuffleAlbums
        }
    }
    var canShuffle = false
    var canShuffleAlbums = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        verticalPresentedVC?.setTitle(labelTitle)
        
//        afterView.isHidden = !allowPlayAfter
//        laterView.isHidden = !allowPlayLast
        
        [nextView, afterView, laterView].forEach({
            
            $0.borderViewTopConstraint.constant = 9
            $0.borderViewBottomConstraint.constant = 10
            queueStackView.addArrangedSubview($0)
            $0.tapAction = .init(action: #selector(addToQueue(_:)), target: self)
            
            if !$0.isHidden {
                
                borderedButtons.append($0)
            }
        })
        
        updateButtons()
        
        updateShuffleView()
        updateAlbumsView()
    }
    
    func updateShuffleView() {
        
        shuffleLabel.lightOverride = !canShuffle
        shuffleSwitch.isUserInteractionEnabled = canShuffle
    }
    
    func updateAlbumsView() {
        
        albumsLabel.lightOverride = !shuffled || !canShuffleAlbums || !canShuffle
        albumsSwitch.isUserInteractionEnabled = shuffled && canShuffle && canShuffleAlbums
    }
    
    @objc func addToQueue(_ sender: UITapGestureRecognizer) {
        
        if sender.view == afterView {
            
            guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
            
            if case .collector(let queueManager) = context, let manager = queueManager {
                
                presentedVC.manager = manager
                presentedVC.queueTVC.shuffleMode = {
                    
                    if shuffled, !byAlbums {
                        
                        return .songs
                        
                    } else if shuffled, byAlbums {
                        
                        return .albums
                        
                    } else {
                        
                        return .none
                    }
                }()
                
            } else if let query = query, !shuffled {

                presentedVC.query = query
                
            } else {
                
                presentedVC.itemsToAdd = requiredSongs()
            }
            
            presentedVC.context = .upNext
            presentedVC.queueTVC.title = labelTitle
            
            present(presentedVC, animated: true, completion: nil)
            
        } else {
            
            let items = requiredSongs()
            
            let kind: MPMusicPlayerController.QueueKind = {
                
                if useMediaItems {
                    
                    return .items(items)
                
                } else if let query = query, !shuffled {
                    
                    return .queries([query].compactMap({ $0 }))
                
                } else {
                    
                    return .queries(items.map({ MPMediaQuery.init(filterPredicates: [.for(.song, using: $0)]) }))
                }
            }()
            
            let alertType: MPMusicPlayerController.QueueModificationAlert = title?.isEmpty == false ? .entity(name: labelTitle) : .arbitrary(count: items.count)
            
            musicPlayer.insert(kind, sender.view == nextView ? .next : .last, alertType: alertType, from: self, withTitle: labelTitle, subtitle: nil, alertTitle: "\(shuffled ? .shuffle() : "Play") \(sender.view == nextView ? "Next" : "Later")", completionKind: .completion({
                
                if case .collector = self.context {
                    
                    notifier.post(name: .endQueueModification, object: nil)
                    self.performSegue(withIdentifier: "unwind", sender: nil)
                    
                } else {
                    
                    if case .filterContainer(let container) = self.context {
                
                        container?.saveRecentSearch(withTitle: container?.searchBar?.text, resignFirstResponder: false)
                    }
                    
                    self.performSegue(withIdentifier: "unwind", sender: nil)
                }
            }))
        }
    }
    
    func requiredSongs() -> [MPMediaItem] {
        
        if shuffled, !byAlbums {
            
            return (query?.items ?? songs).shuffled()
        
        } else if shuffled, byAlbums {
            
            if let query = query?.copy() as? MPMediaQuery, let collections = query.grouped(by: .album).collections?.shuffled() {
                
                return collections.reduce([], { $0 + $1.items })
            
            } else {
                
                return songs.albumsShuffled
            }
        
        } else {
            
            return (query?.items ?? songs)
        }
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            let banner = UniversalMethods.banner(withTitle: "QIVC going away...")
            banner.titleLabel.font = .myriadPro(ofWeight: .light, size: 22)
            banner.show(for: 0.3)
        }
    }
}
