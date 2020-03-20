//
//  SharedEnumerations.swift
//  Mode
//
//  Created by Ezenwa Okoro on 06/12/2019.
//  Copyright © 2019 Ezenwa Okoro. All rights reserved.
//

import Foundation

enum Font: Int, CaseIterable {
    
    case system, myriadPro, avenirNext
    
    var name: String {
        
        switch self {
            
            case .system: return "System"
            
            case .myriadPro: return "Myriad Pro"
            
            case .avenirNext: return "Avenir Next"
        }
    }
}

enum FontWeight: Int, CaseIterable {
    
    case light, regular, semibold, bold

    var systemWeight: UIFont.Weight {

        switch self {

            case .light: return .light

            case .regular: return .medium
            
            case .semibold: return .semibold
            
            case .bold: return .bold
        }
    }
}

enum TextStyle: String, CaseIterable {
    
    case heading, subheading, modalHeading, sectionHeading, alert, body, secondary, nowPlayingTitle, nowPlayingSubtitle, infoTitle, infoBody, prompt, tiny, accessory, veryTiny
    
    func textSize() -> CGFloat {
        
        switch self {
            
            case .heading: return 34
            
            case .subheading: return 25
            
            case .modalHeading: return 22
            
            case .sectionHeading: return 22
            
            case .alert: return 20
            
            case .body: return 17
            
            case .secondary: return 14
            
            case .nowPlayingTitle: return 25
            
            case .nowPlayingSubtitle: return 22
            
            case .infoTitle: return 25
            
            case .infoBody: return 20
            
            case .prompt: return 15
            
            case .accessory: return 15
            
            case .tiny: return 12
            
            case .veryTiny: return 10
        }
    }
}
