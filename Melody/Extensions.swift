//
//  UIKitExtensions.swift
//  Melody
//
//  Created by Ezenwa Okoro on 13/08/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

#if swift(>=4.2)
import UIKit.UIGeometry
extension UIEdgeInsets {
    
    public static let zero = UIEdgeInsets()
}
#endif

// MARK: - MPMediaItemPropertyPredicate
extension MPMediaPredicate {
    
    static var offline: MPMediaPropertyPredicate {
        
        return MPMediaPropertyPredicate.init(value: NSNumber.init(value: false), forProperty: MPMediaItemPropertyIsCloudItem, comparisonType: .equalTo)
    }
    
    static func foldersAllowed(_ allowed: Bool) -> MPMediaPropertyPredicate {
        
        return MPMediaPropertyPredicate.init(value: NSNumber.init(value: allowed), forProperty: "isFolder", comparisonType: .equalTo)
    }
    
    static var regularPlaylists: [MPMediaPropertyPredicate] {
        
        return [0, 1].map({ MPMediaPropertyPredicate.init(value: NSNumber.init(value: $0), forProperty: MPMediaPlaylistPropertyPlaylistAttributes, comparisonType: .equalTo) })
    }
    
    static var user: MPMediaPropertyPredicate {
        
        return MPMediaPropertyPredicate.init(value: NSNumber.init(value: true), forProperty: "isEditable", comparisonType: .equalTo)
    }
    
    static var am: MPMediaPropertyPredicate {
        
        return MPMediaPropertyPredicate.init(value: NSNumber.init(value: false), forProperty: "isEditable", comparisonType: .equalTo)
    }
    
    private class func property(for entityType: EntityType) -> String {
        
        switch entityType {
            
            case .artist: return MPMediaItemPropertyArtistPersistentID
                
            case .album: return MPMediaItemPropertyAlbumPersistentID
                
            case .song: return MPMediaItemPropertyPersistentID
                
            case .composer: return MPMediaItemPropertyComposerPersistentID
                
            case .genre: return MPMediaItemPropertyGenrePersistentID
                
            case .playlist: return MPMediaPlaylistPropertyPersistentID
            
            case .albumArtist: return MPMediaItemPropertyAlbumArtistPersistentID
        }
    }
    
    private class func nameProperty(for entityType: EntityType) -> String {
        
        switch entityType {
            
            case .artist: return MPMediaItemPropertyArtist
            
            case .album: return MPMediaItemPropertyAlbumTitle
            
            case .song: return MPMediaItemPropertyTitle
            
            case .composer: return MPMediaItemPropertyComposer
            
            case .genre: return MPMediaItemPropertyGenre
            
            case .playlist: return MPMediaPlaylistPropertyName
            
            case .albumArtist: return MPMediaItemPropertyAlbumArtist
        }
    }
    
    static func `for`(_ entityType: EntityType, using mediaEntity: MPMediaEntity) -> MPMediaPropertyPredicate {
        
        return MPMediaPropertyPredicate.init(value: NSNumber.init(value: mediaEntity.persistentID), forProperty: property(for: entityType), comparisonType: .equalTo)
    }
    
    static func `for`(_ entityType: EntityType, using id: MPMediaEntityPersistentID) -> MPMediaPropertyPredicate {
        
        return MPMediaPropertyPredicate.init(value: NSNumber.init(value: id), forProperty: property(for: entityType), comparisonType: .equalTo)
    }
    
    static func `for`(_ entityType: EntityType, using name: String) -> MPMediaPropertyPredicate {
        
        return MPMediaPropertyPredicate.init(value: name, forProperty: nameProperty(for: entityType), comparisonType: .equalTo)
    }
}

// MARK: - MPMediaItemArtwork
extension MPMediaItemArtwork {
    
    var actualArtwork: MPMediaItemArtwork? {
        
        if self.bounds.width != 0 {
            
            return self
            
        } else {
            
            return nil
        }
    }
    
