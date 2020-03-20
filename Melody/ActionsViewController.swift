//
//  LibraryOptionsViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 12/01/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ActionsViewController: UIViewController {
    
    @IBOutlet var optionsStackView: UIStackView!
    @IBOutlet var offlineButton: MELButton!
    @IBOutlet var offlineButtonBorder: MELBorderView!
    @IBOutlet var foldersSwitch: MELSwitchContainer! {
        
        didSet {
            
            foldersSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleFolders()
            }
        }
    }
    @IBOutlet var emptyPlaylistsSwitch: MELSwitchContainer! {
        
        didSet {
            
            emptyPlaylistsSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.togglePlaylists()
            }
        }
    }
    @IBOutlet var lockButton: MELButton!
    @IBOutlet var lockButtonBorder: MELBorderView!
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var emptySearchButton: UIButton!
    @IBOutlet var getInfoButton: UIButton!
    @IBOutlet var artistsButton: UIButton!
    @IBOutlet var albumsButton: UIButton!
    @IBOutlet var songsButton: UIButton!
    @IBOutlet var genresButton: UIButton!
    @IBOutlet var compilationsButton: UIButton!
    @IBOutlet var composersButton: UIButton!
    @IBOutlet var removeDuplicatesButton: MELButton!
    @IBOutlet var playlistsButton: MELButton!
    @IBOutlet var libraryTopStackView: UIStackView!
    @IBOutlet var libraryBottomStackView: UIStackView!
    @IBOutlet var filterButton: UIButton!
    @IBOutlet var switchButton: MELButton!
    @IBOutlet var themeButton: MELButton!
    @IBOutlet var themeButtonBorder: MELBorderView!
    @IBOutlet var allButton: MELButton!
    @IBOutlet var appleMusicButton: MELButton!
    @IBOutlet var yoursButton: MELButton!
    @IBOutlet var dynamicSwitch: MELSwitchContainer! {
        
        didSet {
            
            dynamicSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleDynamicStatusBar()
            }
        }
    }
    @IBOutlet var boldSwitch: MELSwitchContainer! {
        
        didSet {
            
            boldSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleBold(weakSelf)
            }
        }
    }
    @IBOutlet var unaddedSwitch: MELSwitchContainer! {
        
        didSet {
            
            unaddedSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleUnadded()
            }
        }
    }
    @IBOutlet var preventSwitch: MELSwitchContainer! {
        
        didSet {
            
            preventSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.togglePreventDuplicates()
            }
        }
    }
    @IBOutlet var volumeViewContainer: UIView!
    
    enum Configuration { case library, search, collection, nowPlaying, info, collected, queue }
    
    var configuration = Configuration.library {
        
        didSet {
            
            guard changeConfiguration else { return }
            
            prepare(self)
        }
    }
    
    lazy var rateShareView: RateShareView = { RateShareView.instance(container: self.sender as? NowPlayingViewController ?? self) }()
    lazy var volumeView = VolumeView.instance(leadingWith: 20)
    
