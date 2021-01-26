//
//  LyricsInfoViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 08/08/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class LyricsInfoViewController: UIViewController, TableViewContaining {
    
    @IBOutlet var tableView: MELTableView!
    
    var nameTextField: MELTextField? {
        
        didSet {
            
            guard let textField = nameTextField, oldValue != textField else { return }
            
            textField.delegate = self
            notifier.addObserver(self, selector: #selector(updateText(_:)), name: UITextField.textDidChangeNotification, object: textField)
        }
    }
    var artistTextField: MELTextField? {
        
        didSet {
            
            guard let textField = artistTextField, oldValue != textField else { return }
            
            textField.delegate = self
            notifier.addObserver(self, selector: #selector(updateText(_:)), name: UITextField.textDidChangeNotification, object: textField)
        }
    }
    
    var hits = [Hit]()
    var manager: LyricsManager? {
        
        didSet {
            
            manager?.infoDetailer = self
        }
    }
    var currentObject = LyricsObject.init(id: 0, name: nil, artist: nil, titleTerm: nil, artistTerm: nil, source: nil)
    var originalObject: LyricsObject?
    var item: MPMediaItem?
    var operationActive = false {
        
        didSet {
            
            tableView.reloadRows(at: [.init(row: 0, section: 1)], with: .none)
        }
    }
    var currentHit: Hit? {
        
        didSet {
            
            guard currentHit != oldValue else { return }
            
            currentObject.url = currentHit?.result.url
            updateLyrics()
            tableView.reloadData()
        }
    }
    
    var editedLyrics: String?
    var hasChanges: Bool { return currentObject.titleTerm != originalObject?.titleTerm || currentObject.artistTerm != originalObject?.artistTerm || currentObject.lyrics != originalObject?.lyrics  }
    
    lazy var setting = Setting.init(title: "Refresh Results", accessoryType: .none, textAlignment: .center, borderVisibility: .both)

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.scrollIndicatorInsets.bottom = 14
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        tableView.flashScrollIndicators()
    }
    
    func updateLyrics() {
        
        manager?.detailerOperation?.cancel()
        manager?.detailerOperation = BlockOperation()
        manager?.detailerOperation?.addExecutionBlock({ [weak self] in
            
            guard let weakSelf = self else { return }
            
            weakSelf.manager?.getLyrics(for: weakSelf.item, with: weakSelf, operation: weakSelf.manager?.detailerOperation)
        })
        
        manager?.lyricsOperationQueue.addOperation((manager?.detailerOperation)!)
    }
    
    @objc func updateText(_ notification: Notification) {
        
        guard let textField = notification.object as? MELTextField else { return }
        
        if textField == nameTextField {
            
            currentObject.titleTerm = textField.text
            tableView.reloadRows(at: [.init(row: 0, section: 1)], with: .none)
        
        } else if textField == artistTextField {
            
            currentObject.artistTerm = textField.text
            tableView.reloadRows(at: [.init(row: 0, section: 1)], with: .none)
        }
    }
    
    func display(_ lyrics: String) {
        
        tableView.reloadRows(at: [.init(item: 0, section: 3)], with: .none)
    }
    
    func displayUnavailable(with message: LyricsManager.ErrorMessage) {
        
        tableView.reloadData()
    }
    
    func shouldColourRow(at indexPath: IndexPath) -> Bool {
        
        if let hit = currentHit {
            
            return hit == hits[indexPath.row]
            
        } else {
            
            return indexPath.row == 0
        }
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            let banner = UniversalMethods.banner(withTitle: "LIVC going away...")
            banner.titleLabel.font = .font(ofWeight: .light, size: 22)
            banner.show(for: 0.3)
        }
        
        manager?.detailerOperation?.cancel()
    }
}

