//
//  Protocols.swift
//  Melody
//
//  Created by Ezenwa Okoro on 02/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

// MARK: - BackgroundHideable
protocol BackgroundHideable {

    var temporaryImageView: UIImageView { get set }
    var temporaryEffectView: MELVisualEffectView { get set }
    var view: UIView! { get set }
}

extension BackgroundHideable {
    
    func modifyBackgroundView(forState state: BackgroundViewState) {
        
        switch state {
            
            case .visible:
                
                let views: [UIView] = [temporaryEffectView, temporaryImageView]
                
                for subview in views {
                    
                    view.addSubview(subview)
                    view.sendSubviewToBack(subview)
                    subview.translatesAutoresizingMaskIntoConstraints = false
                    
                    view.addConstraints([NSLayoutConstraint.init(item: view, attribute: .bottom, relatedBy: .equal, toItem: subview, attribute: .bottom, multiplier: 1, constant: 0), NSLayoutConstraint.init(item: view, attribute: .top, relatedBy: .equal, toItem: subview, attribute: .top, multiplier: 1, constant: 0), NSLayoutConstraint.init(item: view, attribute: .leading, relatedBy: .equal, toItem: subview, attribute: .leading, multiplier: 1, constant: 0), NSLayoutConstraint.init(item: view, attribute: .trailing, relatedBy: .equal, toItem: subview, attribute: .trailing, multiplier: 1, constant: 0)])
                }
            
            case .removed:
                
                temporaryEffectView.frame = .zero
                temporaryImageView.frame = .zero
                temporaryImageView.image = nil
                temporaryEffectView.effect = nil
                temporaryImageView.isHidden = true
                temporaryEffectView.isHidden = true
                temporaryImageView.removeFromSuperview()
                temporaryEffectView.removeFromSuperview()
        }
    }
}

// MARK: - QueueManager
protocol QueueManager: class {
    
    var queue: [MPMediaItem] { get set }
    var shuffled: Bool { get set }
    var reverseShuffle: Bool { get set }
}

// MARK: - DynamicSections
protocol DynamicSections { }

extension DynamicSections where Self: UIViewController {
    
    func getSectionDetails(from arrays: SectionDetails...) -> [SectionDetails] {
        
        var tupleArray = [SectionDetails]()
        
        for array in arrays where array.count > 0 {
            
            tupleArray.append(array)
        }
        
        return tupleArray
    }
}

// MARK: - Contained
protocol Contained { }

extension Contained where Self: UIViewController {
    
    weak var container: ContainerViewController? { return navigationController?.parent as? ContainerViewController }
}

// MARK: - ArtworkContainingCell
protocol ArtworkContainingCell {
    
    var artworkImageView: UIImageView! { get set }
}

protocol ArtistTransitionable: class {
    
    var currentItem: MPMediaItem? { get set }
    var currentAlbum: MPMediaItemCollection? { get set }
    var artistQuery: MPMediaQuery? { get set }
}

protocol AlbumTransitionable: class {
    
    var currentItem: MPMediaItem? { get set }
    var albumQuery: MPMediaQuery? { get set }
}

protocol PlaylistTransitionable: class {
    
    var currentItem: MPMediaItem? { get set }
    var playlistQuery: MPMediaQuery? { get set }
}

protocol PreviewTransitionable: class {
    
    var isCurrentlyTopViewController: Bool { get set }
    var viewController: UIViewController? { get set }
}

protocol GenreTransitionable: class {
    
    var currentItem: MPMediaItem? { get set }
    var currentAlbum: MPMediaItemCollection? { get set }
    var genreQuery: MPMediaQuery? { get set }
}

protocol ComposerTransitionable: class {
    
    var currentItem: MPMediaItem? { get set }
    var currentAlbum: MPMediaItemCollection? { get set }
    var composerQuery: MPMediaQuery? { get set }
}

protocol AlbumArtistTransitionable: class {
    
    var currentItem: MPMediaItem? { get set }
    var currentAlbum: MPMediaItemCollection? { get set }
    var albumArtistQuery: MPMediaQuery? { get set }
}

protocol ArtworkModifying: class {
    
