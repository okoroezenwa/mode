//
//  Constants.swift
//  Melody
//
//  Created by Ezenwa Okoro on 11/08/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

struct DictionaryKeys {
    
    static let queueItems = "itemsToAddToQueue"
    static let trackDetails = "trackDetails"
    static let sameSong = "sameSong"
    static let artwork = "artwork"
    static let nonAnimated = "nonAnimated"
}

struct FileSize: Hashable, Comparable {
    
    let size: Int64
    let actualSize: Int64
    let suffix: String
    
    var hashValue: Int { return size.hashValue ^ suffix.hashValue }
    
    init(size: Int64, suffix: String, actualSize: Int64) {
        
        self.size = size
        self.suffix = suffix
        self.actualSize = actualSize
    }
    
    init(actualSize: Int64) {
        
        self.actualSize = actualSize
        size = actualSize.divided
        suffix = actualSize.fileSizeSuffix
    }
    
    static func ==(lhs: FileSize, rhs: FileSize) -> Bool {
        
        return lhs.size == rhs.size && lhs.suffix == rhs.suffix
    }
    
    static func >(lhs: FileSize, rhs: FileSize) -> Bool {
        
        return lhs.actualSize > rhs.actualSize
    }
    
    static func <(lhs: FileSize, rhs: FileSize) -> Bool {
        
        return lhs.actualSize < rhs.actualSize
    }
    
    static func >=(lhs: FileSize, rhs: FileSize) -> Bool {
        
        return lhs.actualSize >= rhs.actualSize
    }
    
    static func <=(lhs: FileSize, rhs: FileSize) -> Bool {
        
        return lhs.actualSize <= rhs.actualSize
    }
}

struct Attributes {
    
    enum AttributeValue { case colour(type: AttributeColourType), other(Any) }
    
    enum AttributeColourType {
        
        case main, sub, inactive
        
        var colour: UIColor {
            
            switch self {
                
                case .main: return Themer.textColour(for: .title)
                
                case .sub: return Themer.textColour(for: .subtitle)
                
                case .inactive: return Themer.tempInactiveColours
            }
        }
        
        static func colour(for textKind: Themer.TextKind) -> AttributeColourType {
            
            return textKind == .title ? .main : .sub
        }
    }
    
    let range: NSRange
    let name: NSAttributedString.Key
    let value: AttributeValue
    var trueValue: Any {
        
        switch value {
            
            case .other(let object): return object
            
            case .colour(type: let colourType): return colourType.colour
        }
    }
    
    init(name: NSAttributedString.Key, value: AttributeValue, range: NSRange) {
        
        self.range = range
        self.name = name
        self.value = value
    }
    
    init(kind: Themer.TextKind, range: NSRange) {
        
        self.range = range
        name = .foregroundColor
        value = .colour(type: .colour(for: kind))
    }
}

struct TimeComponents: Hashable {
    
    let hour: Int
    let minute: Int
    
    var hashValue: Int { return hour.hashValue ^ minute.hashValue }
    
    init(hour: Int, minute: Int) {
        
        self.hour = hour
        self.minute = minute
    }
    
    static func ==(lhs: TimeComponents, rhs: TimeComponents) -> Bool {
        
        return lhs.hour == rhs.hour && lhs.minute == rhs.minute
    }
}
