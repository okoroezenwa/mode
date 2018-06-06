//
//  Filterable.swift
//  Melody
//
//  Created by Ezenwa Okoro on 16/04/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit
import CoreData

// MARK: - Filterable
protocol Filterable: FilterContaining {
    
    var wasFiltering: Bool { get set }
    var filterText: String? { get set }
    var filtering: Bool { get set }
    var applicableFilterProperties: Set<Property> { get set }
    var filterProperty: Property { get set }
    var propertyTest: PropertyTest { get set }
    var ignorePropertyChange: Bool { get set }
    var filterOperation: BlockOperation? { get set }
    var entityCount: Int { get }
    var filterEntities: FilterViewController.FilterEntities { get }
}

extension Filterable {
    
    var applicationItemFilterProperties: Set<Property> { return [.title, .artist, .album, .genre, .composer, .plays, .year, .isCloud, .artwork, .isCompilation, .isExplicit, .rating, .status, .size, .lastPlayed, .dateAdded] }
    
    var applicableCollectionFilterProperties: Set<Property> { return [.title, .artist, .genre, .plays, .year, .isCloud, .artwork, .isCompilation, .trackCount, .albumCount, .size, .status, .dateAdded] }
    
    var id: MPMediaEntityPersistentID {
        
        if let playlistVC = self as? PlaylistItemsViewController, let id = playlistVC.playlist?.persistentID {
            
            return id
            
        } else if let albumVC = self as? AlbumItemsViewController, let id = albumVC.album?.persistentID {
            
            return id
            
        } else if let artistSongsVC = self as? ArtistSongsViewController, let id = artistSongsVC.artist?.persistentID {
            
            return id
            
        } else if let artistAlbumsVC = self as? ArtistAlbumsViewController, let id = artistAlbumsVC.artist?.persistentID {
            
            return id
            
        } else if let collectionsVC = self as? CollectionsViewController {
            
            switch collectionsVC.collectionKind {
                
                case .playlist: return 1
                
                case .artist, .albumArtist: return 3
                
                case .album: return 4
                
                case .genre: return 5
                
                case .composer: return 6
                
                case .compilation: return 7
            }
        
        } else if let _ = self as? SongsViewController { return 2 }
        
        return 0
    }
    
    func uniqueID(with category: SearchCategory, searchBar: MELSearchBar) -> String { return "\(id)\(category)\(filterProperty.title)\(testTitle)\(searchBar.text ?? "")" }
    
    var filterTitle: String { return filterProperty.title }
    
    var placeholder: String {
        
        switch filterProperty {
            
            case .lastPlayed, .dateAdded: return "DD.MM.YYYY"
            
            case .year: return "YYYY"
            
            case .duration: return "HH.MM.SS"
            
            default: return ""
        }
    }
    
    var testTitle: String { return title(for: propertyTest, property: filterProperty) }
    
    var canFilter: Bool { return entityCount > 1 }
    
    var pickerViewText: [String?] {
        
        switch filterProperty {
            
            case .album, .artist, .title, .composer, .genre, .trackCount, .albumCount, .plays, .year, .size: return []
            
            case .rating: return [nil] + {
                
                    switch propertyTest {
                        
                        case .isExactly: return Array(0...5).map({ String($0) })
                        
                        case .isUnder: return Array(1...5).map({ String($0) })
                        
                        case .isOver: return Array(0..<5).map({ String($0) })
                        
                        default: return []
                    }
                }()
            
            case .isCloud: return [nil, FilterPickerViewOptions.iCloud.rawValue, FilterPickerViewOptions.device.rawValue]
            
            case .isCompilation, .isExplicit: return [nil, FilterPickerViewOptions.yes.rawValue, FilterPickerViewOptions.no.rawValue]
            
            case .status: return [nil, FilterPickerViewOptions.neutral.rawValue, FilterPickerViewOptions.liked.rawValue, FilterPickerViewOptions.disliked.rawValue]
            
            case .artwork: return [nil, FilterPickerViewOptions.available.rawValue, FilterPickerViewOptions.unavailable.rawValue]
            
            case .lastPlayed, .dateAdded, .duration: return []
        }
    }
    
