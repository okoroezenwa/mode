//
//  SharedGlobals.swift
//  Mode
//
//  Created by Ezenwa Okoro on 07/09/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

let sharedDefaults = UserDefaults.init(suiteName: "group.okoroezenwa.modeplayer")!
var sharedUseSystemPlayer: Bool { return sharedDefaults.bool(forKey: .systemPlayer) }
var sharedUseLighterBorders: Bool { return sharedDefaults.bool(forKey: .lighterBorders) }
var sharedCornerRadius: Int { return sharedDefaults.integer(forKey: .cornerRadius) }
var sharedWidgetCornerRadius: Int { return sharedDefaults.integer(forKey: .widgetCornerRadius) }

enum ModeBuild: String {
    
    case dev = "com.okoroezenwa.modeplayer.dev"
    
    case stable = "com.okoroezenwa.modeplayer.stable"
    
    case release = "com.okoroezenwa.ModePlayer"
}
