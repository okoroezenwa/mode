//
//  ArrangeViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 06/10/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ArrangeViewController: UIViewController {
    
    @IBOutlet var collectionView: UICollectionView!
    
    enum Persistence { case off, temporary, permanent }
    
    lazy var lockButtonBorder: MELBorderView? = self.verticalPresentedVC?.leftButtonBorderView
    lazy var lockButton: MELButton? = self.verticalPresentedVC?.leftButton
    lazy var lockBorderedView: MELBorderView? = self.verticalPresentedVC?.leftBorderedBorderView
    
    var index = 0
    weak var sorter: Arrangeable!
    var locationDetails: (location: Location, criteria: SortCriteria, ascending: Bool)?
    @objc var persistPopovers = false
    var isSetting = false
    var persistence = persistArrangeView ? Persistence.permanent : .off {
        
        didSet {
            
            switch persistence {
                
                case .off: persistArrangeView = false
                
                case .temporary: persistPopovers = true
                
                case .permanent:
                
                    persistPopovers = false
                    persistArrangeView = true
            }
        }
    }
    var verticalPresentedVC: VerticalPresentationContainerViewController? { return parent as? VerticalPresentationContainerViewController }
    lazy var applicableCriteria: [SortCriteria] = {
        
        let criteria = isSetting ? SortCriteria.applicableSortCriteria(for: sorterLocation) : sorter.applicableSortCriteria
        
        return (criteria.union([.standard, .random])).sorted(by: { SortCriteria.sortResult(between: $0, and: $1, at: sorterLocation) })
    }()
    lazy var sorterLocation: Location = {
        
        if isSetting, let details = locationDetails {
            
            return details.location
        }
        
        return (sorter as? UIViewController)?.location ?? .unknown
    }()
    var ascending: Bool {
        
        if isSetting, let ascending = locationDetails?.ascending {
            
            return ascending
        }
        
        return sorter.ascending
    }
    var criteria: SortCriteria {
        
        if isSetting, let criteria = locationDetails?.criteria {
            
            return criteria
        }
        
        return sorter.sortCriteria
    }
    let cellHeight: CGFloat = 57
    
    var highlightedIndexPath: IndexPath? {
        
        didSet {
            
            guard highlightedIndexPath != oldValue, let indexPath = oldValue, indexPath != selectedIndexPath, let cell = collectionView.cellForItem(at: indexPath) else { return }
            
            cell.isHighlighted = false
        }
    }
    
    var selectedIndexPath: IndexPath? {
        
        didSet {
            
            guard selectedIndexPath != oldValue, let indexPath = selectedIndexPath, let cell = collectionView.cellForItem(at: indexPath) else { return }
            
            cell.isSelected = true
        }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        verticalPresentedVC?.containerViewHeightConstraint.constant = (cellHeight * ceil(CGFloat(applicableCriteria.count) / 3))
        verticalPresentedVC?.view.layoutIfNeeded()
        
        collectionView.register(UINib.init(nibName: "GestureSelectableCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        collectionView.scrollIndicatorInsets.bottom = 15
        
        notifier.addObserver(self, selector: #selector(updateScrollView), name: UIApplication.didChangeStatusBarFrameNotification, object: UIApplication.shared)
        
        updateScrollView(self)
    
        selectedIndexPath = {
            
            if let index = applicableCriteria.firstIndex(of: criteria)  {
                
                return .init(item: index, section: 0)
            }
            
            return nil
            
        }()

        verticalPresentedVC?.selectedCollectionIndexPath =  .init(item: ascending ? 0 : 1, section: 0)
        
        persist(self)
    }
    
    /// Determines whether the collectionView should be scrollable or not based on the height of its contents.
    @objc func updateScrollView(_ sender: Any) {
        
        guard let parent = verticalPresentedVC else { return }
        
        let constant: CGFloat = sender is Notification ? 20 : 0
        let isScrollEnabled = !((parent.effectViewsContainer.frame.height + 6 + constant + UIApplication.shared.statusBarFrame.height) < screenHeight)
        
        collectionView.isScrollEnabled = isScrollEnabled
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        collectionView.flashScrollIndicators()
    }
    
    @IBAction func selectSort(_ sender: Any) {
        
        if let indexPath = sender as? IndexPath {
            
            let criteria = applicableCriteria[indexPath.item]
            let needsSortPrevention = isSetting.inverted && criteria == .standard && sorter.ascending.inverted
            
            if needsSortPrevention {
                
                sorter.applySort = false
                sorter.ascending = true
                sorter.sortCriteria = criteria
                sorter.applySort = true
            
            } else {
                
                if isSetting, let details = locationDetails {
                    
                    let temp = EntityType.collectionEntityDetails(for: details.location)
                    
                    collectionSortCategories = collectionSortCategories?.appending(key: temp.type.title(matchingPropertyName: true) + temp.startPoint.title, value: criteria.rawValue)
                    
                    notifier.post(name: .collectionSortChanged, object: nil, userInfo: ["index": index])
                    
                    locationDetails = (details.location, criteria, details.ascending)
                    
                } else {
                
                    sorter.sortCriteria = criteria
                }
            }
        }
        
        guard Set([.temporary, .permanent]).contains(persistence) else {
        
            dismiss(animated: true, completion: nil)
            
            return
        }
        
        verticalPresentedVC?.selectedCollectionIndexPath = .init(item: ascending == true ? 0 : 1, section: 0)
    }
    
    @objc func persist(_ sender: Any) {
        
        let animated = !(sender is UIViewController)
        
        if sender is UIButton {
            
            switch persistence {
                
                case .off: persistence = .temporary
                
                case .temporary: persistence = .permanent
                
                case .permanent: persistence = .off
            }
        }
        
        lockButton?.reversed = persistence == .permanent
        
        lockButtonBorder?.updateTheme = false
        lockButtonBorder?.clear = persistence == .off
        lockButtonBorder?.alphaOverride = persistence == .permanent ? 1 : 0
        
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: { [weak self] in
            
            guard let weakSelf = self else { return }
            
            weakSelf.lockButton?.changeThemeColor()
            weakSelf.lockButtonBorder?.updateTheme = true
            weakSelf.lockBorderedView?.alpha = weakSelf.persistence == .permanent ? 0 : 1
        })
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "AVC going away...").show(for: 0.5)
        }
    }
}

