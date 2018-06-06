//
//  DetectBlur.swift
//
//  Created by Moath_Othman on 2/9/16.
//  Modified for Vote on 15/3/16

import Foundation
//inpired by https://gist.github.com/mortenbekditlevsen/5a0ee16b73a084ba404d

extension UIDevice {
    
    @objc public var isBlurAvailable: Bool {
        
        if UIAccessibilityIsReduceTransparencyEnabled() {
            
            return false
        }
        
        if !self.blurSupported {
            
            return false
        }
        
        #if TARGET_IPHONE_SIMULATOR
        #endif
        return true
    }
    
    @objc public var isCharging: Bool {
        
        switch batteryState {
            
            case .unknown, .unplugged: return false
            
            case .charging, .full: return true
        }
    }
    
    fileprivate var blurSupported: Bool {
        
        let unsupportedDevices: Set<String> = ["iPad",
                                        "iPad1,1",
                                        "iPhone1,1",
                                        "iPhone1,2",
                                        "iPhone2,1",
                                        "iPhone3,1",
                                        "iPhone3,2",
                                        "iPhone3,3",
                                        "iPod1,1",
                                        "iPod2,1",
                                        "iPod2,2",
                                        "iPod3,1",
                                        "iPod4,1",
                                        "iPad2,1",
                                        "iPad2,2",
                                        "iPad2,3",
                                        "iPad2,4",
                                        "iPad3,1",
                                        "iPad3,2",
                                        "iPad3,3"]
        
        return !unsupportedDevices.contains(hardwareString)
    }
    
    // http://stackoverflow.com/a/29997626/979169
    fileprivate var hardwareString: String {
        
        var name: [Int32] = [CTL_HW, HW_MACHINE]
        var size: Int = 2
        var name1 = name
        var name2 = name
        var name3 = name
        var otherSize = size
        sysctl(&name, 2, nil, &size, &name2, 0)
        
        var hw_machine = [CChar](repeating: 0, count: Int(size))
        sysctl(&name1, 2, &hw_machine, &otherSize, &name3, 0)
        
        let hardware: String = String(cString: hw_machine)
        
        return hardware
    }
    
    fileprivate var mo_osMajorVersion: Int {
        
        let vComp: [String] = UIDevice.current.systemVersion.components(separatedBy: ".")
        
        return Int(vComp.first!)!
    }
}
