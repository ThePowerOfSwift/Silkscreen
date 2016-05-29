//
//  DevicePickerViewModel.swift
//  Silkscreen
//
//  Created by James Campbell on 5/29/16.
//  Copyright © 2016 SK. All rights reserved.
//

import Foundation
import AVFoundation

class DevicePickerViewModel {
    
    private let mediaType: String
    
    private var devices: [AVCaptureDevice] = []
    
    init(mediaType: String) {
        
        self.mediaType = mediaType
        

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateDevices), name: AVCaptureDeviceWasConnectedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateDevices), name: AVCaptureDeviceWasDisconnectedNotification, object: nil)
        
        updateDevices()
    }
    
    @objc private func updateDevices() {
        devices = AVCaptureDevice.devicesWithMediaType(mediaType) as! [AVCaptureDevice]
    }
}