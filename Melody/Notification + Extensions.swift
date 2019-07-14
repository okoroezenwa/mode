//
//  Notification + Extensions.swift
//  Melody
//
//  Created by Ezenwa Okoro on 25/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    
    // MARK: Miscellaneous
    static let addedToQueue = Notification.Name.init("songAddedToQueue")
    static let beginQueueModification = Notification.Name.init("beginQueueModification")
    static let endQueueModification = Notification.Name.init("endQueueModification")
    static let performSecondaryAction = Notification.Name.init("performSecondaryAction")
    static let scrollCurrentViewToTop = Notification.Name.init("scrollCurrentViewToTop")
    static let removedFromQueue = Notification.Name.init("songsRemovedFromQueue")
    static let resetInsets = Notification.Name.init("resetBottomInsetsFromContainer")
    static let sortConflictFound = Notification.Name.init("conflictFoundInSort")
    static let addedToLibrary = Notification.Name.init("appleMusicSongAddedToLibrary")
    static let updateForFirstLaunch = Notification.Name.init("updateForFirstLaunch")
    static let songsAddedToPlaylists = Notification.Name.init("songsAddedToPlaylists")
    static let changeLibrarySection = Notification.Name.init(rawValue: "changeLibrarySection")
    static let appleMusicStatusChecked = Notification.Name.init(rawValue: "appleMusicStatusChecked")
    static let libraryStatusChanged = Notification.Name.init(rawValue: "userLibraryStatusChanged")
    static let libraryUpdated = Notification.Name.init(rawValue: "userLibraryUpdated")
    static let songWasEdited = Notification.Name.init("songValueWasChanged")
    static let nowPlayingItemChanged = Notification.Name.init("nowPlayingItemChanged")
    static let saveQueue = Notification.Name.init("saveQueue")
    static let queueUpdated = Notification.Name.init("queueHasBeenUpdated") // for QVC
    static let queueModified = Notification.Name.init("queueHasBeenModified") // for everyone else
    static let libraryOptionsChanged = Notification.Name.init("libraryOptionsChanged")
    static let ratingChanged = Notification.Name.init("ratingChanged")
    static let likedStateChanged = Notification.Name.init("likedStateChanged")
    static let showUnaddedSongsChanged = Notification.Name.init("showUnaddedSongsChanged")
    static let managerItemsChanged = Notification.Name.init("managerItemsChanged")
    static let shuffleInvoked = Notification.Name.init("shuffleInvoked")
    static let propertiesUpdated = Notification.Name(rawValue: "propertiesUpdated")
    static let playbackStopped = Notification.Name(rawValue: "playbackStopped")
    static let indexUpdated = Notification.Name.init("indexUpdated")
}
