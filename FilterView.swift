//
//  FilterView.swift
//  Mode
//
//  Created by Ezenwa Okoro on 25/11/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias PropertyStripLocationDetails = (fromOtherArray: Bool, index: Int, indexPath: IndexPath)
typealias FilterInfo = (filter: Filterable?, container: (FilterContainer & UIViewController)?)

class FilterViewContainer: UIView {
    
    var filterInfo: FilterInfo? {
        
        get { filterView.filterInfo }
    
        set { filterView.filterInfo = newValue }
    }
    lazy var filterView = FilterView.instance
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        fill(with: filterView)
    }
}

class FilterView: UIView {

    @IBOutlet var searchBar: MELSearchBar!
    @IBOutlet var borderView: MELBorderView!
    lazy var filterTestButton: MELButton = leftView.testButton
    lazy var propertyButton: MELButton = leftView.propertyButton
    @IBOutlet var filterInputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var filterInputViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var rightButton: MELButton!
    @IBOutlet var rightButtonContainer: UIView!
    @IBOutlet var rightButtonContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet var rightButtonContainerEqualityWidthConstraint: NSLayoutConstraint!
    //    @IBOutlet var actionsButtonContainer: UIView!
//    @IBOutlet var actionsButtonContainerWidthConstraint: NSLayoutConstraint!
    
//    var showActionsButton = false {
//
//        didSet {
//
//            actionsButtonContainer.alpha = showActionsButton ? 1 : 0
//            actionsButtonContainerWidthConstraint.constant = showActionsButton ? 36 : 0
//        }
//    }
    var filterInfo: (filter: Filterable?, container: (FilterContainer & UIViewController)?)?
    lazy var hasSetUpSettingsGesture = false
    var leftView = SearchLeftView.instance
    
    var requiresSearchBar = false {

        didSet {
            
            filterInputViewBottomConstraint.constant = requiresSearchBar.inverted ? -53 : 0
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        updateSpacing(self)
        
        notifier.addObserver(self, selector: #selector(updateSpacing), name: .lineHeightsCalculated, object: nil)
        
        filterTestButton.addTarget(self, action: #selector(showPropertyTests(_:)), for: .touchUpInside)
        propertyButton.addTarget(self, action: #selector(showProperties(_:)), for: .touchUpInside)
        
        let hold = UILongPressGestureRecognizer.init(target: self, action: #selector(showPropertyTests(_:)))
        hold.minimumPressDuration = longPressDuration
        filterTestButton.addGestureRecognizer(hold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))

        let gr = UILongPressGestureRecognizer.init(target: self, action: #selector(showProperties(_:)))
        gr.minimumPressDuration = longPressDuration
        propertyButton.addGestureRecognizer(gr)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: gr))
        
        let rightHold = UILongPressGestureRecognizer.init(target: self, action: #selector(showRightButtonOptions(_:)))
        rightHold.minimumPressDuration = longPressDuration
        rightButton.addGestureRecognizer(rightHold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: rightHold))
    }
    
    @objc func updateSpacing(_ sender: Any) {
        
        filterTestButton.titleEdgeInsets.bottom = {
            
            switch activeFont {
                
                case .avenirNext, .system: return 3
                
                case .myriadPro: return 0
                
                case .museoSansRounded: return 3
            }
        }()
    }
    
    class var instance: FilterView {
        
        let view = Bundle.main.loadNibNamed("FilterView", owner: nil, options: nil)?.first as! FilterView
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }
    
    @objc func showPropertyTests(_ sender: Any) {
        
        if let _ = sender as? UIButton {
            
            filterInfo?.container?.showPropertyTests()
        
        } else if let sender = sender as? UILongPressGestureRecognizer {
            
            switch sender.state {
                
                case .began: filterInfo?.container?.showPropertyTests()
                
                case .changed, .ended:
                
                    guard useSystemAlerts.inverted, let top = topViewController as? VerticalPresentationContainerViewController else { return }
                
                    top.gestureActivated(sender)
                
                default: break
            }
        }
    }
    
    @objc func showProperties(_ sender: Any) {
        
        if let _ = sender as? UIButton {
            
            filterInfo?.container?.showFilterProperties()
        
        } else if let sender = sender as? UILongPressGestureRecognizer {
            
            switch sender.state {
                
                case .began: filterInfo?.container?.showFilterProperties()
                
                case .changed, .ended:
                
                    guard useSystemAlerts.inverted, let top = topViewController as? VerticalPresentationContainerViewController else { return }
                
                    top.gestureActivated(sender)
                
                default: break
            }
        }
    }
    
    @IBAction func showRightButtonOptions(_ sender: Any) {
        
        if let _ = sender as? UIButton {
            
            filterInfo?.container?.showRightButtonOptions()
        
        } else if let sender = sender as? UILongPressGestureRecognizer {
            
            switch sender.state {
                
                case .began: filterInfo?.container?.showRightButtonOptions()
                
                case .changed, .ended:
                
                    guard useSystemAlerts.inverted, let top = topViewController as? VerticalPresentationContainerViewController else { return }
                
                    top.gestureActivated(sender)
                
                default: break
            }
        }
    }
}

class Size: NSObject {
    
    let width: CGFloat
    let height: CGFloat
    
    init(width: CGFloat, height: CGFloat) {
        
        self.width = width
        self.height = height
        
        super.init()
    }
    
    var cgSize: CGSize { return CGSize.init(width: width, height: height) }
    
    override var hash: Int { return width.hashValue ^ height.hashValue }
}

class Index: NSObject {
    
    let indexPath: IndexPath
    let uppercased: Bool
    
    init(indexPath: IndexPath, uppercased: Bool) {
        
        self.indexPath = indexPath
        self.uppercased = uppercased
        
        super.init()
    }
    
    override var hash: Int { return indexPath.hashValue ^ uppercased.hashValue }
}
