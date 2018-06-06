//
//  ThemeTableViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 18/07/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ThemeTableViewController: UITableViewController {

    @IBOutlet weak var nightSwitch: MELSwitch! {
        
        didSet {
            
            nightSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleNightMode()
            }
        }
    }
    @IBOutlet weak var timeSwitch: MELSwitch! {
        
        didSet {
            
            timeSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleTimeConstraint()
            }
        }
    }
    @IBOutlet weak var brightnessSwitch: MELSwitch! {
        
        didSet {
            
            brightnessSwitch.action = { [weak self] in
                
                guard let weakSelf = self else { return }
                
                weakSelf.toggleBrightnessConstraint()
            }
        }
    }
    @IBOutlet weak var anyImageView: MELImageView!
    @IBOutlet weak var allImageView: MELImageView!
    @IBOutlet weak var brightnessSlider: MELSlider!
    @IBOutlet weak var fromButton: MELButton!
    @IBOutlet weak var fromBorderView: MELBorderView!
    @IBOutlet weak var toButton: MELButton!
    @IBOutlet weak var toBorderView: MELBorderView!
    @IBOutlet weak var lowerTimeDescriptionButton: MELButton!
    @IBOutlet weak var higherTimeDescriptionButton: MELButton!
    @IBOutlet var cells: [UITableViewCell]!
    
    lazy var previousBrightnessValue = UIScreen.main.brightness
    lazy var newBrightness = UIScreen.main.brightness
    lazy var frozenBrightness: CGFloat = 0
    var selectedButton: UIButton?
    var timer: Timer?
    lazy var shouldHidePickerView = true
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        cells.forEach({ $0.selectedBackgroundView = MELBorderView.init() })
        
        prepareSwitches(animated: false)
        prepareConditionImageViews()
        prepareButton(constraint: .from)
        prepareButton(constraint: .to)
        tableView.scrollIndicatorInsets.bottom = 14
        
        brightnessSlider.value = brightnessValue
        
        [Notification.Name.toTimeConstraintChanged, .fromTimeConstraintChanged].forEach({ notifier.addObserver(self, selector: #selector(updateButtons(with:)), name: $0, object: nil) })
        notifier.addObserver(self, selector: #selector(updateBrightness), name: .UIScreenBrightnessDidChange, object: UIScreen.main)
        notifier.addObserver(self, selector: #selector(updateNightToggle), name: .themeChanged, object: nil)
    }
    
    @objc func updateButtons(with notification: Notification) {
        
        prepareButton(constraint: notification.name == .fromTimeConstraintChanged ? .from : .to)
    }
    
    @objc func updateBrightness() {
        
        guard !disregardBrightnessNotification else { return }
        
        previousBrightnessValue = UIScreen.main.brightness
    }
    
    @objc func updateNightToggle() {
        
        nightSwitch.setOn(darkTheme, animated: true)
        
        let footer = tableView.footerView(forSection: 0) as? TableFooterView
        let footerText = manualNightMode ? "Manually enabled." : nil
        
        if let text = footerText {
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.5
            
            footer?.label.text = text
            footer?.label.attributes = [.init(name: .paragraphStyle, value: .other(paragraphStyle), range: text.nsRange())]
            
        } else {
            
            footer?.label.text = nil
            footer?.label.attributes = nil
        }
    }
    
    func prepareButton(constraint: ThemeViewController.TimeConstraint) {
        
        switch constraint {
            
            case .from:
                
                let fromText = [fromHourComponent, fromMinuteComponent].map({ ($0 < 10 ? "0" : "") + String($0) }).joined(separator: ":")
            
                fromButton.setTitle(fromText, for: .normal)
            
            case .to:
            
                let toText = [toHourComponent, toMinuteComponent].map({ ($0 < 10 ? "0" : "") + String($0) }).joined(separator: ":")
                
                toButton.setTitle(toText, for: .normal)
        }
    }
    
    func prepareSwitches(animated: Bool) {
        
        nightSwitch.setOn(darkTheme, animated: animated)
        timeSwitch.setOn(timeConstraintEnabled, animated: animated)
        brightnessSwitch.setOn(brightnessConstraintEnabled, animated: animated)
    }
    
    func prepareConditionImageViews() {
        
        allImageView.isHidden = anyConditionActive
        anyImageView.isHidden = !anyConditionActive
    }
    
    func updateButtonViews(using button: UIButton?) {
        
        if button != nil, let secondView = borderView(for: button), let view = [fromBorderView, toBorderView].first(where: { $0 != secondView }), let firstView = view {
            
            UIView.transition(from: firstView, to: secondView, duration: 0.3, options: [.transitionCrossDissolve, .showHideTransitionViews], completion: { _ in self.tableView.scrollToRow(at: .init(row: 2, section: 1), at: .none, animated: true) })
            
        } else if let view = borderView(for: selectedButton) {
            
            UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: { view.isHidden = self.selectedButton != nil }, completion: { _ in
                
                if let _ = button {
                    
                    self.tableView.scrollToRow(at: .init(row: 2, section: 1), at: .none, animated: true)
                }
            })
        }
        
        selectedButton = button
        
        (parent as? ThemeViewController)?.updateBottomView(to: button == nil ? .hidden : .visible, components: components(for: button), constraint: constraint(for: button))
    }
    
    @IBAction func toggleNightMode() {
        
        prefs.set(!darkTheme, forKey: .manualNightMode)
        prefs.set(!darkTheme, forKey: .darkTheme)
        
        let icon = Icon.iconName(width: iconLineWidth, theme: iconTheme).rawValue.nilIfEmpty
        
        if #available(iOS 10.3, *), UIApplication.shared.supportsAlternateIcons, iconTheme == .match, icon != UIApplication.shared.alternateIconName {
            
            UniversalMethods.performOnMainThread({
                
                UIApplication.shared.setAlternateIconName(icon, completionHandler: { _ in })
                
            }, afterDelay: 0.2)
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
        
        if let view = appDelegate.window?.rootViewController?.view {
            
            UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: { notifier.post(name: .themeChanged, object: nil) }, completion: nil)
        }
    }
    
    @IBAction func toggleBrightnessConstraint() {
        
        prefs.set(!brightnessConstraintEnabled, forKey: .darkBrightnessConstraintEnabled)
        notifier.post(name: .brightnessConstraintChanged, object: nil)

        tableView.beginUpdates()
        
        (tableView.headerView(forSection: 2) as? TableHeaderView)?.label.text = !timeConstraintEnabled || !brightnessConstraintEnabled ? nil : "criteria"
        
        UIView.animate(withDuration: 0.3, animations: { (self.tableView.headerView(forSection: 2) as? TableHeaderView)?.alpha = !timeConstraintEnabled || !brightnessConstraintEnabled ? 0 : 1 })
        
        tableView.endUpdates()
    }
    
    @IBAction func toggleTimeConstraint() {
        
        prefs.set(!timeConstraintEnabled, forKey: .darkTimeConstraintEnabled)
        notifier.post(name: .timeConstraintChanged, object: nil)
        
        tableView.beginUpdates()
        
        (tableView.headerView(forSection: 2) as? TableHeaderView)?.label.text = !timeConstraintEnabled || !brightnessConstraintEnabled ? nil : "criteria"
        
        UIView.animate(withDuration: 0.3, animations: { (self.tableView.headerView(forSection: 2) as? TableHeaderView)?.alpha = !timeConstraintEnabled || !brightnessConstraintEnabled ? 0 : 1 })
        
        tableView.endUpdates()
        
        updateButtonViews(using: nil)
        (parent as? ThemeViewController)?.updateBottomView(to: .hidden, components: nil)
        selectedButton = nil
    }
    
    @IBAction func invalidate() {
        
        timer?.invalidate()
    }
    
    @IBAction func changeBrightness(_ sender: UISlider) {
        
        if !disregardBrightnessNotification {
            
            disregardBrightnessNotification = true
        }
        
        UIScreen.main.brightness = CGFloat(sender.value)
    }
    
    @IBAction func setBrightnessValue(_ sender: UISlider) {
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [.autoreverse, .repeat], animations: {
            
            UIView.setAnimationRepeatCount(1.5)
            self.brightnessSlider.alpha = 0
        
        }, completion: { _ in
            
            UIView.animate(withDuration: 0.2, animations: { self.brightnessSlider.alpha = 1 }, completion: { finished in
                
                guard finished else { return }
                
                prefs.set(sender.value, forKey: .brightnessValue)
                notifier.post(name: .brightnessValueChanged, object: nil, userInfo: ["brightness": self.previousBrightnessValue])
                disregardBrightnessNotification = false
                
                self.newBrightness = UIScreen.main.brightness
                
                self.timer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(self.animateBrightnessChange(with:)), userInfo: nil, repeats: true)
            })
        })
    }
    
    @IBAction func selectTime(_ sender: UIButton) {
        
        if selectedButton == nil || selectedButton != sender {
            
            updateButtonViews(using: sender)
            
        } else {
            
            updateButtonViews(using: nil)
        }
    }
    
    @objc func animateBrightnessChange(with timer: Timer) {
        
        if ((newBrightness > previousBrightnessValue) && UIScreen.main.brightness <= previousBrightnessValue) || ((newBrightness < previousBrightnessValue) && UIScreen.main.brightness >= previousBrightnessValue) {
            
            timer.invalidate()
            
            return
        }
        
        let change = CGFloat(timer.timeInterval) * (previousBrightnessValue - newBrightness)
        
        UIScreen.main.brightness += change
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return isInDebugMode ? 3 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
            
            case 0: return 1
            
            case 1: return 4
            
            default: return 2
        }
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
        
        switch section {
            
            case 0: return .tableHeader + 10
            
            case 2 where !timeConstraintEnabled || !brightnessConstraintEnabled: return 0.00001
            
            default: return .textHeaderHeight
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
            
            case 1 where (indexPath.row == 1 && !timeConstraintEnabled) || (indexPath.row == 3 && !brightnessConstraintEnabled),
                 2 where (!timeConstraintEnabled || !brightnessConstraintEnabled): return 0
            
            default: return 54
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = tableView.sectionHeader
        
        view?.label.text = {
            
            switch section {
                
                case 1: return "schedule"
                
                case 2: return !timeConstraintEnabled || !brightnessConstraintEnabled ? nil : "criteria"
                
                default: return nil
            }
        }()
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footer = tableView.sectionFooter
        
        var footerText: String? {
            
            switch section {
                
                case 0 where manualNightMode: return "Manually enabled."
                    
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
        
        return manualNightMode && section == 0 ? 48 : 18
    }
    
//    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
//        
//        return 50
//    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        
        return Set([2]).contains(indexPath.section)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 2 && ((indexPath.row == 0 && !anyConditionActive) || (indexPath.row == 1 && anyConditionActive)) {
            
            prefs.set(!anyConditionActive, forKey: .darkAnyConditionActive)
            prepareConditionImageViews()
            notifier.post(name: .anyConditionChanged, object: nil)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ThemeTableViewController {
    
    func components(for button: UIButton?) -> TimeConstraintComponents? {
        
        switch button {
            
            case .some(fromButton): return (fromHourComponent, fromMinuteComponent)
                
            case .some(toButton): return (toHourComponent, toMinuteComponent)
                
            default: return nil
        }
    }
    
    func constraint(for button: UIButton?) -> ThemeViewController.TimeConstraint? {
        
        switch button {
            
            case .some(fromButton): return .from
            
            case .some(toButton): return .to
            
            default: return nil
        }
    }
    
    func borderView(for button: UIButton?) -> UIView? {
        
        switch button {
            
            case .some(fromButton): return fromBorderView
                
            case .some(toButton): return toBorderView
                
            default: return nil
        }
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if scrollView == tableView, selectedButton != nil {
            
            updateButtonViews(using: nil)
        }
    }
}
