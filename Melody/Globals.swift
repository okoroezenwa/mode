//
//  Globals.swift
//  Melody
//
//  Created by Ezenwa Okoro on 01/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

// MARK: - Storyboards

let presentedStoryboard = UIStoryboard(name: "Presented", bundle: nil)
let entityStoryboard = UIStoryboard(name: "EntityChildren", bundle: nil)
let popoverStoryboard = UIStoryboard(name: "Popovers", bundle: nil)
let settingsStoryboard = UIStoryboard(name: "Settings", bundle: nil)
let tipsStoryboard = UIStoryboard(name: "Tips", bundle: nil)
let nowPlayingStoryboard = UIStoryboard(name: "NowPlaying", bundle: nil)
let presentedChilrenStoryboard = UIStoryboard(name: "PresentedChildren", bundle: nil)
let mainChildrenStoryboard = UIStoryboard(name: "MainChildren", bundle: nil)
let libraryChildrenStoryboard = UIStoryboard(name: "LibraryChildren", bundle: nil)

// MARK: - Miscellaneous

let screenSize = UIScreen.main.bounds
let screenHeight = screenSize.height
let screenWidth = screenSize.width
let prefs = UserDefaults.standard
let notifier = NotificationCenter.default
var useAlternateAnimation = false
var shouldReturnToContainer = false
//var ignoreArtwork
var disregardBrightnessNotification = false
var isInDebugMode: Bool { return Settings.isInDebugMode }
var isSmallScreen: Bool { return /*traitCollection.verticalSizeClass == .compact &&*/ screenHeight / screenWidth < 1.6 }
var isiPhoneX: Bool { return UIApplication.shared.statusBarFrame.height.truncatingRemainder(dividingBy: 20) != 0 }
var albumArtistsAvailable: Bool { return MPMediaQuery.responds(to: NSSelectorFromString("albumArtistsQuery")) }
var topViewController: UIViewController? { return topVC(startingFrom: appDelegate.window?.rootViewController) }
var modalIndex: CGFloat = 0
var collapsedPlaylists: Set<Int64> = []

func offline(considering overridable: OnlineOverridable?) -> Bool {
    
    guard let overridable = overridable else { return !showiCloudItems }
    
    return !showiCloudItems && !overridable.onlineOverride
}

func online(considering overridable: OnlineOverridable?) -> Bool {
    
    guard let overridable = overridable else { return showiCloudItems }
    
    return showiCloudItems || overridable.onlineOverride
}

func topVC(startingFrom vc: UIViewController? = topViewController) -> UIViewController? {
    
    if let presented = vc?.presentedViewController {
        
        return topVC(startingFrom: presented)
        
    } else {
        
        return vc
    }
}

func basePresentedOrNowPlayingViewController(from topVC: UIViewController?) -> UIViewController? {
    
    var vc = topVC
    
    while vc?.presentingViewController != nil && !(vc is NowPlayingViewController) {
        
        vc = vc?.presentingViewController
    }
    
    return vc
}
