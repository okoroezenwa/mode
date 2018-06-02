//
//  Settings.swift
//  Melody
//
//  Created by Ezenwa Okoro on 25/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

var dynamicStatusBar: Bool { return prefs.bool(forKey: .dynamicStatusBar) } // 1.0
var nowPlayingBoldTextEnabled: Bool { return prefs.bool(forKey: .nowPlayingBoldTitle) }
var allowPlayOnly: Bool { return prefs.bool(forKey: .playOnlyShortcut) }
var recentSearchLimit: Int { return prefs.integer(forKey: .recentSearchLimit) } // 1.0, used in 1.2?
var songsCriteria: Int { return prefs.integer(forKey: .songsSort) } // 1.0
var songsOrder: Bool { return prefs.bool(forKey: .songsOrder) } // 1.0
var albumsCriteria: Int { return prefs.integer(forKey: .albumsSort) } // 1.2
var albumsOrder: Bool { return prefs.bool(forKey: .albumsOrder) }
var artistsCriteria: Int { return prefs.integer(forKey: .artistsSort) }
var artistsOrder: Bool { return prefs.bool(forKey: .artistsOrder) }
var genresCriteria: Int { return prefs.integer(forKey: .genresSort) }
var genresOrder: Bool { return prefs.bool(forKey: .genresOrder) }
var compilationsCriteria: Int { return prefs.integer(forKey: .compilationsSort) }
var compilationsOrder: Bool { return prefs.bool(forKey: .compilationsOrder) }
var composersCriteria: Int { return prefs.integer(forKey: .composersSort) }
var composersOrder: Bool { return prefs.bool(forKey: .composersOrder) }
var playlistsCriteria: Int { return prefs.integer(forKey: .playlistsSort) }
var playlistsOrder: Bool { return prefs.bool(forKey: .playlistsOrder) }
public var warnForQueueInterruption: Bool { return prefs.bool(forKey: .warnInterruption) } // 1.0
var showiCloudItems: Bool { return prefs.bool(forKey: .iCloudItems) }
var firstAuthorisation: Bool { return prefs.bool(forKey: .firstAuthorisation) }
var shouldHideEmptyPlaylists: Bool { return prefs.bool(forKey: .hideEmptyPlaylists) }
var lastUsedLibrarySection: Int { return prefs.integer(forKey: .lastUsedLibrarySection) }
var lastUsedTab: Int { return prefs.integer(forKey: .lastUsedTab) }
var filterShortcutEnabled: Bool { return prefs.bool(forKey: .filterShortcutEnabled) }
var boldHeaders: Bool { return prefs.bool(forKey: .boldSectionTitles) } // 1.0, used in 1.2
var showRecentPlaylists: Bool { return prefs.bool(forKey: .showRecentPlaylists) } // 1.1, used in 1.2
public var keepShuffleState: Bool { return prefs.bool(forKey: .keepShuffleState) }
var numbersBelowLetters: Bool { return prefs.bool(forKey: .numbersBelowLetters) } // 1.2
var showRecentComposers: Bool { return prefs.bool(forKey: .showRecentComposers) }
var showRecentArtists: Bool { return prefs.bool(forKey: .showRecentArtists) }
var showRecentAlbums: Bool { return prefs.bool(forKey: .showRecentAlbums) }
var showRecentSongs: Bool { return prefs.bool(forKey: .showRecentSongs) }
var showRecentCompilations: Bool { return prefs.bool(forKey: .showRecentCompilations) }
var showRecentGenres: Bool { return prefs.bool(forKey: .showRecentGenres) }
var nowPlayingAsBackground: Bool { return prefs.bool(forKey: .useNowPlayingAsBackground) }
var strictAlbumBackground: Bool { return prefs.bool(forKey: .strictAlbumBackground) }
var artistItemsStartingPoint: Int { return prefs.integer(forKey: .artistStartingPoint) }
var useSmallerArt: Bool { return prefs.bool(forKey: .prefersSmallerArt) }
var showVolumeViews: Bool { return prefs.bool(forKey: .showNowPlayingVolumeView) }
var darkTheme: Bool { return prefs.bool(forKey: .darkTheme) }
var showExplicit: Bool { return prefs.bool(forKey: .showExplicitness) }
var songCountVisible: Bool { return prefs.bool(forKey: .songCountVisible) }
var playlistsView: Int { return prefs.integer(forKey: .playlistsView) }
var infoBoldTextEnabled: Bool { return prefs.bool(forKey: .infoBoldText) }
var songSecondaryDetails: [SecondaryCategory]? { return (prefs.array(forKey: .songCellCategories) as? [Int])?.flatMap({ SecondaryCategory(rawValue: $0) }) }
var deinitBannersEnabled: Bool { return prefs.bool(forKey: .deinitBannersEnabled) }
var showInfoButtons: Bool { return prefs.bool(forKey: .showInfoButtons) }
var addGuard: Bool { return prefs.bool(forKey: .addGuard) }
public var playGuard: Bool { return prefs.bool(forKey: .playGuard) }
var stopGuard: Bool { return prefs.bool(forKey: .stopGuard) }
var clearGuard: Bool { return prefs.bool(forKey: .clearGuard) }
var changeGuard: Bool { return prefs.bool(forKey: .changeGuard) }
var removeGuard: Bool { return prefs.bool(forKey: .removeGuard) }
var useMicroPlayer: Bool { return prefs.bool(forKey: .microPlayer) }
var refreshMode: Int { return prefs.integer(forKey: .refreshMode) }
var backToStartEnabled: Bool { return prefs.bool(forKey: .backToStart) }
var showUnaddedMusic: Bool { return prefs.bool(forKey: .showUnaddedMusic) }
var useSystemPlayer: Bool { return prefs.bool(forKey: .systemPlayer) }
var longPressDuration: Double { return prefs.double(forKey: .longPressDuration) }
var timeConstraintEnabled: Bool { return prefs.bool(forKey: .darkTimeConstraintEnabled) }
var brightnessConstraintEnabled: Bool { return prefs.bool(forKey: .darkBrightnessConstraintEnabled) }
var brightnessValue: Float { return prefs.float(forKey: .brightnessValue) }
var anyConditionActive: Bool { return prefs.bool(forKey: .darkAnyConditionActive) }
var manualNightMode: Bool { return prefs.bool(forKey: .manualNightMode) }
var showCloseButton: Bool { return prefs.bool(forKey: .showCloseButton) }
var fromHourComponent: Int { return prefs.integer(forKey: .fromHourComponent) }
var fromMinuteComponent: Int { return prefs.integer(forKey: .fromMinuteComponent) }
var toHourComponent: Int { return prefs.integer(forKey: .toHourComponent) }
var toMinuteComponent: Int { return prefs.integer(forKey: .toMinuteComponent) }
var collectorPreventsDuplicates: Bool { return prefs.bool(forKey: .collectorPreventsDuplicates) }
var showSectionChooserEverywhere: Bool { return prefs.bool(forKey: .showSectionChooserEverywhere) }
var fasterNowPlayingStartup: Bool { return prefs.bool(forKey: .fasterNowPlayingStartup) }
var useLighterBorders: Bool { return prefs.bool(forKey: .lighterBorders) }
var tabBarScrollToTop: Bool { return prefs.bool(forKey: .tabBarScrollToTop) }
var screenLockPreventionMode: Int { return prefs.integer(forKey: .screenLockPreventionMode) }
var persistArrangeView: Bool { return prefs.bool(forKey: .persistArrangeView) }
var persistActionsView: Bool { return prefs.bool(forKey: .persistActionsView) }
var usePlaylistCustomBackground: Bool { return prefs.bool(forKey: .usePlaylistCustomBackground) }
var useArtistCustomBackground: Bool { return prefs.bool(forKey: .useArtistCustomBackground) }
var primarySizeSuffix: Int { return prefs.integer(forKey: .primarySizeSuffix) }
var secondarySizeSuffix: Int { return prefs.integer(forKey: .secondarySizeSuffix) }
var filterProperties: [Property] { return prefs.array(forKey: .filterProperties)?.flatMap({ $0 as? Int }).flatMap({ Property(rawValue: $0) }) ?? [] }
var librarySections: [LibrarySection]{ return prefs.array(forKey: .librarySections)?.flatMap({ $0 as? Int }).flatMap({ LibrarySection(rawValue: $0) }) ?? [] }
var useCompactCollector: Bool { return prefs.bool(forKey: .useCompactCollector) }
var cornerRadius: CornerRadius { return CornerRadius(rawValue: prefs.integer(forKey: .cornerRadius)) ?? .automatic }
var widgetCornerRadius: CornerRadius? { return CornerRadius(rawValue: prefs.integer(forKey: .widgetCornerRadius)) }
var listsCornerRadius: CornerRadius? { return CornerRadius(rawValue: prefs.integer(forKey: .listsCornerRadius)) }
var infoCornerRadius: CornerRadius? { return CornerRadius(rawValue: prefs.integer(forKey: .infoCornerRadius)) }
var miniPlayerCornerRadius: CornerRadius? { return CornerRadius(rawValue: prefs.integer(forKey: .miniPlayerCornerRadius)) }
var compactCornerRadius: CornerRadius? { return CornerRadius(rawValue: prefs.integer(forKey: .compactCornerRadius)) }
var fullPlayerCornerRadius: CornerRadius? { return CornerRadius(rawValue: prefs.integer(forKey: .fullScreenPlayerCornerRadius)) }
var filterFuzziness: Double { return prefs.double(forKey: .filterFuzziness) }
var iconTheme: IconTheme { return IconTheme(rawValue: prefs.integer(forKey: .iconTheme)) ?? .light }
var iconLineWidth: IconLineWidth { return IconLineWidth(rawValue: prefs.integer(forKey: .iconLineWidth)) ?? .thin }
var compressOnPause: Bool { return prefs.bool(forKey: .compressOnPause) }
var avoidDoubleHeightBar: Bool { return prefs.bool(forKey: .avoidDoubleHeightBar) }
var separationMethod: SeparationMethod { return SeparationMethod(rawValue: prefs.integer(forKey: .separationMethod)) ?? Settings.defaultSeparationMethod }
var showNowPlayingSupplementaryView: Bool { return prefs.bool(forKey: .showNowPlayingSupplementaryView) }
var supplementaryItems: [Int] { return prefs.array(forKey: .supplementaryItems) as? [Int] ?? [SupplementaryItems.volume.rawValue] }
var useDescriptor: Bool { return prefs.bool(forKey: .useDescriptor) }
var preserveRepeatState: Bool { return prefs.bool(forKey: .preserveRepeatState) }
var useMediaItems: Bool { return prefs.bool(forKey: .useMediaItems) }
var useOldStyleQueue: Bool { return prefs.bool(forKey: .useOldStyleQueue) }
var forceOldStyleQueue: Bool { return Settings.forceOldStyleQueue }
var libraryRefreshInterval: LibraryRefreshInterval { return LibraryRefreshInterval(rawValue: prefs.integer(forKey: .libraryRefreshInterval)) ?? Settings.defaultRefreshInterval }
var recentlyUpdatedPlaylistSorts: Set<PlaylistView> { return Set((prefs.array(forKey: .recentlyUpdatedPlaylistSorts) as? [Int])?.flatMap({ PlaylistView(rawValue: $0) }) ?? Settings.defaultRecentlyUpdatedPlaylistSorts) }
var showPlaylistFolders: Bool { return prefs.bool(forKey: .showPlaylistFolders) }
var tabBarTapBehaviour: TabBarTapBehaviour { return TabBarTapBehaviour(rawValue: prefs.integer(forKey: .tabBarTapBehaviour)) ?? Settings.defaultTabBarBehaviour }

