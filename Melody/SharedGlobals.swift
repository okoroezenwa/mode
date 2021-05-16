//
//  SharedGlobals.swift
//  Mode
//
//  Created by Ezenwa Okoro on 07/09/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

let sharedDefaults: UserDefaults = {
    
    guard let identifier = Bundle.main.bundleIdentifier?.deletingSuffix(".Widget").replacingOccurrences(of: "com.", with: "group.").lowercased() else { return UserDefaults.init(suiteName: "group.okoroezenwa.modeplayer")! }
    
    return UserDefaults.init(suiteName: identifier)!
}()

var sharedUseSystemPlayer: Bool { return sharedDefaults.bool(forKey: .systemPlayer) }
var sharedUseLighterBorders: Bool { return sharedDefaults.bool(forKey: .lighterBorders) }
var sharedCornerRadius: Int { return sharedDefaults.integer(forKey: .cornerRadius) }
var sharedWidgetCornerRadius: Int { return sharedDefaults.integer(forKey: .widgetCornerRadius) }

enum ModeBuild: String {
    
    case dev = "com.okoroezenwa.modeplayer.dev"
    
    case stable = "com.okoroezenwa.modeplayer.stable"
    
    case release = "com.okoroezenwa.ModePlayer"
}

enum EntityArtworkType: Equatable {
    
    enum Size { case small, regular, large, extraLarge }
    enum GranularEntityType { case song, album, compilation, artist, albumArtist, genre, composer, playlist, smartPlaylist, geniusPlaylist }
    
    case empty(entityType: GranularEntityType, size: Size), image(UIImage?)
    
    func artwork(darkTheme: Bool) -> UIImage? {
        
        switch self {
            
            case .image(let image): return image
            
            case .empty(entityType: let type, size: let size):
                
                let suffix: String = {
                    
                    switch size {
                        
                        case .small: return "30"
                        
                        case .regular: return "75"
                        
                        case .large: return "300"
                        
                        case .extraLarge: return "900"
                    }
                }()
                
                let prefix: String = {
                    
                    switch type {
                        
                        case .albumArtist, .artist: return "NoArtist"
                        
                        case .composer: return "NoComposer"
                        
                        case .song: return "NoSong"
                        
                        case .album: return "NoAlbum"
                        
                        case .compilation: return "NoCompilation"
                        
                        case .playlist: return "NoPlaylist"
                        
                        case .smartPlaylist: return "NoSmart"
                        
                        case .geniusPlaylist: return "NoGenius"
                        
                        case .genre: return "NoGenre"
                    }
                }()
            
                let infix = darkTheme ? "Dark" : "Light"
            
            return .init(imageLiteralResourceName: prefix + infix + suffix)
        }
    }
}

protocol EntityArtworkDisplaying: AnyObject {
    
    var artworkType: EntityArtworkType { get set }
}
