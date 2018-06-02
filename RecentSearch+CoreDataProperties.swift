//
//  RecentSearch+CoreDataProperties.swift
//  Mode
//
//  Created by Ezenwa Okoro on 05/03/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//
//

import Foundation
import CoreData


extension RecentSearch {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecentSearch> {
        return NSFetchRequest<RecentSearch>(entityName: "RecentSearch")
    }

    @NSManaged public var category: Int16
    @NSManaged public var entityTitle: String?
    @NSManaged public var entityType: Int16
    @NSManaged public var id: NSNumber?
    @NSManaged public var property: Int16
    @NSManaged public var propertyTest: String?
    @NSManaged public var title: String?
    @NSManaged public var uniqueID: String?

}
