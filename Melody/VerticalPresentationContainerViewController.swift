//
//  VerticalPresentationContainerViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 29/01/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class VerticalPresentationContainerViewController: UIViewController {

    @IBOutlet var effectView: MELVisualEffectView! {
        
        didSet {
            
            effectView.layer.setRadiusTypeIfNeeded()
            effectView.layer.cornerRadius = 15
        }
    }
    @IBOutlet var titleLabel: MELLabel!
    @IBOutlet var containerView: UIView!
    @IBOutlet var containerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var effectViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var cancelButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet var effectViewsContainer: UIView!
    @IBOutlet var subtitleLabel: MELLabel!
    @IBOutlet var topStackView: UIStackView!
    @IBOutlet var labelsStackView: UIStackView!
    @IBOutlet var topView: UIView!
    @IBOutlet var topBorderView: MELBorderView!
    @IBOutlet var segmentedViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var segmentedEffectView: MELVisualEffectView!
    @IBOutlet var cancelEffectView: MELVisualEffectView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var rightButton: MELButton!
    @IBOutlet var rightButtonBorderView: MELBorderView!
    @IBOutlet var rightView: UIView!
    @IBOutlet var leftButton: MELButton!
    @IBOutlet var leftButtonBorderView: MELBorderView!
    @IBOutlet var leftView: UIView!
    @IBOutlet var tableView: MELTableView!
    @IBOutlet var segmentedShadowImageView: ShadowImageView!
    
    enum Context { case insert, sort, actions, show }
    enum RelevantView { case collectionView, tableView }
    
    var context = Context.actions
    let transitioner = SimplePresentationAnimationController.init(orientation: .vertical)
    var subtitle: String?
    lazy var requiresTopView = [Context.actions, .sort/*, .show*/].contains(self.context)
    lazy var requiresSegmentedControl = self.context == .sort
    lazy var segments = [(text: String?, image: UIImage?)]()
    lazy var setting = Setting.init(title: "Cancel", accessoryType: .none)
    
    var highlightedIndexPath: IndexPath? {
        
        didSet {
            
            guard highlightedIndexPath != oldValue, let indexPath = oldValue else { return }
            
            collectionView.deselectItem(at: indexPath, animated: false)
        }
    }
    
    var selectedIndexPath: IndexPath? {
        
        didSet {
            
            guard selectedIndexPath != oldValue, let indexPath = selectedIndexPath else { return }
            
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        }
    }
    
    var selectedTableIndexPath: IndexPath? {
        
        didSet {
            
            guard selectedTableIndexPath != oldValue, let indexPath = oldValue else { return }
            
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
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
    
    lazy var alertVC: AlertTableViewController = {
        
        return popoverStoryboard.instantiateViewController(withIdentifier: String.init(describing: AlertTableViewController.self)) as! AlertTableViewController
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        let gr = UITapGestureRecognizer.init(target: self, action: #selector(dismissVC))
        gr.delegate = self
        view.addGestureRecognizer(gr)
        
        let swipe = UISwipeGestureRecognizer.init(target: self, action: #selector(dismissVC(_:)))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
        
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(panActivated(_:)))
        effectViewsContainer.addGestureRecognizer(pan)
        
        [cancelButtonHeightConstraint, segmentedViewHeightConstraint].forEach({ $0.constant = FontManager.shared.settingCellHeight + 2 })
        tableView.rowHeight = FontManager.shared.settingCellHeight + 2
        
        subtitleLabel.isHidden = subtitle == nil
        labelsStackView.layoutMargins.top = requiresTopView ? 0 : 8
        topView.isHidden = requiresTopView.inverted
        topBorderView.isHidden = true //context != .show
        [segmentedEffectView, segmentedShadowImageView].forEach({ $0.isHidden = requiresSegmentedControl.inverted })
        
        leftView.isHidden = [Context.insert, .show].contains(context)
        rightView.isHidden = [Context.insert, .sort, .show].contains(context)
        
        let images: (left: UIImage?, right: UIImage?) = {
            
            switch context {
                
                case .actions: return (#imageLiteral(resourceName: "Locked13"), #imageLiteral(resourceName: "Settings"))
                
                case .insert: return (nil, nil)
                
                case .show: return (nil, #imageLiteral(resourceName: "InfoNoBorder13"))
                
                case .sort: return (#imageLiteral(resourceName: "Locked13"), nil)
            }
        }()
        
        leftButton.setImage(images.left, for: .normal)
        rightButton.setImage(images.right, for: .normal)
        
        if [Context.actions, .sort].contains(context) {
            
            leftButtonBorderView.bordered = true
            leftButtonBorderView.clear = true
//            leftButtonBorderView.alphaOverride = 0.02
            leftButtonBorderView.layer.borderWidth = 1.2
        }
        
        if requiresSegmentedControl {
            
            collectionView.delegate = self
            collectionView.dataSource = self
            
            collectionView.register(UINib.init(nibName: "GestureSelectableCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        }
        
        activeViewController = {
            
            switch context {
                
                case .insert: return insertVC
                
                case .sort: return arrangeVC
                
                case .actions: return actionsVC
                
                case .show: return alertVC
            }
        }()
    }
    
    @objc func panActivated(_ sender: UIPanGestureRecognizer) {
        
        if containerView.frame.contains(sender.location(in: effectViewsContainer)) {
            
            noSelection(of: .tableView)
            noSelection(of: .collectionView)
            
            if let child = children.first as? GestureSelectable {
            
                child.selectCell(sender)
            }
            
        } else {
            
            if let child = children.first as? GestureSelectable {
                
                child.noSelection()
            }
            
            switch sender.state {

                case .began, .changed:
                    
                    if let indexPath = tableView.indexPathForRow(at: sender.location(in: cancelEffectView)) {
                        
                        noSelection(of: .collectionView)
                        
                        guard indexPath != selectedTableIndexPath else { return }
                        
                        selectedTableIndexPath = indexPath
                        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                        
                    } else if let indexPath = collectionView.indexPathForItem(at: sender.location(in: segmentedEffectView)) {
                        
                        noSelection(of: .tableView)
                        
                        guard indexPath != highlightedIndexPath else { return }
                        
                        highlightedIndexPath = indexPath
                        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                    
                    } else {
                        
                        noSelection(of: .tableView)
                        noSelection(of: .collectionView)
                    }

                case .ended:
                
                    if let indexPath = tableView.indexPathForRow(at: sender.location(in: cancelEffectView)) {
                        
                        noSelection(of: .collectionView)
                        
                        tableView(tableView, didSelectRowAt: indexPath)
                        
                    } else if let indexPath = collectionView.indexPathForItem(at: sender.location(in: segmentedEffectView)) {
                        
                        noSelection(of: .tableView)
                        
                        collectionView(collectionView, didSelectItemAt: indexPath)
                    
                    } else {
                        
                        noSelection(of: .tableView)
                        noSelection(of: .collectionView)
                    }

                default:
                    
                    noSelection(of: .tableView)
                    noSelection(of: .collectionView)
            }
        }
    }
    
    func noSelection(of view: RelevantView) {
        
        switch view {
            
            case .tableView:
            
                if let _ = selectedTableIndexPath {
                    
                    selectedTableIndexPath = nil
                }
            
            case .collectionView:
            
                if let _ = highlightedIndexPath {
                    
                    highlightedIndexPath = nil
                }
            
                guard let indexPath = selectedIndexPath else { return }
                
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        }
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
        
        return !effectViewsContainer.frame.contains(gestureRecognizer.location(in: view))
    }
}

extension VerticalPresentationContainerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return segments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GestureSelectableCollectionViewCell
        
        let segment = segments[indexPath.item]
        cell.prepare(with: segment.text, image: segment.image, style: .alert)
        cell.useBorderView = false
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let child = children.first as? SegmentedResponder else { return }
        
        child.selectedSegment(at: indexPath.item)
    }
}

extension VerticalPresentationContainerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.settingCell(for: indexPath)
        
        cell.prepare(with: setting, context: .alert(cancel: true), alignment: .center)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            
        dismiss(animated: true, completion: nil)
    }
}

extension VerticalPresentationContainerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize.init(width: (screenWidth - 12) / CGFloat(max(1, segments.count)), height: FontManager.shared.settingCellHeight + 2)
    }
}

protocol GestureSelectable {
    
    func selectCell(_ sender: UIPanGestureRecognizer)
    func noSelection()
}

protocol SegmentedResponder {
    
    func selectedSegment(at index: Int)
}