class Settings {
    
    class var isInDebugMode: Bool {
        
        #if DEBUG
            
            return true
            
        #else
            
            return false
            
        #endif
    }

    class func registerDefaults() {
        
        prefs.register(defaults: [
            
            .dynamicStatusBar: true,
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
            .genresSort: SortCriteria.standard.rawValue,
            .genresOrder: true,
            .composersSort: SortCriteria.standard.rawValue,
            .composersOrder: true,
            .compilationsSort: SortCriteria.standard.rawValue,
            .compilationsOrder: true,
            .playlistsSort: SortCriteria.standard.rawValue,
            .playlistsOrder: true,
            .firstAuthorisation: true,
            .hideEmptyPlaylists: isInDebugMode,
            .lastUsedLibrarySection: LibrarySection.artists.rawValue,
            .lastUsedTab: StartPoint.library.rawValue,
            .filterShortcutEnabled: false,
            .showRecentPlaylists: true,
            .showRecentSongs: isInDebugMode.inverted,
            .showRecentArtists: isInDebugMode.inverted,
            .showRecentAlbums: isInDebugMode.inverted,
            .showRecentGenres: isInDebugMode.inverted,
            .showRecentComposers: isInDebugMode.inverted,
            .showRecentCompilations: isInDebugMode.inverted,
            .keepShuffleState: !isInDebugMode,
            .numbersBelowLetters: true,
            .useNowPlayingAsBackground: !isInDebugMode,
            .strictAlbumBackground: false,
            .artistStartingPoint: 1,
            .prefersSmallerArt: isiPhoneX,
            .showNowPlayingVolumeView: true,
            .darkTheme: false,
            .showExplicitness: true, // incomplete
            .songCountVisible: true,
            .playlistsView: PlaylistView.all.rawValue,
            .songCellCategories: Settings.songSecondarySubviews,
            .infoBoldText: false, // not set
            .deinitBannersEnabled: false,
            .showInfoButtons: !isInDebugMode,
            .addGuard: false,
            .playGuard: true,
            .stopGuard: false,
            .clearGuard: true,
            .changeGuard: false,
            .removeGuard: true,
            .microPlayer: true,
            .refreshMode: RefreshMode.refresh.rawValue, // may not bother
            .backToStart: !isInDebugMode,
            .showUnaddedMusic: false, // not set
            .systemPlayer: useSystemMusicPlayer,
            .longPressDuration: GestureDuration.medium.rawValue,
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
            .showSectionChooserEverywhere: false,
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
            .filterProperties: Array(Property.title.rawValue...Property.isCompilation.rawValue),
            .librarySections: [LibrarySection.playlists, .songs, .artists, .albums, .genres, .composers, .compilations].map({ $0.rawValue }),
            .useCompactCollector: true,
            .widgetCornerRadius: CornerRadius.large.rawValue,
            .listsCornerRadius: CornerRadius.automatic.rawValue,
            .infoCornerRadius: CornerRadius.automatic.rawValue,
            .miniPlayerCornerRadius: CornerRadius.square.rawValue,
            .compactCornerRadius: CornerRadius.large.rawValue,
            .fullScreenPlayerCornerRadius: CornerRadius.small.rawValue,
            .filterFuzziness: 0.4,
            .iconLineWidth: IconLineWidth.thin.rawValue,
            .iconTheme: IconTheme.light.rawValue,
            .compressOnPause: true,
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
            .tabBarTapBehaviour: defaultTabBarBehaviour.rawValue
        ])
        
