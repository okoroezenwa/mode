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
var albumArtistsCriteria: Int { return prefs.integer(forKey: .albumArtistsSort) }
var albumArtistsOrder: Bool { return prefs.bool(forKey: .albumArtistsOrder) }
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
var boldHeaders: Bool { return prefs.bool(forKey: .boldSectionTitles) } // 1.0, used in 1.2
var showRecentPlaylists: Bool { return prefs.bool(forKey: .showRecentPlaylists) } // 1.1, used in 1.2
public var keepShuffleState: Bool { return prefs.bool(forKey: .keepShuffleState) }
var numbersBelowLetters: Bool { return prefs.bool(forKey: .numbersBelowLetters) } // 1.2
var showRecentComposers: Bool { return prefs.bool(forKey: .showRecentComposers) }
var showRecentArtists: Bool { return prefs.bool(forKey: .showRecentArtists) }
var showRecentAlbumArtists: Bool { return prefs.bool(forKey: .showRecentAlbumArtists) }
var showRecentAlbums: Bool { return prefs.bool(forKey: .showRecentAlbums) }
var showRecentSongs: Bool { return prefs.bool(forKey: .showRecentSongs) }
var showRecentCompilations: Bool { return prefs.bool(forKey: .showRecentCompilations) }
var showRecentGenres: Bool { return prefs.bool(forKey: .showRecentGenres) }
var strictAlbumBackground: Bool { return prefs.bool(forKey: .strictAlbumBackground) }
var artistItemsStartingPoint: Int { return prefs.integer(forKey: .artistStartingPoint) }
var useSmallerArt: Bool { return prefs.bool(forKey: .prefersSmallerArt) }
var showVolumeViews: Bool { return prefs.bool(forKey: .showNowPlayingVolumeView) }
var darkTheme: Bool { Themer.shared.darkThemeExpected(basedOn: appTheme)/*return prefs.bool(forKey: .darkTheme)*/ }
var showExplicit: Bool { return prefs.bool(forKey: .showExplicitness) }
var songCountVisible: Bool { return prefs.bool(forKey: .songCountVisible) }
var playlistsView: Int { return prefs.integer(forKey: .playlistsView) }
var infoBoldTextEnabled: Bool { return prefs.bool(forKey: .infoBoldText) }
var songSecondaryDetails: [SecondaryCategory]? { return (prefs.array(forKey: .songCellCategories) as? [Int])?.compactMap({ SecondaryCategory(rawValue: $0) }) }
var deinitBannersEnabled: Bool { return prefs.bool(forKey: .deinitBannersEnabled) }
var showInfoButtons: Bool { return prefs.bool(forKey: .showInfoButtons) }
var addGuard: Bool { return prefs.bool(forKey: .addGuard) }
public var playGuard: Bool { return prefs.bool(forKey: .playGuard) }
var stopGuard: Bool { return prefs.bool(forKey: .stopGuard) }
var clearGuard: Bool { return prefs.bool(forKey: .clearGuard) }
var changeGuard: Bool { return prefs.bool(forKey: .changeGuard) }
var removeGuard: Bool { return prefs.bool(forKey: .removeGuard) }
var refreshMode: Int { return prefs.integer(forKey: .refreshMode) }
var backToStartEnabled: Bool { return prefs.bool(forKey: .backToStart) }
var showUnaddedMusic: Bool { return prefs.bool(forKey: .showUnaddedMusic) }
var useSystemPlayer: Bool { return prefs.bool(forKey: .systemPlayer) }
var gestureDuration: GestureDuration { return GestureDuration(rawValue: prefs.integer(forKey: .longPressDuration)) ?? Settings.defaultGestureDuration }
var longPressDuration: Double { return gestureDuration.duration }
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
var persistArrangeView: Bool {
    
    get { return prefs.bool(forKey: .persistArrangeView) }
    
    set { prefs.set(newValue, forKey: .persistArrangeView) }
}
var persistActionsView: Bool { return prefs.bool(forKey: .persistActionsView) }
var usePlaylistCustomBackground: Bool { return prefs.bool(forKey: .usePlaylistCustomBackground) }
var useArtistCustomBackground: Bool { return prefs.bool(forKey: .useArtistCustomBackground) }
var primarySizeSuffix: Int { return prefs.integer(forKey: .primarySizeSuffix) }
var secondarySizeSuffix: Int { return prefs.integer(forKey: .secondarySizeSuffix) }
var filterProperties: [Property] { return prefs.array(forKey: .filterProperties)?.compactMap({ Property.fromOldRawValue($0 as? Property.RawValue) }) ?? [] }
var librarySections: [LibrarySection]{ return prefs.array(forKey: .librarySections)?.compactMap({ LibrarySection.from($0 as? LibrarySection.RawValue) }) ?? [] }
var otherFilterProperties: [Property] { return prefs.array(forKey: .otherFilterProperties)?.compactMap({ Property.fromOldRawValue($0 as? Property.RawValue) }) ?? [] }
var otherLibrarySections: [LibrarySection]{ return prefs.array(forKey: .otherLibrarySections)?.compactMap({ LibrarySection.from($0 as? LibrarySection.RawValue) }) ?? [] }
var useCompactCollector: Bool { return prefs.bool(forKey: .useCompactCollector) }
var cornerRadius: CornerRadius { return CornerRadius(rawValue: prefs.integer(forKey: .cornerRadius)) ?? .automatic }
var widgetCornerRadius: CornerRadius? { return CornerRadius(rawValue: prefs.integer(forKey: .widgetCornerRadius)) }
var listsCornerRadius: CornerRadius? { return CornerRadius(rawValue: prefs.integer(forKey: .listsCornerRadius)) }
var infoCornerRadius: CornerRadius? { return CornerRadius(rawValue: prefs.integer(forKey: .infoCornerRadius)) }
var miniPlayerCornerRadius: CornerRadius? { return CornerRadius(rawValue: prefs.integer(forKey: .miniPlayerCornerRadius)) }
var fullPlayerCornerRadius: CornerRadius? { return CornerRadius(rawValue: prefs.integer(forKey: .fullScreenPlayerCornerRadius)) }
var filterFuzziness: Double { return prefs.double(forKey: .filterFuzziness) }
var iconTheme: IconTheme { return IconTheme(rawValue: prefs.integer(forKey: .iconTheme)) ?? .light }
var iconLineWidth: IconLineWidth { return IconLineWidth(rawValue: prefs.integer(forKey: .iconLineWidth)) ?? .thin }
var iconType: IconType { return IconType(rawValue: prefs.integer(forKey: .iconType)) ?? .regular }
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
var recentlyUpdatedPlaylistSorts: Set<PlaylistView> { return Set((prefs.array(forKey: .recentlyUpdatedPlaylistSorts) as? [Int])?.compactMap({ PlaylistView(rawValue: $0) }) ?? Settings.defaultRecentlyUpdatedPlaylistSorts) }
var showPlaylistFolders: Bool { return prefs.bool(forKey: .showPlaylistFolders) }
var tabBarTapBehaviour: TabBarTapBehaviour { return TabBarTapBehaviour(rawValue: prefs.integer(forKey: .tabBarTapBehaviour)) ?? Settings.defaultTabBarBehaviour }
var backgroundArtworkAdaptivity: BackgroundArtwork { return BackgroundArtwork(rawValue: prefs.integer(forKey: .backgroundArtworkAdaptivity)) ?? .sectionAdaptive }
var lyricsTextAlignment: NSTextAlignment { return NSTextAlignment(rawValue: prefs.integer(forKey: .lyricsTextAlignment)) ?? .center }
var removeTitleBrackets: Bool { return prefs.bool(forKey: .removeTitleBrackets) }
var removeTitleAmpersands: Bool { return prefs.bool(forKey: .removeTitleAmpersands) }
var removeTitlePunctuation: Bool { return prefs.bool(forKey: .removeTitlePunctuation) }
var removeArtistBrackets: Bool { return prefs.bool(forKey: .removeArtistBrackets) }
var removeArtistPunctuation: Bool { return prefs.bool(forKey: .removeArtistPunctuation) }
var removeArtistAmpersands: Bool { return prefs.bool(forKey: .removeArtistAmpersands) }
var replaceTitleCensoredWords: Bool { return prefs.bool(forKey: .replaceTitleCensoredWords) }
var replaceArtistCensoredWords: Bool { return prefs.bool(forKey: .replaceArtistCensoredWords) }
var sectionCountVisible: Bool { return prefs.bool(forKey: .sectionCountVisible) }
var useWhiteColorBackground: Bool { return prefs.bool(forKey: .useWhiteColorBackground) }
var useBlackColorBackground: Bool { return prefs.bool(forKey: .useBlackColorBackground) }
var hiddenFilterProperties: [Property] { return prefs.array(forKey: .hiddenFilterProperties)?.compactMap({ Property.from($0 as? Property.RawValue) }) ?? [] }
var hiddenLibrarySections: [LibrarySection] { return prefs.array(forKey: .hiddenLibrarySections)?.compactMap({ LibrarySection.from($0 as? LibrarySection.RawValue) }) ?? [] }
var activeFont: Font { return Font(rawValue: prefs.integer(forKey: .activeFont)) ?? .system }
var barBlurBehaviour: BarBlurBehavour { return BarBlurBehavour(rawValue: prefs.integer(forKey: .barBlurBehaviour)) ?? .all }
//var visibleInfoItems: [InfoSection] { return prefs.array(forKey: .visibleInfoItems)?.compactMap({ InfoSection.from($0 as? InfoSection.RawValue) }) ?? [] }
var includeAlbumName: Bool {
    
    get { prefs.bool(forKey: .includeAlbumName) }
    
    set { prefs.set(newValue, forKey: .includeAlbumName) }
}

