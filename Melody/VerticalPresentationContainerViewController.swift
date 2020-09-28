//
//  VerticalPresentationContainerViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 29/01/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias AccessoryButtonAction = (MELButton, UIViewController) -> Void
typealias SegmentDetails = (array: [SimpleCollectionInfo], actions: [((UIViewController?) -> ())])
typealias UnwindAction = (VerticalPresentationContainerViewController) -> Void
typealias PreviewAction = (UIViewController) -> UIViewController?
typealias HeaderButtonImages = (left: UIImage?, right: UIImage?)

class VerticalPresentationContainerViewController: UIViewController, PreviewTransitionable, ThemeStatusProvider {

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
    @IBOutlet var topStackView: SubviewIgnoringStackView!
    @IBOutlet var labelsStackView: UIStackView!
    @IBOutlet var topView: UIView!
    @IBOutlet var topBorderView: MELBorderView!
    @IBOutlet var topEntityImageView: InvertIgnoringImageView! {
        
        didSet {
            
            topEntityImageView.provider = self
        }
    }
    @IBOutlet var topThemedImageView: MELImageView!
    @IBOutlet var topThemedImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var topBarView: MELBorderView!
    @IBOutlet var segmentedViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var segmentedEffectView: MELVisualEffectView!
    @IBOutlet var cancelEffectView: MELVisualEffectView!
    @IBOutlet var segmentedCollectionView: UICollectionView!
    @IBOutlet var rightButton: MELButton!
    @IBOutlet var rightButtonBorderView: MELBorderView!
    @IBOutlet var rightView: UIView!
    @IBOutlet var leftButton: MELButton!
    @IBOutlet var leftButtonBorderView: MELBorderView!
    @IBOutlet var leftBorderedBorderView: MELBorderView!
    @IBOutlet var leftView: UIView!
    @IBOutlet var tableView: MELTableView!
    @IBOutlet var topTableView: MELTableView!
    @IBOutlet var segmentedShadowImageView: ShadowImageView!
    @IBOutlet var dividerContainerView: UIView!
    
    enum Context { case sort, actions, alert } // actions referring to actionsVC
    enum RelevantView { case collectionView, tableView, topTableView }
    enum TopHeaderMode { case bar, entityImage(EntityArtworkType, type: EntityType), themedImage(name: String, height: CGFloat) }
    
    var viewController: UIViewController?
    var isCurrentlyTopViewController: Bool = false
    
    var context = Context.actions
    var topHeaderMode = TopHeaderMode.bar
    let transitioner = SimplePresentationAnimationController.init(orientation: .vertical)
    var subtitle: String?
    var requiresTopView = true
    var requiresSegmentedControl: Bool { segments.isEmpty.inverted }
    var requiresTopBorderView = false
    var segments = [SimpleCollectionInfo]()
    lazy var cancelAction = AlertAction.init(info: AlertInfo.init(title: {
        
        switch self.context {
            
            case .alert: return "Cancel"
            
            case .actions, .sort: return "Close"
        }
        
    }(), accessoryType: .none), handler: nil)
    
    var topAction: UnwindAction?
    var topPreviewAction: PreviewAction?
    var leftButtonAction: AccessoryButtonAction?
    var rightButtonAction: AccessoryButtonAction?
    
