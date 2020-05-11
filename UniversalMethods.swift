//
//  UniversalMethods.swift
//  Melody
//
//  Created by Ezenwa Okoro on 08/07/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit
import CoreData

class UniversalMethods: NSObject {

    @objc class func addShadow(to view: UIView,
                         radius: CGFloat = 2,
                         colour: UIColor = .black,
                         xOffset: CGFloat = 0,
                         yOffset: CGFloat = 0,
                         opacity: Float = 0.5,
                         path: CGPath? = nil,
                         shouldRasterise: Bool = false,
                         rasterisationScale: CGFloat = UIScreen.main.scale) {
        
        view.layer.masksToBounds = false
        view.layer.shadowColor = colour.cgColor
        view.layer.shadowOffset = CGSize(width: xOffset, height: yOffset)
        view.layer.shadowOpacity = opacity
        view.layer.shadowRadius = radius
        view.layer.shadowPath = path
        view.layer.shouldRasterize = shouldRasterise
        
        if shouldRasterise {
            
            view.layer.rasterizationScale = rasterisationScale
        }
    }
    
    @objc class func performInBackground(_ function: @escaping () -> ()) {
        
        DispatchQueue.global(qos: .background).async(execute: { function() })
    }
    
    ///Performs the passed function on the main thread
    /// - parameter function: the function to be executed.
    @objc class func performInMain(_ function: @escaping () -> ()) {
        
        DispatchQueue.main.async(execute: {
            
            function()
        })
    }
    
    @objc class func performOnMainThread(_ function: @escaping () -> (), afterDelay delay: Double) {
        
        let delayInNanoSeconds = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        let mainQueue = DispatchQueue.main
        
        mainQueue.asyncAfter(deadline: delayInNanoSeconds, execute: {
            
            function()
        })
    }
    
    @objc class func formattedNumber(from number: Int) -> String {
        
        return appDelegate.formatter.numberFormatter.string(from: NSNumber.init(value: number)) ?? "\(number)"
    }
    
    class func performTransitions(withRelevantParameters parameters: (UIView, TimeInterval, () -> (), ((Bool) -> Void)?)...) {
        
        for tuple in parameters {
            
            UIView.transition(with: tuple.0, duration: tuple.1, options: .transitionCrossDissolve, animations: tuple.2, completion: tuple.3)
        }
    }
    
    @objc class func banner(withTitle title: String?, subtitle: String? = nil, image: UIImage? = nil, backgroundColor: UIColor = .black, titleFont: UIFont = .font(ofWeight: .regular, size: 15), subtitleFont: UIFont = .font(ofWeight: .regular, size: 15), didTapBlock: (() -> ())? = nil) -> Banner {
        
        let banner = Banner.init(title: title, subtitle: subtitle, image: image, backgroundColor: backgroundColor, didTapBlock: didTapBlock)
        banner.titleLabel.font = titleFont
        banner.detailLabel.font = subtitleFont
        banner.detailLabel.textColor = Themer.textColour(for: .subtitle)
        
        return banner
    }
    
    @objc class func cancelAlertAction(withTitle title: String = "Cancel", withHandler handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        
        return UIAlertAction.init(title: title, style: .cancel, handler: handler)
    }
    
    class func alertController(withTitle title: String?,
                               message: String?,
                               preferredStyle: UIAlertController.Style,
                               popoverDetails: (rect: CGRect, view: UIView)? = nil,
                               actions: UIAlertAction...) -> UIAlertController {
        
        return alertController(withTitle: title, message: message, preferredStyle: preferredStyle, popoverDetails: popoverDetails, actions: actions)
    }
    
    class func alertController(withTitle title: String?,
                               message: String?,
                               preferredStyle: UIAlertController.Style,
                               popoverDetails: (rect: CGRect, view: UIView)? = nil,
                               actions: [UIAlertAction]) -> UIAlertController {
        
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: preferredStyle)
        
        for action in actions {
            
            alert.addAction(action)
        }
        
