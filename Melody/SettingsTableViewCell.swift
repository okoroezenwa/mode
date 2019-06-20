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
    @IBOutlet var itemSwitch: MELSwitchContainer!
    @IBOutlet var borderViews: [MELBorderView]!
    @IBOutlet var accessoryButton: MELButton!
    @IBOutlet var buttonBorderView: MELBorderView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var leadingImageView: MELImageView!
    @IBOutlet var leadingImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var labelsStackView: UIStackView!
    @IBOutlet var leadingImageViewLeadingConstraint: NSLayoutConstraint!
    
    enum Context { case setting, alert(cancel: Bool) }
    
    weak var delegate: SettingsCellDelegate?
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        selectedBackgroundView = MELBorderView()
        
        preservesSuperviewLayoutMargins = false
        contentView.preservesSuperviewLayoutMargins = false
        
        updateSpacing()
        
        notifier.addObserver(self, selector: #selector(updateSpacing), name: .lineHeightsCalculated, object: nil)
    }
    
    @objc func updateSpacing() {
        
        stackView.spacing = FontManager.shared.cellSpacing
        stackView.layoutMargins.bottom = FontManager.shared.cellInset
        stackView.layoutMargins.top = FontManager.shared.cellInset
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)
        
        borderViews.forEach({ $0.alphaOverride = selected ? 0.05 : 0 })
        buttonBorderView.alphaOverride = selected ? 0.05 : 0
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        
        super.setHighlighted(highlighted, animated: animated)
        
        borderViews.forEach({ $0.alphaOverride = highlighted ? 0.05 : 0 })
        buttonBorderView.alphaOverride = highlighted ? 0.05 : 0
    }
    
    override func addSubview(_ view: UIView) {
        
        if view.className.contains("ReorderControl") {
            
            view.subviews.forEach({ $0.removeFromSuperview() })
            
            let imageView = MELImageView.init(image: #imageLiteral(resourceName: "ReorderControl"))
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view.centre(imageView, withOffsets: .init(x: 0, y: 1))
        }
        
        super.addSubview(view)
    }
    
    @IBAction func accessoryButtonTapped(_ sender: UIButton) {
        
        delegate?.accessoryButtonTapped(in: self)
    }
    
    func prepare(with setting: Setting, animated: Bool = false, context: Context = .setting, alignment: NSTextAlignment = .left) {
        
        titleLabel.text = setting.title
        titleLabel.textAlignment = alignment
        subtitleLabel.text = setting.subtitle
        subtitleLabel.isHidden = setting.subtitle == nil
        tertiaryLabel.text = setting.tertiaryDetail
        tertiaryLabel.superview?.isHidden = setting.tertiaryDetail == nil
        leadingImageView.image = setting.image
        leadingImageView.superview?.isHidden = setting.image == nil
        chevron.superview?.isHidden = {
            
            if case .chevron = setting.accessoryType {
                
                return false
            }
            
            return true
        }()
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
//        borderViews.forEach({ $0.isHidden = setting.accessoryType != .none })
        
        accessoryButton.superview?.isHidden = {
            
            if case .button = setting.accessoryType {
                
                return false
            }
            
            return true
        }()
        
        switch setting.accessoryType {
            
            case .button(let type, let bordered):
            
                switch type {
                    
                    case .image(let image):
                        
                        accessoryButton.setImage(image, for: .normal)
                        accessoryButton.setTitle(nil, for: .normal)
                    
                    case .text(let text):
                    
                        accessoryButton.setImage(nil, for: .normal)
                        accessoryButton.setTitle(text, for: .normal)
                }
            
                buttonBorderView.isHidden = bordered.inverted
            
            default: break
        }
        
        switch context {
            
            case .setting:
            
                if titleLabel.textStyle != TextStyle.body.rawValue {
                    
                    titleLabel.textStyle = TextStyle.body.rawValue
                }
            
                titleLabel.fontWeight = FontWeight.regular.rawValue
                labelsStackView.layoutMargins.left = 10
                leadingImageViewLeadingConstraint.constant = 10
                leadingImageViewWidthConstraint.constant = 17
            
            case .alert(let cancel):
            
                if titleLabel.textStyle != TextStyle.alert.rawValue {
                    
                    titleLabel.textStyle = TextStyle.alert.rawValue
                }
            
                titleLabel.fontWeight = (cancel ? .semibold : FontWeight.regular).rawValue
                labelsStackView.layoutMargins.left = cancel ? 0 : 16
                leadingImageViewLeadingConstraint.constant = 16
                leadingImageViewWidthConstraint.constant = 22
        }
        
        titleLabel.lightOverride = setting.inactive()
        subtitleLabel.lightOverride = setting.inactive()
        tertiaryLabel.lightOverride = setting.inactive()
        chevron.lightOverride = setting.inactive()
        check.lightOverride = setting.inactive()
        itemSwitch.isUserInteractionEnabled = setting.inactive().inverted
    }
}

protocol SettingsCellDelegate: class {
    
    func accessoryButtonTapped(in cell: SettingsTableViewCell)
}

struct Setting {
    
    let title: String
    let subtitle: String?
    let tertiaryDetail: String?
    let accessoryType: Setting.AccessoryType
    let image: UIImage?
    let inactive: (() -> Bool)
    
    enum AccessoryType: Equatable {
        
        enum ButtonType { case image(UIImage), text(String) }
        
        case none, chevron, button(type: ButtonType, bordered: Bool), check(() -> (Bool)), onOff(isOn: () -> (Bool), action: (() -> ()))
        
        static func ==(lhs: AccessoryType, rhs: AccessoryType) -> Bool {
            
            switch lhs {
                
            case .none: if case .none = rhs { return true } else { return false }
                
                case .chevron: if case .chevron = rhs { return true } else { return false }
                
                case .button(type: let type, bordered: let bordered):
                    
                    if case .button(let otherType, let isAlsoBordered) = rhs {
                        
                        var bool: Bool {
                            
                            switch (type, otherType) {
                                
                                case (.image(let image), .image(let otherImage)): return image == otherImage
                                
                                case (.text(let text), .text(let otherText)): return text == otherText
                                
                                default: return false
                            }
                        }
                        
                        return bool && bordered == isAlsoBordered
                        
                    } else { return false }
                
                case .check(let bool): if case .check(let otherBool) = rhs { return bool() == otherBool() } else { return false }
                
                case .onOff: if case .onOff = rhs { return true } else { return false }
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
