//
//  ModelSelectionViewController.swift
//  OrigamiSensei
//
//  Created by James Chen on 10/27/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit

class ModelSelectionViewController: UIViewController {

//    @IBOutlet weak var dogImageView: UIImageView!
    @IBOutlet weak var oriModelStackView1: UIStackView!
    @IBOutlet weak var oriModelStackView2: UIStackView!
    @IBOutlet weak var oriModelStackView3: UIStackView!
    @IBOutlet weak var oriModelStackView4: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: - Do any additional setup after loading the view.
        // change section corner radius
        for subview in [oriModelStackView1,oriModelStackView2,oriModelStackView3,oriModelStackView4] {
            if let subStackView = subview {
                // Create a background view
                let backgroundView = UIView()
                backgroundView.backgroundColor = .white // Set your desired background color
                backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                backgroundView.layer.cornerRadius = 20
                backgroundView.clipsToBounds = true
                backgroundView.frame = subStackView.bounds
                
                // Insert the background view at the lowest index so it appears behind all other views
                subStackView.insertSubview(backgroundView, at: 0)
                
                // Optional: If the subStackView is not clipping to bounds
                subStackView.clipsToBounds = true
            }
        }
    }
    

    @IBAction func goBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    

    // MARK: - provide parameters for the Detection view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? VisionObjectDetectionViewController {
            switch segue.identifier {
            case "segueToDetectionCVFromDogButton":
                destinationVC.currentOriModel = "Dog"
            case "segueToDetectionCVFromCatButton":
                destinationVC.currentOriModel = "Cat"
            case "segueToDetectionCVFromWhaleButton":
                destinationVC.currentOriModel = "Whale"
            default:
                break
            }
            print("- Segue to '\(destinationVC.currentOriModel)' page")
        }
    }

}

// MARK: - RoundedImageView, helper class to set up cornerRadius
class RoundedImageView: UIImageView {
    /* Method 1: Two initializers are overridden:
        init(frame:) for programmatically created image views and
        init?(coder:) for image views loaded from a storyboard or XIB.
     */
//    override init(frame: CGRect) {
//            super.init(frame: frame)
//            setupRoundedCorners()
//        }
//
//        required init?(coder aDecoder: NSCoder) {
//            super.init(coder: aDecoder)
//            setupRoundedCorners()
//        }
//
//    private func setupRoundedCorners() {
////        self.layer.cornerRadius = 10
////        self.clipsToBounds = true
//        print("called setupRoundedCorners")
//    }
    
    // Method 2: change in layoutSubviews
    override func layoutSubviews() {
        super.layoutSubviews()
//        print("called layoutSubviews")
        self.layer.cornerRadius = 13
        self.clipsToBounds = true
        /*
        for performance optimization, especially if you have several rounded image views.
         This prevents the system from repeatedly re-rendering the UIImageView's layer, thereby making the scrolling much smoother
        */
        self.layer.masksToBounds = true
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }
}
