//
//  Enumerations.swift
//  Melody
//
//  Created by Ezenwa Okoro on 02/09/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

enum BackgroundViewState { case visible, removed }

enum VisibilityState { case hidden, visible }

enum QueueViewState { case invoked, dismissed }

enum DisplayArea { case smaller, typical }

enum InsetContext { case filter(inset: CGFloat), container }

enum SortableKind: Int { case playlist, artistSongs, album, artistAlbums }

enum AnimationDirection { case forward, reverse }

enum PropertyTest: String { case isExactly, contains, beginsWith, endsWith, isOver, isUnder }

enum StartPoint: Int { case library, search }

@objc enum ItemProperty: Int { case name, artist, album }

@objc enum ItemStatus: Int { case present, absent }

enum EmptyViewState { case completelyHidden, subLabelHidden, completelyVisible }

enum Interval: Int { case pastHour, pastDay, pastWeek, pastMonth, pastThreeMonths, pastSixMonths }

enum LikedState: Int { case none = 1, liked = 2, disliked = 3 }

enum HeaderProperty { case songCount, albumCount, sortOrder, duration, size, dateCreated, creator, copyright, year, genre, likedState }

enum SortLocation { case playlist, album, songs, collections, playlistList }

enum PlaylistView: Int { case all, user, appleMusic }

enum SecondaryCategory: Int { case loved, plays, lastPlayed, rating, genre, dateAdded, year, fileSize }

enum Position { case leading, middle(single: Bool), trailing }

enum RefreshMode: Int { case ask, offline, theme, filter, refresh }

enum BackgroundArtwork: Int { case none, sectionAdaptive, nowPlayingAdaptive }

enum AnimationOrientation { case horizontal, vertical }

enum ScreenLockPreventionKind: Int { case never, whenCharging, always }

enum FilterPickerViewOptions: String { case iCloud, device, yes = "true", no = "false", available, unavailable, liked, disliked, neutral }

enum IconType: Int { case regular, rainbow, trans }

enum IconLineWidth: Int { case thin, medium, wide }

enum IconTheme: Int { case dark, light, match }

enum SeparationMethod: Int { case overlay, smaller, below }

enum SupplementaryItems: Int { case star, liked, share, volume }
#warning("Now Playing Supplementary view need completing")

enum SelectionAction { case remove, keep }

enum PlaylistType: Int { case folder, smart, genius, manual, appleMusic }

enum TabBarTapBehaviour: Int { case nothing, scrollToTop, returnToStart, returnThenScroll }

enum Location { case playlist, album, collection(kind: AlbumBasedCollectionKind, point: EntityItemsViewController.StartPoint), songs, collections(kind: CollectionsKind), fullPlayer, miniPlayer, collector, queue, search, info, newPlaylist, filter, unknown }

enum EditingStyle { case insert, select/*, both*/ }

enum CellState { case untouched, highlighted, selected }

// MARK: - Well-Defined

enum GestureDuration: Int {
    
    case short, medium, long
    
    var duration: Double {
        
        switch self {
            
            case .short: return 1/3
            
            case .medium: return 2/3
            
            case .long: return 3/3
        }
    }
}

enum AlbumBasedCollectionKind {
    
    case artist, genre, composer, albumArtist
    
    var entityType: EntityType {
        
        switch self {
            
            case .artist: return .artist
            
            case .genre: return .genre
            
            case .composer: return .composer
            
            case .albumArtist: return .albumArtist
        }
    }
    
    var grouping: MPMediaGrouping { return entityType.grouping }
    
    var collectionKind: CollectionsKind {
        
        switch self {
            
            case .albumArtist: return .albumArtist
            
            case .artist: return .artist
            
            case .composer: return .composer
            
            case .genre: return .genre
        }
    }
}

/// Describes the type of entity an operation will be performed on or with.
enum EntityType: Int {
    
    case song, artist, album, genre, composer, playlist, albumArtist

