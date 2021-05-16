//
//  HeaderEffectView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 18/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias TopBarOffset = VisualEffectNavigationBar.ArtworkMode

var barConstant: Int { return prefs.integer(forKey: "barConstant") }

class VisualEffectNavigationBar: MELVisualEffectView, ThemeStatusProvider {

    @IBOutlet var stackView: UIStackView!
    @IBOutlet var titleLabel: MELLabel!
    @IBOutlet var backLabel: MELLabel!
    @IBOutlet var artworkContainer: InvertIgnoringView!
    @IBOutlet var artworkImageView: InvertIgnoringImageView! {
        
        didSet {
            
            artworkImageView.provider = self
        }
    }
    @IBOutlet var clearButtonView: UIView!
    @IBOutlet var entityImageView: InvertIgnoringImageView! {
        
        didSet {
            
            entityImageView.provider = self
        }
    }
    @IBOutlet var entityImageViewContainer: InvertIgnoringView!
    @IBOutlet var backView: UIView!
    @IBOutlet var backBorderView: UIView!
    @IBOutlet var titleScrollView: MELScrollView!
    @IBOutlet var gradientView: GradientView!
    @IBOutlet var artworkView: UIView!
    @IBOutlet var rightButton: UIButton!
    @IBOutlet var rightView: UIView!
    @IBOutlet var stackViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var clearBorderView: MELBorderView!
    @IBOutlet var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet var titleLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet var backStackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var titleStackViewEqualHeightConstraint: NSLayoutConstraint!
    @IBOutlet var backStackViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var backBorderViewContainer: UIView!
    @IBOutlet var backBorderViewContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet var containerView: UIView!
    @IBOutlet var rightViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var entityTypeLabel: MELLabel!
    
    var statusBarHeight = 0 as CGFloat
    var stackViewTopSafeAreaConstraint: NSLayoutConstraint!
    
    enum ArtworkMode: Int, CaseIterable {
        
        case none, small, large
        
        var title: String {
            
            switch self {
                
                case .none: return "None"
                
                case .small: return "Small"
                
                case .large: return "Large"
            }
        }
    }
    enum AnimationSection { case preparation, firstHalf, secondHalf, end(completed: Bool) }
    enum RightViewMode { case none, button(image: UIImage, hidden: Bool), artwork(UIImage?, details: RadiusDetails) }
    enum RightButtonType {
        
        case actions, clear
        
        var bottomOffset: CGFloat {
            
            switch self {
                
                case .clear: return 22
                
                case .actions: return 26
            }
        }
        
        var image: UIImage {
            
            switch self {
                
                case .actions: return #imageLiteral(resourceName: "More13")
                
                case .clear: return #imageLiteral(resourceName: "Discard")
            }
        }
    }
    
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
    
    var snapshot: UIView? { didSet { oldValue?.removeFromSuperview() } }
    var isAnimating = false
    
    var containerVC: ContainerViewController? { return appDelegate.window?.rootViewController as? ContainerViewController }
    
