//
//  Refreshable.swift
//  Melody
//
//  Created by Ezenwa Okoro on 15/06/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

protocol Refreshable: class, TableViewContaining {
    
    var refresher: Refresher { get }
}

class Refresher: NSObject {
    
    weak var refreshable: Refreshable?
    
    init(refreshable: Refreshable) {
        
        super.init()
        
        self.refreshable = refreshable
    }
    
    @objc func refresh(_ sender: UIRefreshControl) {
        
        guard let refreshMode = RefreshMode(rawValue: refreshMode) else { return }
        
        sender.endRefreshing()
        
        UniversalMethods.performOnMainThread({ self.performRefreshAction(with: refreshMode) }, afterDelay: 0.1)
    }
    
    func performRefreshAction(with refreshMode: RefreshMode) {
        
        switch refreshMode {
            
            case .ask:
                
                guard let vc = refreshable as? UIViewController else { return }
            
                let offline = UIAlertAction.init(title: "Go \(showiCloudItems ? "Offline" : "Online")", style: .default, handler: { _ in
                
                    prefs.set(!showiCloudItems, forKey: .iCloudItems)
                    notifier.post(name: .iCloudVisibilityChanged, object: nil)
                })
                
                let reload = UIAlertAction.init(title: "Refresh", style: .default, handler: { [weak self] _ in
                    
                    guard let weakSelf = self, let sorter = weakSelf.refreshable as? Arrangeable else { return }
                    
                    sorter.sortItems()
                })
            
                let theme = UIAlertAction.init(title: "\(darkTheme ? "Light" : "Dark") Theme", style: .default, handler: { _ in
                    
                    prefs.set(!darkTheme, forKey: .darkTheme)
//                    notifier.post(name: .themeChanged, object: nil)
                    
                    if let view = appDelegate.window?.rootViewController?.view {
                        
                        UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: { notifier.post(name: .themeChanged, object: nil) }, completion: nil)
                    }
                })
            
                let filter = UIAlertAction.init(title: "Filter", style: .default, handler: { [weak self] _ in
                    
                    guard let weakSelf = self, let filter = weakSelf.refreshable as? Filterable else { return }
                    
                    filter.invokeSearch()
                })
            
                vc.present(UIAlertController.withTitle(nil, message: nil, style: .actionSheet, actions: filter, reload, offline, theme, .cancel()), animated: true, completion: { [weak self] in
                    
                    guard let weakSelf = self else { return }
                    
                    if let refreshable = weakSelf.refreshable, abs(refreshable.tableView.contentOffset.y) > 10 {
                        
                        refreshable.tableView.setContentOffset(.zero, animated: true)
                    }
                })
                
            case .filter:
                
                guard let filter = refreshable as? Filterable else {
                    
                    performRefreshAction(with: .ask)
                    return
                }
                
                filter.invokeSearch()
            
            case .refresh:
            
                guard let sorter = refreshable as? Arrangeable else {
                    
                    performRefreshAction(with: .ask)
                    return
                }
            
                sorter.sortItems()
            
            case .offline:
                
                prefs.set(!showiCloudItems, forKey: .iCloudItems)
                notifier.post(name: .iCloudVisibilityChanged, object: nil)
                
            case .theme:
                
                prefs.set(!darkTheme, forKey: .darkTheme)
//                notifier.post(name: .themeChanged, object: nil)
                
                if let view = appDelegate.window?.rootViewController?.view {
                    
                    UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: { notifier.post(name: .themeChanged, object: nil) }, completion: nil)
                }
        }
    }
}
