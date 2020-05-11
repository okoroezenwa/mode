//
//  Fonts + Extensions.swift
//  Mode
//
//  Created by Ezenwa Okoro on 04/02/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias LineHeights = [TextStyle: CGFloat]

extension UIFont {
    
    class func name(for font: Font, of weight: FontWeight) -> String {
        
        switch font {
            
            case .system: return ""
            
            case .avenirNext:
            
                switch weight {
                    
                    case .light: return "AvenirNext-Regular"
                    
                    case .regular: return "AvenirNext-Medium"
                    
                    case .semibold: return "AvenirNext-DemiBold"
                    
                    case .bold: return "AvenirNext-Bold"
                    
                    case .black: return "AvenirNext-Heavy"
                }
            
            case .myriadPro:
            
                switch weight {
                    
                    case .light: return "MyriadPro-Light"
                    
                    case .regular: return "MyriadPro-Regular"
                    
                    case .semibold: return "MyriadPro-SemiBold"
                    
                    case .bold: return "MyriadPro-Bold"
                    
                    case .black: return "MyriadPro-Black"
                }
            
            case .museoSansRounded:
            
                switch weight {
                    
                    case .light: return "MuseoSansRounded-300"
                    
                    case .regular: return "MuseoSansRounded-500"
                    
                    case .semibold: return "MuseoSansRounded-700"
                    
                    case .bold: return "MuseoSansRounded-900"
                    
                    case .black: return "MuseoSansRounded-1000"
                }
        }
    }
    
    class func specificFont(from font: Font, weight: FontWeight, size: CGFloat) -> UIFont {
        
        switch font {
            
            case .system: return .systemFont(ofSize: size, weight: weight.systemWeight)
            
            default: return UIFont(name: name(for: font, of: weight), size: size) ?? .systemFont(ofSize: size, weight: weight.systemWeight)
        }
    }
    
    class func font(ofWeight weight: FontWeight, size: CGFloat) -> UIFont {
            
        return specificFont(from: activeFont, weight: weight, size: size)
    }
    
    class func myriadPro(ofWeight weight: FontWeight, size: CGFloat) -> UIFont {
        
        return UIFont(name: name(for: .myriadPro, of: weight), size: size) ?? UIFont.systemFont(ofSize: size, weight: weight.systemWeight)
    }
    
    class func avenir(ofWeight weight: FontWeight, size: CGFloat) -> UIFont {
        
        return UIFont(name: name(for: .avenirNext, of: weight), size: size) ?? UIFont.systemFont(ofSize: size, weight: weight.systemWeight)
    }
}

class FontManager: NSObject {
    
    @objc static let shared = FontManager()
    
    lazy var entityCellHeight = self.cellHeight
    lazy var heightsDictionary = self.styleHeights
    lazy var collectionViewCellConstant = self.collectionCellConstant
    lazy var settingCellHeight = self.settingHeight(for: .body)
    lazy var alertCellHeight = self.settingHeight(for: .body)
    
    private override init() {
        
        super.init()
        
        notifier.addObserver(self, selector: #selector(updateConstants), name: .activeFontChanged, object: nil)
    }
    
    @objc func updateConstants() {
        
        heightsDictionary = styleHeights
        entityCellHeight = cellHeight
        collectionViewCellConstant = collectionCellConstant
        settingCellHeight = settingHeight(for: .body)
        alertCellHeight = settingHeight(for: .body)
        
        notifier.post(name: .lineHeightsCalculated, object: nil)
    }
}

extension FontManager {
    
    var styleHeights: LineHeights {
        
        return TextStyle.allCases.reduce(LineHeights(), {
            
            var dictionary = $0
            dictionary[$1] = height(for: $1)
            
            return dictionary
        })
    }
    
    var cellSpacing: CGFloat {
        
        switch activeFont {
            
            case .myriadPro: return 5
            
            case .system: return 3
            
            case .avenirNext: return 0
            
            case .museoSansRounded: return 0
        }
    }
    
    var cellConstant: CGFloat {
        
        switch activeFont {
            
            case .myriadPro: return 1
            
            case .system: return 3
            
            case .avenirNext: return 6
            
            case .museoSansRounded: return 6
        }
    }
    
    var cellInset: CGFloat {
        
        switch activeFont {
            
            case .myriadPro: return 8
            
            case .system: return 5
            
            case .avenirNext: return 4
            
            case .museoSansRounded: return 6
        }
    }
    
    var cellHeight: CGFloat {
        
        let heights = [TextStyle.body, TextStyle.secondary, TextStyle.secondary].reduce(0, { $0 + (heightsDictionary[$1] ?? 0) })
            
        return heights + (2 * cellSpacing) + (2 * cellInset) + cellConstant
    }
    
    func settingHeight(for mainStyle: TextStyle) -> CGFloat {
        
        let heights = [mainStyle, TextStyle.secondary].reduce(0, { $0 + (heightsDictionary[$1] ?? 0) })
        
        return heights + cellSpacing + (2 * cellInset) + cellConstant
    }
    
    var sectionHeaderSpacing: CGFloat {
        
        switch activeFont {
            
            case .myriadPro: return 20 + 4
            
            case .system: return 18 + 4
            
            case .avenirNext: return 20
            
            case .museoSansRounded: return 20
        }
    }
    
    var collectionCellConstant: CGFloat {
        
        let heights = [TextStyle.body, TextStyle.secondary].reduce(0, { $0 + (heightsDictionary[$1] ?? 0) })
        
        return heights + (2 * cellSpacing) - (activeFont == .myriadPro ? 2 : 0) + 3
    }
    
    var buttonInset: CGFloat {
        
        switch activeFont {
            
            case .myriadPro: return 2
            
            case .system: return 0
            
            case .avenirNext: return 1
            
            case .museoSansRounded: return 1
        }
    }
    
    var navigationBarSpacing: CGFloat {
        
        switch activeFont {
            
            case .myriadPro: return 10
            
            case .system: return 8
            
            case .avenirNext: return 6
            
            case .museoSansRounded: return 6
        }
    }
    
    var backLabelHeight: CGFloat { return ceil(max(16, FontManager.shared.heightsDictionary[.prompt] ?? 0)) }
    
    var textLineHeight: CGFloat {
        
        switch activeFont {
            
            case .myriadPro: return 1.15
            
            case .system: return 1.08
            
            case .avenirNext: return 1
            
            case .museoSansRounded: return 1
        }
    }
    
    var descriptionConstant: CGFloat {
        
        switch activeFont {
            
            case .myriadPro: return 0
            
            case .system: return 4
            
            case .avenirNext: return 2
            
            case .museoSansRounded: return 2
        }
    }
    
    var navigationBarTopConstant: CGFloat {
        
        switch activeFont {
            
            case .myriadPro: return 0
            
            case .system: return 2
            
            case .avenirNext: return 3
            
            case .museoSansRounded: return 3
        }
    }
    
    func height(for style: TextStyle) -> CGFloat {
        
        return ceil(("y" as NSString).boundingRect(with: .init(width: 100, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.font(ofWeight: .regular, size: style.textSize())], context: nil).height)
    }
}