    func filterTerm(from song: MPMediaItem) -> Any? {
        
        switch filterProperty {
            
            case .album: return song.validAlbum.lowercased().folded
            
            case .artist: return song.validArtist.lowercased().folded
            
            case .title: return song.validTitle.lowercased().folded
            
            case .artwork: return song.artwork != nil
            
            case .composer: return song.validComposer.lowercased().folded
            
            case .dateAdded: return song.validDateAdded
            
            case .duration: return song.playbackDuration
            
            case .genre: return song.validGenre.lowercased().folded
            
            case .isCloud: return song.isCloudItem
            
            case .isCompilation: return song.isCompilation
            
            case .isExplicit: return song.isExplicit
            
            case .lastPlayed: return song.validLastPlayed
            
            case .plays: return song.playCount
            
            case .rating: return song.rating
            
            case .year: return song.year
            
            case .size: return song.fileSize
            
            case .albumCount, .trackCount: return nil
            
            case .status: return song.likedState.rawValue
        }
    }
    
    func filterTerm(from collection: MPMediaItemCollection, kind: CollectionsKind) -> Any? {
        
        switch filterProperty {
            
            case .artist:
                
                switch kind {
                    
                    case .album,
                         .compilation,
                         .artist where self is SearchViewController,
                         .albumArtist where self is SearchViewController: return (albumArtistsAvailable ? collection.representativeItem?.validAlbumArtist : collection.representativeItem?.validArtist)?.lowercased().folded
                    
                    default: return nil
                }
            
            case .title:
                
                switch kind {
                    
                    case .album, .compilation: return collection.representativeItem?.validAlbum.lowercased().folded
                    
                    case .artist, .albumArtist: return (albumArtistsAvailable ? collection.representativeItem?.validAlbumArtist : collection.representativeItem?.validArtist)?.lowercased().folded
                    
                    case .composer: return collection.representativeItem?.validComposer.lowercased().folded
                    
                    case .genre: return collection.representativeItem?.validGenre.lowercased().folded
                    
                    case .playlist: return (collection as? MPMediaPlaylist)?.validName.lowercased().folded
                }
            
            case .artwork:
            
                switch kind {
                    
                    case .playlist: return collection.customArtwork != nil
                    
                    default: return nil
                }
            
            case .dateAdded:
            
                switch kind {
                    
                    case .playlist: return (collection as? MPMediaPlaylist)?.dateCreated
                    
                    default: return collection.recentlyAdded
                }
            
            case .duration: return collection.totalDuration
            
            case .genre:
            
                switch kind {
                    
                    case .album,
                         .compilation,
                         .genre where self is SearchViewController: return collection.genre.lowercased().folded
                    
                    default: return nil
                }
            
            case .isCloud: return collection.isCloudItem
            
            case .isCompilation:
            
                switch kind {
                    
                    case .album: return collection.representativeItem?.isCompilation
                    
                    default: return nil
                }
            
            case .plays: return collection.totalPlays
            
            case .year:
                
                switch kind {
                    
                    case .album, .compilation: return collection.year
                    
                    default: return nil
                }
            
            case .size: return collection.totalSize
            
            case .trackCount: return collection.items.count
            
            case .albumCount:
            
                switch kind {
                    
                    case .album, .compilation: return nil
                    
                    default:
                        
                        let count = MPMediaQuery.init(filterPredicates: [.for(kind.entity, using: collection)]).cloud.grouped(by: .album).collections?.count
                        
                        return count
                }
            
            case .album where self is SearchViewController && Set([CollectionsKind.album, .compilation]).contains(kind): return collection.representativeItem?.validAlbum.lowercased().folded
            
            case .composer where self is SearchViewController && kind == .composer: return collection.representativeItem?.validComposer.lowercased().folded
            
            case .rating, .lastPlayed, .isExplicit, .composer, .album: return nil
            
            case .status:
            
                switch kind {
                    
                    case .album, .compilation, .playlist: return collection.likedState.rawValue
                    
                    default: return nil
                }
        }
    }
    
