//
//  DraggingSession.swift
//  Silkscreen
//
//  Created by James Campbell on 11/1/16.
//  Copyright © 2016 SK. All rights reserved.
//

import UIKit

@objc class DraggingSession: NSObject {
    
    let offset: CGPoint
    let image: UIImage
    
    init(pasteBoard: UIPasteboard, image: UIImage, offset: CGPoint, source: DraggingSource) {
        
        self.image = image
        self.offset = offset
        
        super.init()
    }
}