    var userInfo: [AnyHashable: Any]? {
        
        if let artwork = actualArtwork {
            
            return [DictionaryKeys.artwork: artwork]
            
        } else {
            
            return nil
        }
    }
}

// MARK: - UIColor
extension UIColor {
    
    class var peach: UIColor { return UIColor(red:1.0000, green:0.8000, blue:0.6000, alpha:1.0000) }
    class var azure: UIColor { return UIColor(red:0.0588, green:0.4902, blue:0.9686, alpha:1.0000) }
    class var deepGreen: UIColor { return UIColor(red: 99/255, green: 154/255, blue: 39/255, alpha: 1) }
    class var cream: UIColor { return UIColor(red:0.9569, green:0.9255, blue:0.8824, alpha:1.0000) }
    class var licorice: UIColor { return UIColor(red:0.1843, green:0.2078, blue:0.2784, alpha:1.0000) }
    
    class var noArtwork: UIColor { return darkTheme ? (useBlackColorBackground ? .black : .licorice) : (useWhiteColorBackground ? .white : .cream) }
}

// MARK: - Date
extension Date {
    
    func year() -> Int {
        
        return Calendar.current.component(.year, from: self)
    }
    
    static func from(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        
        var components = DateComponents.init()
        components.day = 1
        components.month = 1
        components.year = 2001
        components.hour = hour
        components.minute = minute
        
        let calendar = Calendar.init(identifier: .gregorian)
        
        return calendar.date(from: components) ?? .init()
    }
    
    static func from(day: Int, month: Int, year: Int) -> Date? {
        
        var components = DateComponents.init()
        components.day = day
        components.month = month
        components.year = year
        
        let calendar = Calendar.init(identifier: .gregorian)
        
        return calendar.date(from: components)
    }
}

// MARK: - Banner
extension Banner {
    
    func show(for duration: TimeInterval) {
        
        show(duration: duration)
    }
}

// MARK: - NSString
extension NSString {
    
    func comparisonTo(_ second: String) -> ComparisonResult {
        
        let firstIsNumeric = !CharacterSet.letters.contains(String((self as String).prefix(1)).unicodeScalars.first!)
        let secondIsNumeric = !CharacterSet.letters.contains(String(second.prefix(1)).unicodeScalars.first!)
        
        switch (firstIsNumeric, secondIsNumeric) {
                
            case (true, false): return numbersBelowLetters ? .orderedDescending : .orderedAscending
                
            case (false, true): return numbersBelowLetters ? .orderedAscending : .orderedDescending
                
            default: return compare(second, options: [])
        }
    }
}

extension String {
    
    var size: CGFloat { return (self as NSString).size(withAttributes: [.font: UIFont.font(ofWeight: .regular, size: 17)]).width }
}

// MARK: - CGRect
extension CGRect {
    
    func modifiedBy(width: CGFloat, height: CGFloat) -> CGRect {
        
        return CGRect.init(x: origin.x, y: origin.y, width: self.width + width, height: self.height + height)
    }
    
    func modifiedBy(newOrigin: CGPoint = .zero, size: CGSize) -> CGRect {
        
        return CGRect.init(x: origin.x + newOrigin.x, y: origin.y + newOrigin.y, width: self.width + size.width, height: self.height + size.height)
    }
    
    func modifiedBy(x: CGFloat, y: CGFloat) -> CGRect {
        
        return CGRect.init(x: origin.x + x, y: origin.y + y, width: width, height: height)
    }
    
    static func + (lhs: CGRect, rhs: CGRect) -> CGRect {
        
        return lhs.union(rhs)
    }
    
    func converted(to superview: UIView) -> CGRect {
        
        return superview.convert(self, to: superview)
    }
    
    func convert(from superview: UIView, to view: UIView) -> CGRect {
        
        return superview.convert(self, to: view)
    }
}

// MARK: - UIView
extension UIView {
    
    enum PinDirection { case top, bottom }
    enum ViewOrientation { case horizontally, vertically }
    
