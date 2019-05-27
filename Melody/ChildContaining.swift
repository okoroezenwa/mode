//
//  ChildContaining.swift
//  Mode
//
//  Created by Ezenwa Okoro on 09/10/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

protocol ChildContaining: class {
    
    var activeChildViewController: UIViewController? { get set }
    var containerView: UIView! { get set }
    var viewControllerSnapshot: UIView? { get set }
    var changeActiveVC: Bool { get set }
}

extension ChildContaining where Self: UIViewController {
    
    var verticalTranslation: CGFloat { return 20 }
    
    func removeInactiveViewController(inactiveViewController: UIViewController?) {
        
        if let inActiveVC = inactiveViewController {
            
            // call before removing child view controller's view from hierarchy
            inActiveVC.willMove(toParent: nil)
            
            inActiveVC.view.removeFromSuperview()
            
            // call after removing child view controller's view from hierarchy
            inActiveVC.removeFromParent()
        }
    }
    
    func updateActiveViewController() {
        
        if let activeVC = activeChildViewController {
            
            // call before adding child view controller's view as subview
            addChild(activeVC)
            
            // call before adding child view controller's view as subview
            activeVC.didMove(toParent: self)
            containerView.addSubview(activeVC.view)
            activeVC.view.frame = containerView.bounds
        }
    }
    
    func changeActiveViewControllerFrom(_ vc: UIViewController?, animated: Bool = true, completion: (() -> ())? = nil) {
        
        guard animated, let snapshot = vc?.view.snapshotView(afterScreenUpdates: false), let container = self as? ContainerViewController ?? appDelegate.window?.rootViewController as? ContainerViewController else {
            
            removeInactiveViewController(inactiveViewController: vc)
            updateActiveViewController()
            
            if let _ = self as? LibraryViewController {
                
                (activeChildViewController as? LibrarySectionContainer)?.updateTopLabels(setTitle: animated.inverted)
            
            } else if let containerVC = self as? ContainerViewController {
                
                containerVC.visualEffectNavigationBar.titleLabel.text = (containerVC.activeViewController?.topViewController as? Navigatable)?.title
            }
            
            return
        }
        
        snapshot.frame = containerView.frame
        view.insertSubview(snapshot, aboveSubview: containerView)
        containerView.alpha = 0
        containerView.transform = .init(translationX: 0, y: verticalTranslation)
        viewControllerSnapshot = snapshot
        
        removeInactiveViewController(inactiveViewController: vc)
        updateActiveViewController()
        
        var oldVC: Navigatable?
        var newVC: Navigatable?
        
        if let libraryVC = self as? LibraryViewController {
            
            oldVC = libraryVC.temporary
            (activeChildViewController as? LibrarySectionContainer)?.updateTopLabels(setTitle: false)
            newVC = libraryVC.temporary
            
            container.visualEffectNavigationBar.animateViews(direction: .forward, section: .preparation, with: oldVC, and: newVC, preferVerticalTransition: true)
        
        } else if let containerVC = self as? ContainerViewController {
            
            containerVC.view.layoutIfNeeded()
            
            oldVC = (vc as? UINavigationController)?.topViewController as? Navigatable
            newVC = containerVC.activeViewController?.topViewController as? Navigatable
            
            if let startPoint = StartPoint(rawValue: lastUsedTab) {
                
                switch startPoint {
                    
                    case .library:
                        
                        containerVC.filterViewContainer.context = .library
                    
                    case .search:
                        
                        if let searchVC = containerVC.searchNavigationController?.viewControllers.first as? SearchViewController {
                            
                            containerVC.filterViewContainer.context = .filter(filter: searchVC, container: searchVC)
                        }
                }
            }
            
            container.visualEffectNavigationBar.animateViews(direction: .forward, section: .preparation, with: oldVC, and: newVC, preferVerticalTransition: true)
            
            UIView.transition(with: containerVC.imageView, duration: animated ? 0.3 : 0, options: .transitionCrossDissolve, animations: { containerVC.imageView.image = (containerVC.activeViewController?.topViewController as? ArtworkModifying)?.artworkType.image }, completion: nil)
        }
        
        UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: .calculationModeCubic, animations: {
            
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/2, animations: {
                
                snapshot.transform = .init(translationX: 0, y: self.verticalTranslation)
                snapshot.alpha = 0
                
                guard (self is EntityItemsViewController).inverted else { return }
                
                container.visualEffectNavigationBar.animateViews(direction: .forward, section: .firstHalf, with: oldVC, and: newVC, preferVerticalTransition: true)
            })
            
            UIView.addKeyframe(withRelativeStartTime: 1/2, relativeDuration: 1/2, animations: {
                
                self.containerView.transform = .identity
                self.containerView.alpha = 1
                
                guard (self is EntityItemsViewController).inverted else { return }
                
                container.visualEffectNavigationBar.animateViews(direction: .forward, section: .secondHalf, with: oldVC, and: newVC, preferVerticalTransition: true)
            })
            
            if let containerVC = self as? ContainerViewController {
                
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                    
                    containerVC.filterViewContainer.filterView.filterInputView.alpha = containerVC.filterViewContainer.filterView.context == .library ? 0 : 1
                    containerVC.view.layoutIfNeeded()
                })
            }
            
        }, completion: { [weak self] _ in
            
            self?.viewControllerSnapshot?.removeFromSuperview()
            self?.viewControllerSnapshot = nil
            self?.containerView.alpha = 1
            
            completion?()
            
            guard (self is EntityItemsViewController).inverted else { return }
            
            container.visualEffectNavigationBar.animateViews(direction: .forward, section: .end(completed: true), with: oldVC, and: newVC, preferVerticalTransition: true)
            
            notifier.post(name: .resetInsets, object: nil)
        })
    }
}
