//
//  SwipeView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 28/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SwipeView: MELBorderView {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var label: MELLabel!
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    @IBOutlet var trailingConstraint: NSLayoutConstraint!
    @IBOutlet var stackView: UIStackView!
    
    weak var container: Swipable?
    var orientation = SwipeActionsOrientation.left
    
    var leftThreshold = Threshold.none {

        didSet {

            guard leftThreshold != oldValue else { return }
            
            switch leftThreshold {
                
                case .none:
                    
                    label.text = container?.swipeDelegate?.leftSwipeActions.first?.title
                    imageView.image = container?.swipeDelegate?.leftSwipeActions.first?.image
                    stackView.alpha = 0
                
                default:
                    
                    let string = String.init(format: "%@%@%@%@", "_feed", "backS", "uppor", "tLevel")
                    
                    if let feedback = UIDevice.current.value(forKey: string) as? Int, feedback < 2 {
                        
                        VibrationFeedback.selection.generateFeedback()
                        
                    } else if #available(iOS 10, *) {
                        
                        HapticFeedback.selection.generateFeedback()
                    }
                    
                    if oldValue == .none {
                        
                        UIView.animate(withDuration: 0.2, animations: {
                            
                            self.stackView.alpha = 1
                        })
                    
                    } else {
                    
                        guard let snapshot = label.snapshotView(afterScreenUpdates: false) else { return }
                        
                        stackView.superview?.addSubview(snapshot)
                        snapshot.frame = stackView.frame
                        stackView.alpha = 0
                        label.text = container?.swipeDelegate?.leftSwipeActions.value(at: leftThreshold.index)?.title
                        imageView.image = container?.swipeDelegate?.leftSwipeActions.value(at: leftThreshold.index)?.image
                        
                        stackView.transform = oldValue == .none ? .init(scaleX: scale, y: scale) : .init(scaleX: 0.2, y: 0.2)
                        
                        UIView.animateKeyframes(withDuration: 0.2, delay: 0, options: .calculationModeCubic, animations: {
                            
                            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/2, animations: {
                                
                                snapshot.transform = oldValue == .none ? .init(scaleX: self.scale, y: self.scale) : .init(scaleX: 0.2, y: 0.2)
                                snapshot.alpha = 0
                            })
                            
                            UIView.addKeyframe(withRelativeStartTime: 1/2, relativeDuration: 1/2, animations: {
                                
                                self.stackView.transform = .identity
                                self.stackView.alpha = 1
                            })
                            
                        }, completion: { _ in snapshot.removeFromSuperview() })
                    }
            }
        }
    }
    
    let scale: CGFloat = 0.7
    var radius: CGFloat = 0
    
    lazy var constant: CGFloat = { (radius / 2) - ((container?.swipeDelegate?.leftSwipeActions.first?.title ?? "") as NSString).boundingRect(with: .init(width: .greatestFiniteMagnitude, height: label.frame.height), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [.font: UIFont.font(ofWeight: .regular, size: 17)], context: nil).width - 10 }()
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        switch orientation {
            
            case .left: trailingConstraint.isActive = false
            
            case .right: leadingConstraint.isActive = false
        }
        
        label.text = container?.swipeDelegate?.leftSwipeActions.first?.title
        imageView.image = container?.swipeDelegate?.leftSwipeActions.first?.image
        stackView.alpha = 0
    }
    
    class func new(container: Swipable?, orientation: SwipeActionsOrientation) -> SwipeView {
        
        let view = Bundle.main.loadNibNamed("SwipeView", owner: nil, options: nil)?.first as! SwipeView
        
        view.container = container
        view.orientation = orientation
        
        return view
    }
}