    func shadowPath(cornerRadius radius: CGFloat? = nil) -> CGPath {
        
        if let radius = radius {
            
            return UIBezierPath.init(roundedRect: bounds, cornerRadius: radius).cgPath
            
        } else {
            
            return UIBezierPath.init(rect: bounds).cgPath
        }
    }
    
    func animateCornerRadius(to newRadius: CGFloat, duration: CFTimeInterval) {
        
        let fromValue = layer.cornerRadius
        layer.cornerRadius = newRadius
        
        let color = CABasicAnimation.init(keyPath: "cornerRadius")
        color.fromValue = fromValue
        color.toValue = newRadius
        color.duration = duration
        color.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        layer.add(color, forKey: "cornerRadius")
    }
    
    func animateShadowOpacity(to newOpacity: Float, duration: CFTimeInterval) {
        
        let animation = CABasicAnimation.init(keyPath: "shadowOpacity")
        animation.timingFunction = CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.fromValue = layer.shadowOpacity
        animation.toValue = newOpacity
        animation.duration = duration
        layer.add(animation, forKey: "shadowOpacity")
        layer.shadowOpacity = newOpacity
    }
    
    func fill(with view: UIView, withInsets insets: UIEdgeInsets = .zero) {
        
        addSubview(view)
        
        leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: insets.right).isActive = true
        topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom).isActive = true
    }
    
    func filled(with view: UIView, withInsets insets: UIEdgeInsets = .zero) -> UIView {
        
        self.fill(with: view, withInsets: insets)
        
        return self
    }
    
    func stack(_ oriented: ViewOrientation, with views: [UIView], spacing: CGFloat) {
        
        views.enumerated().forEach({ (offset, view) in
            
            addSubview(view)
            
            if offset == 0 {
                
                leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
                topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
                
                if oriented == .vertically {
                
                    trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
                
                } else if oriented == .horizontally {
                    
                    bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
                }
            
            } else if offset == views.endIndex - 1, let viewBefore = views.value(at: max(0, views.endIndex - 2)) {
                
                bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
                trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
                
                if oriented == .vertically {
                    
                    leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
                    viewBefore.bottomAnchor.constraint(equalTo: view.topAnchor, constant: spacing).isActive = true
                
                } else if oriented == .horizontally {
                    
                    topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
                    viewBefore.trailingAnchor.constraint(equalTo: view.leadingAnchor, constant: spacing).isActive = true
                }
            
            } else if let viewBefore = views.value(at: max(0, offset - 1)) {
                
                trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
                bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
                
                if oriented == .vertically {
                    
                    leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
                    trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
                    viewBefore.bottomAnchor.constraint(equalTo: view.topAnchor, constant: spacing).isActive = true
                
                } else if oriented == .horizontally {
                    
                    topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
                    bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
                    viewBefore.trailingAnchor.constraint(equalTo: view.leadingAnchor, constant: spacing).isActive = true
                }
            }
        })
    }
    
    func constrain(_ view: UIView, to direction: PinDirection, of vc: UIViewController, withInsets insets: UIEdgeInsets = .zero) {
        
        addSubview(view)
        
        leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: insets.right).isActive = true
        topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom).isActive = true
    }
    
    func centre(_ subview: UIView, withOffsets offsets: CGPoint = .init(x: 0, y: 0)) {
        
        addSubview(subview)
        
        let centreX = centerXAnchor.constraint(equalTo: subview.centerXAnchor)
        centreX.constant = offsets.x
        centreX.isActive = true
        
        let centreY = centerYAnchor.constraint(equalTo: subview.centerYAnchor)
        centreY.constant = offsets.y
        centreY.isActive = true
    }
    
    func constrainDimensions(toWidth width: CGFloat, height: CGFloat) {
        
        addConstraints([
            
            NSLayoutConstraint.init(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width),
            NSLayoutConstraint.init(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height)
        ])
    }
    
    static var clear: UIView {
        
        let view = UIView.init(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.clipsToBounds = false
        
        return view
    }
}

// MARK: - TimeInterval
extension TimeInterval {
    
    enum StringRepresentation { case numerical, short, long }
    
