//
//  DividableViewController.swift
//  Silkscreen
//
//  Created by James Campbell on 18/01/2016.
//  Copyright © 2016 SK. All rights reserved.
//

#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#endif

class DividableViewController: UIViewController {
  
  //TODO: Alias to remove need
  #if os(iOS) || os(watchOS) || os(tvOS)
    private let stackView = UIStackView(arrangedSubviews: [])
  #else
    fileprivate let stackView = UIStackView(views: [])
  #endif
  
    fileprivate let arrangedSubviewControllers: [UIViewController]
    
    var axis: UILayoutConstraintAxis = .vertical {
        didSet {
            updateStackViewProperties()
        }
    }

    init(arrangedSubviewControllers: [UIViewController] = []) {
        
        self.arrangedSubviewControllers = arrangedSubviewControllers
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        arrangedSubviewControllers.forEach(addArrangedChildViewController)
        updateStackViewProperties()
        view = stackView
    }
  
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.setNeedsLayout()
    }
    
    func addArrangedChildViewController(_ viewController: UIViewController) {
        
        viewController.beginAppearanceTransition(true, animated: false)
        viewController.willMove(toParentViewController: self)
        addChildViewController(viewController)
        stackView.addArrangedSubview(viewController.view)
        viewController.endAppearanceTransition()
    }
    
    fileprivate func updateStackViewProperties() {
      
      //TODO: Export this properties to be compatiable with UI notation
        // stackView.axis = axis
        stackView.distribution = .fill
       // stackView.alignment = .Fill
    }
}
