//
//  ArtworkTableViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 15/12/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ArtworkTableViewController: UITableViewController {
    
    @IBOutlet var cells: [UITableViewCell]!
    @IBOutlet var customImageView: MELImageView!
    @IBOutlet var squareImageView: MELImageView!
    @IBOutlet var slightlyRoundedImageView: MELImageView!
    @IBOutlet var prominentlyRoundedImageView: MELImageView!
    @IBOutlet var fullyRoundedImageView: MELImageView!
    @IBOutlet var listsLabel: MELLabel!
    @IBOutlet var widgetLabel: MELLabel!
    @IBOutlet var infoViewLabel: MELLabel!
    @IBOutlet var miniPlayerLabel: MELLabel!
    @IBOutlet var compactPlayerLabel: MELLabel!
    @IBOutlet var fullPlayerLabel: MELLabel!
    @IBOutlet var automaticLabel: MELLabel!
    @IBOutlet var animatableViews: [UIView]!
    
    enum RadiusSection: Int {
        
        case main, lists, widget, info, mini, compact, full
        
        var description: String {
            
            switch self {
                
                case .main: return ""
                
                case .lists: return "Lists"
                
                case .widget: return "Widget"
                
                case .info: return "Info View"
                
                case .mini: return "Mini Player"
                
                case .compact: return "Compact Player"
                
                case .full: return "Fullscreen Player"
            }
        }
    }
    
    var radiusSection = RadiusSection.main
    var preference: String {
        
        switch radiusSection {
            
            case .main: return .cornerRadius
            
            case .lists: return .listsCornerRadius
            
            case .widget: return .widgetCornerRadius
            
            case .info: return .infoCornerRadius
            
            case .mini: return .miniPlayerCornerRadius
            
            case .compact: return .compactCornerRadius
            
            case .full: return .fullScreenPlayerCornerRadius
        }
    }
    var relevantRadius: CornerRadius? {
        
        switch radiusSection {
            
            case .compact: return compactCornerRadius
            
            case .lists: return listsCornerRadius
            
            case .full: return fullPlayerCornerRadius

            case .widget: return widgetCornerRadius
            
            case .info: return infoCornerRadius
            
            case .main: return cornerRadius
            
            case .mini: return miniPlayerCornerRadius
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        cells.forEach({ $0.selectedBackgroundView = MELBorderView.init() })
        
        notifier.addObserver(self, selector: #selector(prepareComponents), name: .cornerRadiusChanged, object: nil)
        
        prepareComponents()
        
        tableView.scrollIndicatorInsets.bottom = 14
        
        if radiusSection != .main {
            
            (parent as? PresentedContainerViewController)?.titleLabel.text = radiusSection.description
            automaticLabel.text = CornerRadius.automatic.description
        }
    }
    
    @objc func prepareComponents() {
        
        prepareArtworkImageViews()
        prepareLabels()
    }

    @objc func prepareArtworkImageViews() {
        
        customImageView.isHidden = relevantRadius != .automatic
        squareImageView.isHidden = relevantRadius != .square
        slightlyRoundedImageView.isHidden = relevantRadius != .small
        prominentlyRoundedImageView.isHidden = relevantRadius != .large
        fullyRoundedImageView.isHidden = relevantRadius != .rounded
    }
    
    @objc func prepareLabels() {
    
        listsLabel.text = (listsCornerRadius ?? .automatic).description
        widgetLabel.text = (widgetCornerRadius ?? .small).description
        infoViewLabel.text = (infoCornerRadius ?? .automatic).description
        miniPlayerLabel.text = (miniPlayerCornerRadius ?? .square).description
        compactPlayerLabel.text = (compactCornerRadius ?? .rounded).description
        fullPlayerLabel.text = (fullPlayerCornerRadius ?? .small).description
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return radiusSection == .main ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return section == 0 ? 5 : 6
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as? UITableViewHeaderFooterView
        header?.textLabel?.text = nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.preservesSuperviewLayoutMargins = false
        cell.contentView.preservesSuperviewLayoutMargins = false
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
            
            case 0: return !Set([RadiusSection.main, .lists, .info]).contains(radiusSection) && indexPath.row == 0 ? 0 : 54
            
            case 1: return cornerRadius == .automatic ? 54 : 0
            
            default: return 54
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard radiusSection == .main else { return nil }
        
        let header = tableView.sectionHeader
        
        header?.label.text = {
            
            switch section {
                
                case 0: return "rounded corners"
                
                case 1: return "automatic options"
                
                default: return nil
            }
        }()
        
        header?.label.alpha = section == 0 || cornerRadius == .automatic ? 1 : 0
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        switch section {
            
            case 0: return radiusSection == .main ? .textHeaderHeight + 20 : .tableHeader + 10
            
            case 1: return cornerRadius == .automatic ? .textHeaderHeight + 8 : 0.00001
            
            default: return 0.00001
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            
            if relevantRadius?.rawValue != indexPath.row {
                
                prefs.set(indexPath.row, forKey: preference)
                
                if [RadiusSection.main, .widget].contains(radiusSection) {
                    
                    sharedDefaults.setValue(indexPath.row, forKey: preference)
                    sharedDefaults.synchronize()
                }
                
                notifier.post(name: .cornerRadiusChanged, object: nil)
                
                if radiusSection == .main {
                    
                    tableView.beginUpdates()
                    
                    UIView.animate(withDuration: 0.3, animations: {

                        (self.tableView.headerView(forSection: 1) as? TableHeaderView)?.label.alpha = cornerRadius == .automatic ? 1 : 0
                        self.animatableViews.forEach({ $0.alpha = cornerRadius == .automatic ? 1 : 0 })
                    })
                    
                    tableView.endUpdates()
                }
            }
            
            if radiusSection != .main {
                
                dismiss(animated: true, completion: nil)
                return
            }
        
        } else {
            
            guard let presentedVC = presentedStoryboard.instantiateViewController(withIdentifier: "presentedVC") as? PresentedContainerViewController, let section = RadiusSection(rawValue: indexPath.row + 1) else { return }
            
            presentedVC.context = .artwork
            presentedVC.artworkVC.radiusSection = section
            
            present(presentedVC, animated: true, completion: nil)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