        return alert
    }
    
    @objc class func artwork(for item: MPMediaItem?, at size: CGSize) -> UIImage? {
        
        guard let artwork = item?.artwork, artwork.bounds.width != 0 else { return nil }
        
        return artwork.image(at: size)
    }
    
    class func sortableItems(usingPredicates predicates: (property: String, value: CVarArg)...) -> [Sortable] {
        
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest: NSFetchRequest<Sortable> = Sortable.fetchRequest()
        
        for predicate in predicates {
            
            fetchRequest.predicate = NSPredicate.init(format: predicate.property, predicate.value)
        }
        
        do {
            
            let results = try managedContext.fetch(fetchRequest)
            return results
            
        } catch _ {
            
            print("Couldn't obtain Sortable Items with predicates: \(predicates)")
            return []
        }
    }
    
    class func sortableItem(forPersistentID id: UInt64, kind: SortableKind) -> Sortable? {
        
        let managedContext = appDelegate.managedObjectContext
        let actualKind = Int16(kind.rawValue)
        
        let fetchRequest: NSFetchRequest<Sortable> = Sortable.fetchRequest()
        fetchRequest.predicate = NSPredicate.init(format: "persistentID == %@ AND kind == %@", NSNumber.init(value: id), NSNumber.init(value: actualKind))
        
        do {
            
            let results = try managedContext.fetch(fetchRequest)
            
            if let gottenPlaylist = results.first(where: { $0.persistentID?.uint64Value == id && Int($0.kind) == kind.rawValue }) {
                
                return gottenPlaylist
                
            } else {
                
                return nil
            }
            
        } catch _ {
            
            print("Couldn't obtain Sortable Item")
            return nil
        }
    }
    
    class func saveSortableItem(withPersistentID id: MPMediaEntityPersistentID, order: Bool, sortCriteria: SortCriteria, kind: SortableKind) {
        
        let managedContext = appDelegate.managedObjectContext
        
        if let sortable = sortableItem(forPersistentID: id, kind: kind) {
            
            sortable.order = order
            sortable.sort = Int16(sortCriteria.rawValue)
        
        } else {
            
            if let sortableEntity = NSEntityDescription.entity(forEntityName: "Sortable", in: managedContext) {
                
                let sortable = Sortable(entity: sortableEntity, insertInto: managedContext)
                
                sortable.order = order
                sortable.sort = Int16(sortCriteria.rawValue)
                sortable.persistentID = NSNumber.init(value: id)
                sortable.kind = Int16(kind.rawValue)
            }
        }
        
        do {
            
            try managedContext.save()
            
        } catch _ {
            
            print("Couldn't save sortable item")
        }
    }
    
    class func deleteRecentSearches(completions: (succes: (() -> ()), error: (() -> ()))) {
        
        let managedContext = appDelegate.managedObjectContext
        
        let recentSearchFetch: NSFetchRequest<RecentSearch> = RecentSearch.fetchRequest()
        
        do {
            
            let results = try managedContext.fetch(recentSearchFetch)
            
            for result in results {
                
                managedContext.delete(result)
            }
            
            try managedContext.save()
            completions.succes()
            
        } catch _ {
            
            completions.error()
        }
    }
    
