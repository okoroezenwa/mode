//
//  String + Keys.swift
//  Melody
//
//  Created by Ezenwa Okoro on 23/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import Foundation

infix operator ???
infix operator ?+

public extension String {
    
    // MARK: - Miscellaneous
    static let collectedItems = "collectedItems"
    static let queueItems = "queueItems"
    static let indexOfNowPlayingItem = "indexOfNowPlayingItem"
    static let currentPlaybackTime = "currentPlaybackTime"
    static let musicPlayerController = "controller"
    static let id = "persistentID"
    static let sender = "sender"
    static let repeatMode = "repeatMode"
    static let primarySizeSuffix = "primarySizeSuffix"
    static let secondarySizeSuffix = "secondarySizeSuffix"
    static let modeURL = "modeapp://"
    
    static func shuffle(_ suffix: ShuffleSuffix = .none) -> String {
        
        let string = "Shuffle"
        
        switch suffix {
            
            case .none: return string
            
            case .songs: return string + " Songs"
            
            case .albums: return string + " Albums"
        }
    }

    // MARK: - Unknown Entity Titles
    static let untitledSong = "Untitled Song"
    static let unknownArtist = "Unknown Artist"
    static let untitledAlbum = "Untitled Album"
    static let untitledGenre = "Untitled Genre"
    static let unknownComposer = "Unknown Composer"
    static let untitledPlaylist = "Untitled Playlist"
    static let unknownEntity = "Unknown Entity"
    static let variousArtists = "Various Artists"
    
    // MARK: - Entity Keys
    static let year = "year"
    static let likedState = "likedState"
    static let isExplicit = "isExplicit"
    static let copyright = "copyright"
    static let fileSize = "fileSize"
    static let dateAdded = "dateAdded"
    static let dateCreated = "dateCreated"
    static let isFolder = "isFolder"
    static let isEditable = "isEditable"
    static let albumLikedState = "albumLikedState"
    
    // MARK: - Control Titles
    static let inactiveEditButtonTitle = "Edit"
    static let activeEditButtonTitle = "More..."
    static let shuffleButtonTitle = "Shuffle"
    static let arrangeButtonTitle = "Sort"
    
    // MARK: - Reusable
    static let songCell = "SongCell"
    static let artistCell = "ArtistCell"
    static let playlistCell = "PlaylistCell"
    static let albumCell = "AlbumCell"
    static let otherCell = "otherCell"
    static let recentCell = "RecentCell"
    static let settingsCell = "SettingsCell"
    static let sectionHeader = "TableHeaderView"
    static let sectionFooter = "TableFooterView"
    
    // MARK: - Shared Settings
    static let systemPlayer = "useSystemPlayer"
    static let lighterBorders = "lighterBorders"
    static let quitWidget = "quitWidget"
    static let cornerRadius = "cornerRadiusMode"
    static var widgetCornerRadius = "widgetCornerRadius"
    static var currentFont = "currentFont"
    
    // MARK: - Segues
    static let artistUnwind = "toArtistUnwind"
    static let albumUnwind = "toAlbumUnwind"
    static let albumArtistUnwind = "toAlbumArtistUnwind"
    static let playlistUnwind = "toPlaylistUnwind"
    static let genreUnwind = "toGenreUnwind"
    static let composerUnwind = "toComposerUnwind"
    
    // MARK: Selectors
    static let setValueForProperty = "setValue:forProperty:"
    
    func nsRange(of string: String? = nil) -> NSRange {
        
        return (self as NSString).range(of: string ?? self)
    }
    
    static func ??? (left: String?, right: String) -> String {
        
        return left != nil && left != "" ? left! : right
    }
    
    static func ?+ (left: String?, right: String) -> String {
        
        return left != nil ? left! + right : ""
    }
    
    static func ?+ (left: String, right: String?) -> String {
        
        return right != nil ? left + right! : ""
    }
    
    func disregarding(_ right: String) -> String? {
        
        return self != right ? self : nil
    }
    
    var diacritic: String {
        
        if !CharacterSet.letters.contains(String(self.prefix(1)).unicodeScalars.first!) {
            
            return "µ" + self
            
        } else {
            
            return "i" + self
        }
    }
    
    var folded: String { return self.folding(options: .diacriticInsensitive, locale: nil) }
    
    var nilIfEmpty: String? { return self.isEmpty ? nil : self }
    
    var roundedBracketsRemoved: String {
        
        if let startIndex = index(of: "("), let endIndex = index(of: ")") {
            
            var string = self
            string.removeSubrange(startIndex...endIndex)
            
            return string
        }
        
        return self
    }
    
    var squareBracketsRemoved: String {
        
        if let startIndex = index(of: "["), let endIndex = index(of: "]") {
            
            var string = self
            string.removeSubrange(startIndex...endIndex)
            
            return string
        }
        
        return self
    }
    
    var punctuationRemoved: String {
        
        return replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "'", with: "")
    }
    
    var censoredWordsReplaced: String {
        
        return replacingOccurrences(of: "f**k", with: "fuck").replacingOccurrences(of: "f*ck", with: "fuck").replacingOccurrences(of: "s**t", with: "shit").replacingOccurrences(of: "b*tch", with: "bitch")
    }
}

// MARK: - Enums
public extension String {
    
    enum ShuffleSuffix { case none, songs, albums }
    
    enum URLAction: String {
        
        case nowPlayingInfo = "openNowPlayingInfo"
        case nowPlaying = "openNowPlaying"
        case queue = "openQueue"
    }
}
