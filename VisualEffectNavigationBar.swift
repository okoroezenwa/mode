//
//  HeaderEffectView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 18/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias NavigatableDetails = (title: String?, backLabelText: String?)

var barConstant: Int { return prefs.integer(forKey: "barConstant") }

class VisualEffectNavigationBar: MELVisualEffectView {

    @IBOutlet var stackView: UIStackView!
    @IBOutlet var titleLabel: MELLabel!
    @IBOutlet var backLabel: MELLabel!
    @IBOutlet var artworkContainer: InvertIgnoringView!
    @IBOutlet var artworkImageView: InvertIgnoringImageView!
    @IBOutlet var clearButtonView: UIView!
    @IBOutlet var entityImageView: MELImageView!
    @IBOutlet var entityImageViewContainer: UIView!
    @IBOutlet var backView: UIView!
    @IBOutlet var backBorderView: UIView!
    @IBOutlet var titleScrollView: MELScrollView!
    @IBOutlet var gradientView: GradientView!
    @IBOutlet var artworkView: UIView!
    @IBOutlet var rightButton: UIButton!
    @IBOutlet var rightView: UIView!
    @IBOutlet var rightViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var stackViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var clearBorderView: MELBorderView!
    @IBOutlet var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet var titleLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet var backStackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var titleStackViewEqualHeightConstraint: NSLayoutConstraint!
    @IBOutlet var backStackViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var backBorderViewContainer: UIView!
    @IBOutlet var backBorderViewContainerBottomConstraint: NSLayoutConstraint!
    
    var stackViewTopConstraint: NSLayoutConstraint!
    
    enum AnimationSection { case preparation, firstHalf, secondHalf, end(completed: Bool) }
    enum RightViewMode { case none, button(hidden: Bool), artwork(UIImage?, details: RadiusDetails) }
    
    enum Location {
        
        case main, entity
        
        var inset: CGFloat {
            
            switch self {
                
                case .main: return (2 * FontManager.shared.navigationBarSpacing) + (FontManager.shared.heightsDictionary[.heading] ?? 0) + 1
                
                case .entity:
                    
                    let height = FontManager.shared.backLabelHeight + FontManager.shared.navigationBarTopConstant
                    
                    return (3 * FontManager.shared.navigationBarSpacing) + (FontManager.shared.heightsDictionary[.heading] ?? 0) + height + 1
            }
        }
        
        var constant: CGFloat {
            
            switch self {
                
                case .main: return (barConstant > 0 ? FontManager.shared.navigationBarSpacing : 0) + (barConstant > 1 ? FontManager.shared.backLabelHeight + FontManager.shared.navigationBarTopConstant : 0)
                
                case .entity: return 0
            }
        }
        
        var total: CGFloat { return inset + constant }
    }
    
    var titleLabelSnapshot: UIView? { didSet { oldValue?.removeFromSuperview() } }
    var backLabelSnapshot: UIView? { didSet { oldValue?.removeFromSuperview() } }
    var backBorderViewSnapshot: UIView? { didSet { oldValue?.removeFromSuperview() } }
    var rightViewSnapshot: UIView? { didSet { oldValue?.removeFromSuperview() } }
    var rightButtonSnapshot: UIView? { didSet { oldValue?.removeFromSuperview() } }
    
    var isAnimatingTitles = false
    var isAnimatingRightView = false
    
    var containerVC: ContainerViewController? { return appDelegate.window?.rootViewController as? ContainerViewController }
    
