//
//  LoginDetailsTableViewCell.swift
//  Mode
//
//  Created by Ezenwa Okoro on 22/07/2019.
//  Copyright © 2019 Ezenwa Okoro. All rights reserved.
//

import UIKit

class LoginDetailsTableViewCell: UITableViewCell {
    
    @IBOutlet var usernameField: MELTextField!
    @IBOutlet var passwordField: MELTextField!
    
    weak var delegate: LoginCellDelegate?
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        usernameField.delegate = self
        passwordField.delegate = self
    }
}

extension LoginDetailsTableViewCell: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == usernameField {
            
            passwordField.becomeFirstResponder()
            
        } else if textField == passwordField {
            
            delegate?.login(username: usernameField.text, password: passwordField.text)
            
            textField.resignFirstResponder()
        }
        
        return true
    }
}

protocol LoginCellDelegate: AnyObject {
    
    func login(username: String?, password: String?)
}
