//
//  Array + Extensions.swift
//  Mode
//
//  Created by Ezenwa Okoro on 16/04/2019.
//  Copyright © 2019 Ezenwa Okoro. All rights reserved.
//

import UIKit

// MARK: - Array
extension Array {
    
    func value(at index: Int) -> Element? {
        
        guard count > index else { return nil }
        
        return self[index]
    }
    
    func inserting(_ element: Element, at index: Index) -> [Element] {
        
        var array = self
        
        array.insert(element, at: index)
        
        return array
    }
    
    func inserting<C>(contentsOf newElements: C, at index: Index) -> [Element] where C: Collection, Element == C.Element {
        
        var array = self
        
        array.insert(contentsOf: newElements, at: index)
        
        return array
    }
    
    func appending(_ element: Element) -> [Element] {
        
        var array = self
        
        array.append(element)
        
        return array
    }
    
    /**
     Appends an element to this array if the passed condition is met.
     
     - Parameters:
     
        - element: The element to append.
        - predicate: The condition on which to append the given element.
     */
    mutating func append(_ element: Element, if predicate: Bool) {
        
        if predicate {
            
            append(element)
        }
    }
    
    /**
    Appends a sequence to this array if the passed condition is met.
    
    - Parameters:
    
       - sequence: The sequence whose contents to append.
       - predicate: The condition on which to append the given element.
    */
    mutating func append<S>(contentsOf sequence: S, if predicate: Bool) where Element == S.Element, S: Sequence {
        
        if predicate {
            
            append(contentsOf: sequence)
        }
    }
    
    func appending<S>(contentsOf sequence: S) -> [Element] where Element == S.Element, S: Sequence {
        
        var array = self
        
        array.append(contentsOf: sequence)
        
        return array
    }
    
    func removing(from index: Index) -> [Element] {
        
        var array = self
        
        array.remove(at: index)
        
        return array
    }
    
    func moving(from oldIndex: Index, to newIndex: Index) -> [Element] {
        
        var array = self
        
        let element = array.remove(at: oldIndex)
        array.insert(element, at: newIndex)
        
        return array//.inserting(array.remove(at: oldIndex), at: newIndex)
    }
}

extension Array where Element: Equatable {
    
    func optionalIndex(of element: Element?) -> Int? {
        
        guard let element = element else { return nil }
        
        return firstIndex(of: element)
    }
    
//    func removing<S>(contentsOf sequence: S) -> [Element] where Element == S.Element, S: Sequence {
//
//        return self.filter({ element in sequence.contains(where: { element == $0 }).inverted })
//    }
    
    func reorder(by preferredOrder: [Element]) -> [Element] {
        
        return self.sorted { (a, b) -> Bool in
            
            guard let first = preferredOrder.firstIndex(of: a) else {
                
                return false
            }
            
            guard let second = preferredOrder.firstIndex(of: b) else {
                
                return true
            }
            
            return first < second
        }
    }
}

extension Array where Element: Hashable {
    
    mutating func removeDuplicates() {
        
        var set = Set<Element>()
        var new = [Element]()
        
        for item in self {
            
            if !set.contains(item) {
                
                set.insert(item)
                new.append(item)
            }
        }
        
        self = new
    }
    
    func duplicatesRemoved() -> [Iterator.Element] {
        
        var new = self
        new.removeDuplicates()
        return new
    }
    
    func removing<S>(contentsOf sequence: S) -> [Element] where Element == S.Element, S: Sequence {
        
        let set = Set(sequence)
        
        return self.filter({ set.contains($0).inverted })
    }
}

extension Array where Element: MPMediaItem {
    
    var albumsShuffled: [MPMediaItem] {
        
        var albumsDict = [String: [MPMediaItem]]()
        
        for song in self {
            
            var array = albumsDict[song.validAlbum] ?? []
            array.append(song)
            albumsDict[song.validAlbum] = array
        }
        
        return albumsDict.shuffled().map({ $0.value.sorted(by: { $0.albumTrackNumber < $1.albumTrackNumber }) }).reduce([], +)
    }
    
    var canShuffleAlbums: Bool { return first(where: { $0.validAlbum != first?.validAlbum }) != nil }
    
    var totalDuration: TimeInterval { return reduce(TimeInterval(0), { $0 + $1.playbackDuration }) }
    var totalPlays: Int { return reduce(0, { $0 + $1.playCount }) }
    var totalSkips: Int { return reduce(0, { $0 + $1.skipCount }) }
    var totalSize: Int64 { return reduce(0, { $0 + $1.fileSize }) }
}

extension Array where Element: MPMediaPlaylist {
    
    var foldersConsidered: [PlaylistContainer] {
        
        var childrenArray = [[MPMediaPlaylist]]()
        let hasParent = filter { $0.parentPersistentID != 0 }
        
        var ids = Set<Int64>()
        
        for playlist in hasParent {
            
            if ids.contains(playlist.parentPersistentID).inverted {
                
                childrenArray.append([playlist])
                ids.insert(playlist.parentPersistentID)
                
            } else {
                
                if let tuple = childrenArray.enumerated().first(where: { $0.element.first?.parentPersistentID == playlist.parentPersistentID }) {
                    
                    childrenArray[tuple.offset] = tuple.element + [playlist]
                }
            }
        }
        
        let temp = childrenArray.map({ TempPlaylistContainer(id: $0.first?.parentPersistentID ?? 0, children: $0) })
        
        return filter({ $0.parentPersistentID == 0 }).compactMap({ $0.isFolder ? $0.gatherChildren(from: temp, root: $0, index: 0) : PlaylistContainer.init(playlist: $0, children: [], actualChildren: []) })
    }
}
