//
//  SavedLyricsViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 13/07/2019.
//  Copyright © 2019 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SavedLyricsViewController: UIViewController {
    
    @IBOutlet var tableView: MELTableView!
    
    var songs = [Song]()
    var settings = [Setting]()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.isEditing = true
        tableView.tableFooterView = .init(frame: .zero)
        tableView.scrollIndicatorInsets.bottom = 14

        resetLyrics()
    }
    
    func resetLyrics() {
        
        songs = Song.all
        settings = self.songs.map({ Setting.init(title: $0.lyrics ?? "", subtitle: ($0.name ?+ "  —  ") ?+ $0.artist, accessoryType: .none) })
        
        tableView.reloadData()
    }
    
    func clearLyrics() {
        
        var actions = [AlertAction]()
        
        actions.append(AlertAction.init(title: "All", style: .destructive, handler: { Song.deleteAllLyrics(completion: { self.resetLyrics() }) }))
        
        if let indexPaths = tableView.indexPathsForSelectedRows {
            
            actions.append(AlertAction.init(title: "Selected", style: .destructive, handler: { Song.delete(indexPaths.map({ self.songs[$0.row] }), completion: { self.resetLyrics() }) }))
            
            actions.append(AlertAction.init(title: "Unselected", style: .destructive, handler: {
                
                let set = Set(indexPaths.map({ self.songs[$0.row] }))
                Song.delete(self.songs.filter({ set.contains($0).inverted }), completion: { self.resetLyrics() }) }))
        }
        
        Transitioner.shared.showAlert(title: "Delete...", from: self, with: actions)
        
//        present(UIAlertController.withTitle("Delete...", message: nil, style: .actionSheet, actions: actions + [.cancel()]), animated: true, completion: nil)
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "SLVC going away...").show(for: 0.3)
        }
    }
}

extension SavedLyricsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.settingCell(for: indexPath)
        
        let setting = settings[indexPath.row]
        
        cell.titleLabel.attributes = nil
        cell.prepare(with: setting)
        cell.titleLabel.numberOfLines = 5
        cell.titleLabel.attributes = [.init(name: .paragraphStyle, value: .other(NSMutableParagraphStyle.withLineHeight(1.2, alignment: .left)), range: setting.title.nsRange())]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        return [.init(style: .destructive, title: "Delete", handler: { _, indexPath in
            
            Song.delete([self.songs[indexPath.row]], completion: { self.resetLyrics() })
        })]
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let heights = [.body, .body, .body, TextStyle.secondary].reduce(0, { $0 + (FontManager.shared.heightsDictionary[$1] ?? 0) })
        
        return heights + FontManager.shared.cellSpacing + (2 * FontManager.shared.cellInset) + FontManager.shared.cellConstant
    }
}
