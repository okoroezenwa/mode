//
//  Formatter.swift
//  Melody
//
//  Created by Ezenwa Okoro on 13/10/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class Formatter {
    
    private init() {}
    
    static let shared = Formatter.init()

    @objc let numberFormatter: NumberFormatter = {
        
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .decimal
        
        return formatter
    }()
    
    @objc let dateFormatter: DateFormatter = {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter
    }()
    
    @objc let timeHourFormatter: DateComponentsFormatter = {
        
        let formatter = DateComponentsFormatter()
        
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        return formatter
    }()
    
    @objc let timeMinuteFormatter: DateComponentsFormatter = {
        
        let formatter = DateComponentsFormatter()
        
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        return formatter
    }()
}
