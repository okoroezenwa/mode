//
//  LyricsViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 06/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit
import SwiftSoup
import SafariServices

class LyricsViewController: UIViewController {

    @IBOutlet var textView: MELTextView! {
        
        didSet {
            
            textView.textContainerInset = UIEdgeInsets.init(top: 10, left: 5, bottom: 10, right: 5)
            textView.scrollIndicatorInsets = UIEdgeInsets.init(top: 10, left: 5, bottom: 10, right: 5)
            textView.textAlignment = textAlignment
        }
    }
    @IBOutlet var locationButton: MELButton!
    @IBOutlet var saveButton: MELButton!
    @IBOutlet var activityIndicator: MELActivityIndicatorView!
    @IBOutlet var bottomStackView: UIStackView!
    @IBOutlet var unavailableLabel: MELLabel!
    @IBOutlet var unavailableView: UIView!
    @IBOutlet var unavailableButton: MELButton!
    @IBOutlet var gradientView: GradientView!
    @IBOutlet var editButton: MELButton!
    
    #warning("Needs localisation update")
    var textAlignment: NSTextAlignment = .left
    lazy var manager = LyricsManager(viewer: self, detailer: nil)
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        updateBottomView(to: .hidden, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        if let nowPlayingVC = parent as? NowPlayingViewController {
            
            let tap = UITapGestureRecognizer.init(target: nowPlayingVC, action: #selector(NowPlayingViewController.viewLyrics))
            view.addGestureRecognizer(tap)
        }
    }
    
    func prepareLyrics(for item: MPMediaItem?, updateBottomView: Bool) {
        
        gradientView.isHidden = true
        unavailableView.isHidden = true
        activityIndicator.startAnimating()
        
        if updateBottomView {
            
            self.updateBottomView(to: .hidden)
        }
        
        manager.viewerOperation?.cancel()
        manager.viewerOperation = BlockOperation()
        manager.viewerOperation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self else { return }
            
            weakSelf.manager.getLyrics(for: item, with: weakSelf.manager, operation: weakSelf.manager.viewerOperation)
        })
        
