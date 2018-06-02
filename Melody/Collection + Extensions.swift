//
//  MPMediaItemCollection + Extensions.swift
//  Melody
//
//  Created by Ezenwa Okoro on 21/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

extension MPMediaPlaylist {
    
    @objc var dateCreated: Date { return value(forProperty: .dateCreated) as? Date ?? Date.distantPast }
    
    @objc var isFolder: Bool { return value(forProperty: .isFolder) as? Bool ?? false }
    
    @objc var isAppleMusic: Bool {
        
        guard /*appDelegate.appleMusicStatus == .appleMusic(libraryAccess: true), */let isUserPlaylist = value(forProperty: .isEditable) as? Bool, playlistAttributes != .onTheGo, responds(to: NSSelectorFromString("isCloudMix")), let isCloudMix = value(forKey: "isCloudMix") as? Bool, isCloudMix else { return false }
        
        return !isUserPlaylist
    }
    
    @objc var validName: String { return name ??? .untitledPlaylist }
    @objc var sortName: String { return validName.diacritic ??? .untitledPlaylist }
    @objc var dateUpdated: Date? { return value(forProperty: "dateModified") as? Date }
    
    var parentPersistentID: Int64 { return value(forProperty: "parentPersistentID") as? Int64 ?? 0 }
    var id: Int64 { return value(forProperty: "persistentID") as? Int64 ?? 0 }
    
    func gatherChildren(from temp: [TempPlaylistContainer], root: MPMediaPlaylist?, index: CGFloat) -> PlaylistContainer? {
        
        let children = temp.first(where: { $0.id == id })?.children.flatMap({ $0.gatherChildren(from: temp, root: root, index: index + 1) }) ?? []
        
        let container = PlaylistContainer.init(playlist: self, children: collapsedPlaylists.contains(id) ? [] : children, actualChildren: children, root: root, index: index)
        
        return container.value(given: container.playlist.isFolder ? container.children.isEmpty.inverted : true)
    }
    
    var type: PlaylistType {
        
        if playlistAttributes == .genius {
            
            return .genius
        
        } else if playlistAttributes == .smart {
            
            return .smart
            
        } else {
            
            if isFolder {
                
                return .folder
                
            } else {
                
                return isAppleMusic ? .appleMusic : .manual
            }
        }
    }
}

extension MPMediaItemCollection {
    
    var likedState: LikedState {
        
        if let liked: Int = {
            
            if let _ = self as? MPMediaPlaylist {
                
                return self.value(forProperty: .likedState) as? Int
            }
            
            return self.value(forProperty: .albumLikedState) as? Int
            
        }() {
            
            switch liked {
                
                case 2: return .liked
                    
                case 3: return .disliked
                    
                default: return .none
            }
            
        } else {
            
            return .none
        }
    }
    
    @objc var totalDuration: TimeInterval { return items.reduce(TimeInterval(0), { $0 + $1.playbackDuration }) }
    @objc var totalPlays: Int { return items.reduce(0, { $0 + $1.playCount }) }
    @objc var totalSkips: Int { return items.reduce(0, { $0 + $1.skipCount }) }
    @objc var totalSize: Int64 { return items.reduce(0, { $0 + $1.fileSize }) }
    @objc var recentlyAdded: Date { return Set(items.map({ $0.validDateAdded })).max() ?? Date.distantFuture }
    @objc var year: Int { return Set(items.map({ $0.year })).filter({ $0 != -1 && $0 != 0 }).max() ?? 0 }
    @objc var albumTitle: String { return representativeItem?.validAlbum ??? .untitledAlbum }
    @objc var sortAlbumTitle: String { return albumTitle.diacritic }
    @objc var albumCount: Int { return Set(items.map({ $0.validAlbum })).count }
    @objc var songCount: Int { return items.count }
    @objc var isCloudItem: Bool { return items.first(where: { $0.isCloudItem }) != nil }
    @objc var artistName: String {
        
        guard representativeItem?.isCompilation == false else { return .variousArtists }
        
        return representativeItem?.validArtist ??? .unknownArtist
    }
    @objc var sortArtistName: String { return artistName.diacritic }
    @objc var genre: String { return Set(items.map({ $0.genre ??? "" })).sorted(by: <).filter({ $0 != "" }).first ??? .untitledGenre }
    @objc var sortGenre: String { return genre.diacritic }
    @objc var albumArtist: String {
        
        return items.first(where: { $0.albumArtist != nil || $0.albumArtist != "" })?.albumArtist ??? .unknownArtist
    }
    
    @objc var averageRating: Int {
        
        let rated = items.filter({ $0.rating > 0 })
        
        guard rated.count > 0 else { return rated.count }
        
        return rated.reduce(0, { $0 + $1.rating }) / rated.count
    }
    
    @objc var customArtwork: UIImage? {
        
        if responds(to: NSSelectorFromString("artworkCatalog")), let catalog = value(forKey: "artworkCatalog") as? NSObject, catalog.responds(to: NSSelectorFromString("bestImageFromDisk")), let image = catalog.value(forKey: "bestImageFromDisk") as? UIImage {
            
            return image
        }
        
        return nil
    }
}

extension MPMediaItemCollection: Settable { }

struct TempPlaylistContainer {
    
    let id: Int64
    let children: [MPMediaPlaylist]
    
    init(id: Int64, children: [MPMediaPlaylist]) {
        
        self.id = id
        self.children = children
    }
}

class PlaylistContainer: Equatable {
    
    var playlist: MPMediaPlaylist
    var children: [PlaylistContainer]
    var actualChildren: [PlaylistContainer]
    var root: MPMediaPlaylist?
    var parent: PlaylistContainer?
    var index: CGFloat
    var isExpanded: Bool
    
    init(playlist: MPMediaPlaylist, children: [PlaylistContainer], actualChildren: [PlaylistContainer], root: MPMediaPlaylist? = nil, index: CGFloat = 0) {
        
        self.playlist = playlist
        self.children = children
        self.root = root
        self.index = index
        self.actualChildren = actualChildren
        self.isExpanded = playlist.parentPersistentID == 0
    }
    
    var reduced: ReducedPlaylist {
        
        return children.reduce(([self], [root ?? playlist], [playlist])) {
            
            let new = $1.reduced
            return ($0.0 + new.containers, $0.1 + new.arrangeable, $0.2 + new.dataSource)
        }
    }
    
    func fullyReverse() {
        
        if children.isEmpty.inverted {
            
            children.reverse()
            children.forEach({ $0.fullyReverse() })
        }
    }
    
    func value(given condition: Bool) -> PlaylistContainer? {
        
        guard condition else { return nil }
        
        return self
    }
    
    static func ==(lhs: PlaylistContainer, rhs: PlaylistContainer) -> Bool {
        
        return lhs.playlist == rhs.playlist
    }
}
