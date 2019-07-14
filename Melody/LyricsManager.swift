//
//  LyricsManager.swift
//  Mode
//
//  Created by Ezenwa Okoro on 11/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit
import SwiftSoup
import CoreData

class LyricsManager: NSObject {
    
    enum Location: String { case genius, device }
    enum ErrorMessage: String { case noLyrics = "No Lyrics Found", unavailable = "Lyrics Unavailable", error = "An Error Occured", deleted = "Lyrics Removed" }
    enum LyricsProperties { case id, name, artist, lyrics, url, source, deleted }
    
    var hits = [Hit]()
    var songTitle = ""
    var artistName = ""
    var currentObject = LyricsObject.init(id: 0, name: nil, artist: nil, titleTerm: nil, artistTerm: nil, source: nil)
    var currentMessage = ErrorMessage.noLyrics
    var operationActive = false
    
    @objc let lyricsOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Lyrics Operation Queue"
        
        return queue
    }()
    @objc var viewerOperation: BlockOperation?
    @objc var detailerOperation: BlockOperation?
    
    var item: MPMediaItem? {
        
        didSet {
            
            guard item != oldValue, let item = item else { return }
            
            if let song = Song.withPersistentID(item.persistentID) {
                
                currentObject = .init(id: UInt64(song.persistentID), name: song.name, artist: song.artist, titleTerm: song.searchTitleTerm, artistTerm: song.searchArtistTerm, source: song.source, lyrics: song.lyrics, url: song.lyricsURL, isDeleted: song.isDeleted)
                
                guard song.lyricsDeleted.inverted else {
                    
                    displayMessage(.deleted, from: self)
                    
                    return
                }
                
                viewer?.useDeviceLyrics(source: song.source, lyrics: song.lyrics, animated: oldValue == nil)
                
            } else if item.validLyrics.isEmpty {
                
                currentObject = .init(id: item.persistentID, name: item.validTitle, artist: item.validArtist, titleTerm: item.validTitle.lowercased().lyricsRemovalsApplied(for: .title), artistTerm: item.validArtist.lowercased().lyricsRemovalsApplied(for: .artist), source: Location.genius.rawValue)
                viewer?.prepareLyrics(for: item, updateBottomView: oldValue != nil)
                
            } else {
                
                viewer?.useDeviceLyrics(source: Location.device.rawValue, lyrics: item.validLyrics, animated: oldValue == nil)
                
                currentObject = .init(id: item.persistentID, name: item.validTitle, artist: item.validArtist, titleTerm: item.validTitle.lowercased().lyricsRemovalsApplied(for: .title), artistTerm: item.validArtist.lowercased().lyricsRemovalsApplied(for: .artist), source: Location.device.rawValue, lyrics: item.validLyrics)
            
                storeLyrics(for: item, via: self)
            }
        }
    }
    
    weak var viewer: LyricsViewController?
    weak var infoDetailer: LyricsInfoViewController?
    
    init(viewer: LyricsViewController?, detailer: LyricsInfoViewController?) {
        
        self.viewer = viewer
        self.infoDetailer = detailer
    }
    
    func displayMessage(_ message: ErrorMessage = .unavailable, from container: LyricsObjectContainer) {
        
        updateIndicator(to: .hidden, from: container)
        
        currentMessage = message
        
        if let detailer = container as? LyricsInfoViewController {
            
            detailer.displayUnavailable(with: message)
            
        } else {
            
            viewer?.displayUnavailable(with: message)
        }
    }
    
    func updateIndicator(to state: VisibilityState, from container: LyricsObjectContainer) {
        
        if let detailer = container as? LyricsInfoViewController {
            
            detailer.operationActive = state == .visible
            (detailer.parent as? PresentedContainerViewController)?.updateIndicator(to: state)
            
        } else {
            
            operationActive = state == .visible
            UIApplication.shared.isNetworkActivityIndicatorVisible = state == .visible
        }
    }
    
    func getLyrics(for item: MPMediaItem?, with container: LyricsObjectContainer, operation: Operation?) {
        
        OperationQueue.main.addOperation { self.updateIndicator(to: .visible, from: container) }
        
        if let detailer = container as? LyricsInfoViewController, let hit = detailer.currentHit {
            
            downloadHTML(from: hit.result.url, for: item, lyricsObjectContainer: detailer, operation: operation)
            
        } else {
        
            let token = "Xn2cLRvTA6EIfuTt8NE4jBiiqf579ocFAwQ5xzlEPkO11Kfo3MW0LGgsm6MtfeAl"
            let base = "https://api.genius.com"
            
            guard let title = container.currentObject.titleTerm ?? item?.validTitle.lowercased().lyricsRemovalsApplied(for: .title),
                let artist = container.currentObject.artistTerm ?? item?.validArtist.lowercased().lyricsRemovalsApplied(for: .artist)
                else {
                    
                    displayMessage(.noLyrics, from: container)
                    
                    return
            }
            
            var request = URLRequest.init(url: URL.init(string: base + "/search")!)
            request.httpMethod = "GET"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            currentObject = .init(id: item?.persistentID ?? 0, name: item?.validTitle, artist: item?.validArtist, titleTerm: title, artistTerm: artist, source: Location.genius.rawValue)
            
            container.currentObject.titleTerm = title
            container.currentObject.artistTerm = artist
            
            let parameters = ["q": title + " " + artist]
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
            
            let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
                
                if let error = error {
                    
                    print(error)
                    
                    DispatchQueue.main.async { self.displayMessage(.error, from: container) }
                    
                    return
                }
                
                guard operation?.isCancelled == false else { return }
                
                do {
                    
                    let genius = try JSONDecoder().decode(Genius.self, from: data!)
                    
                    DispatchQueue.main.async {
                        
                        guard item == container.item else {
                            
                            if isInDebugMode {
                                
                                UniversalMethods.banner(withTitle: "Not the same song").show(for: 1.5)
                            }
                            
                            return
                        }
                        
                        guard operation?.isCancelled == false else { return }
                        
                        guard let hit = genius.response.hits.enumerated().first(where: { hit in Set(["Translations", "Tracklist", "[Credits]"]).contains(where: { hit.element.result.fullTitle.contains($0) }).inverted && (hit.element.result.title.similarityTo(title, fuzziness: 0.4) >= 0.5 || hit.element.result.artist.name.similarityTo(artist, fuzziness: 0.4) >= 0.5) }) else {
                            
                            self.displayMessage(.noLyrics, from: container)
                            
                            return
                        }
                        
                        guard operation?.isCancelled == false else { return }
                        
                        var hits = genius.response.hits
                        hits.insert(hits.remove(at: hit.offset), at: 0)
                        container.hits = hits
                        container.currentObject.url = hit.element.result.url
                        
                        if let detailer = container as? LyricsInfoViewController {
                            
                            detailer.tableView?.reloadSections(.init(integer: 2), with: .none)
                        }
                        
                        guard operation?.isCancelled == false else { return }
                        
                        self.downloadHTML(from: hit.element.result.url, for: item, lyricsObjectContainer: container, operation: operation)
                    }
                    
                } catch let error {
                    
                    print(error)
                    
                    DispatchQueue.main.async { self.displayMessage(.error, from: container) }
                }
            })
        
            task.resume()
        }
    }
    
    func downloadHTML(from urlString: String?, for item: MPMediaItem?, lyricsObjectContainer container: LyricsObjectContainer, operation: Operation?) {
        
        guard let url = URL(string: urlString ?? "") else {
            
            if isInDebugMode {
                
                UniversalMethods.banner(withTitle: "Invalid URL").show(for: 0.3)
            }
            
            self.displayMessage(from: container)
            
            return
        }
        
        guard item?.persistentID == container.currentObject.id else {
            
            if isInDebugMode {
                
                UniversalMethods.banner(withTitle: "Not the same song").show(for: 1.5)
            }
            
            updateIndicator(to: .hidden, from: container)
            
            return
        }
        
        guard operation?.isCancelled == false else { return }
        
        DispatchQueue.global(qos: .utility).async {
            
            do {
                
                let html = try String.init(contentsOf: url)
                
                guard operation?.isCancelled == false else { return }
                
                let document = try SwiftSoup.parse(html)
                document.outputSettings().prettyPrint(pretty: false)
                
                guard operation?.isCancelled == false else { return }
                
                try document.select("br").append("\\n")
                
                guard operation?.isCancelled == false else { return }
                
                try document.select("p").prepend("\\n\\n")
                
                DispatchQueue.main.async { self.parse(document, from: url, for: item, lyricsObjectContainer: container, operation: operation) }
                
            } catch let error {
                
                DispatchQueue.main.async {
                    
                    if isInDebugMode {
                        
                        UniversalMethods.banner(withTitle: "\(error)").show(for: 3)
                    }
                    
                    self.displayMessage(.error, from: container)
                }
            }
        }
    }
    
    func parse(_ document: Document, from url: URL, for item: MPMediaItem?, lyricsObjectContainer container: LyricsObjectContainer, operation: Operation?) {
        
        do {
            
            let elements: Elements = try document.select("body")
            
            guard operation?.isCancelled == false else { return }
            
            if let text = try elements.first()?.text().components(separatedBy: "\\n\\n")[1].replacingOccurrences(of: "\\n ", with: "\n").replacingOccurrences(of: "More on Genius", with: "\\") {
                
                guard container.currentObject.id == item?.persistentID else {
                    
                    if isInDebugMode {
                        
                        UniversalMethods.banner(withTitle: "Not the same song").show(for: 1.5)
                    }
                    
                    updateIndicator(to: .hidden, from: container)
                    
                    return
                }
                
                guard operation?.isCancelled == false else { return }
                let lyrics = String(text.prefix(upTo: text.firstIndex(of: "\\") ?? text.endIndex))
                
                container.currentObject.url = url.absoluteString
                container.currentObject.lyrics = lyrics
                
                guard operation?.isCancelled == false else { return }
                
                if let detailer = container as? LyricsInfoViewController {
                    
                    updateIndicator(to: .hidden, from: container)
                    detailer.display(lyrics)
                    
                } else {
                    
                    storeLyrics(for: item, via: container)
                }
                
            } else {
                
                guard operation?.isCancelled == false else { return }
                
                displayMessage(.noLyrics, from: container)
            }
            
        } catch let error {
            
            displayMessage(.error, from: container)
            
            if isInDebugMode {
                
                UniversalMethods.banner(withTitle: "\(error)").show(for: 1)
            }
        }
    }
    
    func storeLyrics(for item: MPMediaItem?, via container: LyricsObjectContainer, completion: Completions? = nil) {
        
        let completion = completion ?? ({ self.viewer?.performSuccesfulLyricsCheck(with: container.currentObject.lyrics) }, { self.displayMessage(.error, from: container) })
        
        guard item?.persistentID == container.currentObject.id else {
            
            if isInDebugMode {
                
                UniversalMethods.banner(withTitle: "Not the same song").show(for: 1.5)
            }
            
            updateIndicator(to: .hidden, from: container)
            
            return
        }
        
        updateSong(with: container.currentObject)
        
        do {
            
            try appDelegate.managedObjectContext.save()
            
            updateIndicator(to: .hidden, from: container)
            completion.success()
        
        } catch let error {
            
            print(error)
            
            completion.error()
        }
    }
    
    func updateSong(with object: LyricsObject) {
        
        if let song = Song.withPersistentID(object.id) {
            
            song.name = object.name
            song.artist = object.artist
            song.searchArtistTerm = object.artistTerm
            song.searchTitleTerm = object.titleTerm
            song.lyrics = object.lyrics
            song.lyricsURL = object.url
            song.source = object.source
            song.lyricsDeleted = object.isDeleted
            
        } else if let songEntity = NSEntityDescription.entity(forEntityName: "Song", in: appDelegate.managedObjectContext) {
            
            let song = Song.init(entity: songEntity, insertInto: appDelegate.managedObjectContext)
            song.name = object.name
            song.artist = object.artist
            song.persistentID = Int64(object.id)
            song.searchArtistTerm = object.artistTerm
            song.searchTitleTerm = object.titleTerm
            song.lyrics = object.lyrics
            song.lyricsURL = object.url
            song.source = object.source
        }
    }
}

