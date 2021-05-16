//
//  Settings.swift
//  Melody
//
//  Created by Ezenwa Okoro on 25/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class Settings {
    
    class var isInDebugMode: Bool {
        
        #if DEBUG
            
            return true
            
        #else
            
            return Bundle.main.bundleIdentifier?.contains("personal") == true
            
        #endif
    }

    class func registerDefaults() {
        
        let defaultSortDetails: (sorts: [String: Int], orders: [String: Bool]) = [Location.album, .playlist, .collection(kind: .artist, point: .songs), .collection(kind: .artist, point: .albums), .collection(kind: .albumArtist, point: .songs), .collection(kind: .albumArtist, point: .albums), .collection(kind: .genre, point: .songs), .collection(kind: .genre, point: .albums), .collection(kind: .composer, point: .songs), .collection(kind: .composer, point: .albums)].map({ EntityType.collectionEntityDetails(for: $0) }).map({ $0.type.title(matchingPropertyName: true) + $0.startPoint.title }).reduce(([String: Int](), [String: Bool]()), { ($0.0.appending(key: $1, value: ($1.contains("rtistson") ? .albumName : SortCriteria.standard).rawValue), $0.1.appending(key: $1, value: true)) })
        
        let use3D: Bool = {
            
            if #available(iOS 14, *) { return true }
            
            return false
        }()
        
        prefs.register(defaults: [
            
            .dynamicStatusBar: isiPhoneX.inverted,
            .nowPlayingBoldTitle: false,
            .boldSectionTitles: false, // unused
            .playOnlyShortcut: true,
            .recentSearchLimit: 30, // unused; likely won't be
            .warnInterruption: isInDebugMode,
            .iCloudItems: !isInDebugMode,
            .songsSort: SortCriteria.standard.rawValue,
            .songsOrder: true,
            .albumsSort: SortCriteria.standard.rawValue,
            .albumsOrder: true,
            .artistsSort: SortCriteria.standard.rawValue,
            .artistsOrder: true,
            .albumArtistsSort: SortCriteria.standard.rawValue,
            .albumArtistsOrder: true,
            .genresSort: SortCriteria.standard.rawValue,
            .genresOrder: true,
            .composersSort: SortCriteria.standard.rawValue,
            .composersOrder: true,
            .compilationsSort: SortCriteria.standard.rawValue,
            .compilationsOrder: true,
            .playlistsSort: SortCriteria.title.rawValue,
            .playlistsOrder: true,
            .firstAuthorisation: true,
            .hideEmptyPlaylists: isInDebugMode,
            .lastUsedLibrarySection: LibrarySection.artists.rawValue,
            .lastUsedTab: StartPoint.library.rawValue,
            .showRecentPlaylists: true,
            .showRecentSongs: isInDebugMode.inverted,
            .showRecentArtists: isInDebugMode.inverted,
            .showRecentAlbumArtists: isInDebugMode.inverted,
            .showRecentAlbums: isInDebugMode.inverted,
            .showRecentGenres: isInDebugMode.inverted,
            .showRecentComposers: isInDebugMode.inverted,
            .showRecentCompilations: isInDebugMode.inverted,
            .keepShuffleState: !isInDebugMode,
            .numbersBelowLetters: true,
            .strictAlbumBackground: false,
            .artistStartingPoint: 1,
            .prefersSmallerArt: isiPhoneX,
            .showNowPlayingVolumeView: true,
            .darkTheme: false,
            .showExplicitness: true,
            .songCountVisible: true,
            .playlistsView: isInDebugMode ? PlaylistView.user.rawValue : PlaylistView.all.rawValue,
            .songCellCategories: Settings.songSecondarySubviews,
            .artistCellCategories: Settings.artistSecondarySubviews,
            .albumCellCategories: Settings.albumSecondarySubviews,
            .genreCellCategories: Settings.genreSecondarySubviews,
            .composerCellCategories: Settings.composerSecondarySubviews,
            .playlistCellCategories: Settings.playlistSecondarySubviews,
            .infoBoldText: false, // not set
            .deinitBannersEnabled: false,
            .showInfoButtons: true,
            .addGuard: false,
            .playGuard: true,
            .stopGuard: true,
            .clearGuard: true,
            .changeGuard: isInDebugMode,
            .removeGuard: true,
            .refreshMode: RefreshMode.refresh.rawValue, // may not bother
            .backToStart: !isInDebugMode,
            .showUnaddedMusic: false, // not set
            .systemPlayer: useSystemMusicPlayer,
            .longPressDuration: defaultGestureDuration.rawValue,
            .darkTimeConstraintEnabled: false,
            .darkBrightnessConstraintEnabled: false,
            .brightnessValue: 0.1,
            .darkAnyConditionActive: true,
            .fromHourComponent: 22,
            .fromMinuteComponent: 0,
            .toHourComponent: 7,
            .toMinuteComponent: 0,
            .manualNightMode: true,
            .showCloseButton: !isInDebugMode,
            .collectorPreventsDuplicates: true,
            .showSectionChooserEverywhere: true,
            .fasterNowPlayingStartup: false,
            .lighterBorders: isInDebugMode,
            .tabBarScrollToTop: true,
            .screenLockPreventionMode: InsomniaMode.disabled.rawValue,
            .persistActionsView: false,
            .persistArrangeView: false,
            .useArtistCustomBackground: true,
            .usePlaylistCustomBackground: true,
            .primarySizeSuffix: Int64.FileSize.megabyte.rawValue,
            .secondarySizeSuffix: Int64.FileSize.megabyte.rawValue,
            .cornerRadius: CornerRadius.automatic.rawValue,
            .filterProperties: standardProperties.map({ $0.oldRawValue }),
            .librarySections: defaultLibrarySections.map({ $0.rawValue }),
            .useCompactCollector: false,
            .otherFilterProperties: [Int](),
            .otherLibrarySections: defaultOtherLibrarySections.map({ $0.rawValue }),
            .widgetCornerRadius: CornerRadius.large.rawValue,
            .listsCornerRadius: CornerRadius.automatic.rawValue,
            .infoCornerRadius: CornerRadius.automatic.rawValue,
            .miniPlayerCornerRadius: CornerRadius.large.rawValue,
            .fullScreenPlayerCornerRadius: CornerRadius.small.rawValue,
            .filterFuzziness: 0.4,
            .iconLineWidth: IconLineWidth.thin.rawValue,
            .iconTheme: IconTheme.light.rawValue,
            .iconType: IconType.regular.rawValue,
            .compressOnPause: isInDebugMode.inverted,
            .avoidDoubleHeightBar: !isiPhoneX,
            .separationMethod: defaultSeparationMethod.rawValue,
            .showNowPlayingSupplementaryView: true,
            .supplementaryItems: [SupplementaryItems.volume.rawValue],
            .useDescriptor: useDescriptor,
            .preserveRepeatState: !isInDebugMode,
            .useMediaItems: useMediaItems,
            .useOldStyleQueue: useOldQueue,
            .libraryRefreshInterval: LibraryRefreshInterval.fiveMinutes.rawValue,
            .recentlyUpdatedPlaylistSorts: defaultRecentlyUpdatedPlaylistSorts.map({ $0.rawValue }),
            .showPlaylistFolders: false,
            .tabBarTapBehaviour: defaultTabBarBehaviour.rawValue,
            .backgroundArtworkAdaptivity: BackgroundArtwork.sectionAdaptive.rawValue,
            .lyricsTextAlignment: NSTextAlignment.center.rawValue,
            .removeTitleBrackets: true,
            .removeTitleAmpersands: true,
            .removeTitlePunctuation: true,
            .replaceTitleCensoredWords: true,
            .removeArtistBrackets: true,
            .removeArtistPunctuation: true,
            .removeArtistAmpersands: true,
            .replaceArtistCensoredWords: true,
            .sectionCountVisible: false,
            .useWhiteColorBackground: false,
            .useBlackColorBackground: false,
            .hiddenFilterProperties: [Int](),
            .hiddenLibrarySections: [Int](),
            .navBarConstant: TopBarOffset.large.rawValue,
            .activeFont: Font.myriadPro.rawValue,
            .barBlurBehaviour: BarBlurBehavour.all.rawValue/*,
            .visibleInfoItems: InfoSection.allCases.map({ $0.rawValue })*/,
            .includeAlbumName: true,
            .showLastFMLoginAlert: true,
            .showScrobbleAlert: false,
            .showLoveAlert: true,
            .showNowPlayingUpdateAlert: false,
            .navBarArtworkMode: VisualEffectNavigationBar.ArtworkMode.small.rawValue,
            .allowPlayIncrementingSkip: isInDebugMode,
            .useSystemSwitch: true,
            .useSystemAlerts: false,
            .theme: defaultTheme.rawValue,
            .useArtworkInShowMenu: true,
            .lastUsedPlaylists: [MPMediaPlaylist](),
            .showPlaylistHistory: false,
            .defaultCollectionSortCategories: defaultSortDetails.sorts,
            .defaultCollectionSortOrders: defaultSortDetails.orders,
            .useExpandedSlider: false,
            .showMiniPlayerSongTitles: false,
            .showTabBarLabels: true,
            .useQueuePositionMiniPlayerTitle: true,
            .animateWithPresentation: true,
            .use3DTransforms: use3D,
            .hideMiniPlayerTabLabel: false
        ])
        
        sharedDefaults.register(defaults: [
            
            .systemPlayer: useSystemMusicPlayer,
            .lighterBorders: useLighterBorders,
            .widgetCornerRadius: CornerRadius.large.rawValue
        ])
    }
    
    static let standardProperties = [Property.title, .artist, .album, .dateAdded, .lastPlayed, .genre, .composer, .plays, .duration, .year, .rating, .affinity, .size, .songCount, .albumCount, .isCloud, .artwork, .isExplicit, .isCompilation, .albumArtist]
    
    class func resetDefaults() {
        
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        
        prefs.removePersistentDomain(forName: bundleID)
        
        registerDefaults()
    }
    
    static var songSecondarySubviews: [Int] { return isInDebugMode ? [SecondaryCategory.dateAdded, .plays, .lastPlayed].map({ $0.rawValue }) : [] }
    static var artistSecondarySubviews: [Int] { return isInDebugMode ? [SecondaryCategory.plays, .fileSize].map({ $0.rawValue }) : [] }
    static var albumSecondarySubviews: [Int] { return isInDebugMode ? [SecondaryCategory.songCount, .plays, .fileSize].map({ $0.rawValue }) : [] }
    static var genreSecondarySubviews: [Int] { return isInDebugMode ? [SecondaryCategory.plays, .fileSize].map({ $0.rawValue }) : [] }
    static var composerSecondarySubviews: [Int] { return isInDebugMode ? [SecondaryCategory.plays, .fileSize].map({ $0.rawValue }) : [] }
    static var playlistSecondarySubviews: [Int] { return isInDebugMode ? [SecondaryCategory.albumCount, .fileSize].map({ $0.rawValue }) : [] }
    
    static var forceOldStyleQueue: Bool {
        
        if #available(iOS 12.2, *), !useSystemPlayer {
            
            return useOldStyleQueue
        
        } else if #available(iOS 11.3, *), !useSystemPlayer {
            
            return true
            
        } else {
            
            return useOldStyleQueue
        }
    }
    
    static var useSystemMusicPlayer: Bool {
        
        #if targetEnvironment(simulator)
        
        return false
        
        #else
        
        if isInDebugMode, #available(iOS 12.2, *) {
            
            return false
            
        } else if #available(iOS 11, *) {
            
            return true
            
        } else if #available(iOS 10.3, *) {
            
            return false
            
        } else {
            
            return true
        }
        
        #endif
    }
    
    static var useDescriptor: Bool {
        
        if #available(iOS 11.3, *) {
            
            return true
        
        } else if #available(iOS 11, *) {
            
            return false
            
        } else if #available(iOS 10.3, *) {
            
            return true
            
        } else {
            
            return false
        }
    }
    
    static var useMediaItems: Bool {
        
        if #available(iOS 11.3, *), useSystemMusicPlayer {
            
            return true
            
        } else if #available(iOS 10.3, *) {
            
            return false
            
        } else {
            
            return true
        }
    }
    
    static var useOldQueue: Bool {
        
        if isInDebugMode, #available(iOS 12.2, *) {
            
            return false
            
        } else if #available(iOS 11.3, *) {
            
            return isInDebugMode
            
        } else if #available(iOS 10.3, *) {
            
            return false
            
        } else {
            
            return true
        }
    }
    
    static var defaultSeparationMethod: SeparationMethod { return isiPhoneX ? .below : .smaller }
    static var defaultRefreshInterval: LibraryRefreshInterval = .none
    static var defaultRecentlyUpdatedPlaylistSorts: [PlaylistView] { return isInDebugMode ? [.appleMusic] : [] }
    static var defaultTabBarBehaviour: TabBarTapBehaviour { return isInDebugMode ? .scrollToTop : .returnThenScroll }
    static var defaultGestureDuration: GestureDuration { return isInDebugMode ? .short : .medium }
    static var defaultLibrarySections: [LibrarySection] {
        
        let sections = [LibrarySection.songs, .artists, .albums, .playlists]
        
        return isInDebugMode ? sections : sections + [.albumArtists, .albums, .genres, .composers, .compilations]
    }
    static var defaultOtherLibrarySections: [LibrarySection] { return isInDebugMode ? [.genres, .composers, .compilations, .albumArtists] : [] }
    
    static func components(from date: Date) -> TimeConstraintComponents {
        
        return (Calendar.current.component(.hour, from: date), Calendar.current.component(.minute, from: date))
    }
    static var defaultTheme: Theme {
        
        if #available(iOS 13, *) {
            
            return .system
        }
        
        return .light
    }
}

