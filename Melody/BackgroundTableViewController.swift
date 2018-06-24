//
//  ArtworkTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 22/07/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class BackgroundTableViewController: UITableViewController {
    
    var sections: SectionDictionary = [
        
        0: ("artwork", nil)
    ]
    var settings: SettingsDictionary = [
        
        .init(0, 0): .init(title: "Static", accessoryType: .check({ backgroundArtworkAdaptivity == .none })),
        .init(0, 1): .init(title: "Adapts to View", accessoryType: .check({ backgroundArtworkAdaptivity == .sectionAdaptive })),
        .init(0, 2): .init(title: "Adapts to Now Playing", accessoryType: .check({ backgroundArtworkAdaptivity == .nowPlayingAdaptive }))
    ]

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.scrollIndicatorInsets.bottom = 14
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
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = sections[section]?.header
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return .textHeaderHeight + (section == 0 ? 20 : 8)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 && backgroundArtworkAdaptivity.rawValue != indexPath.row, let oldCell = tableView.cellForRow(at: IndexPath.init(row: backgroundArtworkAdaptivity.rawValue, section: indexPath.section)) as? SettingsTableViewCell, let newCell = tableView.cellForRow(at: indexPath) as? SettingsTableViewCell, let oldSetting = settings[IndexPath.init(row: backgroundArtworkAdaptivity.rawValue, section: indexPath.section).settingsSection], let newSetting = settings[indexPath.settingsSection] {
            
            prefs.set(indexPath.row, forKey: .backgroundArtworkAdaptivity)
            notifier.post(name: .backgroundArtworkAdaptivityChanged, object: nil)
            
            oldCell.prepare(with: oldSetting)
            newCell.prepare(with: newSetting)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 54
    }
}