//    @objc class func deleteSongs() {
//
//        let managedContext = appDelegate.managedObjectContext
//
//        let songFetch: NSFetchRequest<Song> = Song.fetchRequest()
//
//        do {
//
//            let results = try managedContext.fetch(songFetch)
//
//            for result in results {
//
//                managedContext.delete(result)
//            }
//
//            try managedContext.save()
//
//        } catch _ {
//
//            print("couldn't delete")
//        }
//    }
    
    @objc class func deleteSortableItems() {
        
        let managedContext = appDelegate.managedObjectContext
        
        let fetchRequest: NSFetchRequest<Sortable> = Sortable.fetchRequest()
        
        do {
            
            let results = try managedContext.fetch(fetchRequest)
            
            for sortable in results {
                
                managedContext.delete(sortable)
            }
            
            try managedContext.save()
            
            let newBanner = Banner.init(title: "Saved Playlists Deleted", subtitle: nil, image: nil, backgroundColor: .azure, didTapBlock: nil)
            newBanner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
            newBanner.show(duration: 0.7)
            
        } catch _ {
            
            print("Couldn't delete sortable items")
        }
    }
    
    class func addToLibrary(_ item: MPMediaItem?, completions: Completions, sameSongAction: ((Bool) -> Void)? = nil) {
        
        guard let item = item, item.existsInLibrary.inverted/*persistentID = item?.persistentID, let items = MPMediaQuery.init(filterPredicates: [.for(.song, using: persistentID)]).items, items.isEmpty*/ else {
            
            let banner = Banner.init(title: "This song is already in your library", subtitle: nil, image: nil, backgroundColor: .deepGreen, didTapBlock: nil)
            banner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
            banner.show(duration: 0.5)
            completions.success()
            
            return
        }
        
        let banner = Banner.init(title: "Searching Apple Music...", subtitle: nil, image: nil, backgroundColor: .azure, didTapBlock: nil)
        banner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
        banner.show()
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        guard /*let item = item, */let songName = item.title, songName.isEmpty.inverted, let artist = item.artist, artist.isEmpty.inverted, let identifier = appDelegate.storeIdentifier else {
            
            let newBanner = Banner.init(title: "An error occurred", subtitle: nil, image: nil, backgroundColor: .red, didTapBlock: nil)
            newBanner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
            newBanner.show(duration: 0.5)
            completions.error()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            return
        }
        
        let iTunesTerm = songName.replacingOccurrences(of: " ", with: "+") + "+" + artist.replacingOccurrences(of: " ", with: "+")
        let path = "https://itunes.apple.com/search?term=\(iTunesTerm)&s=\(identifier)&entity=song"
        let trialURL = URL.init(string: path)
        
        guard let url = trialURL else {
            
            let newBanner = Banner.init(title: "An error occurred", subtitle: nil, image: nil, backgroundColor: .red, didTapBlock: nil)
            newBanner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
            newBanner.show(duration: 0.5)
            completions.error()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            
            return
        }
        
        let request = URLRequest.init(url: url)
        let conn = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            guard let obtainedData = data else {
                
                let newBanner = Banner.init(title: "An error occurred", subtitle: nil, image: nil, backgroundColor: .red, didTapBlock: nil)
                newBanner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
                newBanner.show(duration: 0.5)
                completions.error()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                return
            }
            
            do {
                
                if let json = try JSONSerialization.jsonObject(with: obtainedData, options: .mutableContainers) as? [String: Any], let results = json["results"] as? [[String: Any]], let result = results.first(where: { result in ((result["trackName"] as? String) == item.title || (result["trackCensoredName"] as? String) == item.title) && result["artistName"] as? String == item.artist && result["collectionName"] as? String == item.albumTitle }), let trackID = result["trackId"] as? NSNumber {
                    
                    UniversalMethods.performInMain {
                        
                        banner.dismiss()
                        
                        musicLibrary.addItem(withProductID: trackID.stringValue, completionHandler: { items, error in
                            
                            if error == nil {
                                
                                let sameSong: Bool = {
                                    
                                    guard !items.isEmpty else { return false }
                                    
                                    return items.first?.persistentID == item.persistentID
                                }()
                                
                                UniversalMethods.performInMain {
                                    
                                    let newBanner = Banner.init(title: sameSong ? "Added song to library" : "Added duplicate song to library", subtitle: nil, image: nil, backgroundColor: sameSong ? .deepGreen : .orange, didTapBlock: nil)
                                    newBanner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
                                    newBanner.show(duration: sameSong ? 0.5 : 1)
                                    
                                    if let sameSongAction = sameSongAction {
                                        
                                        sameSongAction(sameSong)
                                    }
                                    
                                    completions.success()
                                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                }
                                
                            } else {
                                
                                UniversalMethods.performInMain {
                                    
                                    let newBanner = Banner.init(title: "Unable to add song to library", subtitle: error?.localizedDescription, image: nil, backgroundColor: .red, didTapBlock: nil)
                                    newBanner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
                                    newBanner.detailLabel.font = UIFont.font(ofWeight: .regular, size: 15)
                                    newBanner.show(duration: 0.5)
                                    
                                    completions.error()
                                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                }
                            }
                        })
                    }
                    
                } else {
                    
                    UniversalMethods.performInMain {
                        
                        let newBanner = Banner.init(title: "Couldn't obtain song information from Apple Music", subtitle: nil, image: nil, backgroundColor: .red, didTapBlock: nil)
                        newBanner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
                        newBanner.show(duration: 0.5)
                        
                        banner.dismiss()
                        completions.error()
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                }
                
            } catch let error {
                
                UniversalMethods.performInMain {
                    
                    let newBanner = Banner.init(title: "Couldn't obtain song information from Apple Music", subtitle: error.localizedDescription, image: nil, backgroundColor: .red, didTapBlock: nil)
                    newBanner.titleLabel.font = UIFont.font(ofWeight: .regular, size: 15)
                    newBanner.detailLabel.font = UIFont.font(ofWeight: .regular, size: 15)
                    newBanner.show(duration: 0.5)
                    
                    banner.dismiss()
                    completions.error()
                    
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }
        
        conn.resume()
    }
    
    @available(iOS 10.3, *)
    class func add(_ item: MPMediaItem, completions: Completions) {
        
        guard !item.existsInLibrary else {
            
            UniversalMethods.banner(withTitle: "This song is already in your library").show(for: 0.7)
            return
        }
        
        musicLibrary.addItem(withProductID: item.playbackStoreID, completionHandler: { _, error in
            
            UniversalMethods.performInMain {
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                if error == nil {
                    
                    UniversalMethods.banner(withTitle: "Added \(item.validTitle) to library").show(for: 0.7)
                    completions.success()
                    
                } else {
                    
                    UniversalMethods.banner(withTitle: "Unable to add \(item.validTitle) to library", backgroundColor: .red).show(for: 0.7)
                    completions.error()
                }
            }
        })
    }
    
    @objc class func rate(_ item: MPMediaItem?, in view: UIStackView, with gr: UIPanGestureRecognizer) {
        
        guard let imageViews = view.arrangedSubviews as? [UIImageView], let item = item else { return }
        
        switch gr.state {
            
            case .began, .changed:
            
                for imageView in imageViews {
                    
                    if gr.location(in: view).x >= imageView.frame.origin.x {
                        
                        imageView.image = #imageLiteral(resourceName: "StarFilled17")
                        
                    } else {
                        
                        imageView.image = #imageLiteral(resourceName: "Dot")
                    }
                }
            
            case .ended:
            
                let rating = imageViews.filter({ $0.image == #imageLiteral(resourceName: "StarFilled17") }).count
            
                guard item.rating != rating else { return }
            
                item.set(property: MPMediaItemPropertyRating, to: rating)
            
                notifier.post(name: .ratingChanged, object: nil, userInfo: [String.id: item.persistentID, String.sender: view])
            
            default: break
        }
    }
    
    class func setRadiusType(for layer: CALayer) {
        
        let string = String.init(format: "%@%@%@%@", "conti", "nuous", "Cor", "ners")
        let sel = NSSelectorFromString(string)
        
        guard layer.responds(to: sel) else { return }
        
        layer.setValue(true, forKey: string)
    }
}