    let verticalTranslation: CGFloat = 20
    let horizontalTranslation: CGFloat = 40
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(dismiss))
        titleScrollView.addGestureRecognizer(tap)
        
        containerView.bringSubviewToFront(rightButton)
        updateSpacing(self)
        
        notifier.addObserver(self, selector: #selector(updateSpacing), name: .lineHeightsCalculated, object: nil)
        
        let hold = UILongPressGestureRecognizer.init(target: self, action: #selector(showOptions(_:)))
        hold.minimumPressDuration = longPressDuration
        rightButton.addGestureRecognizer(hold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
        
        if isInDebugMode {
            
            let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(viewTemporarySettings))
            gr.minimumPressDuration = 0.3
            gr.require(toFail: hold)
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
                
                case .museoSansRounded: return 2
            }
        }
        
        backBorderViewContainerBottomConstraint.constant = bottomInset
        backBorderViewContainer.layer.cornerRadius = (FontManager.shared.backLabelHeight - bottomInset) / 2
        
        if sender is Notification, let entityVC = self.containerVC?.activeViewController?.topViewController as? EntityItemsViewController {
            
            prepareArtwork(for: entityVC)
        }
        
        layoutIfNeeded()
    }
    
    @objc func viewTemporarySettings(_ sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
            
            case .began:
            
                let font = AlertAction.init(title: "Change Font", style: .default, requiresDismissalFirst: true, handler: { [weak self] in self?.changeFont() })
                let artwork = AlertAction.init(title: "Change Artwork Type", style: .default, requiresDismissalFirst: true, handler: { [weak self] in self?.changeArtwork() })
                let constant = AlertAction.init(title: "Change Bar Constant", style: .default, requiresDismissalFirst: true, handler: { [weak self] in self?.updateBarConstant(0) })
                let blur = AlertAction.init(title: "Change Bar Blur Behaviour", style: .default, requiresDismissalFirst: true, handler: { [weak self] in self?.changeBarBlurBehaviour() })
                
                topViewController?.showAlert(title: nil, with: font, constant, artwork, blur)
            
            case .changed, .ended:
            
                guard let top = topViewController as? VerticalPresentationContainerViewController else { return }
            
                top.gestureActivated(sender)
            
            default: break
        }
    }
    
    func changeArtwork() {
        
        let actions = TopBarOffset.allCases.map({ mode in
            
            AlertAction.init(title: mode.title, style: .default, accessoryType: .check({ mode == navBarArtworkMode }), requiresDismissalFirst: false, handler: { [weak self] in
                
                guard let weakSelf = self else { return }
                
                prefs.set(mode.rawValue, forKey: .navBarArtworkMode)
                weakSelf.prepareArtwork(for: weakSelf.containerVC?.activeViewController?.topViewController as? Navigatable)
            })
        })
        
        topViewController?.showAlert(title: nil, with: actions)
    }
    
    func changeFont() {
        
        let actions = Font.allCases.map({ font in
            
            AlertAction.init(title: font.name, style: .default, accessoryType: .check({ font == activeFont }), requiresDismissalFirst: false, handler: {
                
                prefs.set(font.rawValue, forKey: .activeFont)
                notifier.post(name: .activeFontChanged, object: nil)
            })
        })
        
        topViewController?.showAlert(title: nil, with: actions)
    }
    
    func updateBarConstant(_ sender: Any) {
        
        if let _ = sender as? Int {
            
            let actions = TopBarOffset.allCases.map({ offset in
                
                AlertAction.init(title: offset.title, style: .default, accessoryType: .check({ offset == navBarConstant }), requiresDismissalFirst: false, handler: { [weak self] in
                
                    guard let weakSelf = self else { return }
                    
                    prefs.set(offset.rawValue, forKey: .navBarConstant)
                    weakSelf.updateBarConstant(weakSelf)
                })
            })
            
            topViewController?.showAlert(title: nil, with: actions)
            
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
            
            AlertAction.init(title: behaviour.title, style: .default, accessoryType: .check({ barBlurBehaviour == behaviour }), requiresDismissalFirst: false, handler: {
                
                prefs.set(behaviour.rawValue, forKey: .barBlurBehaviour)
                notifier.post(name: .barBlurBehaviourChanged, object: nil)
            })
        })
        
        topViewController?.showAlert(title: nil, with: actions)
    }
    
    func location(from navigatable: Navigatable?) -> Location {
        
        if let _ = navigatable as? FilterViewController {
            
            return .entity
            
        } else if let _ = navigatable as? EntityItemsViewController {
            
            return .entity
            
        } else {
            
            return .main
        }
    }
    
    func animateViews(direction: AnimationDirection, section: AnimationSection, with initialVC: Navigatable?, and finalVC: Navigatable?, preferVerticalTransition: Bool = false, updateConstraint: Bool = true) {
        
        if updateConstraint {
        
            updateTopConstraint(for: section, with: initialVC, and: finalVC)
        }
        
        switch section {
            
            case .preparation:
            
                isAnimating = true
            
                if let snapshot = containerView.snapshotView(afterScreenUpdates: false) {
                    
                    snapshot.frame = containerView.frame
                    contentView.addSubview(snapshot)
                    self.snapshot = snapshot
                    
                    let transform = CGAffineTransform.init(translationX: preferVerticalTransition ? 0 : (direction == .forward ? horizontalTranslation : -horizontalTranslation), y: preferVerticalTransition ? verticalTranslation : 0)
                    
                    containerView.alpha = 0
                    containerView.transform = transform
                    prepareTitles(for: finalVC)
                    prepareArtwork(for: finalVC)
                    prepareRightButton(for: finalVC)
                    
                    backBorderView.alpha = finalVC?.backLabelText == nil ? 0 : 1
                    
                    if Location.main.total - Location.entity.total == 0 {

                        backView.isHidden = false
                    }
                    
                    if updateConstraint {
                    
                        layoutIfNeeded()
                    }
                }
            
            case .firstHalf:
                
                if finalVC?.backLabelText != nil {
                    
                    backView.isHidden = false
                }
            
                snapshot?.alpha = 0
            
                let transform = CGAffineTransform.init(translationX: preferVerticalTransition ? 0 : (direction == .forward ? -horizontalTranslation : horizontalTranslation), y: preferVerticalTransition ? verticalTranslation : 0)

                if preferVerticalTransition.inverted, Location.main.total - Location.entity.total != 0 {

                    if initialVC?.backLabelText != nil && finalVC?.backLabelText == nil {

                        snapshot?.transform = transform.translatedBy(x: 0, y: (Location.main.total - Location.entity.total) / 2)

                    } else if finalVC?.backLabelText != nil && initialVC?.backLabelText == nil {

                        snapshot?.transform = transform.translatedBy(x: 0, y: abs(Location.main.total - Location.entity.total) / 2)

                    } else {

                        snapshot?.transform = transform
                    }

                } else {

                    snapshot?.transform = transform
                }
            
            case .secondHalf:
            
                if finalVC?.backLabelText == nil, Location.main.total - Location.entity.total != 0 {
                    
                    backView.isHidden = true
                }
                
                if finalVC?.backLabelText != nil {
                    
                    backBorderView.alpha = 1
                }
            
                containerView.alpha = 1
                containerView.transform = .identity
            
            case .end(completed: let completed):
            
                backView.isHidden = completed ? finalVC?.backLabelText == nil : initialVC?.backLabelText == nil
                backBorderView.alpha = completed ? (finalVC?.backLabelText == nil ? 0 : 1) : (initialVC?.backLabelText == nil ? 0 : 1)
                prepareTitles(for: completed ? finalVC : initialVC)
                prepareArtwork(for: completed ? finalVC : initialVC)
                prepareRightButton(for: completed ? finalVC : initialVC)
                containerView.transform = .identity
                containerView.alpha = 1
                snapshot?.removeFromSuperview()
                snapshot = nil
                gradientView.updateGradient()
                
                isAnimating = false
        }
    }
    
    func updateTopConstraint(for section: AnimationSection, with initialVC: Navigatable?, and finalVC: Navigatable?) {
        
        if case .preparation = section {
            
            stackViewTopSafeAreaConstraint.constant = statusBarHeight + {
                
                if Location.main.total - Location.entity.total == 0, initialVC != nil {
                    
                    return 0
                    
                } else {
                    
                    return location(from: finalVC).constant
                }
            }()
            
        } else if case .end(completed: let completed) = section {
            
            stackViewTopSafeAreaConstraint.constant = statusBarHeight + location(from: completed ? finalVC : initialVC).constant
        }
    }
    
    func prepareTitles(for navigatable: Navigatable?) {
        
        titleLabel.text = navigatable?.title
        backLabel.text = navigatable?.backLabelText
    }
    
    func prepareArtwork(for navigatable: Navigatable?) {
        
        guard navBarArtworkMode != .none else {
            
            artworkView.isHidden = true
            entityImageViewContainer.superview?.isHidden = true
            
            return
        }
        
        guard let navigatable = navigatable,
            let view = navBarArtworkMode == .large ? artworkView : entityImageViewContainer.superview,
            let altView = navBarArtworkMode == .small ? artworkView : entityImageViewContainer.superview,
            let container = navBarArtworkMode == .large ? artworkContainer : entityImageViewContainer,
            let imageView = navBarArtworkMode == .large ? artworkImageView : entityImageView else { return }
        
        altView.isHidden = true
        view.isHidden = navigatable.artworkDetails == nil
        
        if let artworkDetails = navigatable.artworkDetails {
                          
            imageView.artworkType = artworkDetails.artworkType
            imageView.layer.setRadiusTypeIfNeeded(to: artworkDetails.details.useContinuousCorners)
            imageView.layer.cornerRadius = artworkDetails.details.radius
        }
        
        if container.layer.shadowOpacity < 0.1 {
        
            UniversalMethods.addShadow(to: container, radius: 4, opacity: 0.3, shouldRasterise: true)
        }
    }
    
    func prepareRightButton(for navigatable: Navigatable?, animated: Bool = false) {
        
        guard let navigatable = navigatable else { return }
        
        rightButton.contentEdgeInsets.bottom = navigatable.buttonDetails.type.bottomOffset
        rightButton.setImage(navigatable.buttonDetails.type.image, for: .normal)
        
        rightViewWidthConstraint.constant = navigatable.buttonDetails.hidden ? 0 : 44
        
        if animated {
        
            UIView.animate(withDuration: 0.3, animations: {
                
                self.containerView.layoutIfNeeded()
                self.rightButton.alpha = navigatable.buttonDetails.hidden ? 0 : 1
                self.clearBorderView.alpha = navigatable.buttonDetails.hidden ? 0 : 1
            })
            
        } else {
            
            rightButton.alpha = navigatable.buttonDetails.hidden ? 0 : 1
            clearBorderView.alpha = navigatable.buttonDetails.hidden ? 0 : 1
        }
    }
    
    @IBAction func dismiss() {
        
        _ = containerVC?.activeViewController?.popViewController(animated: true)
    }
    
    @IBAction func showActions() {
        
        if let navigatable = containerVC?.activeViewController?.topViewController as? Navigatable, let child = navigatable.activeChildViewController as? HeaderViewContaining & UIViewController {
            
            guard child.headerView.buttonDetails.isEmpty.inverted else { return }
            
            var array = child.headerView.buttonDetails.enumerated().map({ item -> AlertAction in
                
                let type = (navigatable as? EntityItemsViewController)?.entityTypeForContainerType()
                let entity = (navigatable as? EntityItemsViewController)?.collection
                let altTitle = (child.headerView.supplementaryCollectionView.cellForItem(at: .init(item: item.offset, section: 0)) as? HeaderButtonsCollectionViewCell)?.label?.text
                let assistiveText: String? = {
                    
                    switch item.element.type {
                        
                        case .grouping:
                            
                            if let entityVC = navigatable as? EntityItemsViewController {
                                
                                return entityVC.currentStartPoint.title.capitalized
                                
                            } else if let collectionsVC = child as? CollectionsViewController, collectionsVC.collectionKind == .playlist, collectionsVC.presented.inverted {
                                
                                return collectionsVC.playlistsViewText
                            }
                            
                            return nil
                            
                        case .sort:
                            
                            guard let arrangeable = child as? Arrangeable else { return nil }
                            
                            return arrangeable.arrangementLabelText + ", " + "\(arrangeable.ascending ? "Ascending" : "Descending")"
                            
                        default: return nil
                    }
                }()
                let subtitleDetails = item.element.type.subtitleDetails(with: assistiveText, basedOn: type, for: entity)
                                                                            
                return AlertAction.init(info: AlertInfo.init(title: item.element.type.rawValue, subtitle: item.element.type == .newPlaylist ? nil : (subtitleDetails?.text ?? altTitle), attributesInfo: SettingsAttributesInfo.init(titleAttributes: nil, subtitleAttributes: subtitleDetails?.attributes, tertiaryAttributes: nil, accessoryButtonAttributes: nil), image: item.element.type.image, accessoryType: .none), requiresDismissalFirst: item.element.type.requiresDismissalFirst, handler: item.element.type.action(at: item.offset, for: entity, basedOn: child))
            })
            
            if let editable = child as? SongActionable & TableViewContaining {
                
                array.append(.init(title: editable.tableView.isEditing ? "End Editing" : "Begin Editing", image: #imageLiteral(resourceName: "EditNoBorder22"), requiresDismissalFirst: false, handler: { editable.songManager.toggleEditing(editable) }))
                
                array.append(.init(title: "View Actions", image: #imageLiteral(resourceName: "ActionsMenu22"), requiresDismissalFirst: true, handler: { editable.songManager.showActionsForAll(editable) }))
            }
            
            if let filterable = child as? Filterable {
                
                array.append(.init(title: "Filter", image: #imageLiteral(resourceName: "Filter22"), requiresDismissalFirst: (child as? CollectionsViewController)?.presented == true, handler: { filterable.invokeSearch() }))
            }
            
            child.showAlert(title: navigatable.title, with: array)
            
        } else if let searchVC = containerVC?.activeViewController?.topViewController as? SearchViewController, searchVC.filtering.inverted, searchVC.recentSearches.isEmpty.inverted {
            
            searchVC.deleteRecentSearches()
        
        } else if let filterVC = containerVC?.activeViewController?.topViewController as? FilterViewController {
            
            if filterVC.filtering {
                
                filterVC.songManager.showActionsForAll(filterVC)
                
            } else if filterVC.recentSearches.isEmpty.inverted {
            
                filterVC.clearRecentSearches()
            }
        }
    }
    
    @objc func showOptions(_ sender: UILongPressGestureRecognizer) {
        
        guard sender.state == .began else { return }
        
        if let entityVC = containerVC?.activeViewController?.topViewController as? EntityItemsViewController {
        
            entityVC.showOptions()
        }
    }
}

protocol Navigatable: ArtworkModifying {
    
    var title: String? { get set }
    var backLabelText: String? { get set }
    var preferredTitle: String? { get set }
    var inset: CGFloat { get }
    var activeChildViewController: UIViewController? { get set }
    var artworkDetails: NavigationBarArtworkDetails? { get set }
    var buttonDetails: NavigationBarButtonDetails { get set }
}

extension Navigatable {
    
    var temporary: TemporaryNavigatable {
        
        return .init(navigatable: self)
    }
}

protocol NavigatableContained {
    
    var navigatable: Navigatable? { get }
}

typealias NavigationBarArtworkDetails = (artworkType: EntityArtworkType, details: RadiusDetails)
typealias NavigationBarButtonDetails = (type: VisualEffectNavigationBar.RightButtonType, hidden: Bool)

class TemporaryNavigatable: Navigatable {
    
    var title: String?
    var backLabelText: String?
    var preferredTitle: String?
    var inset: CGFloat
    weak var activeChildViewController: UIViewController?
    weak var artwork: UIImage?
    var artworkDetails: NavigationBarArtworkDetails?
    var buttonDetails: NavigationBarButtonDetails
    
    init(navigatable: Navigatable) {
        
        self.title = navigatable.title
        self.backLabelText = navigatable.backLabelText
        self.preferredTitle = navigatable.preferredTitle
        self.inset = navigatable.inset
        self.activeChildViewController = navigatable.activeChildViewController
        self.artwork = navigatable.artwork
        self.artworkDetails = navigatable.artworkDetails
        self.buttonDetails = navigatable.buttonDetails
    }
}
