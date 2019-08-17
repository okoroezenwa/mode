//
//  RatingView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 12/06/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class RateShareView: UIView {

    @IBOutlet var ratingView: UIView!
    @IBOutlet var ratingStackView: UIStackView!
    @IBOutlet var shareButton: MELButton!
    @IBOutlet var likedStateButton: MELButton!
    
    @objc weak var entity: MPMediaEntity? {
        
        didSet {
            
            guard likedStateButton != nil, ratingStackView != nil else { return }
            
            setRating()
            prepareLikedView()
            determineOverrides()
        }
    }
    var canLikeEntity = true
    weak var container: UIViewController?
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        translatesAutoresizingMaskIntoConstraints = false
        
        let gr = UIPanGestureRecognizer.init(target: self, action: #selector(changeRating(_:)))
        ratingStackView.addGestureRecognizer(gr)
        
        let tapGR = UITapGestureRecognizer.init(target: self, action: #selector(tap(_:)))
        ratingStackView.addGestureRecognizer(tapGR)
        
        let hold = UILongPressGestureRecognizer.init(target: self, action: #selector(setLastFMAffinity(_:)))
        hold.minimumPressDuration = longPressDuration
        likedStateButton.addGestureRecognizer(hold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
        
        notifier.addObserver(self, selector: #selector(update), name: UIApplication.willEnterForegroundNotification, object: UIApplication.shared)
    }
    
    @objc func setLastFMAffinity(_ gr: UILongPressGestureRecognizer) {
        
        guard gr.state == .began, let song = entity as? MPMediaItem, let container = container else { return }
            
        guard Scrobbler.shared.sessionInfoObtained else {
            
            UniversalMethods.banner(withTitle: "Not logged in to Last.fm").show(for: 2)
            
            return
        }
        
        let actions = [AlertAction.init(info: .init(title: "Loved", image: #imageLiteral(resourceName: "Loved22"), accessoryType: .none), handler: {
            
            Scrobbler.shared.love(song)
            container.dismiss(animated: true, completion: nil)
            
        }), .init(info: .init(title: "Unloved", image: #imageLiteral(resourceName: "Unloved22"), accessoryType: .none), handler: {
            
            Scrobbler.shared.unlove(song)
            container.dismiss(animated: true, completion: nil)
        })]
        
        Transitioner.shared.showAlert(title: "Last.fm", subtitle: "Set as...", from: container, context: .other, with: actions)
    }
    
    func determineOverrides() {
        
        likedStateButton.lightOverride = !canLikeEntity
        likedStateButton.isUserInteractionEnabled = canLikeEntity
        
        if let imageViews = ratingStackView.arrangedSubviews as? [MELImageView] {
            
            imageViews.forEach({ $0.lightOverride = entity is MPMediaItemCollection })
        }
    }
    
    @objc func changeRating(_ sender: UIPanGestureRecognizer) {
        
        guard let item = entity as? MPMediaItem else { return }
        
        UniversalMethods.rate(item, in: ratingStackView, with: sender)
    }
    
    @objc func tap(_ sender: UITapGestureRecognizer) {
        
        guard let item = entity as? MPMediaItem, let imageViews = ratingStackView.arrangedSubviews as? [UIImageView] else { return }
        
        var rating = 0
        
        for imageView in imageViews {
            
            if sender.location(in: ratingStackView).x >= imageView.frame.origin.x {
                
                rating += 1
            }
        }
        
        item.set(property: MPMediaItemPropertyRating, to: rating)
        
        setRating()
        
        notifier.post(name: .ratingChanged, object: nil, userInfo: [String.id: item.persistentID, String.sender: ratingStackView as Any])
    }
    
    @objc func setRating() {
        
        guard let item = entity as? MPMediaItem, let imageViews = ratingStackView.arrangedSubviews as? [UIImageView] else { return }
        
        for imageView in imageViews {
            
            imageView.image = item.rating >= imageView.tag ? #imageLiteral(resourceName: "StarFilled17") : #imageLiteral(resourceName: "Dot")
        }
    }
    
    func image(for likedState: LikedState) -> UIImage {
        
        switch likedState {
                
            case .none: return #imageLiteral(resourceName: "NoLove17")
                
            case .liked: return #imageLiteral(resourceName: "Loved17")
                
            case .disliked: return #imageLiteral(resourceName: "Unloved17")
        }
    }
    
    @objc func prepareLikedView() {
        
        guard let item = entity as? Settable else { return }
        
        var image: UIImage {
            
            switch item.likedState {
                
                case .none: return #imageLiteral(resourceName: "NoLove17")
                    
                case .liked: return #imageLiteral(resourceName: "Loved17")
                    
                case .disliked: return #imageLiteral(resourceName: "Unloved17")
            }
        }
        
        likedStateButton.setImage(image, for: .normal)
    }
    
    @IBAction func setLiked(_ sender: Any) {
        
        guard let item = entity as? Settable else { return }
        
        let value: LikedState = {
            
            switch item.likedState {
                
                case .none: return LikedState.liked
                    
                case .liked: return LikedState.disliked
                    
                case .disliked: return LikedState.none
            }
        }()
        
        item.set(property: entity is MPMediaItem || entity is MPMediaPlaylist ? .likedState : .albumLikedState, to: NSNumber.init(value: value.rawValue))
        
        UIView.transition(with: likedStateButton, duration: 0.3, options: .transitionCrossDissolve, animations: { self.prepareLikedView() }, completion: { [weak self] finished in
            
            guard finished, let weakSelf = self else { return }
            
            notifier.post(name: .likedStateChanged, object: nil, userInfo: [String.id: item.persistentID, String.sender: weakSelf.ratingStackView as Any])
            
            UniversalMethods.performOnMainThread({
            
                if weakSelf.likedStateButton.image(for: .normal) != weakSelf.image(for: item.likedState) {
                    
                    UIView.transition(with: weakSelf.likedStateButton, duration: 0.3, options: .transitionCrossDissolve, animations: { weakSelf.prepareLikedView() }, completion: { _ in notifier.post(name: .likedStateChanged, object: nil, userInfo: [String.id: item.persistentID, String.sender: weakSelf.ratingStackView as Any]) })
                }
            
            }, afterDelay: 0.3)
        })
    }
    
    @IBAction func share() {
        
        var images: [UIImage] {
            
            if let nowPlayingVC = container as? NowPlayingViewController {
                
                return [UIImage.from(nowPlayingVC.view)].compactMap({ $0 })
            }
            
            if let item = entity as? MPMediaItem {
                
                return [item.actualArtwork?.image(at: item.artwork?.bounds.size ?? .zero)].compactMap({ $0 })
                
            } else if let collection = entity as? MPMediaItemCollection {
                
                return collection.items.compactMap({ $0.actualArtwork?.image(at: $0.artwork?.bounds.size ?? .zero) })
            }
            
            return []
        }
        
        let activity = UIActivityViewController.init(activityItems: images.compactMap({ $0 }), applicationActivities: nil)
        
        if let actionsVC = topViewController as? ActionsViewController {
            
            actionsVC.dismiss(animated: false, completion: { actionsVC.sender?.present(activity, animated: true, completion: nil) })
            
        } else {
            
            topViewController?.show(activity, sender: nil)
        }
    }
    
    @objc func update() {
        
        UniversalMethods.performOnMainThread({
            
            self.setRating()
            self.prepareLikedView()
        
        }, afterDelay: 1)
    }
}

extension RateShareView {
    
    @objc class func instance(container: UIViewController) -> RateShareView {
        
        let view = Bundle.main.loadNibNamed("RateShareView", owner: nil, options: nil)?.first as! RateShareView
        view.container = container
        
        return view
    }
}
