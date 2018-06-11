//
//  VerticalPresentationContainerViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 29/01/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class VerticalPresentationContainerViewController: UIViewController {

    @IBOutlet weak var imageView: ShadowImageView!
    @IBOutlet weak var effectView: MELVisualEffectView! {
        
        didSet {
            
            effectView.layer.setRadiusTypeIfNeeded()
            effectView.layer.cornerRadius = 15
        }
    }
    @IBOutlet weak var titleLabel: MELLabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!
    
    enum Context { case insert, sort, actions }
    
    var context = Context.actions
    let transitioner = SimplePresentationAnimationController.init(orientation: .vertical)
    
    override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        
        get { return transitioner }
        
        set { }
    }
    
    override var modalPresentationStyle: UIModalPresentationStyle {
        
        get { return .overFullScreen }
        
        set { }
    }
    
    @objc var activeViewController: UIViewController? {
        
        didSet {
            
            updateActiveViewController()
        }
    }
    
    lazy var arrangeVC: ArrangeViewController = {
        
        return popoverStoryboard.instantiateViewController(withIdentifier: "simpleArrangeVC") as! ArrangeViewController
    }()
    
    lazy var actionsVC: ActionsViewController = {
        
        return popoverStoryboard.instantiateViewController(withIdentifier: "actionsVC") as! ActionsViewController
    }()
    
    lazy var insertVC: QueueInsertViewController = {
        
        return popoverStoryboard.instantiateViewController(withIdentifier: String.init(describing: QueueInsertViewController.self)) as! QueueInsertViewController
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        let gr = UITapGestureRecognizer.init(target: self, action: #selector(dismissVC))
        gr.delegate = self
        view.addGestureRecognizer(gr)
        
        let swipe = UISwipeGestureRecognizer.init(target: self, action: #selector(dismissVC))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
        
        if #available(iOS 11, *) {
            
            view.accessibilityIgnoresInvertColors = darkTheme
        }
        
        activeViewController = {
            
            switch context {
                
                case .insert: return insertVC
                
                case .sort: return arrangeVC
                
                case .actions: return actionsVC
            }
        }()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setTitle(_ title: String) {
        
        titleLabel.text = title
        titleLabel.attributes = [.init(name: .paragraphStyle, value: .other(NSMutableParagraphStyle.withLineHeight(1.5, alignment: .center)), range: title.nsRange())]
    }
    
    @objc func dismissVC(_ sender: UIGestureRecognizer) {
        
        if sender is UITapGestureRecognizer {
            
            guard sender.state == .ended else { return }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func updateActiveViewController() {
        
        if let activeVC = activeViewController {
            
            // call before adding child view controller's view as subview
            addChild(activeVC)
            
            // call before adding child view controller's view as subview
            activeVC.didMove(toParent: self)
            containerView.addSubview(activeVC.view)
            activeVC.view.frame = containerView.bounds
        }
    }
}

extension VerticalPresentationContainerViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return !imageView.frame.contains(gestureRecognizer.location(in: view))
    }
}
