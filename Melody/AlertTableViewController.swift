//
//  AlertTableViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 16/11/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias ShowMenuParameters = (collection: MPMediaItemCollection?, entityType: EntityType)
typealias ShowMenuImageInfo = (image: UIImage?, entityType: EntityType)

class AlertTableViewController: UITableViewController, PreviewTransitionable {
    
    enum Context { case show, other, queue(title: String?, kind: MPMusicPlayerController.QueueKind, context: QueueInsertController.Context), select }
    
    var actions = [AlertAction]()
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
    var showMenuParameters = [ShowMenuParameters]() {
        
        didSet {
            
            guard showMenuParameters.isEmpty.inverted else { return }
            
            imageInfo = showMenuParameters.map({ ($0.collection?.customArtwork(for: $0.entityType)?.scaled(to: .init(width: 38, height: 38), by: 2) ?? $0.collection?.representativeArtwork(for: $0.entityType, size: .init(width: 38, height: 38)) ?? $0.collection?.emptyArtwork(for: $0.entityType), $0.entityType) })
        }
    }
    lazy var imageInfo = [ShowMenuImageInfo]()
    
    var segmentActions = [((UIViewController?) -> ())]()
    lazy var queueInsertController = QueueInsertController.init(vc: self)

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        verticalPresentedVC?.containerViewHeightConstraint.constant = (FontManager.shared.alertCellHeight + 2) * CGFloat(actions.count)
        
        if case .queue = context {

            verticalPresentedVC?.setTitle(queueInsertController.labelTitle)
        }
        
        if case .show = context {
            
            verticalPresentedVC?.leftButton.setImage(#imageLiteral(resourceName: "Search13"), for: .normal)
        }
        
        verticalPresentedVC?.view.layoutIfNeeded()
//        tableView.scrollIndicatorInsets.top = 15
        tableView.scrollIndicatorInsets.bottom = 15
        tableView.separatorInset.left = actions.first?.info.subtitle == nil && actions.first?.info.image == nil ? 0 : 54
        
        notifier.addObserver(self, selector: #selector(updateScrollView), name: UIApplication.didChangeStatusBarFrameNotification, object: UIApplication.shared)
        
        updateScrollView(self)
        
        if case .select = context {
            
            verticalPresentedVC?.selectedCollectionIndexPath = .init(item: 0, section: 0)
        
        } else if case .other = context, let count = verticalPresentedVC?.segments.count, count > 1 {
            
            verticalPresentedVC?.selectedCollectionIndexPath = .init(item: 0, section: 0)
        }
        
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
        
        return actions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.settingCell(for: indexPath)
        
        cell.prepare(with: actions[indexPath.row])
        
        if case .show = context {
            
            cell.delegate = self
            
            if useArtworkInShowMenu {
            
                let info = imageInfo[indexPath.row]
                
                cell.leadingImageViewWidthConstraint.constant = 38
                cell.leadingImageViewLeadingConstraint.constant = 8
                cell.labelsStackView.layoutMargins.left = 8
                cell.leadingImageView.image = info.image
                (listsCornerRadius ?? cornerRadius).updateCornerRadius(on: cell.leadingImageView.layer, width: 38, entityType: info.entityType, globalRadiusType: cornerRadius)
                
                if let superview = cell.leadingImageView.superview, superview.layer.shadowOpacity < 0.1 {
                    
                    UniversalMethods.addShadow(to: superview, radius: 4, opacity: 0.35, shouldRasterise: true)
                }
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let action = actions[indexPath.row]
        
        switch context {
            
            case .show:
                
                action.handler?()
                dismiss(animated: true, completion: nil)
            
            case .other, .select:
                
                if action.requiresDismissalFirst.inverted {
                    
                    action.handler?()
                }
                
                dismiss(animated: true, completion: {
                    
                    guard action.requiresDismissalFirst else { return }
                    
                    action.handler?()
                })
            
            case .queue: action.handler?()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return FontManager.shared.alertCellHeight + 2
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        return actions[indexPath.row].info.inactive().inverted
    }
}

extension AlertTableViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        switch context {
            
            case .show:
            
                guard let indexPath = tableView.indexPathForRow(at: location), let action = actions[indexPath.row].previewAction, let cell = tableView.cellForRow(at: indexPath) else { return nil }
                
                previewingContext.sourceRect = cell.frame
            
                return action(self)
            
            default: return nil
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
        
        guard let indexPath = tableView.indexPath(for: cell), let action = actions[indexPath.row].accessoryAction else { return }
        
        action(cell.accessoryButton, self)
    }
}

extension AlertTableViewController: SegmentedResponder {
    
    func selectedSegment(at index: Int) {
        
        switch context {
            
            case .show:
            
                segmentActions[index](self)
                dismiss(animated: true, completion: nil)
            
            case .queue:
            
                switch index {
            
                    case 0: queueInsertController.addToQueue(.next)
                    
                    case 1: queueInsertController.addToQueue(.after)
                    
                    case 2: queueInsertController.addToQueue(.last)
                    
                    default: break
                }
            
            case .select: segmentActions[index](self)
            
            case .other: segmentActions[index](self)
        }
    }
}

extension AlertTableViewController: GestureSelectable {
    
    @objc func selectCell(_ sender: UIGestureRecognizer) {
        
        switch sender.state {
            
            case .began, .changed:
                
                guard let indexPath = tableView.indexPathForRow(at: sender.location(in: tableView)), actions[indexPath.row].info.inactive().inverted else {
                    
                    noSelection()
                    
                    return
                }
                
                guard indexPath != selectedIndexPath else { return }
            
                selectedIndexPath = indexPath
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        
            case .ended:
            
                guard let indexPath = selectedIndexPath else { return }
                
                if let cell = tableView.cellForRow(at: indexPath) as? SettingsTableViewCell, let view = cell.accessoryButton.superview, view.convert(cell.accessoryButton.frame, to: cell.contentView).contains(sender.location(in: cell)) {
                    
                    accessoryButtonTapped(in: cell)
                    
                    return
                }
                
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
