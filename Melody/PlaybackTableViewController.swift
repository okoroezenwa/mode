//
//  PlaybackTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 22/07/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PlaybackTableViewController: UITableViewController {
    
    @IBOutlet weak var playOnlySwitch: MELSwitch! {
        
        didSet {
            
            playOnlySwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.togglePlayOnly()
            }
        }
    }
    @IBOutlet weak var shuffleSwitch: MELSwitch! {
        
        didSet {
            
            shuffleSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleKeepShuffleState()
            }
        }
    }
    @IBOutlet weak var repeatSwitch: MELSwitch! {
        
        didSet {
            
            repeatSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleKeepRepeatState()
            }
        }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        prepareSwitches()
        
        tableView.scrollIndicatorInsets.bottom = 14
    }

    @objc func prepareSwitches() {
        
        playOnlySwitch.setOn(allowPlayOnly, animated: false)
        shuffleSwitch.setOn(keepShuffleState, animated: false)
        repeatSwitch.setOn(preserveRepeatState, animated: false)
    }
    
    func togglePlayOnly() {
        
        prefs.set(!allowPlayOnly, forKey: .playOnlyShortcut)
        notifier.post(name: .playOnlyChanged, object: nil)
    }
    
    func toggleKeepShuffleState() {
        
        prefs.set(!keepShuffleState, forKey: .keepShuffleState)
    }
    
    func toggleKeepRepeatState() {
        
        prefs.set(!preserveRepeatState, forKey: .preserveRepeatState)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.preservesSuperviewLayoutMargins = false
        cell.contentView.preservesSuperviewLayoutMargins = false
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        
        let footer = view as? UITableViewHeaderFooterView
        footer?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return /*section == 0 ?*/ .tableHeader + 8
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footer = tableView.sectionFooter
        
        var footerText: String? {
            
            switch section {
                
                case 0: return "Tap an item's artwork to play just that item."
                
                case 1: return "When disabled, any active shuffle mode will be discarded when the queue is reset."
                
                case 2: return "When disabled, any active repeat mode will be discarded when the queue is reset."
                
                default: return nil
            }
        }
        
        if let text = footerText {
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.5
            
            footer?.label.text = text
            footer?.label.attributes = [.init(name: .paragraphStyle, value: .other(paragraphStyle), range: text.nsRange())]
            
        } else {
            
            footer?.label.text = nil
            footer?.label.attributes = nil
        }
        
        return footer
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        
        return 50
    }
}