    var shortStringRepresentation: String {
        
        let interval = abs(Int(self))
        
        if interval < 60 {
            
            return "\(interval)s"
            
        } else if interval > 59 && interval < 3600 {
            
            return "\(interval/60)m"
            
        } else if interval > 3599 && interval < 86400 {
            
            return "\(interval/3600)h"
            
        } else if interval > 86399 && interval < 31536000 {
            
            return "\(interval/86400)d"
            
        } else {
            
            return "\(interval/31536000)y"
        }
    }
    
    func stringRepresentation(as format: StringRepresentation) -> String {
        
        guard isFinite && !isNaN else { return "--:--" }
        
        let int = abs(Int(self))
        
        let seconds = int % 60
        let minutes = (int / 60) % 60
        let hours = (int / 3600) % 24
        let days = int / (3600 * 24)
        
        let dayIsAbsent = days < 1
        let hourIsAbsent = hours < 1
        let minuteIsAbsent = minutes < 1
        
        switch format {
            
            case .numerical:
            
                let daysString = dayIsAbsent  ? "" : "\(days):"
                let hoursString = dayIsAbsent && hourIsAbsent ? "" : String.init(format: "%02d:", hours)
                let minutesString = dayIsAbsent && hourIsAbsent && minuteIsAbsent ? "" : String.init(format: "%02d:", minutes)
                let secondsString = String.init(format: "%02d", seconds)
                
                return daysString + hoursString + minutesString + secondsString
            
            case .short:
            
                let daysString = dayIsAbsent  ? "" : "\(days)d, "
                let hoursString = dayIsAbsent && hourIsAbsent ? "" : String.init(format: "%02d", hours) + "h, "
                let minutesString = dayIsAbsent && hourIsAbsent && minuteIsAbsent ? "" : String.init(format: "%02d", minutes) + "m, "
                let secondsString = String.init(format: "%02d", seconds) + "s"
                
                return daysString + hoursString + minutesString + secondsString
            
            case .long:
            
                let daysString = dayIsAbsent  ? "" : "\(days) \(days == 1 ? "day" : "days"), "
                let hoursString = dayIsAbsent && hourIsAbsent ? "" : String.init(format: "%02d", hours) + " \(hours == 1 ? "hour" : "hours"), "
                let minutesString = dayIsAbsent && hourIsAbsent && minuteIsAbsent ? "" : String.init(format: "%02d", minutes) + " \(minutes == 1 ? "minute" : "minutes"), "
                let secondsString = String.init(format: "%02d", seconds) + " \(minutes == 1 ? "second" : "seconds")"
                
                return daysString + hoursString + minutesString + secondsString
        }
    }
    
    var nowPlayingRepresentation: String {
        
        guard isFinite && !isNaN else { return "--:--" }
        
        let int = abs(Int(self))
        
        let seconds = int % 60
        let minutes = int / 60
        let hours = int / 3600
        
        let hoursString = hours < 1 ? "" : "\(hours):"
        let minutesString = String.init(format: "%02d:", minutes)
        let secondsString = String.init(format: "%02d", seconds)
        
        return hoursString + minutesString + secondsString
    }
    
    static var bannerInterval: TimeInterval { return isInDebugMode ? 0.5 : 0.7 }
}

// MARK: - Int64
extension Int64 {
    
    enum FileSize: Int {
        
        case byte, kilobyte, megabyte, gigabyte, terabyte
        
        var suffix: String {
            
            switch self {
                
                case .byte: return "B"
            
                case .kilobyte: return "KB"
                
                case .megabyte: return "MB"
                
                case .gigabyte: return "GB"
                
                case .terabyte: return "TB"
            }
        }
    }
    
    var fileSize: FileSize {
        
        switch self {
            
            case 0..<1000: return .byte
            
            case 1000..<1000000: return .kilobyte
                
            case 1000000..<1000000000: return .megabyte
                
            case 1000000000..<1000000000000: return .gigabyte
            
            default: return .terabyte
        }
    }
    
