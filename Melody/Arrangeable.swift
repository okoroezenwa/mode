//
//  Arrangeable.swift
//  Melody
//
//  Created by Ezenwa Okoro on 18/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

protocol Arrangeable: NSObjectProtocol, TableViewContaining {
    
    var query: MPMediaQuery? { get }
    var sortCriteria: SortCriteria { get set }
    var ascending: Bool { get set }
    var applicableSortCriteria: Set<SortCriteria> { get }
    var arrangeButton: MELButton! { get set }
    var location: SortLocation { get }
    
    func sortItems()
}

protocol FullySortable: Arrangeable {
    
    var operation: BlockOperation? { get set }
    var sections: [SortSectionDetails] { get set }
    var sorter: Sorter { get set }
    var highlightedIndex: Int? { get set }
}

extension FullySortable {
    
    var duration: TimeInterval { return 1 }
    
    var alphaNumericCritieria: Set<SortCriteria> {
        
        return [.title, .artist, .album, .genre]
    }
    
    func scrollToHighlightedRow() {
        
        if let index = highlightedIndex {
            
            let indexPath = relevantIndexPath(using: index)
            
            tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
            
            unhighlightRow(with: indexPath)
        }
    }
    
    func relevantIndexPath(using index: Int) -> IndexPath {
        
        switch sortCriteria {
            
            case .standard:
                
                switch location {
                    
                case .songs:
                    
                    if let _ = self as? ArtistSongsViewController {
                        
                        if let detail = sections.enumerated().first(where: { $0.element.startingPoint + $0.element.count > index }) {
                            
                            return IndexPath.init(row: index - detail.element.startingPoint, section: detail.offset)
                        }
                    }
                    
                    if let itemSections = query?.itemSections, let detail = itemSections.enumerated().first(where: { $0.element.range.location + $0.element.range.length > index }) {
                        
                        return IndexPath.init(row: index - detail.element.range.location, section: detail.offset)
                    }
                    
                    return IndexPath.init(row: index, section: 0)
                    
                case .playlist: return IndexPath.init(row: index, section: 0)
                    
                case .playlistList, .album:
                    
                    if let detail = sections.enumerated().first(where: { $0.element.startingPoint + $0.element.count > index }) {
                        
                        return IndexPath.init(row: index - detail.element.startingPoint, section: detail.offset)
                    }
                    
                    return IndexPath.init(row: index, section: 0)
                    
                case .collections:
                    
                    if let itemSections = query?.collectionSections, let detail = itemSections.enumerated().first(where: { $0.element.range.location + $0.element.range.length > index }) {
                        
                        return IndexPath.init(row: index - detail.element.range.location, section: detail.offset)
                    }
                    
                    return IndexPath.init(row: index, section: 0)
                }
                
            case .random: return IndexPath.init(row: index, section: 0)
                
            default:
                
                if let detail = sections.enumerated().first(where: { $0.element.startingPoint + $0.element.count > index }) {
                    
                    return IndexPath.init(row: index - detail.element.startingPoint, section: detail.offset)
                }
                
                return IndexPath.init(row: index, section: 0)
        }
    }
    
    func unhighlightRow(with indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath), ((self as? UIViewController)?.parent as? Peekable)?.peeker == nil {
            
            cell.backgroundColor = (darkTheme ? UIColor.white : .black).withAlphaComponent(0.05)
            
            UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: { cell.backgroundColor = .clear }, completion: { _ in self.highlightedIndex = nil })
            
            if let vc = self as? UIViewController, let entityVC = vc.parent as? EntityItemsViewController {
                
                switch location {
                    
                    case .album, .songs, .playlist: entityVC.highlightedEntities?.song = nil
                        
                    case .collections: entityVC.highlightedEntities?.album = nil
                        
                    default: break
                }
            }
        }
    }
}

struct SortSectionDetails {
    
    let title: String
    let count: Int
    let startingPoint: Int
    let indexTitle: String
    
    init(title: String, count: Int, startingPoint: Int, indexTitle: String) {
        
        self.title = title
        self.count = count
        self.startingPoint = startingPoint
        self.indexTitle = indexTitle
    }
}

extension Arrangeable {
    
    var arrangementLabelText: String {
        
        switch sortCriteria {
            
            case .duration: return "Duration"
            
            case .title: return location == .playlistList ? "Name" : "Title"
                
            case .plays: return "Plays"
                
            case .lastPlayed: return "Last Played"
                
            case .genre: return "Genre Name"
                
            case .rating: return "Rating"
                
            case .standard:
                
                switch location {
                    
                    case .album: return "Track Number"
                    
                    case .playlist: return "Playlist Order"
                    
                    case .playlistList: return "Type"
                    
                    case .songs, .collections: return "Default Order"
                }
                
            case .dateAdded:
                
                switch location {
                    
                    case .collections: return "Recently Added"
                    
                    case .songs, .playlist, .album, .playlistList: return "Date Added"
                }
                
            case .random: return "Random Order"
                
            case .album: return "Album Title"
                
            case .artist: return "Artist Name"
                
            case .year: return "Year"
            
            case .fileSize: return "Size"
            
            case .songCount: return "Song Count"
            
            case .albumCount: return "Album Count"
        }
    }
    
