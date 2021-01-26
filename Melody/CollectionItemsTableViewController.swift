//
//  CollectionItemsTableViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 09/10/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class CollectionItemsTableViewController: UITableViewController, InfoLoading {
    
    enum Collection: String, CaseIterable {
        
        case aList = "A List"
        case bList = "B List"
        case cList = "C List"
        case languageList = "Language List"
        case choppingBlock = "Chopping Block"
        
        var index: Int {
            
            switch self {
                
                case .aList: return 0
                    
                case .bList: return 1
                    
                case .cList: return 2
                    
                case .languageList: return 3
                    
                case .choppingBlock: return 4
            }
        }
        
        var array: [MPMediaEntityPersistentID] {
            
            get {
                
                switch self {
                    
                    case .aList: return Mode.aList
                        
                    case .bList: return Mode.bList
                        
                    case .cList: return Mode.cList
                        
                    case .languageList: return Mode.languageList
                        
                    case .choppingBlock: return Mode.choppingBlock
                }
            }
            
            set {
                
                switch self {
                    
                    case .aList: return Mode.aList = newValue
                        
                    case .bList: return Mode.bList = newValue
                        
                    case .cList: return Mode.cList = newValue
                        
                    case .languageList: Mode.languageList = newValue
                        
                    case .choppingBlock: Mode.choppingBlock = newValue
                }
            }
        }
    }
    
    @objc var operations = ImageOperations()
    @objc var infoOperations = InfoOperations()
    @objc let infoCache: InfoCache = {
        
        let cache = InfoCache()
        cache.name = "Info Cache"
        cache.countLimit = 2500
        
        return cache
    }()
    @objc let imageOperationQueue: OperationQueue = {
        
        let queue = OperationQueue()
        queue.name = "Image Operation Queue"
        
        return queue
    }()
    @objc let imageCache: ImageCache = {
        
        let cache = ImageCache()
        cache.name = "Image Cache"
        cache.countLimit = 500
        
        return cache
    }()
    
    var collection = Collection.aList

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.register(.init(nibName: "EntityCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.rowHeight = FontManager.shared.entityCellHeight
    }
    
    func clearCollection() {
        
        let alert = AlertAction.init(title: "Clear All", style: .destructive, requiresDismissalFirst: true, handler: { [weak self] in
            
            self?.collection.array = []
            UniversalMethods.banner(withTitle: "Collection Cleared").show(for: 1)
            self?.dismiss(animated: true, completion: nil)
        })
        
        showAlert(title: nil, with: alert)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        collection.array.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.songCell(for: indexPath)
        
        if let song = MPMediaQuery.for(.song, using: collection.array[indexPath.row]).itemsAccessed(at: .all).items?.first {
        
            cell.prepare(with: song, songNumber: indexPath.row + 1, hideOptionsView: true)
            updateImageView(using: song, in: cell, indexPath: indexPath, reusableView: tableView)
            
            cell.supplementaryCollectionView.isHidden = true
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        guard editingStyle == .delete else { return }
        
        collection.array.remove(at: indexPath.row)
        tableView.reloadData()
    }
}