    var artwork: UIImage? { get set }
}

extension ArtworkModifying {
    
    var artworkType: ArtworkType {
        
        switch backgroundArtworkAdaptivity {
            
            case .none: return .colour(.noArtwork)
            
            case .nowPlayingAdaptive:
            
                if let artwork = musicPlayer.nowPlayingItem?.actualArtwork?.image(at: .artworkSize) {
                    
                    return .image(artwork)
                }
                
                return .colour(.noArtwork)
            
            case .sectionAdaptive:
            
                if let artwork = artwork {
                    
                    return .image(artwork)
                }
                
                return .colour(.noArtwork)
        }
    }
}

protocol ArtworkModifierContaining: class {
    
    var modifier: ArtworkModifying? { get }
}

protocol Peekable: class {
    
    var peeker: UIViewController? { get set }
    var oldArtwork: UIImage? { get set }
}

protocol InteractivePresenter {
    
    var presenter: PresentationAnimationController { get }
}

protocol PropertyStripPresented {
    
    var title: String { get }
    var propertyImage: UIImage? { get }
}

extension PropertyStripPresented {
    
    func perform(_ operation: FilterViewContext.Operation, context: FilterViewContext) {
        
        switch operation {
            
            case .group(index: let index):
            
                switch context {
                    
                    case .filter:
                    
                        guard let property = self as? Property, let arrayIndex = filterProperties.firstIndex(of: property), Set(otherFilterProperties).contains(property).inverted else { return }
                    
                        prefs.set(filterProperties.removing(from: arrayIndex).map({ $0.rawValue }), forKey: .filterProperties)
                        prefs.set(otherFilterProperties.inserting(property, at: index ?? otherFilterProperties.endIndex).map({ $0.rawValue }), forKey: .otherFilterProperties)
                    
                    case .library:
                    
                        guard let section = self as? LibrarySection, let arrayIndex = librarySections.firstIndex(of: section), Set(otherLibrarySections).contains(section).inverted else { return }
                        
                        prefs.set(librarySections.removing(from: arrayIndex).map({ $0.rawValue }), forKey: .librarySections)
                        prefs.set(otherLibrarySections.inserting(section, at: index ?? otherLibrarySections.endIndex).map({ $0.rawValue }), forKey: .otherLibrarySections)
                }
            
            case .ungroup(index: let index):
            
                switch context {
                    
                    case .filter:
                        
                        guard let property = self as? Property, let arrayIndex = otherFilterProperties.firstIndex(of: property), Set(filterProperties).contains(property).inverted else { return }
                        
                        prefs.set(otherFilterProperties.removing(from: arrayIndex).map({ $0.rawValue }), forKey: .otherFilterProperties)
                        prefs.set(filterProperties.inserting(property, at: index ?? filterProperties.endIndex).map({ $0.rawValue }), forKey: .filterProperties)
                    
                    case .library:
                        
                        guard let section = self as? LibrarySection, let arrayIndex = otherLibrarySections.firstIndex(of: section), Set(librarySections).contains(section).inverted else { return }
                        
                        prefs.set(otherLibrarySections.removing(from: arrayIndex).map({ $0.rawValue }), forKey: .otherLibrarySections)
                        prefs.set(librarySections.inserting(section, at: index ?? librarySections.endIndex).map({ $0.rawValue }), forKey: .librarySections)
                }
            
            case .hide:
            
                switch context {
                    
                    case .filter:
                    
                        guard let property = self as? Property, Set(hiddenFilterProperties).contains(property).inverted else { return }
                    
                        prefs.set(hiddenFilterProperties.appending(property).map({ $0.rawValue }), forKey: .hiddenFilterProperties)
                    
                    case .library:
                    
                        guard let section = self as? LibrarySection, Set(hiddenLibrarySections).contains(section).inverted else { return }
                        
                        prefs.set(hiddenLibrarySections.appending(section).map({ $0.rawValue }), forKey: .hiddenLibrarySections)
                }
            
            case .unhide:
            
                switch context {
                    
                    case .filter:
                    
                        guard let property = self as? Property, let index = hiddenFilterProperties.firstIndex(of: property) else { return }
                    
                        prefs.set(hiddenFilterProperties.removing(from: index).map({ $0.rawValue }), forKey: .hiddenFilterProperties)
                    
                    case .library:
                    
                        guard let section = self as? LibrarySection, let index = hiddenLibrarySections.firstIndex(of: section) else { return }
                        
                        prefs.set(hiddenLibrarySections.removing(from: index).map({ $0.rawValue }), forKey: .hiddenLibrarySections)
                }
        }
        
        notifier.post(name: .propertiesUpdated, object: nil, userInfo: [String.filterViewContext: context])
    }
}

