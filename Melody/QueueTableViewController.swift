//
//  QueueGuardTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 29/05/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class QueueTableViewController: UITableViewController {
    
    @IBOutlet weak var playGuardSwitch: MELSwitch! {
        
        didSet {
            
            playGuardSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleQueueGuard(weakSelf.playGuardSwitch)
            }
        }
    }
    @IBOutlet weak var playImageView: MELImageView!
    @IBOutlet weak var changeImageView: MELImageView!
    @IBOutlet weak var addImageView: MELImageView!
    @IBOutlet weak var removeImageView: MELImageView!
    @IBOutlet weak var clearImageView: MELImageView!
    @IBOutlet weak var stopImageView: MELImageView!
    @IBOutlet weak var modeQueueImageView: MELImageView!
    @IBOutlet weak var musicAppQueueImageView: MELImageView!
    @IBOutlet var cells: [UITableViewCell]!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView.init(frame: .zero)
        tableView.scrollIndicatorInsets.bottom = 14

        Array(0..<6).forEach({ prepareQueueGuardImageView(at: $0) })
        prepareQueueImageView()
        
        playGuardSwitch.setOn(warnForQueueInterruption, animated: false)
        
        cells.forEach({ $0.selectedBackgroundView = MELBorderView.init() })
    }
    
    @objc func prepareQueueImageView(at row: Int = 0, setPreference: Bool = false) {
        
        if setPreference {
            
            guard (row == 0 && useSystemPlayer) || (row == 1 && !useSystemPlayer) else { return }
            
            let alert = UIAlertAction.init(title: "Quit", style: .destructive, handler: { _ in
                
                let newPreference = !useSystemPlayer
                
                prefs.set(newPreference, forKey: .systemPlayer)
                sharedDefaults.set(newPreference, forKey: .systemPlayer)
                sharedDefaults.set(true, forKey: .quitWidget)
                sharedDefaults.synchronize()
                
                fatalError()
            })
            
            present(UIAlertController.withTitle("Relaunch Required", message: "Mode must quit and be relaunched for this to take effect.", style: .alert, actions: alert, .cancel()), animated: true, completion: nil)
        
        } else {
            
            modeQueueImageView.isHidden = useSystemPlayer
            musicAppQueueImageView.isHidden = !useSystemPlayer
        }
    }

    @objc func prepareQueueGuardImageView(at row: Int, setPreference: Bool = false) {
        
        let updateQueueGuardIfNecessary: (() -> ()) = { [weak self] in
            
            guard let weakSelf = self else { return }
            
            if !playGuard, !changeGuard, !addGuard, !removeGuard, !clearGuard, !stopGuard {
                
                weakSelf.toggleQueueGuard(weakSelf)
            }
        }
        
        switch row {
            
            case 0:
                
                if setPreference {
                    
                    prefs.set(!playGuard, forKey: .playGuard)
                    updateQueueGuardIfNecessary()
                }
                
                playImageView.isHidden = !playGuard
            
            case 1:
                
                if setPreference {
                    
                    prefs.set(!changeGuard, forKey: .changeGuard)
                    updateQueueGuardIfNecessary()
                }
                
                changeImageView.isHidden = !changeGuard
            
            case 2:
                
                if setPreference {
                    
                    prefs.set(!addGuard, forKey: .addGuard)
                    updateQueueGuardIfNecessary()
                }
                
                addImageView.isHidden = !addGuard
            
            case 3:
                
                if setPreference {
                    
                    prefs.set(!removeGuard, forKey: .removeGuard)
                    updateQueueGuardIfNecessary()
                }
                
                removeImageView.isHidden = !removeGuard
            
            case 4:
                
                if setPreference {
                    
                    prefs.set(!clearGuard, forKey: .clearGuard)
                    updateQueueGuardIfNecessary()
                }
                
                clearImageView.isHidden = !clearGuard
            
            case 5:
                
                if setPreference {
                    
                    prefs.set(!stopGuard, forKey: .stopGuard)
                    updateQueueGuardIfNecessary()
                }
                
                stopImageView.isHidden = !stopGuard
            
            default: break
        }
    }
    
    @IBAction func toggleQueueGuard(_ sender: Any) {
        
        let bool = !warnForQueueInterruption
        prefs.set(bool, forKey: .warnInterruption)
        
        if sender is UIViewController {
            
            playGuardSwitch.setOn(!playGuardSwitch.isOn, animated: true)
        }
        
        if !playGuard, !changeGuard, !addGuard, !removeGuard, !clearGuard, !stopGuard {
            
            prepareQueueGuardImageView(at: 0, setPreference: true)
        }
        
        tableView.beginUpdates()
        
        (tableView.headerView(forSection: 2) as? TableHeaderView)?.label.text = !warnForQueueInterruption ? nil : "criteria"
        
        tableView.endUpdates()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
            
            case 0: return 2
            
            case 1: return 1
            
            case 2: return 6
            
            default: return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        
        let footer = view as? UITableViewHeaderFooterView
        footer?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.preservesSuperviewLayoutMargins = false
        cell.contentView.preservesSuperviewLayoutMargins = false
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        return Set([0, 2]).contains(indexPath.section)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = {
            
            switch section {
                
                case 0:
                    
                    guard #available(iOS 10.3, *) else { return nil }
                    
                    return "active queue"
                
                case 2 where warnForQueueInterruption: return "criteria"
                
                default: return nil
            }
        }()
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        switch section {
            
            case 0:
            
                guard #available(iOS 10.3, *) else { return 0.00001 }
            
                return .textHeaderHeight + 10
            
            case 1: return .tableHeader
            
            case 2: return warnForQueueInterruption ? .textHeaderHeight + 10 : 0.00001
            
            default: return .tableHeader
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footer = tableView.sectionFooter
        
        var footerText: String? {
            
            switch section {
                
                case 0:
                    
                    if #available(iOS 11, *) {
                        
                        return "Using Mode's queue is not advised in iOS 11 due to multiple bugs"
                    }
                    
                    return "Using the Music app's queue will result in a worse experience when editing or adding to the queue."
                
                case 1: return "Enable to select criteria for which a confirmation alert will be shown before the queue is modified."
                    
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
        
        if section == 0 {
            
            guard #available(iOS 10.3, *) else { return 0.00001 }
        }
        
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        
        return 50
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            
            prepareQueueImageView(at: indexPath.row, setPreference: true)
            
        } else {
            
            prepareQueueGuardImageView(at: indexPath.row, setPreference: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            
            if #available(iOS 10.3, *) { } else { return 0 }
        }
        
        if indexPath.section == 2, !warnForQueueInterruption {
            
            return 0
        }
        
        return 54
    }
}