// MARK: - String Settings Constants
extension String {
    
    // MARK: - Collection
    static let songsSort = "songsSort"
    static let songsOrder = "songsOrder"
    static let albumsSort = "albumsSort"
    static let albumsOrder = "albumsOrder"
    static let artistsSort = "artistsSort"
    static let artistsOrder = "artistsOrder"
    static let albumArtistsSort = "albumArtistsSort"
    static let albumArtistsOrder = "albumArtistsOrder"
    static let genresSort = "genresSort"
    static let genresOrder = "genresOrder"
    static let compilationsSort = "compilationsSort"
    static let compilationsOrder = "compilationsOrder"
    static let composersSort = "composersSort"
    static let composersOrder = "composersOrder"
    static let playlistsSort = "playlistsSort"
    static let playlistsOrder = "playlistsOrder"
    
    // MARK: - Custom Collections
    static let aList = "aList"
    static let bList = "bList"
    static let cList = "cList"
    static let languageList = "languageList"
    static let choppingBlock = "choppingBlock"
    
    // MARK: - Playback
    static let warnInterruption = "warnInterruption"
    static let playOnlyShortcut = "allowPlayOnly"
    
    // MARK: - Settings
    static let iCloudItems = "showiCloudItems"
    static let boldSectionTitles = "boldTableViewSectionTitles" // unused
    static let recentSearchLimit = "recentSearchLimit" // unused
    static let nowPlayingBoldTitle = "nowPlayingBoldTitleSize"
    static let infoBoldText = "infoBoldText"
    static let dynamicStatusBar = "dynamicStatusBar"
    static let firstAuthorisation = "firstMusicLibraryAuthorisation"
    static let hideEmptyPlaylists = "hideEmptyPlaylists"
    static let lastUsedLibrarySection = "lastUsedLibrarySection"
    static let lastUsedTab = "lastUsedTab"
//    static let filterShortcutEnabled = "filterShortcutEnabled"
    static let showRecentPlaylists = "showRecentPlaylists"
    static let showRecentSongs = "showRecentSongs"
    static let showRecentAlbums = "showRecentAlbums"
    static let showRecentArtists = "showRecentArtists"
    static let showRecentAlbumArtists = "showRecentAlbumArtists"
    static let showRecentComposers = "showRecentComposers"
    static let showRecentCompilations = "showRecentCompilations"
    static let showRecentGenres = "showRecentGenres"
    static let darkTheme = "darkThemeEnabled"
    static let keepShuffleState = "keepShuffleState"
    static let numbersBelowLetters = "numbersBelowLetters"
    static let strictAlbumBackground = "strictAlbumBackground" // not even sure
    static let artistStartingPoint = "artistStartingPoint"
    static let prefersSmallerArt = "prefersSmallerArt"
    static let showNowPlayingVolumeView = "showNowPlayingVolumeView"
    static let showExplicitness = "showExplicitness"
    static let playlistsView = "playlistsView"
    static let songCountVisible = "songCountVisible"
    static let songCellCategories = "songCellCategories"
    static let artistCellCategories = "artistCellCategories"
    static let albumCellCategories = "albumCellCategories"
    static let genreCellCategories = "genreCellCategories"
    static let composerCellCategories = "composerCellCategories"
    static let playlistCellCategories = "playlistCellCategories"
    static let deinitBannersEnabled = "deinitBanners"
    static let showInfoButtons = "showInfoButtons"
    static let playGuard = "playGuard"
    static let changeGuard = "changeGuard"
    static let addGuard = "addGuard"
    static let removeGuard = "removeGuard"
    static let clearGuard = "clearGuard"
    static let stopGuard = "stopGuard"
    static let refreshMode = "refreshMode"
    static let backToStart = "backToStart"
    static let showUnaddedMusic = "showUnaddedMusic"
    static let longPressDuration = "longPressDuration"
    static let darkTimeConstraintEnabled = "darkTimeConstraintEnabled"
    static let darkBrightnessConstraintEnabled = "darkBrightnessConstraintEnabled"
    static let brightnessValue = "brightnessValue"
    static let darkAnyConditionActive = "darkAnyConditionActive"
    static let fromHourComponent = "fromHourComponent"
    static let fromMinuteComponent = "fromMinuteComponent"
    static let toHourComponent = "toHourComponent"
    static let toMinuteComponent = "toMinuteComponent"
    static let fromTimeConstraint = "fromTimeConstraint"
    static let toTimeConstraint = "toTimeConstraint"
    static let manualNightMode = "manualNightMode"
    static let showCloseButton = "showCloseButton"
    static let collectorPreventsDuplicates = "collectorPreventsDuplicates"
    static let showSectionChooserEverywhere = "showSectionChooserEverywhere"
    static let fasterNowPlayingStartup = "fasterNowPlayingStartup"
    static let tabBarScrollToTop = "tabBarScrollToTop"
    static let screenLockPreventionMode = "screenLockPreventionMode"
    static let persistActionsView = "persistActionsView"
    static let persistArrangeView = "persistArrangeView"
    static let usePlaylistCustomBackground = "usePlaylistCustomBackground"
    static let useArtistCustomBackground = "useArtistCustomBackground"
    static let filterProperties = "filterProperties"
    static let librarySections = "librarySections"
    static let otherFilterProperties = "otherFilterProperties"
    static let otherLibrarySections = "otherLibrarySections"
    static let hiddenFilterProperties = "hiddenFilterProperties"
    static let hiddenLibrarySections = "hiddenLibrarySections"
    static let useCompactCollector = "useCompactCollector"
    static let listsCornerRadius = "listsCornerRadius"
    static let infoCornerRadius = "infoCornerRadius"
    static let miniPlayerCornerRadius = "miniPlayerCornerRadius"
    static let fullScreenPlayerCornerRadius = "fullScreenPlayerCornerRadius"
    static let filterFuzziness = "filterFuzziness"
    static let iconLineWidth = "iconLineWidth"
    static let iconTheme = "iconTheme"
    static let iconType = "iconType"
    static let compressOnPause = "compressOnPause"
    static let avoidDoubleHeightBar = "avoidDoubleHeightBar"
    static let separationMethod = "separationMethod"
    static let showNowPlayingSupplementaryView = "showNowPlayingSupplementaryView"
    static let supplementaryItems = "supplementaryItems"
    static let useDescriptor = "useDescriptor"
    static let preserveRepeatState = "preserveRepeatState"
    static let useMediaItems = "useMediaItems"
    static let useOldStyleQueue = "useOldStyleQueue"
    static let libraryRefreshInterval = "libraryRefreshInterval"
    static let recentlyUpdatedPlaylistSorts = "recentlyUpdatedPlaylistSorts"
    static let showPlaylistFolders = "showPlaylistFolders"
    static let tabBarTapBehaviour = "tabBarTapBehaviour"
    static let backgroundArtworkAdaptivity = "backgroundArtworkAdaptivity"
    static let lyricsTextAlignment = "lyricsTextAlignment"
    static let removeArtistBrackets = "removeArtistBrackets"
    static let removeArtistPunctuation = "removeArtistPunctuation"
    static let removeArtistAmpersands = "removeArtistAmpersands"
    static let replaceArtistCensoredWords = "replaceArtistCensoredWords"
    static let removeTitleBrackets = "removeTitleBrackets"
    static let removeTitlePunctuation = "removeTitlePunctuation"
    static let removeTitleAmpersands = "removeTitleAmpersands"
    static let replaceTitleCensoredWords = "replaceTitleCensoredWords"
    static let sectionCountVisible = "sectionCountVisible"
    static let useWhiteColorBackground = "useWhiteColorBackground"
    static let useBlackColorBackground = "useBlackColorBackground"
    static let activeFont = "activeFont"
    static let barBlurBehaviour = "barBlurBehaviour"
    static let visibleInfoItems = "visibleInfoItems"
    static let includeAlbumName = "includeAlbumName"
    static let showLastFMLoginAlert = "showLastFMLoginAlert"
    static let showScrobbleAlert = "showScrobbleAlert"
    static let showLoveAlert = "showLoveAlert"
    static let showNowPlayingUpdateAlert = "showNowPlayingUpdateAlert"
    static let navBarArtworkMode = "navBarArtworkMode"
    static let allowPlayIncrementingSkip = "allowPlayIncrementingSkip"
    static let navBarConstant = "barConstant"
    static let useSystemSwitch = "useSystemSwitch"
    static let useSystemAlerts = "useSystemAlerts"
    static let theme = "appTheme"
    static let useArtworkInShowMenu = "useArtworkInShowMenu"
    static let lastUsedPlaylists = "lastUsedPlaylists"
    static let showPlaylistHistory = "showPlaylistHistory"
    static let defaultCollectionSortCategories = "defaultCollectionSortCategories"
    static let defaultCollectionSortOrders = "defaultCollectionSortOrders"
    static let useExpandedSlider = "useExpandedSlider"
    static let showMiniPlayerSongTitles = "showMiniPlayerSongTitles"
    static let showTabBarLabels = "showTabBarLabels"
    static let useQueuePositionMiniPlayerTitle = "useQueuePositionMiniPlayerTitle"
    static let showCustomCollections = "showCustomCollections"
    static let hideMiniPlayerTabLabel = "hideMiniPlayerTabLabel"
}