    let verticalTranslation: CGFloat = 20
    let horizontalTranslation: CGFloat = 40
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(dismiss))
        titleScrollView.addGestureRecognizer(tap)
        
        contentView.bringSubviewToFront(rightButton)
        updateSpacing(self)
        
        notifier.addObserver(self, selector: #selector(updateSpacing), name: .lineHeightsCalculated, object: nil)
        
        if isInDebugMode {
            
            let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(viewTemporarySettings))
            gr.minimumPressDuration = 0.3
            addGestureRecognizer(gr)
        }
    }
    
    @objc func updateSpacing(_ sender: Any) {
        
        [titleLabelTopConstraint, titleLabelBottomConstraint].forEach({ $0?.constant = FontManager.shared.navigationBarSpacing })
        
        backStackViewTopConstraint.constant = FontManager.shared.navigationBarSpacing + FontManager.shared.navigationBarTopConstant
        backStackViewHeightConstraint.constant = FontManager.shared.backLabelHeight
        titleStackViewEqualHeightConstraint.constant = -(2 * FontManager.shared.navigationBarSpacing)
        
        var bottomInset: CGFloat {
            
            switch activeFont {
                
                case .avenirNext, .myriadPro: return 2
                
                case .system: return 0
            }
        }
        
        backBorderViewContainerBottomConstraint.constant = bottomInset
        backBorderViewContainer.layer.cornerRadius = (FontManager.shared.backLabelHeight - bottomInset) / 2
        
        if sender is Notification, let entityVC = self.containerVC?.activeViewController?.topViewController as? EntityItemsViewController {
            
            prepareRightView(for: entityVC.rightViewMode)
        }
    }
    
    @objc func viewTemporarySettings(_ sender: UILongPressGestureRecognizer) {
        
        guard sender.state == .began else { return }
        
        let font = UIAlertAction.init(title: "Change Font", style: .default, handler: { [weak self] _ in self?.changeFont() })
        
        let constant = UIAlertAction.init(title: "Change Bar Constant", style: .default, handler: { [weak self] action in self?.updateBarConstant(action) })
        
        let blur = UIAlertAction.init(title: "Change Bar Blur Behaviour", style: .default, handler: { [weak self] _ in self?.changeBarBlurBehaviour() })
        
        topViewController?.present(UIAlertController.withTitle(nil, message: nil, style: .actionSheet, actions: font, constant, blur, .cancel()), animated: true, completion: nil)
    }
    
    func changeFont() {
        
        let actions = Font.allCases.map({ font in
            
            UIAlertAction.init(title: font.name, style: .default, handler: { _ in
                
                prefs.set(font.rawValue, forKey: .activeFont)
                notifier.post(name: .activeFontChanged, object: nil)
            
            }).checked(given: font == activeFont)
        })
        
        topViewController?.present(UIAlertController.withTitle(nil, message: nil, style: .actionSheet, actions: actions + [.cancel()]), animated: true, completion: nil)
    }
    
    func updateBarConstant(_ sender: Any) {
        
        if let _ = sender as? UIAlertAction {
            
            let actions = [("None", 0), ("Small", 1), ("Large", 2)].map({ tuple in
                
                UIAlertAction.init(title: tuple.0, style: .default, handler: { [weak self] _ in
                
                    guard let weakSelf = self else { return }
                    
                    prefs.set(tuple.1, forKey: "barConstant")
                    weakSelf.updateBarConstant(weakSelf)
                
                }).checked(given: prefs.integer(forKey: "barConstant") == tuple.1)
            })
            
            topViewController?.present(UIAlertController.withTitle(nil, message: nil, style: .actionSheet, actions: actions + [.cancel()]), animated: true, completion: nil)
            
        } else {
            
            updateTopConstraint(for: .preparation, with: nil, and: containerVC?.activeViewController?.topViewController as? Navigatable)
            
            UIView.animate(withDuration: 0.3, animations: {
                
                self.superview?.layoutIfNeeded()
                
                if let searchVC = self.containerVC?.activeViewController?.topViewController as? SearchViewController {
                    
                    searchVC.tableView.contentInset.top = Location.main.total
                    searchVC.tableView.scrollIndicatorInsets.top = Location.main.total
                    searchVC.tableView.contentOffset = .init(x: 0, y: -Location.main.total)
                
                } else if let container = self.containerVC?.activeViewController?.topViewController as? ChildContaining & Navigatable, let contained = container.activeChildViewController as? Arrangeable {
                    
                    contained.tableView.contentInset.top = self.location(from: container).total
                    contained.tableView.scrollIndicatorInsets.top = self.location(from: container).total
                    contained.tableView.contentOffset = .init(x: 0, y: -self.location(from: container).total)
                }
            })
        }
    }
    
    func changeBarBlurBehaviour() {
        
        let actions = BarBlurBehavour.allCases.map({ behaviour in
            
            UIAlertAction.init(title: behaviour.title, style: .default, handler: { _ in
                
                prefs.set(behaviour.rawValue, forKey: .barBlurBehaviour)
                notifier.post(name: .barBlurBehaviourChanged, object: nil)
            
            }).checked(given: barBlurBehaviour == behaviour)
        })
        
        topViewController?.present(UIAlertController.withTitle(nil, message: nil, style: .actionSheet, actions: actions + [.cancel()]), animated: true, completion: nil)
    }
    
    func location(from navigatable: Navigatable?) -> Location {
        
        if let _ = navigatable as? EntityItemsViewController {
            
            return .entity
            
        } else {
            
            return .main
        }
    }
    
    func animateViews(direction: AnimationDirection, section: AnimationSection, with initialVC: Navigatable?, and finalVC: Navigatable?, preferVerticalTransition: Bool = false) {
        
        updateTopConstraint(for: section, with: initialVC, and: finalVC)
        
        animateTitleLabel(direction: direction, section: section, with: (initialVC?.title, initialVC?.backLabelText), and: (finalVC?.title, finalVC?.backLabelText), preferVerticalTransition: preferVerticalTransition)
        
        animateRightView(direction: direction, section: section, with: initialVC, and: finalVC, preferVerticalTransition: preferVerticalTransition)
    }
    
    func updateTopConstraint(for section: AnimationSection, with initialVC: Navigatable?, and finalVC: Navigatable?) {
        
        if case .preparation = section {
            
            stackViewTopConstraint.constant = {
                
                if Location.main.total - Location.entity.total == 0, initialVC != nil {
                    
                    return 0
                    
                } else {
                    
                    return location(from: finalVC).constant
                }
            }()
            
        } else if case .end(completed: let completed) = section {
            
            stackViewTopConstraint.constant = location(from: completed ? finalVC : initialVC).constant
        }
    }
    
    func prepareRightView(for mode: RightViewMode, initialPreparation: Bool = false) {
        
        switch mode {
            
            case .none:
                
                rightButton.setImage(nil, for: .normal)
                
                if initialPreparation {
                
                    rightView.alpha = 0
                    rightButton.alpha = 0
                }
                
                rightViewWidthConstraint.constant = 0
                rightViewWidthConstraint.priority = .init(901)

            case .artwork(let image, details: let details):
                
                rightButton.setImage(nil, for: .normal)
                rightButton.alpha = 1
                
                clearButtonView.isHidden = true
                artworkView.isHidden = false
                artworkImageView.image = image
            
                artworkImageView.layer.setRadiusTypeIfNeeded(to: details.useContinuousCorners)
                artworkImageView.layer.cornerRadius = details.radius
                
                UniversalMethods.addShadow(to: artworkContainer, radius: 8, opacity: 0.35, shouldRasterise: true)
                
                rightViewWidthConstraint.priority = .init(899)

            case .button(hidden: let hidden):
                
                rightButton.setImage(#imageLiteral(resourceName: "Discard"), for: .normal)
                
                artworkView.isHidden = true
                clearButtonView.isHidden = false
                
                if initialPreparation {
                    
                    rightButton.alpha = hidden ? 0 : 1
                    clearButtonView.alpha = hidden ? 0 : 1
                }
            
                rightViewWidthConstraint.constant = hidden ? 0 : 44
                rightViewWidthConstraint.priority = .init(901)
        }
    }
    
    func animateRightView(direction: AnimationDirection, section: AnimationSection, with initialVC: Navigatable?, and finalVC: Navigatable?, preferVerticalTransition: Bool = false) {
        
        guard let initialMode = initialVC?.rightViewMode, let finalMode = finalVC?.rightViewMode else { return }
        
        switch section {
            
            case .preparation:
                
                isAnimatingRightView = true
            
                if let snapshot = rightView.snapshotView(afterScreenUpdates: false), let buttonSnapshot = rightButton.snapshotView(afterScreenUpdates: false) {
                    
                    snapshot.frame = contentView.convert(rightView.frame, from: rightView.superview)
                    contentView.addSubview(snapshot)
                    rightViewSnapshot = snapshot
                    
                    if case .none = initialMode {
                        
                        rightViewSnapshot?.alpha = 0
                    }
                    
                    buttonSnapshot.frame = rightButton.frame
                    contentView.addSubview(buttonSnapshot)
                    rightButtonSnapshot = buttonSnapshot
                    
                    rightView.alpha = 0
                    rightButton.alpha = 0

                    prepareRightView(for: finalMode)
                    
                    let transform = CGAffineTransform.init(translationX: preferVerticalTransition ? 0 : (direction == .forward ? horizontalTranslation : -horizontalTranslation), y: preferVerticalTransition ? verticalTranslation : 0)
                    
                    if preferVerticalTransition.inverted, case .none = initialMode, case .artwork = finalMode, Location.main.total - Location.entity.total != 0 {
                        
                        let scale = location(from: initialVC).inset/location(from: finalVC).inset
                    
                        rightView.transform = transform.scaledBy(x: scale, y: scale).translatedBy(x: 0, y: (Location.main.total - Location.entity.total) / 2)
                    
                    } else {
                        
                        rightView.transform = transform
                    }
                    
                    rightButton.transform = transform
                    
                    layoutIfNeeded()
                }
            
            case .firstHalf:
            
                rightViewSnapshot?.alpha = 0
                rightButtonSnapshot?.alpha = 0
                let transform = CGAffineTransform.init(translationX: preferVerticalTransition ? 0 : (direction == .forward ? -horizontalTranslation : horizontalTranslation), y: preferVerticalTransition ? verticalTranslation : 0)
                
                if preferVerticalTransition.inverted, Location.main.total - Location.entity.total != 0 {
                    
                    switch (initialMode, finalMode) {
                        
                        case (.artwork, .none), (.artwork, .button):
                        
                            let scale = location(from: finalVC).inset/location(from: initialVC).inset
                            
                            rightViewSnapshot?.transform = transform.scaledBy(x: scale, y: scale).translatedBy(x: 0, y: (Location.main.total - Location.entity.total) / 2)
                        
                        default: rightViewSnapshot?.transform = transform
                    }
                    
                } else {
                    
                    rightViewSnapshot?.transform = transform
                }
            
                rightButtonSnapshot?.transform = transform
            
            case .secondHalf:
                
                rightView.transform = .identity
                rightButton.transform = .identity
                
                rightView.alpha = {
                    
                    switch finalMode {
                        
                        case .none: return 0
                        
                        case .button, .artwork: return 1
                    }
                }()
                
                rightButton.alpha = {
                    
                    switch finalMode {
                        
                        case .none, .artwork: return 0
                        
                        case .button(hidden: let hidden): return hidden ? 0 : 1
                    }
                }()
            
                clearBorderView.alpha = {
                    
                    switch finalMode {
                        
                        case .none, .artwork: return 0
                        
                        case .button(hidden: let hidden): return hidden ? 0 : 1
                    }
                }()
            
            case .end(completed: let completed):
            
                prepareRightView(for: completed ? finalMode : initialMode, initialPreparation: true)
                rightView.alpha = 1
                rightView.transform = .identity
                rightButton.transform = .identity
                rightViewSnapshot?.removeFromSuperview()
                rightViewSnapshot = nil
                rightButtonSnapshot?.removeFromSuperview()
                rightButtonSnapshot = nil
            
                isAnimatingRightView = false
        }
    }
    
    func animateTitleLabel(direction: AnimationDirection, section: AnimationSection, with initialDetails: NavigatableDetails, and finalDetails: NavigatableDetails, preferVerticalTransition: Bool = false) {
        
        switch section {
            
            case .preparation:
                
                isAnimatingTitles = true
            
                if let snapshot = titleLabel.snapshotView(afterScreenUpdates: false), let backSnapshot = backLabel.snapshotView(afterScreenUpdates: false), let borderSnapshot = backBorderView.snapshotView(afterScreenUpdates: false) {
                    
                    snapshot.frame = contentView.convert(titleLabel.frame, from: titleLabel.superview)
                    contentView.addSubview(snapshot)
                    titleLabelSnapshot = snapshot
                    
                    let transform = CGAffineTransform.init(translationX: preferVerticalTransition ? 0 : (direction == .forward ? horizontalTranslation : -horizontalTranslation), y: preferVerticalTransition ? verticalTranslation : 0)
                    
                    titleLabel.alpha = 0
                    titleLabel.text = finalDetails.title
                    titleLabel.transform = transform
                    
                    backSnapshot.frame = contentView.convert(backLabel.frame, from: backLabel.superview)
                    contentView.addSubview(backSnapshot)
                    backLabelSnapshot = backSnapshot
                    
                    backLabel.alpha = 0
                    backLabel.text = finalDetails.backLabelText
                    backLabel.transform = transform
                    
                    borderSnapshot.frame = contentView.convert(backBorderView.frame, from: backBorderView.superview)
                    borderSnapshot.alpha = initialDetails.backLabelText == nil ? 0 : 1
                    contentView.addSubview(borderSnapshot)
                    backBorderViewSnapshot = borderSnapshot
                    
                    backBorderView.alpha = 0
                    backBorderView.transform = transform
                    
                    if Location.main.total - Location.entity.total == 0 {
                        
                        backView.isHidden = false
                    }
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
                
                let transform = CGAffineTransform.init(translationX: preferVerticalTransition ? 0 : (direction == .forward ? -horizontalTranslation : horizontalTranslation), y: preferVerticalTransition ? verticalTranslation : 0)
                
                if preferVerticalTransition.inverted, Location.main.total - Location.entity.total != 0 {
                    
                    if initialDetails.backLabelText != nil && finalDetails.backLabelText == nil {
                    
                        titleLabelSnapshot?.transform = transform.translatedBy(x: 0, y: (Location.main.total - Location.entity.total) / 2)
                    
                    } else if finalDetails.backLabelText != nil && initialDetails.backLabelText == nil {
                        
                        titleLabelSnapshot?.transform = transform.translatedBy(x: 0, y: abs(Location.main.total - Location.entity.total) / 2)
                    
                    } else {
                        
                        titleLabelSnapshot?.transform = transform
                    }
                    
                } else {
                    
                    titleLabelSnapshot?.transform = transform
                }
            
            case .secondHalf:
                
                if finalDetails.backLabelText == nil, Location.main.total - Location.entity.total != 0 {
                    
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
            
                isAnimatingTitles = false
        }
    }
    
    @IBAction func dismiss() {
        
        _ = containerVC?.activeViewController?.popViewController(animated: true)
    }
    
    @IBAction func showOptions() {
        
        if let entityVC = containerVC?.activeViewController?.topViewController as? EntityItemsViewController {
        
            entityVC.showOptions()
        
        } else if let searchVC = containerVC?.activeViewController?.topViewController as? SearchViewController, searchVC.filtering.inverted, searchVC.recentSearches.isEmpty.inverted {
            
            searchVC.deleteRecentSearches()
        }
    }
}

protocol Navigatable: ArtworkModifying {
    
    var title: String? { get set }
    var backLabelText: String? { get set }
    var preferredTitle: String? { get set }
    var inset: CGFloat { get }
    var activeChildViewController: UIViewController? { get set }
    var rightViewMode: VisualEffectNavigationBar.RightViewMode { get set }
}

extension Navigatable {
    
    var temporary: TemporaryNavigatable {
        
        return .init(title: title, backLabelText: backLabelText, preferredTitle: preferredTitle, inset: inset, activeChildViewController: activeChildViewController, rightViewMode: rightViewMode, artwork: artwork)
    }
}

protocol NavigatableContained {
    
    var navigatable: Navigatable? { get }
}

class TemporaryNavigatable: Navigatable {
    
    var title: String?
    var backLabelText: String?
    var preferredTitle: String?
    var inset: CGFloat
    weak var activeChildViewController: UIViewController?
    var rightViewMode: VisualEffectNavigationBar.RightViewMode
    weak var artwork: UIImage?
    
    init(title: String?, backLabelText: String?, preferredTitle: String?, inset: CGFloat, activeChildViewController: UIViewController?, rightViewMode: VisualEffectNavigationBar.RightViewMode, artwork: UIImage?) {
        
        self.title = title
        self.backLabelText = backLabelText
        self.preferredTitle = preferredTitle
        self.inset = inset
        self.activeChildViewController = activeChildViewController
        self.rightViewMode = rightViewMode
        self.artwork = artwork
    }
}
