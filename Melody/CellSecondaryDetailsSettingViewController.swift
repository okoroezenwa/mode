//
//  CellSecondaryDetailsSettingViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 05/05/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class CellSecondaryDetailsSettingViewController: UIViewController {

    @IBOutlet var tableView: MELTableView!
    
    let array = [SecondaryCategory.loved, .plays, .lastPlayed, .rating, .genre, .dateAdded, .year, .fileSize]
    var secondaryArray = songSecondaryDetails ?? []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        tableView.rowHeight = 54
        tableView.tableFooterView = UIView.init(frame: .zero)
        tableView.scrollIndicatorInsets.bottom = 14
    }
    
    deinit {
        
//        prefs.set(secondaryArray.map({ $0.rawValue }).sorted(by: <), forKey: .songCellCategories)
//        notifier.post(name: .songCellCategoriesChanged, object: nil)
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "CSIVC going away...").show(for: 0.5)
        }
    }
}

extension CellSecondaryDetailsSettingViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongDetailsTableViewCell
        
        let detail = array[indexPath.row]
        cell.prepare(for: detail, visible: secondaryArray.contains(detail))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        let detail = array[indexPath.row]
        
        if let index = secondaryArray.index(of: detail) {
            
            secondaryArray.remove(at: index)
            
        } else {
            
            secondaryArray.append(detail)
        }
        
        prefs.set(secondaryArray.map({ $0.rawValue }).sorted(by: <), forKey: .songCellCategories)
        notifier.post(name: .songCellCategoriesChanged, object: nil)
        tableView.reloadRows(at: [indexPath], with: .none)
        
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = tableView.sectionHeader
        
        if section == 0 {
            
            view?.label.text = "songs"
        }
        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return .textHeaderHeight + 20
    }
}
