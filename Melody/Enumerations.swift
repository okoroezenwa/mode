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

enum SortCriteria: Int { case standard, title, artist, album, duration, plays, lastPlayed, rating, genre, dateAdded, year, random, songCount, albumCount, fileSize }

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

enum IconLineWidth: Int { case thin, medium, wide }

enum IconTheme: Int { case dark, light, match }

enum SeparationMethod: Int { case overlay, smaller, below }

enum SupplementaryItems: Int { case star, liked, share, volume }
#warning("Now Playing Supplementary view need completing")

enum SelectionAction { case remove, keep }

enum PlaylistType: Int { case folder, smart, genius, manual, appleMusic }

enum TabBarTapBehaviour: Int { case nothing, scrollToTop, returnToStart, returnThenScroll }

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
    
    var entity: Entity {
        
        switch self {
            
            case .artist: return .artist
            
            case .genre: return .genre
            
            case .composer: return .composer
            
            case .albumArtist: return .albumArtist
        }
    }
    
    var grouping: MPMediaGrouping { return entity.grouping }
    
    var collectionKind: CollectionsKind {
        
        switch self {
            
            case .albumArtist: return .albumArtist
            
            case .artist: return .artist
            
            case .composer: return .composer
            
            case .genre: return .genre
        }
    }
}

enum Entity: Int {
    
    case song, artist, album, genre, composer, playlist, albumArtist

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
    
    var containerType: EntityItemsViewController.EntityContainerType {
        
        switch self {
            
            case .album: return .album
            
            case .playlist: return .playlist
            
            default: return .collection
        }
    }
    
    var albumBasedCollectionKind: AlbumBasedCollectionKind {
        
        switch self {
            
            case .artist: return .artist
                
            case .composer: return .composer
                
            case .genre: return .genre
                
            case .albumArtist: return .albumArtist
                
            default: fatalError("No other collection kind should invoke this")
        }
    }
    
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
    
