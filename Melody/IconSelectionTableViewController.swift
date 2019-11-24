//
//  IconSelectionTableViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 31/01/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class IconSelectionTableViewController: UITableViewController {
    
    var sections: SectionDictionary = [
        
        0: ("style", nil),
        1: ("line width", nil),
        2: ("background", nil)
    ]
    var settings: SettingsDictionary = [
        
        .init(0, 0): .init(title: "Static", accessoryType: .check({ iconType == .regular })),
        .init(0, 1): .init(title: "Colourful", accessoryType: .check({ iconType == .rainbow })),
        .init(0, 2): .init(title: "Alternating", accessoryType: .check({ iconType == .trans })),
        .init(1, 0): .init(title: "Thin", accessoryType: .check({ iconLineWidth == .thin })),
        .init(1, 1): .init(title: "Medium", accessoryType: .check({ iconLineWidth == .medium })),
        .init(1, 2): .init(title: "Wide", accessoryType: .check({ iconLineWidth == .wide })),
        .init(2, 0): .init(title: "Dark", accessoryType: .check({ iconTheme == .dark }), inactive: { iconType == .trans }),
        .init(2, 1): .init(title: "Light", accessoryType: .check({ iconTheme == .light }), inactive: { iconType == .trans }),
        .init(2, 2): .init(title: "Match Current Theme", accessoryType: .check({ iconTheme == .match }), inactive: { iconType == .trans })
    ]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.scrollIndicatorInsets.bottom = 14
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateIconIfNeeded() {
        
        let icon = Icon.iconName(type: iconType, width: iconLineWidth, theme: iconTheme).rawValue.nilIfEmpty
        
        guard #available(iOS 10.3, *), UIApplication.shared.supportsAlternateIcons, icon != UIApplication.shared.alternateIconName else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: { UIApplication.shared.setAlternateIconName(icon, completionHandler: { error in if let error = error { print(error) } }) })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return settings.filter({ $0.key.section == section }).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.settingCell(for: indexPath)
        
        if let setting = settings[indexPath.settingsSection] {
            
            cell.prepare(with: setting)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let value: Int = {
            
            switch indexPath.section {
                
                case 0: return iconType.rawValue
            
                case 1: return iconLineWidth.rawValue
                
                case 2: return iconTheme.rawValue
                
                default: fatalError("No other section should be here")
            }
        }()
        
        if indexPath.row != value, let oldCell = tableView.cellForRow(at: IndexPath.init(row: value, section: indexPath.section)) as? SettingsTableViewCell, let newCell = tableView.cellForRow(at: indexPath) as? SettingsTableViewCell, let oldSetting = settings[IndexPath.init(row: value, section: indexPath.section).settingsSection], let newSetting = settings[indexPath.settingsSection] {
            
            prefs.set(indexPath.row, forKey: {
                
                switch indexPath.section {
                    
                    case 0: return .iconType
                
                    case 1: return .iconLineWidth
                    
                    case 2: return .iconTheme
                    
                    default: fatalError("No other section should be here")
                }
            
            }())
            
            oldCell.prepare(with: oldSetting)
            newCell.prepare(with: newSetting)
            
            updateIconIfNeeded()
            
            if indexPath.section == 0 { tableView.reloadSections(.init(integer: 2), with: .none) }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = sections[section]?.header
        header?.label.lightOverride = section == 2 && iconType == .trans
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        switch section {
            
            case 0: return .textHeaderHeight + 20
            
            case 1, 2: return .textHeaderHeight + 8
            
            default: return 0.00001
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.00001
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 54
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        return settings[SettingSection.from(indexPath)]?.inactive() == false
    }
}
