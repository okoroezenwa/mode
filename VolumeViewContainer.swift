//
//  VolumeView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 17/07/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit
import AVKit

class VolumeView: UIView {

    @IBOutlet var sliderVolumeViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var sliderVolumeViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var sliderVolumeView: MELVolumeView!
    @IBOutlet var routeAlternateButton: MELButton!
    @IBOutlet var routeButtonVolumeView: MELVolumeView!
    @IBOutlet var routeButtonVolumeViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var avRoutePickerViewContainer: UIView!
    @IBOutlet var avRoutePickerViewContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet var avRoutePickerViewContainerTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var avRoutePickerViewContainerLeadingConstraint: NSLayoutConstraint!
    
    var leadingConstraint: CGFloat = 0 {
        
        didSet {
            
            updateViews(self)
        }
    }
    var count = 3
    var pickerView: Any?
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 11, *) {
            
            notifier.addObserver(self, selector: #selector(updatePickerView), name: .themeChanged, object: nil)
            
        } else {
            
            notifier.addObserver(self, selector: #selector(updateViews(_:)), name: .MPVolumeViewWirelessRoutesAvailableDidChange, object: nil)
        }
    }
    
    @objc func updateViews(_ sender: Any) {
        
        let animated = sender is Notification && count < 1
        
        sliderVolumeViewLeadingConstraint.constant = leadingConstraint
        
        if #available(iOS 11, *), !routeButtonVolumeView.areWirelessRoutesAvailable, !routeButtonVolumeView.responds(to: NSSelectorFromString("_displayAudioRoutePicker")) {
            
            sliderVolumeViewTrailingConstraint.constant = 0
            routeButtonVolumeViewWidthConstraint.priority = UILayoutPriority(rawValue: 999)
            routeButtonVolumeView.isHidden = true
            routeAlternateButton.isHidden = true
            
            if self.pickerView == nil {
                
                let pickerView = AVRoutePickerView()
                pickerView.translatesAutoresizingMaskIntoConstraints = false
                pickerView.tintColor = Themer.tempActiveColours
                self.pickerView = pickerView
                
                avRoutePickerViewContainer.fill(with: pickerView)
            }
            
            avRoutePickerViewContainerLeadingConstraint.constant = -8
            avRoutePickerViewContainerTrailingConstraint.constant = 18
            
        } else {
            
            if routeButtonVolumeView.responds(to: NSSelectorFromString("_displayAudioRoutePicker")) {
                
                sliderVolumeViewTrailingConstraint.constant = 0
                routeButtonVolumeViewWidthConstraint.priority = UILayoutPriority(rawValue: 250)
                routeButtonVolumeView.isHidden = true
                routeAlternateButton.isHidden = false
                
            } else if routeButtonVolumeView.areWirelessRoutesAvailable {
                
                sliderVolumeViewTrailingConstraint.constant = 0
                routeButtonVolumeViewWidthConstraint.priority = UILayoutPriority(rawValue: 250)
                routeButtonVolumeView.isHidden = false
                routeAlternateButton.isHidden = true
                
            } else {
                
                sliderVolumeViewTrailingConstraint.constant = leadingConstraint
                routeButtonVolumeViewWidthConstraint.priority = UILayoutPriority(rawValue: 999)
                routeButtonVolumeView.isHidden = true
                routeAlternateButton.isHidden = true
            }
            
            avRoutePickerViewContainerWidthConstraint.priority = .init(999)
            avRoutePickerViewContainer.isHidden = true
            avRoutePickerViewContainerLeadingConstraint.constant = 0
            avRoutePickerViewContainerTrailingConstraint.constant = 0
        }
        
        if count > 0 {
            
            count -= 1
        }
        
        if animated {
            
            UIView.animate(withDuration: 0.3, animations: { self.superview?.layoutIfNeeded() })
        }
    }
    
    @objc func updatePickerView() {
        
        guard #available(iOS 11, *), let pickerView = pickerView as? AVRoutePickerView else { return }
        
        pickerView.tintColor = Themer.tempActiveColours
    }
    
    @IBAction func showSources() {
        
        guard routeButtonVolumeView.responds(to: NSSelectorFromString("_displayAudioRoutePicker")) else { return }
        
        routeButtonVolumeView.perform(NSSelectorFromString("_displayAudioRoutePicker"))
    }
    
    class func instance(leadingWith leadingConstraint: CGFloat) -> VolumeView {
        
        let volumeView = Bundle.main.loadNibNamed("VolumeView", owner: nil, options: nil)?.first as! VolumeView
        
        volumeView.leadingConstraint = leadingConstraint
        
        return volumeView
    }
}
