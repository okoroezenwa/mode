//
//  TextViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 18/04/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class TextViewController: UIViewController {

    @IBOutlet weak var searchBar: MELSearchBar! {
        
        didSet {
            
            searchBar.setImage(nil, for: .search, state: .normal)
        }
    }
    @IBOutlet weak var textView: MELTextView! {
        
        didSet {
            
            textView.textContainerInset = .init(top: 7, left: 7, bottom: 0, right: 7)
        }
    }
    @IBOutlet weak var creatorView: UIView!
    @IBOutlet weak var searchBarBottomConstraint: NSLayoutConstraint!
    
    @objc weak var newPlaylistVC: NewPlaylistViewController?
    var textFieldWasFirstResponder = false
    var textViewWasFirstResponder = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        view.layoutIfNeeded()

        prepare()
        
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: .UIKeyboardWillShow, object: nil)
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: .UIKeyboardWillHide, object: nil)
        
        searchBar.setImage(#imageLiteral(resourceName: "CreatorIcon"), for: .search, state: .normal)
        
        (parent as? PresentedContainerViewController)?.transitionStart = { [weak self] in
            
            guard let weakSelf = self else { return }
            
            if weakSelf.searchBar.isFirstResponder {
                
                weakSelf.textFieldWasFirstResponder = true
            
            } else if weakSelf.textView.isFirstResponder {
                
                weakSelf.textViewWasFirstResponder = true
            }
            
            weakSelf.searchBarBottomConstraint.constant = 0
        }
        
        (parent as? PresentedContainerViewController)?.transitionAnimation = { [weak self] in
            
            guard let weakSelf = self else { return }
            
            if weakSelf.textFieldWasFirstResponder {
                
                weakSelf.searchBar.resignFirstResponder()
                
            } else if weakSelf.textViewWasFirstResponder {
                
                weakSelf.textView.resignFirstResponder()
            }
            
            weakSelf.view.layoutIfNeeded()
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
            
            newPlaylistVC?.nameSearchBar.becomeFirstResponder()
            newPlaylistVC?.wasFirstResponder = false
        }
    }

    @objc func prepare() {
        
        searchBar.text = newPlaylistVC?.creatorText
        textView.text = newPlaylistVC?.descriptionText
        searchBar.becomeFirstResponder()
    }
    
    @IBAction func focusDescription() {
        
        textView.becomeFirstResponder()
    }
    
    @IBAction func focusCreator() {
        
        searchBar.becomeFirstResponder()
    }
    
    @objc func adjustKeyboard(with notification: Notification) {
        
        guard let keyboardHeightAtEnd = ((notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height, searchBar.isFirstResponder || textView.isFirstResponder else { return }
        
        let keyboardWillShow = notification.name == NSNotification.Name.UIKeyboardWillShow
        
        searchBarBottomConstraint.constant = keyboardWillShow && searchBar.isFirstResponder ? keyboardHeightAtEnd - 8 : 0
        
        UIView.animate(withDuration: 0.3, animations: { self.view.layoutIfNeeded() })
    }
}
