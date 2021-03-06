//
//  UIViewController+DragDestination.swift
//  Silkscreen
//
//  Created by James Campbell on 10/31/16.
//  Copyright © 2016 SK. All rights reserved.
//

#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#endif

private var DraggingAssociationKey: UInt8 = 0

extension UIViewController {
    
    func beginDraggingSession(with item: DraggingItem,
                                   location: CGPoint) -> DraggingSession {
        
        guard let window = view.window as? Window else {
            fatalError("Dragging Session started with view without dragging compatable Window")
        }
        
        guard let pasteboard = UIPasteboard(name: UIPasteboardName(rawValue: "com.silkscreen.drag-and-drop"), create: true) else {
            fatalError("Pastboard for Dragging Session failed to be created")
        }
        
        item.item.writeToPasteboard(pasteboard)
        
        let session = DraggingSession(pasteboard: pasteboard, image: item.image, offset: location)
        window.beginDraggingSession(session)
        
        return session
    }
    
    func findDraggingDestinationForDraggingInfo(_ info: DraggingInfo) -> DraggingDestination? {
      
        #if os(iOS) || os(watchOS) || os(tvOS)
        let location = view.convert(info.draggingLocation, from: info.destinationWindow)
        let inside = view.point(inside: location, with: nil)
        let canAcceptDrag = (self as? DraggingDestination)?.shouldAllowDrag(info) ?? false
        
        if (inside && canAcceptDrag) {
            
            return self as? DraggingDestination
            
        } else {
            
            for viewController in childViewControllers {
                if let draggingDestination = viewController.findDraggingDestinationForDraggingInfo(info) {
                    return draggingDestination
                }
            }
        }
        #endif
        
        return nil
    }
}
