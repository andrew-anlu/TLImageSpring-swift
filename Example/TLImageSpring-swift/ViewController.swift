//
//  ViewController.swift
//  TLImageSpring-swift
//
//  Created by Andrew on 04/06/2016.
//  Copyright (c) 2016 Andrew. All rights reserved.
//

import UIKit
import TLImageSpring_swift


class ViewController: UIViewController {

    
    var downloadResult:DownloadIMGResult?
    var imgView:UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor=UIColor.whiteColor()
        self.navigationController?.delegate=self;
        // Do any additional setup after loading the view, typically from a nib.
        self.initView();
        
        print("hello world")
        
    }

    
    func initView(){
        var rect=CGRectMake(50, 100, 200, 40)
        let btn1=createBtn(rect, title: "在普通视图中加载图片")
        btn1.tag=1
        btn1.addTarget(self, action: Selector("tapAction:"), forControlEvents: .TouchUpInside)
        self.view .addSubview(btn1)
        
        rect=CGRectMake(50, CGRectGetMaxY(btn1.frame)+10, btn1.frame.size.width, 40)
        let btn2=createBtn(rect, title: "在表格中加载图片")
        btn2.tag=2
        btn2.addTarget(self, action: Selector("tapAction:"), forControlEvents: .TouchUpInside)
        self.view.addSubview(btn2)
        
        
        rect=CGRectMake(50, CGRectGetMaxY(btn2.frame)+10, btn1.frame.size.width, 40)
        let btn3=createBtn(rect, title: "在按钮上加载图片")
        btn3.tag=3
        btn3.addTarget(self, action: Selector("tapAction:"), forControlEvents: .TouchUpInside)
        self.view.addSubview(btn3)
        
        
    }
    
    
    func createBtn(rect:CGRect,title:String)->UIButton{
        let btn1=UIButton(frame: rect)
        btn1.setTitle(title, forState: .Normal)
        btn1.setTitleColor(UIColor.redColor(), forState: .Normal)
        btn1.backgroundColor=UIColor.yellowColor()
        
        return btn1
    }
    
   
    
   
    
    func test(){
        print("调用了")
        
        let download:TLImageSpringDownloader=TLImageSpringDownloader.STACICINSTANCE();
        
        let url=NSURL(string: "http://7xkxhx.com1.z0.glb.clouddn.com/QQ20151022-3.png");
        
        
       
            downloadResult = download.downloadImageWithURL(url!, progressBlock: { (receivedSize, totalSize) -> () in
                print("receivedSize:\(receivedSize),totalSize=\(totalSize)");
                }) { (image, error, imageURL, originalData) -> () in
                    
                    print("执行回调方法了 ");
                    if let error=error{
                        print("出错了\(error.localizedDescription)")
                    } else {
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.imgView!.image=image;
                        })
                        
                    }
                }!

        }
    
    func tapAction(sender:AnyObject){
      let btn=sender as! UIButton
        switch (btn.tag){
           case 1:
            let normalVc=NormalViewController()
            self.navigationController?.pushViewController(normalVc, animated: true)
            break
            
        case 2:
            let tableVc=TableController()
            self.navigationController?.pushViewController(tableVc, animated: true)
            break;
        case 3:
            let btnVc=ButtonViewController()
            self.navigationController?.pushViewController(btnVc, animated: true)
            break
            
        default:
            break;
            
        }
    }
   
}


extension UIViewController:UINavigationControllerDelegate{
    public func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool){
        if viewController is ViewController{
            for subview in (viewController.navigationController?.navigationBar.subviews)!{
            
                if subview is UIButton{
                  subview.removeFromSuperview()
                }
            }
        }
    }
}