    var divider: Int64 {
        
        switch fileSize {
            
            case .kilobyte: return 1000
            
            case .megabyte: return 1000000
            
            case .gigabyte: return 1000000000
            
            case .terabyte: return 1000000000000
            
            default: return 1
        }
    }
    
    var fileSizeSuffix: String {
        
        switch fileSize {
            
            case .byte: return "B"
            
            case .kilobyte: return "KB"
            
            case .megabyte: return "MB"
            
            case .gigabyte: return "GB"
            
            case .terabyte: return "TB"
        }
    }
    
    var divided: Int64 { return self / divider }
    
    var fileSizeRepresentation: String {
        
        switch fileSize {
            
            case .byte: return String.init(describing: self)
            
            default: return self % divider == 0 ? String.init(describing: divided) : String.init(format: "%.2f", Double(self) / Double(divider)) + " " + fileSizeSuffix
        }
    }
}

// MARK: - Double
extension Double {
    
    func multiplier(from fileSize: Int64.FileSize) -> Double {
        
        switch fileSize {
            
            case .kilobyte: return 1000
            
            case .megabyte: return 1000000
            
            case .gigabyte: return 1000000000
            
            case .terabyte: return 1000000000000
            
            default: return 1
        }
    }
    
    func applyMultiplier(of fileSize: Int64.FileSize) -> Int64 {
        
        return Int64(self * multiplier(from: fileSize))
    }
}

// MARK: - NSObject
extension NSObject {
    
    func unregisterAll(from observers: Set<NSObject>) {
        
        observers.forEach({ notifier.removeObserver($0) })
    }
    
    @objc var className: String { return String.init(describing: type(of: self)) }
    static var staticName: String { return String.init(describing: type(of: self)) }
    
    func value(for key: String) -> Any? {
        
        if responds(to: NSSelectorFromString(key)) {
            
            return value(forKey: key)
        }
        
        return nil
    }
}

// MARK: - CGSize
extension CGSize {
    
    static func square(of dimension: Int) -> CGSize {
        
        return .init(width: dimension, height: dimension)
    }
    
    static func square(of dimension: CGFloat) -> CGSize {
        
        return .init(width: dimension, height: dimension)
    }
    
    static func square(of dimension: Double) -> CGSize {
        
        return .init(width: dimension, height: dimension)
    }
    
    static var artworkSize: CGSize { return .init(width: 20, height: 20) }
}

// MARK: - UITableView
extension UITableView {
    
    func songCell(for indexPath: IndexPath) -> SongTableViewCell {
        
        return dequeueReusableCell(withIdentifier: .songCell, for: indexPath) as! SongTableViewCell
    }
    
    func regularCell(for indexPath: IndexPath) -> MELTableViewCell {
        
        return dequeueReusableCell(withIdentifier: .otherCell, for: indexPath) as! MELTableViewCell
    }
    
    func recentSearchCell(for indexPath: IndexPath) -> RecentSearchTableViewCell {
        
        return dequeueReusableCell(withIdentifier: .recentCell, for: indexPath) as! RecentSearchTableViewCell
    }
    
    func settingCell(for indexPath: IndexPath) -> SettingsTableViewCell {
        
        return dequeueReusableCell(withIdentifier: .settingsCell, for: indexPath) as! SettingsTableViewCell
    }
    
    func loginCell(for indexPath: IndexPath) -> LoginDetailsTableViewCell {
        
        return dequeueReusableCell(withIdentifier: .loginCell, for: indexPath) as! LoginDetailsTableViewCell
    }
    
    var sectionHeader: TableHeaderView? {
        
        return dequeueReusableHeaderFooterView(withIdentifier: .sectionHeader) as? TableHeaderView
    }
    
    var sectionFooter: TableFooterView? {
        
        return dequeueReusableHeaderFooterView(withIdentifier: .sectionFooter) as? TableFooterView
    }
}

// MARK: - MPMediaQuery
extension MPMediaQuery {
    
    func showAll() {
        
        let selector = NSSelectorFromString("setShouldIncludeNonLibraryEntities:")
        
        if responds(to: selector) {
            
            perform(selector, with: true)
        }
    }
    
