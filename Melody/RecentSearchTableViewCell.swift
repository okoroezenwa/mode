//
//  RecentSearchTableViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 28/02/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class RecentSearchTableViewCell: UITableViewCell/*, Swipable, SwipeActionsDelegate*/ {
    
    @IBOutlet var searchCategoryImageView: MELImageView!
    @IBOutlet var termLabel: MELLabel!
    @IBOutlet var criteriaLabel: MELLabel!
    @IBOutlet var borderView: MELBorderView!
    @IBOutlet var trailingConstraint: NSLayoutConstraint!
    @IBOutlet var leadingConstraint: NSLayoutConstraint!
    
    weak var delegate: (FilterContainer & UIViewController)?
//    weak var swipeDelegate: SwipeActionsDelegate?
//    
//    lazy var leftSwipeView = SwipeView.new(container: self, orientation: .left)
//    lazy var rightSwipeView = SwipeView.new(container: self, orientation: .right)
//    var radius: CGFloat = 50
//    var totalInset = UIScreen.main.bounds.width
//    var leftAttachedView: UIView { return contentView }
//    var rightAttachedView: UIView { return contentView }
//    var leftSwipeActions = [SwipeContainerAction]()
//    var rightSwipeActions = [SwipeContainerAction]()
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        selectedBackgroundView = MELBorderView()
        
        preservesSuperviewLayoutMargins = false
        contentView.preservesSuperviewLayoutMargins = false
        
//        let gr = UIPanGestureRecognizer.init(target: self, action: #selector(revealActions(_:)))
//        gr.delegate = self
//        addGestureRecognizer(gr)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        borderView.alphaOverride = selected ? 0.05 : 0
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        
        super.setHighlighted(highlighted, animated: animated)
        
        borderView.alphaOverride = highlighted ? 0.05 : 0
    }
    
//    @objc func revealActions(_ sender: UIPanGestureRecognizer) {
//
//        revealSwipeActions(sender)
//    }

    @IBAction func deleteTerm() {
        
        delegate?.deleteRecentSearch(in: self)
    }
}

extension RecentSearchTableViewCell {
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let gr = gestureRecognizer as? UIPanGestureRecognizer {
            
            let translation = gr.translation(in: superview)
            
            if abs(translation.x) > abs(translation.y) {
                
                return true
            }
            
            return false
        }
        
        return true
    }
}
