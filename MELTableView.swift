//
//  MELTableView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 27/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELTableView: UITableView {
    
    @objc var header = false { didSet { register(UINib.init(nibName: .sectionHeader, bundle: nil), forHeaderFooterViewReuseIdentifier: .sectionHeader) } }
    
    @objc var footer = false { didSet { register(UINib.init(nibName: .sectionFooter, bundle: nil), forHeaderFooterViewReuseIdentifier: .sectionFooter) } }
    
    @objc var song = false { didSet { register(UINib.init(nibName: .songCell, bundle: nil), forCellReuseIdentifier: .songCell) } }
    
    @objc var artist = false { didSet { register(UINib.init(nibName: .artistCell, bundle: nil), forCellReuseIdentifier: .artistCell) } }
    
    @objc var album = false { didSet { register(UINib.init(nibName: .albumCell, bundle: nil), forCellReuseIdentifier: .albumCell) } }
    
    @objc var playlist = false { didSet { register(UINib.init(nibName: .playlistCell, bundle: nil), forCellReuseIdentifier: .playlistCell) } }
    
    @objc var regular = false { didSet { register(MELTableViewCell.self, forCellReuseIdentifier: .otherCell) } }
    
    @objc var settings = false { didSet { register(UINib.init(nibName: .settingsCell, bundle: nil), forCellReuseIdentifier: .settingsCell) } }
    
    @objc var login = false { didSet { register(UINib.init(nibName: .loginCell, bundle: nil), forCellReuseIdentifier: .loginCell) } }

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        sectionIndexBackgroundColor = .clear
        sectionIndexMinimumDisplayRowCount = Int.max
        keyboardDismissMode = .onDrag
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    @objc func changeThemeColor() {
        
        tintColor = darkTheme ? .white : .black
        separatorColor = (darkTheme ? UIColor.white : .black).withAlphaComponent(0.08)
        sectionIndexTrackingBackgroundColor = (darkTheme ? .white : UIColor.black).withAlphaComponent(0.05)
        indicatorStyle = darkTheme ? .white : .black
    }
}
