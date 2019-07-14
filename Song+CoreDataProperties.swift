//
//  Song+CoreDataProperties.swift
//  Mode
//
//  Created by Ezenwa Okoro on 12/07/2019.
//  Copyright © 2019 Ezenwa Okoro. All rights reserved.
//
//

import Foundation
import CoreData


extension Song {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Song> {
        return NSFetchRequest<Song>(entityName: "Song")
    }

    @NSManaged public var lyrics: String?
    @NSManaged public var lyricsDeleted: Bool
    @NSManaged public var lyricsURL: String?
    @NSManaged public var persistentID: Int64
    @NSManaged public var searchArtistTerm: String?
    @NSManaged public var searchTitleTerm: String?
    @NSManaged public var source: String?
    @NSManaged public var name: String?
    @NSManaged public var artist: String?

}
