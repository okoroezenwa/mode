//
//  PassthroughView.swift
//  Melody
//
//  Created by Ezenwa Okoro on 22/04/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class PassthroughView: UIView {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        return subviews.first(where: { $0.frame.contains(point) }) != nil
    }
}
