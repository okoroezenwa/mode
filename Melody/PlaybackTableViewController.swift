//
//  PlaybackTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 22/07/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PlaybackTableViewController: UITableViewController {
    
    var sections: SectionDictionary = [
        
        0: (nil, "Tap an item's artwork to play just that item."),
        1: (nil, "When disabled, any active shuffle mode will be discarded when the queue is reset."),
        2: (nil, "When disabled, any active repeat mode will be discarded when the queue is reset.")
    ]
    lazy var settings: SettingsDictionary = [
        
        .init(0, 0): .init(title: "Single Play", accessoryType: .onOff(isOn: { allowPlayOnly }, action: { [weak self] in self?.togglePlayOnly() })),
        .init(1, 0): .init(title: "Preserve Shuffle State", accessoryType: .onOff(isOn: { keepShuffleState }, action: { [weak self] in self?.toggleKeepShuffleState() })),
        .init(2, 0): .init(title: "Preserve Repeat State", accessoryType: .onOff(isOn: { preserveRepeatState }, action: { [weak self] in self?.toggleKeepRepeatState() }))
    ]

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.scrollIndicatorInsets.bottom = 14
    }
    
    func togglePlayOnly() {
        
        prefs.set(!allowPlayOnly, forKey: .playOnlyShortcut)
        notifier.post(name: .playOnlyChanged, object: nil)
    }
    
    func toggleKeepShuffleState() {
        
        prefs.set(!keepShuffleState, forKey: .keepShuffleState)
    }
    
    func toggleKeepRepeatState() {
        
        prefs.set(!preserveRepeatState, forKey: .preserveRepeatState)
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
        
        return .tableHeader + 8
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
}
