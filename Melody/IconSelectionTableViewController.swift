//
//  IconSelectionTableViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 31/01/2018.
//  Copyright © 2018 Ezenwa Okoro. All rights reserved.
//

import UIKit

class IconSelectionTableViewController: UITableViewController {

    @IBOutlet weak var thinImageView: MELImageView!
    @IBOutlet weak var mediumImageView: MELImageView!
    @IBOutlet weak var wideImageView: MELImageView!
    @IBOutlet weak var darkImageView: MELImageView!
    @IBOutlet weak var lightImageView: MELImageView!
    @IBOutlet weak var matchImageView: MELImageView!
    @IBOutlet var cells: [UITableViewCell]!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        cells.forEach({ $0.selectedBackgroundView = MELBorderView.init() })
        tableView.scrollIndicatorInsets.bottom = 14
        
        prepareWidthImageViews()
        prepareThemeImageViews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareWidthImageViews() {
        
        thinImageView.isHidden = iconLineWidth != .thin
        mediumImageView.isHidden = iconLineWidth != .medium
        wideImageView.isHidden = iconLineWidth != .wide
    }
    
    func prepareThemeImageViews() {
        
        darkImageView.isHidden = iconTheme != .dark
        lightImageView.isHidden = iconTheme != .light
        matchImageView.isHidden = iconTheme != .match
    }
    
    func updateIconIfNeeded() {
        
        let icon = Icon.iconName(width: iconLineWidth, theme: iconTheme)
        
        guard #available(iOS 10.3, *), UIApplication.shared.supportsAlternateIcons, (icon.rawValue.isEmpty ? nil : icon.rawValue) != UIApplication.shared.alternateIconName else { return }
        
        UIApplication.shared.setAlternateIconName(icon.rawValue.isEmpty ? nil : icon.rawValue, completionHandler: { _ in })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 3
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 ? indexPath.row != iconLineWidth.rawValue : indexPath.row != iconTheme.rawValue {
            
            if indexPath.section == 0 {
                
                prefs.set(indexPath.row, forKey: .iconLineWidth)
                prepareWidthImageViews()
                
            } else {
                
                prefs.set(indexPath.row, forKey: .iconTheme)
                prepareThemeImageViews()
            }
            
            updateIconIfNeeded()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.preservesSuperviewLayoutMargins = false
        cell.contentView.preservesSuperviewLayoutMargins = false
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.sectionHeader
        
        header?.label.text = {
            
            switch section {
                
                case 0: return "line width"
                
                case 1: return "theme"
                
                default: return nil
            }
        }()
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        switch section {
            
            case 0: return .textHeaderHeight + 20
            
            case 1: return .textHeaderHeight + 8
            
            default: return 0.00001
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.00001
    }
}
