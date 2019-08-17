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
    lazy var lockButtonBorder: MELBorderView? = self.verticalPresentedVC?.leftButtonBorderView
    lazy var lockButton: MELButton? = self.verticalPresentedVC?.leftButton
    
    enum InactiveView: CaseIterable { case collectionView, randomView, defaultView }
    
    weak var sorter: Arrangeable!
    @objc var firstLaunch = true
    @objc var persistPopovers = false
    var verticalPresentedVC: VerticalPresentationContainerViewController? { return parent as? VerticalPresentationContainerViewController }
    lazy var applicableCriteria = sorter.applicableSortCriteria.sorted(by: { $0.title(from: (sorter as? UIViewController)?.location ?? .unknown) < $1.title(from: (sorter as? UIViewController)?.location ?? .unknown) })
    let cellHeight: CGFloat = 57
    
    var highlightedIndexPath: IndexPath? {
        
        didSet {
            
            guard highlightedIndexPath != oldValue else { return }
            
            if let indexPath = selectedIndexPath, let cell = collectionView.cellForItem(at: indexPath) as? GestureSelectableCollectionViewCell, cell.selectedBorderView.isHidden.inverted {
                
                collectionView.deselectItem(at: indexPath, animated: false)
            }
            
            if let indexPath = oldValue {
            
                collectionView.deselectItem(at: indexPath, animated: false)
            }
        }
    }
    
    var selectedIndexPath: IndexPath? {
        
        didSet {
            
            guard selectedIndexPath != oldValue, let indexPath = selectedIndexPath else { return }
            
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        verticalPresentedVC?.containerViewHeightConstraint.constant = (cellHeight * ceil(CGFloat(applicableCriteria.count) / 3))
        verticalPresentedVC?.setTitle("Sort By...")
        verticalPresentedVC?.view.layoutIfNeeded()
        
        collectionView.register(UINib.init(nibName: "GestureSelectableCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        collectionView.scrollIndicatorInsets.bottom = 15
        
        notifier.addObserver(self, selector: #selector(updateScrollView), name: UIApplication.didChangeStatusBarFrameNotification, object: UIApplication.shared)
        
        updateScrollView(self)
        
        switch sorter.sortCriteria {
            
            case .random: verticalPresentedVC?.selectedStaticIndexPath = .init(item: 1, section: 0)
            
            case .standard: verticalPresentedVC?.selectedStaticIndexPath = .init(item: 0, section: 0)
            
            default:
                
                var index = 0
            
                applicableCriteria.enumerated().forEach {
                    
                    if $0.element == sorter.sortCriteria {
                        
                        index = $0.offset
                    }
                }
            
                selectedIndexPath = .init(item: index, section: 0)
        }

        verticalPresentedVC?.selectedSegmentedIndexPath = IndexPath.init(item: sorter.ascending ? 0 : 1, section: 0)
        persist(self)
        
        let hold = UILongPressGestureRecognizer.init(target: self, action: #selector(persist(_:)))
        hold.minimumPressDuration = longPressDuration
        hold.delegate = self
        lockButton?.addGestureRecognizer(hold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
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
        
        if let criteria = sender as? SortCriteria {
            
            if criteria == .standard, !sorter.ascending {
                
                sorter.applySort = false
                sorter.ascending = true
            }
            
            sorter.sortCriteria = criteria
            sorter.applySort = true
            
            [InactiveView.collectionView, (criteria == .standard ? .randomView : .defaultView)].forEach({ noSelection(of: $0, allowCollectionViewSelection: false) })
            
            if criteria == .standard {
                
                verticalPresentedVC?.selectedStaticIndexPath = .init(item: 0, section: 0)
                
            } else {
                
                verticalPresentedVC?.selectedStaticIndexPath = .init(item: 1, section: 0)
            }
            
            if let indexPath = selectedIndexPath {
                
                collectionView.deselectItem(at: indexPath, animated: false)
                selectedIndexPath = nil
            }
            
        } else if let indexPath = sender as? IndexPath {
            
            sorter.sortCriteria = applicableCriteria[indexPath.item]
            [InactiveView.randomView, .defaultView].forEach({ noSelection(of: $0) })
            verticalPresentedVC?.selectedStaticIndexPath = nil
        }
        
        guard persistPopovers || persistArrangeView else {
        
            dismiss(animated: true, completion: nil)
            
            return
        }
        
        verticalPresentedVC?.selectedSegmentedIndexPath = .init(item: sorter.ascending == true ? 0 : 1, section: 0)
    }
    
    @objc func persist(_ sender: Any) {
        
        let animated = !(sender is UIViewController)
        
        if let gr = sender as? UIGestureRecognizer, gr.state == .began {
            
            persistPopovers = !persistPopovers
            
            UniversalMethods.banner(withTitle: persistPopovers ? "Temporarily Locked" : "Unlocked").show(for: 0.7)
            
        } else if sender is UIButton {
            
            var setPreference = true
            
            if persistPopovers {
                
                persistPopovers = false
                setPreference = persistArrangeView
            }
            
            if setPreference {
                
                prefs.set(!persistArrangeView, forKey: .persistArrangeView)
            }
        }
        
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: { [weak self] in
            
            guard let weakSelf = self else { return }
            
            weakSelf.lockButtonBorder?.clear = !weakSelf.persistPopovers && !persistArrangeView
        })
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        if firstLaunch, !Set([SortCriteria.standard, .random]).contains(sorter.sortCriteria) {
            
            firstLaunch = false
        }
    }
    
    func noSelection(of view: InactiveView, allowCollectionViewSelection: Bool = true) {
        
        switch view {
            
            case .randomView: verticalPresentedVC?.staticCollectionView.deselectItem(at: .init(item: 1, section: 0), animated: false)
            
            case .defaultView: verticalPresentedVC?.staticCollectionView.deselectItem(at: .init(item: 0, section: 0), animated: false)
            
            case .collectionView:
                
                if let _ = highlightedIndexPath {
                    
                    highlightedIndexPath = nil
                }
                
                guard let indexPath = selectedIndexPath else { return }
                
                if allowCollectionViewSelection {
                    
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    
                } else {
                    
                    collectionView.deselectItem(at: indexPath, animated: false)
                }
        }
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
        cell.prepare(with: criteria.title(from: (sorter as! UIViewController).location), image: nil, style: .body)
        cell.selectedBorderView.isHidden = criteria != sorter.sortCriteria
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        [InactiveView.randomView, .defaultView].forEach({ noSelection(of: $0) })
        
        if let old = selectedIndexPath {

            collectionView.deselectItem(at: old, animated: false)
        }
        
        selectedIndexPath = indexPath
        selectSort(indexPath)
    }
}

extension ArrangeViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize.init(width: (screenWidth - 12) / 3, height: cellHeight)
    }
}

extension ArrangeViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return !persistArrangeView
    }
}