        manager.lyricsOperationQueue.addOperation(manager.viewerOperation!)
    }
    
    func useDeviceLyrics(source: String?, lyrics: String?, animated: Bool) {
        
        activityIndicator.stopAnimating()
        unavailableView.isHidden = true
        textView.contentOffset = .zero
        textView.text = lyrics
        gradientView.isHidden = false
        
        locationButton.setImage(#imageLiteral(resourceName: "Offline14"), for: .normal)
        locationButton.setTitle(source, for: .normal)
        
        updateBottomView(to: .visible, animated: animated)
    }
    
    func updateBottomView(to state: VisibilityState, animated: Bool = true) {
        
//        if isInDebugMode.inverted {
//
//            bottomStackView.isHidden = true
//            bottomStackView.alpha = 0
//
//            return
//        }
        
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            
            self.bottomStackView.alpha = state == .hidden ? 0 : 1
            self.bottomStackView.transform = state == .hidden ? .init(translationX: 0, y: 36) : .identity
        })
    }
    
    @IBAction func viewLyricsDetails() {
        
        guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }

        presentedVC.lyricsInfoVC.manager = manager
        presentedVC.lyricsInfoVC.currentObject = manager.currentObject
        presentedVC.lyricsInfoVC.originalObject = manager.currentObject
        presentedVC.lyricsInfoVC.hits = manager.hits
        presentedVC.lyricsInfoVC.item = manager.item
        
        presentedVC.context = .lyricsInfo
        present(presentedVC, animated: true, completion: nil)
    }
    
    @IBAction func editLyrics() {
        
        guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
        
        presentedVC.context = .lyricsEdit
        presentedVC.prompt = (manager.item?.validTitle ?+ "  —  ") ?+ manager.item?.validArtist
        presentedVC.textVC.updater = manager
        presentedVC.textVC.object = manager.currentObject
        
        present(presentedVC, animated: true, completion: nil)
    }
    
    @IBAction func showLocationActions() {
        
        let isFromGenius = manager.currentObject.source == LyricsManager.Location.genius.rawValue
        var actions = [UIAlertAction]()
        
        actions.append(UIAlertAction.init(title: isFromGenius ? "Refresh Lyrics" : "Refresh from Genius", style: .default, handler: { _ in
            
            self.prepareLyrics(for: self.manager.item, updateBottomView: true)
        }))
        
        actions.append(UIAlertAction.init(title: "Remove Lyrics", style: .destructive, handler: { _ in
            
            self.manager.currentObject.isDeleted = true
            self.manager.storeLyrics(for: self.manager.item, via: self.manager, completion: ({ self.manager.displayMessage(.deleted, from: self.manager) }, { self.manager.displayMessage(.error, from: self.manager) }))
        }))
        
        if isFromGenius, let lyricsURL = manager.currentObject.url, let url = URL.init(string: lyricsURL) {
            
            actions.append(UIAlertAction.init(title: "Show on Genius", style: .default, handler: { _ in
                
                let vc: SFSafariViewController = {
                    
                    let vc = SFSafariViewController.init(url: url)
                    vc.delegate = self
                    
                    if #available(iOS 10, *) {
                        
                        vc.preferredBarTintColor = darkTheme ? .black : .white
                    }
                    
                    return vc
                }()
                
                self.present(vc, animated: true, completion: nil)
            }))
        }
        
        actions.append(UIAlertAction.init(title: "Manage Saved Lyrics", style: .default, handler: { _ in

            guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
            
            presentedVC.context = .savedLyrics
            
            self.present(presentedVC, animated: true, completion: nil)
        }))
        
        present(UIAlertController.withTitle(nil, message: nil, style: .actionSheet, actions: actions + [.cancel()]), animated: true, completion: nil)
    }
    
    func performSuccesfulLyricsCheck(with text: String?) {
        
        activityIndicator.stopAnimating()
        unavailableView.isHidden = true
        
        textView.contentOffset = .zero
        textView.text = text
        gradientView.isHidden = false
        
        locationButton?.setImage(#imageLiteral(resourceName: "Web"), for: .normal)
        locationButton?.setTitle(LyricsManager.Location.genius.rawValue, for: .normal)
        
        updateBottomView(to: .visible)
    }
    
    func displayUnavailable(with message: LyricsManager.ErrorMessage) {
        
        unavailableLabel.text = message.rawValue
        unavailableButton.setTitle(message == .deleted ? "Restore" : "Try Again", for: .normal)
        activityIndicator.stopAnimating()
        unavailableView.isHidden = false
        gradientView.isHidden = true
        
        updateBottomView(to: .hidden)
    }
    
    @IBAction func actOnError() {
        
        switch manager.currentMessage {
            
            case .deleted:
            
                manager.currentObject.isDeleted = false
                manager.storeLyrics(for: manager.item, via: manager)
            
            default: prepareLyrics(for: manager.item, updateBottomView: true)
        }
    }
    
    deinit {
        
//        if isInDebugMode, deinitBannersEnabled {
//            
//            let banner = UniversalMethods.banner(withTitle: "LVC going away...")
//            banner.titleLabel.font = .myriadPro(ofWeight: .light, size: 22)
//            banner.show(for: 0.3)
//        }
        
        manager.viewerOperation?.cancel()
    }
}

extension LyricsViewController: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        
        if let nowPlayingVC = parent as? NowPlayingViewController {
            
            NowPlaying.shared.nowPlayingVC = nowPlayingVC
            ArtworkManager.shared.nowPlayingVC = nowPlayingVC
        }
    }
}

// MARK: - Genius Codables
struct Genius: Codable, Equatable {
    
    let response: Response
}

struct Response: Codable, Equatable {
    
    let hits: [Hit]
}

struct Hit: Codable, Equatable {
    
    let result: Result
}

struct Result: Codable, Equatable {
    
    enum CodingKeys: String, CodingKey {
        
        case url
        case title
        case artist = "primary_artist"
        case fullTitle = "full_title"
    }
    
    let url: String
    let title: String
    let artist: Artist
    let fullTitle: String
}

struct Artist: Codable, Equatable {
    
    let name: String
}
