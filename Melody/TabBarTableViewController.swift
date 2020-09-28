//
//  TabBarTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 22/07/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class TabBarTableViewController: UITableViewController {
    
    var sections: SectionDictionary = [
        
        0: ("appearance", nil),
        1: ("selected tab behaviour", "A tap on the already selected tab will trigger a return to the starting view if not on it, otherwise scroll to the top of the main view when tapped."),
        2: ("mini player", "Press and hold on the playing song to view song options."),
        3: ("collector", nil)
    ]
    
    lazy var settings: SettingsDictionary = [
        
        .init(0, 0): .init(title: "Show Tab Titles", accessoryType: .onOff(isOn: { showTabBarLabels }, action: { showTabBarLabels.toggle() })),
        .init(1, 0): .init(title: "Do Nothing", accessoryType: .check({ tabBarTapBehaviour == .nothing })),
        .init(1, 1): .init(title: "Scroll to Top", accessoryType: .check({ tabBarTapBehaviour == .scrollToTop })),
        .init(1, 2): .init(title: "Return to Start", accessoryType: .check({ tabBarTapBehaviour == .returnToStart })),
        .init(1, 3): .init(title: "Return, then Scroll to Top", accessoryType: .check({ tabBarTapBehaviour == .returnThenScroll })),
        .init(2, 0): .init(title: "Show Song Titles", accessoryType: .onOff(isOn: { showMiniPlayerSongTitles }, action: { showMiniPlayerSongTitles.toggle() })),
        .init(2, 1): .init(title: "Show Full Scrubber", accessoryType: .onOff(isOn: { useExpandedSlider }, action: { useExpandedSlider.toggle() })),
        .init(2, 2): .init(title: "Always Hide Title", accessoryType: .onOff(isOn: { false }, action: { })),
        .init(2, 3): .init(title: "Prefer Queue Position", subtitle: "Replaces the static mini player title with the current position in the queue.", attributesInfo: .init(subtitleAttributes: [.init(name: .paragraphStyle, value: .other(NSMutableParagraphStyle.withLineHeight(.settingsSubtitleLineHeight)), range: "Replaces the \"Queue\" label title with the current position in the queue.".nsRange())]), accessoryType: .onOff(isOn: { useQueuePositionMiniPlayerTitle }, action: { useQueuePositionMiniPlayerTitle.toggle() })),
        .init(3, 0): .init(title: "Compact", accessoryType: .onOff(isOn: { useCompactCollector }, action: { [weak self] in self?.toggleCompactCollector() })),
        .init(3, 1): .init(title: "Prevent Duplicates", accessoryType: .onOff(isOn: { collectorPreventsDuplicates }, action: { [weak self] in self?.toggleDuplicates() })),
    ]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.scrollIndicatorInsets.bottom = 14
    }
    
    func toggleCompactCollector() {
        
        prefs.set(!useCompactCollector, forKey: .useCompactCollector)
        notifier.post(name: .collectorSizeChanged, object: nil)
    }
    
    func toggleDuplicates() {
        
        prefs.set(!collectorPreventsDuplicates, forKey: .collectorPreventsDuplicates)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        settings.filter({ $0.key.section == section }).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.settingCell(for: indexPath)
        
        if let setting = settings[indexPath.settingsSection] {
            
            cell.prepare(with: setting)
            
            if cell.subtitleLabel.numberOfLines > 0 {
                
                cell.subtitleLabel.numberOfLines = 0
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard indexPath.row != tabBarTapBehaviour.rawValue, let behaviour = TabBarTapBehaviour(rawValue: indexPath.row) else { return }
        
        prefs.set(behaviour.rawValue, forKey: .tabBarTapBehaviour)
        
        for (index, cell) in (0..<tableView.numberOfRows(inSection: indexPath.section)).compactMap({ ($0, tableView.cellForRow(at: .init(item: $0, section: indexPath.section))) as? (Int, SettingsTableViewCell) }) {
            
            if let setting = settings[IndexPath.init(item: index, section: indexPath.section).settingsSection] {
                
                cell.prepare(with: setting)
            }
        }
                    
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return .textHeaderHeight + (section == 1 ? 8 : 20)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = sections[section]?.header
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        Set(settings.filter({
            
            switch $0.value.accessoryType {
                
                case .check: return true
                
                default: return false
            }
        
        }).keys.map({ $0.section })).contains(indexPath.section)
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
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        settings[indexPath.settingsSection]?.subtitle?.isEmpty == false ? 54 : 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        settings[indexPath.settingsSection]?.subtitle?.isEmpty == false ? UITableView.automaticDimension : 54
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        
        return 50
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "TBVC going away...").show(for: 0.3)
        }
    }
}
