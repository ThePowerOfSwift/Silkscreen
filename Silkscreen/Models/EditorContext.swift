//
//  EditorContext.swift
//  Silkscreen
//
//  Created by James Campbell on 4/24/16.
//  Copyright © 2016 SK. All rights reserved.
//

import UIKit
import AVFoundation

class EditorContext {
    
    init () {
        
        (1...5).enumerate().forEach {
            _ in
            addTrack()
        }
    }
    
    //MARK- Player Item
 
    lazy var playerItem: AVPlayerItem = {
        
        let mutableComposition = AVMutableComposition()
        let videoTrack = mutableComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let mutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.instructions = []
        mutableVideoComposition.frameDuration = CMTimeMake(1, 30)
        mutableVideoComposition.renderSize = CGSizeMake(500, 500)

        let item = AVPlayerItem(asset: mutableComposition)
        item.videoComposition = mutableVideoComposition
        
        return item
    }()
    
    //MARK:- Tracks
    
    private(set) var tracks = Frozen<[Track]>(value: [])
    
    func addTrack() {
        
        let track = Track()
        
        track.itemsDidChangeSignal.addSlot { _ in
            self.trackItemsDidChangeSignal.trigger()
        }
        
        tracks = tracks.append(track)
    }
    
    //MARK:- Assets
    
    private(set) var assets = Frozen<[Asset]>(value: []) {
        didSet {
            assetsDidChangeSignal.trigger()
        }
    }
    
    private(set) lazy var assetsDidChangeSignal: Signal<EditorContext> = {
        return Signal(sender: self)
    }()
    
    func addAsset(path: NSURL) {
        assets = assets.append(Asset(path: path))
    }
    
    //MARK:- Items
    
    private(set) lazy var trackItemsDidChangeSignal: Signal<EditorContext> = {
        return Signal(sender: self)
    }()
}
