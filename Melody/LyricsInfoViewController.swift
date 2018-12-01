//
//  LyricsInfoViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 08/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class LyricsInfoViewController: UIViewController, TableViewContaining {
    
    @IBOutlet var tableView: MELTableView!
    
    var manager: LyricsManager? {
        
        didSet {
            
            manager?.detailer = self
        }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.contentInset.bottom = 14
        tableView.scrollIndicatorInsets.bottom = 14
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        tableView.flashScrollIndicators()
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            let banner = UniversalMethods.banner(withTitle: "LIVC going away...")
            banner.titleLabel.font = .myriadPro(ofWeight: .light, size: 22)
            banner.show(for: 0.3)
        }
    }
}

extension LyricsInfoViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
            
            case 0: return 3
            
            case 1: return manager?.hits.count ?? 0
            
            default: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch (indexPath.section, indexPath.row) {
            
            case (1, _):
            
                let cell = tableView.dequeueReusableCell(withIdentifier: .settingsCell, for: indexPath) as! SettingsTableViewCell
                
                let result = manager?.hits[indexPath.row].result
                
                cell.prepare(with: Setting.init(title: result?.title ?? "", subtitle: result?.artist.name ?? "", accessoryType: .none))
                cell.borderViews.forEach({ $0.isHidden = true })
                cell.titleLabel.textAlignment = .left
            
                return cell
            
            case (0, 0), (0, 1):
            
                let cell = tableView.dequeueReusableCell(withIdentifier: "field", for: indexPath) as! TextFieldsTableViewCell
                
                cell.itemImageView.image = #imageLiteral(resourceName: indexPath.row == 0 ? "Songs" : "Artists")
                cell.textField.placeholder = indexPath.row == 0 ? "song title" : "artist name"
                cell.textField.text = indexPath.row == 0 ? manager?.songTitle : manager?.artistName
            
                return cell
            
            case (0, 2):
            
                let cell = tableView.dequeueReusableCell(withIdentifier: .settingsCell, for: indexPath) as! SettingsTableViewCell
            
                cell.prepare(with: Setting.init(title: "Lyrics Settings", accessoryType: .chevron(tap: nil, preview: nil)))
            
                return cell
            
            default: return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = {
            
            switch section {
                
                case 1: return "search results"
                
                case 0: return "search terms"
                
                default: return nil
            }
        }()
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return .textHeaderHeight + (section == 0 ? 12 : 0)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
            
            case 1: return 57
            
            case 0: return 50
            
            default: return 44
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            
            guard let manager = manager else { return }
            
            manager.hits.insert(manager.hits.remove(at: indexPath.row), at: 0)
            
            tableView.moveRow(at: indexPath, to: .init(row: 0, section: indexPath.section))
            
            tableView.deselectRow(at: .init(row: 0, section: indexPath.section), animated: true)
        
        } else {
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        switch indexPath {
            
            case let x where x.section == 1,
                 let x where x.section == 0 && x.row == 2: return true
            
            default: return false
        }
    }
}
