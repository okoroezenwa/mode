//
//  TextViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 18/04/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class TextViewController: UIViewController {

    @IBOutlet var searchBar: MELSearchBar! {
        
        didSet {
            
            searchBar.setImage(nil, for: .search, state: .normal)
        }
    }
    @IBOutlet var textView: MELTextView! {
        
        didSet {
            
            textView.textContainerInset = .init(top: context == .details ? 7 : 10, left: 7, bottom: context == .details ? 0 : 7, right: 7)
        }
    }
    @IBOutlet var creatorView: UIView!
    @IBOutlet var searchBarBottomConstraint: NSLayoutConstraint!
    @IBOutlet var topTitleView: UIView!
    
    enum Context { case details, lyrics }
    
    @objc weak var newPlaylistVC: NewPlaylistViewController?
    weak var updater: LyricsUpdater?
    var textFieldWasFirstResponder = false
    var textViewWasFirstResponder = false
    var context = Context.details
    lazy var object = LyricsObject.init(id: 0, name: nil, artist: nil, titleTerm: nil, artistTerm: nil, source: nil)
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        view.layoutIfNeeded()

        prepare()
        
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        searchBar.setImage(#imageLiteral(resourceName: "CreatorIcon"), for: .search, state: .normal)
        
        (parent as? PresentedContainerViewController)?.transitionStart = { [weak self] in
            
            guard let weakSelf = self else { return }
            
            if weakSelf.searchBar.isFirstResponder {
                
                weakSelf.textFieldWasFirstResponder = true
            
            } else if weakSelf.textView.isFirstResponder {
                
                weakSelf.textViewWasFirstResponder = true
            }
            
            if weakSelf.context == .details {
            
                weakSelf.searchBarBottomConstraint.constant = 0
            }
        }
        
        (parent as? PresentedContainerViewController)?.transitionAnimation = { [weak self] in
            
            guard let weakSelf = self else { return }
            
            if weakSelf.textFieldWasFirstResponder {
                
                weakSelf.searchBar.resignFirstResponder()
                
            } else if weakSelf.textViewWasFirstResponder {
                
                weakSelf.textView.resignFirstResponder()
            }
            
            if weakSelf.context == .details {
                
                weakSelf.view.layoutIfNeeded()
            }
        }
        
        (parent as? PresentedContainerViewController)?.transitionCancellation = { [weak self] in
            
            guard let weakSelf = self else { return }
            
            if weakSelf.textFieldWasFirstResponder {
                
                weakSelf.searchBar.becomeFirstResponder()
                weakSelf.textFieldWasFirstResponder = false
                
            } else if weakSelf.textViewWasFirstResponder {
                
                weakSelf.textView.becomeFirstResponder()
                weakSelf.textViewWasFirstResponder = false
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        textView.flashScrollIndicators()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        if newPlaylistVC?.wasFirstResponder == true {
            
            newPlaylistVC?.nameTextField.becomeFirstResponder()
            newPlaylistVC?.wasFirstResponder = false
        }
    }

    @objc func prepare() {
        
        switch context {
            
            case .details:
            
                searchBar.text = newPlaylistVC?.creatorText
                textView.text = newPlaylistVC?.descriptionText
                textView.keyboardDismissMode = .onDrag
                searchBar.becomeFirstResponder()
            
            case .lyrics:
                
                topTitleView.isHidden = true
                creatorView.isHidden = true
            
                textView.scrollIndicatorInsets.bottom = 14
                textView.text = object.lyrics
                textView.keyboardDismissMode = .interactive
        }
    }
    
    @IBAction func focusDescription() {
        
        textView.becomeFirstResponder()
    }
    
    @IBAction func focusCreator() {
        
        searchBar.becomeFirstResponder()
    }
    
    @objc func adjustKeyboard(with notification: Notification) {
        
        guard let keyboardHeightAtEnd = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height, searchBar.isFirstResponder || textView.isFirstResponder else { return }
        
        let keyboardWillShow = notification.name == UIResponder.keyboardWillShowNotification
        
        switch context {
            
            case .details:
            
                searchBarBottomConstraint.constant = keyboardWillShow && searchBar.isFirstResponder ? keyboardHeightAtEnd - 6 : 0
                
                UIView.animate(withDuration: 0.3, animations: { self.view.layoutIfNeeded() })
            
            case .lyrics: UIView.animate(withDuration: 0.3, animations: {
                
                self.textView.contentInset.bottom = keyboardHeightAtEnd - 6
                self.textView.scrollIndicatorInsets.bottom = keyboardHeightAtEnd + 4
            })
        }
    }
}

protocol LyricsUpdater: LyricsObjectContainer {
    
    func updateLyrics(with object: LyricsObject)
}
