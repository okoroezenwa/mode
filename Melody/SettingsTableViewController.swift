//
//  SettingsTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 27/10/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var offlineSwitch: MELSwitch! {
        
        didSet {
            
            offlineSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleCloud()
            }
        }
    }
    @IBOutlet weak var countsSwitch: MELSwitch! {
        
        didSet {
            
            countsSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleCounts()
            }
        }
    }
    @IBOutlet weak var numbersSwitch: MELSwitch! {
        
        didSet {
            
            numbersSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleNumbersBelow()
            }
        }
    }
    @IBOutlet weak var explicitSwitch: MELSwitch! {
        
        didSet {
            
            explicitSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleExplicit()
            }
        }
    }
    @IBOutlet weak var artistStartPointSwitch: MELSwitch! {
        
        didSet {
            
            artistStartPointSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleArtistStartPoint()
            }
        }
    }
    @IBOutlet weak var deinitSwitch: MELSwitch! {
        
        didSet {
            
            deinitSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleDeinit()
            }
        }
    }
    @IBOutlet weak var infoSwitch: MELSwitch! {
        
        didSet {
            
            infoSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleInfoButtons()
            }
        }
    }
    @IBOutlet weak var volumeSwitch: MELSwitch! {
        
        didSet {
            
            volumeSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleVolumeViews()
            }
        }
    }
    @IBOutlet weak var themeLabel: MELLabel!
    @IBOutlet weak var chooserSwitch: MELSwitch! {
        
        didSet {
            
            chooserSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleChooser()
            }
        }
    }
    @IBOutlet weak var fasterSwitch: MELSwitch! {
        
        didSet {
            
            fasterSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleFasterStartup()
            }
        }
    }
    @IBOutlet weak var lighterSwitch: MELSwitch! {
        
        didSet {
            
            lighterSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleLighterBorders()
            }
        }
    }
    @IBOutlet weak var descriptorSwitch: MELSwitch! {
        
        didSet {
            
            descriptorSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleDescriptor()
            }
        }
    }
    @IBOutlet weak var mediaItemsSwitch: MELSwitch! {
        
        didSet {
            
            mediaItemsSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleMediaItems()
            }
        }
    }
    @IBOutlet weak var manualSwitch: MELSwitch! {
        
        didSet {
            
            manualSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleManual()
            }
        }
    }
    @IBOutlet weak var nightSwitch: MELSwitch! {
        
        didSet {
            
            nightSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleNightMode()
            }
        }
    }
    @IBOutlet weak var neverImageView: MELImageView!
    @IBOutlet weak var pluggedImageView: MELImageView!
    @IBOutlet weak var alwaysImageView: MELImageView!
    @IBOutlet weak var refreshLabel: MELLabel!
    @IBOutlet var cells: [UITableViewCell]!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        cells.forEach({ $0.selectedBackgroundView = MELBorderView.init() })
        
        tableView.scrollIndicatorInsets.bottom = 14
        
        prepareSwitches(animated: false)
        
        notifier.addObserver(self, selector: #selector(updateThemeLabel), name: .themeChanged, object: nil)
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    @objc func prepareSwitches(animated: Bool) {
        
        offlineSwitch.setOn(!showiCloudItems, animated: animated)
        countsSwitch.setOn(songCountVisible, animated: animated)
        numbersSwitch.setOn(numbersBelowLetters, animated: animated)
        explicitSwitch.setOn(showExplicit, animated: animated)
        artistStartPointSwitch.setOn(artistItemsStartingPoint == EntityItemsViewController.StartPoint.songs.rawValue, animated: animated)
        deinitSwitch.setOn(deinitBannersEnabled, animated: animated)
        infoSwitch.setOn(showInfoButtons, animated: animated)
        volumeSwitch.setOn(showVolumeViews, animated: animated)
        chooserSwitch.setOn(showSectionChooserEverywhere, animated: animated)
        fasterSwitch.setOn(fasterNowPlayingStartup, animated: animated)
        lighterSwitch.setOn(useLighterBorders, animated: animated)
        descriptorSwitch.setOn(useDescriptor, animated: animated)
        mediaItemsSwitch.setOn(useMediaItems, animated: animated)
        manualSwitch.setOn(useOldStyleQueue, animated: animated)
        nightSwitch.setOn(darkTheme, animated: animated)
        updateThemeLabel()
        prepareImageViews()
    }
    
    @objc func updateThemeLabel() {
        
        themeLabel.text = (darkTheme && manualNightMode) || (!brightnessConstraintEnabled && !timeConstraintEnabled) ? nil : "Scheduled"
    }
    
    func prepareImageViews(at row: Int? = nil) {
        
        if let row = row {
            
            prefs.set(row, forKey: .screenLockPreventionMode)
            appDelegate.screenLocker.mode = InsomniaMode.init(rawValue: row) ?? .disabled
        }
        
        neverImageView.isHidden = screenLockPreventionMode != InsomniaMode.disabled.rawValue
        alwaysImageView.isHidden = screenLockPreventionMode != InsomniaMode.always.rawValue
        pluggedImageView.isHidden = screenLockPreventionMode != InsomniaMode.whenCharging.rawValue
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
    
    func toggleNightMode() {
        
        prefs.set(!darkTheme, forKey: .manualNightMode)
        prefs.set(!darkTheme, forKey: .darkTheme)
        
        let icon = Icon.iconName(width: iconLineWidth, theme: iconTheme).rawValue.nilIfEmpty
        
        if #available(iOS 10.3, *), UIApplication.shared.supportsAlternateIcons, iconTheme == .match, icon != UIApplication.shared.alternateIconName {
            
            UniversalMethods.performOnMainThread({
                
                UIApplication.shared.setAlternateIconName(icon, completionHandler: { _ in })
                
            }, afterDelay: 0.2)
        }
        
        if let view = appDelegate.window?.rootViewController?.view {
            
            UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: { notifier.post(name: .themeChanged, object: nil) }, completion: nil)
        }
    }
    
    func reset() {
        
        let reset = UIAlertAction.init(title: "Reset All Settings", style: .destructive, handler: { _ in
            
            let wasCloud = showiCloudItems
            let wasDynamic = dynamicStatusBar
            let wasBold = nowPlayingBoldTextEnabled
            let wasSinglePlay = allowPlayOnly
            
            Settings.resetDefaults()
            
            self.prepareSwitches(animated: true)
            
            if !wasCloud {
                
                notifier.post(name: .iCloudVisibilityChanged, object: nil)
            }
            
            if !wasDynamic {
                
                notifier.post(name: .dynamicStatusBarChanged, object: nil)
            }
            
            if wasBold {
                
                notifier.post(name: .nowPlayingTextSizesChanged, object: nil)
            }
            
            if !wasSinglePlay {
                
                notifier.post(name: .playOnlyChanged, object: nil)
            }
            
            if darkTheme {
                
                if let view = appDelegate.window?.rootViewController?.view {
                    
                    UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: { notifier.post(name: .themeChanged, object: nil) }, completion: nil)
                }
            }
            
            if nowPlayingAsBackground {
                
                notifier.post(name: .nowPlayingBackgroundUsageChanged, object: nil)
            }
        })
        
        present(UniversalMethods.alertController(withTitle: nil, message: nil, preferredStyle: .actionSheet, actions: reset, UniversalMethods.cancelAlertAction()), animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toTips", let presentedVC = segue.destination as? PresentedContainerViewController {
            
            presentedVC.context = .tips
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return isInDebugMode ? 8 : 7
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
            
            case 4: return 9
            
            case 5: return 3
            
            case 7: return 4
            
            default: return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            
            if let url = URL.init(string: "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1170715139&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8") {
                
                UIApplication.shared.openURL(url)
            }
        
        } else if indexPath.section == 1, let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController {
            
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
                
                default: break
            }
            
            present(presentedVC, animated: true, completion: nil)
        
        } else if indexPath.section == 5, screenLockPreventionMode != indexPath.row {
            
            prepareImageViews(at: indexPath.row)
        
        } else if indexPath.section == 6 {
            
            reset()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        return indexPath.section == 0 || (indexPath.section == 1 && Set([0, 1]).contains(indexPath.row).inverted) || indexPath.section == 2 || (indexPath.section == 4 && Set([3, 4]).contains(indexPath.row)) || indexPath.section == 5 || indexPath.section == 6
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
        
        header?.label.text = {
            
            switch section {
                
                case 1: return "general"
                
                case 2: return "player"
                
                case 3: return "now playing"
                
                case 4: return "temporary"
                
                case 5: return "sleep prevention"
                
                default: return nil
            }
        }()
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        guard Set([0, 1, 2, 3, 4, 5]).contains(section) else { return .tableHeader }
        
        return .textHeaderHeight + 8
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footer = tableView.sectionFooter
        
        var footerText: String? {
            
            switch section {
                
                case 4: return "Enable or disable extra song info in lists."
                
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
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "STVC going away...").show(for: 0.3)
        }
    }
}