    /// The equivalent media grouping of a given entity type.
    var grouping: MPMediaGrouping {
        
        switch self {
            
            case .album: return .album
            
            case .artist: return .artist
            
            case .composer: return .composer
            
            case .genre: return .genre
            
            case .playlist: return .playlist
            
            case .song: return .title
            
            case .albumArtist: return .albumArtist
        }
    }
    
    /// The general type of container entity currently displayed by an EntityItemsViewController.
    var containerType: EntityItemsViewController.EntityContainerType {
        
        switch self {
            
            case .album: return .album
            
            case .playlist: return .playlist
            
            default: return .collection
        }
    }
    
    /// The specific collection kind of a container type that can display both albums and songs.
    var albumBasedCollectionKind: AlbumBasedCollectionKind {
        
        switch self {
            
            case .artist: return .artist
                
            case .composer: return .composer
                
            case .genre: return .genre
                
            case .albumArtist: return .albumArtist
                
            default: fatalError("No other collection kind should invoke this")
        }
    }
    
    /// EntityType images in sizes 13, 16, 17, and 22.
    var images: (size13: UIImage, size16: UIImage, size17: UIImage, size22: UIImage) {
        
        switch self {
            
            case .album: return (#imageLiteral(resourceName: "AlbumsSmall"), #imageLiteral(resourceName: "Albums16"), #imageLiteral(resourceName: "Albums"), #imageLiteral(resourceName: "AlbumsLarge"))
            
            case .artist, .albumArtist: return (#imageLiteral(resourceName: "ArtistsSmall"), #imageLiteral(resourceName: "Artists16"), #imageLiteral(resourceName: "Artists"), #imageLiteral(resourceName: "ArtistsLarge"))
            
            case .composer: return (#imageLiteral(resourceName: "ComposersSmall"), #imageLiteral(resourceName: "Composers16"), #imageLiteral(resourceName: "Composers"), #imageLiteral(resourceName: "ComposersLarge"))
            
            case .genre: return (#imageLiteral(resourceName: "GenresSmall"), #imageLiteral(resourceName: "Genres16"), #imageLiteral(resourceName: "Genres"), #imageLiteral(resourceName: "GenresLarge"))
            
            case .playlist: return (#imageLiteral(resourceName: "PlaylistsAltSmall"), #imageLiteral(resourceName: "Playlists16"), #imageLiteral(resourceName: "PlaylistsAlt"), #imageLiteral(resourceName: "PlaylistsAlt"))
            
            case .song: return (#imageLiteral(resourceName: "SongsSmall"), #imageLiteral(resourceName: "Songs16"), #imageLiteral(resourceName: "Songs"), #imageLiteral(resourceName: "SongsLarge"))
        }
    }
    
    /**
     The title of the entityType being used.
     
     - Parameter albumArtistOverride: Whether an album artist should identify as an album artist, otherwise simply displayed as an artist.
     
     - Returns: The title of the entity type.
     */
    func title(albumArtistOverride: Bool = false, matchingPropertyName: Bool = false) -> String {
        
        switch self {
            
            case .album: return "album"
            
            case .artist: return "artist"
            
            case .albumArtist: return albumArtistOverride ? (matchingPropertyName ? "albumArtist" : "album artist") : "artist"
            
            case .composer: return "composer"
            
            case .genre: return "genre"
            
            case .playlist: return "playlist"
            
            case .song: return "song"
        }
    }
    
    /**
    The persistentID of the entity being used.
    
    - Parameter song: The song to use to determine the persistentID of the entity.
     
    - Warning: Should not be used for playlists as their persistentIDs cannot be obtained from songs.
    
    - Returns: The persistentID of the entity.
    */
    func persistentID(from song: MPMediaItem) -> MPMediaEntityPersistentID {
        
        switch self {
            
            case .song: return song.persistentID
            
            case .album: return song.albumPersistentID
            
            case .artist: return song.artistPersistentID
            
            case .albumArtist: return song.albumArtistPersistentID
            
            case .genre: return song.genrePersistentID
            
            case .composer: return song.composerPersistentID
            
            case .playlist: return 0
        }
    }
    
    /**
    The librarySection of the entity being used.
    
    - Parameter entity: The entity to use to determine the library section in to navigate to.
    
    - Returns: The librarySection of the entity.
    */
    func librarySection(from entity: MPMediaEntity) -> LibrarySection {
        
        switch self {
            
            case .song: return .songs
            
            case .album:
                
                if let item = entity as? MPMediaItem ?? (entity as? MPMediaItemCollection)?.representativeItem {
                    
                    return item.isCompilation ? .compilations : .albums   
                }
                
                return .albums
            
            case .artist: return .artists
            
            case .albumArtist: return .artists
            
            case .genre: return .genres
            
            case .composer: return .composers
            
            case .playlist: return .playlists
        }
    }
    
    /**
    The persistentID of the entity being used.
    
    - Parameter song: The MPMediaItem to use to determine the persistentID of the entity.
     
    - Warning: Should not be used for playlists as their persistentIDs cannot be obtained from songs.
    
    - Returns: The persistentID of the entity.
    */
    func collection(from entity: MPMediaEntity) -> MPMediaItemCollection? {
        
        switch self {
            
            case .playlist: return MPMediaQuery.init(filterPredicates: [.for(.playlist, using: entity.persistentID)]).cloud.grouped(by: .playlist).collections?.first
            
            default:
                
                if let collection = entity as? MPMediaItemCollection {
                    
                    let persistentID: MPMediaEntityPersistentID = {
                        
                        if let item = collection.representativeItem {
                            
                            return self.persistentID(from: item)
                        }
                        
                        return collection.persistentID
                    }()
                    
                    return MPMediaQuery.init(filterPredicates: [.for(self, using: /*collection.*/persistentID)]).cloud.grouped(by: self.grouping).collections?.first
                
                } else if let item = entity as? MPMediaItem {
                    
                    return MPMediaQuery.init(filterPredicates: [.for(self, using: self.persistentID(from: item))]).cloud.grouped(by: self.grouping).collections?.first
                }
                
                return nil
        }
    }
    
    /**
    The info context of the entityType.
    
    - Parameter collection: The collection to use to determine the info context of the entityType.
     
    - Warning: Should not be used for songs as this method will always return nil.
    
    - Returns: The info context of the entityType or nil if unable to obtain it.
    */
    func singleCollectionInfoContext(for collection: MPMediaItemCollection) -> InfoViewController.Context? {
        
        switch self {
            
            case .song: return nil
            
            case .album: return .album(at: 0, within: [collection])
            
            case .artist, .albumArtist, .genre, .composer: return .collection(kind: self.albumBasedCollectionKind, at: 0, within: [collection])
            
            case .playlist:
            
                guard let playlist = collection as? MPMediaPlaylist else { return nil }
            
                return .playlist(at: 0, within: [playlist])
        }
    }
    
    static func collectionEntityType(for location: Location) -> EntityType {
        
        switch location {
            
            case .album: return .album
            
            case .playlist: return .playlist
            
            case .collection(kind: let kind, point: _): return kind.entityType
            
            default: return .song
        }
    }
    
    static func collectionEntityDetails(for location: Location) -> (type: EntityType, startPoint: EntityItemsViewController.StartPoint) {
        
        switch location {
            
            case .album: return (.album, .songs)
            
            case .playlist: return (.playlist, .songs)
            
            case .collection(kind: let kind, point: let point): return (kind.entityType, point)
            
            default: return (.song, .songs)
        }
    }
    
    func collectionLocation(_ startPoint: EntityItemsViewController.StartPoint) -> Location {
        
        switch self {
            
            case .playlist: return .playlist
            
            case .album: return .album
            
            case .artist, .albumArtist, .genre, .composer: return .collection(kind: self.albumBasedCollectionKind, point: startPoint)
            
            case .song: fatalError("Should not happen")
        }
    }
}

enum CollectionsKind {
    
    case artist, album, genre, compilation, composer, playlist, albumArtist
    
    var albumBasedCollectionKind: AlbumBasedCollectionKind {
        
        switch self {
            
            case .artist: return .artist
            
            case .composer: return .composer
            
            case .genre: return .genre
            
            case .albumArtist: return .albumArtist
            
            default: fatalError("No other collection kind should invoke this")
        }
    }
    
    var entityType: EntityType {
        
        switch self {
            
            case .album, .compilation: return .album
            
            case .composer: return .composer
            
            case .artist: return .artist
            
            case .genre: return .genre
            
            case .playlist: return .playlist
            
            case .albumArtist: return .albumArtist
        }
    }
    
    var category: SearchCategory {
        
        switch self {
            
            case .album, .compilation: return .albums
            
            case .composer: return .composers
            
            case .artist, .albumArtist: return .artists
            
            case .genre: return .genres
            
            case .playlist: return .playlists
        }
    }
}

enum LibrarySection: Int, PropertyStripPresented {
    
    case songs, artists, albums, genres, composers, compilations, playlists
    
    var entityType: EntityType {
        
        switch self {
            
            case .albums, .compilations: return .album
            
            case .composers: return .composer
            
            case .artists: return .artist
            
            case .genres: return .genre
            
            case .playlists: return .playlist
            
            case .songs: return .song
        }
    }
    
    var image: UIImage {
        
        switch self {
            
            case .albums: return #imageLiteral(resourceName: "Albums")
            
             case .compilations: return #imageLiteral(resourceName: "Compilations")
            
            case .composers: return #imageLiteral(resourceName: "Composers")
            
            case .artists: return #imageLiteral(resourceName: "Artists")
            
            case .genres: return #imageLiteral(resourceName: "Genres")
            
            case .playlists: return #imageLiteral(resourceName: "PlaylistsAltSmaller")
            
            case .songs: return #imageLiteral(resourceName: "Songs")
        }
    }
    
    var propertyImage: UIImage? {
        
        switch self {
            
            case .albums: return #imageLiteral(resourceName: "Albums17")
            
             case .compilations: return #imageLiteral(resourceName: "CompilationsSmall")
            
            case .composers: return #imageLiteral(resourceName: "ComposersSmall")
            
            case .artists: return #imageLiteral(resourceName: "Artists16")
            
            case .genres: return #imageLiteral(resourceName: "GenresSmall")
            
            case .playlists: return #imageLiteral(resourceName: "Playlists13")
            
            case .songs: return #imageLiteral(resourceName: "SongsSmall")
        }
    }
    
    var title: String {
        
        switch self {
            
            case .albums: return "Albums"
                
            case .artists: return "Artists"
                
            case .songs: return "Songs"
                
            case .genres: return "Genres"
                
            case .composers: return "Composers"
                
            case .compilations: return "Compilations"
                
            case .playlists: return "Playlists"
        }
    }
}

enum CornerRadius: Int {
    
    case automatic, square, small, large, rounded

    func nowPlayingRadius(width: CGFloat) -> CGFloat {
        
        switch self {
            
            case .automatic: return 8
            
            case .square: return 0
            
            case .small: return ceil((4/54) * width)
            
            case .large: return ceil((14/54) * width)
            
            case .rounded: return width / 2
        }
    }

    func radius(for entityType: EntityType, width: CGFloat) -> CGFloat {
        
        switch self {
            
            case .automatic:
            
                switch entityType {
                    
                    case .song: return 0
                    
                    case .playlist: return ceil((4/54) * width)
                    
                    case .album: return ceil((14/54) * width)
                    
                    default: return width / 2
                }
            
            case .square: return 0
            
            case .small: return ceil((4/66) * width)
            
            case .large: return ceil((14/54) * width)
            
            case .rounded: return width / 2
        }
    }
    
    func radiusDetails(for entityType: EntityType, width: CGFloat, globalRadiusType: CornerRadius) -> RadiusDetails {
        
        switch globalRadiusType {
            
            case .automatic: return (self.radius(for: entityType, width: width), (self == .rounded || self == .automatic && Set([EntityType.artist, .albumArtist, .genre, .composer]).contains(entityType)).inverted)
        
            default: return (globalRadiusType.radius(for: entityType, width: width), globalRadiusType != .rounded)
        }
    }
    
    func updateCornerRadius(on layer: CALayer?, width: CGFloat, entityType: EntityType, globalRadiusType: CornerRadius) {
        
        let details = radiusDetails(for: entityType, width: width, globalRadiusType: globalRadiusType)
        
        layer?.setRadiusTypeIfNeeded(to: details.useContinuousCorners)
        layer?.cornerRadius = details.radius
    }
    
    var description: String {
        
        switch self {
            
            case .automatic: return "By Type"
            
            case .small: return "Slight"
            
            case .square: return "None"
            
            case .large: return "Prominent"
            
            case .rounded: return "Full"
        }
    }
}

enum Property: Int, PropertyStripPresented, CaseIterable {
    
    case title, artist, album, dateAdded, lastPlayed, genre, composer, plays, duration, year, rating, status, size, trackCount, albumCount, isCloud, artwork, isExplicit, isCompilation
    
    var title: String {
        
        switch self {
            
            case .album: return "Album"
            
            case .albumCount: return "Albums"
            
            case .artist: return "Artist"
            
            case .artwork: return "Artwork"
            
            case .composer: return "Composer"
            
            case .dateAdded: return "Added"
            
            case .duration: return "Duration"
            
            case .genre: return "Genre"
            
            case .isCloud: return "Location"
            
            case .isCompilation: return "Compilation"
            
            case .isExplicit: return "Explicit"
            
            case .lastPlayed: return "Played"
            
            case .plays: return "Plays"
            
            case .rating: return "Rating"
            
            case .size: return "Size"
            
            case .trackCount: return "Songs"
            
            case .title: return "Name"
            
            case .year: return "Year"
            
            case .status: return "Affinity"
        }
    }
    
    var propertyImage: UIImage? { return nil }
}

enum Icon: String {
    
    case lightThin = ""
    case lightMedium = "Light App Icon Medium"
    case lightWide = "Light App Icon Wide"
    case lightThinRainbow = "Light Rainbow App Icon Thin"
    case lightMediumRainbow = "Light Rainbow App Icon Medium"
    case lightWideRainbow = "Light Rainbow App Icon Wide"
    case darkThin = "Dark App Icon Thin"
    case darkMedium = "Dark App Icon Medium"
    case darkWide = "Dark App Icon Wide"
    case darkThinRainbow = "Dark Rainbow App Icon Thin"
    case darkMediumRainbow = "Dark Rainbow App Icon Medium"
    case darkWideRainbow = "Dark Rainbow App Icon Wide"
    case darkThinTrans = "Dark Trans App Icon Thin"
    case darkMediumTrans = "Dark Trans App Icon Medium"
    case darkWideTrans = "Dark Trans App Icon Wide"
    
    static func iconName(type: IconType, width: IconLineWidth, theme: IconTheme) -> Icon {
        
        switch width {
            
            case .thin:
            
                switch theme {
                    
                    case .light:
                    
                        switch type {
                            
                            case .regular: return .lightThin
                            
                            case .rainbow: return .lightThinRainbow
                            
                            case .trans: return .darkThinTrans
                        }
                    
                    case .dark:
                        
                        switch type {
                            
                            case .regular: return .darkThin
                            
                            case .rainbow: return .darkThinRainbow
                            
                            case .trans: return .darkThinTrans
                        }
                    
                    case .match:
                    
                        switch type {
                            
                            case .regular: return darkTheme ? .darkThin : .lightThin
                            
                            case .rainbow: return darkTheme ? .darkThinRainbow : .lightThinRainbow
                            
                            case .trans: return darkThinTrans
                        }
                }
            
            case .medium:
            
                switch theme {
                    
                    case .light:
                    
                        switch type {
                            
                            case .regular: return .lightMedium
                            
                            case .rainbow: return .lightMediumRainbow
                            
                            case .trans: return .darkMediumTrans
                        }
                    
                    case .dark:
                        
                        switch type {
                            
                            case .regular: return .darkMedium
                            
                            case .rainbow: return .darkMediumRainbow
                            
                            case .trans: return .darkMediumTrans
                        }
                    
                    case .match:
                    
                        switch type {
                            
                            case .regular: return darkTheme ? .darkMedium : .lightMedium
                            
                            case .rainbow: return darkTheme ? .darkMediumRainbow : .lightMediumRainbow
                            
                            case .trans: return darkMediumTrans
                        }
                }
            
            case .wide:
            
                switch theme {
                    
                    case .light:
                    
                        switch type {
                            
                            case .regular: return .lightWide
                            
                            case .rainbow: return .lightWideRainbow
                            
                            case .trans: return .darkWideTrans
                        }
                    
                    case .dark:
                        
                        switch type {
                            
                            case .regular: return .darkWide
                            
                            case .rainbow: return .darkWideRainbow
                            
                            case .trans: return .darkWideTrans
                        }
                    
                    case .match:
                    
                        switch type {
                            
                            case .regular: return darkTheme ? .darkWide : .lightWide
                            
                            case .rainbow: return darkTheme ? .darkWideRainbow : .lightWideRainbow
                            
                            case .trans: return darkWideTrans
                        }
                }
        }
    }
}

enum SearchCategory: Int {
    
    case all, songs, artists, albums, playlists, genres, composers

    var title: String {
        
        switch self {
            
            case .all: return "all"
            
            case .albums: return "albums"
            
            case .artists: return "artists"
            
            case .composers: return "composers"
            
            case .genres: return "genres"
            
            case .playlists: return "playlists"
            
            case .songs: return "songs"
        }
    }

    var image: UIImage {
        
        switch self {
            
            case .all: return #imageLiteral(resourceName: "SearchTab")
            
            case .albums: return #imageLiteral(resourceName: "Albums16")
            
            case .artists: return #imageLiteral(resourceName: "Artists16")
            
            case .composers: return #imageLiteral(resourceName: "Composers16")
            
            case .genres: return #imageLiteral(resourceName: "Genres16")
            
            case .playlists: return #imageLiteral(resourceName: "Playlists16")
            
            case .songs: return #imageLiteral(resourceName: "Songs16")
        }
    }
    
    var albumBasedCollectionKind: AlbumBasedCollectionKind {
        
        switch self {
            
            case .artists: return .artist
            
            case .genres: return .genre
            
            case .composers: return .composer
            
            default: fatalError("No other collection kind should invoke this")
        }
    }
    
    var entityType: EntityType {
        
        switch self {
            
            case .artists: return .artist
            
            case .genres: return .genre
            
            case .composers: return .composer
            
            case .songs: return .song
            
            case .albums: return .album
            
            case .playlists: return .playlist
            
            case .all: fatalError("No other collection kind should invoke this")
        }
    }
}

enum LibraryRefreshInterval: Int {
    
    case none, thirtySeconds, oneMinute, twoMinutes, fiveMinutes, tenMinutes, thirtyMinutes, oneHour
    
    var inSeconds: Int {
        
        switch self {
            
            case .none: return 0
            
            case .thirtySeconds: return 30
            
            case .oneMinute: return 60
            
            case .twoMinutes: return 120
            
            case .fiveMinutes: return 300
            
            case .tenMinutes: return 600
            
            case .thirtyMinutes: return 1800
            
            case .oneHour: return 3600
        }
    }
}

enum SongAction {
    
    case collect, addTo, newPlaylist, remove, library, queue(name: String?, query: MPMediaQuery?), likedState, rate, insert(items: [MPMediaItem], completions: Completions?), show(title: String?, context: InfoViewController.Context, canDisplayInLibrary: Bool), info(context: InfoViewController.Context), reveal(indexPath: IndexPath), play(title: String?, completion: (() -> ())?), shuffle(mode: String.ShuffleSuffix, title: String?, completion: (() -> ())?), search(unwinder: (() -> UIViewController?)?)
    
    var icon: UIImage {
        
        switch self {
            
            case .collect: return #imageLiteral(resourceName: "Collected17")
            
            case .addTo, .newPlaylist: return #imageLiteral(resourceName: "AddNoBorder")
            
            case .remove: return #imageLiteral(resourceName: "Discard17")
            
            case .library: return #imageLiteral(resourceName: "AddToLibrary")
            
            case .queue: return #imageLiteral(resourceName: "AddSong17")
            
            case .likedState: return #imageLiteral(resourceName: "NoLove17")
            
            case .rate: return #imageLiteral(resourceName: "Star17")
            
            case .insert: return #imageLiteral(resourceName: "AddToPlaylist17")
            
            case .show: return #imageLiteral(resourceName: "GoTo17NoBorder")
            
            case .info: return #imageLiteral(resourceName: "InfoNoBorder17")
            
            case .reveal: return #imageLiteral(resourceName: "Context17")
            
            case .play: return #imageLiteral(resourceName: "PlayFilled17")
            
            case .shuffle: return #imageLiteral(resourceName: "Shuffle")
            
            case .search: return #imageLiteral(resourceName: "SearchTab")
        }
    }
    
    var requiresDismissalFirst: Bool {
        
        switch self {
            
            case .addTo, .newPlaylist, .play, .shuffle, .info, .queue, .rate, .likedState, .show: return true
        
            default: return false
        }
    }
}

enum Threshold: String, Comparable {
    
    case none, first, second, third

    static func <(lhs: Threshold, rhs: Threshold) -> Bool {
        
        switch (lhs, rhs) {
            
            case (.none, .first), (.none, .second), (.none, .third), (.first, .second), (.first, .third), (.second, .third): return true
            
            default: return false
        }
    }

    var index: Int {
        
        switch self {
            
            case .none, .first: return 0
            
            case .second: return 1
            
            case .third: return 2
        }
    }
}

enum ArtworkType {
    
    case image(UIImage?), colour(UIColor)
    
    var image: UIImage? {
        
        switch self {
            
            case .image(let image): return image
            
            case .colour(let colour): return .new(withColour: colour, size: .artworkSize)
        }
    }
}

enum FilterViewContext: Equatable {
    
    case filter(filter: Filterable?, container: (FilterContainer & UIViewController)?), library
    
    enum Operation { case group(index: Int?), ungroup(index: Int?), hide, unhide }

    static func ==(lhs: FilterViewContext, rhs: FilterViewContext) -> Bool {
        
        switch lhs {
            
            case .filter(let filter, _):
            
                switch rhs {
                    
                    case .filter(filter: let otherFilter, container: _): return filter == nil && otherFilter == nil
                    
                    default: return false
                }
            
            case .library:
            
                switch rhs {
                    
                    case .library: return true
                    
                    default: return false
                }
        }
    }
    
    static func ~=(lhs: FilterViewContext, rhs: FilterViewContext) -> Bool {
        
        switch lhs {
            
            case .filter:
            
                if case .filter = rhs { return true }
            
                return false
            
            case .library: return rhs == .library
        }
    }
}

enum BarBlurBehavour: Int, CaseIterable {
    
    case none, top, bottom, all
    
    var title: String {
        
        switch self {
            
            case .none: return "None"
            
            case .top: return "Blur Top"
            
            case .bottom: return "Blur Bottom"
            
            case .all: return "Blur Both Bars"
        }
    }
}

enum InfoSection: String, CaseIterable {
    
    case genre, composer, albumArtist, playlistType, duration, plays, added, updated, placement, bpm, skips, grouping, comments, copyright
    
    static func applicableSections(for entityType: EntityType) -> Set<InfoSection> {
        
        var set: Set<InfoSection> {
            
            switch entityType {
                
                case .album: return [.composer, .playlistType, .albumArtist, .updated, .placement, .bpm, .grouping, .comments]
                
                case .artist, .albumArtist, .genre, .composer: return [.genre, .composer, .playlistType, .albumArtist, .updated, .placement, .bpm, .grouping, .comments, .copyright]
                
                case .playlist: return [.genre, .composer, .albumArtist, .placement, .bpm, .grouping, .comments, .copyright]
                
                case .song: return [.playlistType, .updated]
            }
        }
        
        return Set(InfoSection.allCases).subtracting(set)
    }
}

enum SortCriteria: Int, CaseIterable {
    
    case standard, title, artist, album, duration, plays, lastPlayed, rating, genre, dateAdded, year, random, songCount, albumCount, fileSize, albumName, albumYear
    
    func title(from location: Location) -> String {
        
        switch self {
            
            case .title:
            
                switch location {
                    
                    case .album, .collection(kind: _, point: .songs), .songs, .playlist, .collections(kind: .artist), .collections(kind: .genre), .collections(kind: .composer), .collections(kind: .playlist): return "Name"
                    
                    case .collections(kind: .album), .collections(kind: .compilation), .collection(_, point: .albums): return "Title"
                    
                    default: return ""
                }
            
            case .album, .albumYear, .albumName: return "Album"
            
            case .artist: return "Artist"
            
            case .genre: return "Genre"
            
            case .albumCount: return "Albums"
            
            case .songCount: return "Songs"
            
            case .dateAdded: return "Added"
            
            case .duration: return "Duration"
            
            case .fileSize: return "Size"
            
            case .lastPlayed: return "Played"
            
            case .plays: return "Plays"
            
            case .random: return "Random"
            
            case .rating: return "Rating"
            
            case .standard: return "Default"
            
            case .year: return "Year"
        }
    }
    
    func subtitle(from location: Location) -> String {
        
        switch location {
            
            case .collection(kind: let kind, point: .songs) where Set([AlbumBasedCollectionKind.artist, .albumArtist]).contains(kind):
            
                switch self {
            
                    case .album: return "by Index"
                    
                    case .albumName: return "by Name"
                    
                    case .albumYear: return "by Year"
                    
                    default: return ""
                }
            
            default: return ""
        }
    }
    
    static func sortResult(between first: SortCriteria, and second: SortCriteria, at location: Location) -> Bool {
        
        return (first.title(from: location) + first.subtitle(from: location)) < (second.title(from: location) + second.subtitle(from: location))
    }
    
    static func applicableSortCriteria(for location: Location) -> Set<SortCriteria> {
        
        switch location {
            
            case .album: return [.duration, .artist, .album, .plays, .lastPlayed, .genre, .rating, .dateAdded, .title, .fileSize]
            
            case .playlist: return [.duration, .title, .artist, .album, .plays, .year, .lastPlayed, .genre, .rating, .dateAdded, .fileSize]
            
            case .collections(kind: let kind):
            
                let set: Set<SortCriteria> = [.album, .duration, .year, .genre, .artist, .plays, .dateAdded, .fileSize, .songCount, .albumCount, .title]
                
                switch kind {
                    
                    case .album: return set.subtracting([.albumCount])
                    
                    case .compilation: return set.subtracting([.albumCount, .artist])
                    
                    case .artist, .albumArtist: return set.subtracting([.year, .genre, .title, .album])
                    
                    case .genre, .composer: return set.subtracting([.year, .genre, .artist, .album])
                    
                    case .playlist: return set.subtracting([.album, .year, .genre, .artist, .albumCount])
                }
            
            case .collection(kind: let kind, point: let point):
            
                switch point {
                    
                    case .songs:
                    
                        let set: Set<SortCriteria> = [.duration, .artist, .album, .plays, .lastPlayed, .genre, .rating, .dateAdded, .title, .fileSize, .year, .albumName, .albumYear]
                        
                        switch kind {
                            
                            case .artist, .albumArtist: return set.subtracting([.artist])
                                
                            case .genre: return set.subtracting([.genre, .albumName, .albumYear])
                            
                            case .composer: return set.subtracting([.albumName, .albumYear])
                        }
                    
                    case .albums:
                    
                        let set: Set<SortCriteria> = [.album, .duration, .year, .genre, .artist, .plays, .dateAdded, .fileSize, .songCount]
                        
                        switch kind {
                            
                            case .artist, .albumArtist: return set.subtracting([.artist])
                            
                            case .genre: return set.subtracting([.genre])
                            
                            case .composer: return set
                        }
                }
            
            default: return []
        }
    }
}

enum Theme: Int {
    
    case system, light, dark
    
    var title: String {
        
        switch self {
            
            case .system: return "System"
            
            case .light: return "Light"
            
            case .dark: return "Dark"
        }
    }
}
