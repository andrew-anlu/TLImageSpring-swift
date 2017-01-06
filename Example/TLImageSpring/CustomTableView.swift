//
//  CustomTableView.swift
//  TLImageSpring
//
//  Created by Andrew on 2017/1/6.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit

class CustomTableView: UITableView,UITableViewDelegate,UITableViewDataSource {

    var arrayData = ["Normal loading style"]
    
   public var navigationController:UINavigationController?
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        
    self.delegate = self
        self.dataSource = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayData.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        if cell == nil{
          cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        }
        
        cell?.textLabel?.text = arrayData[indexPath.item]
        cell?.accessoryType = .disclosureIndicator
        return cell!
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let normalVc = NormalController()
        self.navigationController?.pushViewController(normalVc, animated: true)
    }

}