protocol EntityContainer: UITableViewDelegate, TableViewContaining {
    
    func handleLeftSwipe(_ sender: Any)
    func handleRightSwipe(_ sender: Any)
}

protocol TableViewContainer: FullySortable, InfoLoading, Filterable, SingleItemActionable {
    
    var tableDelegate: TableDelegate { get set }
    var collectionView: UICollectionView? { get set }
    var entities: [MPMediaEntity] { get }
    var query: MPMediaQuery? { get }
    var filteredEntities: [MPMediaEntity] { get set }
    var highlightedEntity: MPMediaEntity? { get }
    func selectCell(in tableView: UITableView, at indexPath: IndexPath, filtering: Bool)
    func getEntity(at indexPath: IndexPath, filtering: Bool) -> MPMediaEntity
}

protocol FilterContaining: class {
    
    var filterContainer: (FilterContainer & UIViewController)? { get set }
}

protocol Dismissable {
    
    var needsDismissal: Bool { get set }
    var navigationController: UINavigationController? { get }
    func dismiss(animated: Bool, completion: (() -> Void)?)
}

protocol QueryUpdateable {
    
    func updateWithQuery()
}

protocol Attributor: class {
    
    func updateAttributedText(for view: TableHeaderView?, inSection section: Int)
}

protocol CellAnimatable: TableViewContaining { }

extension CellAnimatable {
    
    func animateCells(direction: AnimationOrientation = .horizontal, alphaOnly: Bool = false) {
        
        let cells = tableView.visibleCells
        
        for cell in cells {
            
            cell.alpha = 0
            
            if alphaOnly.inverted {
            
                cell.transform = .init(translationX: direction == .horizontal ? tableView.bounds.size.width : 0, y: direction == .horizontal ? 0 : 40)
            }
        }
        
        for cell in cells.enumerated() {
            
            UIView.animate(withDuration: 0.8, delay: 0.02 * Double(cell.offset), usingSpringWithDamping: 0.8, initialSpringVelocity: direction == .horizontal ? 0 : 20, options: [.curveLinear, .allowUserInteraction], animations: {
                
                cell.element.alpha = 1
                
                if alphaOnly.inverted {
                
                    cell.element.transform = .identity
                }
                
            }, completion: nil)
        }
    }
}

@objc protocol OnlineOverridable {
    
    var onlineOverride: Bool { get set }
    func performOnlineOverride()
    @objc optional var tempViewLeadingConstraint: NSLayoutConstraint! { get set }
    @objc optional var topView: UIView! { get set }
    func updateOfflineFilterPredicates(onCondition condition: Bool)
}

extension OnlineOverridable {
    
//    func updateTempView(hidden: Bool) {
//
//        tempViewLeadingConstraint?.priority = UILayoutPriority(rawValue: hidden ? 899 : 901)
//
//        UIView.animate(withDuration: 0.3, animations: { self.topView?.layoutIfNeeded() })
//    }
}

protocol TextContaining: class {
    
    var actualFont: UIFont? { get set }
}

protocol Boldable {
    
    var boldableLabels: [TextContaining?] { get }
}

extension Boldable {
    
    func changeSize(to weight: FontWeight) {
        
        for container in boldableLabels {
            
            guard let size = container?.actualFont?.pointSize else { return }
            
            container?.actualFont = UIFont.font(ofWeight: weight, size: size)
        }
    }
}

protocol Settable: NSObjectProtocol {

    var likedState: LikedState { get }
    var persistentID: MPMediaEntityPersistentID { get }
}

extension Settable {
    
