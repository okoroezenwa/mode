//
//  MELTableViewCell.swift
//  Melody
//
//  Created by Ezenwa Okoro on 27/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class MELTableViewCell: UITableViewCell {
    
    lazy var emptyView: MELBorderView = {
        
        let view = MELBorderView.init(frame: .zero)
        view.layer.cornerRadius = 2
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.constrainDimensions(toWidth: 120, height: 4)
        addSubview(view)
        self.centre(view)
        
        return view
    }()

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        backgroundColor = .clear
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        
        changeThemeColor()
        
        notifier.addObserver(self, selector: #selector(changeThemeColor), name: .themeChanged, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    @objc func changeThemeColor() {
        
        tintColor = darkTheme ? .white : .black
        textLabel?.textColor = Themer.textColour(for: .title)
        imageView?.tintColor = darkTheme ? .white : .black
    }
}