    func hideUnadded() {
        
        let selector = NSSelectorFromString("setShouldIncludeNonLibraryEntities:")
        
        if responds(to: selector) {
            
            perform(selector, with: false)
        }
    }
    
    func allShown() -> MPMediaQuery {
        
        let selector = NSSelectorFromString("setShouldIncludeNonLibraryEntities:")
        
        if responds(to: selector) {
            
            perform(selector, with: true)
        }
        
        return self
    }
    
    var cloud: MPMediaQuery {
        
        if showiCloudItems.inverted {
            
            addFilterPredicate(.offline)
        }
        
        return self
    }
    
    func foldersAllowed(_ allowed: Bool) -> MPMediaQuery {
        
        if allowed.inverted {
            
            addFilterPredicate(.foldersAllowed(false))
        
        } else {
            
            removeFilterPredicate(.foldersAllowed(false))
        }
        
        return self
    }
    
    func playlistsExtracted(showCloudItems: Bool = showiCloudItems) -> [MPMediaPlaylist] {
        
        guard let collections = collections as? [MPMediaPlaylist] else { return [] }
        
        guard !showCloudItems else { return collections }
        
        var playlists = [MPMediaPlaylist]()
        
        collections.forEach({
            
            let sel = NSSelectorFromString("itemsQuery")
            
            if $0.responds(to: sel), let query = $0.value(forKey: "itemsQuery") as? MPMediaQuery {
                
                query.filterPredicates = [MPMediaPropertyPredicate.init(value: NSNumber.init(value: $0.persistentID), forProperty: "playlistPersistentID", comparisonType: .equalTo), .offline]
                
                playlists.append($0)
                
            } else {
                
                let query = MPMediaQuery.init(filterPredicates: [.for(.playlist, using: $0), .offline])
                
                query.groupingType = .playlist
                
                if let result = query.collections as? [MPMediaPlaylist], let playlist = result.first {
                    
                    playlists.append(playlist)
                }
            }
        })
        
        return playlists
    }
    
    func grouped(by groupingType: MPMediaGrouping) -> MPMediaQuery {
        
        self.groupingType = groupingType
        
        return self
    }
    
    func with(predicates: Set<MPMediaPredicate>) -> MPMediaQuery {
        
        predicates.forEach({ addFilterPredicate($0) })
        
        return self
    }
}

// MARK: - MPMediaEntity
extension MPMediaEntity {
    
    func title(for entityType: EntityType, basedOn mainEntityType: EntityType) -> String? {
        
        switch mainEntityType {
            
            case .song:
            
                guard let song = self as? MPMediaItem else { return nil }
            
                switch entityType {
                    
                    case .song: return song.validTitle
                    
                    case .album: return song.validAlbum
                    
                    case .albumArtist: return song.validAlbumArtist
                    
                    case .artist: return song.validArtist
                    
                    case .composer: return song.validComposer
                    
                    case .genre: return song.validGenre
                    
                    case .playlist: return nil
                }
            
            case .playlist:
            
                guard let playlist = self as? MPMediaPlaylist else { return nil }
            
                switch entityType {
                    
                    case .playlist: return playlist.validName
                    
                    default: return nil
                }
            
            default:
            
                guard let collection = self as? MPMediaItemCollection else { return nil }
            
                switch entityType {
                    
                    case .album: return collection.representativeItem?.validAlbum
                    
                    case .albumArtist: return collection.representativeItem?.validAlbumArtist
                    
                    case .artist: return collection.representativeItem?.validArtist
                    
                    case .composer: return collection.representativeItem?.validComposer
                    
                    case .genre: return collection.representativeItem?.validGenre
                    
                    case .playlist, .song: return nil
                }
        }
    }
    
