//
//  ThemeViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 19/07/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ThemeViewController: UIViewController {

    @IBOutlet weak var bottomViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var pickerView: UIPickerView!
    
    lazy var twelveHourTimes = Array(1...12)
    lazy var twentyFourHourTimes = Array(0...23)
    var minutes = Array(0...59)
    lazy var meridianPeriods = ["am", "pm"]
    var currentConstraint: TimeConstraint?
    
    enum TimeConstraint { case from, to }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        updatePickerView(animated: false)
    }
    
    func updateBottomView(to state: VisibilityState, components: TimeConstraintComponents?, constraint: TimeConstraint? = nil) {
        
        let details: (constant: CGFloat, alpha: CGFloat) = {
            
            switch state {
                
                case .hidden: return (-216, 0)
                
                case .visible: return (0, 1)
            }
        }()
        
        bottomViewBottomConstraint.constant = details.constant
        
        UIView.animate(withDuration: 0.3, animations: {
        
            self.bottomView.alpha = details.alpha
            self.view.layoutIfNeeded()
        })
        
        updatePickerView(with: components ?? Settings.components(from: .init()), animated: true, constraint: constraint)
    }
    
    func updatePickerView(with components: TimeConstraintComponents = Settings.components(from: .init()), animated: Bool, constraint: TimeConstraint? = nil) {
        
        pickerView.selectRow(components.hour + (twentyFourHourTimes.count * 100), inComponent: 0, animated: animated)
        pickerView.selectRow(components.minute + (minutes.count * 50), inComponent: 1, animated: animated)
        
        currentConstraint = constraint
    }
}

extension ThemeViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        switch component {
            
            case 0: return twentyFourHourTimes.count * 200
            
            case 1: return minutes.count * 100
            
            default: return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let label = view as? MELLabel ?? MELLabel.init(fontWeight: .regular, fontSize: 25, alignment: .center)
        
        label.text = values(forRow: row, inComponent: component).string
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        
        return 36
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        
        return 50
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        guard let currentConstraint = currentConstraint, let vc = children.first as? ThemeTableViewController, currentConstraint == vc.constraint(for: vc.selectedButton) else { return }
        
        let selectedHour = pickerView.selectedRow(inComponent: 0)
        let selectedMinute = pickerView.selectedRow(inComponent: 1)
        let hour = values(forRow: selectedHour, inComponent: 0).number
        let minute = values(forRow: selectedMinute, inComponent: 1).number
        
        switch currentConstraint {
            
            case .from:
                
                guard !(hour == toHourComponent && minute == toMinuteComponent) else {
                    
                    let minuteToScrollTo = selectedMinute == 0 ? 59 + (minutes.count * 50) : selectedMinute - 1
                    
                    pickerView.selectRow(minuteToScrollTo, inComponent: 1, animated: true)
                    
                    if selectedHour % twentyFourHourTimes.count == 0 && selectedMinute % minutes.count == 0 {
                        
                        let hourToScrollTo = 23 + (twentyFourHourTimes.count * 100)
                        
                        pickerView.selectRow(hourToScrollTo, inComponent: 0, animated: true)
                    }
                    
                    self.pickerView(pickerView, didSelectRow: minuteToScrollTo, inComponent: 1)
                    
                    return
                }
            
                prefs.set(hour, forKey: .fromHourComponent)
                prefs.set(minute, forKey: .fromMinuteComponent)
                notifier.post(name: .fromTimeConstraintChanged, object: nil)
            
            case .to:
                
                let minuteToScrollTo = selectedMinute == minutes.endIndex - 1 ? 0 + (minutes.count * 50) : selectedMinute + 1
                
                guard !(hour == fromHourComponent && minute == fromMinuteComponent) else {
                    
                    if selectedHour % twentyFourHourTimes.count == 23 && selectedMinute % minutes.count == 59 {
                        
                        let hourToScrollTo = 0 + (twentyFourHourTimes.count * 100)
                        
                        pickerView.selectRow(hourToScrollTo, inComponent: 0, animated: true)
                    }
                    
                    pickerView.selectRow(minuteToScrollTo, inComponent: 1, animated: true)
                    self.pickerView(pickerView, didSelectRow: minuteToScrollTo, inComponent: 1)
                    
                    return
                }
            
                prefs.set(hour, forKey: .toHourComponent)
                prefs.set(minute, forKey: .toMinuteComponent)
                notifier.post(name: .toTimeConstraintChanged, object: nil)
        }
    }
    
    func values(forRow row: Int, inComponent component: Int) -> (number: Int, string: String) {
        
        switch component {
            
            case 0:
                
                let hour = twentyFourHourTimes[row % twentyFourHourTimes.count]
                
                return (hour, (hour < 10 ? "0" : "") + String(hour))
            
            case 1:
                
                let minute = minutes[row % minutes.count]
                
                return (minute, (minute < 10 ? "0" : "") + String(minute))
            
            default: return (0, "")
        }
    }
}