// MARK: - Notification Settings Constants
extension NSNotification.Name {
    
    // MARK: Settings
    static let iCloudVisibilityChanged = Notification.Name.init(rawValue: "iCloudVisibilityChanged")
    static let recentSearchLimitChanged = Notification.Name.init(rawValue: "recentSearchLimitChanged")
    static let dynamicStatusBarChanged = Notification.Name.init(rawValue: "dynamicStatusBarChanged")
    static let nowPlayingTextSizesChanged = Notification.Name.init("nowPlayingTextSizesChanged")
    static let infoTextSizesChanged = Notification.Name.init("infoTextSizesChanged")
    static let infoButtonVisibilityChanged = Notification.Name.init("infoTextSizesChanged")
    static let tableViewHeaderSizesChanged = Notification.Name.init("infoButtonVisibilityChanged")
    static let playOnlyChanged = Notification.Name.init("playOnlyChanged")
    static let settingsDismissed = Notification.Name.init("settingsVCDismissed")
    static let emptyPlaylistsVisibilityChanged = Notification.Name.init("emptyPlaylistsChanged")
    static let backgroundArtworkAdaptivityChanged = Notification.Name.init("backgroundArtworkAdaptivityChanged")
    static let songCellCategoriesChanged = Notification.Name.init("songCellCategoriesChanged")
    static let artistCellCategoriesChanged = nameByAppending(to: "artistCellCategories")
    static let albumCellCategoriesChanged = nameByAppending(to: "albumCellCategories")
    static let genreCellCategoriesChanged = nameByAppending(to: "genreCellCategories")
    static let composerCellCategoriesChanged = nameByAppending(to: "composerCellCategories")
    static let playlistCellCategoriesChanged = nameByAppending(to: "playlistCellCategories")
    static let volumeVisibilityChanged = Notification.Name.init("volumeVisibilityChanged")
    static let longPressDurationChanged = Notification.Name.init("longPressDurationChanged")
    static let timeConstraintChanged = Notification.Name.init("timeConstraintChanged")
    static let fromTimeConstraintChanged = Notification.Name.init("fromTimeConstraintChanged")
    static let toTimeConstraintChanged = Notification.Name.init("toTimeConstraintChanged")
    static let brightnessConstraintChanged = Notification.Name.init("brightnessConstraintChanged")
    static let brightnessValueChanged = Notification.Name.init("brightnessValueChanged")
    static let anyConditionChanged = Notification.Name.init("anyConditionChanged")
    static let showCloseButtonChanged = Notification.Name.init("showCloseButtonChanged")
    static let lighterBordersChanged = Notification.Name.init("lighterBordersChanged")
    static let playerChanged = Notification.Name.init("playerChanged")
    static let collectorSizeChanged = Notification.Name.init("collectorSizeChanged")
    static let cornerRadiusChanged = Notification.Name.init("cornerRadiusChanged")
    static let filterFuzzinessChanged = Notification.Name.init("filterFuzzinessChanged")
    static let compressOnPauseChanged = Notification.Name.init("compressOnPauseChanged")
    static let avoidDoubleHeightBarChanged = Notification.Name.init("avoidDoubleHeightBarChanged")
    static let separationMethodChanged = Notification.Name.init("separationMethodChanged")
    static let showNowPlayingSupplementaryViewChanged = Notification.Name.init("showNowPlayingSupplementaryViewChanged")
    static let supplementaryItemsChanged = Notification.Name.init("supplementaryItemsChanged")
    static let libraryRefreshIntervalChanged = Notification.Name.init("libraryRefreshIntervalChanged")
    static let showRecentPlaylistsChanged = Notification.Name.init("showRecentPlaylistsChanged")
    static let showRecentSongsChanged = Notification.Name.init("showRecentSongsChanged")
    static let showRecentAlbumsChanged = Notification.Name.init("showRecentAlbumsChanged")
    static let showRecentArtistsChanged = Notification.Name.init("showRecentArtistsChanged")
    static let showRecentAlbumArtistsChanged = Notification.Name.init("showRecentAlbumArtistsChanged")
    static let showRecentComposersChanged = Notification.Name.init("showRecentComposersChanged")
    static let showRecentCompilationsChanged = Notification.Name.init("showRecentCompilationsChanged")
    static let showRecentGenresChanged = Notification.Name.init("showRecentGenresChanged")
    static let recentlyUpdatedPlaylistSortsChanged = Notification.Name.init("recentlyUpdatedPlaylistSortsChanged")
    static let showPlaylistFoldersChanged = Notification.Name.init("showPlaylistFoldersChanged")
    static let entityCountVisibilityChanged = Notification.Name.init("entityCountVisibilityChanged")
    static let numbersBelowLettersChanged = Notification.Name.init("numbersBelowLettersChanged")
    static let lyricsTextAlignmentChanged = nameByAppending(to: .lyricsTextAlignment)
    static let lyricsTextOptionsChanged = nameByAppending(to: "lyricsTextOptions")
    static let showExplicitnessChanged = nameByAppending(to: .showExplicitness)
    static let sectionCountVisiblityChanged = nameByAppending(to: .sectionCountVisible)
    static let useWhiteColorBackgroundChanged = nameByAppending(to: .useWhiteColorBackground)
    static let useBlackColorBackgroundChanged = nameByAppending(to: .useBlackColorBackground)
    static let activeFontChanged = nameByAppending(to: .activeFont)
    static let barBlurBehaviourChanged = nameByAppending(to: .barBlurBehaviour)
    static let lineHeightsCalculated = Notification.Name.init("lineHeightsCalculated")
    static let headerHeightCalculated = Notification.Name.init("headerHeightCalculated")
    static let visibleInfoItemsChanged = nameByAppending(to: .visibleInfoItems)
    static let navBarArtworkModeChanged = nameByAppending(to: .navBarArtworkMode)
    static let navBarConstantChanged = nameByAppending(to: .navBarConstant)
    static let useSystemSwitchChanged = nameByAppending(to: .useSystemSwitch)
    static let collectionSortChanged = nameByAppending(to: "collectionSort")
    static let useExpandedSliderChanged = nameByAppending(to: .useExpandedSlider)
    static let showMiniPlayerSongTitlesChanged = nameByAppending(to: .showMiniPlayerSongTitles)
    static let showTabBarLabelsChanged = nameByAppending(to: .showTabBarLabels)
    static let useQueuePositionMiniPlayerTitleChanged = nameByAppending(to: .useQueuePositionMiniPlayerTitle)
    static let hideMiniPlayerTabLabelChanged = nameByAppending(to: .hideMiniPlayerTabLabel)
    
    static func nameByAppending(to text: String) -> Notification.Name {
        
        return Notification.Name.init(text + "Changed")
    }
}
