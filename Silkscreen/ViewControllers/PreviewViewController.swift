//
//  PreviewViewController.swift
//  Silkscreen
//
//  Created by James Campbell on 4/22/16.
//  Copyright © 2016 SK. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class PreviewViewController: AVPlayerViewController {

    var editorContext: EditorContext? = nil {
        didSet {
            if let editorContext = editorContext {
                player = AVPlayer()
                player?.replaceCurrentItemWithPlayerItem(editorContext.playerItem)
            }
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        showsPlaybackControls = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
