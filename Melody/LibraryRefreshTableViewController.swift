
//
//  LibraryRefreshTableViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 25/02/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class LibraryRefreshTableViewController: UITableViewController {
    
    @IBOutlet var cells: [UITableViewCell]!
    @IBOutlet weak var manualImageView: MELImageView!
    @IBOutlet weak var thirtySecondsImageView: MELImageView!
    @IBOutlet weak var oneMinuteImageView: MELImageView!
    @IBOutlet weak var twoMinutesImageView: MELImageView!
    @IBOutlet weak var fiveMinutesImageView: MELImageView!
    @IBOutlet weak var tenMinutesImageView: MELImageView!
    @IBOutlet weak var thirtyMinutesImageView: MELImageView!
    @IBOutlet weak var oneHourImageView: MELImageView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.scrollIndicatorInsets.bottom = 14

        cells.forEach({ $0.selectedBackgroundView = MELBorderView.init() })
        
        prepareImageViews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareImageViews() {
        
        manualImageView.isHidden = libraryRefreshInterval != .none
        thirtySecondsImageView.isHidden = libraryRefreshInterval != .thirtySeconds
        oneMinuteImageView.isHidden = libraryRefreshInterval != .oneMinute
        twoMinutesImageView.isHidden = libraryRefreshInterval != .twoMinutes
        fiveMinutesImageView.isHidden = libraryRefreshInterval != .fiveMinutes
        tenMinutesImageView.isHidden = libraryRefreshInterval != .tenMinutes
        thirtyMinutesImageView.isHidden = libraryRefreshInterval != .thirtyMinutes
        oneHourImageView.isHidden = libraryRefreshInterval != .oneHour
    }
    
    func refreshLibrary() {
        
        appDelegate.updateLibrary()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return section == 1 ? 8 : 1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            
            if libraryRefreshInterval.rawValue != indexPath.row {
                
                prefs.set(indexPath.row, forKey: .libraryRefreshInterval)
                notifier.post(name: .libraryRefreshIntervalChanged, object: nil)
                
                prepareImageViews()
            }
            
        } else {
            
            refreshLibrary()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.preservesSuperviewLayoutMargins = false
        cell.contentView.preservesSuperviewLayoutMargins = false
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        
        let footer = view as? UITableViewHeaderFooterView
        footer?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = {
            
            switch section {
                
                case 1: return "interval"
                
                default: return nil
            }
        }()
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return .textHeaderHeight + 8
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footer = tableView.sectionFooter
        
        var footerText: String? {
            
            switch section {
                
                case 0: return "Only refreshes when there is a change to your library."
                
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
        
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        
        return 50
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "LRTVC going away...").show(for: 0.3)
        }
    }
}
