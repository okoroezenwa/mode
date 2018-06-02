//
//  GesturesTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 18/07/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class GesturesTableViewController: UITableViewController {
    
    @IBOutlet weak var shortImageView: MELImageView!
    @IBOutlet weak var mediumImageView: MELImageView!
    @IBOutlet weak var longImageView: MELImageView!
    @IBOutlet var cells: [UITableViewCell]!

    override func viewDidLoad() {
        
        super.viewDidLoad()

        cells.forEach({ $0.selectedBackgroundView = MELBorderView.init() })
        
        updateImageViews()
        
        tableView.scrollIndicatorInsets.bottom = 14
        
        notifier.addObserver(self, selector: #selector(updateImageViews), name: .longPressDurationChanged, object: nil)
    }
    
    @objc func updateImageViews() {
        
        if let duration = GestureDuration(rawValue: longPressDuration) {
            
            let imageView: MELImageView = {
                
                switch duration {
                    
                    case .short: return shortImageView
                    
                    case .medium: return mediumImageView
                    
                    case .long: return longImageView
                }
            }()
            
            for view in [shortImageView, mediumImageView, longImageView] {
                
                view?.isHidden = view != imageView
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 3
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.preservesSuperviewLayoutMargins = false
        cell.contentView.preservesSuperviewLayoutMargins = false
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        
        let footer = view as? UITableViewHeaderFooterView
        footer?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return .textHeaderHeight + 20
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = tableView.sectionHeader
        
        view?.label.text = "duration"
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footer = tableView.sectionFooter
        
        var footerText: String? {
            
            switch section {
                
                case 0: return "Applies to hold gestures."
                    
                default: return nil
            }
        }
        
        if let text = footerText {
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.5
            
            footer?.label.text = text
            footer?.label.attributes = [.init(name: .paragraphStyle, value: .other(paragraphStyle), range: text.nsRange())]
            
        } else {
            
            footer?.label.text = nil
            footer?.label.attributes = nil
        }
        
        return footer
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        
        return 50
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            
            if indexPath.row == 0 && longPressDuration != GestureDuration.short.rawValue {
                
                prefs.set(GestureDuration.short.rawValue, forKey: .longPressDuration)
                notifier.post(name: .longPressDurationChanged, object: nil)
            
            } else if indexPath.row == 1 && longPressDuration != GestureDuration.medium.rawValue {
                
                prefs.set(GestureDuration.medium.rawValue, forKey: .longPressDuration)
                notifier.post(name: .longPressDurationChanged, object: nil)
                
            } else if indexPath.row == 2 && longPressDuration != GestureDuration.long.rawValue {
                
                prefs.set(GestureDuration.long.rawValue, forKey: .longPressDuration)
                notifier.post(name: .longPressDurationChanged, object: nil)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