    func title(albumArtistOverride: Bool = false) -> String {
        
        switch self {
            
            case .album: return "album"
            
            case .artist: return "artist"
            
            case .albumArtist: return albumArtistOverride ? "album artist" : "artist"
            
            case .composer: return "composer"
            
            case .genre: return "genre"
            
            case .playlist: return "playlist"
            
            case .song: return "title"
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
    
    var entity: Entity {
        
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
    
    var entity: Entity {
        
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

    func radius(for entity: Entity, width: CGFloat) -> CGFloat {
        
        switch self {
            
            case .automatic:
            
                switch entity {
                    
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
    
    func radiusDetails(for entityType: Entity, width: CGFloat, globalRadiusType: CornerRadius) -> RadiusDetails {
        
        switch globalRadiusType {
            
            case .automatic: return (self.radius(for: entityType, width: width), (self == .rounded || self == .automatic && Set([Entity.artist, .albumArtist, .genre, .composer]).contains(entityType)).inverted)
        
            default: return (globalRadiusType.radius(for: entityType, width: width), globalRadiusType != .rounded)
        }
    }
    
    func updateCornerRadius(on layer: CALayer?, width: CGFloat, entityType: Entity, globalRadiusType: CornerRadius) {
        
        let details = radiusDetails(for: entityType, width: width, globalRadiusType: globalRadiusType)/*{
            
            switch globalRadiusType {
                
                case .automatic: return (self.radius(for: entityType, width: width), (self == .rounded || self == .automatic && Set([Entity.artist, .albumArtist, .genre, .composer]).contains(entityType)).inverted)
                
                default: return (globalRadiusType.radius(for: entityType, width: width), globalRadiusType != .rounded)
            }
        }()*/
        
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

enum Location {
    
    case playlist, album, artist(point: EntityItemsViewController.StartPoint), songs, collections(kind: CollectionsKind), fullPlayer, miniPlayer, collector, queue, search, info, newPlaylist
    
    func location(from vc: UIViewController?) -> Location {
        
        if let _ = vc as? PlaylistItemsViewController {
            
            return .playlist
            
        } else if let _ = vc as? AlbumItemsViewController {
            
            return .album
            
        } else if let _ = vc as? ArtistSongsViewController {
            
            return .artist(point: .songs)
            
        } else if let _ = vc as? ArtistAlbumsViewController {
            
            return .artist(point: .albums)
            
        } else if let _ = vc as? SongsViewController {
            
            return .songs
            
        } else if let vc = vc as? CollectionsViewController {
            
            return .collections(kind: vc.collectionKind)
        
        } else if let _ = vc as? CollectorViewController {
            
            return .collector
            
        } else if let _ = vc as? NowPlayingViewController {
            
            return .fullPlayer
            
        } else if let _ = vc as? ContainerViewController {
            
            return .miniPlayer
            
        } else if let _ = vc as? QueueViewController {
            
            return .queue
            
        } else if let _ = vc as? SearchViewController {
            
            return .search
            
        } else if let _ = vc as? InfoViewController {
            
            return .info
            
        } else if let _ = vc as? NewPlaylistViewController {
            
            return .newPlaylist
            
        } else {
            
            fatalError("No other VC should invoke this")
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
            
            case .status: return "Status"
        }
    }
    
    var propertyImage: UIImage? { return nil }
}

enum Icon: String {
    
    case lightThin = ""
    case lightMedium = "Light App Icon Medium"
    case lightWide = "Light App Icon Wide"
    case darkThin = "Dark App Icon Thin"
    case darkMedium = "Dark App Icon Medium"
    case darkWide = "Dark App Icon Wide"
    
    static func iconName(width: IconLineWidth, theme: IconTheme) -> Icon {
        
        switch width {
            
            case .thin:
            
                switch theme {
                    
                    case .light: return .lightThin
                    
                    case .dark: return .darkThin
                    
                    case .match: return darkTheme ? .darkThin : .lightThin
                }
            
            case .medium:
            
                switch theme {
                    
                    case .light: return .lightMedium
                    
                    case .dark: return .darkMedium
                    
                    case .match: return darkTheme ? .darkMedium : .lightMedium
                }
            
            case .wide:
            
                switch theme {
                    
                    case .light: return .lightWide
                    
                    case .dark: return .darkWide
                    
                    case .match: return darkTheme ? .darkWide : .lightWide
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
    
    var entity: Entity {
        
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
    
    case collect, addTo, newPlaylist, remove, library, queue(name: String?, query: MPMediaQuery?), likedState, rate, insert(items: [MPMediaItem], completions: Completions?), show(title: String?, context: InfoViewController.Context), info(context: InfoViewController.Context), reveal(indexPath: IndexPath), play(title: String?, completion: (() -> ())?), shuffle(mode: String.ShuffleSuffix, title: String?, completion: (() -> ())?)
    
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
            
            case .show: return #imageLiteral(resourceName: "goTo17")
            
            case .info: return #imageLiteral(resourceName: "InfoNoBorder17")
            
            case .reveal: return #imageLiteral(resourceName: "Context17")
            
            case .play: return #imageLiteral(resourceName: "PlayFilled17")
            
            case .shuffle: return #imageLiteral(resourceName: "Shuffle")
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

enum Font: Int, CaseIterable {
    
    case system, myriadPro, avenirNext
    
    var name: String {
        
        switch self {
            
            case .system: return "System"
            
            case .myriadPro: return "Myriad Pro"
            
            case .avenirNext: return "Avenir Next"
        }
    }
}

enum FontWeight: Int, CaseIterable {
    
    case light, regular, semibold, bold

    var systemWeight: UIFont.Weight {

        switch self {

            case .light: return .light

            case .regular: return .medium
            
            case .semibold: return .semibold
            
            case .bold: return .bold
        }
    }
}

enum TextStyle: String, CaseIterable {
    
    case heading, subheading, modalHeading, sectionHeading, body, secondary, nowPlayingTitle, nowPlayingSubtitle, infoTitle, infoBody, prompt, tiny, accessory, veryTiny
    
    func textSize() -> CGFloat {
        
        switch self {
            
            case .heading: return 34
            
            case .subheading: return 25
            
            case .modalHeading: return 22
            
            case .sectionHeading: return 22
            
            case .body: return 17
            
            case .secondary: return 14
            
            case .nowPlayingTitle: return 25
            
            case .nowPlayingSubtitle: return 22
            
            case .infoTitle: return 25
            
            case .infoBody: return 20
            
            case .prompt: return 15
            
            case .accessory: return 15
            
            case .tiny: return 12
            
            case .veryTiny: return 10
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
    
    case genre, composer, albumArtist, type, duration, plays, added, updated, placement, bpm, skips, grouping, comments, copyright
    
    static func applicableSections(for entityType: Entity) -> Set<InfoSection> {
        
        var set: Set<InfoSection> {
            
            switch entityType {
                
                case .album: return [.composer, .type, .albumArtist, .updated, .placement, .bpm, .grouping, .comments]
                
                case .artist, .albumArtist, .genre, .composer: return [.genre, .composer, .type, .albumArtist, .updated, .placement, .bpm, .grouping, .comments, .copyright]
                
                case .playlist: return [.genre, .composer, .albumArtist, .placement, .bpm, .grouping, .comments, .copyright]
                
                case .song: return [.type, .updated]
            }
        }
        
        return Set(InfoSection.allCases).subtracting(set)
    }
}
