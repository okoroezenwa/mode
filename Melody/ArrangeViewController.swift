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
    @IBOutlet var defaultButton: MELButton!
    @IBOutlet var randomButton: MELButton!
    @IBOutlet var defaultView: UIView!
    @IBOutlet var randomView: UIView!
    @IBOutlet var defaultBorderView: MELBorderView!
    @IBOutlet var randomBorderView: MELBorderView!
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
                
                collectionView.deselectItem(at: indexPath, animated: false)//cell.selectedBorderView.isHidden = true
            }
            
            if let indexPath = oldValue {
            
                collectionView.deselectItem(at: indexPath, animated: false)//cell.selectedBorderView.isHidden = true
            }
        }
    }
    
    var selectedIndexPath: IndexPath? {
        
        didSet {
            
            guard selectedIndexPath != oldValue, let indexPath = selectedIndexPath else { return }
            
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])//cell.selectedBorderView.isHidden = false
        }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let constant = (18 * 2) + (FontManager.shared.heightsDictionary[.body] ?? 0)
        verticalPresentedVC?.containerViewHeightConstraint.constant = (cellHeight * ceil(CGFloat(applicableCriteria.count) / 3)) + constant
        verticalPresentedVC?.setTitle("Sort By...")
        verticalPresentedVC?.view.layoutIfNeeded()
        
        collectionView.register(UINib.init(nibName: "GestureSelectableCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        collectionView.scrollIndicatorInsets.bottom = 15
        
        notifier.addObserver(self, selector: #selector(updateScrollView), name: UIApplication.didChangeStatusBarFrameNotification, object: UIApplication.shared)
        
        updateScrollView(self)
        
        switch sorter.sortCriteria {
            
            case .random: randomBorderView.isHidden = false
            
            case .standard: defaultBorderView.isHidden = false
            
            default:
                
                var index = 0
            
                applicableCriteria.enumerated().forEach {
                    
                    if $0.element == sorter.sortCriteria {
                        
                        index = $0.offset
                    }
                }
            
                selectedIndexPath = .init(item: index, section: 0)
        }

        verticalPresentedVC?.selectedIndexPath = IndexPath.init(item: sorter.ascending ? 0 : 1, section: 0)
        persist(self)
        
        let hold = UILongPressGestureRecognizer.init(target: self, action: #selector(persist(_:)))
        hold.minimumPressDuration = longPressDuration
        hold.delegate = self
        lockButton?.addGestureRecognizer(hold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
        
        verticalPresentedVC?.leftButtonAction = { [weak self] button, _ in
            
            guard let weakSelf = self else { return }
            
            weakSelf.persist(button)
        }
    }
    
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
        
        if let button = sender as? UIButton {
            
            if button == defaultButton, !sorter.ascending {
                
                sorter.applySort = false
                sorter.ascending = true
            }
            
            sorter.sortCriteria = criteria(for: button)
            sorter.applySort = true
            
            if button == defaultButton {
                
                defaultBorderView.isHidden = false
                
            } else {
                
                randomBorderView.isHidden = false
            }
            
            [InactiveView.collectionView, (button == defaultButton ? .randomView : .defaultView)].forEach({ noSelection(of: $0, allowCollectionViewSelection: false) })
            
            if let indexPath = selectedIndexPath {
                
                collectionView.deselectItem(at: indexPath, animated: false)
                selectedIndexPath = nil
            }
            
        } else if let indexPath = sender as? IndexPath {
            
            sorter.sortCriteria = applicableCriteria[indexPath.item]
            [InactiveView.randomView, .defaultView].forEach({ noSelection(of: $0) })
        }
        
        guard persistPopovers || persistArrangeView else {
        
            dismiss(animated: true, completion: nil)
            
            return
        }
        
        verticalPresentedVC?.selectedIndexPath = .init(item: sorter.ascending == true ? 0 : 1, section: 0)
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
    
    func criteria(for button: UIButton) -> SortCriteria {
        
        switch button {
            
            case randomButton: return .random
            
            default: return .standard
        }
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        if firstLaunch, !Set([SortCriteria.standard, .random]).contains(sorter.sortCriteria) {
            
            firstLaunch = false
        }
    }
    
    func noSelection(of view: InactiveView, allowCollectionViewSelection: Bool = true) {
        
        switch view {
            
            case .randomView: randomBorderView.isHidden = true
            
            case .defaultView: defaultBorderView.isHidden = true
            
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
                
                if defaultView.bounds.contains(sender.location(in: defaultView)) {
                    
                    [InactiveView.randomView, .collectionView].forEach({ noSelection(of: $0, allowCollectionViewSelection: false) })
                    
                    defaultBorderView.isHidden = false
                    
                } else if randomView.bounds.contains(sender.location(in: randomView)) {
                    
                    [InactiveView.collectionView, .defaultView].forEach({ noSelection(of: $0, allowCollectionViewSelection: false) })
                    
                    randomBorderView.isHidden = false
                    
                } else if let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)) {
                    
                    guard indexPath != highlightedIndexPath else {
                        
                        [InactiveView.randomView, .defaultView].forEach({ noSelection(of: $0) })
                        
                        return
                    }
                    
                    highlightedIndexPath = indexPath
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                
                } else {
                    
                    noSelection()
                }
            
            case .ended:
                
                if defaultView.bounds.contains(sender.location(in: defaultView)) {
                    
                    selectSort(defaultButton)
                    
                } else if randomView.bounds.contains(sender.location(in: randomView)) {
                    
                    selectSort(randomButton)
                    
                } else if let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)) {
                    
                    self.collectionView(collectionView, didSelectItemAt: indexPath)
                }
        
            default: InactiveView.allCases.forEach({ noSelection(of: $0, allowCollectionViewSelection: false) })
        }
    }
    
    func noSelection() {
        
        switch sorter.sortCriteria {
            
            case .random:
            
                randomBorderView.isHidden = false
                [InactiveView.collectionView, .defaultView].forEach({ noSelection(of: $0, allowCollectionViewSelection: false) })
            
            case .standard:
            
                defaultBorderView.isHidden = false
                [InactiveView.collectionView, .randomView].forEach({ noSelection(of: $0, allowCollectionViewSelection: false) })
            
            default: [InactiveView.collectionView, .randomView, .defaultView].forEach({ noSelection(of: $0) })
        }
    }
}

extension ArrangeViewController: SegmentedResponder {
    
    func selectedSegment(at index: Int) {
        
        if index == 0, sorter.ascending.inverted {
            
            sorter.ascending = true
            verticalPresentedVC?.selectedIndexPath = IndexPath.init(item: 0, section: 0)
        
        } else if index == 1, sorter.ascending {
            
            sorter.ascending = false
            verticalPresentedVC?.selectedIndexPath = IndexPath.init(item: 1, section: 0)
        }
        
        guard persistPopovers.inverted, persistArrangeView.inverted else { return }
        
        self.dismiss(animated: true, completion: nil)
    }
}
