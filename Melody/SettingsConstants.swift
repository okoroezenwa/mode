//
//  SettingsConstants.swift
//  Mode
//
//  Created by Ezenwa Okoro on 16/09/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
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

var albumSecondaryDetails: [SecondaryCategory] {
    
    get { (prefs.array(forKey: .albumCellCategories) as? [Int])?.compactMap({ SecondaryCategory(rawValue: $0) }) ?? [] }

    set {
        
        prefs.set(newValue, forKey: .albumCellCategories)
        notifier.post(name: .albumCellCategoriesChanged, object: nil)
    }
}

var artistSecondaryDetails: [SecondaryCategory] {
    
    get { (prefs.array(forKey: .artistCellCategories) as? [Int])?.compactMap({ SecondaryCategory(rawValue: $0) }) ?? [] }

    set {
        
        prefs.set(newValue, forKey: .artistCellCategories)
        notifier.post(name: .artistCellCategoriesChanged, object: nil)
    }
}

var genreSecondaryDetails: [SecondaryCategory] {
    
    get { (prefs.array(forKey: .genreCellCategories) as? [Int])?.compactMap({ SecondaryCategory(rawValue: $0) }) ?? [] }

    set {
        
        prefs.set(newValue, forKey: .genreCellCategories)
        notifier.post(name: .genreCellCategoriesChanged, object: nil)
    }
}

var composerSecondaryDetails: [SecondaryCategory] {
    
    get { (prefs.array(forKey: .composerCellCategories) as? [Int])?.compactMap({ SecondaryCategory(rawValue: $0) }) ?? [] }

    set {
        
        prefs.set(newValue, forKey: .composerCellCategories)
        notifier.post(name: .composerCellCategoriesChanged, object: nil)
    }
}

var playlistSecondaryDetails: [SecondaryCategory] {
    
    get { (prefs.array(forKey: .playlistCellCategories) as? [Int])?.compactMap({ SecondaryCategory(rawValue: $0) }) ?? [] }

    set {
        
        prefs.set(newValue, forKey: .playlistCellCategories)
        notifier.post(name: .playlistCellCategoriesChanged, object: nil)
    }
}
