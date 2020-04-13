//
//  SettingsTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 27/10/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    var sections: SectionDictionary = [
        
        0: (nil, nil),
        1: ("general", nil),
        2: ("player", nil),
        3: ("now playing", nil),
        4: ("temporary", nil),
        5: ("sleep prevention", nil),
        6: ("default sort options", nil),
        7: (nil, nil),
        8: (nil, nil),
        9: (nil, nil),
        10: (nil, nil)
    ]
    lazy var settings: SettingsDictionary = [
        
        .init(0, 0): .init(title: "Rate and Review", accessoryType: .none, textAlignment: .center, borderVisibility: .both),
        .init(1, 0): .init(title: "Offline Mode", accessoryType: .onOff(isOn: { showiCloudItems.inverted }, action: { [weak self] in self?.toggleCloud() })),
        .init(1, 1): .init(title: "Theme", tertiaryDetail: { appTheme.title }, accessoryType: .none),
        .init(1, 2): .init(title: "Library Refresh", accessoryType: .chevron),
        .init(1, 3): .init(title: "Tab Bar", accessoryType: .chevron),
        .init(1, 4): .init(title: "Gestures", accessoryType: .chevron),
        .init(1, 5): .init(title: "Artwork", accessoryType: .chevron),
        .init(1, 6): .init(title: "Background", accessoryType: .chevron),
        .init(1, 7): .init(title: "App Icon", accessoryType: .chevron),
        .init(1, 8): .init(title: "Theme", accessoryType: .chevron),
        .init(2, 0): .init(title: "Queue", accessoryType: .chevron),
        .init(2, 1): .init(title: "Playback", accessoryType: .chevron),
        .init(2, 2): .init(title: "Fullscreen Player", accessoryType: .chevron),
        .init(3, 0): .init(title: "Volume Slider", accessoryType: .onOff(isOn: { showVolumeViews }, action: { [weak self] in self?.toggleVolumeViews() })),
        .init(3, 1): .init(title: "Faster Startup", accessoryType: .onOff(isOn: { fasterNowPlayingStartup }, action: { [weak self] in self?.toggleFasterStartup() })),
        .init(4, 0): .init(title: "Always Show Counts", accessoryType: .onOff(isOn: { songCountVisible }, action: { [weak self] in self?.toggleCounts() })),
        .init(4, 1): .init(title: "Show Explicit Indicator", accessoryType: .onOff(isOn: { showExplicit }, action: { [weak self] in self?.toggleExplicit() })),
        .init(4, 2): .init(title: "Artists Open With Songs", accessoryType: .onOff(isOn: { artistItemsStartingPoint == EntityItemsViewController.StartPoint.songs.rawValue }, action: { [weak self] in self?.toggleArtistStartPoint() })),
        .init(4, 3): .init(title: "Secondary Song Info", accessoryType: .chevron),
        .init(4, 4): .init(title: "Recents", accessoryType: .chevron),
        .init(4, 5): .init(title: "Section Picker Everywhere", accessoryType: .onOff(isOn: { showSectionChooserEverywhere }, action: { [weak self] in self?.toggleChooser() })),
        .init(4, 6): .init(title: "Lighter Borders and Lines", accessoryType: .onOff(isOn: { useLighterBorders }, action: { [weak self] in self?.toggleLighterBorders() })),
        .init(4, 7): .init(title: "Numbers Below Letters", accessoryType: .onOff(isOn: { numbersBelowLetters }, action: { [weak self] in self?.toggleNumbersBelow() })),
        .init(4, 8): .init(title: "Show Info Buttons", accessoryType: .onOff(isOn: { showInfoButtons }, action: { [weak self] in self?.toggleInfoButtons() })),
        .init(4, 9): .init(title: "Last.fm", accessoryType: .chevron),
        .init(4, 10): .init(title: "Use System Alerts", accessoryType: .onOff(isOn: { useSystemAlerts }, action: { useSystemAlerts.toggle() })),
        .init(4, 11): .init(title: "Use Artwork In Show Menu", accessoryType: .onOff(isOn: { useArtworkInShowMenu }, action: { useArtworkInShowMenu.toggle() })),
        .init(5, 0): .init(title: "Never", accessoryType: .check({ screenLockPreventionMode == InsomniaMode.disabled.rawValue })),
        .init(5, 1): .init(title: "Always", accessoryType: .check({ screenLockPreventionMode == InsomniaMode.always.rawValue })),
        .init(5, 2): .init(title: "While Charging", accessoryType: .check({ screenLockPreventionMode == InsomniaMode.whenCharging.rawValue })),
        .init(6, 0): .init(title: "Playlists", subtitle: "Songs", tertiaryDetail: { [weak self] in self?.tertiaryText(for: .playlist) }, accessoryType: .button(type: .image({ SettingsTableViewController.image(for: 0) }), bordered: false, widthType: .other(36), touchEnabled: false)),
        .init(6, 1): .init(title: "Albums", subtitle: "Songs", tertiaryDetail: { [weak self] in self?.tertiaryText(for: .album) }, accessoryType: .button(type: .image({ SettingsTableViewController.image(for: 1) }), bordered: false, widthType: .other(36), touchEnabled: false)),
        .init(6, 2): .init(title: "Artists", subtitle: "Songs", tertiaryDetail: { [weak self] in self?.tertiaryText(for: .collection(kind: .artist, point: .songs)) }, accessoryType: .button(type: .image({ SettingsTableViewController.image(for: 2) }), bordered: false, widthType: .other(36), touchEnabled: false)),
        .init(6, 3): .init(title: "Artists", subtitle: "Albums", tertiaryDetail: { [weak self] in self?.tertiaryText(for: .collection(kind: .artist, point: .albums)) }, accessoryType: .button(type: .image({ SettingsTableViewController.image(for: 3) }), bordered: false, widthType: .other(36), touchEnabled: false)),
        .init(6, 4): .init(title: "Album Artists", subtitle: "Songs", tertiaryDetail: { [weak self] in self?.tertiaryText(for: .collection(kind: .albumArtist, point: .songs)) }, accessoryType: .button(type: .image({ SettingsTableViewController.image(for: 4) }), bordered: false, widthType: .other(36), touchEnabled: false)),
        .init(6, 5): .init(title: "Album Artists", subtitle: "Albums", tertiaryDetail: { [weak self] in self?.tertiaryText(for: .collection(kind: .albumArtist, point: .albums)) }, accessoryType: .button(type: .image({ SettingsTableViewController.image(for: 5) }), bordered: false, widthType: .other(36), touchEnabled: false)),
        .init(6, 6): .init(title: "Genres", subtitle: "Songs", tertiaryDetail: { [weak self] in self?.tertiaryText(for: .collection(kind: .genre, point: .songs)) }, accessoryType: .button(type: .image({ SettingsTableViewController.image(for: 6) }), bordered: false, widthType: .other(36), touchEnabled: false)),
        .init(6, 7): .init(title: "Genres", subtitle: "Albums", tertiaryDetail: { [weak self] in self?.tertiaryText(for: .collection(kind: .genre, point: .albums)) }, accessoryType: .button(type: .image({ SettingsTableViewController.image(for: 7) }), bordered: false, widthType: .other(36), touchEnabled: false)),
        .init(6, 8): .init(title: "Composers", subtitle: "Songs", tertiaryDetail: { [weak self] in self?.tertiaryText(for: .collection(kind: .composer, point: .songs)) }, accessoryType: .button(type: .image({ SettingsTableViewController.image(for: 8) }), bordered: false, widthType: .other(36), touchEnabled: false)),
        .init(6, 9): .init(title: "Composers", subtitle: "Albums", tertiaryDetail: { [weak self] in self?.tertiaryText(for: .collection(kind: .composer, point: .albums)) }, accessoryType: .button(type: .image({ SettingsTableViewController.image(for: 9) }), bordered: false, widthType: .other(36), touchEnabled: false)),
        .init(7, 0): .init(title: "Manage Saved Lyrics", accessoryType: .none, textAlignment: .center, borderVisibility: .both),
        .init(8, 0): .init(title: "Reset All Settings", accessoryType: .none, textAlignment: .center, borderVisibility: .both),
        .init(9, 0): .init(title: "Show Deinit Banner", accessoryType: .onOff(isOn: { deinitBannersEnabled }, action: { [weak self] in self?.toggleDeinit() })),
        .init(9, 1): .init(title: "Use Descriptor", accessoryType: .onOff(isOn: { useDescriptor }, action: { [weak self] in self?.toggleDescriptor() })),
        .init(9, 2): .init(title: "Use Media Items", accessoryType: .onOff(isOn: { useMediaItems }, action: { [weak self] in self?.toggleMediaItems() })),
        .init(9, 3): .init(title: "Manual Queue Insertion", accessoryType: .onOff(isOn: { useOldStyleQueue }, action: { [weak self] in self?.toggleManual() })),
        .init(10, 0): .init(title: "Collect New Songs", accessoryType: .none, textAlignment: .center, borderVisibility: .both)
    ]

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.scrollIndicatorInsets.bottom = 14
        
        notifier.addObserver(self, selector: #selector(updateThemeCellTertiaryText), name: .themeChanged, object: nil)
        
        notifier.addObserver(self, selector: #selector(updateSortSection(_:)), name: .collectionSortChanged, object: nil)
    }
    
    @objc func updateSortSection(_ notification: Notification) {
        
        let path: ((Int) -> IndexPath)? = { IndexPath.init(row: $0, section: 6) }
        
        guard let index = notification.userInfo?["index"] as? Int, let indexPath = path?(index), let setting = settings[indexPath.settingsSection] else { return }
        
        (tableView.cellForRow(at: indexPath) as? SettingsTableViewCell)?.updateTertiaryText(with: setting)
        
        switch setting.accessoryType {
            
            case .button(type: let type, bordered: _, widthType: _, touchEnabled: _): (tableView.cellForRow(at: indexPath) as? SettingsTableViewCell)?.updateAccessoryButtonDetails(with: setting, type: type)
            
            default: break
        }
    }
    
    @objc func updateThemeCellTertiaryText() {
        
        let indexPath = IndexPath.init(row: 1, section: 1)
        
        guard let setting = settings[indexPath.settingsSection] else { return }
        
        (tableView.cellForRow(at: indexPath) as? SettingsTableViewCell)?.updateTertiaryText(with: setting)
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    func tertiaryText(for location: Location) -> String? {
        
        let details = EntityType.collectionEntityDetails(for: location)
        
        let criteria: String? = {
            
            if let rawValue = collectionSortCategories?[details.type.title(matchingPropertyName: true) + details.startPoint.title], let criteria = SortCriteria(rawValue: rawValue) {
                
                return criteria.title(from: location) + criteria.subtitle(from: location).replacingOccurrences(of: "by ", with: " ")// + ", "
            }
            
            return nil
        }()
        
        return criteria
    }
    
    static func image(for index: Int) -> UIImage {
        
        let details = EntityType.collectionEntityDetails(for: location(for: index))
        
        if let ascending = collectionSortOrders?[details.type.title(matchingPropertyName: true) + details.startPoint.title] {

            return #imageLiteral(resourceName: ascending ? "Save22" : "Upload22")
        }
        
        return #imageLiteral(resourceName: "Save22")
    }
    
    static func location(for index: Int) -> Location {
        
        switch index {
            
            case 0: return .playlist
            
            case 1: return .album
            
            case 2: return .collection(kind: .artist, point: .songs)
            
            case 3: return .collection(kind: .artist, point: .albums)
                
            case 4: return .collection(kind: .albumArtist, point: .songs)
                
            case 5: return .collection(kind: .albumArtist, point: .albums)
                
            case 6: return .collection(kind: .genre, point: .songs)
                
            case 7: return .collection(kind: .genre, point: .albums)
                
            case 8: return .collection(kind: .composer, point: .songs)
                
            case 9: return .collection(kind: .composer, point: .albums)
            
            default: fatalError("Not allowed")
        }
    }
    
    func toggleCloud() {
        
        let bool = !showiCloudItems
        prefs.set(bool, forKey: .iCloudItems)
        notifier.post(name: .iCloudVisibilityChanged, object: nil)
    }
    
    func toggleTableHeaders() {
        
        let bool = !boldHeaders
        prefs.set(bool, forKey: .boldSectionTitles)
        notifier.post(name: .tableViewHeaderSizesChanged, object: nil)
    }
    
    func toggleDeinit() {
        
        prefs.set(!deinitBannersEnabled, forKey: .deinitBannersEnabled)
    }
    
    func toggleCounts() {
        
        prefs.set(!songCountVisible, forKey: .songCountVisible)
        notifier.post(name: .entityCountVisibilityChanged, object: nil)
    }
    
    func toggleExplicit() {
        
        prefs.set(!showExplicit, forKey: .showExplicitness)
        notifier.post(name: .showExplicitnessChanged, object: nil)
    }
    
    func toggleNumbersBelow() {
        
        prefs.set(numbersBelowLetters.inverted, forKey: .numbersBelowLetters)
        notifier.post(name: .numbersBelowLettersChanged, object: nil)
    }

    func toggleArtistStartPoint() {
        
        let number = artistItemsStartingPoint == EntityItemsViewController.StartPoint.songs.rawValue ? EntityItemsViewController.StartPoint.albums.rawValue : EntityItemsViewController.StartPoint.songs.rawValue
        prefs.set(number, forKey: .artistStartingPoint)
    }
    
    func toggleInfoButtons() {
        
        prefs.set(!showInfoButtons, forKey: .showInfoButtons)
        notifier.post(name: .infoButtonVisibilityChanged, object: nil)
    }
    
    func toggleVolumeViews() {
        
        prefs.set(!showVolumeViews, forKey: .showNowPlayingVolumeView)
        notifier.post(name: .volumeVisibilityChanged, object: nil)
    }
    
    func toggleChooser() {
        
        prefs.set(!showSectionChooserEverywhere, forKey: .showSectionChooserEverywhere)
    }
    
    func toggleFasterStartup() {
        
        prefs.set(!fasterNowPlayingStartup, forKey: .fasterNowPlayingStartup)
    }
    
    func toggleLighterBorders() {
        
        prefs.set(!useLighterBorders, forKey: .lighterBorders)
        sharedDefaults.set(!sharedUseLighterBorders, forKey: .lighterBorders)
        sharedDefaults.synchronize()
        notifier.post(name: .lighterBordersChanged, object: nil)
    }
    
    func toggleDescriptor() {
        
        prefs.set(!useDescriptor, forKey: .useDescriptor)
    }
    
    func toggleMediaItems() {
        
        prefs.set(useMediaItems.inverted, forKey: .useMediaItems)
    }
    
    func toggleManual() {
        
        prefs.set(useOldStyleQueue.inverted, forKey: .useOldStyleQueue)
    }
    
    func reset() {
        
        let reset = AlertAction.init(title: "Reset All Settings", style: .destructive, handler: {
            
            let wasCloud = showiCloudItems
            let wasDynamic = dynamicStatusBar
            let wasBold = nowPlayingBoldTextEnabled
            let wasSinglePlay = allowPlayOnly
            let backgroundWasSectionAdaptive = backgroundArtworkAdaptivity == .sectionAdaptive
            
            Settings.resetDefaults()
            self.tableView.reloadData()
//            self.prepareSwitches(animated: true)
            
            if wasCloud.inverted {
                
                notifier.post(name: .iCloudVisibilityChanged, object: nil)
            }
            
            if wasDynamic.inverted {
                
                notifier.post(name: .dynamicStatusBarChanged, object: nil)
            }
            
            if wasBold {
                
                notifier.post(name: .nowPlayingTextSizesChanged, object: nil)
            }
            
            if wasSinglePlay.inverted {
                
                notifier.post(name: .playOnlyChanged, object: nil)
            }
            
            if darkTheme {
                
                if let view = appDelegate.window?.rootViewController?.view {
                    
                    UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: { notifier.post(name: .themeChanged, object: nil) }, completion: nil)
                }
            }
            
            if backgroundWasSectionAdaptive.inverted {
                
                notifier.post(name: .backgroundArtworkAdaptivityChanged, object: nil)
            }
        })
        
        showAlert(title: nil, with: reset)
        
//        present(UniversalMethods.alertController(withTitle: nil, message: nil, preferredStyle: .actionSheet, actions: reset, UniversalMethods.cancelAlertAction()), animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toTips", let presentedVC = segue.destination as? PresentedContainerViewController {
            
            presentedVC.context = .tips
        
        } else if segue.identifier == "toArranger", let vc = segue.destination as? VerticalPresentationContainerViewController, let index = sender as? Int {
            
            let location = SettingsTableViewController.location(for: index)
            let details = EntityType.collectionEntityDetails(for: location)
            let key = details.type.title(matchingPropertyName: true) + details.startPoint.title
                    
            vc.title = "Select Default Sort"
            vc.segments = [.init(title: "Ascending", image: #imageLiteral(resourceName: "Save22")), .init(title: "Descending", image: #imageLiteral(resourceName: "Upload22"))]
            vc.context = .sort
            vc.topHeaderMode = .themedImage(name: "Order17", height: 17)
            vc.arrangeVC.isSetting = true
            vc.arrangeVC.index = index
            vc.arrangeVC.locationDetails = (location, SortCriteria(rawValue: collectionSortCategories?[key] ?? 0) ?? .standard, collectionSortOrders?[key] ?? true)
            vc.leftButtonAction = { button, vc in (vc as? VerticalPresentationContainerViewController)?.arrangeVC.persist(button) }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return isInDebugMode ? 11 : 9
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
            
            case 1:
            
                if #available(iOS 10.3, *), UIApplication.shared.supportsAlternateIcons {
                    
                    return 8
                }
            
                return 7
            
            case 2: return 3
            
            case 3: return 2
            
            case 4: return 12
            
            case 5: return 3
            
            case 6: return 10
            
            case 9: return 4
            
            default: return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.settingCell(for: indexPath)
        
        if let setting = settings[indexPath.settingsSection] {
            
            cell.prepare(with: setting)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            
            if let url = URL.init(string: "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1170715139&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8") {
                
                UIApplication.shared.openURL(url)
            }
        
        } else if indexPath.section == 1 {
            
            if indexPath.row == 1 {
                
                var alerts = [AlertAction
                    .init(title: "Dark", accessoryType: .check({ appTheme == .dark }), handler: {
                    
                        guard appTheme != .dark else { return }
                        
                        Themer.shared.changeTheme(to: .dark, changePreference: true)
                    }),
                    .init(title: "Light", accessoryType: .check({ appTheme == .light }), handler: {
                        
                        guard appTheme != .light else { return }
                        
                        Themer.shared.changeTheme(to: .light, changePreference: true)
                    }),
                    .init(title: "System", accessoryType: .check({ appTheme == .system }), handler: {
                        
                        guard appTheme != .system else { return }
                        
                        Themer.shared.changeTheme(to: .system, changePreference: true)
                    })
                ]
                
                if #available(iOS 13, *) { } else { alerts.remove(at: 0) }
                
                showAlert(title: "Theme", with: alerts)
                
            } else if let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController {
            
                switch indexPath.row {
                    
                    case 2: presentedVC.context = .libraryRefresh
                    
                    case 3: presentedVC.context = .tabBar
                    
                    case 4: presentedVC.context = .gestures
                    
                    case 5: presentedVC.context = .artwork
                    
                    case 6: presentedVC.context = .background
                    
                    case 7: presentedVC.context = .icon
                    
                    case 8: presentedVC.context = .theme
                    
                    default: break
                }
                
                present(presentedVC, animated: true, completion: nil)
            }
            
        } else if indexPath.section == 2, let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController {
            
            switch indexPath.row {
                
                case 0: presentedVC.context = .queueGuard
                
                case 1: presentedVC.context = .playback
                
                case 2: presentedVC.context = .fullPlayer
                
                default: break
            }
            
            present(presentedVC, animated: true, completion: nil)
            
        } else if indexPath.section == 4, let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController {
            
            switch indexPath.row {
                
                case 3: presentedVC.context = .songDetails
                
                case 4: presentedVC.context = .recents
                
                case 9: presentedVC.context = .lastFM
                
                default: break
            }
            
            present(presentedVC, animated: true, completion: nil)
        
        } else if indexPath.section == 5, screenLockPreventionMode != indexPath.row {
            
//            prepareImageViews(at: indexPath.row)
            prefs.set(indexPath.row, forKey: .screenLockPreventionMode)
            appDelegate.screenLocker.mode = InsomniaMode.init(rawValue: indexPath.row) ?? .disabled
            
            tableView.reloadSections(indexPath.indexSet, with: .none)
        
        } else if indexPath.section == 6 {
            
            performSegue(withIdentifier: "toArranger", sender: indexPath.row)
            
        } else if indexPath.section == 7 {
            
            guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
            
            presentedVC.context = .savedLyrics
            
            self.present(presentedVC, animated: true, completion: nil)
            
        } else if indexPath.section == 8 {
            
            reset()
        
        } else if indexPath.section == 10 {
            
            let playlists = (MPMediaQuery.playlists().collections as? [MPMediaPlaylist])?.filter({ $0.isAppleMusic })
            playlists?.forEach({ ($0.value(forKey: "itemsQuery") as? MPMediaQuery)?.showAll() })
            let items = playlists?.reduce([], { $0 + $1.items.filter({ $0.existsInLibrary.inverted }) }) ?? []
            
            notifier.post(name: .addedToQueue, object: nil, userInfo: [DictionaryKeys.queueItems: items])
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        return indexPath.section == 0 || (indexPath.section == 1 && Set([0]).contains(indexPath.row).inverted) || indexPath.section == 2 || (indexPath.section == 4 && Set([3, 4, 10]).contains(indexPath.row)) || indexPath.section == 5 || indexPath.section == 6 || indexPath.section == 7 || indexPath.section == 8 || indexPath.section == 10
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = sections[section]?.header
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        guard Set([0, 1, 2, 3, 4, 5, 6]).contains(section) else { return .tableHeader }
        
        return .textHeaderHeight + 8
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
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        
        return 50
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 54
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "STVC going away...").show(for: 0.3)
        }
    }
}