    var filterTests: Set<PropertyTest> {
        
        switch filterProperty {
            
            case .album, .artist, .title, .composer, .genre: return [.isExactly, .contains, .beginsWith, .endsWith]
                
            case .trackCount, .albumCount, .plays, .rating, .year, .size: return [.isExactly, .isOver, .isUnder]
                
            case .isCloud, .isCompilation, .artwork, .isExplicit, .status: return [.isExactly]
                
            case .lastPlayed, .dateAdded, .duration: return [.isExactly, .isOver, .isUnder]
        }
    }
    
    var preferredInitialFilterTest: PropertyTest { return initialPropertyTest(for: filterProperty) }
    
    func initialPropertyTest(for property: Property) -> PropertyTest {
        
        switch property {
            
            case .album, .artist, .title, .composer, .genre: return .contains
            
            case .trackCount, .albumCount, .plays, .year, .size: return .isOver
            
            case .rating: return .isExactly
            
            case .isCloud, .isCompilation, .artwork, .isExplicit, .status: return .isExactly
            
            case .lastPlayed, .dateAdded, .duration: return .isOver
        }
    }
    
    var keyboardType: UIKeyboardType {
        
        switch filterProperty {
            
            case .album, .artist, .title, .composer, .genre: return .default
            
            case .trackCount, .albumCount, .plays, .rating, .year: return .numberPad
            
            case .size, .lastPlayed, .dateAdded, .duration: return .decimalPad
            
            default: return .default
        }
    }
    
    var inputView: UIView? {
        
        switch filterProperty {
        case .album, .artist, .title, .composer, .genre, .trackCount, .albumCount, .plays, .year, .size, .lastPlayed, .dateAdded: return nil
            
            case .duration, .isCloud, .isCompilation, .artwork, .isExplicit, .rating, .status: return filterContainer?.requiredInputView
        }
    }
    
    var rightViewDetails: (rightView: UIView?, mode: UITextFieldViewMode) {
        
        switch filterProperty {
            
            case .size:
                
                if let container = filterContainer {
                    
                    return (container.rightViewButton, .always)
                    
                }
            
                return (nil, .never)
            
            default: return (nil, .never)
        }
    }
    
    func getResults(for items: [MPMediaItem], against term: Any?, and otherTerm: Any? = nil) -> [MPMediaItem] {
        
        switch filterProperty {
            
            case .album, .artist, .title, .composer, .genre:
                
                guard let text = term as? String, !text.isEmpty else { return [] }
            
                switch propertyTest {
                    
                    case .isExactly: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0) as? String == (term as? String)?.lowercased().folded })
                    
