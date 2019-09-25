
//  AppDelegate.swift
//  Melody
//
//  Created by Ezenwa Okoro on 06/07/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit
import StoreKit
import CoreData

let appDelegate = UIApplication.shared.delegate as! AppDelegate
public var musicPlayer: MPMusicPlayerController {
    
    if #available(iOS 10.3, *), !useSystemPlayer {

        return .applicationQueuePlayer
    
    } else {
    
        return .systemMusicPlayer
    }
}
public let musicLibrary = MPMediaLibrary.default()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    enum Subscription: Equatable { case none, iTunesMatch, appleMusic(libraryAccess: Bool) }
    
    enum HomeScreenAction: String {
        
        case playAll = "PlayAllSongs"
        case shuffleSongs = "ShuffleAllSongs"
        case shuffleAlbums = "ShuffleAllAlbums"
        case search = "SearchLibrary"
    }

    var window: UIWindow?
    @objc var storeIdentifier: String?
    var appleMusicStatus: Subscription = .none {
        
        didSet {
            
            UniversalMethods.performInMain { notifier.post(name: .libraryOptionsChanged, object: nil) }
        }
    }
    var musicLibraryStatus: SKCloudServiceAuthorizationStatus?
    lazy var formatter = Formatter.shared
    @objc var libraryChanged = false
    @objc var backgroundTimer: Timer?
    @objc lazy var noAccessView = Bundle.main.loadNibNamed("NoAccessView", owner: nil, options: nil)?.first as? UIView
    @objc var player: AVPlayer?
    let screenLocker = Insomnia.init(mode: InsomniaMode(rawValue: screenLockPreventionMode) ?? .disabled)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        musicLibrary.beginGeneratingLibraryChangeNotifications()
        musicPlayer.beginGeneratingPlaybackNotifications()
        window?.tintColor = .black
        
        if #available(iOS 11, *) {
            
            window?.accessibilityIgnoresInvertColors = true
        }
        
        notifier.addObserver(forName: .MPMediaLibraryDidChange, object: nil, queue: nil, using: { [weak self] _ in
            
            self?.libraryChanged = true
        })
        
        notifier.addObserver(forName: .libraryRefreshIntervalChanged, object: nil, queue: nil, using: { [weak self] _ in
            
            self?.setLibraryTimerIfNeeded()
        })
        
        performLaunchChecks()
        Settings.registerDefaults()
