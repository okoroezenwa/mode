//
//  TipsTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 12/03/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class TipsTableViewController: UITableViewController {
    
    @IBOutlet var labels: [UILabel]!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        labels.forEach({
            
            if let text = $0.text {
                
                let style = NSMutableParagraphStyle.init()
                style.lineHeightMultiple = 1.5
                
                $0.attributedText = NSAttributedString.init(string: text, attributes: [.foregroundColor: Themer.textColour(for: .title), .paragraphStyle: style])
            }
        })
        
        tableView.scrollIndicatorInsets.bottom = 14
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 6
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 92
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        return false
    }
}
