
//
//  LibraryRefreshTableViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 25/02/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class LibraryRefreshTableViewController: UITableViewController {
    
    var sections: SectionDictionary = [
        
        0: (nil, "Only refreshes when there is a change to your library."),
        1: ("interval", nil)
    ]
    var settings: SettingsDictionary = [
        
        .init(0, 0): .init(title: "Refresh Now", accessoryType: .none),
        .init(1, 0): .init(title: "Manual", accessoryType: .check({ libraryRefreshInterval == .none })),
        .init(1, 1): .init(title: "30 seconds", accessoryType: .check({ libraryRefreshInterval == .thirtySeconds })),
        .init(1, 2): .init(title: "1 minute", accessoryType: .check({ libraryRefreshInterval == .oneMinute })),
        .init(1, 3): .init(title: "2 minutes", accessoryType: .check({ libraryRefreshInterval == .twoMinutes })),
        .init(1, 4): .init(title: "5 minutes", accessoryType: .check({ libraryRefreshInterval == .fiveMinutes })),
        .init(1, 5): .init(title: "10 minutes", accessoryType: .check({ libraryRefreshInterval == .tenMinutes })),
        .init(1, 6): .init(title: "30 minutes", accessoryType: .check({ libraryRefreshInterval == .thirtyMinutes })),
        .init(1, 7): .init(title: "1 hour", accessoryType: .check({ libraryRefreshInterval == .oneHour }))
    ]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.scrollIndicatorInsets.bottom = 14
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.settingCell(for: indexPath)
        
        if let setting = settings[indexPath.settingsSection] {
            
            cell.prepare(with: setting)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            
            if libraryRefreshInterval.rawValue != indexPath.row, let oldCell = tableView.cellForRow(at: IndexPath.init(row: libraryRefreshInterval.rawValue, section: indexPath.section)) as? SettingsTableViewCell, let newCell = tableView.cellForRow(at: indexPath) as? SettingsTableViewCell, let oldSetting = settings[IndexPath.init(row: libraryRefreshInterval.rawValue, section: indexPath.section).settingsSection], let newSetting = settings[indexPath.settingsSection] {
                
                prefs.set(indexPath.row, forKey: .libraryRefreshInterval)
                notifier.post(name: .libraryRefreshIntervalChanged, object: nil)
                
                oldCell.prepare(with: oldSetting)
                newCell.prepare(with: newSetting)
            }
            
        } else {
            
            refreshLibrary()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = sections[section]?.header
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return .textHeaderHeight + 8
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footer = tableView.sectionFooter
        
        if let text = sections[section]?.footer {
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = .footerLineHeight
            
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 54
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "LRTVC going away...").show(for: 0.3)
        }
    }
}
