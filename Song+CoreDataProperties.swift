//
//  Song+CoreDataProperties.swift
//  Mode
//
//  Created by Ezenwa Okoro on 12/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//
//

import Foundation
import CoreData


extension Song {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Song> {
        return NSFetchRequest<Song>(entityName: "Song")
    }

    @NSManaged public var lyrics: String?
    @NSManaged public var source: String?
    @NSManaged public var searchArtistTerm: String?
    @NSManaged public var searchTitleTerm: String?
    @NSManaged public var persistentID: Int64

}
