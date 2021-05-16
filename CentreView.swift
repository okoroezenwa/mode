//
//  CentreView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 27/04/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class CentreView: UIView {
    
    @IBOutlet var activityView: UIView!
    @IBOutlet var activityIndicator: MELActivityIndicatorView!
    @IBOutlet var activityVisualEffectView: MELVisualEffectView!
    @IBOutlet var emptyStackView: UIStackView!
    @IBOutlet var titleLabel: MELLabel!
    @IBOutlet var subtitleLabel: MELLabel!
    @IBOutlet var labelsImageView: UIImageView!
    @IBOutlet var tableView: UITableView!
    
    enum CurrentView: Equatable {
        
        case none, indicator, labels(components: Set<LabelStackViewComponent>), image
        
        enum LabelStackViewComponent: Hashable { case title, subtitle, image }
    }
    
    let imageAlpha: CGFloat = 0.4
    weak var manager: PassthroughManaging?
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        labelsImageView.alpha = imageAlpha
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        if let frames = manager?.passthroughFrames, frames.contains(where: { $0.contains(point) }) {
            
            return false
        }
        
        return super.point(inside: point, with: event)
    }
    
    func updateCurrentView(to type: CurrentView, animated: Bool, setAlpha: Bool = true, completion: (() -> ())? = nil) {
        
        if type == .indicator { activityIndicator.startAnimating() }
        
        let operations: () -> () = {
            
            if setAlpha {
            
                self.alpha = type == .none ? 0 : 1
            }
            
            switch type {
                
                case .none:
                
                    self.activityView.alpha = 0
                    self.emptyStackView.alpha = 0
                
                case .indicator:
                
                    self.activityView.alpha = 1
                    self.emptyStackView.alpha = 0
                
                case .labels(components: let components):
                    
                    let shouldHide: (CurrentView.LabelStackViewComponent) -> Bool = { component in
                        
                        switch component {
                            
                            case .title: return components.contains(.title).inverted
                            
                            case .subtitle: return components.contains(.subtitle).inverted
                            
                            case .image: return components.contains(.image).inverted
                        }
                    }
                    
                    if components.contains(.title).inverted, self.titleLabel.isHidden { } else {
                        
                        let hide = shouldHide(.title)
                        
                        self.titleLabel.alpha = hide ? 0 : 1
                        self.titleLabel.isHidden = hide
                    }
                    
                    if components.contains(.subtitle).inverted, self.subtitleLabel.isHidden { } else {
                        
                        let hide = shouldHide(.subtitle)
                        
                        self.subtitleLabel.alpha = hide ? 0 : 1
                        self.subtitleLabel.isHidden = hide
                    }
                    
                    if components.contains(.image).inverted, self.labelsImageView.isHidden { } else {
                        
                        let hide = shouldHide(.image)
                        
                        self.labelsImageView.superview?.alpha = hide ? 0 : self.imageAlpha
                        self.labelsImageView.superview?.isHidden = hide
                    }
                
                    self.activityView.alpha = 0
                    self.emptyStackView.alpha = 1
                
                case .image:
                
                    self.activityView.alpha = 0
                    self.emptyStackView.alpha = 0
            }
        }
        
        let completionBlock: ((Bool) -> ())? = { completed in
            
            if type != .indicator { self.activityIndicator.stopAnimating() }
            
            self.isUserInteractionEnabled = type != .none
            completion?()
        }
        
        if animated {
        
            UIView.animate(withDuration: 0.3, animations: operations, completion: completionBlock)
            
        } else {
            
            operations()
            completionBlock?(true)
        }
    }
    
    class var instance: CentreView {
            
        let view = Bundle.main.loadNibNamed("CentreView", owner: nil, options: nil)?.first as! CentreView
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }
    
    func add(to view: UIView, below topView: YAxisAnchorable, above bottomView: YAxisAnchorable) {
        
        view.addSubview(self)
        
        NSLayoutConstraint.activate([
        
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            self.topAnchor.constraint(equalTo: topView.bottomAnchor),
            self.bottomAnchor.constraint(equalTo: bottomView.topAnchor)
        ])
    }
}

protocol PassthroughManaging: AnyObject {
    
    var passthroughFrames: [CGRect]? { get }
}

extension PassthroughManaging {
    
    var passthroughFrames: [CGRect]? { nil }
}