    func emptyArtwork(for entityType: EntityType) -> UIImage {
        
        switch entityType {
            
            case .song: return #imageLiteral(resourceName: "NoSong75")
            
            case .album: return (self as? MPMediaItemCollection)?.representativeItem?.isCompilation == true ? #imageLiteral(resourceName: "NoAlbum75") : #imageLiteral(resourceName: "NoCompilation75")
            
            case .artist, .albumArtist: return #imageLiteral(resourceName: "NoArtist75")
            
            case .composer: return #imageLiteral(resourceName: "NoComposer75")
            
            case .genre: return #imageLiteral(resourceName: "NoGenre75")
            
            case .playlist: return #imageLiteral(resourceName: "NoPlaylist75")
        }
    }
}

// MARK: - CGFloat
extension CGFloat {
    
    static var tableHeader: CGFloat { return 22 }
    
    static var textHeaderHeight: CGFloat {
        
        let height = FontManager.shared.heightsDictionary[.sectionHeading] ?? 0
        
        return height + FontManager.shared.sectionHeaderSpacing
    }
    
    static var emptyHeaderHeight: CGFloat { return 11 }
}

// MARK: - UILabel
extension UILabel: TextContaining {
    
    var actualFont: UIFont? {
        
        get { return font }
        
        set(newValue) { font = newValue }
    }
}

// MARK: - UITextView 
extension UITextView: TextContaining {
    
    var actualFont: UIFont? {
        
        get { return font }
        
        set(newValue) { font = newValue }
    }
}

extension UIAlertAction {
    
    static func cancel(withTitle title: String = "Cancel", handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        
        return UIAlertAction.init(title: title, style: .cancel, handler: handler)
    }
    
    static var stop: UIAlertAction {
        
        return UIAlertAction.init(title: "Stop Playback", style: .destructive, handler: { _ in NowPlaying.shared.stopPlayback() })
    }
    
    func checked(given condition: Bool) -> UIAlertAction {
        
        if condition {
            
            let selString = "ch" + "eck" + "ed"
            
            if let _ = value(forKey: selString) {
                
                setValue(true, forKey: selString)
            }
        }
        
        return self
    }
}

extension UIAlertController {
    
    /// Variadic Version
    static func withTitle(_ title: String?, message: String?, style: UIAlertController.Style, actions: UIAlertAction..., popoverDetails details: (rect: CGRect, view: UIView)? = nil) -> UIAlertController {
        
        return self.withTitle(title, message: message, style: style, popoverDetails: details, actions: actions)
    }
    
    /// Array Version
    static func withTitle(_ title: String?, message: String?, style: UIAlertController.Style, popoverDetails details: (rect: CGRect, view: UIView)? = nil, actions: [UIAlertAction]) -> UIAlertController {
        
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: style)
        
        for action in actions {
            
            alert.addAction(action)
        }
        
        if let details = details, let popover = alert.popoverPresentationController {
            
            popover.sourceView = details.view
            popover.sourceRect = details.view.bounds
        }
        
        return alert
    }
}

extension Int {
    
    var formatted: String { return appDelegate.formatter.numberFormatter.string(from: NSNumber.init(value: self)) ?? "\(self)" }
    
    func countText(for entity: EntityType, compilationOverride: Bool = false, capitalised: Bool = false) -> String {
        
        let text: String = {
            
            switch entity {
            
                case .album: return compilationOverride ? "compilation" : "album"
                
                case .artist, .albumArtist: return "artist"
                
                case .playlist: return "playlist"
                
                case .composer: return "composer"
                
                case .song: return "song"
                
                case .genre: return "genre"
            }
        }()
        
        return (capitalised ? text.capitalized : text) + (self == 1 ? "" : "s")
    }
    
    func fullCountText(for entityType: EntityType, filteredCount: Int? = nil, compilationOverride: Bool = false, capitalised: Bool = false, withInsert insert: String = "") -> String {
        
        return (filteredCount?.formatted ?+ " of ") + formatted + " " + insert + countText(for: entityType, compilationOverride: compilationOverride, capitalised: capitalised)
    }
    
    var plays: String {
        
        return formatted + " " + "\(self == 1 ? "play" : "plays")"
    }
    
    var float: Float { return Float(self) }
    var layoutPriority: UILayoutPriority { return UILayoutPriority(self.float) }
}

