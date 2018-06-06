//
//  TypeAliases.swift
//  Melody
//
//  Created by Ezenwa Okoro on 24/11/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import Foundation

typealias SectionDetails = (title: String, count: Int, category: SearchCategory)

typealias ImageCache = NSCache<NSString, UIImage>

typealias InfoCache = NSCache<InfoKey, NSString>

typealias InfoOperations = [InfoKey: Operation]

typealias PredicateDetails = (property: String, id: MPMediaEntityPersistentID)

typealias Completions = (success: () -> (), error: () -> ())

typealias ImageOperations = [IndexPath: Operation]

typealias TimeConstraintComponents = (hour: Int, minute: Int)

typealias ReducedPlaylist = (containers: [PlaylistContainer], arrangeable: [MPMediaPlaylist], dataSource: [MPMediaPlaylist])

typealias ActionDetails = (action: SongAction, title: String, style: UIAlertActionStyle, handler: (() -> Void))
