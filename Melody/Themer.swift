//
//  File.swift
//  Melody
//
//  Created by Ezenwa Okoro on 26/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import Foundation

class Themer {
    
    enum TextKind { case title, subtitle }
    enum Mode { case light, dark }
    
    static let shared = Themer()
    var timer: Timer?
    
    private init() {
    
        [Notification.Name.brightnessConstraintChanged, .timeConstraintChanged, .toTimeConstraintChanged, .fromTimeConstraintChanged, .brightnessValueChanged, .anyConditionChanged].forEach({ notifier.addObserver(self, selector: #selector(updateTheme), name: $0, object: nil) })
    }
    
    func darkThemeExpected(basedOn theme: Theme) -> Bool {
        
        if #available(iOS 13, *), theme == .system, let style = appDelegate.window?.rootViewController?.traitCollection.userInterfaceStyle {

            return style == .dark

        } else {

            return theme == .dark
        }
    }
    
    @objc func updateTheme() {
        
        guard !manualNightMode, (brightnessConstraintEnabled || timeConstraintEnabled) else { return }
        
        if (darkTheme && Themer.canSwitchTo(.light)) || (!darkTheme && Themer.canSwitchTo(.dark)) {
            
            prefs.set(!darkTheme, forKey: .darkTheme)
            
            if let view = appDelegate.window?.rootViewController?.view {
                
                UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: { notifier.post(name: .themeChanged, object: nil) }, completion: nil)
            }
        }
    }
    
    func changeTheme(to theme: Theme, changePreference: Bool) {
        
        if changePreference {
                
            prefs.set(theme.rawValue, forKey: .theme)
//            prefs.set(!darkTheme, forKey: .manualNightMode)
//            prefs.set(!darkTheme, forKey: .darkTheme)
        }
        
        let icon = Icon.iconName(type: iconType, width: iconLineWidth, theme: iconTheme).rawValue.nilIfEmpty
        
        if #available(iOS 10.3, *), UIApplication.shared.supportsAlternateIcons, iconTheme == .match, icon != UIApplication.shared.alternateIconName {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { UIApplication.shared.setAlternateIconName(icon, completionHandler: { error in if let error = error { print(error) } }) })
        }
        
        if let view = appDelegate.window?.rootViewController?.view {
            
            UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: { notifier.post(name: .themeChanged, object: nil) }, completion: nil)
        }
    }
    
    static func textColour(for kind: TextKind) -> UIColor {
        
        switch kind {
            
            case .title: return darkTheme ? .white : .black
            
            case .subtitle: return darkTheme ? UIColor.white.withAlphaComponent(0.6) : UIColor.black.withAlphaComponent(0.6)
        }
    }
    
    static func reversedTextColour(for kind: TextKind) -> UIColor {
        
        switch kind {
            
            case .title: return !darkTheme ? .white : .black
                
            case .subtitle: return !darkTheme ? UIColor.white.withAlphaComponent(0.6) : UIColor.black.withAlphaComponent(0.6)
        }
    }
    
    static func greyThemeColour() -> UIColor {
    
        return darkTheme ? .lightGray : .darkGray
    }
    
    static func themeColour(reversed: Bool = false, alpha: CGFloat = 1) -> UIColor {
        
        return (reversed ? (!darkTheme ? UIColor.white : .black) : (darkTheme ? .white : .black)).withAlphaComponent(alpha)
    }
    
    static var vibrancyContainingBackground: UIColor {
        
        return darkTheme ? UIColor.white.withAlphaComponent(0.3) : UIColor.white.withAlphaComponent(0.2)
    }
    
    static var vibrancyContainingEffect: UIBlurEffect {
        
        return .init(style: darkTheme ? .dark : UIDevice.current.isBlurAvailable ? .light : .extraLight)
    }
    
    static var vibrancyEffect: UIVibrancyEffect {
        
        return .init(blurEffect: Themer.vibrancyContainingEffect)
    }
    
    static func borderViewColor(withAlphaOverride alphaOverride: CGFloat = 0) -> UIColor {
        
        return (darkTheme ? UIColor.white : .black).withAlphaComponent(alphaOverride + (useLighterBorders ? 0.05 : 0.08))
    }
    
    static func reversedBorderViewColor(withAlphaOverride alphaOverride: CGFloat = 0) -> UIColor {
        
        return (darkTheme ? UIColor.black : .white).withAlphaComponent(alphaOverride + (useLighterBorders ? 0.05 : 0.08))
    }
    
    static var tempActiveColours: UIColor { darkTheme ? .white : .black }
    
    static var tempInactiveColours: UIColor { (darkTheme ? UIColor.white : .black).withAlphaComponent(0.3) }
    
    static var reversedTempActiveColours: UIColor { darkTheme ? .black : .white }
    
    static var reversedTempInactiveColours: UIColor { (darkTheme ? UIColor.black : .white).withAlphaComponent(0.3) }
}

extension Themer {
    
    static func brightnessConditionMet(for mode: Mode) -> Bool {
        
        return mode == .light ? CGFloat(brightnessValue) > UIScreen.main.brightness : CGFloat(brightnessValue) <= UIScreen.main.brightness
    }
    
    static func timeConditionMet(for mode: Mode) -> Bool {
        
        let currentComponents = Settings.components(from: .init())
        
        if fromHourComponent < toHourComponent {
            
            return mode == .light ? currentComponents.hour >= toHourComponent : currentComponents.hour >= fromHourComponent
            
        } else if fromHourComponent > toHourComponent {
            
            switch mode {
                
            case .light: return currentComponents.hour >= toHourComponent && currentComponents.hour < fromHourComponent
                
            case .dark: return currentComponents.hour >= fromHourComponent || currentComponents.hour < toHourComponent
            }
            
        } else {
            
            if fromMinuteComponent < toMinuteComponent {
                
                return mode == .light ? currentComponents.minute >= toMinuteComponent : currentComponents.minute >= fromMinuteComponent
                
            } else if fromMinuteComponent > toMinuteComponent {
                
                switch mode {
                    
                case .light: return currentComponents.minute >= toMinuteComponent && currentComponents.minute < fromMinuteComponent
                    
                case .dark: return currentComponents.hour >= fromHourComponent || currentComponents.hour < toHourComponent
                }
                
            }
        }
        
        return false
    }
    
    static func canSwitchTo(_ mode: Mode) -> Bool {
        
        switch mode {
            
            case .light:
                
                switch (brightnessConstraintEnabled, timeConstraintEnabled) {
                    
                    case (true, true): return anyConditionActive ? !brightnessConditionMet(for: .light) && !timeConditionMet(for: .light) : brightnessConditionMet(for: .light) || timeConditionMet(for: .light)
                    
                    case (true, false): return brightnessConditionMet(for: .light)
                    
                    case (false, true): return timeConditionMet(for: .light)
                    
                    case (false, false): return false
                }
            
            case .dark:
                
                switch (brightnessConstraintEnabled, timeConstraintEnabled) {
                    
                    case (true, true): return anyConditionActive ? brightnessConditionMet(for: .dark) || timeConditionMet(for: .dark) : brightnessConditionMet(for: .dark) && timeConditionMet(for: .dark)
                        
                    case (true, false): return brightnessConditionMet(for: .dark)
                        
                    case (false, true): return timeConditionMet(for: .dark)
                        
                    case (false, false): return true
                }
        }
    }
}
