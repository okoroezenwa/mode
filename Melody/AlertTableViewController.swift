//
//  AlertTableViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 16/11/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias TapActionsDictionary = [Int: () -> ()]
typealias PreviewActionsDictionary = [Int: (UIViewController) -> UIViewController?]
typealias AccessoryActionsDictionary = [Int: AccessoryButtonAction]

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
    
    var segmentAction: ((UIViewController?) -> ())?
    
    var tapActions = TapActionsDictionary()
    var previewActions = PreviewActionsDictionary()
    var accessoryActions = AccessoryActionsDictionary()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        verticalPresentedVC?.containerViewHeightConstraint.constant = (FontManager.shared.alertCellHeight + 2) * CGFloat(array.count)
        
        verticalPresentedVC?.view.layoutIfNeeded()
        tableView.scrollIndicatorInsets.bottom = 15
        
        notifier.addObserver(self, selector: #selector(updateScrollView), name: UIApplication.didChangeStatusBarFrameNotification, object: UIApplication.shared)
        
        updateScrollView(self)
        
        registerForPreviewing(with: self, sourceView: tableView)
    }
    
    @objc func updateScrollView(_ sender: Any) {
        
        guard let parent = verticalPresentedVC else { return }

        let constant: CGFloat = sender is Notification ? 20 : 0
        let isScrollEnabled = !((parent.effectViewsContainer.frame.height + 6 + constant + UIApplication.shared.statusBarFrame.height) < screenHeight)
        
        tableView.isScrollEnabled = isScrollEnabled
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            let banner = UniversalMethods.banner(withTitle: "ATVC going away...")
            banner.titleLabel.font = .myriadPro(ofWeight: .light, size: 22)
            banner.show(for: 0.3)
        }
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
        
        if context == .show {
            
            cell.delegate = self
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        tapActions[indexPath.row]?()
        
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return FontManager.shared.alertCellHeight + 2
    }
}

extension AlertTableViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        switch context {
            
            case .show:
            
                guard let indexPath = tableView.indexPathForRow(at: location), let action = previewActions[indexPath.row], let cell = tableView.cellForRow(at: indexPath) else { return nil }
                
                previewingContext.sourceRect = cell.frame
            
                return action(self)
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        performCommitActions(on: viewControllerToCommit)
        
        viewController = viewControllerToCommit
        
        performSegue(withIdentifier: "preview", sender: nil)
    }
}

extension AlertTableViewController: SettingsCellDelegate {
    
    func accessoryButtonTapped(in cell: SettingsTableViewCell) {
        
        guard let indexPath = tableView.indexPath(for: cell), let action = accessoryActions[indexPath.row] else { return }
        
        action(cell.accessoryButton, self)
    }
}

extension AlertTableViewController: SegmentedResponder {
    
    func selectedSegment(at index: Int) {
        
        segmentAction?(self)
        dismiss(animated: true, completion: nil)
    }
}

extension AlertTableViewController: GestureSelectable {
    
    @objc func selectCell(_ sender: UIPanGestureRecognizer) {
        
        switch sender.state {
            
            case .began, .changed:
                
                guard let indexPath = tableView.indexPathForRow(at: sender.location(in: tableView)) else {
                    
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
