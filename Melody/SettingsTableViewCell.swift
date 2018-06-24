//
//  SettingsTableViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 20/06/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {

    @IBOutlet var titleLabel: MELLabel!
    @IBOutlet var subtitleLabel: MELLabel!
    @IBOutlet var tertiaryLabel: MELLabel!
    @IBOutlet var chevron: MELImageView!
    @IBOutlet var check: MELImageView!
    @IBOutlet var itemSwitch: MELSwitch!
    @IBOutlet var borderViews: [MELBorderView]!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        selectedBackgroundView = MELBorderView()
        
        preservesSuperviewLayoutMargins = false
        contentView.preservesSuperviewLayoutMargins = false
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)
        
        borderViews.forEach({ $0.alphaOverride = selected ? 0.05 : 0 })
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        
        super.setHighlighted(highlighted, animated: animated)
        
        borderViews.forEach({ $0.alphaOverride = highlighted ? 0.05 : 0 })
    }

    func prepare(with setting: Setting, animated: Bool = false) {
        
        titleLabel.text = setting.title
        titleLabel.textAlignment = setting.accessoryType == .none ? .center : .left
        subtitleLabel.text = setting.subtitle
        subtitleLabel.isHidden = setting.subtitle == nil
        tertiaryLabel.text = setting.tertiaryDetail
        tertiaryLabel.isHidden = setting.tertiaryDetail == nil
        chevron.superview?.isHidden = setting.accessoryType != .chevron
        check.superview?.isHidden = { if case .check(let bool) = setting.accessoryType { return bool().inverted } else { return true } }()
        itemSwitch.isHidden = {
            
            if case .onOff(isOn: let isOn, let action) = setting.accessoryType {
                
                itemSwitch.setOn(isOn(), animated: animated)
                itemSwitch.action = action
                return false
                
            } else {
                
                return true
            }
        }()
        borderViews.forEach({ $0.isHidden = setting.accessoryType != .none })
        
        titleLabel.lightOverride = setting.inactive()
        subtitleLabel.lightOverride = setting.inactive()
        tertiaryLabel.lightOverride = setting.inactive()
        chevron.lightOverride = setting.inactive()
        check.lightOverride = setting.inactive()
        itemSwitch.isUserInteractionEnabled = setting.inactive().inverted
    }
}

struct Setting {
    
    let title: String
    let subtitle: String?
    let tertiaryDetail: String?
    let accessoryType: Setting.AccessoryType
    let image: UIImage?
    let inactive: (() -> Bool)
    
    enum AccessoryType: Equatable {
        
        case none, chevron, check(() -> (Bool)), onOff(isOn: () -> (Bool), action: (() -> ()))
        
        static func ==(lhs: AccessoryType, rhs: AccessoryType) -> Bool {
            
            switch lhs {
                
            case .none: if case .none = rhs { return true } else { return false }
                
                case .chevron: if case .chevron = rhs { return true } else { return false }
                
                case .check(let bool): if case .check(let otherBool) = rhs { return bool() == otherBool() } else { return false }
                
                case .onOff(_): if case .onOff(_) = rhs { return true } else { return false }
            }
        }
    }
    
    init(title: String, subtitle: String? = nil, image: UIImage? = nil, tertiaryDetail: String? = nil, accessoryType: AccessoryType, inactive inactiveCondition: @escaping (() -> Bool) = { false }) {
        
        self.title = title
        self.subtitle = subtitle
        self.tertiaryDetail = tertiaryDetail
        self.image = image
        self.accessoryType = accessoryType
        self.inactive = inactiveCondition
    }
}

struct SettingSection: Hashable {
    
    let section: Int
    let row: Int
    
    init(_ section: Int, _ row: Int) {
        
        self.section = section
        self.row = row
    }
    
    var indexPath: IndexPath { return .init(row: row, section: section) }
    
    static func from(_ indexPath: IndexPath) -> SettingSection {
        
        return .init(indexPath.section, indexPath.row)
    }
}
