//
//  RecentsTableViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 07/03/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class RecentsTableViewController: UITableViewController {

    @IBOutlet var songsSwitch: MELSwitch! {
        
        didSet {
            
            songsSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleSongs()
            }
        }
    }
    @IBOutlet var artistsSwitch: MELSwitch! {
        
        didSet {
            
            artistsSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleArtists()
            }
        }
    }
    @IBOutlet var genresSwitch: MELSwitch! {
        
        didSet {
            
            genresSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleGenres()
            }
        }
    }
    @IBOutlet var albumsSwitch: MELSwitch! {
        
        didSet {
            
            albumsSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleAlbums()
            }
        }
    }
    @IBOutlet var playlistsSwitch: MELSwitch! {
        
        didSet {
            
            playlistsSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.togglePlaylists()
            }
        }
    }
    @IBOutlet var composersSwitch: MELSwitch! {
        
        didSet {
            
            composersSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleComposers()
            }
        }
    }
    @IBOutlet var compilationsSwitch: MELSwitch! {
        
        didSet {
            
            compilationsSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleCompilations()
            }
        }
    }
    @IBOutlet var allSwitch: MELSwitch! {
        
        didSet {
            
            allSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleRecentlyUpdated(with: .all)
            }
        }
    }
    @IBOutlet var mineSwitch: MELSwitch! {
        
        didSet {
            
            mineSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleRecentlyUpdated(with: .user)
            }
        }
    }
    @IBOutlet var appleMusicSwitch: MELSwitch! {
        
        didSet {
            
            appleMusicSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleRecentlyUpdated(with: .appleMusic)
            }
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.scrollIndicatorInsets.bottom = 14

        prepareSwitches(animated: false)
        
        notifier.addObserver(tableView, selector: #selector(UITableView.reloadData), name: .appleMusicStatusChecked, object: nil)
    }
    
    func prepareSwitches(animated: Bool) {
        
        songsSwitch.setOn(showRecentSongs, animated: animated)
        playlistsSwitch.setOn(showRecentPlaylists, animated: animated)
        artistsSwitch.setOn(showRecentArtists, animated: animated)
        albumsSwitch.setOn(showRecentAlbums, animated: animated)
        genresSwitch.setOn(showRecentGenres, animated: animated)
        compilationsSwitch.setOn(showRecentCompilations, animated: animated)
        composersSwitch.setOn(showRecentComposers, animated: animated)
        
        let set = recentlyUpdatedPlaylistSorts
        
        appleMusicSwitch.setOn(set.contains(.appleMusic), animated: animated)
        mineSwitch.setOn(set.contains(.user), animated: animated)
        allSwitch.setOn(set.contains(.all), animated: animated)
    }
    
    func toggleSongs() {
        
        prefs.set(!showRecentSongs, forKey: .showRecentSongs)
        notifier.post(name: .showRecentSongsChanged, object: nil)
    }
    
    func togglePlaylists() {
        
        prefs.set(!showRecentPlaylists, forKey: .showRecentPlaylists)
        notifier.post(name: .showRecentPlaylistsChanged, object: nil)
    }
    
    func toggleArtists() {
        
        prefs.set(!showRecentArtists, forKey: .showRecentArtists)
        notifier.post(name: .showRecentArtistsChanged, object: nil)
    }
    
    func toggleAlbums() {
        
        prefs.set(!showRecentAlbums, forKey: .showRecentAlbums)
        notifier.post(name: .showRecentAlbumsChanged, object: nil)
    }
    
    func toggleGenres() {
        
        prefs.set(!showRecentGenres, forKey: .showRecentGenres)
        notifier.post(name: .showRecentGenresChanged, object: nil)
    }
    
    func toggleCompilations() {
        
        prefs.set(!showRecentCompilations, forKey: .showRecentCompilations)
        notifier.post(name: .showRecentCompilationsChanged, object: nil)
    }
    
    func toggleComposers() {
        
        prefs.set(!showRecentComposers, forKey: .showRecentComposers)
        notifier.post(name: .showRecentComposersChanged, object: nil)
    }
    
    func toggleRecentlyUpdated(with playlistView: PlaylistView) {
        
        guard let array = (prefs.array(forKey: .recentlyUpdatedPlaylistSorts) as? [Int])?.flatMap({ PlaylistView(rawValue: $0) }) else { return }
        
        if recentlyUpdatedPlaylistSorts.contains(playlistView) {
            
            prefs.set(array.filter({ $0 != playlistView }).map({ $0.rawValue }), forKey: .recentlyUpdatedPlaylistSorts)
            
        } else {
            
            prefs.set(array.map({ $0.rawValue }) + [playlistView.rawValue], forKey: .recentlyUpdatedPlaylistSorts)
        }
        
        notifier.post(name: .recentlyUpdatedPlaylistSortsChanged, object: nil, userInfo: ["playlistsView": playlistView.rawValue])
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return appDelegate.appleMusicStatus == .appleMusic(libraryAccess: true) ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return section == 0 ? 7 : 3
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.preservesSuperviewLayoutMargins = false
        cell.contentView.preservesSuperviewLayoutMargins = false
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        return false
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = {
            
            switch section {
                
                case 0: return "show..."
                
                case 1: return "use recently updated for..."
                
                default: return nil
            }
        }()
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return .textHeaderHeight + 8
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "RTVC going away...").show(for: 0.3)
        }
    }
}
