//
//  SongDelegate.swift
//  Melody
//
//  Created by Ezenwa Okoro on 11/02/2017.
//  Copyright © 2017 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SongDelegate: NSObject {
    
    weak var container: EntityContainer?

    init(container: EntityContainer) {
        
        self.container = container
        
        super.init()
    }
}

//extension SongDelegate: SongCellDelegate {
//    
//    @objc func performAuxillaryAction(inCell cell: SongTableViewCell) {
//        
//        guard let container = container as? SongContainer, let indexPath = container.tableView.indexPath(for: cell) else { return }
//        
//        if container.tableView.isEditing {
//            
//            container.tableView(container.tableView, commit: container.tableView(container.tableView, editingStyleForRowAt: indexPath), forRowAt: indexPath)
//            
//        } else {
//            
//            let song = container.getSong(from: indexPath, filtering: false)
//
//            musicPlayer.play([song], startingFrom: nil, from: container as? UIViewController, withTitle: song.validTitle, alertTitle: "Play")
//        }
//    }
//}
//
//extension SongDelegate: SongCellScrollDelegate {
//    
//    @objc func handleScrollTap(in cell: SongTableViewCell) {
//        
//        guard let container = container, let indexPath = container.tableView.indexPath(for: cell) else { return }
//        
//        if container.tableView.allowsMultipleSelectionDuringEditing && container.tableView.isEditing {
//            
//            if cell.isSelected {
//                
//                container.tableView.deselectRow(at: indexPath, animated: false)
//                
//            } else {
//                
//                container.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
//            }
//            
//            return
//        }
//        
//        cell.setHighlighted(true, animated: true)
//        container.tableView?(container.tableView, didSelectRowAt: indexPath)
//        cell.setHighlighted(false, animated: true)
//    }
//    
//    @objc func handleScrollSwipe(in cell: SongTableViewCell, from gr: UISwipeGestureRecognizer, direction: UISwipeGestureRecognizer.Direction) {
//        
//        guard let container = container else { return }
//        
//        if direction == .left {
//            
//            container.handleLeftSwipe(gr)
//            
//        } else if direction == .right {
//            
//            container.handleRightSwipe(gr)
//        }
//    }
//}

