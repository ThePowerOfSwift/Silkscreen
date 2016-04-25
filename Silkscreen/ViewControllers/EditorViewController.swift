//
//  EditorViewController.swift
//  Silkscreen
//
//  Created by James Campbell on 4/22/16.
//  Copyright © 2016 SK. All rights reserved.
//

import UIKit

class EditorViewController: DividableViewController {
    
    let editorContext = EditorContext()
    
    lazy var contentAreaViewController: DividableViewController = {
        let viewController = DividableViewController(arrangedSubviewControllers: [self.assetsNavigationController, self.previewViewController])
        viewController.axis = .Horizontal
        return viewController
    }()
    
    lazy var assetsNavigationController: UINavigationController = {
        return UINavigationController(rootViewController: self.assetViewController)
    }()
    
    let assetViewController = AssetsViewController()
    
    let previewViewController = PreviewViewController()
    
    let timelineViewController = TimelineViewController()
    
    init() {
        super.init()
        
        title = NSLocalizedString("Untitled Project", comment: "")

        addArrangedChildViewController(contentAreaViewController)
        addArrangedChildViewController(timelineViewController)
        
        contentAreaViewController.view.heightAnchor.constraintEqualToAnchor(view.heightAnchor, multiplier: 0.45, constant: 0.0).active = true
        assetsNavigationController.view.widthAnchor.constraintEqualToAnchor(view.widthAnchor, multiplier: 0.5, constant: 0.0).active = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        previewViewController.editorContext = editorContext
        timelineViewController.editorContext = editorContext
    }
}