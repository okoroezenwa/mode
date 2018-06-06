//
//  Sortable+CoreDataProperties.swift
//  Melody
//
//  Created by Ezenwa Okoro on 10/10/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import Foundation
import CoreData

extension Sortable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Sortable> {
        return NSFetchRequest<Sortable>(entityName: "Sortable");
    }

    @NSManaged public var order: Bool
    @NSManaged public var persistentID: NSNumber?
    @NSManaged public var sort: Int16
    @NSManaged public var kind: Int16
    @NSManaged public var artwork: NSData?
}
