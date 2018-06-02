//
//  SectionIndexViewController.swift
//  Mode
//
//  Created by Ezenwa Okoro on 20/11/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SectionIndexViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var effectView: MELVisualEffectView!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var effectViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var effectViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var shadowImageViewTrailingConstraint: NSLayoutConstraint!
    
    enum IndexKind { case text(String), image(UIImage), view, dot }
    
    enum OverflowBehaviour { case stretch, squeeze }
    
    let transitioner = SimplePresentationAnimationController.init(orientation: .horizontal)
    var array = [IndexKind]()
    lazy var overflowBahaviour: OverflowBehaviour = { return array.count > 30 || array.count <= maxRowsAtMaxFontSize ? .stretch : .squeeze }()
    weak var container: (IndexContaining & UIViewController)?
    lazy var hasHeader: Bool = {
        
        if let kind = array.first, case .view = kind {
            
            return true
        }
        
        return false
    }()
    
    lazy var rowHeight: CGFloat = {
        
        switch overflowBahaviour {
            
            case .stretch: return 44
            
            case .squeeze: return floor((UIScreen.main.bounds.height - (isiPhoneX ? UIApplication.shared.statusBarFrame.height * 2 : 80) - 5) / CGFloat(array.count))
        }
        
    }() // assuming a max section count of 30
    
    lazy var fontSize: CGFloat = {
        
        switch overflowBahaviour {
            
            case .stretch: return 25
            
            case .squeeze: return ceil((15 / 20) * rowHeight)
        }
        
    }() // min font size of 15 gets min height of 20 on 6S.
    
    lazy var maxWidthDifferenceForMaxFontSize: CGFloat = {
        
        switch overflowBahaviour {
            
            case .stretch: return 44 - 20.5
            
            case .squeeze: return rowHeight - Array("abcdefghijklmnopqrstuvwxyz#".capitalized).map({ (String($0) as NSString).boundingRect(with: .init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [.font: UIFont.myriadPro(ofWeight: .light, size: fontSize)], context: nil).width }).max()!
        }
        
    }() // max single, capital character of MP @ 25pt = 20.5. Given a max width for this font size, this leaves (`max` - 20.5) space on both sides combined. Thus, this space will be added to the width of the max string width in the array for the final cell/constraint size.
    
    lazy var maxRowsAtMaxFontSize = Int(floor((UIScreen.main.bounds.height - (isiPhoneX ? UIApplication.shared.statusBarFrame.height : 80) - 5) / 44))
    
    override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        
        get { return transitioner }
        
        set { }
    }
    
    override var modalPresentationStyle: UIModalPresentationStyle {
        
        get { return .overFullScreen }
        
        set { }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let swipe = UISwipeGestureRecognizer.init(target: self, action: #selector(dismissVC))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)

        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(changeSection(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(dismissVC))
        tap.delegate = self
        view.addGestureRecognizer(tap)
        
        if container?.requiresLargerTrailingConstraint == true {
            
            effectViewTrailingConstraint.constant = 12
            shadowImageViewTrailingConstraint.constant = -33
        }
        
        verifySize()
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        dismiss(animated: false, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        container?.sectionIndexViewController = nil
    }
    
    @objc func dismissVC() {
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func changeSection(_ gr: UIPanGestureRecognizer) {
        
        switch gr.state {
            
            case .began, .changed:
                
                guard let location: CGPoint = {
                    
                    if view.convert(effectView.frame, from: containerView).contains(gr.location(in: view)) {
                        
                        return gr.location(in: collectionView)
                        
                    } else if overflowBahaviour == .squeeze || array.count <= maxRowsAtMaxFontSize, let location: CGPoint = {
                        
                        let height: CGFloat = {
                            
                            if gr.location(in: collectionView).y < 0 {
                                
                                return 1 + 4
                                
                            } else if gr.location(in: collectionView).y > collectionView.frame.height {
                                
                                return collectionView.frame.height - 1 - 3
                            }
                            
                            return gr.location(in: collectionView).y
                        }()
                        
                        return .init(x: collectionView.center.x, y: height)
                        
                        }() {
                        
                        return location
                    }
                    
                    return nil
                    
                }(), let indexPath = collectionView.indexPathForItem(at: /*gr.location(in: collectionView)*/location) else { return }
                
                if hasHeader, indexPath.row == 0 {
                    
                    container?.tableView.setContentOffset(.zero, animated: false)
                    
                } else {
                    
                    container?.tableView.scrollToRow(at: .init(row: NSNotFound, section: indexPath.row - (hasHeader ? 1 : 0)), at: .top, animated: false)
                }
            
            case .ended, .cancelled, .failed: dismissVC()
            
            default: break
        }
    }
    
    func verifySize() {
        
        let maxWidth: CGFloat = {
            
            return array.map({
                
                switch $0 {
                    
                    case .view, .dot, .image: return 20.5
                    
                    case .text(let string): return (string as NSString).boundingRect(with: .init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [.font: UIFont.myriadPro(ofWeight: .light, size: fontSize)], context: nil).width
                }
                
            }).max() ?? 20.5
        }()
        
        let adjustedMax = ceil(maxWidth + maxWidthDifferenceForMaxFontSize)
        
        let arrayCount = CGFloat(array.count)
        let maxRows = CGFloat(maxRowsAtMaxFontSize)
        collectionViewHeightConstraint.constant = {
            
            switch overflowBahaviour {
            
                case .stretch: return (min(maxRows, arrayCount) * 44) + 5
                
                case .squeeze: return (rowHeight * arrayCount) + 5
            }
            
        }()
        
        effectViewWidthConstraint.constant = {
            
            switch overflowBahaviour {
                
                case .stretch: return max(ceil(arrayCount/maxRows) * adjustedMax, 44)
                
                case .squeeze: return max(adjustedMax, 16)
            }
        }()
        
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = .init(width: max(adjustedMax, overflowBahaviour == .squeeze ? 16 : 44), height: rowHeight)
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "SIVC going away...").show(for: 0.3)
        }
    }
}

extension SectionIndexViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard gestureRecognizer is UITapGestureRecognizer else { return true }
        
        return !view.convert(effectView.frame, from: containerView).contains(gestureRecognizer.location(in: view))
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard gestureRecognizer is UIPanGestureRecognizer else { return false }
        
        return otherGestureRecognizer is UISwipeGestureRecognizer
    }
}