extension LyricsManager: LyricsUpdater {
    
    func updateLyrics(with object: LyricsObject) {
        
        updateSong(with: object)
        
        do {
            
            try appDelegate.managedObjectContext.save()
            
            if object.id == currentObject.id {
                
                currentObject = object
                viewer?.useDeviceLyrics(source: currentObject.source, lyrics: currentObject.lyrics, animated: true)
            
            } else {
                
                UniversalMethods.banner(withTitle: "Lyrics Updated").show(for: 2)
            }
            
        } catch let error {
            
            print(error)
        }
    }
}

struct LyricsObject {
    
    var lyrics: String?
    var url: String?
    var id: UInt64
    var name: String?
    var artist: String?
    var artistTerm: String?
    var titleTerm: String?
    var source: String?
    var isDeleted: Bool
    
    var convertedID: Int64 { return Int64(id) }
    
    init(id: UInt64, name: String?, artist: String?, titleTerm: String?, artistTerm: String?, source: String?, lyrics: String? = nil, url: String? = nil, isDeleted deleted: Bool = false) {
        
        self.lyrics = lyrics
        self.id = id
        self.name = name
        self.artist = artist
        self.titleTerm = titleTerm
        self.artistTerm = artistTerm
        self.source = source
        self.url = url
        self.isDeleted = deleted
    }
}

protocol LyricsObjectContainer: class {
    
    var currentObject: LyricsObject { get set }
    var hits: [Hit] { get set }
    var item: MPMediaItem? { get set }
    var operationActive: Bool { get set }
}