    func updateImage(for button: UIButton) {
        
        button.setImage(ascending ? #imageLiteral(resourceName: "AscendingLines") : #imageLiteral(resourceName: "DescendingLines"), for: .normal)
    }
    
    func descriptor(for criteria: SortCriteria) -> NSSortDescriptor {
        
        switch criteria {
                
            case .title:
                
                switch location {
                    
                    case .album, .playlist, .songs: return .init(key: numbersBelowLetters ? #keyPath(MPMediaItem.sortTitle) : #keyPath(MPMediaItem.validTitle), ascending: ascending, selector: #selector(NSString.localizedStandardCompare(_:)))
                    
                    case .playlistList: return .init(key: numbersBelowLetters ? #keyPath(MPMediaPlaylist.sortName) : #keyPath(MPMediaPlaylist.validName), ascending: ascending, selector: #selector(NSString.localizedStandardCompare(_:)))
                    
                    case .collections: return .init()
                }
                
            case .album:
                
                switch location {
                    
                    case .album, .songs, .playlist: return .init(key: numbersBelowLetters ? #keyPath(MPMediaItem.sortAlbum) : #keyPath(MPMediaItem.validAlbum), ascending: ascending, selector: #selector(NSString.localizedStandardCompare(_:)))
                    
                    case .collections: return .init(key: numbersBelowLetters ? #keyPath(MPMediaItemCollection.sortAlbumTitle) : #keyPath(MPMediaItemCollection.albumTitle), ascending: ascending, selector: #selector(NSString.localizedStandardCompare(_:)))
                    
                    case .playlistList: return .init()
                }
                
            case .artist:
                
                switch location {
                    
                    case .collections: return .init(key: numbersBelowLetters ? #keyPath(MPMediaItemCollection.sortArtistName) : #keyPath(MPMediaItemCollection.artistName), ascending: ascending, selector: #selector(NSString.localizedStandardCompare(_:)))
                    
                    case .playlist, .songs, .album: return .init(key: numbersBelowLetters ? #keyPath(MPMediaItem.sortArtist) : #keyPath(MPMediaItem.validArtist), ascending: ascending, selector: #selector(NSString.localizedStandardCompare(_:)))
                    
                    case .playlistList: return .init()
                }
                
            case .dateAdded:
                
                switch location {
                    
                    case .collections: return .init(key: #keyPath(MPMediaItemCollection.recentlyAdded), ascending: ascending)
                    
                    case .album, .songs, .playlist: return .init(key: #keyPath(MPMediaItem.validDateAdded), ascending: ascending)
                    
                    case .playlistList: return .init(key: #keyPath(MPMediaPlaylist.dateCreated), ascending: ascending)
                }
                
            case .duration:
                
                switch location {
                    
                    case .album, .songs, .playlist: return .init(key: #keyPath(MPMediaItem.playbackDuration), ascending: ascending)
                        
                    case .collections, .playlistList: return .init(key: #keyPath(MPMediaItemCollection.totalDuration), ascending: ascending)
                }
                
            case .genre:
                
                switch location {
                    
                    case .collections: return .init(key: numbersBelowLetters ? #keyPath(MPMediaItemCollection.sortGenre) : #keyPath(MPMediaItemCollection.genre), ascending: ascending, selector: #selector(NSString.localizedStandardCompare(_:)))
                    
                    case .songs, .playlist, .album: return .init(key: numbersBelowLetters ? #keyPath(MPMediaItem.sortGenre) : #keyPath(MPMediaItem.validGenre), ascending: ascending, selector: #selector(NSString.localizedStandardCompare(_:)))
                    
                    case .playlistList: return .init()
                }
                
            case .lastPlayed: return .init(key: #keyPath(MPMediaItem.validLastPlayed), ascending: ascending)
                
            case .plays:
                
                switch location {
                    
                    case .collections, .playlistList: return .init(key: #keyPath(MPMediaItemCollection.totalPlays), ascending: ascending)
                    
                    case .songs, .playlist, .album: return .init(key: #keyPath(MPMediaItem.playCount), ascending: ascending)
                }
                
            case .rating: return .init(key: #keyPath(MPMediaItem.rating), ascending: ascending)
                
            case .year:
                
                switch location {
                    
                    case .collections: return .init(key: #keyPath(MPMediaItemCollection.year), ascending: ascending)
                    
                    default: return .init(key: #keyPath(MPMediaItem.year), ascending: ascending)
                }
            
            case .standard:
            
                switch location {
                    
                    case .album: return .init(key: #keyPath(MPMediaItem.discCount), ascending: ascending)
                    
                    case .collections, .playlist, .songs: return .init()
                    
                    case .playlistList: return .init()
                }
                
            case .random: return .init()
            
            case .fileSize:
                
                switch location {
                    
                    case .playlistList, .collections: return .init(key: #keyPath(MPMediaItemCollection.totalSize), ascending: ascending)
                    
                    case .playlist, .songs, .album: return .init(key: #keyPath(MPMediaItem.fileSize), ascending: ascending)
                }
            
            case .songCount: return .init(key: #keyPath(MPMediaItemCollection.songCount), ascending: ascending)
            
            case .albumCount: return .init(key: #keyPath(MPMediaItemCollection.albumCount), ascending: ascending)
        }
    }
    
    func descriptors(for criteria: SortCriteria...) -> [NSSortDescriptor] {
        
        var descriptors = [NSSortDescriptor]()
        
        for criterion in criteria {
            
            descriptors.append(descriptor(for: criterion))
        }
        
        return descriptors
    }
    
    /// Sort descriptors for each sort category.
    var sortDescriptors: [NSSortDescriptor] {
        
        get {
            
            switch sortCriteria {
                
                case .title:
                    
                    switch location {
                        
                        case .collections: return []
                        
                        case .playlistList: return descriptors(for: .title, .dateAdded)
                        
                        case .playlist, .album, .songs: return descriptors(for: .title, .artist, .album)
                    }
                    
                case .artist:
                    
                    switch location {
                        
                        case .collections: return descriptors(for: .artist, .album)
                        
                        case .playlistList: return []
                            
                        case .album, .playlist, .songs: return descriptors(for: .artist, .album, .title)
                    }
                    
                case .album:
                    
                    switch location {
                        
                        case .collections: return descriptors(for: .album, .artist)
                        
                        case .playlistList: return []
                            
                        case .album, .playlist, .songs: return descriptors(for: .album, .artist, .title)
                    }
                    
                case .standard:
                    
                    switch location {
                        
                    case .album: return [descriptor(for: sortCriteria)] + [NSSortDescriptor.init(key: #keyPath(MPMediaItem.albumTrackNumber), ascending: ascending)] + descriptors(for: .title, .duration) // changed from Song to MPMediaItem for some reason; may need to change back
                        
                        case .playlistList: return []
                        
                        case .collections, .playlist, .songs: return []
                    }
                
                case .random: return []
                    
                default:
                    
                    let array: [NSSortDescriptor] = {
                        
                        switch location {
                            
                            case .album, .playlist, .songs: return descriptors(for: .artist, .album, .title)
                                
                            case .collections: return descriptors(for: .album, .artist)
                            
                            case .playlistList: return descriptors(for: .title, .dateAdded)
                        }
                    }()
                    
                    return [descriptor(for: sortCriteria)] + array
            }
        }
    }
    
    /**
     
     Generates section titles and indices from a sorted array of songs or collections.
     
     - Parameters:
        - items: the sorted entities to generate sections from.
        - mappedArray: an array generated from the **items** array which contains all section titles. This array is used to generate the item count per section.
        - sectionTitles: section titles to use.
        - indexTitles: index titles to use for the section index tableView property.
     */
    func getSectionDetails<T: Comparable>(from items: [T], withOrderedArray mappedArray: [T], sectionTitles: [String], indexTitles: [String]) -> [SortSectionDetails] {
        
        var details = [SortSectionDetails]()
        
        // for each item (array) in the unique items array
        for thing in mappedArray.enumerated() {
            
            // count for each array within + starting point
            let count = items.filter({ $0 == thing.element }).count
            let startingPoint = thing.offset == 0 ? 0 : details[thing.offset - 1].count + details[thing.offset - 1].startingPoint
            
            details.append(SortSectionDetails(title: sectionTitles[thing.offset], count: count, startingPoint: startingPoint, indexTitle: indexTitles[thing.offset]))
        }
        
        return details
    }
    
    func prepareSections(from collections: [MPMediaItemCollection]) -> [SortSectionDetails] {
        
        switch sortCriteria {
            
            case .standard, .random: return []
            
            case .duration:
            
                let props = collections.map({ Int($0.totalDuration) / 60 })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let sectionTitles = orderedProps.map({ /*$0 > 60 ? "\($0):00:00+" : */"\($0):00+" })
                let indexTitles = orderedProps.map({ /*$0 > 60 ? "\($0)H+" : */"\($0)M+" })
                
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
            
            case .album:
            
                let props = collections.compactMap({ $0.representativeItem }).map({ $0.validAlbum }).map({ !CharacterSet.letters.contains(String($0.prefix(1)).unicodeScalars.first!) ? "#" : String($0.prefix(1)).uppercased() }).map({ $0.folding(options: .diacriticInsensitive, locale: .current) })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let numeric = orderedProps.filter({ $0 == "#" })
                let alpha = orderedProps.filter({ $0 != "#" })
                let trueSort = numbersBelowLetters ? (ascending ? alpha + numeric : numeric + alpha) : (ascending ? numeric + alpha : alpha + numeric)
                
                return getSectionDetails(from: props, withOrderedArray: trueSort, sectionTitles: trueSort, indexTitles: trueSort)
            
            case .year:
            
                let props = collections.map({ $0.year })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let sectionTitles = orderedProps.map({ $0 == 0 ? "?" : String.init(describing: $0) })
                let indexTitles = orderedProps.map({ $0 == 0 ? "?" : (String.init(describing: $0) as NSString).replacingCharacters(in: NSMakeRange(0, 2), with: "'") })
                
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
            
            case .artist:
            
                let props = collections.map({ $0.artistName }).map({ !CharacterSet.letters.contains(String($0.prefix(1)).unicodeScalars.first!) ? "#" : String($0.prefix(1)).uppercased() }).map({ $0.folding(options: .diacriticInsensitive, locale: .current) })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let numeric = orderedProps.filter({ $0 == "#" })
                let alpha = orderedProps.filter({ $0 != "#" })
                let trueSort = numbersBelowLetters ? (ascending ? alpha + numeric : numeric + alpha) : (ascending ? numeric + alpha : alpha + numeric)
                
                return getSectionDetails(from: props, withOrderedArray: trueSort, sectionTitles: trueSort, indexTitles: trueSort)
            
            case .genre:
                
                let genres = collections.map({ $0.genre })
                let isOverIndexLimit = Set(genres).count > 29
            
                let props = isOverIndexLimit ? genres.map({ !CharacterSet.letters.contains(String($0.prefix(1)).unicodeScalars.first!) ? "#" : String($0.prefix(1)).uppercased() }).map({ $0.folding(options: .diacriticInsensitive, locale: .current) }) : genres.map({ $0.folding(options: .diacriticInsensitive, locale: .current) })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let numeric = orderedProps.filter({ isOverIndexLimit ? $0 == "#" : CharacterSet.letters.contains(String($0.prefix(1)).unicodeScalars.first!).inverted })
                let alpha = orderedProps.filter({ isOverIndexLimit ? $0 != "#" : CharacterSet.letters.contains(String($0.prefix(1)).unicodeScalars.first!) })
                let trueSort = numbersBelowLetters ? (ascending ? alpha + numeric : numeric + alpha) : (ascending ? numeric + alpha : alpha + numeric)
                
                return getSectionDetails(from: props, withOrderedArray: trueSort, sectionTitles: trueSort, indexTitles: isOverIndexLimit ? trueSort.map { $0.capitalized } : trueSort.map({ String($0.prefix(3)).capitalized }))
            
            case .dateAdded:
            
                let props = collections.map({ (collection: MPMediaItemCollection) -> Int in
                    
                    let int = abs(Int(collection.recentlyAdded.timeIntervalSince(Date())))
                    
                    if int == -1 {
                        
                        return -1
                        
                    } else if int < 3601 {
                        
                        return Interval.pastHour.rawValue
                        
                    } else if int < 86401 {
                        
                        return Interval.pastDay.rawValue
                        
                    } else if int < 604801 {
                        
                        return Interval.pastWeek.rawValue
                        
                    } else if int < 2592001 {
                        
                        return Interval.pastMonth.rawValue
                        
                    } else if int < 7776001 {
                        
                        return Interval.pastThreeMonths.rawValue
                        
                    } else if int < 15552001 {
                        
                        return Interval.pastSixMonths.rawValue
                        
                    } else {
                        
                        return Calendar.current.component(.year, from: collection.recentlyAdded)
                    }
                })
                let set = Set(props)
                let notInLibrary = set.filter({ $0 == -1 })
                let enumContaining = Array(set).filter({ $0 < 10 && $0 > -1 }).sorted(by: { (ascending ? $0 > $1 : $0 < $1) }) // values within the set that are represented by the Interval enum. They are arranged in the reverse order due to the order of the enum values (Which I really should chage at some point)
                let years = Array(set).filter({ $0 > 10 }).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let orderedProps = ascending ? years + enumContaining + notInLibrary : notInLibrary + enumContaining + years
                let sectionTitles = orderedProps.map({ (item: Int) -> String in
                    
                    switch item {
                        
                        case -1: return "unadded"
                            
                        case Interval.pastHour.rawValue: return "last hour"
                            
                        case Interval.pastDay.rawValue: return "last 24 hours"
                            
                        case Interval.pastWeek.rawValue: return "last 7 days"
                            
                        case Interval.pastMonth.rawValue: return "last 30 days"
                            
                        case Interval.pastThreeMonths.rawValue: return "last 3 months"
                            
                        case Interval.pastSixMonths.rawValue: return "last 6 months"
                            
                        default: return "\(item)"
                    }
                })
                let indexTitles = orderedProps.map({ (item: Int) -> String in
                    
                    switch item {
                        
                        case -1: return "nil"
                            
                        case Interval.pastHour.rawValue: return "1H"
                            
                        case Interval.pastDay.rawValue: return "1D"
                            
                        case Interval.pastWeek.rawValue: return "7D"
                            
                        case Interval.pastMonth.rawValue: return "1M"
                            
                        case Interval.pastThreeMonths.rawValue: return "3M"
                            
                        case Interval.pastSixMonths.rawValue: return "6M"
                            
                        default: return ("\(item)" as NSString).replacingCharacters(in: NSMakeRange(0, 2), with: "'")
                    }
                })
                
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
            
            case .plays:
            
                let props = collections.map({ (collection: MPMediaItemCollection) -> Int in
                    
                    let plays = collection.totalPlays
                    
                    if plays == 0 {
                        
                        return 0
                        
                    } else if plays < 10 {
                        
                        return 1
                        
                    } else if plays >= 10 && plays < 20 {
                        
                        return 2
                        
                    } else if plays >= 20 && plays < 50 {
                        
                        return 3
                        
                    } else if plays >= 50 && plays < 100 {
                        
                        return 4
                        
                    } else if plays >= 100 && plays < 200 {
                        
                        return 5
                        
                    } else if plays >= 200 && plays < 500 {
                        
                        return 6
                        
                    } else if plays >= 500 && plays < 1000 {
                        
                        return 7
                        
                    } else {
                        
                        return 8
                    }
                })
                
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let sectionTitles = orderedProps.map({ (item: Int) -> String in
                    
                    switch item {
                        
                        case 0: return "unplayed"
                            
                        case 1: return "under 10"
                            
                        case 2: return "10 and over"
                            
                        case 3: return "20 and over"
                            
                        case 4: return "50 and over"
                            
                        case 5: return "100 and over"
                            
                        case 6: return "200 and over"
                            
                        case 7: return "500 and over"
                            
                        default: return 1000.formatted + " and over"
                    }
                })
                
                let indexTitles = orderedProps.map({ (item: Int) -> String in
                    
                    switch item {
                        
                        case 0: return "nil"
                            
                        case 1: return "<10"
                            
                        case 2: return "10+"
                            
                        case 3: return "20+"
                            
                        case 4: return "50+"
                            
                        case 5: return "1H+"
                            
                        case 6: return "2H+"
                            
                        case 7: return "5H+"
                            
                        default: return "1K+"
                    }
                })
                
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
            
            case .fileSize:
                
                let props = collections.map({ FileSize.init(size: $0.totalSize < 1000000 ? 0 : $0.totalSize.divided, suffix: $0.totalSize < 1000000 ? "B" : $0.totalSize.fileSizeSuffix, actualSize: $0.totalSize) })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0.actualSize < $1.actualSize : $0.actualSize > $1.actualSize) })
                let sectionTitles = orderedProps.map({ $0.suffix == "B" || $0.suffix == "KB" ? "Under 1 MB" : "\($0.size) \($0.suffix) and over" })
                let indexTitles = orderedProps.map({ $0.suffix == "B" || $0.suffix == "KB" ? "<1MB" : "\($0.size)\($0.suffix)+" })
                
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
            
            case .songCount:
            
                let props = collections.map({ $0.songCount })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let sectionTitles = orderedProps.map({ $0.fullCountText(for: .song) })
                let indexTitles = orderedProps.map({ "\($0)" })
                
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
            
            case .albumCount:
            
                let props = collections.map({ $0.albumCount })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let sectionTitles = orderedProps.map({ $0.fullCountText(for: .album) })
                let indexTitles = orderedProps.map({ "\($0)" })
                
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
            
            default: return []
        }
    }
    
    func prepareSections(from playlists: [MPMediaPlaylist]) -> [SortSectionDetails] {
        
        switch sortCriteria {
            
            case .standard:
            
                let attributes = playlists.map({ $0.type.rawValue })
                let things = Set(attributes).sorted(by: { ascending ? $0 < $1 : $0 > $1 })
                let titles = things.map({ number -> String in
                    
                    switch number {
                        
                        case PlaylistType.folder.rawValue: return "folders"
                        
                        case PlaylistType.smart.rawValue: return "smart"
                            
                        case PlaylistType.genius.rawValue: return "genius"
                            
                        case PlaylistType.appleMusic.rawValue: return "apple music"
                            
                        default: return "manual"
                    }
                })
                let indexTitles = titles.map({ String($0.prefix(1)).capitalized })
                
                return getSectionDetails(from: attributes, withOrderedArray: things, sectionTitles: titles, indexTitles: indexTitles)
            
            case .dateAdded:
            
                let props = playlists.map({ (collection: MPMediaPlaylist) -> Int in
                    
                    let int = abs(Int(collection.dateCreated.timeIntervalSince(Date())))
                    
                    if int == -1 {
                        
                        return -1
                        
                    } else if int < 3601 {
                        
                        return Interval.pastHour.rawValue
                        
                    } else if int < 86401 {
                        
                        return Interval.pastDay.rawValue
                        
                    } else if int < 604801 {
                        
                        return Interval.pastWeek.rawValue
                        
                    } else if int < 2592001 {
                        
                        return Interval.pastMonth.rawValue
                        
                    } else if int < 7776001 {
                        
                        return Interval.pastThreeMonths.rawValue
                        
                    } else if int < 15552001 {
                        
                        return Interval.pastSixMonths.rawValue
                        
                    } else {
                        
                        return Calendar.current.component(.year, from: collection.dateCreated)
                    }
                })
                let set = Set(props)
                let notInLibrary = set.filter({ $0 == -1 })
                let enumContaining = Array(set).filter({ $0 < 10 && $0 > -1 }).sorted(by: { (ascending ? $0 > $1 : $0 < $1) }) // values within the set that are represented by the Interval enum. They are arranged in the reverse order due to the order of the enum values (Which I really should chage at some point)
                let years = Array(set).filter({ $0 > 10 }).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let orderedProps = ascending ? years + enumContaining + notInLibrary : notInLibrary + enumContaining + years
                let sectionTitles = orderedProps.map({ (item: Int) -> String in
                    
                    switch item {
                        
                        case -1: return "not in library"
                        
                        case Interval.pastHour.rawValue: return "last hour"
                        
                        case Interval.pastDay.rawValue: return "last 24 hours"
                        
                        case Interval.pastWeek.rawValue: return "last 7 days"
                        
                        case Interval.pastMonth.rawValue: return "last 30 days"
                        
                        case Interval.pastThreeMonths.rawValue: return "last 3 months"
                        
                        case Interval.pastSixMonths.rawValue: return "last 6 months"
                        
                        default: return "\(item)"
                    }
                })
                let indexTitles = orderedProps.map({ (item: Int) -> String in
                    
                    switch item {
                        
                        case -1: return "nil"
                        
                        case Interval.pastHour.rawValue: return "1H"
                        
                        case Interval.pastDay.rawValue: return "1D"
                        
                        case Interval.pastWeek.rawValue: return "7D"
                        
                        case Interval.pastMonth.rawValue: return "1M"
                        
                        case Interval.pastThreeMonths.rawValue: return "3M"
                        
                        case Interval.pastSixMonths.rawValue: return "6M"
                        
                        default: return ("\(item)" as NSString).replacingCharacters(in: NSMakeRange(0, 2), with: "'")
                    }
                })
                
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
            
            case .title:
            
                let props = playlists.map({ $0.validName }).map({ !CharacterSet.letters.contains(String($0.prefix(1)).unicodeScalars.first!) ? "#" : String($0.prefix(1)).uppercased() }).map({ $0.folding(options: .diacriticInsensitive, locale: .current) })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let numeric = orderedProps.filter({ $0 == "#" })
                let alpha = orderedProps.filter({ $0 != "#" })
                let trueSort = numbersBelowLetters ? (ascending ? alpha + numeric : numeric + alpha) : (ascending ? numeric + alpha : alpha + numeric)
                
                return getSectionDetails(from: props, withOrderedArray: trueSort, sectionTitles: trueSort, indexTitles: trueSort)
            
            default: return prepareSections(from: playlists as [MPMediaItemCollection])
        }
    }
    
    func prepareSections(from items: [MPMediaItem]) -> [SortSectionDetails] {
        
        switch sortCriteria {
            
            case .standard:
            
                switch location {
                    
                    case .album:
                    
                        let items = items.map({ $0.discNumber })
                        let discNumbers = Set(items).sorted(by: { ascending ? $0 < $1 : $0 > $1 })
                        let titles = discNumbers.map({ "disc \($0)" })
                        let indexTitles = discNumbers.map({ "D\($0)" })
                        
                        return getSectionDetails(from: items, withOrderedArray: discNumbers, sectionTitles: titles, indexTitles: indexTitles)
                    
                    default: return []
                }
            
            case .random, .songCount, .albumCount: return []
                
            case .plays:
                
                let props = items.map({ (item: MPMediaItem) -> Int in
                    
                    let plays = item.playCount
                    
                    if plays == 0 {
                        
                        return 0
                        
                    } else if plays < 10 {
                        
                        return 1
                        
                    } else if plays >= 10 && plays < 20 {
                        
                        return 2
                        
                    } else if plays >= 20 && plays < 50 {
                        
                        return 3
                        
                    } else if plays >= 50 && plays < 100 {
                        
                        return 4
                        
                    } else if plays >= 100 && plays < 200 {
                        
                        return 5
                        
                    } else if plays >= 200 && plays < 500 {
                        
                        return 6
                        
                    } else if plays >= 500 && plays < 1000 {
                        
                        return 7
                        
                    } else {
                        
                        return 8
                    }
                })
                
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let sectionTitles = orderedProps.map({ (item: Int) -> String in
                    
                    switch item {
                        
                        case 0: return "unplayed"
                            
                        case 1: return "under 10"
                            
                        case 2: return "10 and over"
                            
                        case 3: return "20 and over"
                            
                        case 4: return "50 and over"
                            
                        case 5: return "100 and over"
                            
                        case 6: return "200 and over"
                            
                        case 7: return "500 and over"
                            
                        default: return 1000.formatted + " and over"
                    }
                })
                
                let indexTitles = orderedProps.map({ (item: Int) -> String in
                    
                    switch item {
                        
                        case 0: return "0"
                            
                        case 1: return "<10"
                            
                        case 2: return "10+"
                            
                        case 3: return "20+"
                            
                        case 4: return "50+"
                            
                        case 5: return "1H+"
                            
                        case 6: return "2H+"
                            
                        case 7: return "5H+"
                            
                        default: return "1K+"
                    }
                })
                
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
                
            case .year:
                
                let props = items.map({ $0.year })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let sectionTitles = orderedProps.map({ $0 == 0 ? "?" : String.init(describing: $0) })
                let indexTitles = orderedProps.map({ $0 == 0 ? "?" : (String.init(describing: $0) as NSString).replacingCharacters(in: NSMakeRange(0, 2), with: "'") })
                
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
                
            case .title:
                
                let props = items.map({ $0.validTitle }).map({ !CharacterSet.letters.contains(String($0.prefix(1)).unicodeScalars.first!) ? "#" : String($0.prefix(1)).uppercased() }).map({ $0.folding(options: .diacriticInsensitive, locale: .current) })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let numeric = orderedProps.filter({ $0 == "#" })
                let alpha = orderedProps.filter({ $0 != "#" })
                let trueSort = numbersBelowLetters ? (ascending ? alpha + numeric : numeric + alpha) : (ascending ? numeric + alpha : alpha + numeric)
                
                return getSectionDetails(from: props, withOrderedArray: trueSort, sectionTitles: trueSort, indexTitles: trueSort)
                
            case .album:
                
                let props = items.map({ $0.validAlbum }).map({ !CharacterSet.letters.contains(String($0.prefix(1)).unicodeScalars.first!) ? "#" : String($0.prefix(1)).uppercased() }).map({ $0.folding(options: .diacriticInsensitive, locale: .current) })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let numeric = orderedProps.filter({ $0 == "#" })
                let alpha = orderedProps.filter({ $0 != "#" })
                let trueSort = numbersBelowLetters ? (ascending ? alpha + numeric : numeric + alpha) : (ascending ? numeric + alpha : alpha + numeric)
                
                return getSectionDetails(from: props, withOrderedArray: trueSort, sectionTitles: trueSort, indexTitles: trueSort)
                
            case .artist:
                
                let props = items.map({ $0.validArtist }).map({ !CharacterSet.letters.contains(String($0.prefix(1)).unicodeScalars.first!) ? "#" : String($0.prefix(1)).uppercased() }).map({ $0.folding(options: .diacriticInsensitive, locale: .current) })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let numeric = orderedProps.filter({ $0 == "#" })
                let alpha = orderedProps.filter({ $0 != "#" })
                let trueSort = numbersBelowLetters ? (ascending ? alpha + numeric : numeric + alpha) : (ascending ? numeric + alpha : alpha + numeric)
                
                return getSectionDetails(from: props, withOrderedArray: trueSort, sectionTitles: trueSort, indexTitles: trueSort)
                
            case .genre:
                
                let genres = items.map({ $0.validGenre })
                let isOverIndexLimit = Set(genres).count > 29
                
                let props = isOverIndexLimit ? genres.map({ !CharacterSet.letters.contains(String($0.prefix(1)).unicodeScalars.first!) ? "#" : String($0.prefix(1)).uppercased() }).map({ $0.folding(options: .diacriticInsensitive, locale: .current) }) : genres.map({ $0.folding(options: .diacriticInsensitive, locale: .current) })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let numeric = orderedProps.filter({ isOverIndexLimit ? $0 == "#" : CharacterSet.letters.contains(String($0.prefix(1)).unicodeScalars.first!).inverted })
                let alpha = orderedProps.filter({ isOverIndexLimit ? $0 != "#" : CharacterSet.letters.contains(String($0.prefix(1)).unicodeScalars.first!) })
                let trueSort = numbersBelowLetters ? (ascending ? alpha + numeric : numeric + alpha) : (ascending ? numeric + alpha : alpha + numeric)
                
                return getSectionDetails(from: props, withOrderedArray: trueSort, sectionTitles: trueSort, indexTitles: isOverIndexLimit ? trueSort.map { $0.capitalized } : trueSort.map({ String($0.prefix(3)).capitalized }))
                
            case .rating:
                
                let props = items.map({ $0.rating })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let sectionTitles = orderedProps.map({ $0 == 0 ? "unrated" : "\($0) star" })
                let indexTitles = orderedProps.map({ "\($0)" })
                
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
                
            case .dateAdded:
                
                let props = items.map({ (item: MPMediaItem) -> Int in
                    
                    let int = item.existsInLibrary ? abs(Int(item.validDateAdded.timeIntervalSince(Date()))) : -1
                    
                    if int == -1 {
                        
                        return -1
                        
                    } else if int < 3601 {
                        
                        return Interval.pastHour.rawValue
                        
                    } else if int < 86401 {
                        
                        return Interval.pastDay.rawValue
                        
                    } else if int < 604801 {
                        
                        return Interval.pastWeek.rawValue
                        
                    } else if int < 2592001 {
                        
                        return Interval.pastMonth.rawValue
                        
                    } else if int < 7776001 {
                        
                        return Interval.pastThreeMonths.rawValue
                        
                    } else if int < 15552001 {
                        
                        return Interval.pastSixMonths.rawValue
                        
                    } else {
                        
                        return Calendar.current.component(.year, from: item.validDateAdded)
                    }
                })
                let set = Set(props)
                let notInLibrary = set.filter({ $0 == -1 })
                let enumContaining = Array(set).filter({ $0 < 10 && $0 > -1 }).sorted(by: { (ascending ? $0 > $1 : $0 < $1) }) // values within the set that are represented by the Interval enum. They are arranged in the reverse order due to the order of the enum values (Which I really should chage at some point)
                let years = Array(set).filter({ $0 > 10 }).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let orderedProps = ascending ? years + enumContaining + notInLibrary : notInLibrary + enumContaining + years
                let sectionTitles = orderedProps.map({ (item: Int) -> String in
                    
                    switch item {
                        
                    case -1: return "not in library"
                        
                    case Interval.pastHour.rawValue: return "last hour"
                        
                    case Interval.pastDay.rawValue: return "last 24 hours"
                        
                    case Interval.pastWeek.rawValue: return "last 7 days"
                        
                    case Interval.pastMonth.rawValue: return "last 30 days"
                        
                    case Interval.pastThreeMonths.rawValue: return "last 3 months"
                        
                    case Interval.pastSixMonths.rawValue: return "last 6 months"
                        
                    default: return "\(item)"
                    }
                })
                let indexTitles = orderedProps.map({ (item: Int) -> String in
                    
                    switch item {
                        
                    case -1: return "nil"
                        
                    case Interval.pastHour.rawValue: return "1H"
                        
                    case Interval.pastDay.rawValue: return "1D"
                        
                    case Interval.pastWeek.rawValue: return "7D"
                        
                    case Interval.pastMonth.rawValue: return "1M"
                        
                    case Interval.pastThreeMonths.rawValue: return "3M"
                        
                    case Interval.pastSixMonths.rawValue: return "6M"
                        
                    default: return ("\(item)" as NSString).replacingCharacters(in: NSMakeRange(0, 2), with: "'")
                    }
                })
                
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
                
            case .lastPlayed:
                
                let props = items.map({ (item: MPMediaItem) -> Int in
                    
                    if let date = item.lastPlayedDate {
                        
                        let int = abs(Int(date.timeIntervalSince(Date())))
                        
                        if int < 3601 {
                            
                            return Interval.pastHour.rawValue
                            
                        } else if int < 86401 {
                            
                            return Interval.pastDay.rawValue
                            
                        } else if int < 604801 {
                            
                            return Interval.pastWeek.rawValue
                            
                        } else if int < 2592001 {
                            
                            return Interval.pastMonth.rawValue
                            
                        } else if int < 7776001 {
                            
                            return Interval.pastThreeMonths.rawValue
                            
                        } else if int < 15552001 {
                            
                            return Interval.pastSixMonths.rawValue
                            
                        } else {
                            
                            return Calendar.current.component(.year, from: date)
                        }
                        
                    } else {
                        
                        return -1
                    }
                })
                let set = Set(props)
                let enumContaining = Array(set).filter({ $0 < 10 && $0 != -1 }).sorted(by: { (ascending ? $0 > $1 : $0 < $1) })
                let years = Array(set).filter({ $0 > 10 }).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let unplayed = set.filter({ $0 == -1 })
                let orderedProps = ascending ? unplayed + years + enumContaining : enumContaining + years + unplayed
                let sectionTitles = orderedProps.map({ (item: Int) -> String in
                    
                    switch item {
                        
                    case -1: return "unplayed"
                        
                    case Interval.pastHour.rawValue: return "last hour"
                        
                    case Interval.pastDay.rawValue: return "last 24 hours"
                        
                    case Interval.pastWeek.rawValue: return "last 7 days"
                        
                    case Interval.pastMonth.rawValue: return "last 30 days"
                        
                    case Interval.pastThreeMonths.rawValue: return "last 3 months"
                        
                    case Interval.pastSixMonths.rawValue: return "last 6 months"
                        
                    default: return "\(item)"
                    }
                })
                let indexTitles = orderedProps.map({ (item: Int) -> String in
                    
                    switch item {
                        
                    case -1: return "nil"
                        
                    case Interval.pastHour.rawValue: return "1H"
                        
                    case Interval.pastDay.rawValue: return "1D"
                        
                    case Interval.pastWeek.rawValue: return "7D"
                        
                    case Interval.pastMonth.rawValue: return "1M"
                        
                    case Interval.pastThreeMonths.rawValue: return "3M"
                        
                    case Interval.pastSixMonths.rawValue: return "6M"
                        
                    default: return ("\(item)" as NSString).replacingCharacters(in: NSMakeRange(0, 2), with: "'")
                    }
                })
                
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
                
            case .duration:
                
                let props = items.map({ Int($0.playbackDuration / 60) })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0 < $1 : $0 > $1) })
                let sectionTitles = orderedProps.map({ /*$0 > 60 ? "\($0):00:00+" : */"\($0):00+" })
                let indexTitles = orderedProps.map({ /*$0 > 60 ? "\($0)H+" : */"\($0)M+" })
                
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
            
            
            case .fileSize:
            
                let props = items.map({ FileSize.init(size: $0.fileSize < 1000000 ? 0 : $0.fileSize.divided, suffix: $0.fileSize < 1000000 ? "B" : $0.fileSize.fileSizeSuffix, actualSize: $0.fileSize) })
                let orderedProps = Set(props).sorted(by: { (ascending ? $0.actualSize < $1.actualSize : $0.actualSize > $1.actualSize) })
                let sectionTitles = orderedProps.map({ $0.suffix == "B" || $0.suffix == "KB" ? "Under 1 MB" : "\($0.size) \($0.suffix) and over" })
                let indexTitles = orderedProps.map({ $0.suffix == "B" || $0.suffix == "KB" ? "<1MB" : "\($0.size)\($0.suffix)+" })
            
                return getSectionDetails(from: props, withOrderedArray: orderedProps, sectionTitles: sectionTitles, indexTitles: indexTitles)
        }
    }
}

class Sorter: NSObject {
    
    var operation: Operation?
    
    init(operation: Operation?) {
        
        self.operation = operation
        super.init()
    }
}

protocol IndexContaining: NSObjectProtocol, TableViewContaining, NavigatableContained {
    
    var sectionIndexViewController: SectionIndexViewController? { get set }
    var requiresLargerTrailingConstraint: Bool { get }
}