    lazy var images: HeaderButtonImages = {
        
        switch context {
            
            case .actions: return (#imageLiteral(resourceName: "Locked13"), #imageLiteral(resourceName: "Settings13"))
            
            case .alert: return (nil, #imageLiteral(resourceName: "InfoNoBorder13"))
            
            case .sort: return (#imageLiteral(resourceName: "Locked13"), nil)
        }
    }()
    
    var highlightedCollectionIndexPath: IndexPath? {
        
        didSet {
            
            guard highlightedCollectionIndexPath != oldValue, let indexPath = oldValue, indexPath != selectedCollectionIndexPath, let cell = segmentedCollectionView.cellForItem(at: indexPath) else { return }
            
            cell.isHighlighted = false
        }
    }
    
    var selectedCollectionIndexPath: IndexPath? {
        
        didSet {
            
            guard selectedCollectionIndexPath != oldValue, let indexPath = selectedCollectionIndexPath, let cell = segmentedCollectionView.cellForItem(at: indexPath) else { return }
            
            if context == .alert {
                
                switch alertVC.context {
                    
                    case .show,
                         .queue(title: _, kind: _, context: _),
                         .other where segments.count == 1: cell.isHighlighted = true
                    
                    default: cell.isSelected = true
                }
                
            } else {
            
                cell.isSelected = true
            }
        }
    }
    
    var selectedTableIndexPath: IndexPath? {
        
        didSet {
            
            guard selectedTableIndexPath != oldValue, let indexPath = oldValue else { return }
            
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    var selectedTopTableIndexPath: IndexPath? {
        
        didSet {
            
            guard selectedTopTableIndexPath != oldValue, let indexPath = oldValue else { return }
            
            topTableView.deselectRow(at: indexPath, animated: false)
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
        
        leftView.bringSubviewToFront(leftButton)
        rightView.bringSubviewToFront(rightButton)

        prepareGestures()
        
        [cancelButtonHeightConstraint, segmentedViewHeightConstraint].forEach({ $0.constant = FontManager.shared.settingCellHeight + 2 })
        
        if requiresSegmentedControl.inverted {
            
            segmentedViewHeightConstraint.constant = 0
        
        } else {
            
            segmentedCollectionView.delegate = self
            segmentedCollectionView.dataSource = self
            segmentedCollectionView.register(UINib.init(nibName: "GestureSelectableCell", bundle: nil), forCellWithReuseIdentifier: "cell")
            
            if segments.count > 2 {
                
                let constant: (Int) -> CGFloat = { (self.view.frame.width - 12) / CGFloat(self.segments.count * $0) }
                
                (0..<segments.count - 1).enumerated().forEach({ offset, _ in
                    
                    let subview = MELBorderView.init(override: 0.05)
                    subview.translatesAutoresizingMaskIntoConstraints = false
                    subview.layer.cornerRadius = 1
                    subview.tag = offset
                    
                    dividerContainerView.addSubview(subview)
                    subview.widthAnchor.constraint(equalToConstant: 2).isActive = true
                    subview.leadingAnchor.constraint(equalTo: dividerContainerView.leadingAnchor, constant: (UIScreen.main.scale * constant(offset + 1)) - 1).isActive = true
                    subview.topAnchor.constraint(equalTo: dividerContainerView.topAnchor, constant: 8).isActive = true
                    subview.bottomAnchor.constraint(equalTo: dividerContainerView.bottomAnchor, constant: -8).isActive = true
                })
                
            }
        }
        
        prepareTopHeader()
        
        topTableView.isUserInteractionEnabled = topAction != nil
        topTableView.isHidden = topAction == nil
        topTableView.rowHeight = topTableView.frame.height
        tableView.rowHeight = FontManager.shared.settingCellHeight + 2
        
        [segmentedEffectView, segmentedShadowImageView].forEach({ $0.isHidden = requiresSegmentedControl.inverted })
        
        activeViewController = {
            
            switch context {
                
                case .sort: return arrangeVC
                
                case .actions: return actionsVC
                
                case .alert: return alertVC
            }
        }()
        
        registerForPreviewing(with: self, sourceView: topTableView)
    }
    
    func updateDividerViews(with indexPath: IndexPath) {
        
        
    }
    
    func prepareTopHeader() {
        
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
        labelsStackView.layoutMargins.top = {
            
            switch topHeaderMode {
                
                case .themedImage(name: _, height: _): return context == .alert && alertVC.actions.first?.info.subtitle == nil ? 0 : 8
                
                default: return requiresTopView ? 0 : 8
            }
        }()
        labelsStackView.layoutMargins.bottom = context == .alert && (alertVC.actions.isEmpty.inverted && alertVC.actions.first?.info.subtitle == nil) ? 20 : 8
        topView.isHidden = requiresTopView.inverted
        topBorderView.isHidden = requiresTopBorderView.inverted
        labelsStackView.isHidden = title == nil && subtitle == nil
        
        topStackView.frames.append(.init(origin: .zero, size: .init(width: 52, height: 53)), if: leftButtonAction != nil)
        topStackView.frames.append(.init(x: screenWidth - 12 - 52, y: 0, width: 52, height: 53), if: rightButtonAction != nil)
        
        leftView.isHidden = leftButtonAction == nil
        rightView.isHidden = rightButtonAction == nil
        
        leftButton.setImage(images.left, for: .normal)
        rightButton.setImage(images.right, for: .normal)
        
        switch topHeaderMode {
            
            case .bar:
            
                topEntityImageView.superview?.isHidden = true
                topThemedImageView.isHidden = true
            
            case .entityImage(let artworkType, type: let type):
            
                topBarView.isHidden = true
                topThemedImageView.isHidden = true
                topEntityImageView.image = artworkType.artwork
                
                (listsCornerRadius ?? cornerRadius).updateCornerRadius(on: topEntityImageView.layer, width: 30, entityType: type, globalRadiusType: cornerRadius)
                
                if let superview = topEntityImageView.superview {
                    
                    UniversalMethods.addShadow(to: superview, radius: 4, opacity: 0.35, shouldRasterise: true)
                }
            
            case .themedImage(name: let name, height: let height):
            
                topBarView.isHidden = true
                topEntityImageView.superview?.isHidden = true
                
                topThemedImageViewHeightConstraint.constant = height
                topThemedImageView.image = #imageLiteral(resourceName: name)
        }
    }
    
    func prepareGestures() {
        
        let gr = UITapGestureRecognizer.init(target: self, action: #selector(dismissVC))
        gr.delegate = self
        view.addGestureRecognizer(gr)
        
        let swipe = UISwipeGestureRecognizer.init(target: self, action: #selector(dismissVC(_:)))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
        
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(gestureActivated))
        effectViewsContainer.addGestureRecognizer(pan)
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
            noSelection(of: .collectionView)
            noSelection(of: .topTableView)
            
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
                        noSelection(of: .topTableView)
                        
                        guard indexPath != selectedTableIndexPath else { return }
                        
                        selectedTableIndexPath = indexPath
                        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                        
                    } else if let indexPath = topTableView.indexPathForRow(at: sender.location(in: effectView)), leftView.convert(leftButton.frame, to: topView).contains(sender.location(in: effectView)).inverted, rightView.convert(rightButton.frame, to: topView).contains(sender.location(in: effectView)).inverted {
                        
                        noSelection(of: .collectionView)
                        noSelection(of: .tableView)
                        
                        guard indexPath != selectedTopTableIndexPath else { return }
                        
                        selectedTopTableIndexPath = indexPath
                        topTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                        
                    } else if let indexPath = segmentedCollectionView.indexPathForItem(at: sender.location(in: segmentedEffectView)) {
                        
                        noSelection(of: .tableView)
                        noSelection(of: .topTableView)
                        
                        guard indexPath != highlightedCollectionIndexPath, let cell = segmentedCollectionView.cellForItem(at: indexPath) as? GestureSelectableCollectionViewCell else { return }
                        
                        highlightedCollectionIndexPath = indexPath
                        
                        if indexPath != selectedCollectionIndexPath {

                            cell.isHighlighted = true
                        }
                    
                    } else {
                        
                        noSelection(of: .tableView)
                        noSelection(of: .collectionView)
                        noSelection(of: .topTableView)
                    }

                case .ended:
                    
                    if leftView.convert(leftButton.frame, to: topView).contains(sender.location(in: effectView)), let action = leftButtonAction {
                        
                        action(leftButton, self)
                        
                    } else if rightView.convert(rightButton.frame, to: topView).contains(sender.location(in: effectView)), let action = rightButtonAction {
                        
                        action(rightButton, self)
                        
                    } else if let indexPath = topTableView.indexPathForRow(at: sender.location(in: effectView)) {
                        
                        noSelection(of: .collectionView)
                        noSelection(of: .tableView)
                        
                        tableView(topTableView, didSelectRowAt: indexPath)
                        
                    } else if let indexPath = tableView.indexPathForRow(at: sender.location(in: cancelEffectView)) {
                        
                        noSelection(of: .collectionView)
                        noSelection(of: .topTableView)
                        
                        tableView(tableView, didSelectRowAt: indexPath)
                        
                    } else if let indexPath = segmentedCollectionView.indexPathForItem(at: sender.location(in: segmentedEffectView)) {
                        
                        noSelection(of: .tableView)
                        noSelection(of: .topTableView)
                        
                        collectionView(segmentedCollectionView, didSelectItemAt: indexPath)
                    
                    } else {
                        
                        noSelection(of: .tableView)
                        noSelection(of: .collectionView)
                        noSelection(of: .topTableView)
                    }

                default:
                    
                    noSelection(of: .tableView)
                    noSelection(of: .collectionView)
                    noSelection(of: .topTableView)
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
            
                if let _ = highlightedCollectionIndexPath {
                    
                    highlightedCollectionIndexPath = nil
                }
            
            case .topTableView:
            
                if let _ = selectedTopTableIndexPath {
                    
                    selectedTopTableIndexPath = nil
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
        
        segments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GestureSelectableCollectionViewCell
        
        let segment = segments[indexPath.item]
        cell.prepare(with: segment.title, subtitle: segment.subtitle, image: segment.image, style: .alert)
        cell.useBorderView = false
        cell.useEffectView = false
        cell.inset = 10
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        if context == .alert {
            
            switch alertVC.context {
                
                case .show,
                     .queue(title: _, kind: _, context: _),
                     .other where segments.count == 1:
                
                    self.collectionView(collectionView, didSelectItemAt: indexPath)
                    
                    return false
                
                default: break
            }
        }
        
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let old = selectedCollectionIndexPath, old != indexPath {
            
            selectedCollectionIndexPath = nil
            collectionView.cellForItem(at: old)?.isSelected = false
        }
        
        selectedCollectionIndexPath = indexPath
        
        guard let child = children.first as? SegmentedResponder else { return }
        
        child.selectedSegment(at: indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if indexPath == selectedCollectionIndexPath {
            
            cell.isSelected = true
        }
    }
}

extension VerticalPresentationContainerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == topTableView {
            
            let cell = tableView.regularCell(for: indexPath)
            
            return cell
        }
        
        let cell = tableView.settingCell(for: indexPath)
        
        cell.prepare(with: cancelAction)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == topTableView {
            
            topAction?(self)
            
            return
        }
            
        dismiss(animated: true, completion: nil)
    }
}

extension VerticalPresentationContainerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize.init(width: (screenWidth - 12) / CGFloat(max(1, segments.count)), height: FontManager.shared.settingCellHeight + 2)
    }
}

extension VerticalPresentationContainerViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let action = topPreviewAction else { return nil }
    
        return action(self)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        performCommitActions(on: viewControllerToCommit)
        
        viewController = viewControllerToCommit
        
        performSegue(withIdentifier: "preview", sender: nil)
    }
}

protocol GestureSelectable {
    
    func selectCell(_ sender: UIGestureRecognizer)
    func noSelection()
}

protocol SegmentedResponder {
    
    func selectedSegment(at index: Int)
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

class SubviewIgnoringStackView: UIStackView {
    
    var frames = [CGRect]()
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        if let _ = frames.first(where: { $0.contains(point) }) {
            
            return true
        }
        
        return false
    }
}
