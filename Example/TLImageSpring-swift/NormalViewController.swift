//
//  NormalViewController.swift
//  TLImageSpring-swift
//
//  Created by Andrew on 16/4/13.
//  Copyright © 2016年 CocoaPods. All rights reserved.
//

import UIKit
import TLImageSpring_swift

class NormalViewController: UIViewController {
    var downloadResult:DownloadIMGResult?
    var imgView:UIImageView?
    
    var dowloadManager:TLImageSpringManager?
    
    private let imageURL:NSURL = NSURL(string: "http://7xkxhx.com1.z0.glb.clouddn.com/QQ20151022-3.png")!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor=UIColor.whiteColor()
        dowloadManager=TLImageSpringManager.sharedManager
        initView()

    }

  
    func initView(){
        imgView=UIImageView(frame: CGRectMake(10, 10+64, 200, 200))
        imgView?.backgroundColor=UIColor.yellowColor()
        self.view.addSubview(imgView!);
        
        var rect = CGRectMake(10, 300, 100, 40)
        let btn:UIButton=UIButton(frame: rect);
        btn.addTarget(self, action: Selector("testManager"), forControlEvents: .TouchUpInside);
        btn.setTitle("用Manager下载", forState: .Normal);
        btn.setTitleColor(UIColor.redColor(), forState: .Normal);
        btn.backgroundColor=UIColor.yellowColor();
        self.view.addSubview(btn);
        
        rect = CGRectMake(10, CGRectGetMaxY(btn.frame)+15, 100, 40)
        let btnLoadImgView=self.createBtn(rect, title: "用UIImageView加载")
        btnLoadImgView.addTarget(self, action: Selector("testUIImageview"), forControlEvents: .TouchUpInside)
        btnLoadImgView.sizeToFit()
        self.view .addSubview(btnLoadImgView)
        
        rect=CGRectMake(CGRectGetMaxX(btn.frame)+20, 300, btn.frame.size.width, btn.frame.size.height);
        let clearBtn=UIButton(frame: rect);
        clearBtn.addTarget(self, action: Selector("clearAction"), forControlEvents: .TouchUpInside)
        clearBtn.backgroundColor=UIColor.yellowColor()
        clearBtn .setTitle("从内存中清空", forState: .Normal);
        clearBtn.setTitleColor(UIColor.redColor(), forState: .Normal)
        self.view.addSubview(clearBtn)
        
        
    }
    
    func clearAction(){
        imgView?.image=nil;
        
        dowloadManager?.cache.removeImageForkey(imageURL.absoluteString);
        
    }
    
    func testManager(){
        
        let manager=TLImageSpringManager.sharedManager;
        manager.downloadImageWithURL(imageURL, options: TLImgDownloadOpions.BackgroundDecode, progoressBlock: { (receivedSize, totalSize) -> () in
            
            }) { (image, error, cacheType, imageUrl) -> () in
                if let error=error{
                    print("出错了\(error.localizedDescription)")
                } else {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.imgView!.image=image;
                    })
                    
                }
        }
    }
    
    func testUIImageview(){
        
       
       
        self.imgView?.TL_setImageWithURL(imageURL, placeholderImage: UIImage(named: "placeholder"));
    }
    
    func createBtn(rect:CGRect,title:String)->UIButton{
        let btn1=UIButton(frame: rect)
        btn1.setTitle(title, forState: .Normal)
        btn1.setTitleColor(UIColor.redColor(), forState: .Normal)
        btn1.backgroundColor=UIColor.yellowColor()
        
        return btn1
    }

}
