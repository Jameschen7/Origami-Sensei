//
//  WelcomeViewController.swift
//  OrigamiSensei
//
//  Created by James Chen on 10/5/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
    @IBAction func startButton1Tapped(_ sender: UIButton) {
        print("sender.tag", sender.tag)
        performSegue(withIdentifier: "startCameraSegue", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
