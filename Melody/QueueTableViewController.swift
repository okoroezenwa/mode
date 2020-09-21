//
//  QueueGuardTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 29/05/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit
import NotificationCenter

class QueueTableViewController: UITableViewController {
    
    enum GuardCriteria: String {
        
        case play, change, add, remove, clear, stop
    }
    
    lazy var sections: SectionDictionary = [

        0: ("active player", self.firstSectionFooter),
        1: (nil, "When enabled, a confirmation alert will be shown for the selected criteria before the queue is modified."),
        2: ("show alert on...", nil)
    ]
    lazy var settings: SettingsDictionary = [

        .init(0, 0): .init(title: "Mode", accessoryType: .check({ useSystemPlayer.inverted })),
        .init(0, 1): .init(title: "Music app", accessoryType: .check({ useSystemPlayer })),
        .init(1, 0): .init(title: "Guard", accessoryType: .onOff(isOn: { warnForQueueInterruption }, action: { [weak self] in self?.toggleQueueGuard() })),
        .init(2, 0): .init(title: "Playback Start", accessoryType: .onOff(isOn: { playGuard }, action: { [weak self] in self?.toggleCriteria(.play) }), inactive: { warnForQueueInterruption.inverted }),
        .init(2, 1): .init(title: "Now Playing Change", accessoryType: .onOff(isOn: { changeGuard }, action: { [weak self] in self?.toggleCriteria(.change) }), inactive: { warnForQueueInterruption.inverted }),
        .init(2, 2): .init(title: "Queue Addition", accessoryType: .onOff(isOn: { addGuard }, action: { [weak self] in self?.toggleCriteria(.add) }), inactive: { warnForQueueInterruption.inverted }),
        .init(2, 3): .init(title: "Queue Removal", accessoryType: .onOff(isOn: { removeGuard }, action: { [weak self] in self?.toggleCriteria(.remove) }), inactive: { warnForQueueInterruption.inverted }),
        .init(2, 4): .init(title: "Queue Clear", accessoryType: .onOff(isOn: { clearGuard }, action: { [weak self] in self?.toggleCriteria(.clear) }), inactive: { warnForQueueInterruption.inverted }),
        .init(2, 5): .init(title: "Playback Stop", accessoryType: .onOff(isOn: { stopGuard }, action: { [weak self] in self?.toggleCriteria(.stop) }), inactive: { warnForQueueInterruption.inverted })
    ]
    
    let firstSectionFooter: String = {
        
        if #available(iOS 12.2, *) {
            
            return "The Today widget is unavailable when using Mode's player."
            
        } else if #available(iOS 11, *) {
            
            return "Using Mode's player is not advised due to multiple bugs."
        }
        
        return "Playing via the Music app will result in a worse experience when editing or adding to the queue."
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.scrollIndicatorInsets.bottom = 14
    }
    
    @objc func prepareQueueImageView(at row: Int) {
        
        guard (row == 0 && useSystemPlayer) || (row == 1 && !useSystemPlayer) else { return }
        
//        let alert = UIAlertAction.init(title: "Quit", style: .destructive, handler: { _ in
        
        if musicPlayer.isPlaying { musicPlayer.pause() }
            
        let newPreference = !useSystemPlayer
        
        prefs.set(newPreference, forKey: .systemPlayer)
        sharedDefaults.set(newPreference, forKey: .systemPlayer)
        sharedDefaults.set(true, forKey: .quitWidget)
        sharedDefaults.synchronize()
        
        let hasContent: Bool = {
            
            if #available(iOS 10, *) {
                
                return newPreference
            }
            
            return false
        }()
        
        NCWidgetController().setHasContent(hasContent, forWidgetWithBundleIdentifier: (Bundle.main.bundleIdentifier ?? ModeBuild.release.rawValue) + ".Widget")
        
        notifier.post(name: .playerChanged, object: nil)
//        })
        
//        present(UIAlertController.withTitle("Relaunch Required", message: "Mode must quit and be relaunched for this to take effect.", style: .alert, actions: alert, .cancel()), animated: true, completion: nil)
    }
    
    func toggleQueueGuard(_ sender: Any? = nil) {
        
        let bool = !warnForQueueInterruption
        prefs.set(bool, forKey: .warnInterruption)
        
        if sender is UIViewController, let cell = tableView.cellForRow(at: .init(row: 0, section: 1)) as? SettingsTableViewCell {
            
            cell.itemSwitch.setOn(cell.itemSwitch.isOn.inverted, animated: true)
        }
        
        if let indexPaths = tableView.indexPathsForVisibleRows?.filter({ $0.section == 2 }) {
            
            indexPaths.forEach({
                
                guard let cell = tableView.cellForRow(at: $0) as? SettingsTableViewCell, let setting = settings[$0.settingsSection] else { return }
                
                cell.prepare(with: setting)
            })
        }
        
        if let header = tableView.headerView(forSection: 2) as? TableHeaderView {
            
            header.label.lightOverride = warnForQueueInterruption.inverted
        }
    }
    
    func toggleCriteria(_ criteria: GuardCriteria) {
        
        var details: (id: String, value: Bool) {
            
            switch criteria {
                
                case .add: return (.addGuard, addGuard)
                
                case .change: return (.changeGuard, changeGuard)
                
                case .clear: return (.clearGuard, clearGuard)
                
                case .play: return (.playGuard, playGuard)
                
                case .remove: return (.removeGuard, removeGuard)
                
                case .stop: return (.stopGuard, stopGuard)
            }
        }
        
        prefs.set(details.value.inverted, forKey: details.id)
        
        if !playGuard, !changeGuard, !addGuard, !removeGuard, !clearGuard, !stopGuard {
            
            toggleQueueGuard(self)
        }
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
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        return indexPath.section == 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = sections[section]?.header
        
        if section == 2 {
            
            header?.label.lightOverride = warnForQueueInterruption.inverted
        }
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        switch section {
            
            case 0:
            
                guard #available(iOS 10.3, *) else { return 0.00001 }
            
                return .textHeaderHeight + 20
            
            case 1: return .tableHeader
            
            case 2: return .textHeaderHeight + 20
            
            default: return .tableHeader
        }
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
        
        if section == 0 {
            
            guard #available(iOS 10.3, *) else { return 0.00001 }
        }
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        
        return 50
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            
            prepareQueueImageView(at: indexPath.row)
            tableView.reloadSections(indexPath.indexSet, with: .fade)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            
            if #available(iOS 10.3, *) { } else { return 0 }
        }
        
        return 54
    }
}
