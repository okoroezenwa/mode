//
//  UIViewController + Extensions.swift
//  Melody
//
//  Created by Ezenwa Okoro on 09/10/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

extension UIViewController {
    
    class var storyboardName: String {
        
        return String.init(describing: type(of: self))
    }
    
    /// Array Version
    func guardQueue(title: String? = nil, subtitle: String? = nil, with actions: [AlertAction], onCondition condition: Bool, fallBack: () -> ()) {
        
        if condition {
            
            showAlert(title: title, subtitle: subtitle, context: .other, with: actions)
            
        } else {
            
            fallBack()
        }
    }
    
    /// Variadic Version
    func guardQueue(title: String? = nil, subtitle: String? = nil, with actions: AlertAction..., onCondition condition: Bool, fallBack: () -> ()) {
        
        guardQueue(title: title, subtitle: subtitle, with: actions, onCondition: condition, fallBack: fallBack)
    }
    
    @objc func showSettings(with sender: Any) {
        
        if let sender = sender as? UILongPressGestureRecognizer {
            
            guard sender.state == .began else { return }
        }
        
        guard let vc = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
        
        vc.context = .settings
        
        present(vc, animated: true, completion: nil)
    }
    
    static var fromStoryboard: UIViewController {
        
        return UIStoryboard.init(name: self.storyboardName, bundle: nil).instantiateViewController(withIdentifier: self.storyboardName)
    }
    
    var location: Location {
        
        switch self {
        
            case let x where x is ItemsViewController:
                
                guard let vc = x as? ItemsViewController else { return .unknown }
                
                return vc.actualLocation
            
            case let x where x is PlaylistItemsViewController: return .playlist
            
            case let x where x is AlbumItemsViewController: return .album
            
            case let x where x is ArtistSongsViewController:
                
                if let artistSongsVC = x as? ArtistSongsViewController, let kind = artistSongsVC.entityKind {
                    
                    return .collection(kind: kind, point: .songs)
                }
            
                return .unknown
            
            case let x where x is ArtistAlbumsViewController:
            
                if let artistAlbumsVC = x as? ArtistAlbumsViewController, let kind = artistAlbumsVC.entityKind {
                    
                    return .collection(kind: kind, point: .albums)
                }
            
                return .unknown
            
            case let x where x is SongsViewController: return .songs
            
            case let x where x is CollectionsViewController: return .collections(kind: (x as! CollectionsViewController).collectionKind)
            
            case let x where x is NowPlayingViewController: return .fullPlayer
            
            case let x where x is ContainerViewController: return .miniPlayer
            
            case let x where x is CollectorViewController: return .collector
            
            case let x where x is QueueViewController: return .queue
            
            case let x where x is SearchViewController: return .search
            
            case let x where x is InfoViewController: return .info
            
            case let x where x is NewPlaylistViewController: return .newPlaylist
            
            case let x where x is FilterViewController: return .filter
            
            default: return .unknown
        }
    }
    
    /// Array Version
    func showAlert(
        title: String?,
        subtitle: String? = nil,
        context: AlertTableViewController.Context = .other,
        topHeaderMode: VerticalPresentationContainerViewController.TopHeaderMode = .bar,
        with actions: [AlertAction],
        shouldSortActions: Bool = true,
        segmentDetails: SegmentDetails = ([], []),
        leftAction: AccessoryButtonAction? = nil,
        rightAction: AccessoryButtonAction? = nil,
        images: HeaderButtonImages? = nil,
        topAction: UnwindAction? = nil,
        topPreviewAction: PreviewAction? = nil,
        showMenuParameters parameters: [ShowMenuParameters] = [],
        completion: (() -> ())? = nil) {
        
        if useSystemAlerts {
            
            let actions: [UIAlertAction] = {
                
                let temp: [AlertAction] = {
                
                    if shouldSortActions {
                        
                        return actions.sorted(by: { $0.info.title.size < $1.info.title.size })
                    }
                    
                    return actions
                }()
                
                return temp.map({ $0.systemAction }) + [.cancel()]
            }()
            
            present(UIAlertController.withTitle(title, message: subtitle, style: .actionSheet, actions: actions), animated: true, completion: completion)
            
        } else {
            
            guard let vc = popoverStoryboard.instantiateViewController(withIdentifier: String.init(describing: VerticalPresentationContainerViewController.self)) as? VerticalPresentationContainerViewController else { return }
            
            vc.context = .alert
            vc.alertVC.context = context
            vc.topHeaderMode = topHeaderMode
            vc.alertVC.actions = {
                
                if shouldSortActions {
                    
                    return actions.sorted(by: { $0.info.title.size < $1.info.title.size })
                }
                
                return actions
            }()
            
            if let images = images {
                
                vc.images = images
            }
            
            vc.alertVC.segmentActions = segmentDetails.actions
            vc.alertVC.showMenuParameters = parameters
            vc.leftButtonAction = leftAction
            vc.rightButtonAction = rightAction
            vc.topAction = topAction
            vc.topPreviewAction = topPreviewAction
            vc.title = title
            vc.subtitle = subtitle
            vc.segments = segmentDetails.array
            vc.requiresTopBorderView = {
                
                if case .show = context, actions.isEmpty {
                    
                    return false
                }
                
                return title != nil || subtitle != nil
            }()
            vc.requiresTopView = title != nil || subtitle != nil
            
            present(vc, animated: true, completion: completion)
        }
    }
    
    /// Variadic Version
    func showAlert(
        title: String?,
        subtitle: String? = nil,
        context: AlertTableViewController.Context = .other,
        topHeaderMode: VerticalPresentationContainerViewController.TopHeaderMode = .bar,
        with actions: AlertAction...,
        shouldSortActions: Bool = true,
        segmentDetails: SegmentDetails = ([], []),
        leftAction: AccessoryButtonAction? = nil,
        rightAction: AccessoryButtonAction? = nil,
        images: HeaderButtonImages? = nil,
        topAction: UnwindAction? = nil,
        topPreviewAction: PreviewAction? = nil,
        showMenuParameters parameters: [ShowMenuParameters] = [],
        completion: (() -> ())? = nil) {
        
        showAlert(title: title, subtitle: subtitle, context: context, topHeaderMode: topHeaderMode, with: actions, shouldSortActions: shouldSortActions, segmentDetails: segmentDetails, leftAction: leftAction, rightAction: rightAction, topAction: topAction, topPreviewAction: topPreviewAction, showMenuParameters: parameters, completion: completion)
    }
}
