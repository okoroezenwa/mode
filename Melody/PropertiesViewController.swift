//
//  PropertiesViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 22/07/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PropertiesViewController: UIViewController {

    @IBOutlet var textView: MELTextView! {
        
        didSet {
            
            textView.textContainerInset = .init(top: 7, left: 7, bottom: 7, right: 7)
        }
    }
    @IBOutlet var tableView: MELTableView!
    @IBOutlet var getSetButton: MELButton!
    @IBOutlet var valueButton: MELButton!
    @IBOutlet var propertyInput: MELSearchBar!
    @IBOutlet var bottomViewBottomConstraint: NSLayoutConstraint!
    
    enum KeyType: String { case property = "P", selector = "S" }
    enum Operation: String { case get = "G", set = "S" }
    enum Button { case leftButton, rightButton }
    enum Key: String {
        
        case persistentID, mediaLibrary, multiverseIdentifier, itemsQuery, artworkCatalog, dateAccessed, lyrics, effectiveAlbumArtist, effectiveStopTime, playCountSinceSync, storeCloudAlbumID, cloudUniversalLibraryID, existsInLibrary, isCloudMix, storeCloudID, isPlaybackHistoryPlaylist, cloudShareURL, cloudGlobalID, cloudIsSubscribed, albumStoreID, artistArtworkCatalog, artistStoreID, albumArtistArtworkCatalog, albumArtistStoreID, genreStoreID, composerStoreID, bitRate
        
        static func keys(for entityType: EntityType) -> [Key] {
        
            let array = [Key.persistentID, .mediaLibrary, .multiverseIdentifier]
            let collectionArray = [Key.itemsQuery]
            
            let others: [Key] = {
            
                switch entityType {
                    
                    case .song: return [.artworkCatalog, .dateAccessed, .playCountSinceSync, .bitRate, .lyrics, .effectiveAlbumArtist, .effectiveStopTime, .storeCloudAlbumID, .cloudUniversalLibraryID]
                    
                    case .playlist: return collectionArray + [.artworkCatalog, .existsInLibrary, .isCloudMix, .storeCloudID, .isPlaybackHistoryPlaylist, .cloudShareURL, .cloudGlobalID, .cloudIsSubscribed]
                    
                    case .album: return collectionArray + [.albumStoreID]
                    
                    case .artist: return collectionArray + [.artistArtworkCatalog, .artistStoreID]
                    
                    case .albumArtist: return collectionArray + [.albumArtistArtworkCatalog, .albumArtistStoreID]
                    
                    case .genre: return collectionArray + [.genreStoreID]
                    
                    case .composer: return collectionArray + [.composerStoreID]
                }
            }()
            
            return array + others
        }
        
        var preferredKeyType: PropertiesViewController.KeyType {
            
            switch self {
                
                case .persistentID, .mediaLibrary, .multiverseIdentifier, .itemsQuery, .artworkCatalog, .dateAccessed, .lyrics, .effectiveAlbumArtist, .effectiveStopTime, .playCountSinceSync, .existsInLibrary, .isCloudMix, .artistArtworkCatalog, .albumArtistArtworkCatalog: return .selector
                
                default: return .property
            }
        }
        
        var preferredOperation: PropertiesViewController.Operation {
            
            switch self {
                
                case .playCountSinceSync, .lyrics: return .set
                
                default: return .get
            }
        }
    }
    
    var entityType = EntityType.song
    var entity: MPMediaEntity?
    lazy var keys = Key.keys(for: entityType)
    var keyType = KeyType.property {
        
        didSet {
            
            update(.rightButton)
        }
    }
    var operation = Operation.get {
        
        didSet {
            
            update(.leftButton)
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notifier.addObserver(self, selector: #selector(adjustKeyboard(with:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func setUpRightView() {
        
        switch operation {
            
            case .get: propertyInput.textField?.rightView = nil
            
            case .set:
            
                let button = MELButton.init(frame: .init(x: 0, y: 0, width: 30, height: 30))
                button.setTitle(nil, for: .normal)
                button.addTarget(self, action: #selector(rightViewButtonTapped), for: .touchUpInside)
                button.setImage(UIImage.init(imageLiteralResourceName: "More13"), for: .normal)
            
                propertyInput.textField?.rightView = button
                propertyInput.textField?.rightViewMode = .always
        }
    }
    
    @objc func rightViewButtonTapped() {
        
        guard let text = propertyInput.text, let entity = entity, entity.value(forProperty: text) != nil, entity.responds(to: NSSelectorFromString(.setValueForProperty)) else { return }
        
        let alert = UIAlertController.init(title: "Set \"\(text)\" to...", message: nil, preferredStyle: .alert)
        
        let action = UIAlertAction.init(title: "Set", style: .default, handler: { _ in
            
            entity.perform(NSSelectorFromString(.setValueForProperty), with: alert.textFields?.first?.text ?? "", with: text)
            
            self.searchBar(self.propertyInput, textDidChange: text)
        })
        
        alert.addTextField(configurationHandler: nil)
        alert.addAction(action)
        alert.addAction(.cancel())
        
        present(alert, animated: true, completion: nil)
    }
    
    func update(_ button: Button) {
        
        switch button {
            
            case .leftButton:
                
                getSetButton.setTitle(operation.rawValue, for: .normal)
                setUpRightView()
            
            case .rightButton:
                
                valueButton.setTitle(keyType.rawValue, for: .normal)
                textView.text = value()
        }
    }
    
    @IBAction func changeValue(_ sender: UIButton) {
        
        let button = sender == getSetButton ? Button.leftButton : .rightButton
        
        switch button {
            
            case .leftButton:
            
                let oldValue = operation
                
                switch oldValue {
                    
                    case .get: operation = .set
                    
                    case .set: operation = .get
                }
            
            case .rightButton:
            
                let oldValue = keyType
                
                switch oldValue {
                    
                    case .property: keyType = .selector
                    
                    case .selector: keyType = .property
                }
        }
    }
    
    @objc func adjustKeyboard(with notification: Notification) {
        
        guard let keyboardHeightAtEnd = ((notification as NSNotification).userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height, propertyInput.isFirstResponder || textView.isFirstResponder, let duration = (notification as NSNotification).userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        let keyboardWillShow = notification.name == UIResponder.keyboardWillShowNotification
        
        bottomViewBottomConstraint.constant = keyboardWillShow ? keyboardHeightAtEnd - 6 : 0
        
        UIView.animate(withDuration: duration, animations: { self.view.layoutIfNeeded() })
    }
}

extension PropertiesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return keys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: .otherCell, for: indexPath) as! MELTableViewCell
        
        cell.textLabel?.text = keys[indexPath.row].rawValue
        cell.textLabel?.font = UIFont.font(ofWeight: .regular, size: 17)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let key = keys[indexPath.row]
        
        propertyInput.text = key.rawValue
        operation = key.preferredOperation
        keyType = key.preferredKeyType
//        searchBar(propertyInput, textDidChange: key.rawValue)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 50
    }
}

extension PropertiesViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        textView.text = value()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
    }
}

extension PropertiesViewController {
    
    @objc func value() -> String? {
        
        guard let entity = entity, let text = propertyInput.text else { return nil }
        
        switch keyType {
            
            case .property: return entity.value(forProperty: text).debugDescription
            
            case .selector: return entity.responds(to: NSSelectorFromString(text)) == true ? String(describing: entity.value(forKey: text) ?? "") : nil
        }
    }
}
