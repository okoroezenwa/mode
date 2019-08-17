//
//  LastFMHandler.swift
//  Mode
//
//  Created by Ezenwa Okoro on 19/07/2019.
//  Copyright © 2019 Ezenwa Okoro. All rights reserved.
//

import Foundation

class Scrobbler {
    
    private init() { }
    
    static let shared = Scrobbler.init()
    var sessionInfoObtained = false
    var isAuthenticating = false
    
    func login(username: String, password: String, completion: Completions?) {
        
        isAuthenticating = true
        
        LastFm.sharedInstance()?.getSessionForUser(username, password: password, successHandler: { dictionary in
            
            DispatchQueue.main.async {
                
                guard let result = dictionary as? [String: Any], let name = result["name"] as? String, let key = result["key"] as? String else {
                    
                    self.isAuthenticating = false
                    completion?.error()
                    
                    return
                }
                
                prefs.set(key, forKey: .lastFMSessionKey)
                prefs.set(name, forKey: .lastFMUsername)
                
                self.setupLastFM(key: key, name: name, completion: completion)
            }
            
        }, failureHandler: { error in
            
            print(error as Any)
            
            self.isAuthenticating = false
            completion?.error()
        })
    }
    
    func setupLastFM(key: String? = prefs.string(forKey: .lastFMSessionKey), name: String? = prefs.string(forKey: .lastFMUsername), completion: Completions? = nil) {
        
        LastFm.sharedInstance().apiKey = "90a7ccbe108f675c385046807028d4e8"
        LastFm.sharedInstance().apiSecret = "f3ba0786d7888cd0166103badb00b676"
        
        guard let key = key, let name = name else {
            
            self.isAuthenticating = false
            completion?.error()
            
            return
        }
        
        LastFm.sharedInstance().session = key
        LastFm.sharedInstance().username = name
        
        LastFm.sharedInstance()?.getSessionInfo(successHandler: { dictionary in
            
            self.isAuthenticating = false
            self.sessionInfoObtained = true
            
            if showLastFMLoginAlert {
            
                UniversalMethods.banner(withTitle: "Successfully logged in to Last.fm", backgroundColor: .deepGreen).show(for: 2)
            }
            
            completion?.success()
            
        }, failureHandler: { error in
            
            print(error as Any)
            
            self.isAuthenticating = false
            
            if showLastFMLoginAlert {
                
                UniversalMethods.banner(withTitle: "Unable to log in to Last.fm", backgroundColor: .red).show(for: 2)
            }
            
            completion?.error()
        })
    }
    
    func logout() {
        
        LastFm.sharedInstance()?.logout()
        prefs.set(nil, forKey: .lastFMSessionKey)
        prefs.set(nil, forKey: .lastFMUsername)
        sessionInfoObtained = false
    }
    
    func scrobble(_ song: MPMediaItem, completion: Completions? = nil) {
        
        guard sessionInfoObtained else { return }
        
        LastFm.sharedInstance()?.sendScrobbledTrack(song.validTitle, byArtist: song.validArtist, onAlbum: includeAlbumName ? song.validAlbum : "", withDuration: song.playbackDuration, atTimestamp: (song.lastPlayedDate ?? Date.init()).timeIntervalSince1970, successHandler: { _ in
            
            if showScrobbleAlert {
                
                UniversalMethods.banner(withTitle: "\(song.validTitle) scrobbled").show(for: 2)
            }
            
            completion?.success()
            
        }, failureHandler: { error in
            
            print(error as Any)
            completion?.error()
        })
    }
    
    func setNowPlayingTo(_ song: MPMediaItem) {
        
        guard sessionInfoObtained else { return }
        
        LastFm.sharedInstance()?.sendNowPlayingTrack(song.validTitle, byArtist: song.validArtist, onAlbum: includeAlbumName ? song.validAlbum : "", withDuration: song.playbackDuration, successHandler: { _ in
            
            if showNowPlayingUpdateAlert {
            
                UniversalMethods.banner(withTitle: "\(song.validTitle) set as Now Playing").show(for: 2)
            }
            
        }, failureHandler: { error in print(error as Any) })
    }
    
    func love(_ song: MPMediaItem) {
        
        guard sessionInfoObtained else { return }
        
        LastFm.sharedInstance()?.loveTrack(song.validTitle, artist: song.validArtist, successHandler: { _ in
            
            if showLoveAlert {
            
                UniversalMethods.banner(withTitle: "\(song.validTitle) loved").show(for: 2)
            }
            
        }, failureHandler: { error in print(error as Any) })
    }
    
    func unlove(_ song: MPMediaItem) {
        
        guard sessionInfoObtained else { return }
        
        LastFm.sharedInstance()?.unloveTrack(song.validTitle, artist: song.validArtist, successHandler: { _ in
            
            if showLoveAlert {
                
                UniversalMethods.banner(withTitle: "\(song.validTitle) unloved").show(for: 2)
            }
            
        }, failureHandler: { error in print(error as Any) })
    }
}

struct ScrobbleAttempt: Hashable {
    
    let persistentID: MPMediaEntityPersistentID
    let date: Date
    let count: Int
}

struct Scrobble {
    
    let attempt: ScrobbleAttempt
    var successful: Bool
}