    func set(property: String, to value: Any?) {
        
        let string = NSString.init(format: "%@%@%@%@%@%@%@%@%@%@", "set", "Va", "lu", "e:", "for", "Pr", "op", "er", "ty", ":")
        let sel = NSSelectorFromString(string as String)
        
        guard self.responds(to: sel) else { return }
        
        _ = perform(sel, with: value, with: property)
    }
}

protocol BorderButtonContaining {
    
    var borderedButtons: [BorderedButtonView?] { get set }
}

extension BorderButtonContaining {
    
    func updateButtons() {
        
        let edgeConstraint: CGFloat = 10.0/3.0
        let middleConstraint: CGFloat = 20.0/3.0
        
        for view in borderedButtons {
            
            guard let view = view ?? nil, let first = borderedButtons.first ?? nil, let last = borderedButtons.last ?? nil else { return }
            
            let position: Position = {
                
                switch (first, last) {
                    
                    case (view, let z) where z != view: return .leading
                    
                    case (view, view): return .middle(single: true)
                    
                    case (let y, let z) where y != view && z != view: return .middle(single: false)
                    
                    case (let y, view) where y != view: return .trailing
                    
                    default:
                        
                        print("couldn't find button position")
                        
                        return .leading
                }
            }()
            
            switch position {
                
                case .leading:
                
                    view.borderViewLeadingConstraint.constant = 10
                    view.borderViewTrailingConstraint.constant = borderedButtons.count < 3 ? 5 : edgeConstraint
//                    view.button.contentEdgeInsets.left = borderedButtons.count < 3 ? 5 : edgeConstraint
                
                case .middle(single: let single):
                
                    view.borderViewLeadingConstraint.constant = single ? 10 : middleConstraint
                    view.borderViewTrailingConstraint.constant = single ? 10 : middleConstraint
//                    view.button.contentEdgeInsets.left = 0
//                    view.button.contentEdgeInsets.right = 0
                
                case .trailing:
                
                    view.borderViewLeadingConstraint.constant = borderedButtons.count < 3 ? 5 : edgeConstraint
                    view.borderViewTrailingConstraint.constant = 10
//                    view.button.contentEdgeInsets.right = borderedButtons.count < 3 ? 5 : edgeConstraint
            }
        }
    }
}

protocol OptionsContaining {
    
    var options: LibraryOptions { get }
}

protocol LargeActivityIndicatorContaining: TableViewContaining {
    
    var largeActivityIndicator: MELActivityIndicatorView! { get set }
    var activityView: UIView! { get set }
    var activityVisualEffectView: MELVisualEffectView! { get set }
}

extension LargeActivityIndicatorContaining {
    
    func updateLoadingViews(hidden: Bool) {
        
        if let queueVC = self as? QueueViewController {
            
            activityVisualEffectView.isHidden = queueVC.queueIsBeingEdited ? hidden : queueVC.firstScroll
        
        } else {
            
            tableView.isUserInteractionEnabled = hidden
        }
        
        UIView.animate(withDuration: 0.2, animations: { self.activityView.alpha = hidden ? 0 : 1 })
        
        hidden ? largeActivityIndicator.stopAnimating() : largeActivityIndicator.startAnimating()
    }
}

protocol TableViewContaining: class {
    
    var tableView: MELTableView! { get set }
}

protocol TopScrollable: IndexContaining { }

extension TopScrollable {
    
    func scrollToTop() {
        
        tableView.setContentOffset(.init(x: 0, y: -(navigatable?.inset ?? 0)), animated: true)
    }
}

protocol Detailing {
    
    func goToDetails(basedOn entity: Entity) -> (entities: [Entity], albumArtOverride: Bool)
}

extension Detailing {
    
    func getActionDetails(from action: SongAction, indexPath: IndexPath, actionable: SingleItemActionable?, vc: UIViewController?, entityType: Entity, entity: MPMediaEntity, useAlternateTitle alternateTitle: Bool = false) -> ActionDetails? {
        
        guard let actionable = actionable, let vc = vc else { return nil }
        
        return actionable.singleItemActionDetails(for: action, entity: entityType, using: entity, from: vc, useAlternateTitle: alternateTitle)
    }
}
