//
//  AlertTableViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 16/11/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class AlertTableViewController: UITableViewController, PreviewTransitionable {
    
    enum Context { case show }
    
    var array = [Setting]()
    var context = Context.show
    var verticalPresentedVC: VerticalPresentationContainerViewController? { return parent as? VerticalPresentationContainerViewController }
    
    var isCurrentlyTopViewController: Bool = false
    var viewController: UIViewController?
    var selectedIndexPath: IndexPath? {
        
        didSet {
            
            guard selectedIndexPath != oldValue, let indexPath = oldValue else { return }
            
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        verticalPresentedVC?.containerViewHeightConstraint.constant = (FontManager.shared.alertCellHeight + 2) * CGFloat(array.count)
        verticalPresentedVC?.setTitle("Show...")
        
        verticalPresentedVC?.view.layoutIfNeeded()
        tableView.scrollIndicatorInsets.bottom = 15
        
        notifier.addObserver(self, selector: #selector(AlertTableViewController.updateScrollView), name: UIApplication.didChangeStatusBarFrameNotification, object: UIApplication.shared)
        
        updateScrollView(self)
        
        registerForPreviewing(with: self, sourceView: tableView)
    }
    
    @objc func updateScrollView(_ sender: Any) {
        
        guard let parent = verticalPresentedVC else { return }

        let constant: CGFloat = sender is Notification ? 20 : 0
        let isScrollEnabled = !((parent.effectViewsContainer.frame.height + 6 + constant + UIApplication.shared.statusBarFrame.height) < screenHeight)
        
        tableView.isScrollEnabled = isScrollEnabled
    }
}

extension AlertTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return array.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.settingCell(for: indexPath)
        
        cell.prepare(with: array[indexPath.row], context: .alert(cancel: false))
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch context {
            
            case .show where indexPath.row == 0:
            
                dismiss(animated: true, completion: { [weak self] in
                    
                    guard let weakSelf = self else { return }
                    
                    if case .chevron(let tapAction, _) = weakSelf.array[indexPath.row].accessoryType {
                        
                        tapAction?()
                    }
                })
            
            default:
            
                if case .chevron(let tapAction, _) = array[indexPath.row].accessoryType {
                    
                    tapAction?()
                }
            
                dismiss(animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return FontManager.shared.alertCellHeight + 2
    }
}

extension AlertTableViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        switch context {
            
            case .show:
            
                guard let indexPath = tableView.indexPathForRow(at: location), indexPath.row != 0, case .chevron(_, let action) = array[indexPath.row].accessoryType, let cell = tableView.cellForRow(at: indexPath) else { return nil }
                
                previewingContext.sourceRect = cell.frame
            
                return action?(self)
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        performCommitActions(on: viewControllerToCommit)
        
        viewController = viewControllerToCommit
        
        performSegue(withIdentifier: "preview", sender: nil)
    }
}

extension AlertTableViewController: GestureSelectable {
    
    @objc func selectCell(_ gr: UIPanGestureRecognizer) {
        
        switch gr.state {
            
            case .began, .changed:
                
                guard let indexPath = tableView.indexPathForRow(at: gr.location(in: tableView)) else {
                    
                    noSelection()
                    
                    return
                }
                
                guard indexPath != selectedIndexPath else { return }
            
                selectedIndexPath = indexPath
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        
            case .ended:
            
                guard let indexPath = selectedIndexPath else { return }
            
                self.tableView(tableView, didSelectRowAt: indexPath)
        
            default: noSelection()
        }
    }
    
    func noSelection() {
        
        if let indexPath = selectedIndexPath {
            
            selectedIndexPath = nil
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
}