extension ArrangeViewController: GestureSelectable {
    
    func selectCell(_ sender: UIPanGestureRecognizer) {
        
        switch sender.state {
            
            case .began, .changed:
                
                if let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)) {
                    
                    guard indexPath != highlightedIndexPath else {
                        
                        [InactiveView.randomView, .defaultView].forEach({ noSelection(of: $0) })
                        
                        return
                    }
                    
                    highlightedIndexPath = indexPath
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                
                } else {
                    
                    noSelection(of: .collectionView)
                    verticalPresentedVC?.noSelection(of: .staticCollectionView)
                }
            
            case .ended:
                
                if let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)) {
                    
                    self.collectionView(collectionView, didSelectItemAt: indexPath)
                
                } else {
                    
                    noSelection(of: .collectionView)
                    verticalPresentedVC?.noSelection(of: .staticCollectionView)
                }
        
            default: InactiveView.allCases.forEach({ noSelection(of: $0, allowCollectionViewSelection: false) })
        }
    }
    
    func noSelection(withinChildViewFrame: Bool) {
        
        noSelection(of: .collectionView, allowCollectionViewSelection: withinChildViewFrame.inverted)
    }
}

extension ArrangeViewController: SegmentedResponder {
    
    func selectedSegment(at index: Int) {
        
        if index == 0, sorter.ascending.inverted {
            
            sorter.ascending = true
            verticalPresentedVC?.selectedSegmentedIndexPath = IndexPath.init(item: 0, section: 0)
        
        } else if index == 1, sorter.ascending {
            
            sorter.ascending = false
            verticalPresentedVC?.selectedSegmentedIndexPath = IndexPath.init(item: 1, section: 0)
        }
        
        guard persistPopovers.inverted, persistArrangeView.inverted else { return }
        
        self.dismiss(animated: true, completion: nil)
    }
}

extension ArrangeViewController: StaticOptionResponder {
    
    func selectedStaticOption(at index: Int) {
        
        if index == 0 {
            
            [InactiveView.randomView, .collectionView].forEach({ noSelection(of: $0, allowCollectionViewSelection: false) })
            selectSort(SortCriteria.standard)
            
        } else if index == 1 {
            
            [InactiveView.defaultView, .collectionView].forEach({ noSelection(of: $0, allowCollectionViewSelection: false) })
            selectSort(SortCriteria.random)
        }
    }
}
