//
//  VerticalPresentationContainerViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 29/01/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias AccessoryButtonAction = ((MELButton, UIViewController) -> ())
typealias SegmentDetails = (array: [SimpleCollectionInfo], actions: [((UIViewController?) -> ())])

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
    @IBOutlet var segmentedCollectionView: UICollectionView!
    @IBOutlet var staticCollectionView: UICollectionView!
    @IBOutlet var rightButton: MELButton!
    @IBOutlet var rightButtonBorderView: MELBorderView!
    @IBOutlet var rightView: UIView!
    @IBOutlet var leftButton: MELButton!
    @IBOutlet var leftButtonBorderView: MELBorderView!
    @IBOutlet var leftView: UIView!
    @IBOutlet var tableView: MELTableView!
    @IBOutlet var segmentedShadowImageView: ShadowImageView!
    @IBOutlet var staticView: UIView!
    @IBOutlet var staticViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var staticStackView: UIStackView!
    @IBOutlet var hideableShadowView: UIView!
    @IBOutlet var middleHideableShadowView: UIView!
    
    enum Context { case sort, actions, alert } // actions referring to actionsVC
    enum RelevantView { case segmentedCollectionView, staticCollectionView, tableView }
    
    var context = Context.actions
    let transitioner = SimplePresentationAnimationController.init(orientation: .vertical)
    var subtitle: String?
    var requiresTopView = true
    var requiresSegmentedControl = false
    var requiresTopBorderView = false
    var requiresStaticView = false
    lazy var segments = [SimpleCollectionInfo]()
    var staticOptions = [SimpleCollectionInfo]()
    lazy var shadowViews = [UIView]()
    lazy var cancelAction = AlertAction.init(info: AlertInfo.init(title: {
        
        switch self.context {
            
            case .alert: return "Cancel"
            
            case .actions, .sort: return "Close"
        }
        
    }(), accessoryType: .none), handler: nil)
    
    var leftButtonAction: AccessoryButtonAction?
    var rightButtonAction: AccessoryButtonAction?
    
    var highlightedSegmentedIndexPath: IndexPath? {
        
        didSet {
            
            guard highlightedSegmentedIndexPath != oldValue, let indexPath = oldValue else { return }
            
            segmentedCollectionView.deselectItem(at: indexPath, animated: false)
        }
    }
    
    var selectedSegmentedIndexPath: IndexPath? {
        
        didSet {
            
            guard selectedSegmentedIndexPath != oldValue, let indexPath = selectedSegmentedIndexPath else { return }
            
            segmentedCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
    }
    
    var highlightedStaticIndexPath: IndexPath? {
        
        didSet {
            
            guard highlightedStaticIndexPath != oldValue, let indexPath = oldValue else { return }
            
            staticCollectionView.deselectItem(at: indexPath, animated: false)
        }
    }
    
    var selectedStaticIndexPath: IndexPath? {
        
        didSet {
            
            guard selectedStaticIndexPath != oldValue, let indexPath = selectedStaticIndexPath else { return }
            
            staticCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
    }
    
    var selectedTableIndexPath: IndexPath? {
        
        didSet {
            
            guard selectedTableIndexPath != oldValue, let indexPath = oldValue else { return }
            
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    lazy var applyToCurrentItem = false
    
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
        
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(gestureActivated))
        effectViewsContainer.addGestureRecognizer(pan)
        
        [cancelButtonHeightConstraint, segmentedViewHeightConstraint, staticViewHeightConstraint].forEach({ $0.constant = FontManager.shared.settingCellHeight + 2 })
        tableView.rowHeight = FontManager.shared.settingCellHeight + 2
        
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
        labelsStackView.layoutMargins.top = requiresTopView ? 0 : 8
        labelsStackView.layoutMargins.bottom = context == .alert && alertVC.actions.first?.info.subtitle == nil ? 20 : 8
        topView.isHidden = requiresTopView.inverted
        topBorderView.isHidden = requiresTopBorderView.inverted
        
        if requiresStaticView {

            hideableShadowView.isHidden = staticOptions.count < 3
            middleHideableShadowView.isHidden = staticOptions.count < 2
        }
        
        [segmentedEffectView, segmentedShadowImageView].forEach({ $0.isHidden = requiresSegmentedControl.inverted })
        
        [staticView, staticStackView].forEach({ $0.isHidden = requiresStaticView.inverted })
        
        leftView.isHidden = leftButtonAction == nil
        rightView.isHidden = rightButtonAction == nil
        
        let images: (left: UIImage?, right: UIImage?) = {
            
            switch context {
                
                case .actions: return (#imageLiteral(resourceName: "Locked13"), #imageLiteral(resourceName: "Settings"))
                
                case .alert: return (nil, #imageLiteral(resourceName: "InfoNoBorder13"))
                
                case .sort: return (#imageLiteral(resourceName: "Locked13"), nil)
            }
        }()
        
        leftButton.setImage(images.left, for: .normal)
        rightButton.setImage(images.right, for: .normal)
        
        if [Context.actions, .sort].contains(context) {
            
            leftButtonBorderView.bordered = true
            leftButtonBorderView.clear = true
            leftButtonBorderView.layer.borderWidth = 1.2
        }
        
        if requiresSegmentedControl {
            
            segmentedCollectionView.delegate = self
            segmentedCollectionView.dataSource = self
            segmentedCollectionView.register(UINib.init(nibName: "GestureSelectableCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        }
        
        if requiresStaticView {
            
            staticCollectionView.delegate = self
            staticCollectionView.dataSource = self
            staticCollectionView.register(UINib.init(nibName: "GestureSelectableCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        }
        
        activeViewController = {
            
            switch context {
                
                case .sort: return arrangeVC
                
                case .actions: return actionsVC
                
                case .alert: return alertVC
            }
        }()
    }
    
    @IBAction func leftButtonTapped(_ sender: MELButton) {
        
        leftButtonAction?(sender, self)
    }
    
    @IBAction func rightButtonTapped(_ sender: MELButton) {
        
        rightButtonAction?(sender, self)
    }
    
    @objc func gestureActivated(_ sender: UIGestureRecognizer) {
        
        if containerView.frame.contains(sender.location(in: effectViewsContainer)) {
            
            noSelection(of: .tableView)
            noSelection(of: .segmentedCollectionView)
            noSelection(of: .staticCollectionView, allowStaticViewSelection: false)
            
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
                        
                        noSelection(of: .segmentedCollectionView)
                        noSelection(of: .staticCollectionView)
                        
                        guard indexPath != selectedTableIndexPath else { return }
                        
                        selectedTableIndexPath = indexPath
                        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                        
                    } else if let indexPath = segmentedCollectionView.indexPathForItem(at: sender.location(in: segmentedEffectView)) {
                        
                        noSelection(of: .tableView)
                        noSelection(of: .staticCollectionView)
                        
                        guard indexPath != highlightedSegmentedIndexPath else { return }
                        
                        highlightedSegmentedIndexPath = indexPath
                        segmentedCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    
                    } else if let indexPath = staticCollectionView.indexPathForItem(at: sender.location(in: staticView)) {
                        
                        noSelection(of: .tableView)
                        noSelection(of: .segmentedCollectionView)
                        
                        if context == .alert, case .select = alertVC.context { return }
                        
                        guard indexPath != highlightedStaticIndexPath else { return }
                        
                        highlightedStaticIndexPath = indexPath
                        staticCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        
                    } else {
                        
                        noSelection(of: .tableView)
                        noSelection(of: .segmentedCollectionView)
                        noSelection(of: .staticCollectionView)
                    }

                case .ended:
                
                    if let indexPath = tableView.indexPathForRow(at: sender.location(in: cancelEffectView)) {
                        
                        noSelection(of: .segmentedCollectionView)
                        noSelection(of: .staticCollectionView)
                        
                        tableView(tableView, didSelectRowAt: indexPath)
                        
                    } else if let indexPath = segmentedCollectionView.indexPathForItem(at: sender.location(in: segmentedEffectView)) {
                        
                        noSelection(of: .tableView)
                        noSelection(of: .staticCollectionView)
                        
                        collectionView(segmentedCollectionView, didSelectItemAt: indexPath)
                    
                    } else if let indexPath = staticCollectionView.indexPathForItem(at: sender.location(in: staticView)) {
                        
                        noSelection(of: .tableView)
                        noSelection(of: .segmentedCollectionView)
                        
                        collectionView(staticCollectionView, didSelectItemAt: indexPath)
                        
                    } else {
                        
                        noSelection(of: .tableView)
                        noSelection(of: .segmentedCollectionView)
                        noSelection(of: .staticCollectionView)
                    }

                default:
                    
                    noSelection(of: .tableView)
                    noSelection(of: .segmentedCollectionView)
                    noSelection(of: .staticCollectionView)
            }
        }
    }
    
    func noSelection(of view: RelevantView, allowStaticViewSelection: Bool = true) {
        
        switch view {
            
            case .tableView:
            
                if let _ = selectedTableIndexPath {
                    
                    selectedTableIndexPath = nil
                }
            
            case .segmentedCollectionView:
            
                if let _ = highlightedSegmentedIndexPath {
                    
                    highlightedSegmentedIndexPath = nil
                }
            
                guard let indexPath = selectedSegmentedIndexPath else { return }
                
                segmentedCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            
            case .staticCollectionView:
            
                if let _ = highlightedStaticIndexPath {
                    
                    highlightedStaticIndexPath = nil
                }
                
                guard let indexPath = selectedStaticIndexPath else { return }
                
                if allowStaticViewSelection {
                
                    staticCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            
                } else {
                    
                    staticCollectionView.deselectItem(at: indexPath, animated: false)
                }
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
        
        return (collectionView == segmentedCollectionView ? segments : staticOptions).count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GestureSelectableCollectionViewCell
        
        let deepSelectMode: Bool = {
            
            if collectionView == staticCollectionView, context == .alert, case .select = alertVC.context {
                
                return true
            }
            
            return false
        }()
        
        let segment = (collectionView == segmentedCollectionView ? segments : staticOptions)[indexPath.item]
        cell.prepare(with: segment.title, subtitle: segment.subtitle, image: segment.image, style: .alert, switchDetails: deepSelectMode ? (applyToCurrentItem, { self.applyToCurrentItem.toggle(); print("eh") }) : nil)
        cell.useBorderView = collectionView == staticCollectionView
        cell.useEffectView = collectionView == staticCollectionView
        cell.inset = collectionView == staticCollectionView ? 0 : 10
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == segmentedCollectionView {
            
            guard let child = children.first as? SegmentedResponder else { return }
            
            child.selectedSegment(at: indexPath.item)
            
        } else {
            
            guard let child = children.first as? StaticOptionResponder else { return }
            
            child.selectedStaticOption(at: indexPath.item)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        
        if collectionView == staticCollectionView, context == .alert, case .select = alertVC.context {
            
            return false
        }
        
        return true
    }
}

extension VerticalPresentationContainerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.settingCell(for: indexPath)
        
        cell.prepare(with: cancelAction)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            
        dismiss(animated: true, completion: nil)
    }
}

extension VerticalPresentationContainerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let constant = collectionView == staticCollectionView ? 6 * (staticOptions.count - 1) : 0
        let preferredArray = collectionView == staticCollectionView ? staticOptions : segments
        
        return CGSize.init(width: (screenWidth - 12 - CGFloat(constant)) / CGFloat(max(1, preferredArray.count)), height: FontManager.shared.settingCellHeight + 2)
    }
}

protocol GestureSelectable {
    
    func selectCell(_ sender: UIGestureRecognizer)
    func noSelection()
}

protocol SegmentedResponder {
    
    func selectedSegment(at index: Int)
}

protocol StaticOptionResponder {
    
    func selectedStaticOption(at index: Int)
}

struct SimpleCollectionInfo {
    
    let title: String?
    let subtitle: String?
    let image: UIImage?
    
    init(title: String, subtitle: String? = nil, image: UIImage? = nil) {
        
        self.title = title
        self.subtitle = subtitle
        self.image = image
    }
}
//
//struct CancelContainingPresentationControllerBehaviours: OptionSet {
//
//    let rawValue: Int
//    typealias RawValue = Int
//}
