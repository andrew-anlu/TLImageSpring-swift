//
//  ViewController.swift
//  TLImageSpring
//
//  Created by Andrew on 12/30/2016.
//  Copyright (c) 2016 Andrew. All rights reserved.
//

import UIKit
import TLImageSpring

let screenWidth = UIScreen.main.bounds.width
let screenHeight = UIScreen.main.bounds.height

class ViewController: UIViewController {
    
    var tableView:CustomTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor.white
        
        let rect = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        tableView = CustomTableView(frame: rect, style: .plain)
        tableView.navigationController = self.navigationController
        self.view.addSubview(tableView)
        
    }


}