var showLastFMLoginAlert: Bool {
    
    get { prefs.bool(forKey: .showLastFMLoginAlert) }
    
    set { prefs.set(newValue, forKey: .showLastFMLoginAlert) }
}

var showScrobbleAlert: Bool {
    
    get { prefs.bool(forKey: .showScrobbleAlert) }
    
    set { prefs.set(newValue, forKey: .showScrobbleAlert) }
}

var showLoveAlert: Bool {
    
    get { prefs.bool(forKey: .showLoveAlert) }
    
    set { prefs.set(newValue, forKey: .showLoveAlert) }
}

var showNowPlayingUpdateAlert: Bool {
    
    get { prefs.bool(forKey: .showNowPlayingUpdateAlert) }
    
    set { prefs.set(newValue, forKey: .showNowPlayingUpdateAlert) }
}

var navBarArtworkMode: VisualEffectNavigationBar.ArtworkMode {
    
    get { VisualEffectNavigationBar.ArtworkMode(rawValue: prefs.integer(forKey: .navBarArtworkMode)) ?? .small }
    
    set { prefs.set(newValue.rawValue, forKey: .navBarArtworkMode) }
}

var allowPlayIncrementingSkip: Bool {
    
    get { prefs.bool(forKey: .allowPlayIncrementingSkip) }
    
    set { prefs.set(newValue, forKey: .allowPlayIncrementingSkip) }
}

