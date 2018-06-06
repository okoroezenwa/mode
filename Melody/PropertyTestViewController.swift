//
//  PropertyTestViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 21/04/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PropertyTestViewController: UIViewController {

    @IBOutlet weak var containsButton: MELButton!
    @IBOutlet weak var matchesButton: MELButton!
    @IBOutlet weak var beginsWithButton: MELButton!
    @IBOutlet weak var endsWithButton: MELButton!
    @IBOutlet weak var isOverButton: MELButton!
    @IBOutlet weak var isUnderButton: MELButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var filter: Filterable?
    weak var container: (FilterContainer & UIViewController)?
    
    var buttons: [MELButton] { return [containsButton, matchesButton, beginsWithButton, endsWithButton, isOverButton, isUnderButton] }
    
    override var modalPresentationStyle: UIModalPresentationStyle {
        
        get { return .popover }
        
        set { }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        preferredContentSize.height = 54

        if let filter = filter {
            
            buttons.forEach({
                
                $0.isHidden = !filter.filterTests.contains(test(for: $0))
                $0.setTitle(filter.title(for: test(for: $0), property: filter.filterProperty), for: .normal)
            })
            
            button(for: filter.propertyTest).isHidden = true
        }
        
        view.layoutIfNeeded()
        preferredContentSize.width = scrollView.contentSize.width
    }

    @IBAction func selectTest(_ sender: MELButton) {
        
        filter?.propertyTest = test(for: sender)
        container?.updateTestView()
        container?.requiredInputView?.pickerView.reloadAllComponents()
        dismiss(animated: true, completion: nil)
    }
    
    func test(for button: MELButton) -> PropertyTest {
        
        switch button {
            
            case containsButton: return .contains
            
            case matchesButton: return .isExactly
            
            case beginsWithButton: return .beginsWith
            
            case endsWithButton: return .endsWith
            
            case isOverButton: return .isOver
            
            case isUnderButton: return .isUnder
            
            default: fatalError("no other button should be present")
        }
    }
    
    func button(for test: PropertyTest) -> MELButton {
        
        switch test {
            
            case .contains: return containsButton
            
            case .isExactly: return matchesButton
            
            case .beginsWith: return beginsWithButton
            
            case .endsWith: return endsWithButton
            
            case .isOver: return isOverButton
            
            case .isUnder: return isUnderButton
        }
    }
}