extension SectionIndexViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return array.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! SectionIndexCollectionViewCell
        
        switch array[indexPath.row] {
            
            case .view:
            
                cell.borderView.isHidden = false
                cell.label.isHidden = true
                cell.borderViewWidthConstraint.priority = UILayoutPriority(rawValue: 899)
                cell.borderViewProportionalWidthConstraint.priority = UILayoutPriority(rawValue: 900)
            
            case .image: break
            
            case .dot:
            
                cell.label.isHidden = true
                cell.borderView.isHidden = false
                cell.borderViewWidthConstraint.priority = UILayoutPriority(rawValue: 900)
                cell.borderViewProportionalWidthConstraint.priority = UILayoutPriority(rawValue: 899)
            
            case .text(let string):
                
                cell.borderView.isHidden = true
                cell.label.isHidden = false
                cell.label.text = string
                cell.label.font = UIFont.myriadPro(ofWeight: fontSize < 19 ? .regular : .light, size: fontSize)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if hasHeader, indexPath.row == 0 {
            
            container?.tableView.setContentOffset(.zero, animated: false)
            
        } else {
            
            container?.tableView.scrollToRow(at: .init(row: NSNotFound, section: indexPath.row - (hasHeader ? 1 : 0)), at: .top, animated: false)
        }
        
        dismissVC()
    }
}