                    case .contains: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return ((filterTerm(from: $0) as? String)?.score(word: (term as? String ?? "").lowercased().folded, fuzziness: 1 - filterFuzziness) ?? 0) >= 0.5 || (filterTerm(from: $0) as? String)?.range(of: (term as? String ?? "").lowercased().folded) != nil })
                    
                    case .beginsWith: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return (filterTerm(from: $0) as? String)?.hasPrefix((term as? String ?? "").lowercased().folded) == true })
                    
                    case .endsWith: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return (filterTerm(from: $0) as? String)?.hasSuffix((term as? String ?? "").lowercased().folded) == true })
                    
                    default: return []
                }
            
            case .plays, .rating, .year:
                
                guard let string = term as? String, let number = Int(string) else { return [] }
            
                switch propertyTest {
                    
                    case .isExactly: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0) as? Int == number })
                    
                    case .isOver: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return (filterTerm(from: $0) as? Int ?? 0) > number })
                    
                    case .isUnder: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return (filterTerm(from: $0) as? Int ?? 0) < number })
                    
                    default: return []
                }
            
            case .isCloud:
            
                guard let string = term as? String, let location = FilterPickerViewOptions(rawValue: string) else { return [] }
            
                switch location {
                    
                    case .iCloud: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0) as? Bool == true })
                    
                    case .device: return items.filter({  guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0) as? Bool == false })
                    
                    default: return []
                }
            
            case .artwork:
            
                guard let string = term as? String, let location = FilterPickerViewOptions(rawValue: string) else { return [] }
                
                switch location {
                    
                    case .available: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0) as? Bool == true })
                    
                    case .unavailable: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0) as? Bool == false })
                    
                    default: return []
                }
            
            case .isCompilation, .isExplicit:
            
                guard let string = term as? String, let location = FilterPickerViewOptions(rawValue: string) else { return [] }
            
                switch location {
                    
                    case .yes: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0) as? Bool == true })
                    
                    case .no: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0) as? Bool == false })
                    
                    default: return []
                }
            
            case .size:
                
                guard let primarySuffix = Int64.FileSize(rawValue: primarySizeSuffix), let string = term as? String, let number = Double(string) else { return [] }
            
                switch propertyTest {
                    
                    case .isExactly: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.fileSize == number.applyMultiplier(of: primarySuffix) })
                        
                    case .isOver: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.fileSize > number.applyMultiplier(of: primarySuffix) })
                        
                    case .isUnder: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.fileSize < number.applyMultiplier(of: primarySuffix) })
                        
                    default: return []
                }
            
            case .duration:
            
                switch propertyTest {
                    
                    case .isExactly: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.playbackDuration == term as? TimeInterval })
                        
                    case .isOver: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.playbackDuration > (term as? TimeInterval ?? 0) })
                        
                    case .isUnder: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.playbackDuration < (term as? TimeInterval ?? 0) })
                        
                    default: return []
                }
            
            case .lastPlayed:
                
                guard let string = term as? String else { return [] }
                
                let components = string.components(separatedBy: ".").flatMap({ Int($0) })
                
                guard let day = components.first, let month = components.value(at: 1), let year = components.value(at: 2), let date = Date.from(day: day, month: month, year: year) else { return [] }
            
                switch propertyTest {
                    
                    case .isExactly: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.validLastPlayed == date })
                        
                    case .isOver: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.validLastPlayed > date })
                        
                    case .isUnder: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.validLastPlayed < date })
                        
                    default: return []
                }
            
            case .dateAdded:
                
                guard let string = term as? String else { return [] }
                
                let components = string.components(separatedBy: ".").flatMap({ Int($0) })
                
                guard let day = components.first, let month = components.value(at: 1), let year = components.value(at: 2), let date = Date.from(day: day, month: month, year: year) else { return [] }
            
                switch propertyTest {
                    
                    case .isExactly: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.validDateAdded == date })
                        
                    case .isOver: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.validDateAdded > date })
                        
                    case .isUnder: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.validDateAdded < date })
                        
                    default: return []
                }
            
            case .status:
            
                guard let string = term as? String, let status = FilterPickerViewOptions(rawValue: string) else { return [] }
                
                switch status {
                    
                    case .neutral: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0) as? Int == LikedState.none.rawValue })
                    
                    case .liked: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0) as? Int == LikedState.liked.rawValue })
                    
                    case .disliked: return items.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0) as? Int == LikedState.disliked.rawValue })
                    
                    default: return []
                }
            
            case .trackCount, .albumCount: return []
        }
    }
    
    func getResults(for collections: [MPMediaItemCollection], of kind: CollectionsKind, against term: Any?, and otherTerm: Any? = nil) -> [MPMediaItemCollection] {
        
        switch filterProperty {
            
            case .artist, .title, .genre, .album, .composer:
                
                guard let text = term as? String, !text.isEmpty else { return [] }
            
                switch propertyTest {
                    
                    case .isExactly: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0, kind: kind) as? String == (term as? String)?.lowercased().folded })
                    
                    case .contains: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return ((filterTerm(from: $0, kind: kind) as? String)?.score(word: (term as? String ?? "").lowercased().folded, fuzziness: 1 - filterFuzziness) ?? 0) >= 0.5 || (filterTerm(from: $0, kind: kind) as? String)?.range(of: (term as? String ?? "").lowercased().folded) != nil })
                    
                    case .beginsWith: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return (filterTerm(from: $0, kind: kind) as? String)?.hasPrefix((term as? String ?? "").lowercased().folded) == true })
                    
                    case .endsWith: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return (filterTerm(from: $0, kind: kind) as? String)?.hasSuffix((term as? String ?? "").lowercased().folded) == true })
                    
                    default: return []
                }
            
            case .plays, .year, .trackCount, .albumCount:
                
                guard let string = term as? String, let number = Int(string) else { return [] }
            
                switch propertyTest {
                    
                    case .isExactly: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0, kind: kind) as? Int == number })
                    
                    case .isOver: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return (filterTerm(from: $0, kind: kind) as? Int ?? 0) > number })
                    
                    case .isUnder: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return (filterTerm(from: $0, kind: kind) as? Int ?? 0) < number })
                    
                    default: return []
                }
            
            case .isCloud:
            
                guard let string = term as? String, let location = FilterPickerViewOptions(rawValue: string) else { return [] }
            
                switch location {
                    
                    case .iCloud: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0, kind: kind) as? Bool == true })
                    
                    case .device: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0, kind: kind) as? Bool == false })
                    
                    default: return []
                }
            
            case .artwork:
            
                guard let string = term as? String, let location = FilterPickerViewOptions(rawValue: string) else { return [] }
                
                switch location {
                    
                    case .available: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0, kind: kind) as? Bool == true })
                    
                    case .unavailable: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0, kind: kind) as? Bool == false })
                    
                    default: return []
                }
            
            case .isCompilation:
            
                guard let string = term as? String, let location = FilterPickerViewOptions(rawValue: string) else { return [] }
            
                switch location {
                    
                    case .yes: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0, kind: kind) as? Bool == true })
                    
                    case .no: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0, kind: kind) as? Bool == false })
                    
                    default: return []
                }
            
            case .size:
            
                guard let primarySuffix = Int64.FileSize(rawValue: primarySizeSuffix), let string = term as? String, let number = Double(string) else { return [] }
            
                switch propertyTest {
                    
                    case .isExactly: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.totalSize == number.applyMultiplier(of: primarySuffix) })
                    
                    case .isOver: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.totalSize > number.applyMultiplier(of: primarySuffix) })
                    
                    case .isUnder: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.totalSize < number.applyMultiplier(of: primarySuffix) })
                    
                    default: return []
                }
            
            case .duration:
            
                switch propertyTest {
                    
                    case .isExactly: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.totalDuration == term as? TimeInterval })
                    
                    case .isOver: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.totalDuration > (term as? TimeInterval ?? 0) })
                    
                    case .isUnder: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return $0.totalDuration < (term as? TimeInterval ?? 0) })
                    
                    default: return []
                }

            case .dateAdded:
                
                guard let string = term as? String else { return [] }
                
                let components = string.components(separatedBy: ".").flatMap({ Int($0) })
                
                guard let day = components.first, let month = components.value(at: 1), let year = components.value(at: 2), let date = Date.from(day: day, month: month, year: year) else { return [] }
            
                switch propertyTest {
                    
                    case .isExactly: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled, let dateAdded = filterTerm(from: $0, kind: kind) as? Date else { return false }; return dateAdded == date })
                    
                    case .isOver: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled, let dateAdded = filterTerm(from: $0, kind: kind) as? Date else { return false }; return dateAdded > date })
                    
                    case .isUnder: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled, let dateAdded = filterTerm(from: $0, kind: kind) as? Date else { return false }; return dateAdded < date })
                    
                    default: return []
                }
            
            case .rating, .lastPlayed, .isExplicit: return []
            
            case .status:
            
                guard let string = term as? String, let status = FilterPickerViewOptions(rawValue: string) else { return [] }
                
                switch status {
                    
                    case .neutral: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0, kind: kind) as? Int == LikedState.none.rawValue })
                    
                    case .liked: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0, kind: kind) as? Int == LikedState.liked.rawValue })
                    
                    case .disliked: return collections.filter({ guard let filterOperation = filterOperation, !filterOperation.isCancelled else { return false }; return filterTerm(from: $0, kind: kind) as? Int == LikedState.disliked.rawValue })
                    
                    default: return []
                }
        }
    }
    
    func title(for test: PropertyTest, property: Property) -> String {
        
        switch test {
            
            case .isExactly:
                
                switch property {
                    
                    case .album, .artist, .title, .composer, .genre: return "matches"
                    
                    case .trackCount, .albumCount, .plays: return "equal"
                    
                    case .rating, .size, .duration: return "equals"
                    
                    case .lastPlayed, .dateAdded: return "on"
                    
                    default: return "is"
                }
            
            case .contains: return "contains"
            
            case .beginsWith: return "begins with"
            
            case .endsWith: return "ends with"
            
            case .isOver:
            
                switch property {
                    
                case .album, .artist, .title, .composer, .genre, .isCloud, .isCompilation, .artwork, .isExplicit, .status: return ""
                    
                    case .trackCount, .albumCount, .plays, .rating, .size, .duration: return "over"
                    
                    case .lastPlayed, .dateAdded, .year: return "after"
                }
            
            case .isUnder:
            
                switch property {
                    
                    case .album, .artist, .title, .composer, .genre, .isCloud, .isCompilation, .artwork, .isExplicit, .status: return ""
                    
                    case .trackCount, .albumCount, .plays, .rating, .size, .duration: return "under"
                    
                    case .lastPlayed, .dateAdded, .year: return "before"
                }
        }
    }
    
    func buttonTitle(for filterProperty: Property) -> String {
        
        return filterProperty.title
    }
    
    func invokeSearch() {
        
        if let searchVC = self as? SearchViewController {
            
            searchVC.searchBar?.becomeFirstResponder()
            
        } else if let filter = self as? (UIViewController & Filterable), let vc = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController {
            
            vc.context = .filter
            vc.filterVC.sender = filter
            vc.filterVC.entities = filter.filterEntities
            
            filter.present(vc, animated: true, completion: nil)
        }
    }
    
    func verifyPropertyTest(with container: FilterContainer & UIViewController) {
        
        if ignorePropertyChange.inverted {
            
            propertyTest = preferredInitialFilterTest
        }
        
        container.updateTestView()
    
        updateKeyboard(with: container)
    }
    
    func updateKeyboard(with container: FilterContainer) {
        
        container.searchBar.keyboardType = keyboardType
        container.searchBar.inputView = inputView
        container.searchBar.reloadInputViews()
    }
    
    func clearIfNeeded(with property: Property) {
        
        guard let container = filterContainer else { return }
        
        switch property {
            
            case .trackCount, .albumCount, .plays, .rating, .year:
                
                guard let text = container.searchBar.text, let int = Int(text) else {
                    
                    container.searchBar.text = nil
                    container.requiredInputView?.pickerView.selectRow(0, inComponent: 0, animated: true)
                    return
                }
            
                if filterProperty == .rating, !(0...5).contains(int) || (propertyTest == .isOver && int > 4) || (propertyTest == .isUnder && int > 1) {
                    
                    container.searchBar.text = nil
                    container.requiredInputView?.pickerView.selectRow(0, inComponent: 0, animated: true)
                }
            
            case .isExplicit, .isCompilation:
            
                guard let string = container.searchBar.text, let location = FilterPickerViewOptions(rawValue: string) else {
                
                    container.searchBar.text = nil
                    container.requiredInputView?.pickerView.selectRow(0, inComponent: 0, animated: true)
                    return
                }
                
                switch location {
                    
                    case .yes, .no: break
                    
                    default:
                        
                        container.searchBar.text = nil
                        container.requiredInputView?.pickerView.selectRow(0, inComponent: 0, animated: true)
                }
            
            case .size:
            
                if Double(container.searchBar.text ?? "") == nil {
                    
                    container.searchBar.text = nil
                }
            
            case .lastPlayed, .dateAdded, .duration, .isCloud, .artwork, .status:
                
                container.searchBar.text = nil
                container.requiredInputView?.pickerView.selectRow(0, inComponent: 0, animated: true)
            
            default: break
        }
    }
}

protocol FilterContextDiscoverable: Filterable {
    
    func showFilteredContext(_ sender: Any)
}