extension LyricsInfoViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
            
            case 0: return 2
            
            case 1: return 1
            
            case 2: return max(hits.count, 1)
            
            default: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch (indexPath.section, indexPath.row) {
            
            case (2, _) where hits.isEmpty.inverted:
            
                let cell = tableView.settingCell(for: indexPath)
                
                let hit = hits[indexPath.row]
                let result = hit.result
                
                cell.titleLabel.attributes = nil
                cell.prepare(with: Setting.init(title: result.title, subtitle: result.artist.name, accessoryType: .none))
                cell.titleLabel.numberOfLines = 1
                cell.backgroundColor = shouldColourRow(at: indexPath) ? Themer.borderViewColor() : .clear
            
                return cell
            
            case (2, _) where hits.isEmpty:
            
                let cell = tableView.regularCell(for: indexPath)
                
                cell.emptyView.isHidden = false
                
                return cell
            
            case (0, 0), (0, 1):
            
                let cell = tableView.dequeueReusableCell(withIdentifier: "field", for: indexPath) as! TextFieldsTableViewCell
                
                cell.itemImageView.image = #imageLiteral(resourceName: indexPath.row == 0 ? "Songs" : "Artists20")
                cell.textField.placeholder = indexPath.row == 0 ? "song title" : "artist name"
                cell.textField.text = indexPath.row == 0 ? currentObject.titleTerm : currentObject.artistTerm
                
                if indexPath.row == 0 {
                    
                    nameTextField = cell.textField
                    
                } else {
                    
                    artistTextField = cell.textField
                }
            
                return cell
            
            case (1, _):
            
                let cell = tableView.settingCell(for: indexPath)
            
                cell.titleLabel.attributes = nil
                cell.prepare(with: setting)
                cell.titleLabel.numberOfLines = 1
                cell.backgroundColor = .clear
            
                return cell
            
            case (3, _):
                
                if let lyrics = editedLyrics ?? currentObject.lyrics, lyrics.isEmpty.inverted {
                    
                    let cell = tableView.settingCell(for: indexPath)
                    
                    cell.titleLabel.attributes = nil
                    cell.prepare(with: Setting.init(title: lyrics, accessoryType: .none))
                    cell.titleLabel.attributes = [.init(name: .paragraphStyle, value: .other(NSMutableParagraphStyle.withLineHeight(1.2)), range: lyrics.nsRange())]
                    cell.titleLabel.numberOfLines = 0
                    cell.backgroundColor = .clear
                    
                    return cell
                    
                } else {
                    
                    let cell = tableView.regularCell(for: indexPath)
                    
                    cell.emptyView.isHidden = false
                    
                    return cell
                }
            
            default: return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = {
            
            switch section {
                
                case 2: return "search results"
                
                case 0: return "search terms"
                
                case 3: return "lyrics"
                
                default: return nil
            }
        }()
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return section == 1 ? 0 : .textHeaderHeight + (section == 0 ? 12 : 0)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
            
            case 2: return 57
            
            case 0, 1: return 50
            
            case 3 where (editedLyrics ?? currentObject.lyrics)?.isEmpty == false: return UITableView.automaticDimension
            
            default: return 44
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
            
            case 2: return 57
            
            case 0, 1: return 50
            
            case 3 where (editedLyrics ?? currentObject.lyrics)?.isEmpty == false: return (editedLyrics as NSString? ?? currentObject.lyrics as NSString?)?.boundingRect(with: .init(width: screenWidth - 12 - 20, height: .greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin, .usesDeviceMetrics], attributes: [.font: UIFont.specificFont(from: activeFont, weight: .regular, size: TextStyle.body.textSize())], context: nil).height ?? 44
            
            default: return 44
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            
            currentHit = nil
            updateLyrics()
            
        } else if indexPath.section == 2 {
            
            currentHit = hits[indexPath.row]
        
        } else if indexPath.section == 3 {
            
            let editAction: () -> () = {
                
                guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController else { return }
                
                presentedVC.context = .lyricsEdit
                presentedVC.prompt = (self.item?.validTitle ?+ "  —  ") ?+ self.item?.validArtist
                presentedVC.textVC.updater = self
                presentedVC.textVC.object = self.currentObject
                
                self.present(presentedVC, animated: true, completion: nil)
            }
            
            if editedLyrics == nil {
                
                editAction()
                
            } else {
            
                let edit = AlertAction.init(title: "Edit", style: .default, requiresDismissalFirst: true, handler: editAction)
                
                let revert = AlertAction.init(title: "Revert", style: .destructive, requiresDismissalFirst: false, handler: {
                    
                    self.editedLyrics = nil
                    tableView.reloadRows(at: [indexPath], with: .none)
                })
                
                showAlert(title: nil, with: edit, revert)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        switch indexPath {
            
            case let x where x.section == 2 && hits.isEmpty.inverted,
                 let x where x.section == 3 && (editedLyrics ?? currentObject.lyrics)?.isEmpty == false,
                 let x where x.section == 1: return true
            
            default: return false
        }
    }
}

extension LyricsInfoViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == nameTextField {
            
            artistTextField?.becomeFirstResponder()
            
        } else if textField == artistTextField {
            
            textField.resignFirstResponder()
        }
        
        return true
    }
}

extension LyricsInfoViewController: LyricsUpdater {
    
    func updateLyrics(with object: LyricsObject) {
        
        editedLyrics = object.lyrics
        tableView.reloadRows(at: [.init(row: 0, section: 3)], with: .none)
    }
}
