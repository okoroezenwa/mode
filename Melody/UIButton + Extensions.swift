//
//  UIButton + Extensions.swift
//  Mode
//
//  Created by Ezenwa Okoro on 15/04/2019.
//  Copyright © 2019 Ezenwa Okoro. All rights reserved.
//

import UIKit

// MARK: - UIButton
extension UIButton {
    
    enum SelectionState { case selected, unselected }
    
    func update(for state: SelectionState, capitalised: Bool = true) {
        
        switch state {
            
            case .selected:
                
                setTitle(title(for: .normal)?.uppercased(), for: .normal)
                
                if let melButton = self as? MELButton {
                    
                    melButton.fontWeight = FontWeight.bold.rawValue
                    
                } else {
                    
                    titleLabel?.font = UIFont.font(ofWeight: .bold, size: titleLabel?.font.pointSize ?? 15)
                }
            
            case .unselected:
                
                let text = !capitalised ? title(for: .normal)?.lowercased() : title(for: .normal)?.capitalized
                
                setTitle(text, for: .normal)
                
                if let melButton = self as? MELButton {
                    
                    melButton.fontWeight = FontWeight.regular.rawValue
                    
                } else {
                    
                    titleLabel?.font = UIFont.font(ofWeight: .regular, size: titleLabel?.font.pointSize ?? 15)
                }
        }
    }
}

public class ClosureSelector<Parameter> {
    
    public let selector: Selector
    private let closure: (Parameter) -> ()
    
    init(closure: @escaping (Parameter) -> ()) {
        
        self.selector = #selector(ClosureSelector.target)
        self.closure = closure
    }
    
    // Unfortunately we need to cast to AnyObject here
    @objc func target(_ param: AnyObject) {
        
        guard let parameter = param as? Parameter else { return }
        
        closure(parameter)
    }
}

extension UIButton {
    
    func addAction(for events: UIControl.Event = .touchUpInside, _ closure: @escaping (UIButton) -> Void) {
        
        let closureSelector = ClosureSelector<UIButton>(closure: closure)
        var handle = 0
        objc_setAssociatedObject(self, &handle, closureSelector, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.addTarget(closureSelector, action: closureSelector.selector, for: events)
    }
}

extension UITapGestureRecognizer {
    
    static func new(_ closure: @escaping GestureRecogniserAction) -> UITapGestureRecognizer {
        
        let closureSelector = ClosureSelector<UITapGestureRecognizer>(closure: closure)
        var handle = 0
        objc_setAssociatedObject(self, &handle, closureSelector, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        return UITapGestureRecognizer.init(target: closureSelector, action: closureSelector.selector)
    }
}

extension UILongPressGestureRecognizer {
    
    static func new(_ closure: @escaping GestureRecogniserAction) -> UILongPressGestureRecognizer {
        
        let closureSelector = ClosureSelector<UILongPressGestureRecognizer>(closure: closure)
        var handle = 0
        objc_setAssociatedObject(self, &handle, closureSelector, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        return UILongPressGestureRecognizer.init(target: closureSelector, action: closureSelector.selector)
    }
}
