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
        
        0: ("line width", nil),
        1: ("theme", nil)
    ]
    var settings: SettingsDictionary = [
        
        .init(0, 0): .init(title: "Thin", accessoryType: .check({ iconLineWidth == .thin })),
        .init(0, 1): .init(title: "Medium", accessoryType: .check({ iconLineWidth == .medium })),
        .init(0, 2): .init(title: "Wide", accessoryType: .check({ iconLineWidth == .wide })),
        .init(1, 0): .init(title: "Dark", accessoryType: .check({ iconTheme == .dark })),
        .init(1, 1): .init(title: "Light", accessoryType: .check({ iconTheme == .light })),
        .init(1, 2): .init(title: "Match Current Theme", accessoryType: .check({ iconTheme == .match }))
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
        
        let icon = Icon.iconName(width: iconLineWidth, theme: iconTheme)
        
        guard #available(iOS 10.3, *), UIApplication.shared.supportsAlternateIcons, (icon.rawValue.isEmpty ? nil : icon.rawValue) != UIApplication.shared.alternateIconName else { return }
        
        UIApplication.shared.setAlternateIconName(icon.rawValue.isEmpty ? nil : icon.rawValue, completionHandler: { _ in })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.settingCell(for: indexPath)
        
        if let setting = settings[indexPath.settingsSection] {
            
            cell.prepare(with: setting)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let value = indexPath.section == 0 ? iconLineWidth.rawValue : iconTheme.rawValue
        
        if indexPath.row != value, let oldCell = tableView.cellForRow(at: IndexPath.init(row: value, section: indexPath.section)) as? SettingsTableViewCell, let newCell = tableView.cellForRow(at: indexPath) as? SettingsTableViewCell, let oldSetting = settings[IndexPath.init(row: value, section: indexPath.section).settingsSection], let newSetting = settings[indexPath.settingsSection] {
            
            prefs.set(indexPath.row, forKey: indexPath.section == 0 ? .iconLineWidth : .iconTheme)
            
            oldCell.prepare(with: oldSetting)
            newCell.prepare(with: newSetting)
            
            updateIconIfNeeded()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = sections[section]?.header
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        switch section {
            
            case 0: return .textHeaderHeight + 20
            
            case 1: return .textHeaderHeight + 8
            
            default: return 0.00001
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.00001
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 54
    }
}
