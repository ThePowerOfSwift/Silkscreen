//
//  AddAssetViewController.swift
//  Silkscreen
//
//  Created by James Campbell on 4/28/16.
//  Copyright © 2016 SK. All rights reserved.
//

import UIKit

// - Fix crash in portrait
class AddAssetViewController: DividableViewController {

    private let assetSourcePicker = UISplitViewController()
    private let assetSourceViewController = AssetSourceViewController()
    
    var editorContext: EditorContext? = nil {
        didSet {
            
        }
    }
    
    init() {
        
        super.init()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(didPressCancel))
        title = NSLocalizedString("Import Asset", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Camera, target: self, action: #selector(didPressCamera))
        
        self.addArrangedChildViewController(assetSourcePicker)
        
        assetSourceViewController.sources = [
            PhotoLibraryAssetImportSource()
        ]
        
        let assetGroupViewController = AssetGroupViewController(assetImportSource: PhotoLibraryAssetImportSource())
        
        assetSourcePicker.viewControllers = [assetSourceViewController, assetGroupViewController]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didPressCamera() {
        let viewController = CameraViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc private func didPressCancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}