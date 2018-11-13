//
//  PropertiesTableViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 14/09/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PropertiesTableViewController: UITableViewController {
    
    lazy var sections: SectionDictionary = [
        
        0: (nil, "Turn an item off to hide it from view."),
        1: ("other", "Move items here to group into an \"Other\" list.")
    ]
    
    lazy var settings = SettingsDictionary()
    
    var context = FilterViewContext.library
    
    var relevantArrays: (hidden: [PropertyStripPresented], dynamic: [PropertyStripPresented], other: [PropertyStripPresented]) {
        
        switch context {
            
            case .library: return (hiddenLibrarySections, librarySections, otherLibrarySections)
            
            case .filter: return (hiddenFilterProperties, filterProperties, otherFilterProperties)
        }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.scrollIndicatorInsets.bottom = 14
        tableView.setEditing(true, animated: false)
        
        prepareSections()
        tableView.reloadData()
    }
    
    func update(_ property: PropertyStripPresented, operation: FilterViewContext.Operation) {
        
        property.perform(operation, context: context)
        
        prepareSections()
    }

    func performCheck(on property: PropertyStripPresented, within array: [PropertyStripPresented]) -> Bool {
        
        switch context {
            
            case .library:
            
                guard let section = property as? LibrarySection, let sections = array as? [LibrarySection] else { return false }
            
                return Set(sections).contains(section).inverted
            
            case .filter:
            
                guard let property = property as? Property, let properties = array as? [Property] else { return false }
                
                return Set(properties).contains(property).inverted
        }
    }
    
    func prepareSections() {
        
        let arrays = relevantArrays
        
        var firstSection = arrays.dynamic.enumerated().reduce(SettingsDictionary(), { dictionary, enumerated in
            
            let isVisible = performCheck(on: enumerated.element, within: arrays.hidden)
            
            var sections = dictionary
            sections[.init(0, enumerated.offset)] = Setting.init(title: enumerated.element.title, accessoryType: Setting.AccessoryType.onOff(isOn: { isVisible }, action: { [weak self] in self?.update(enumerated.element, operation: isVisible ? .hide : .unhide) }))
            
            return sections
        })
        
        let secondSection = arrays.other.enumerated().reduce(SettingsDictionary(), { dictionary, enumerated in
            
            var sections = dictionary
            sections[.init(1, enumerated.offset)] = Setting.init(title: enumerated.element.title, accessoryType: .none)
            
            return sections
        })
        
        secondSection.forEach({ firstSection[$0.key] = $0.value  })
        
        settings = firstSection
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
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        guard sourceIndexPath != destinationIndexPath else { return }
        
        let arrays = relevantArrays
        
        switch (sourceIndexPath.section, destinationIndexPath.section) {
            
            case (0, 1):
            
                update(arrays.dynamic[sourceIndexPath.row], operation: .group(index: destinationIndexPath.row))
                tableView.reloadData()//reloadRows(at: [destinationIndexPath], with: .none)
            
            case (1, 0):
            
                update(arrays.other[sourceIndexPath.row], operation: .ungroup(index: destinationIndexPath.row))
                tableView.reloadData()//reloadRows(at: [destinationIndexPath], with: .none)
            
            case (0, 0), (1, 1):
            
                switch context {
                    
                    case .library:
                    
                        guard let sections = (sourceIndexPath.section == 0 ? arrays.dynamic : arrays.other) as? [LibrarySection] else { return }
                    
                        prefs.set(sections.moving(from: sourceIndexPath.row, to: destinationIndexPath.row).map({ $0.rawValue }), forKey: (sourceIndexPath.section == 0 ? .librarySections : .otherLibrarySections))
                    
                    case .filter:
                    
                        guard let properties = (sourceIndexPath.section == 0 ? arrays.dynamic : arrays.other) as? [Property] else { return }
                        
                        prefs.set(properties.moving(from: sourceIndexPath.row, to: destinationIndexPath.row).map({ $0.rawValue }), forKey: (sourceIndexPath.section == 0 ? .filterProperties : .otherFilterProperties))
                }
            
                prepareSections()
                tableView.reloadData()
            
                notifier.post(name: .propertiesUpdated, object: nil, userInfo: [String.filterViewContext: context])
            
            default: return
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        
        return false
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = sections[section]?.header
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footer = tableView.sectionFooter
        
        if let text = sections[section]?.footer {
            
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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return (section == 0 ? .tableHeader : .textHeaderHeight) + 8
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 54
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        
        return 50
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "PSTVC going away...").show(for: 0.3)
        }
    }
}
