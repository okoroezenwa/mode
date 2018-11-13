//
//  LyricsViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 06/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit
import SwiftSoup

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
    
    #warning("Needs localisation update")
    var textAlignment: NSTextAlignment = .left
    lazy var manager = LyricsManager(viewer: self)
    
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
    
    func prepareLyrics(updateBootomView: Bool) {
        
        textView.isHidden = true
        unavailableLabel.isHidden = true
        activityIndicator.startAnimating()
        
        if updateBootomView {
            
            updateBottomView(to: .hidden)
        }
        
        manager.getLyrics()
    }
    
    func useDeviceLyrics(source: String?, lyrics: String?, animated: Bool) {
        
        activityIndicator.stopAnimating()
        unavailableLabel.isHidden = true
        textView.contentOffset = .zero
        textView.text = lyrics
        textView.isHidden = false
        
        locationButton.setImage(#imageLiteral(resourceName: "Offline14"), for: .normal)
        locationButton.setTitle(source, for: .normal)
        
        updateBottomView(to: .visible, animated: animated)
    }
    
    func updateBottomView(to state: VisibilityState, animated: Bool = true) {
        
        if isInDebugMode.inverted {
            
            bottomStackView.isHidden = true
            bottomStackView.alpha = 0
            
            return
        }
        
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            
            self.bottomStackView.alpha = state == .hidden ? 0 : 1
            self.bottomStackView.transform = state == .hidden ? .init(translationX: 0, y: 36) : .identity
        })
    }
    
    @IBAction func viewLyricsDetails() {
        
        guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
        
        presentedVC.context = .lyricsInfo
        presentedVC.lyricsInfoVC.manager = manager
        
        present(presentedVC, animated: true, completion: nil)
    }
    
    func performSuccesfulLyricsCheck(with text: String) {
        
        activityIndicator?.stopAnimating()
        unavailableLabel?.isHidden = true
        
        textView.contentOffset = .zero
        
        textView?.text = text
        
        textView?.isHidden = false
        
        locationButton?.setImage(#imageLiteral(resourceName: "Web"), for: .normal)
        locationButton?.setTitle("genius", for: .normal)
        
        updateBottomView(to: .visible)
    }
    
    func displayUnavailable() {
        
        activityIndicator.stopAnimating()
        unavailableLabel.isHidden = false
        textView.isHidden = true
        
        updateBottomView(to: .hidden)
    }
    
    deinit {
        
//        if isInDebugMode, deinitBannersEnabled {
//            
//            let banner = UniversalMethods.banner(withTitle: "LVC going away...")
//            banner.titleLabel.font = .myriadPro(ofWeight: .light, size: 22)
//            banner.show(for: 0.3)
//        }
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
