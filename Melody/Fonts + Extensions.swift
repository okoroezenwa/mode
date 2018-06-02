//
//  Fonts + Extensions.swift
//  Mode
//
//  Created by Ezenwa Okoro on 04/02/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

extension UIFont {
    
    enum MyriadProWeigths: String {
        
        case light = "MyriadPro-Light"
        case lightItalic = "MyriadPro-LightIt"
        case regular = "MyriadPro-Regular"
        case regularItalic = "MyriadPro-It"
        case bold = "MyriadPro-Semibold"
        case boldItalic = "MyriadPro-SemiboldIt"
    }
    
    enum AvenirWeigths: String {
        
        case light = "AvenirNext-UltraLight"
        case lightItalic = "AvenirNext-UltraLightItalic"
        case regular = "AvenirNext-Regular"
        case regularItalic = "AvenirNext-Italic"
        case bold = "AvenirNext-DemiBold"
        case boldItalic = "AvenirNext-DemiBoldItalic"
    }
    
    enum SFWeigths: String {
        
        case light = "AvenirNext-UltraLight"
        case lightItalic = "AvenirNext-UltraLightItalic"
        case regular = "AvenirNext-Regular"
        case regularItalic = "AvenirNext-Italic"
        case bold = "AvenirNext-DemiBold"
        case boldItalic = "AvenirNext-DemiBoldItalic"
    }
    
    enum FontWeight: String {
        
        case light = "MyriadPro-Light"
        case lightItalic = "MyriadPro-LightIt"
        case regular = "MyriadPro-Regular"
        case regularItalic = "MyriadPro-It"
        case bold = "MyriadPro-Semibold"
        case boldItalic = "MyriadPro-SemiboldIt"
    }
    
    class func myriadPro(ofWeight weight: FontWeight, size: CGFloat) -> UIFont {
        
        return UIFont(name: weight.rawValue, size: size) ?? UIFont.systemFont(ofSize: size)
    }
}
