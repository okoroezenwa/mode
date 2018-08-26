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

class LyricsManager {
    
    enum Location { case genius, device, coreData }
    enum Physicality { case temporal, ephemeral }
    
    var hits = [Hit]()
    var songTitle = ""
    var artistName = ""
    var currentHit: Hit?
    var currentSong: Song?
    var currentLyrics = "" {
        
        didSet {
            
//            notifier.post(name: .init("lyricsChanged"), object: nil, userInfo: ["lyrics": currentLyrics])
        }
    }
    @objc let lyricsOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Lyrics Operation Queue"
        
        return queue
    }()
    @objc var operation: BlockOperation?
    var physicality = Physicality.temporal // determines what details window will do when song changes
    
    var previousItem: MPMediaItem?
    var item: MPMediaItem? {
        
        didSet {
            
            previousItem = oldValue
            
            guard item != oldValue, let item = item else { return }
            
            if let song: Song = {
                
                let fetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
                fetchRequest.predicate = NSPredicate.init(format: "persistentID == %@", NSNumber.init(value: item.persistentID))
                
                do {
                 
                    return try appDelegate.managedObjectContext.fetch(fetchRequest).first
                
                } catch let error {
                    
                    print(error)
                    return nil
                }
                
            }() {
                
                currentSong = song
                viewer?.useDeviceLyrics(source: song.source, lyrics: song.lyrics, animated: oldValue == nil)
                
            } else if item.validLyrics.isEmpty {
                
                currentSong = nil
                viewer?.prepareLyrics(updateBootomView: oldValue != nil)
                
            } else {
                
                currentSong = nil
                viewer?.useDeviceLyrics(source: "device", lyrics: item.validLyrics, animated: oldValue == nil)
            }
        }
    }
    
    weak var viewer: LyricsViewController?
    weak var detailer: TableViewContaining?
    
    init(viewer: LyricsViewController) {
        
        self.viewer = viewer
    }
    
    func getLyrics() {
        
        let token = "Xn2cLRvTA6EIfuTt8NE4jBiiqf579ocFAwQ5xzlEPkO11Kfo3MW0LGgsm6MtfeAl"
        let base = "https://api.genius.com"
        
        guard let title = item?.validTitle.lowercased().remove(.brackets, from: .title).remove(.punctuation, from: .title).remove(.punctuation, from: .title).remove(.ampersands, from: .title),
            let artist = item?.validArtist.lowercased().remove(.brackets, from: .artist).remove(.punctuation, from: .artist).remove(.punctuation, from: .artist).remove(.ampersands, from: .artist)
            else { return }
        
        var request = URLRequest.init(url: URL.init(string: base + "/search")!)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        songTitle = title
        artistName = artist
        
        let text = title + " " + artist
        
        let parameters = ["q": text]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            
            if let error = error {
                
                print(error)
                
                DispatchQueue.main.async { self.viewer?.displayUnavailable() }
                
                return
            }
            
            do {
                
                let genius = try JSONDecoder().decode(Genius.self, from: data!)
                
                DispatchQueue.main.async {
                    
                    if let hit = self.currentHit {
                        
                        self.downloadHTML(from: hit.result.url)
                        
                    } else {
                        
                        guard let hit = genius.response.hits.enumerated().first(where: { hit in Set(["Translations", "Tracklist", "[Credits]"]).contains(where: { hit.element.result.fullTitle.contains($0) }).inverted && (hit.element.result.title.similarityTo(title, fuzziness: 0.4) >= 0.5 || hit.element.result.artist.name.similarityTo(artist, fuzziness: 0.4) >= 0.5) }) else {
                            
                            self.viewer?.displayUnavailable()
                            
                            return
                        }
                        
                        var hits = genius.response.hits
                        let first = hits.remove(at: hit.offset)
                        hits.insert(first, at: 0)
                        self.hits = hits
                        
                        self.downloadHTML(from: hit.element.result.url)
                    }
                }
                
            } catch let error {
                
                print(error)
                
                DispatchQueue.main.async { self.viewer?.displayUnavailable() }
            }
        })
        
        task.resume()
    }
    
    func downloadHTML(from urlString: String?) {
        
        guard let url = URL(string: urlString ?? "") else {
            
            if isInDebugMode {
                
                UniversalMethods.banner(withTitle: "Invalid URL").show(for: 0.3)
            }
            
            self.viewer?.displayUnavailable()
            
            return
        }
        
        DispatchQueue.global(qos: .utility).async {
            
            do {
                
                let html = try String.init(contentsOf: url)
                
                let document = try SwiftSoup.parse(html)
                document.outputSettings().prettyPrint(pretty: false)
                try document.select("br").append("\\n")
                try document.select("p").prepend("\\n\\n")
                
                UniversalMethods.performInMain { self.parse(document) }
                
            } catch let error {
                
                DispatchQueue.main.async {
                    
                    if isInDebugMode {
                        
                        UniversalMethods.banner(withTitle: "\(error)").show(for: 1)
                    }
                    
                    self.viewer?.displayUnavailable()
                }
            }
        }
    }
    
    func parse(_ document: Document) {
        
        do {
            
            let elements: Elements = try document.select("body")
            
            if let text = try elements.first()?.text().components(separatedBy: "\\n\\n")[1].replacingOccurrences(of: "\\n ", with: "\n").replacingOccurrences(of: "More on Genius", with: "\\") {
                
                let lyrics = String(text.prefix(upTo: text.index(of: "\\") ?? text.endIndex))
                store(lyrics)
                
                guard item != previousItem else { return }
                
                viewer?.performSuccesfulLyricsCheck(with: lyrics)
                
            } else {
                
                guard item != previousItem else { return }
                
                viewer?.displayUnavailable()
            }
            
        } catch let error {
            
            guard item != previousItem else { return }
            
            viewer?.displayUnavailable()
            
            if isInDebugMode {
                
                UniversalMethods.banner(withTitle: "\(error)").show(for: 1)
            }
        }
    }
    
    func store(_ text: String) {
        
        guard let item = item, let songEntity = NSEntityDescription.entity(forEntityName: "Song", in: appDelegate.managedObjectContext) else { print("Couldn't get recent searches"); return }
        
        let song = Song.init(entity: songEntity, insertInto: appDelegate.managedObjectContext)
        song.lyrics = text
        song.persistentID = Int64(item.persistentID)
        song.searchTitleTerm = songTitle
        song.searchArtistTerm = artistName
        song.source = "genius"
        
        do {
            
            try appDelegate.managedObjectContext.save()
        
        } catch let error {
            
            print(error)
        }
    }
}