var navBarConstant: TopBarOffset {
    
    get { VisualEffectNavigationBar.ArtworkMode(rawValue: prefs.integer(forKey: .navBarConstant)) ?? .large }
    
    set { prefs.set(newValue.rawValue, forKey: .navBarConstant) }
}

var useSystemSwitch: Bool {
    
    get { prefs.bool(forKey: .useSystemSwitch) }
    
    set {
        
        prefs.set(newValue, forKey: .useSystemSwitch)
        notifier.post(name: .useSystemSwitchChanged, object: nil)
    }
}

var useSystemAlerts: Bool {
    
    get { prefs.bool(forKey: .useSystemAlerts) }
    
    set { prefs.set(newValue, forKey: .useSystemAlerts) }
}

var appTheme: Theme {
    
    get { Theme(rawValue: prefs.integer(forKey: .theme)) ?? .system }
    
    set {
        
        prefs.set(newValue.rawValue, forKey: .theme)
        notifier.post(name: .themeChanged, object: nil)
    }
}

var useArtworkInShowMenu: Bool {
    
    get { prefs.bool(forKey: .useArtworkInShowMenu) }
    
    set { prefs.set(newValue, forKey: .useArtworkInShowMenu) }
}

var playlistHistoryDetails: PlaylistHistoryDetails {
    
    get { (prefs.array(forKey: .lastUsedPlaylists) as? [MPMediaEntityPersistentID] ?? [], .get) }
    
    set {
        
        switch newValue.operation {
            
            case .reset: prefs.set([], forKey: .lastUsedPlaylists)
            
            case .insert:
            
                let set = Set(newValue.ids)
                let array = playlistHistoryDetails.ids.filter({ set.contains($0).inverted })
                
                prefs.set(array.inserting(contentsOf: newValue.ids.reversed(), at: 0), forKey: .lastUsedPlaylists)
            
            case .remove: prefs.set(playlistHistoryDetails.ids.removing(contentsOf: newValue.ids), forKey: .lastUsedPlaylists)
            
            case .get: return
        }
    }
}