//        Queue.shared.verifyQueue()
        setLibraryTimerIfNeeded()
        
        if showPlaylistFolders {
            
            prefs.set(false, forKey: .showPlaylistFolders)
        }
        
        #warning("Fix this need to reset the font")
        if prefs.integer(forKey: .activeFont) != Font.myriadPro.rawValue {
            
            prefs.set(Font.myriadPro.rawValue, forKey: .activeFont)
            notifier.post(name: .activeFontChanged, object: nil)
        }
        
        if #available(iOS 10.3, *), !useSystemPlayer {

            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

            Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { _ in

                guard musicPlayer.isPlaying else { return }
                
                Queue.shared.updateIndex(self)
            })
        
        } else {
            
            NowPlaying.shared.nowPlayingItem = musicPlayer.nowPlayingItem
            
            if let item = musicPlayer.nowPlayingItem {
            
                Queue.shared.plays[item.persistentID] = item.playCount
            }
        }
        
        if prefs.bool(forKey: "lyricsDeleted").inverted {
            
            Song.deleteAllLyrics(completion: { prefs.set(true, forKey: "lyricsDeleted") })
        }
        
        Scrobbler.shared.setupLastFM(completion: ({
            
            guard let item = NowPlaying.shared.nowPlayingItem, musicPlayer.isPlaying else { return }
            
            Scrobbler.shared.setNowPlayingTo(item)
            
        }, { }))
        
        return true
    }
    
    @objc func updateLibrary() {
        
        guard musicLibraryStatus == .authorized else { return }
        
        if libraryChanged {
            
            notifier.post(name: .libraryUpdated, object: self)
            
            libraryChanged = false
        }
    }
    
    @objc func setLibraryTimerIfNeeded() {
        
        guard libraryRefreshInterval != .none else {
            
            backgroundTimer?.invalidate()
            backgroundTimer = nil
            
            return
        }
        
        backgroundTimer = Timer.scheduledTimer(timeInterval: TimeInterval(libraryRefreshInterval.inSeconds), target: self, selector: #selector(updateLibrary), userInfo: nil, repeats: true)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        
        Queue.shared.updateIndex(self)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
        Queue.shared.updateIndex(self)
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        Queue.shared.updateIndex(self)
        completionHandler(.newData)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
        Queue.shared.updateIndex(self)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
        Queue.shared.updateIndex(self)
//        musicLibrary.endGeneratingLibraryChangeNotifications()
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        completionHandler(handleQuickActions(with: shortcutItem))
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        guard let string = url.absoluteString.components(separatedBy: "/").last, let urlAction = String.URLAction.init(rawValue: string), let topVC = topViewController else { return false }
        
        switch urlAction {
            
            case .nowPlayingInfo:
                
                guard musicPlayer.nowPlayingItem != nil else { return false }
                
                if let presented = topVC as? PresentedContainerViewController, presented.context == .info, case .song(_, at: let index, within: let items) = presented.optionsContext, items[index] == musicPlayer.nowPlayingItem {
                        
                        return false
                
                } else {
                    
                    Transitioner.shared.showInfo(from: topVC, with: .song(location: .queue(loaded: false, index: Queue.shared.indexToUse), at: 0, within: [musicPlayer.nowPlayingItem].compactMap({ $0 })))
                }
            
            case .nowPlaying:
                
                guard musicPlayer.nowPlayingItem != nil else { return false }
                
                let base = basePresentedOrNowPlayingViewController(from: topViewController)
                
                base?.dismiss(animated: base is NowPlayingViewController, completion: { [weak self] in
                    
                    guard let weakSelf = self, !(base is NowPlayingViewController), let presenter = weakSelf.window?.rootViewController as? ContainerViewController, let nowPlayingVC = presenter.moveToNowPlaying(vc: nowPlayingStoryboard.instantiateViewController(withIdentifier: "nowPlaying"), showingQueue: false) else { return }
                    
                    presenter.present(nowPlayingVC, animated: true, completion: nil)
                })
            
            case .queue:
                
                guard musicPlayer.nowPlayingItem != nil else { return false }
                
                if let presented = topVC as? PresentedContainerViewController, presented.context == .queue {
                    
                    return false
                }
            
                guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return false }
            
                presentedVC.context = .queue
                
                topVC.present(presentedVC, animated: true, completion: nil)
        }
        
        return true
    }
    
    @discardableResult func perform(_ action: HomeScreenAction) -> Bool {
        
        switch action {
            
            case .search:
            
                guard let container = window?.rootViewController as? ContainerViewController else { return false }
            
                if container.presentedViewController != nil {
                    
                    container.dismiss(animated: true, completion: nil)
                }
            
                if container.activeViewController == container.searchNavigationController {
                    
                    if let searchVC = container.activeViewController?.topViewController as? SearchViewController {
                        
                        notifier.post(name: .performSecondaryAction, object: searchVC.navigationController)
                        
                    } else {
                        
                        _ = container.activeViewController?.popToRootViewController(animated: true)
                        
                        if let searchVC = container.activeViewController?.topViewController as? SearchViewController {
                            
                            notifier.post(name: .performSecondaryAction, object: searchVC.navigationController)
                        
                        } else {
                            
                            return false
                        }
                    }
                
                } else {
                    
                    container.changeActiveVC = false
                    container.switchViewController(container.searchButton)
                    container.changeActiveViewControllerFrom(container.libraryNavigationController, animated: true, completion: {
                    
                        if let searchVC = container.activeViewController?.topViewController as? SearchViewController {
                            
                            notifier.post(name: .performSecondaryAction, object: searchVC.navigationController)
                            
                        } else {
                            
                            _ = container.activeViewController?.popToRootViewController(animated: true)
                            
                            if let searchVC = container.activeViewController?.topViewController as? SearchViewController {
                                
                                notifier.post(name: .performSecondaryAction, object: searchVC.navigationController)
                            }
                        }
                    })
                    
                    container.changeActiveVC = true
                }
            
                return true
            
            case .playAll, .shuffleSongs:
            
                let songs = MPMediaQuery.songs().cloud.items ?? []
                let shuffled = action == .shuffleSongs
                
                if isInDebugMode {
                    
                    UniversalMethods.banner(withTitle: topViewController?.description).show(for: 0.5)
                }
                
                musicPlayer.play(songs, startingFrom: nil, shuffleMode: shuffled ? .songs : .off, from: topViewController, withTitle: "All Songs", subtitle: nil, alertTitle: shuffled ? .shuffle(.songs) : "Play", completion: nil)
                
                return true
            
            case .shuffleAlbums:
                
                UniversalMethods.banner(withTitle: "Shuffling Albums...").show(for: 0.5)
            
                let songs = (MPMediaQuery.albums().cloud.collections ?? []).shuffled().flatMap({ $0.items })
                musicPlayer.play(songs, startingFrom: nil, shuffleMode: .off, from: topViewController, withTitle: "All Albums", subtitle: nil, alertTitle: .shuffle(.albums), completion: nil)
            
                return true
        }
    }
    
    @objc func handleQuickActions(with shortcutItem: UIApplicationShortcutItem) -> Bool {
        
        guard let type = shortcutItem.type.components(separatedBy: ".").last, let shortcutType = HomeScreenAction.init(rawValue: type) else { return false }
        
        return perform(shortcutType)
    }
    
    @objc func performLaunchChecks() {
        
        verifyLibraryAccessStatus()
        verifyAppleMusicStatus()
        verifyStorefrontIdentifier()
    }
    
    @objc func verifyStorefrontIdentifier() {
        
        SKCloudServiceController().requestStorefrontIdentifier(completionHandler: { [weak self] id, error in
            
            if error == nil {
                
                self?.storeIdentifier = id?.components(separatedBy: ",").first
            }
        })
    }

    @objc func verifyAppleMusicStatus() {
        
        let serviceController = SKCloudServiceController()
        serviceController.requestCapabilities { [weak self] (capability: SKCloudServiceCapability, err: Error?) in
            
            switch capability {
                
                case SKCloudServiceCapability.addToCloudMusicLibrary: self?.appleMusicStatus = .iTunesMatch
                    
                case SKCloudServiceCapability.musicCatalogPlayback: self?.appleMusicStatus = .appleMusic(libraryAccess: false)
                    
                case [.musicCatalogPlayback, .addToCloudMusicLibrary]: self?.appleMusicStatus = .appleMusic(libraryAccess: true)
                    
                default: self?.appleMusicStatus = .none
            }
            
            UniversalMethods.performInMain {
                
                notifier.post(name: .appleMusicStatusChecked, object: nil)
            }
        }
    }
    
    @objc func verifyLibraryAccessStatus() {
        
        SKCloudServiceController.requestAuthorization { [weak self] (status: SKCloudServiceAuthorizationStatus) in
            
            self?.musicLibraryStatus = status
                        
            if firstAuthorisation {
                
                UniversalMethods.performInMain {
                    
                    if status != .authorized {
                        
                        self?.placeNoAccessView()
                    
                    } else {
                        
                        notifier.post(name: .updateForFirstLaunch, object: self)
                    }
                    
                    prefs.set(false, forKey: .firstAuthorisation)
                }
            
            } else {
                
                UniversalMethods.performInMain {
                    
                    if status != .authorized {
                        
                        self?.placeNoAccessView()
                    }
                }
            }
        }
    }
    
    @objc func placeNoAccessView() {
        
        if let noAccessView = noAccessView, let window = window {
            
            noAccessView.frame = window.frame
            window.addSubview(noAccessView)
        }
    }
    
    // MARK: - Core Data stack
    
    @objc lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.okoroezenwa.Test" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    
    @objc lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Melody", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    @objc lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
            
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    @objc lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
//        managedObjectContext.mergePolicy = NSOverwriteMergePolicy
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    @objc func saveContext() {
        
        if managedObjectContext.hasChanges {
            
            do {
                
                try managedObjectContext.save()
                
            } catch let error {
                
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                print(error)
            }
        }
    }
    
    /*@objc func prepareModel() {
        
        let query = MPMediaQuery.songs()
        query.perform(NSSelectorFromString("setShouldIncludeNonLibraryEntities:"), with: true)
        
        if let items = query.items {
            
            for item in items {
                
                autoreleasepool(invoking: {
                    
                    if let songEntity = NSEntityDescription.entity(forEntityName: "Song", in: managedObjectContext) {
                        
                        let song = Song.init(entity: songEntity, insertInto: managedObjectContext)
                        
                        song.albumArtist = item.albumArtist ??? "Unknown Album Artist"
                        song.albumArtistNonDiacritic = (item.albumArtist ??? "Unknown Album Artist").lowercased().folded
                        song.albumArtistDiacritic = (item.albumArtist ??? "Unknown Album Artist").lowercased().folded.diacritic
                        song.album = item.validAlbum
                        song.albumNonDiacritic = item.validAlbum.lowercased().folded
                        song.albumDiacritic = item.validAlbum.lowercased().folded.diacritic
                        song.albumTrackCount = Int64(item.albumTrackCount)
                        song.albumTrackNumber = Int64(item.albumTrackNumber)
                        song.artist = item.validArtist
                        song.artistNonDiacritic = item.validArtist.lowercased().folded
                        song.artistDiacritic = item.validArtist.lowercased().folded.diacritic
                        song.assetURL = item.assetURL?.absoluteString
                        song.beatsPerMinute = Int64(item.beatsPerMinute)
                        song.comments = item.comments
                        song.composer = item.validComposer
                        song.composerNonDiacritic = item.validComposer.lowercased().folded
                        song.composerDiacritic = item.validComposer.lowercased().folded.diacritic
                        song.dateAdded = item.existsInLibrary ? item.validDateAdded as NSDate : NSDate()
                        song.discCount = Int64(item.discCount)
                        song.discNumber = Int64(item.discNumber)
                        song.duration = item.playbackDuration
                        song.existsInLibrary = item.existsInLibrary
                        song.genre = item.validGenre
                        song.genreNonDiacritic = item.validGenre.lowercased().folded
                        song.genreDiacritic = item.validGenre.lowercased().folded.diacritic
                        song.grouping = item.userGrouping
                        song.hasProtectedAsset = item.hasProtectedAsset
                        song.isCloudItem = item.isCloudItem
                        song.isExplicit = item.isExplicit
                        song.lastPlayed = item.lastPlayedDate as NSDate?
                        song.lyrics = item.lyrics ?? ""
                        song.persistentID = Int64(item.persistentID)
                        song.plays = Int64(item.playCount)
                        song.rating = Int16(item.rating)
                        song.released = item.releaseDate as NSDate?
                        song.skips = Int64(item.skipCount)
                        song.storeID = item.storeID
                        song.title = item.validTitle
                        song.titleNonDiacritic = item.validTitle.lowercased().folded
                        song.titleDiacritic = item.validTitle.lowercased().folded.diacritic
                        song.year = Int16(item.year)
                        song.loved = Int16(item.likedState.rawValue)
                    }
                })
            }
            
            do {
                
                try managedObjectContext.save()
                
            } catch let error {
                
                print("Couldn't save sortable item", error.localizedDescription)
            }
        }
    }*/
}
