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
        // Do any additional setup after loading the view, typically from a nib.
        self.initView();
        
        print("hello world")
        
    }

    
    func initView(){
        imgView=UIImageView(frame: CGRectMake(10, 10, 200, 200))
        imgView?.backgroundColor=UIColor.yellowColor()
        self.view.addSubview(imgView!);
        
        var rect = CGRectMake(10, 300, 100, 40)
        let btn:UIButton=UIButton(frame: rect);
        btn.addTarget(self, action: Selector("test"), forControlEvents: .TouchUpInside);
        btn.setTitle("try", forState: .Normal);
        btn.setTitleColor(UIColor.redColor(), forState: .Normal);
        btn.backgroundColor=UIColor.yellowColor();
        self.view.addSubview(btn);
        
        rect=CGRectMake(CGRectGetMaxX(btn.frame)+20, 300, btn.frame.size.width, btn.frame.size.height);
        let clearBtn=UIButton(frame: rect);
        clearBtn.addTarget(self, action: Selector("clearAction"), forControlEvents: .TouchUpInside)
        clearBtn.backgroundColor=UIColor.yellowColor()
        clearBtn .setTitle("clear", forState: .Normal);
        clearBtn.setTitleColor(UIColor.redColor(), forState: .Normal)
        self.view.addSubview(clearBtn)
    }
    
    func clearAction(){
        imgView?.image=nil;
    }
    
    func test(){
        print("调用了")
        
        let download:TLImageSpringDownloader=TLImageSpringDownloader();
        
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
   

}

