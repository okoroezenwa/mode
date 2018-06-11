//
//  TabBarTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 22/07/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class TabBarTableViewController: UITableViewController {
    
    @IBOutlet var cells: [UITableViewCell]!
    @IBOutlet var nothingImageView: MELImageView!
    @IBOutlet var topImageView: MELImageView!
    @IBOutlet var startImageView: MELImageView!
    @IBOutlet var startScrollImageView: MELImageView!
    @IBOutlet weak var miniCompactSwitch: MELSwitch! {
        
        didSet {
            
            miniCompactSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleCompactPlayer()
            }
        }
    }
    @IBOutlet weak var duplicatesSwitch: MELSwitch! {
        
        didSet {
            
            duplicatesSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleDuplicates()
            }
        }
    }
    @IBOutlet weak var collectorCompactSwitch: MELSwitch! {
        
        didSet {
            
            collectorCompactSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleCompactCollector()
            }
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        cells.forEach({ $0.selectedBackgroundView = MELBorderView.init() })
        
        prepareSwitches()
        updateImageViews()
        
        tableView.scrollIndicatorInsets.bottom = 14
    }
    
    func prepareSwitches() {
        
        miniCompactSwitch.setOn(useMicroPlayer, animated: false)
        collectorCompactSwitch.setOn(useCompactCollector, animated: false)
        duplicatesSwitch.setOn(collectorPreventsDuplicates, animated: false)
    }
    
    func updateImageViews() {
        
        nothingImageView.isHidden = tabBarTapBehaviour != .nothing
        topImageView.isHidden = tabBarTapBehaviour != .scrollToTop
        startImageView.isHidden = tabBarTapBehaviour != .returnToStart
        startScrollImageView.isHidden = tabBarTapBehaviour != .returnThenScroll
    }
    
//    @IBAction func toggleFilter() {
//
//        let bool = !filterShortcutEnabled
//        prefs.set(bool, forKey: .filterShortcutEnabled)
//    }
//
//    @IBAction func toggleReturn() {
//
//        prefs.set(!backToStartEnabled, forKey: .backToStart)
//    }
    
    @IBAction func toggleCompactPlayer() {
        
        prefs.set(!useMicroPlayer, forKey: .microPlayer)
        notifier.post(name: .microPlayerChanged, object: nil)
    }
    
    @IBAction func toggleCompactCollector() {
        
        prefs.set(!useCompactCollector, forKey: .useCompactCollector)
        notifier.post(name: .collectorSizeChanged, object: nil)
    }
    
    @IBAction func toggleDuplicates() {
        
        prefs.set(!collectorPreventsDuplicates, forKey: .collectorPreventsDuplicates)
    }
    
//    @IBAction func toggleScrollToTop() {
//
//        prefs.set(!tabBarScrollToTop, forKey: .tabBarScrollToTop)
//    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
            
            case 0: return 4
            
            case 1: return 1
            
            case 2: return 2
            
            default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.preservesSuperviewLayoutMargins = false
        cell.contentView.preservesSuperviewLayoutMargins = false
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        
        let footer = view as? UITableViewHeaderFooterView
        footer?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard indexPath.row != tabBarTapBehaviour.rawValue, let behaviour = TabBarTapBehaviour(rawValue: indexPath.row) else { return }
        
        prefs.set(behaviour.rawValue, forKey: .tabBarTapBehaviour)
        updateImageViews()
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return /*Set([3, 4]).contains(section) ? */.textHeaderHeight + 20// : .tableHeader + 10
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = {
            
            switch section {
                
                case 0: return "selected tab behaviour"
                
                case 1: return "mini player"
                
                case 2: return "collector"
                
                default: return nil
            }
        }()
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        return indexPath.section == 0
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footer = tableView.sectionFooter
        
        var footerText: String? {
            
            switch section {
                
                case 0: return "A tap on the already selected tab will trigger a return to the starting view if not on it, otherwise scroll to the top of the main view when tapped."
                
                case 1: return "Press and hold on the playing song to view song options."
                    
                default: return nil
            }
        }
        
        if let text = footerText {
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.5
            
            footer?.label.text = text
            footer?.label.attributes = [.init(name: .paragraphStyle, value: .other(paragraphStyle), range: text.nsRange())]
            
        } else {
            
            footer?.label.text = nil
            footer?.label.attributes = nil
        }
        
        return footer
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        
        return 50
    }
}
