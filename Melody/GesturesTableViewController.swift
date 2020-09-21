//
//  GesturesTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 18/07/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class GesturesTableViewController: UITableViewController {
    
    @IBOutlet var shortImageView: MELImageView!
    @IBOutlet var mediumImageView: MELImageView!
    @IBOutlet var longImageView: MELImageView!
    @IBOutlet var cells: [UITableViewCell]!
    
    var sections: SectionDictionary = [
        
        0: ("duration", "Applies to hold gestures.")
    ]
    var settings: SettingsDictionary = [
        
        .init(0, 0): .init(title: "Short", accessoryType: .check({ gestureDuration == .short })),
        .init(0, 1): .init(title: "Medium", accessoryType: .check({ gestureDuration == .medium })),
        .init(0, 2): .init(title: "Long", accessoryType: .check({ gestureDuration == .long }))
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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return .textHeaderHeight + 20
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = tableView.sectionHeader
        
        view?.label.text = sections[section]?.header
        
        return view
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0, gestureDuration.rawValue != indexPath.row, let oldCell = tableView.cellForRow(at: IndexPath.init(row: gestureDuration.rawValue, section: indexPath.section)) as? SettingsTableViewCell, let newCell = tableView.cellForRow(at: indexPath) as? SettingsTableViewCell, let oldSetting = settings[IndexPath.init(row: gestureDuration.rawValue, section: indexPath.section).settingsSection], let newSetting = settings[indexPath.settingsSection] {
            
            prefs.set(indexPath.row, forKey: .longPressDuration)
            notifier.post(name: .longPressDurationChanged, object: nil)
            
            oldCell.prepare(with: oldSetting)
            newCell.prepare(with: newSetting)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 54
    }
}
