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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func goBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)

    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

class RoundedImageView: UIImageView {
    // MARK: - Initializers
    /* Two initializers are overridden:
        init(frame:) for programmatically created image views and
        init?(coder:) for image views loaded from a storyboard or XIB.
     */
    override init(frame: CGRect) {
            super.init(frame: frame)
            setupRoundedCorners()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setupRoundedCorners()
        }
    
    // MARK: - Setup Rounded Corners
    private func setupRoundedCorners() {
        self.layer.cornerRadius = 30
        self.clipsToBounds = true
        print("called setupRoundedCorners")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        print("called layoutSubviews")
        /*
        for performance optimization, especially if you have several rounded image views.
         This prevents the system from repeatedly re-rendering the UIImageView's layer, thereby making the scrolling much smoother
        */
        self.layer.masksToBounds = true
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }
}
