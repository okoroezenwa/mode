//
//  ArrangeViewController.swift
//  Melody
//
//  Created by Ezenwa Okoro on 06/10/2016.
//  Copyright © 2016 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ArrangeViewController: UIViewController {
    
    @IBOutlet var orderBorderView: MELBorderView!
    @IBOutlet var orderBorderViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var ascendingButton: MELButton!
    @IBOutlet var descendingButton: MELButton!
    @IBOutlet var resetButton: MELButton!
    @IBOutlet var randomButton: MELButton!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var titleButton: MELButton!
    @IBOutlet var artistButton: MELButton!
    @IBOutlet var albumButton: MELButton!
    @IBOutlet var dateAddedButton: MELButton!
    @IBOutlet var playsButton: MELButton!
    @IBOutlet var durationButton: MELButton!
    @IBOutlet var ratingButton: MELButton!
    @IBOutlet var genreButton: MELButton!
    @IBOutlet var lastPlayedButton: MELButton!
    @IBOutlet var yearButton: MELButton!
    @IBOutlet var fileSizeButton: MELButton!
    @IBOutlet var songCountButton: MELButton!
    @IBOutlet var albumCountButton: MELButton!
    @IBOutlet var lockButtonBorder: MELBorderView!
    @IBOutlet var lockButton: MELButton!
    
    weak var sorter: Arrangeable!
    @objc var firstLaunch = true
    var buttons: [MELButton?] { return [resetButton, randomButton, titleButton, artistButton, albumButton, dateAddedButton, playsButton, durationButton, ratingButton, genreButton, lastPlayedButton, yearButton, fileSizeButton, songCountButton, albumCountButton] }
    @objc var persistPopovers = false
    var verticalPresentedVC: VerticalPresentationContainerViewController? { return parent as? VerticalPresentationContainerViewController }

    override func viewDidLoad() {
        
        super.viewDidLoad()

        prepare()
    }
    
    @objc func prepare() {
        
        for button in buttons where button != resetButton && button != randomButton {
            
            if let button = button {
                
                button.isHidden = !sorter.applicableSortCriteria.contains(criteria(for: button))
            }
        }
        
        orderBorderViewLeadingConstraint.priority = UILayoutPriority(rawValue: sorter?.ascending == true ? 901 : 899)
        persist(self)
        
        [randomButton, resetButton].forEach({
            
            $0?.titleEdgeInsets.bottom = {
            
                switch activeFont {
                    
                    case .avenirNext, .system: return 3
                    
                    case .myriadPro: return 0
                }
            }()
        })
        
        selectedButton().update(for: .selected)
        
        let hold = UILongPressGestureRecognizer.init(target: self, action: #selector(persist(_:)))
        hold.minimumPressDuration = longPressDuration
        hold.delegate = self
        lockButton.addGestureRecognizer(hold)
        LongPressManager.shared.gestureRecognisers.append(Weak.init(value: hold))
        
        verticalPresentedVC?.containerViewHeightConstraint.constant = 169
        verticalPresentedVC?.setTitle("Sort By")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        scrollView.flashScrollIndicators()
    }
    
    @objc func selectedButton() -> UIButton {
        
        switch sorter.sortCriteria {
            
            case .album: return albumButton
                
            case .artist: return artistButton
                
            case .dateAdded: return dateAddedButton
                
            case .duration: return durationButton
                
            case .genre: return genreButton
                
            case .lastPlayed: return lastPlayedButton
                
            case .plays: return playsButton
                
            case .rating: return ratingButton
                
            case .title: return titleButton
                
            case .year: return yearButton
            
            case .fileSize: return fileSizeButton
            
            case .songCount: return songCountButton
            
            case .albumCount: return albumCountButton
                
            case .random: return randomButton
            
            case .standard: return resetButton
        }
    }
    
    @IBAction func selectSort(_ sender: UIButton) {
        
        if sender == resetButton, !sorter.ascending {
            
            sorter.ascending = true
        }
        
        sorter.sortCriteria = criteria(for: sender)
        
        guard persistPopovers || persistArrangeView else {
        
            dismiss(animated: true, completion: nil)
            
            return
        }
        
        for button in buttons {
            
            if button == sender {
                
                button?.update(for: .selected)
                
            } else {
                
                button?.update(for: .unselected)
            }
        }
        
        orderBorderViewLeadingConstraint.priority = UILayoutPriority(rawValue: sorter.ascending == true ? 901 : 899)
    }
    
    @IBAction func persist(_ sender: Any) {
        
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
            
            weakSelf.lockButtonBorder.clear = !weakSelf.persistPopovers && !persistArrangeView
        })
    }
    
    func criteria(for button: UIButton) -> SortCriteria {
        
        switch button {
            
            case titleButton: return .title
            
            case artistButton: return .artist
            
            case albumButton: return .album
            
            case dateAddedButton: return .dateAdded
            
            case playsButton: return .plays
            
            case durationButton: return .duration
            
            case yearButton: return .year
            
            case ratingButton: return .rating
            
            case genreButton: return .genre
            
            case lastPlayedButton: return .lastPlayed
            
            case fileSizeButton: return .fileSize
            
            case songCountButton: return .songCount
            
            case albumCountButton: return .albumCount
            
            case randomButton: return .random
            
            default: return .standard
        }
    }
    
    @IBAction func setAscending() {
        
        guard !sorter.ascending else { return }
        
        orderBorderViewLeadingConstraint.priority = UILayoutPriority(rawValue: 901)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { self.orderBorderView.superview?.layoutIfNeeded() }, completion: { finished in
            
            self.sorter.ascending = true
        
            guard finished, !self.persistPopovers, !persistArrangeView else { return }
            
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    @IBAction func setDescending() {
        
        guard sorter.ascending else { return }
        
        orderBorderViewLeadingConstraint.priority = UILayoutPriority(rawValue: 899)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: { self.orderBorderView.superview?.layoutIfNeeded() }, completion: { finished in
            
            self.sorter.ascending = false
            
            guard finished, !self.persistPopovers, !persistArrangeView else { return }
            
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        if firstLaunch, !Set([SortCriteria.standard, .random]).contains(sorter.sortCriteria) {
            
            scrollView.layoutIfNeeded()
            scrollView.scrollRectToVisible(selectedButton().frame, animated: false)
            firstLaunch = false
        }
    }
    
    deinit {
        
        if isInDebugMode, deinitBannersEnabled {
            
            UniversalMethods.banner(withTitle: "AVC going away...").show(for: 0.5)
        }
    }
}

extension ArrangeViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return !persistArrangeView
    }
}