        sharedDefaults.register(defaults: [
            
            .systemPlayer: useSystemMusicPlayer,
            .lighterBorders: useLighterBorders,
            .widgetCornerRadius: CornerRadius.small.rawValue
        ])
    }
    
    class func resetDefaults() {
        
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        
        prefs.removePersistentDomain(forName: bundleID)
        
        registerDefaults()
    }
    
    static var songSecondarySubviews: [Int] { return isInDebugMode ? [SecondaryCategory.dateAdded, .plays, .lastPlayed].map({ $0.rawValue }) : [] }
    
    static var forceOldStyleQueue: Bool {
        
        if #available(iOS 11.3, *), !useSystemPlayer {
            
            return true
            
        } else {
            
            return useOldStyleQueue
        }
    }
    
    static var useSystemMusicPlayer: Bool {
        
        if #available(iOS 11, *) {
            
            return true
        
        } else if #available(iOS 10.3, *) {
            
            return false
            
        } else {
            
            return true
        }
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
        
        if #available(iOS 11.3, *) {
            
            return isInDebugMode
            
        } else if #available(iOS 11, *) {
            
            return false
            
        } else if #available(iOS 10.3, *) {
            
            return false
            
        } else {
            
            return true
        }
    }
    
    static var defaultSeparationMethod: SeparationMethod { return isiPhoneX ? .below : .smaller }
    static var defaultRefreshInterval: LibraryRefreshInterval = .none // { return isInDebugMode ? .none : .fiveMinutes }
    static var defaultRecentlyUpdatedPlaylistSorts: [PlaylistView] { return isInDebugMode ? [.appleMusic] : [] }
    static var defaultTabBarBehaviour: TabBarTapBehaviour { return isInDebugMode ? .scrollToTop : .returnThenScroll }
    
    static func components(from date: Date) -> TimeConstraintComponents {
        
        return (Calendar.current.component(.hour, from: date), Calendar.current.component(.minute, from: date))
    }
}

