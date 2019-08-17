//
//  LastFMTableViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 22/07/2019.
//  Copyright © 2019 Ezenwa Okoro. All rights reserved.
//

import UIKit

class LastFMTableViewController: UITableViewController {
    
    lazy var completion: Completions = ({
        
        (self.parent as? PresentedContainerViewController)?.updateIndicator(to: .hidden)
        self.settings[.init(0, 0)] = self.loginCellDetails()
        self.settings[.init(1, 0)] = self.loginButtonDetails()
        self.tableView.reloadData()
        
    }, {
        
        (self.parent as? PresentedContainerViewController)?.updateIndicator(to: .hidden)
        self.tableView.cellForRow(at: .init(row: 0, section: 0))?.isUserInteractionEnabled = true
    })
    
    var sections: SectionDictionary = [
        
        0: ("account", nil),
        1: (nil, nil),
        2: ("alert on...", "Press and hold the Affinity button to mark a song as loved or unloved."),
        3: ("scrobbling", nil)
    ]
    
    lazy var settings: SettingsDictionary = [
        
        .init(0, 0): loginCellDetails(),
        .init(1, 0): loginButtonDetails(),
        .init(2, 0): .init(title: "Login", accessoryType: .onOff(isOn: { showLastFMLoginAlert }, action: { [weak self] in showLastFMLoginAlert.toggle() })),
        .init(2, 1): .init(title: "Scrobble", accessoryType: .onOff(isOn: { showScrobbleAlert }, action: { [weak self] in showScrobbleAlert.toggle() })),
        .init(2, 2): .init(title: "Love or Unlove", accessoryType: .onOff(isOn: { showLoveAlert }, action: { [weak self] in showLoveAlert.toggle() })),
        .init(2, 3): .init(title: "Now Playing Update", accessoryType: .onOff(isOn: { showNowPlayingUpdateAlert }, action: { [weak self] in showNowPlayingUpdateAlert.toggle() })),
        .init(3, 0): .init(title: "Include Album", accessoryType: .onOff(isOn: { includeAlbumName }, action: { [weak self] in includeAlbumName.toggle() }))
    ]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.scrollIndicatorInsets.bottom = 14
    }
    
    func loginCellDetails() -> Setting {
        
        return .init(title: "Logged in as \(prefs.string(forKey: .lastFMUsername) ?? "")", accessoryType: .none, textAlignment: .center)
    }
    
    func loginButtonDetails() -> Setting {
        
        return .init(title: Scrobbler.shared.sessionInfoObtained ? "Logout" : "Login", accessoryType: .none, textAlignment: .center, borderVisibility: .both)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return settings.filter({ $0.key.section == section }).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 && Scrobbler.shared.sessionInfoObtained.inverted {
            
            let cell = tableView.loginCell(for: indexPath)
            
            cell.delegate = self
            
            return cell
            
        } else {
            
            let cell = tableView.settingCell(for: indexPath)
            
            if let setting = settings[indexPath.settingsSection] {
                
                cell.titleLabel.attributes = nil
                cell.prepare(with: setting)
                
                if indexPath.section == 0 && indexPath.row == 0 {
                    
                    cell.titleLabel.attributes = [.init(name: .font, value: .other(UIFont.font(ofWeight: .bold, size: TextStyle.body.textSize())), range: setting.title.nsRange(of: (prefs.string(forKey: .lastFMUsername) ?? "")))]
                }
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        return indexPath.section == 1 && Scrobbler.shared.isAuthenticating.inverted
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
            paragraphStyle.lineHeightMultiple = 1.5
            
            footer?.label.text = text
            footer?.label.attributes = [.init(name: .paragraphStyle, value: .other(paragraphStyle), range: text.nsRange())]
            
        } else {
            
            footer?.label.text = nil
            footer?.label.attributes = nil
        }
        
        return footer
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return (section == 1 ? .tableHeader : .textHeaderHeight + (section == 0 ? 20 : 8))
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return indexPath.section == 0 && Scrobbler.shared.sessionInfoObtained.inverted ? 80 : settings[indexPath.settingsSection]?.borderVisibility == .some(.both) ? 50 : 54
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return sections[section]?.footer == nil && section != 1 ? 0.00001 : UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            
            if Scrobbler.shared.sessionInfoObtained {
                
                Scrobbler.shared.logout()
                self.settings[.init(0, 0)] = self.loginCellDetails()
                self.settings[.init(1, 0)] = self.loginButtonDetails()
                self.tableView.reloadData()
                
            } else if let cell = tableView.cellForRow(at: .init(row: 0, section: 0)) as? LoginDetailsTableViewCell {
                
                login(username: cell.usernameField.text, password: cell.passwordField.text)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        
        return 50
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "LFMTVC going away...").show(for: 0.3)
        }
    }
}

extension LastFMTableViewController: LoginCellDelegate {
    
    func login(username: String?, password: String?) {
        
        guard let username = username, let password = password, username.isEmpty.inverted, password.isEmpty.inverted else {
            
            UniversalMethods.banner(withTitle: "Invalid Login Details").show(for: 2)
            
            return
        }
        
        tableView.cellForRow(at: .init(row: 0, section: 0))?.isUserInteractionEnabled = false
        (parent as? PresentedContainerViewController)?.updateIndicator(to: .visible)
        Scrobbler.shared.login(username: username, password: password, completion: completion)
    }
}
