//
//  HeaderEffectView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 18/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias NavigatableDetails = (title: String?, backLabelText: String?)

class VisualEffectNavigationBar: MELVisualEffectView {

    @IBOutlet var stackView: UIStackView!
    @IBOutlet var titleLabel: MELLabel!
    @IBOutlet var backLabel: MELLabel!
    @IBOutlet var albumsButton: MELButton!
    @IBOutlet var songsButton: MELButton!
    @IBOutlet var artworkContainer: InvertIgnoringView!
    @IBOutlet var artworkImageView: InvertIgnoringImageView!
    @IBOutlet var clearButtonView: UIView!
    @IBOutlet var entityImageView: MELImageView!
    @IBOutlet var entityImageViewContainer: UIView!
    @IBOutlet var backView: UIView!
    @IBOutlet var backBorderView: UIView!
    @IBOutlet var titleScrollView: MELScrollView!
    @IBOutlet var gradientView: GradientView!
    
    enum AnimationSection { case preparation, firstHalf, secondHalf, end(completed: Bool) }
    
    var titleLabelSnapshot: UIView?
    var backLabelSnapshot: UIView?
    var backBorderViewSnapshot: UIView?
    
    var containerVC: ContainerViewController? { return appDelegate.window?.rootViewController as? ContainerViewController }
    
    var verticalTranslation: CGFloat = 30
    var horizontalTranslation: CGFloat = 50
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(dismiss))
        titleScrollView.addGestureRecognizer(tap)
    }
    
    func animateTitleLabel(direction: AnimationDirection, section: AnimationSection, with initialVC: Navigatable?, and finalVC: Navigatable?, preferVerticalTransition: Bool = false) {
        
        animateTitleLabel(direction: direction, section: section, with: (initialVC?.title, initialVC?.backLabelText), and: (finalVC?.title, finalVC?.backLabelText), preferVerticalTransition: preferVerticalTransition)
    }
    
    func animateTitleLabel(direction: AnimationDirection, section: AnimationSection, with initialDetails: NavigatableDetails, and finalDetails: NavigatableDetails, preferVerticalTransition: Bool = false) {
        
        switch section {
            
            case .preparation:
            
                if let snapshot = titleLabel.snapshotView(afterScreenUpdates: false), let backSnapshot = backLabel.snapshotView(afterScreenUpdates: false), let borderSnapshot = backBorderView.snapshotView(afterScreenUpdates: false) {
                    
                    snapshot.frame = titleLabel.frame
                    titleLabel.superview?.addSubview(snapshot)
                    titleLabelSnapshot = snapshot
                    
                    titleLabel.alpha = 0
                    titleLabel.text = finalDetails.title
                    titleLabel.transform = .init(translationX: preferVerticalTransition ? 0 : (direction == .forward ? horizontalTranslation : -horizontalTranslation), y: preferVerticalTransition ? verticalTranslation : 0)
                    
                    backSnapshot.frame = backLabel.frame.modifiedBy(x: 10, y: 10)
                    backLabel.superview?.superview?.addSubview(backSnapshot)
                    backLabelSnapshot = backSnapshot
                    
                    backLabel.alpha = 0
                    backLabel.text = finalDetails.backLabelText
                    backLabel.transform = .init(translationX: preferVerticalTransition ? 0 : (direction == .forward ? horizontalTranslation : -horizontalTranslation), y: preferVerticalTransition ? verticalTranslation : 0)
                    
                    borderSnapshot.frame = backBorderView.frame.modifiedBy(x: 10, y: 10)
                    backBorderView.superview?.superview?.addSubview(borderSnapshot)
                    backBorderViewSnapshot = borderSnapshot
                    
                    backBorderView.alpha = 0
                    backBorderView.transform = .init(translationX: preferVerticalTransition ? 0 : (direction == .forward ? horizontalTranslation : -horizontalTranslation), y: preferVerticalTransition ? verticalTranslation : 0)
                }
            
            case .firstHalf:
                
                backLabelSnapshot?.alpha = 0
                backBorderViewSnapshot?.alpha = 0
                backLabelSnapshot?.transform = .init(translationX: preferVerticalTransition ? 0 : (direction == .forward ? -horizontalTranslation : horizontalTranslation), y: preferVerticalTransition ? verticalTranslation : 0)
                backBorderViewSnapshot?.transform = .init(translationX: preferVerticalTransition ? 0 : (direction == .forward ? -horizontalTranslation : horizontalTranslation), y: preferVerticalTransition ? verticalTranslation : 0)
                
                if finalDetails.backLabelText != nil {
                    
                    backView.isHidden = false
                }
            
                titleLabelSnapshot?.alpha = 0
                titleLabelSnapshot?.transform = .init(translationX: preferVerticalTransition ? 0 : (direction == .forward ? -horizontalTranslation : horizontalTranslation), y: preferVerticalTransition ? verticalTranslation : 0)
            
            case .secondHalf:
                
                if finalDetails.backLabelText == nil {
                    
                    backView.isHidden = true
                }
                
                if finalDetails.backLabelText != nil {
                    
                    backLabel.alpha = 1
                    backLabel.transform = .identity
                    backBorderView.alpha = 1
                    backBorderView.transform = .identity
                }
            
                titleLabel.alpha = 1
                titleLabel.transform = .identity
            
            case .end(completed: let completed):
                
                backView.isHidden = completed ? finalDetails.backLabelText == nil : initialDetails.backLabelText == nil
                backLabel.text = completed ? finalDetails.backLabelText : initialDetails.backLabelText
                backLabel.transform = .identity
                backLabel.alpha = 1
                backBorderView.transform = .identity
                backBorderView.alpha = completed ? (finalDetails.backLabelText == nil ? 0 : 1) : (initialDetails.backLabelText == nil ? 0 : 1)
                backBorderViewSnapshot?.removeFromSuperview()
                backBorderViewSnapshot = nil
                backLabelSnapshot?.removeFromSuperview()
                backLabelSnapshot = nil
                titleLabel.text = completed ? finalDetails.title : initialDetails.title
                titleLabel.transform = .identity
                titleLabel.alpha = 1
                titleLabelSnapshot?.removeFromSuperview()
                titleLabelSnapshot = nil
                gradientView.updateGradient()
        }
    }
    
    @IBAction func dismiss() {
        
        _ = containerVC?.activeViewController?.popViewController(animated: true)
    }
    
    @IBAction func showOptions() {
        
        guard let entityVC = containerVC?.activeViewController?.topViewController as? EntityItemsViewController else { return }
        
        entityVC.showOptions()
    }
}

protocol Navigatable: ArtworkModifying {
    
    var title: String? { get set }
    var backLabelText: String? { get set }
    var preferredTitle: String? { get set }
    var requiresShadow: Bool { get set }
    var inset: CGFloat { get }
    var activeChildViewController: UIViewController? { get set }
}

protocol NavigatableContained {
    
    var navigatable: Navigatable? { get }
}
