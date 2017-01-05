//
//  ViewController.swift
//  TLImageSpring
//
//  Created by Andrew on 12/30/2016.
//  Copyright (c) 2016 Andrew. All rights reserved.
//

import UIKit
import TLImageSpring

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let s = Spring()
        s.HelloWorld()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