// MARK: - String Settings Constants
extension String {
    
    // MARK: - Sortable
    static let songsSort = "songsSort"
    static let songsOrder = "songsOrder"
    static let albumsSort = "albumsSort"
    static let albumsOrder = "albumsOrder"
    static let artistsSort = "artistsSort"
    static let artistsOrder = "artistsOrder"
    static let genresSort = "genresSort"
    static let genresOrder = "genresOrder"
    static let compilationsSort = "compilationsSort"
    static let compilationsOrder = "compilationsOrder"
    static let composersSort = "composersSort"
    static let composersOrder = "composersOrder"
    static let playlistsSort = "playlistsSort"
    static let playlistsOrder = "playlistsOrder"
    
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
    static let filterShortcutEnabled = "filterShortcutEnabled"
    static let showRecentPlaylists = "showRecentPlaylists"
    static let showRecentSongs = "showRecentSongs"
    static let showRecentAlbums = "showRecentAlbums"
    static let showRecentArtists = "showRecentArtists"
    static let showRecentComposers = "showRecentComposers"
    static let showRecentCompilations = "showRecentCompilations"
    static let showRecentGenres = "showRecentGenres"
    static let darkTheme = "darkThemeEnabled"
    static let keepShuffleState = "keepShuffleState"
    static let numbersBelowLetters = "numbersBelowLetters"
    static let useNowPlayingAsBackground = "useNowPlayingAsBackground"
    static let strictAlbumBackground = "strictAlbumBackground" // not even sure
    static let artistStartingPoint = "artistStartingPoint"
    static let prefersSmallerArt = "prefersSmallerArt"
    static let showNowPlayingVolumeView = "showNowPlayingVolumeView"
    static let showExplicitness = "showExplicitness"
    static let playlistsView = "playlistsView"
    static let songCountVisible = "songCountVisible"
    static let songCellCategories = "songCellCategories"
    static let deinitBannersEnabled = "deinitBanners"
    static let showInfoButtons = "showInfoButtons"
    static let playGuard = "playGuard"
    static let changeGuard = "changeGuard"
    static let addGuard = "addGuard"
    static let removeGuard = "removeGuard"
    static let clearGuard = "clearGuard"
    static let stopGuard = "stopGuard"
    static let microPlayer = "microPlayer"
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
    static let useCompactCollector = "useCompactCollector"
    static let listsCornerRadius = "listsCornerRadius"
    static let infoCornerRadius = "infoCornerRadius"
    static let miniPlayerCornerRadius = "miniPlayerCornerRadius"
    static let compactCornerRadius = "compactCornerRadius"
    static let fullScreenPlayerCornerRadius = "fullScreenPlayerCornerRadius"
    static let filterFuzziness = "filterFuzziness"
    static let iconLineWidth = "iconLineWidth"
    static let iconTheme = "iconTheme"
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
    static let nowPlayingBackgroundUsageChanged = Notification.Name.init("nowPlayingBackgroundUsageChanged")
    static let themeChanged = Notification.Name.init("themeChanged")
    static let songCellCategoriesChanged = Notification.Name.init("songCellCategoriesChanged")
    static let microPlayerChanged = Notification.Name.init("microPlayerChanged")
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
    static let showRecentComposersChanged = Notification.Name.init("showRecentComposersChanged")
    static let showRecentCompilationsChanged = Notification.Name.init("showRecentCompilationsChanged")
    static let showRecentGenresChanged = Notification.Name.init("showRecentGenresChanged")
    static let recentlyUpdatedPlaylistSortsChanged = Notification.Name.init("recentlyUpdatedPlaylistSortsChanged")
    static let showPlaylistFoldersChanged = Notification.Name.init("showPlaylistFoldersChanged")
    static let entityCountVisibilityChanged = Notification.Name.init("entityCountVisibilityChanged")
    static let numbersBelowLettersChanged = Notification.Name.init("numbersBelowLettersChanged")
}
