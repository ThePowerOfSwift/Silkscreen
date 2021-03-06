//
//  RenderTrack.swift
//  Silkscreen
//
//  Created by James Campbell on 11/2/16.
//  Copyright © 2016 SK. All rights reserved.
//

import Foundation
import GPUImage
import Photos

class RenderTrack: GPUImageFilter {
    
    func render(_ track: Track) {
      
        //TODO: Fix this train
        guard let asset = track.items.value.first?.0 else {
            return
        }
      
      #if os(iOS) || os(watchOS) || os(tvOS)
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        
        option.isSynchronous = true
      
        //TODO: Move into extension for PHAsset
        manager.requestImage(for: asset, targetSize: CGSize(width: 100.0, height: 100.0), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            
            guard let result = result else {
                return
            }
            
            let pictureSource = GPUImagePicture(image: result)
            pictureSource?.addTarget(self)
            pictureSource?.processImage()
        })
      #endif
    }
}
