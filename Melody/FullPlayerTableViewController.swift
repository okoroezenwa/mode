//
//  FullPlayerTableViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 14/02/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class FullPlayerTableViewController: UITableViewController {
    
    @IBOutlet weak var bolderTitleSwitch: MELSwitch! {
        
        didSet {
            
            bolderTitleSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleNowPlayingText()
            }
        }
    }
    @IBOutlet weak var minimiseSwitch: MELSwitch! {
        
        didSet {
            
            minimiseSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleMinimise()
            }
        }
    }
    @IBOutlet weak var closeButtonSwitch: MELSwitch! {
        
        didSet {
            
            closeButtonSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleCloseButton()
            }
        }
    }
    @IBOutlet weak var separateSwitch: MELSwitch! {
        
        didSet {
            
            separateSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleSeparation()
            }
        }
    }
    @IBOutlet weak var avoidSwitch: MELSwitch! {
        
        didSet {
            
            avoidSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleAvoidance()
            }
        }
    }
    @IBOutlet weak var supplementarySwitch: MELSwitch! {
        
        didSet {
            
            supplementarySwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleSupplementary()
            }
        }
    }
    @IBOutlet weak var starSwitch: MELSwitch!
    @IBOutlet weak var likedSwitch: MELSwitch!
    @IBOutlet weak var shareSwitch: MELSwitch!
    @IBOutlet weak var volumeSwitch: MELSwitch!
    @IBOutlet weak var overlayImageView: MELImageView!
    @IBOutlet weak var smallerImageView: MELImageView!
    @IBOutlet weak var belowImageView: MELImageView!
    @IBOutlet var cells: [UITableViewCell]!
    @IBOutlet var separationSubviews: [UIView]!
    @IBOutlet var supplementarySubviews: [UIView]!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.scrollIndicatorInsets.bottom = 14
        
        cells.forEach({ $0.selectedBackgroundView = MELBorderView.init() })
        
        prepareSwitches(animated: false)
        prepareSeparationImageViews()
    }

    @objc func prepareSwitches(animated: Bool) {
        
        bolderTitleSwitch.setOn(nowPlayingBoldTextEnabled, animated: animated)
        closeButtonSwitch.setOn(showCloseButton, animated: animated)
        separateSwitch.setOn(dynamicStatusBar, animated: animated)
        avoidSwitch.setOn(avoidDoubleHeightBar, animated: animated)
        supplementarySwitch.setOn(showNowPlayingSupplementaryView, animated: animated)
        minimiseSwitch.setOn(compressOnPause, animated: animated)
        
        let items = Set(supplementaryItems)
        starSwitch.setOn(items.contains(SupplementaryItems.star.rawValue), animated: animated)
        likedSwitch.setOn(items.contains(SupplementaryItems.liked.rawValue), animated: animated)
        shareSwitch.setOn(items.contains(SupplementaryItems.share.rawValue), animated: animated)
        volumeSwitch.setOn(items.contains(SupplementaryItems.volume.rawValue), animated: animated)
    }
    
    func prepareSeparationImageViews() {
        
        overlayImageView.isHidden = separationMethod != .overlay
        smallerImageView.isHidden = separationMethod != .smaller
        belowImageView.isHidden = separationMethod != .below
    }
    
    func toggleNowPlayingText() {
        
        prefs.set(!nowPlayingBoldTextEnabled, forKey: .nowPlayingBoldTitle)
        notifier.post(name: .nowPlayingTextSizesChanged, object: nil)
    }
    
    func toggleCloseButton() {
        
        prefs.set(!showCloseButton, forKey: .showCloseButton)
        notifier.post(name: .showCloseButtonChanged, object: nil)
    }
    
    func toggleMinimise() {
        
        prefs.set(!compressOnPause, forKey: .compressOnPause)
        notifier.post(name: .compressOnPauseChanged, object: nil)
    }
    
    func toggleSeparation() {
        
        prefs.set(!dynamicStatusBar, forKey: .dynamicStatusBar)
        notifier.post(name: .dynamicStatusBarChanged, object: nil)
        
//        tableView.beginUpdates()
//
//        UIView.animate(withDuration: 0.3, animations: {
//
//            (self.tableView.headerView(forSection: 3) as? TableHeaderView)?.label.alpha = dynamicStatusBar.inverted ? 1 : 0
//            self.separationSubviews.forEach({ $0.alpha = dynamicStatusBar.inverted ? 1 : 0 })
//        })
//
//        tableView.endUpdates()
    }
    
    func toggleAvoidance() {
        
        prefs.set(!avoidDoubleHeightBar, forKey: .avoidDoubleHeightBar)
        notifier.post(name: .avoidDoubleHeightBarChanged, object: nil)
    }
    
    func toggleSupplementary() {
        
        prefs.set(!showNowPlayingSupplementaryView, forKey: .showNowPlayingSupplementaryView)
        notifier.post(name: .showNowPlayingSupplementaryViewChanged, object: nil)
        
//        tableView.beginUpdates()
//
//        UIView.animate(withDuration: 0.3, animations: {
//
//            (self.tableView.headerView(forSection: 5) as? TableHeaderView)?.label.alpha = showNowPlayingSupplementaryView ? 1 : 0
//            self.supplementarySubviews.forEach({ $0.alpha = showNowPlayingSupplementaryView ? 1 : 0 })
//        })
//
//        tableView.endUpdates()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return isInDebugMode ? 6 : 5
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
            
            case 0: return 2
            
            case 1: return 3
            
            case 2: return isiPhoneX ? 1 : isSmallScreen ? 0 : 2
                
            case 3: return isSmallScreen ? 0 : 3
            
            case 4: return 1
            
            case 5: return 4
            
            default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        return Set([0, 3]).contains(indexPath.section)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 3, separationMethod.rawValue != indexPath.row {
            
            prefs.set(indexPath.row, forKey: .separationMethod)
            prepareSeparationImageViews()
            notifier.post(name: .separationMethodChanged, object: nil)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
            
            case 0 where isInDebugMode.inverted: return 0
            
//            case 3: return dynamicStatusBar ? 0 : 54
            
//            case 5: return showNowPlayingSupplementaryView ? 54 : 0
            
            default: return 54
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.preservesSuperviewLayoutMargins = false
        cell.contentView.preservesSuperviewLayoutMargins = false
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        
        let footer = view as? UITableViewHeaderFooterView
        footer?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        switch section {
            
            case 0 where isInDebugMode,
                 1,
                 2 where isSmallScreen.inverted,
                 3 where isSmallScreen.inverted && dynamicStatusBar.inverted,
                 5 where showNowPlayingSupplementaryView: return .textHeaderHeight + 20
            
            case 4: return .tableHeader + 10
            
            default: return 0.00001
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = {
            
            switch section {
                
                case 0: return "preferred start point"
                
                case 1: return "appearance"
                
                case 2: return "status bar"
                
                case 3: return "unmixed mode"
                
                case 5: return "supplementary items"
                
                default: return nil
            }
        }()
        
        header?.label.alpha = {
            
            switch section {
            
                case 0 where isInDebugMode,
                     1,
                     2 where isSmallScreen.inverted,
                     3 where isSmallScreen.inverted && dynamicStatusBar.inverted,
                     5 where showNowPlayingSupplementaryView: return 1
                
                default: return 0
            }
        }()
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footer = tableView.sectionFooter
        
        var footerText: String? {
            
            switch section {
                
                case 0: return isInDebugMode ? "The alternate option can be accessed by swiping from the edge of the mini or compact players." : nil
                
                case 1: return "When disabled, artwork is not minimised and its shadow is not removed when music is paused."
                
                case 2: return isSmallScreen ? nil : isiPhoneX ? "Artwork will be blocked by the camera if enabled" : "Prevents the status bar from obscuring artwork during a call, etc. Applies when the status bar is mixed with artwork, or distinguished with an overlay."
                
                case 4: return "Resides below the playback controls."
                
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
        
        return isInDebugMode.inverted && section == 0 ? 0.00001 : UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        
        return 50
    }
}
