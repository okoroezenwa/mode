//
//  ItemsViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 31/03/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ItemsViewController: UIViewController {
    
    @IBOutlet var tableView: MELTableView!
    lazy var headerView: HeaderView = {
        
        let view = HeaderView.instance
//        self.actionsStackView = view.actionsStackView
//        self.stackView = view.scrollStackView
        view.showRecents = showRecentSongs
        view.collectionView.isHidden = true
//        view.sortButton.setTitle(arrangementLabelText, for: .normal)
//        view.sortButton.addTarget(self, action: #selector(showArranger), for: .touchUpInside)
//        self.collectionView = view.collectionView
        view.viewController = self
//        view.header.button.addTarget(self, action: #selector(backToStart), for: .touchUpInside)
//        view.header.altButton.addTarget(isInDebugMode ? self : self.tableDelegate, action: isInDebugMode ? #selector(backToStart) : #selector(tableDelegate.viewSections), for: .touchUpInside)
        
        return view
    }()

    override func viewDidLoad() {
        
        super.viewDidLoad()

        
    }
}
