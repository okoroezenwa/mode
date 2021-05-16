//
//  MPMediaItem+Extensions.swift
//  Melody
//
//  Created by Ezenwa Okoro on 21/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

extension MPMediaItem {
    
    @objc var year: Int {
        
        return (self.value(forProperty: .year) as? NSNumber)?.intValue ?? releaseDate?.year() ?? -1
    }
    
    var likedState: LikedState {
        
        if let liked = value(forProperty: .likedState) as? Int {
            
            switch liked {
                
                case 2: return .liked
                    
                case 3: return .disliked
                    
                default: return .none
            }
            
        } else {
            
            return .none
        }
    }
    
    @objc var isExplicit: Bool {
        
        if #available(iOS 10, *) {
            
            return isExplicitItem
            
        } else {
            
            return value(forProperty: .isExplicit) as? Bool ?? false
        }
    }
    
    @objc var copyright: String? { return value(forProperty: .copyright) as? String }
    @objc var fileSize: Int64 { return value(forProperty: .fileSize) as? Int64 ?? 0 }
    @objc var isPlayable: Bool { return (value(forProperty: .isPlayable) as? NSNumber)?.boolValue ?? false }
    
    @objc var validDateAdded: Date {
        
        return value(forProperty: .dateAdded) as? Date ?? .distantFuture
    }
    
    @objc public var validTitle: String { return title ??? .untitledSong }
    @objc var sortTitle: String { return validTitle.diacritic }
    @objc public var validArtist: String { return artist ??? .unknownArtist }
    @objc var sortArtist: String { return validArtist.diacritic }
    @objc var validAlbumArtist: String { return albumArtist ??? (isCompilation ? "Various Artists" : .unknownArtist) }
    @objc var sortAlbumArtist: String { return validAlbumArtist.diacritic }
    @objc var validAlbum: String { return albumTitle ??? .untitledAlbum }
    @objc var sortAlbum: String { return validAlbum.diacritic }
    @objc var validGenre: String { return genre ??? .untitledGenre }
    @objc var sortGenre: String { return validGenre.diacritic }
    @objc var validComposer: String { return composer ??? .unknownComposer }
    @objc var sortComposer: String { return validComposer.diacritic }
    @objc var validLastPlayed: Date { return lastPlayedDate ?? .distantPast }
    @objc var validLyrics: String { return lyrics ??? "" }
    
    @objc var existsInLibrary: Bool {
        
        let selString = NSString.init(format: "%@%@%@", "exis", "tsInLi", "brary")
        let sel = NSSelectorFromString(selString as String)
        
        if responds(to: sel), let songExists = value(forKey: "existsInLibrary") as? Bool {
            
            return songExists
            
        } else {
            
            guard MPMediaQuery.init(filterPredicates: [.for(.song, using: self)]).items?.isEmpty != true else {
                
                return false
            }
            
            return true
        }
    }
    
    @objc var lastSkippedDate: Date? { return value(forProperty: "lastSkippedDate") as? Date }
    
    @objc var storeID: String {
        
        if #available(iOS 10.3, *) {
            
            return playbackStoreID
            
        } else {
            
            return ""
        }
    }
    
    @objc func dateAddedCompare(to second: MPMediaItem) -> ComparisonResult {
        
        return validDateAdded.compare(second.validDateAdded)
    }
    
    @objc func lastPlayedCompare(to second: MPMediaItem) -> ComparisonResult {
        
        return (lastPlayedDate ?? Date.init()).compare(second.lastPlayedDate ?? Date.init())
    }
    
    @objc var actualArtwork: MPMediaItemArtwork? {
        
        if let artwork = artwork, artwork.bounds.width != 0 {
            
            return artwork
        }
        
        return nil
    }
    
    var canBeAddedToLibrary: Bool { existsInLibrary.inverted && isPlayable }
}

extension MPMediaItem: Settable { }