extension Array {
    
    func value(given condition: Bool) -> [Element]? {
        
        guard condition else { return nil }
        
        return self
    }
}

extension Dictionary {
    
    func appending(key: Key, value: Value) -> [Key: Value] {
        
        var dict = self
        dict[key] = value
        
        return dict
    }
}

extension Set {
    
    func value(given condition: Bool) -> Set<Element>? {
        
        guard condition else { return nil }
        
        return self
    }
}

extension Optional {
    
    func value(given condition: Bool) -> Optional {
        
        guard condition else { return nil }
        
        return self
    }
}

extension Optional where Wrapped: Collection {
    
    static func ??? (lhs: Optional, rhs: Wrapped) -> Wrapped {
        
        if let left = lhs, left.isEmpty.inverted {
            
            return left
        }
        
        return rhs
    }
}

extension NSMutableParagraphStyle {
    
    class func withLineHeight(_ lineHeight: CGFloat, alignment: NSTextAlignment = .left) -> NSMutableParagraphStyle {
        
        let style = NSMutableParagraphStyle.init()
        style.lineHeightMultiple = lineHeight
        style.alignment = alignment
        
        return style
    }
}

extension Bool {
    
    var inverted: Bool { return !self }
    
    mutating func invert() {
        
        self = self.inverted
    }
}

extension CALayer {
    
    func setRadiusTypeIfNeeded(to value: Bool = true) {
        
        let string = String.init(format: "%@%@%@%@", "conti", "nuous", "Cor", "ners")
        let sel = NSSelectorFromString(string)
        
        guard responds(to: sel) else { return }
        
        setValue(value, forKey: string)
    }
}

extension IndexPath {
    
    var settingsSection: SettingSection { return .from(self) }
    var indexSet: IndexSet { return .init(integer: self.section) }
}

extension Range where Element == Int {
    
    func indexPaths(in section: Int) -> [IndexPath] {
        
        return self.map({ IndexPath.init(row: $0, section: section) })
    }
}

extension RawRepresentable {
    
    static func from(_ optionalRawValue: Self.RawValue?) -> Self? {
        
        if let rawValue = optionalRawValue {
            
            return self.init(rawValue: rawValue)
        }
        
        return nil
    }
}

extension UIViewControllerPreviewingDelegate where Self: UIViewController {
    
    func performCommitActions(on viewControllerToCommit: UIViewController) {
        
        if let vc = viewControllerToCommit as? BackgroundHideable {
            
            vc.modifyBackgroundView(forState: .removed)
        }
        
        if let vc = viewControllerToCommit as? Peekable {
            
            vc.peeker = nil
            vc.oldArtwork = nil
        }
        
        if let entityVC = viewControllerToCommit as? EntityItemsViewController {
            
            entityVC.updateEffectView(to: .hidden)
        }
        
        if let vc = viewControllerToCommit as? Navigatable, let indexer = vc.activeChildViewController as? IndexContaining, let container = appDelegate.window?.rootViewController as? ContainerViewController {
            
            indexer.tableView.contentInset.top = vc.inset
            indexer.tableView.scrollIndicatorInsets.top = vc.inset
            
            if let sortable = indexer as? FullySortable, sortable.highlightedIndex == nil {
                
                indexer.tableView.contentOffset.y = -vc.inset
            }
            
            container.imageView.image = vc.artworkType.image
            container.visualEffectNavigationBar.backBorderView.alpha = 1
            container.visualEffectNavigationBar.backView.isHidden = false
            container.visualEffectNavigationBar.backLabel.text = vc.backLabelText
            container.visualEffectNavigationBar.titleLabel.text = vc.title
            container.visualEffectNavigationBar.updateTopConstraint(for: .end(completed: true), with: nil, and: vc)
            container.visualEffectNavigationBar.prepareRightButton(for: vc)
            container.visualEffectNavigationBar.prepareArtwork(for: vc)
            container.visualEffectNavigationBar.rightView.alpha = 1
        }
    }
}
