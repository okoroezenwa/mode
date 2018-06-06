//
//  ArtworkTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 22/07/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class BackgroundTableViewController: UITableViewController {
    
    @IBOutlet weak var withSectionImageView: MELImageView!
    @IBOutlet weak var withCurrentSongImageView: MELImageView!
    @IBOutlet var cells: [UITableViewCell]!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        cells.forEach({ $0.selectedBackgroundView = MELBorderView.init() })
        
        prepareBackgroundImageViews()
        
        tableView.scrollIndicatorInsets.bottom = 14
    }
    
    func prepareBackgroundImageViews() {
        
        withSectionImageView.isHidden = nowPlayingAsBackground
        withCurrentSongImageView.isHidden = !nowPlayingAsBackground
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 2
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.preservesSuperviewLayoutMargins = false
        cell.contentView.preservesSuperviewLayoutMargins = false
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        
        let footer = view as? UITableViewHeaderFooterView
        footer?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = "background"
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return .textHeaderHeight + (section == 0 ? 8 : 0)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 && ((indexPath.row == 0 && nowPlayingAsBackground) || (indexPath.row == 1 && !nowPlayingAsBackground)) {
            
            prefs.set(!nowPlayingAsBackground, forKey: .useNowPlayingAsBackground)
            prepareBackgroundImageViews()
            notifier.post(name: .nowPlayingBackgroundUsageChanged, object: nil)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