//    @objc lazy var index: CGFloat = 0
    lazy var context = InfoViewController.Context.song(location: .queue(loaded: false, index: Queue.shared.indexToUse), at: 0, within: [musicPlayer.nowPlayingItem].compactMap({ $0 }))
    @objc var libraryVC: LibraryViewController? { return sender as? LibraryViewController ?? sender?.parent as? LibraryViewController }
    var filterer: Filterable? { return sender as? Filterable }
    var overridable: OnlineOverridable? { return sender as? OnlineOverridable }
    var boldable: Boldable? { return sender as? Boldable }
    @objc var searchVC: SearchViewController? { return sender as? SearchViewController }
    @objc var collectionsVC: CollectionsViewController? { return sender as? CollectionsViewController }
    @objc var sender: UIViewController?
    @objc lazy var count = 0
    @objc var subviewCount: Int { return optionsStackView.arrangedSubviews.count }
    var playlistButtons: [MELButton?] { return [allButton, appleMusicButton, yoursButton] }
    @objc var persistPopovers = false
    var changeConfiguration = true
    var ignoreNotification = false

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        notifier.addObserver(self, selector: #selector(offlineModeChanged), name: .iCloudVisibilityChanged, object: nil)
        
        notifier.addObserver(self, selector: #selector(dynamicStatusBarChanged), name: .dynamicStatusBarChanged, object: nil)
        
        notifier.addObserver(self, selector: #selector(themeChanged), name: .themeChanged, object: nil)
        
        notifier.addObserver(self, selector: #selector(prepare(_:)), name: .libraryOptionsChanged, object: nil)
        
        let hold = UILongPressGestureRecognizer.init(target: self, action: #selector(toggleLock(_:)))
        hold.minimumPressDuration = longPressDuration
        hold.delegate = self
        lockButton.addGestureRecognizer(hold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func prepare(_ sender: Any) {
        
        guard !ignoreNotification else { return }
        
        let animated = sender is Notification
        
        if let options = (sender as? Notification)?.userInfo?["options"] as? LibraryOptions {
            
            if options.count > 0 {
                
                count = options.count
            }
            
            self.sender = options.fromVC
            
            if let context = options.context {
                
                self.context = context
            }
            
            changeConfiguration = false
            
            configuration = options.configuration
        }
        
        var array = [UIView?]()
        
        switch configuration {
            
            case .library:
                
                array = [emptySearchButton, foldersSwitch, dynamicSwitch, boldSwitch, switchButton, volumeViewContainer.viewWithTag(1), preventSwitch, removeDuplicatesButton] as [UIView?]
                
                if collectionsVC?.collectionKind == .playlist {
                    
                    array.append(unaddedSwitch)
                    
                    if let playlistsVC = collectionsVC, playlistsVC.presented {
                        
                        emptyPlaylistsSwitch.setOn(playlistsVC.presentedEmptyPlaylists, animated: false)
                        
                    } else {
                        
                        emptyPlaylistsSwitch.setOn(!shouldHideEmptyPlaylists, animated: false)
                    }
                    
                    foldersSwitch.setOn(showPlaylistFolders, animated: false)
                    
                    if collectionsVC?.presented == true {
                        
                        array.append(allButton.superview)
                        
                        if !showSectionChooserEverywhere {
                            
                            [libraryTopStackView, libraryBottomStackView].forEach({ array.append($0) })
                        }
                        
                    } else {
                        
                        switch appDelegate.appleMusicStatus {
                            
                            case .appleMusic(libraryAccess: _): button(for: collectionsVC?.currentPlaylistsView ?? .all).update(for: .selected)
                            
                            default: array.append(allButton.superview)
                        }
                        
                        [libraryTopStackView, libraryBottomStackView].forEach({ array.append($0) })
                    }
                    
                } else {
                    
                    if libraryVC?.activeChildViewController is SongsViewController, appDelegate.appleMusicStatus == .appleMusic(libraryAccess: true) {
                    
                        unaddedSwitch.setOn(showUnaddedMusic, animated: false)
                    
                    } else {
                        
                        array.append(unaddedSwitch)
                    }
                    
                    for view in [allButton.superview, emptyPlaylistsSwitch] {
                        
                        array.append(view)
                    }
                    
                    [libraryTopStackView, libraryBottomStackView].forEach({ array.append($0) })
                }
                
                if count > 1 {
                    
                    getInfoButton.superview?.isHidden = true
                    
                } else {
                    
                    array.append(getInfoButton.superview?.superview?.superview)
                }
                
                if let section = collectionsVC?.presented == true ? LibrarySection(rawValue: lastUsedLibrarySection) : libraryVC?.section {
                    
                    button(for: section).superview?.superview?.viewWithTag(1)?.isHidden = false
                }
            
            case .search:
                
                array = [emptyPlaylistsSwitch, foldersSwitch, getInfoButton.superview?.superview?.superview, allButton.superview, dynamicSwitch, boldSwitch, switchButton, unaddedSwitch, volumeViewContainer.viewWithTag(1), preventSwitch, removeDuplicatesButton, emptySearchButton]
                
                button(for: LibrarySection(rawValue: lastUsedLibrarySection) ?? .artists).superview?.superview?.viewWithTag(1)?.isHidden = false
            
            case .collection:
                
                array = [emptyPlaylistsSwitch, foldersSwitch, emptySearchButton, allButton.superview, dynamicSwitch, boldSwitch, switchButton, unaddedSwitch, volumeViewContainer.viewWithTag(1), preventSwitch, removeDuplicatesButton] as [UIView?]
                
                if let container = appDelegate.window?.rootViewController as? ContainerViewController, !container.filterViewContainer.filterView.withinSearchTerm {
                    
                    [libraryTopStackView, libraryBottomStackView].forEach({ array.append($0) })
                }
                
                switch context {
                    
                    case .album(at: let index, within: let collections): filterButton.superview?.isHidden = collections[index].items.count < 2
                    
                    case .collection(kind: _, at: let index, within: let collections): filterButton.superview?.isHidden = collections[index].items.count < 2
                    
                    case .playlist(at: let index, within: let collections): filterButton.superview?.isHidden = collections[index].items.count < 2
                    
                    default: break
                }
                
                button(for: LibrarySection(rawValue: lastUsedLibrarySection) ?? .artists).superview?.superview?.viewWithTag(1)?.isHidden = false
            
            case .nowPlaying:
                
                array = [emptyPlaylistsSwitch, foldersSwitch, emptySearchButton, allButton.superview, switchButton, unaddedSwitch, boldSwitch, preventSwitch, removeDuplicatesButton] as [UIView?]
                
                if !showSectionChooserEverywhere {
                    
                    [libraryTopStackView, libraryBottomStackView].forEach({ array.append($0) })
                
                } else {
                    
                    button(for: LibrarySection(rawValue: lastUsedLibrarySection) ?? .artists).superview?.superview?.viewWithTag(1)?.isHidden = false
                }
                
                if showVolumeViews {
                    
                    volumeViewContainer.fill(with: rateShareView)
                    rateShareView.entity = musicPlayer.nowPlayingItem
                
                } else {
                    
                    volumeViewContainer.fill(with: volumeView)
                }
                
                dynamicSwitch.setOn(dynamicStatusBar, animated: false)
                boldSwitch.setOn(nowPlayingBoldTextEnabled, animated: false)
            
                filterButton.superview?.isHidden = true
            
            case .info:
                
                array = [emptyPlaylistsSwitch, foldersSwitch, emptySearchButton, allButton.superview, getInfoButton.superview?.superview?.superview, dynamicSwitch, unaddedSwitch, volumeViewContainer.viewWithTag(1), preventSwitch, removeDuplicatesButton] as [UIView?]
                
                if !showSectionChooserEverywhere {
                    
                    [libraryTopStackView, libraryBottomStackView].forEach({ array.append($0) })
                
                } else {
                    
                    button(for: LibrarySection(rawValue: lastUsedLibrarySection) ?? .artists).superview?.superview?.viewWithTag(1)?.isHidden = false
                }
                
                if /*isInDebugMode, */case .song(_, at: let index, within: let items) = context/*, musicPlayer.nowPlayingItem != nil*/, items[index] == musicPlayer.nowPlayingItem { array.append(switchButton) } else if !isInDebugMode || musicPlayer.nowPlayingItem == nil {
                    
                    array.append(switchButton)
                }
                
                boldSwitch.setOn(infoBoldTextEnabled, animated: false)
            
            case .collected:
            
                array = [emptyPlaylistsSwitch, foldersSwitch, emptySearchButton, allButton.superview, getInfoButton.superview?.superview?.superview, dynamicSwitch, unaddedSwitch, volumeViewContainer.viewWithTag(1), switchButton, boldSwitch] as [UIView?]
                
                if !showSectionChooserEverywhere {
                    
                    [libraryTopStackView, libraryBottomStackView].forEach({ array.append($0) })
                
                } else {
                    
                    button(for: LibrarySection(rawValue: lastUsedLibrarySection) ?? .artists).superview?.superview?.viewWithTag(1)?.isHidden = false
                }
            
                if collectorPreventsDuplicates {
                    
                    array.append(removeDuplicatesButton)
                }
                
                preventSwitch.setOn(collectorPreventsDuplicates, animated: false)
            
            case .queue:
            
                array = [emptyPlaylistsSwitch, foldersSwitch, emptySearchButton, allButton.superview, getInfoButton.superview?.superview?.superview, dynamicSwitch, unaddedSwitch, volumeViewContainer.viewWithTag(1), switchButton, boldSwitch, preventSwitch, removeDuplicatesButton] as [UIView?]
                
                if !showSectionChooserEverywhere {
                    
                    [libraryTopStackView, libraryBottomStackView].forEach({ array.append($0) })
                
                } else {
                    
                    button(for: LibrarySection(rawValue: lastUsedLibrarySection) ?? .artists).superview?.superview?.viewWithTag(1)?.isHidden = false
                }
        }
        
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            
            self.optionsStackView.arrangedSubviews.forEach({
                
                let bool = Set(array.compactMap({ $0?.superview })).contains($0)
                
                if bool && $0.isHidden == true { } else { $0.isHidden = bool }
                
                $0.alpha = bool ? 0 : 1
            })
            
            if appDelegate.appleMusicStatus == .none && self.offlineButton.superview?.isHidden == true { } else {
                
                self.offlineButton.superview?.isHidden = appDelegate.appleMusicStatus == .none
            }
            
            self.offlineButton.superview?.alpha = appDelegate.appleMusicStatus == .none ? 0 : 1
            self.themeButtonBorder.clear = !darkTheme
            self.lockButtonBorder.clear = !persistActionsView && !self.persistPopovers
            
            if let playlistsVC = self.collectionsVC, playlistsVC.presented {
                
                self.offlineButtonBorder.clear = playlistsVC.onlineOverride
                
            } else {
                
                self.offlineButtonBorder.clear = showiCloudItems
            }
            
            self.preferredContentSize = .init(width: 350, height: CGFloat(54 * (self.subviewCount - array.count)))
        })
    }
    
    @objc func updateFilterConstraints() {
        
        
    }
    
    @objc func offlineModeChanged(_ sender: Any) {
        
        let shouldDismiss = !(sender is Notification)
        
        UIView.animate(withDuration: 0.3, animations: {
            
            if let playlistsVC = self.collectionsVC, playlistsVC.presented {
                
                self.offlineButtonBorder.clear = playlistsVC.onlineOverride
                
            } else {
                
                self.offlineButtonBorder.clear = showiCloudItems
            }
            
        }, completion: { _ in
            
            if !persistActionsView && !self.persistPopovers, shouldDismiss {
                
                self.dismiss(animated: true, completion: nil)
            }
        })
//        updateTempView(animated: true)
    }
    
    @objc func dynamicStatusBarChanged() {
        
        dynamicSwitch.setOn(dynamicStatusBar, animated: true)
    }
    
    @objc func themeChanged(_ sender: Any) {
        
        let shouldDismiss = !(sender is Notification)
        let changeIconIfNeeded: (() -> ()) = {
            
            let icon = Icon.iconName(type: iconType, width: iconLineWidth, theme: iconTheme).rawValue.nilIfEmpty
            
            if #available(iOS 10.3, *), UIApplication.shared.supportsAlternateIcons, iconTheme == .match, icon != UIApplication.shared.alternateIconName {
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { UIApplication.shared.setAlternateIconName(icon, completionHandler: { error in if let error = error { print(error) } }) })
            }
        }
        
        UIView.animate(withDuration: 0.3, animations: { self.themeButtonBorder.clear = !darkTheme }, completion: { _ in
            
            if !persistActionsView && !self.persistPopovers, shouldDismiss {
                
                self.dismiss(animated: isInDebugMode, completion: { changeIconIfNeeded() })
            
            } else {
                
                changeIconIfNeeded()
            }
        })
    }
    
    @objc func persistenceLockChanged() {
        
        UIView.animate(withDuration: 0.3, animations: { self.lockButtonBorder.clear = !persistActionsView && !self.persistPopovers })
    }
    
    func button(for section: LibrarySection) -> UIButton {
        
        switch section {
            
            case .artists: return artistsButton
                
            case .albums: return albumsButton
                
            case .songs: return songsButton
                
            case .genres: return genresButton
                
            case .compilations: return compilationsButton
                
            case .composers: return composersButton
            
            case .playlists: return playlistsButton
        }
    }
    
    func section(for button: UIButton) -> LibrarySection {
        
        switch button {
            
            case artistsButton: return .artists
            
            case albumsButton: return .albums
            
            case genresButton: return .genres
            
            case songsButton: return .songs
            
            case compilationsButton: return .compilations
            
            case composersButton: return .composers
            
            case playlistsButton: return .playlists
            
            default: fatalError("No other buttons should invoke this")
        }
    }
    
    @IBAction func togglePlaylists() {
        
        if let playlistsVC = collectionsVC, playlistsVC.presented {
            
            playlistsVC.presentedEmptyPlaylists = !playlistsVC.presentedEmptyPlaylists
            playlistsVC.updateWithQuery()
        
        } else {
            
            prefs.set(!shouldHideEmptyPlaylists, forKey: .hideEmptyPlaylists)
            notifier.post(name: .emptyPlaylistsVisibilityChanged, object: nil)
        }
        
        if !persistActionsView && !persistPopovers {
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func toggleOffline(_ sender: NSObject) {
        
        if let playlistsVC = collectionsVC, playlistsVC.presented {
            
            playlistsVC.performOnlineOverride()
            
        } else {
            prefs.set(!showiCloudItems, forKey: .iCloudItems)
            notifier.post(name: .iCloudVisibilityChanged, object: nil)
        }
        
        offlineModeChanged(sender)
    }
    
    @IBAction func toggleLock(_ sender: Any) {
        
        if let gr = sender as? UIGestureRecognizer, gr.state == .began {
            
            persistPopovers = !persistPopovers
            
            UniversalMethods.banner(withTitle: persistPopovers ? "Temporarily Locked" : "Unlocked").show(for: 0.7)
            
        } else if sender is UIButton {
            
            var setPreference = true
            
            if persistPopovers {
                
                persistPopovers = false
                setPreference = persistActionsView
            }
            
            if setPreference {
                
                prefs.set(!persistActionsView, forKey: .persistActionsView)
            }
        }
        
        persistenceLockChanged()
    }
    
    @IBAction func toggleTheme(_ sender: UIButton) {
        
        prefs.set(!darkTheme, forKey: .manualNightMode)
        prefs.set(!darkTheme, forKey: .darkTheme)
        
        if let view = appDelegate.window?.rootViewController?.view {
            
            UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: { notifier.post(name: .themeChanged, object: nil) }, completion: nil)
        }
        
        themeChanged(sender)
        
        view.backgroundColor = UIDevice.current.isBlurAvailable ? .clear : darkTheme ? UIColor.darkGray.withAlphaComponent(0.6) : .white
        popoverPresentationController?.backgroundColor = darkTheme ? UIColor.darkGray.withAlphaComponent(UIDevice.current.isBlurAvailable ? 0.5 : 1) : UIColor.white.withAlphaComponent(UIDevice.current.isBlurAvailable ? 0.6 : 1)
    }
    
    func toggleFolders() {
        
        prefs.set(showPlaylistFolders.inverted, forKey: .showPlaylistFolders)
        notifier.post(name: .showPlaylistFoldersChanged, object: nil)
        
        if !persistActionsView && !persistPopovers {
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func chooseSection(_ sender: UIButton) {
        
        ignoreNotification = !persistActionsView && !persistPopovers
        
        guard let section = LibrarySection(rawValue: prefs.integer(forKey: .lastUsedLibrarySection)), let firstView = button(for: section).superview?.superview?.viewWithTag(1), let secondView = sender.superview?.superview?.viewWithTag(1) else { return }
        
        if let libraryVC = libraryVC, collectionsVC?.presented != true {
            
            if sender == button(for: libraryVC.section) {
                
                if !persistActionsView && !persistPopovers {
                    
                    dismiss(animated: false, completion: nil)
                }
                
                return
            }
            
            UIView.transition(from: firstView, to: secondView, duration: 0.1, options: [.showHideTransitionViews, .transitionCrossDissolve], completion: { [weak self] finished in
                
                guard let weakSelf = self, finished else { return }
                
                prefs.set(weakSelf.section(for: sender).rawValue, forKey: .lastUsedLibrarySection)
                libraryVC.activeChildViewController = libraryVC.viewControllerForCurrentSection()
                
                if !persistActionsView && !weakSelf.persistPopovers {
                    
                    weakSelf.dismiss(animated: false, completion: nil)
                }
            })
        
        } else {
            
            useAlternateAnimation = true
            shouldReturnToContainer = true
            
            UIView.transition(from: firstView, to: secondView, duration: 0.1, options: [.showHideTransitionViews, .transitionCrossDissolve], completion: { [weak self] finished in
                
                guard let weakSelf = self, finished else { return }
                
                if let container = appDelegate.window?.rootViewController as? ContainerViewController {
                    
                    if container.activeViewController == container.libraryNavigationController, let details = container.filterViewContainer.filterView.locationDetails(for: weakSelf.section(for: sender)) {
                        
                        container.filterViewContainer.filterView.selectCell(at: details.indexPath, usingOtherArray: details.fromOtherArray, arrayIndex: details.index)
                        container.filterViewContainer.filterView.collectionView.scrollToItem(at: details.indexPath, at: .centeredHorizontally, animated: true)
                        
                    } else {
                        
                        let oldSection = prefs.integer(forKey: .lastUsedLibrarySection)
                        let section = weakSelf.section(for: sender).rawValue
        
                        prefs.set(section, forKey: .lastUsedLibrarySection)
                        notifier.post(name: .changeLibrarySection, object: nil, userInfo: ["section": section, "oldSection": oldSection])
                        
                        container.switchViewController(container.libraryButton)
                    }
                }
                
                if (!persistActionsView && !weakSelf.persistPopovers) || weakSelf.configuration != .search {
                    
                    weakSelf.performSegue(withIdentifier: "unwind", sender: nil)
                }
            })
        }
    }
    
    @IBAction func toggleDynamicStatusBar() {
        
        prefs.set(!dynamicStatusBar, forKey: .dynamicStatusBar)
        notifier.post(name: .dynamicStatusBarChanged, object: nil)
        
        if !persistActionsView && !persistPopovers {
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func toggleBold(_ sender: Any) {
        
        switch configuration {
            
            case .nowPlaying:
            
                prefs.set(!nowPlayingBoldTextEnabled, forKey: .nowPlayingBoldTitle)
                notifier.post(name: .nowPlayingTextSizesChanged, object: nil)
            
            case .info:
            
                prefs.set(!infoBoldTextEnabled, forKey: .infoBoldText)
                notifier.post(name: .infoTextSizesChanged, object: nil)
            
            default: break
        }
        
        if !persistActionsView && !persistPopovers {
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func toggleUnadded() {
        
        guard libraryVC?.activeChildViewController is SongsViewController else { return }
        
        prefs.set(!showUnaddedMusic, forKey: .showUnaddedMusic)
        notifier.post(name: .showUnaddedSongsChanged, object: nil)
        
        if !persistActionsView && !persistPopovers {
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func togglePreventDuplicates() {
        
        if !collectorPreventsDuplicates, let collectedVC = sender as? CollectorViewController {
            
            collectedVC.removeDuplicates()
        }
        
        prefs.set(!collectorPreventsDuplicates, forKey: .collectorPreventsDuplicates)
        
        if !persistActionsView && !persistPopovers {
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func filter() {
        
        guard filterer?.canFilter == true else { return }
        
        dismiss(animated: /*true*/false, completion: { self.filterer?.invokeSearch() })
    }
    
    @IBAction func emptySearch() {
        
        searchVC?.performEmptySearch()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func switchPlaylistsView(_ sender: UIButton) {
        
//        guard sender != button(for: collectionsVC?.currentPlaylistsView ?? .all) else { return }
        
        for button in playlistButtons {
            
            if button == sender {
                
                button?.update(for: .selected)
                
                collectionsVC?.changeView(from: collectionsVC?.currentPlaylistsView ?? .all, to: playlistView(for: sender))
                
            } else {
                
                button?.update(for: .unselected, capitalised: true)
            }
        }
        
        if !persistActionsView && !persistPopovers {
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func switchToNowPlaying() {
        
        if let sender = sender as? InfoViewController {
            
            let context = InfoViewController.Context.song(location: .queue(loaded: false, index: Queue.shared.indexToUse), at: 0, within: [musicPlayer.nowPlayingItem].compactMap({ $0 }))

            if persistActionsView || persistPopovers {
                
                UIView.animate(withDuration: 0.3, animations: {
                
                    self.switchButton.superview?.isHidden = true
                    self.preferredContentSize.height -= 54
                })
                
                Transitioner.shared.showInfo(from: self, with: context)
            
            } else {
                
                dismiss(animated: false, completion: { Transitioner.shared.showInfo(from: sender, with: context) })
            }
        }
    }
    
//    @IBAction func performOnlineOverride() {
//        
//        toggleOffline(sender: tempButton)
//    }
    
    @IBAction func goToSettings() {
        
        guard !persistActionsView && !persistPopovers else {
            
            performSegue(withIdentifier: "toSettings", sender: nil)
            
            return
        }
        
        dismiss(animated: false, completion: { self.sender?.showSettings(with: self) })
    }
    
    @IBAction func goToInfo() {
        
        guard !persistActionsView && !persistPopovers, let sender = sender else {
            
            performSegue(withIdentifier: "toOptions", sender: nil)
            
            return
        }
        
        dismiss(animated: false, completion: { Transitioner.shared.showInfo(from: sender, with: self.context) })
    }
    
    @IBAction func removeDuplicates() {
        
        if let collectedVC = sender as? CollectorViewController {
            
            collectedVC.removeDuplicates()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let id = segue.identifier else { return }
        
        if id == "toSettings", let presentedVC = segue.destination as? PresentedContainerViewController {
            
            presentedVC.context = .settings
        
        } else if id == "toOptions", let presentedVC = segue.destination as? PresentedContainerViewController {
            
            presentedVC.context = .info
            presentedVC.optionsContext = context
        }
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "LOVC going away...").show(for: 0.3)
        }
        
        notifier.removeObserver(self)
    }
    
    private func button(for view: PlaylistView) -> UIButton {
        
        switch view {
            
            case .all: return allButton
            
            case .appleMusic: return appleMusicButton
            
            case .user: return yoursButton
        }
    }
    
    private func playlistView(for button: UIButton) -> PlaylistView {
        
        switch button {
            
            case allButton: return .all
            
            case yoursButton: return .user
            
            case appleMusicButton: return .appleMusic
            
            default: fatalError("No other button should invoke this")
        }
    }
}

struct LibraryOptions {
    
    let fromVC: UIViewController?
    let configuration: ActionsViewController.Configuration
    let context: InfoViewController.Context?
    let count: Int
    
    init(fromVC: UIViewController?, configuration: ActionsViewController.Configuration, context: InfoViewController.Context? = nil, count: Int = 0) {
        
        self.fromVC = fromVC
        self.configuration = configuration
        self.context = context
        self.count = count
    }
}

extension ActionsViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return !persistActionsView
    }
}