extension ArrangeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return applicableCriteria.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GestureSelectableCollectionViewCell
        
        let criteria = applicableCriteria[indexPath.item]
        cell.prepare(with: criteria.title(from: sorterLocation), subtitle: criteria.subtitle(from: sorterLocation))
        cell.selectedBorderView.isHidden = criteria != self.criteria
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let old = selectedIndexPath, old != indexPath {
            
            selectedIndexPath = nil
            collectionView.cellForItem(at: old)?.isSelected = false
        }
        
        selectedIndexPath = indexPath
        selectSort(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if indexPath == selectedIndexPath {
            
            cell.isSelected = true
        }
    }
}

extension ArrangeViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize.init(width: (screenWidth - 12) / 3, height: cellHeight)
    }
}

extension ArrangeViewController: GestureSelectable {
    
    func selectCell(_ sender: UIGestureRecognizer) {
        
        switch sender.state {
            
            case .began, .changed:
                
                if let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)) {
                    
                    guard indexPath != highlightedIndexPath, let cell = collectionView.cellForItem(at: indexPath) as? GestureSelectableCollectionViewCell else { return }
                    
                    highlightedIndexPath = indexPath
                    
                    if indexPath != selectedIndexPath {
                        
                        cell.isHighlighted = true
                    }
                
                } else {
                    
                    noSelection()
                }
            
            case .ended:
                
                if let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)) {
                    
                    self.collectionView(collectionView, didSelectItemAt: indexPath)
                
                } else {
                    
                    noSelection()
                }
        
            default: noSelection()
        }
    }
    
    func noSelection() {
        
        if let _ = highlightedIndexPath {
            
            highlightedIndexPath = nil
        }
    }
}

extension ArrangeViewController: SegmentedResponder {
    
    func selectedSegment(at index: Int) {
        
        if index == 0, ascending.inverted {
            
            if isSetting, let details = locationDetails {
                
                let temp = EntityType.collectionEntityDetails(for: details.location)
                
                collectionSortOrders = collectionSortOrders?.appending(key: temp.type.title(matchingPropertyName: true) + temp.startPoint.title, value: true)
                
                notifier.post(name: .collectionSortChanged, object: nil, userInfo: ["index": self.index])
                
                locationDetails = (details.location, details.criteria, true)
                
            } else {
            
                sorter.ascending = true
            }
        
        } else if index == 1, ascending {
            
            if isSetting, let details = locationDetails {
                
                let temp = EntityType.collectionEntityDetails(for: details.location)
                
                collectionSortOrders = collectionSortOrders?.appending(key: temp.type.title(matchingPropertyName: true) + temp.startPoint.title, value: false)
                
                notifier.post(name: .collectionSortChanged, object: nil, userInfo: ["index": self.index])
                
                locationDetails = (details.location, details.criteria, false)
                
            } else {
            
                sorter.ascending = false
            }
        }
        
        guard persistence == .off else { return }
        
        self.dismiss(animated: true, completion: nil)
    }
}
