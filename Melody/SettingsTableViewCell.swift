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
    @IBOutlet var checkMirrorView: UIView!
    @IBOutlet var itemSwitch: MELSwitchContainer!
    @IBOutlet var accessoryButton: MELButton!
    @IBOutlet var buttonBorderView: MELBorderView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var leadingImageView: MELImageView!
    @IBOutlet var leadingImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var labelsStackView: UIStackView!
    @IBOutlet var leadingImageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var topBorderView: MELBorderView!
    @IBOutlet var bottomBorderView: MELBorderView!
    
    enum Context: Equatable {
        
        case setting, alert(UIAlertAction.Style)
    }
    
    weak var delegate: SettingsCellDelegate?
    var borderViews: [MELBorderView] { return [topBorderView, bottomBorderView] }
    
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
    
    func prepare(with setting: Setting, animated: Bool = false, context: Context = .setting) {
        
        let isAlert: Bool = {
            
            if case .alert = context { return true }
            
            return false
        }()
        
        titleLabel.text = setting.title
        
        let preferredAlignment: NSTextAlignment = {
            
            if case .alert = context, setting.image == nil, setting.subtitle == nil {
                
                return .center
            }
            
            return setting.textAlignment
        }()
        
        titleLabel.textAlignment = preferredAlignment
        subtitleLabel.text = setting.subtitle
        subtitleLabel.isHidden = setting.subtitle == nil
        tertiaryLabel.text = setting.tertiaryDetail
        tertiaryLabel.superview?.isHidden = isAlert || setting.tertiaryDetail == nil
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
        
        checkMirrorView.isHidden = {
        
            if case .check = setting.accessoryType, preferredAlignment == .center {
                
                return false
            }
            
            return true
        }()
        
        topBorderView.isHidden = isAlert || Set([Setting.BorderVisibility.bottom, .none]).contains(setting.borderVisibility)
        bottomBorderView.isHidden = isAlert || Set([Setting.BorderVisibility.top, .none]).contains(setting.borderVisibility)
        
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
                
                labelsStackView.layoutMargins.right = {
                    
                    if setting.accessoryType == .none, setting.tertiaryDetail == nil {
                        
                        return 10
                        
                    } else {
                        
                        return 0
                    }
                }()
                
                leadingImageViewLeadingConstraint.constant = 10
                leadingImageViewWidthConstraint.constant = 17
            
            case .alert(let type):
            
                if titleLabel.textStyle != TextStyle.alert.rawValue {
                    
                    titleLabel.textStyle = TextStyle.alert.rawValue
                }
            
                titleLabel.colorOverride = type == .destructive ? .red : nil
                titleLabel.fontWeight = (type == .cancel ? .semibold : FontWeight.regular).rawValue
                labelsStackView.layoutMargins.left = type == .cancel || setting.image == nil ? 0 : 16
                leadingImageViewLeadingConstraint.constant = 16
                leadingImageViewWidthConstraint.constant = 22
        }
        
        setInactiveIfNecessary(setting)
    }
    
    func setInactiveIfNecessary(_ setting: Setting) {
        
        titleLabel.lightOverride = setting.inactive()
        subtitleLabel.lightOverride = setting.inactive()
        tertiaryLabel.lightOverride = setting.inactive()
        chevron.lightOverride = setting.inactive()
        check.lightOverride = setting.inactive()
        itemSwitch.isUserInteractionEnabled = setting.inactive().inverted
    }
    
    func prepare(with action: AlertAction) {
        
        prepare(with: action.info, animated: false, context: action.context)
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
    let textAlignment: NSTextAlignment
    let borderVisibility: BorderVisibility
    
    enum BorderVisibility { case none, top, bottom, both }
    
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
    
    init(title: String, subtitle: String? = nil, image: UIImage? = nil, tertiaryDetail: String? = nil, accessoryType: AccessoryType, textAlignment alignment: NSTextAlignment = .left, borderVisibility: BorderVisibility = .none, inactive inactiveCondition: @escaping (() -> Bool) = { false }) {
        
        self.title = title
        self.subtitle = subtitle
        self.tertiaryDetail = tertiaryDetail
        self.image = image
        self.accessoryType = accessoryType
        self.inactive = inactiveCondition
        self.textAlignment = alignment
        self.borderVisibility = borderVisibility
    }
}

typealias AlertInfo = Setting

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

struct AlertAction {
    
    enum AlertStyle { case `default`, destructive, cancel }
    
    let info: AlertInfo
    let context: SettingsTableViewCell.Context
    let requiresDismissalFirst: Bool
    let handler: (() -> ())?
    let accessoryAction: ((MELButton, UIViewController) -> ())?
    let previewAction: ((UIViewController) -> UIViewController?)?
    
    init(info: AlertInfo, context: SettingsTableViewCell.Context = .alert(.default), requiresDismissalFirst: Bool = false, handler: (() -> ())?, accessoryAction: ((MELButton, UIViewController) -> ())? = nil, previewAction: ((UIViewController) -> UIViewController?)? = nil) {
        
        self.info = info
        self.context = context
        self.requiresDismissalFirst = requiresDismissalFirst
        self.handler = handler
        self.accessoryAction = accessoryAction
        self.previewAction = previewAction
    }
    
    init(title: String, style: UIAlertAction.Style = .default, accessoryType type: Setting.AccessoryType = .none, requiresDismissalFirst: Bool = false, handler: (() -> ())?, accessoryAction: ((MELButton, UIViewController) -> ())? = nil, previewAction: ((UIViewController) -> UIViewController?)? = nil) {
        
        self.info = AlertInfo.init(title: title, accessoryType: type)
        self.context = .alert(style)
        self.requiresDismissalFirst = requiresDismissalFirst
        self.handler = handler
        self.accessoryAction = accessoryAction
        self.previewAction = previewAction
    }
}

extension AlertAction {
    
    static var stop = AlertAction.init(info: AlertInfo.init(title: "Stop Playback", accessoryType: .none, textAlignment: .center), context: .alert(.destructive), handler: NowPlaying.shared.stopPlayback)
}
