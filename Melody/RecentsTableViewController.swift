//
//  RecentsTableViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 07/03/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class RecentsTableViewController: UITableViewController {
    
    var sections: SectionDictionary = [
        
        0: (nil, nil),
        1: ("recently updated", "Selected playlists will instead be sorted by recently updated over recently added.")
    ]
    
    lazy var settings: SettingsDictionary = [
        
        .init(0, 0): .init(title: "Songs", accessoryType: .onOff(isOn: { showRecentSongs }, action: { [weak self] in self?.toggleSongs() })),
        .init(0, 1): .init(title: "Artists", accessoryType: .onOff(isOn: { showRecentArtists }, action: { [weak self] in self?.toggleArtists() })),
        .init(0, 2): .init(title: "Genres", accessoryType: .onOff(isOn: { showRecentGenres }, action: { [weak self] in self?.toggleGenres() })),
        .init(0, 3): .init(title: "Albums", accessoryType: .onOff(isOn: { showRecentAlbums }, action: { [weak self] in self?.toggleAlbums() })),
        .init(0, 4): .init(title: "Playlists", accessoryType: .onOff(isOn: { showRecentPlaylists }, action: { [weak self] in self?.togglePlaylists() })),
        .init(0, 5): .init(title: "Composers", accessoryType: .onOff(isOn: { showRecentComposers }, action: { [weak self] in self?.toggleComposers() })),
        .init(0, 6): .init(title: "Compilations", accessoryType: .onOff(isOn: { showRecentCompilations }, action: { [weak self] in self?.toggleCompilations() })),
        .init(0, 7): .init(title: "Album Artists", accessoryType: .onOff(isOn: { showRecentAlbumArtists }, action: { [weak self] in self?.toggleAlbumArtists() })),
        .init(1, 0): .init(title: "All Playlists", accessoryType: .onOff(isOn: { recentlyUpdatedPlaylistSorts.contains(.all) }, action: { [weak self] in self?.toggleRecentlyUpdated(with: .all) })),
        .init(1, 1): .init(title: "My Playlists", accessoryType: .onOff(isOn: { recentlyUpdatedPlaylistSorts.contains(.user) }, action: { [weak self] in self?.toggleRecentlyUpdated(with: .user) })),
        .init(1, 2): .init(title: "Apple Music Playlists", accessoryType: .onOff(isOn: { recentlyUpdatedPlaylistSorts.contains(.appleMusic) }, action: { [weak self] in self?.toggleRecentlyUpdated(with: .appleMusic) }))
    ]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.scrollIndicatorInsets.bottom = 14
        
        notifier.addObserver(tableView as Any, selector: #selector(UITableView.reloadData), name: .appleMusicStatusChecked, object: nil)
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
    
    func toggleAlbumArtists() {
        
        prefs.set(!showRecentAlbumArtists, forKey: .showRecentAlbumArtists)
        notifier.post(name: .showRecentAlbumArtistsChanged, object: nil)
    }
    
    func toggleComposers() {
        
        prefs.set(!showRecentComposers, forKey: .showRecentComposers)
        notifier.post(name: .showRecentComposersChanged, object: nil)
    }
    
    func toggleRecentlyUpdated(with playlistView: PlaylistView) {
        
        guard let array = (prefs.array(forKey: .recentlyUpdatedPlaylistSorts) as? [Int])?.compactMap({ PlaylistView(rawValue: $0) }) else { return }
        
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
        
        return sections.count - (appDelegate.appleMusicStatus == .appleMusic(libraryAccess: true) ? 0 : 1)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return settings.filter({ $0.key.section == section }).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.settingCell(for: indexPath)
        
        if let setting = settings[indexPath.settingsSection] {
            
            cell.prepare(with: setting)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        return false
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = sections[section]?.header
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footer = tableView.sectionFooter
        
        if let text = sections[section]?.footer {
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = .footerLineHeight
            
            footer?.label.text = text
            footer?.label.attributes = [.init(name: .paragraphStyle, value: .other(paragraphStyle), range: text.nsRange())]
            
        } else {
            
            footer?.label.text = nil
            footer?.label.attributes = nil
        }
        
        return footer
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return (section == 0 ? .tableHeader : .textHeaderHeight) + 8
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 54
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        
        return 50
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "RTVC going away...").show(for: 0.3)
        }
    }
}
