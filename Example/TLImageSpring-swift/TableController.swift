//
//  TableController.swift
//  TLImageSpring-swift
//
//  Created by Andrew on 16/4/14.
//  Copyright © 2016年 CocoaPods. All rights reserved.
//

import UIKit
import TLImageSpring_swift

class TableController: UIViewController {
    
    private var arrayData:NSMutableArray!
    var tableview:UITableView?
    
    var clearBtn:UIButton!
    var reloadBtn:UIButton!
    
    var downloadManager:TLImageSpringManager!
    
    private var SCREENT_WIDTH = UIScreen.mainScreen().bounds.width
    private var SCREENT_HEIGHT = UIScreen.mainScreen().bounds.height
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor=UIColor.whiteColor()
        
        downloadManager = TLImageSpringManager.sharedManager
        
        initData()
        initTableview()
        initView()
    }
    
    func initView(){
        var rect=CGRectMake(SCREENT_WIDTH-100, 5, 100, 30)
        if clearBtn==nil{
            clearBtn=self.createBtn(rect, title: "从内存清空")
            clearBtn.addTarget(self, action: Selector("clearAction"), forControlEvents: .TouchUpInside)
            self.navigationController?.navigationBar.addSubview(clearBtn)
        }
       
        
        if reloadBtn==nil{
            rect=CGRectMake(CGRectGetMinX(clearBtn.frame)-100, clearBtn.frame.origin.y, 100, 30)
            reloadBtn=self.createBtn(rect, title: "重新加载")
            reloadBtn.addTarget(self, action: Selector("reload"), forControlEvents: .TouchUpInside)
            self.navigationController?.navigationBar.addSubview(reloadBtn)
        }
        

    }
    
    func createBtn(rect:CGRect,title:String)->UIButton{
        let btn1=UIButton(frame: rect)
        btn1.setTitle(title, forState: .Normal)
        btn1.setTitleColor(UIColor.redColor(), forState: .Normal)
        
        return btn1
    }
    func initData(){
        
        arrayData=NSMutableArray()
        
        arrayData=[
            ["name":"张三",
            "url":"http://7xkxhx.com1.z0.glb.clouddn.com/1432799466416554.jpeg"],
            ["name":"张三",
                "url":"http://7xkxhx.com1.z0.glb.clouddn.com/QQ20151012-0.png"],
            ["name":"张三",
                "url":"http://7xkxhx.com1.z0.glb.clouddn.com/QQ20151022-0.png"],
            ["name":"张三",
                "url":"http://7xkxhx.com1.z0.glb.clouddn.com/QQ20151022-1.png"],
            ["name":"张三",
                "url":"http://7xkxhx.com1.z0.glb.clouddn.com/QQ20151022-3.png"],
            ["name":"张三",
                "url":"http://7xkxhx.com1.z0.glb.clouddn.com/QQ20151022-6.png"],
            ["name":"张三",
                "url":"http://7xkxhx.com1.z0.glb.clouddn.com/QQ20151022-7.png"],
            ["name":"张三",
                "url":"http://7xkxhx.com1.z0.glb.clouddn.com/QQ20151022-6.png"],
            ["name":"张三",
                "url":"http://7xkxhx.com1.z0.glb.clouddn.com/QQ20160303-0.png"],
            ["name":"张三",
                "url":"http://7xkxhx.com1.z0.glb.clouddn.com/IMG_5853.jpg"],
            ["name":"张三",
                "url":"http://7xkxhx.com1.z0.glb.clouddn.com/1432799466416554.jpeg"]
        
        ]
        
    }
    
    func initTableview(){
        tableview=UITableView(frame: CGRectMake(0, 64, SCREENT_WIDTH, SCREENT_HEIGHT-64))
        tableview?.delegate=self;
        tableview?.dataSource=self;
        self.view.addSubview(tableview!)
    }
    

}

extension TableController:UITableViewDataSource,UITableViewDelegate{

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identity="identity"
        var cell=tableview?.dequeueReusableCellWithIdentifier(identity) as? TableViewCell
        
        if cell==nil{
            cell=TableViewCell(style: .Default, reuseIdentifier: identity)
        }
        
        if let dict = arrayData[indexPath.row] as? NSDictionary{
            cell?.setDataSource(dict)
        }
        
        return cell!
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 220
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayData.count
    }
    
    
    //MARK: - 清空
    func clearAction(){
        arrayData.removeAllObjects()
        self.tableview?.reloadData()
        downloadManager.cache.clearMemory()
        downloadManager.cache.clearDiskOnCompletion(nil)
    }
    
    func reload(){
        initData();
        self.tableview?.reloadData()
    }

   
}
