//
//  Song+Methods.swift
//  Mode
//
//  Created by Ezenwa Okoro on 09/07/2019.
//  Copyright © 2019 Ezenwa Okoro. All rights reserved.
//

import Foundation
import CoreData

extension Song {
    
    class func withPersistentID(_ id: MPMediaEntityPersistentID) -> Song? {
        
        let fetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
        fetchRequest.predicate = NSPredicate.init(format: "persistentID == %@", NSNumber.init(value: id))
        
        do {
            
            return try appDelegate.managedObjectContext.fetch(fetchRequest).first
            
        } catch let error {
            
            print(error)
            return nil
        }
    }
    
    class var all: [Song] {
        
        let fetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
        
        do {
            
            return try appDelegate.managedObjectContext.fetch(fetchRequest)
            
        } catch let error {
            
            print(error)
            return []
        }
    }
    
    class func delete(_ items: [Song], completion: (() -> ())? = nil) {
        
        for search in items {
            
            appDelegate.managedObjectContext.delete(search)
        }
        
        do {
            
            try appDelegate.managedObjectContext.save()
            completion?()
            
        } catch let error {
            
            print(error)
        }
    }
    
    class func deleteAllLyrics(completion: (() -> ())? = nil) {
        
        let fetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
        
        do {
            
            let songs = try appDelegate.managedObjectContext.fetch(fetchRequest)
            
            guard songs.isEmpty.inverted else { return }
            
            for song in songs {
                
                appDelegate.managedObjectContext.delete(song)
            }
            
            try appDelegate.managedObjectContext.save()
            
            completion?()
            
        } catch let error {
            
            print(error.localizedDescription)
        }
    }
}
