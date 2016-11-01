//
//  DraggingInfo.swift
//  Silkscreen
//
//  Created by James Campbell on 11/1/16.
//  Copyright © 2016 SK. All rights reserved.
//

import UIKit

class DraggingInfo {
    
    let draggingPasteboard: UIPasteboard
    let draggingLocation: CGPoint
    let destinationWindow: UIWindow
    let draggingImage: UIImage
    
    init(draggingPasteboard: UIPasteboard, draggingLocation: CGPoint, destinationWindow: UIWindow, draggingImage: UIImage) {
        self.draggingPasteboard = draggingPasteboard
        self.draggingLocation = draggingLocation
        self.destinationWindow = destinationWindow
        self.draggingImage = draggingImage
    }
}