var showPlaylistHistory: Bool {
    
    get { prefs.bool(forKey: .showPlaylistHistory) }
    
    set { prefs.set(newValue, forKey: .showPlaylistHistory) }
}

var collectionSortCategories: [String: Int]? {
    
    get { prefs.dictionary(forKey: .defaultCollectionSortCategories) as? [String: Int] }
    
    set { prefs.set(newValue, forKey: .defaultCollectionSortCategories) }
}

var collectionSortOrders: [String: Bool]? {
    
    get { prefs.dictionary(forKey: .defaultCollectionSortOrders) as? [String: Bool] }
    
    set { prefs.set(newValue, forKey: .defaultCollectionSortOrders) }
}

var useExpandedSlider: Bool {
    
    get { prefs.bool(forKey: .useExpandedSlider) }
    
    set {
        
        prefs.set(newValue, forKey: .useExpandedSlider)
        notifier.post(name: .useExpandedSliderChanged, object: nil)
    }
}

var showMiniPlayerSongTitles: Bool {
    
    get { prefs.bool(forKey: .showMiniPlayerSongTitles) }
    
    set {
        
        prefs.set(newValue, forKey: .showMiniPlayerSongTitles)
        notifier.post(name: .showMiniPlayerSongTitlesChanged, object: nil)
    }
}

var showTabBarLabels: Bool {
    
    get { prefs.bool(forKey: .showTabBarLabels) }
    
    set {
        
        prefs.set(newValue, forKey: .showTabBarLabels)
        notifier.post(name: .showTabBarLabelsChanged, object: nil)
    }
}

var useQueuePositionMiniPlayerTitle: Bool {
    
    get { prefs.bool(forKey: .useQueuePositionMiniPlayerTitle) }
    
    set {
        
        prefs.set(newValue, forKey: .useQueuePositionMiniPlayerTitle)
        notifier.post(name: .useQueuePositionMiniPlayerTitleChanged, object: nil)
    }
}

class Settings {
    
    class var isInDebugMode: Bool {
        
        #if DEBUG
            
            return true
            
        #else
            
            return false
            
        #endif
    }

    class func registerDefaults() {
        
        let defaultSortDetails: (sorts: [String: Int], orders: [String: Bool]) = [Location.album, .playlist, .collection(kind: .artist, point: .songs), .collection(kind: .artist, point: .albums), .collection(kind: .albumArtist, point: .songs), .collection(kind: .albumArtist, point: .albums), .collection(kind: .genre, point: .songs), .collection(kind: .genre, point: .albums), .collection(kind: .composer, point: .songs), .collection(kind: .composer, point: .albums)].map({ EntityType.collectionEntityDetails(for: $0) }).map({ $0.type.title(matchingPropertyName: true) + $0.startPoint.title }).reduce(([String: Int](), [String: Bool]()), { ($0.0.appending(key: $1, value: ($1.contains("rtistson") ? .albumName : SortCriteria.standard).rawValue), $0.1.appending(key: $1, value: true)) })
        
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
            .infoBoldText: false, // not set
            .deinitBannersEnabled: false,
            .showInfoButtons: true,
            .addGuard: false,
            .playGuard: true,
            .stopGuard: isInDebugMode,
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
            .useQueuePositionMiniPlayerTitle: true
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
        
        let sections = [LibrarySection.playlists, .songs, .artists]
        
        return isInDebugMode ? sections : sections + [.albumArtists, .albums, .genres, .composers, .compilations]
    }
    static var defaultOtherLibrarySections: [LibrarySection] { return isInDebugMode ? [.albums, .genres, .albumArtists, .composers, .compilations] : [] }
    
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
    static let themeChanged = Notification.Name.init("themeChanged")
    static let songCellCategoriesChanged = Notification.Name.init("songCellCategoriesChanged")
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
    
    static func nameByAppending(to text: String) -> Notification.Name {
        
        return Notification.Name.init(text + "Changed")
    }
}
