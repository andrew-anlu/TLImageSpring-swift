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
    
    private let imageURL:NSURL = NSURL(string: "http://7xkxhx.com1.z0.glb.clouddn.com/IMG_5853.jpg")!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor=UIColor.whiteColor()
        self.title="普通视图中"
        dowloadManager=TLImageSpringManager.sharedManager
        initView()

    }
  
    func initView(){
        imgView=UIImageView(frame: CGRectMake(10, 10+64, 200, 200))
        imgView?.backgroundColor=UIColor.whiteColor()
        self.view.addSubview(imgView!);
        
        var rect = CGRectMake(10, 300, 150, 40)
        let btn:UIButton=UIButton(frame: rect);
        btn.addTarget(self, action: Selector("testManager"), forControlEvents: .TouchUpInside);
        btn.setTitle("用Manager下载", forState: .Normal);
        btn.setTitleColor(UIColor.redColor(), forState: .Normal);
        btn.backgroundColor=UIColor.yellowColor();
        self.view.addSubview(btn);
        
        //用UIImageView加载
        rect = CGRectMake(10, CGRectGetMaxY(btn.frame)+15, 200, 40)
        let btnLoadImgView=self.createBtn(rect, title: "用UIImageView加载")
        btnLoadImgView.addTarget(self, action: Selector("testUIImageview"), forControlEvents: .TouchUpInside)
        btnLoadImgView.sizeToFit()
        self.view .addSubview(btnLoadImgView)
        
        //取消下载
        rect = CGRectMake(10, CGRectGetMaxY(btnLoadImgView.frame)+15, 200, 40)
        let cancelBtn=self.createBtn(rect, title: "取消下载")
        cancelBtn.addTarget(self, action: Selector("cancelDownload"), forControlEvents: .TouchUpInside);
        self.view.addSubview(cancelBtn)
        
        
        rect=CGRectMake(CGRectGetMaxX(btn.frame)+20, 300, btn.frame.size.width, btn.frame.size.height);
        let clearBtn=UIButton(frame: rect);
        clearBtn.addTarget(self, action: Selector("clearAction"), forControlEvents: .TouchUpInside)
        clearBtn.backgroundColor=UIColor.yellowColor()
        clearBtn .setTitle("从内存中清空", forState: .Normal);
        clearBtn.setTitleColor(UIColor.redColor(), forState: .Normal)
        self.view.addSubview(clearBtn)
        
    }
    
    /**
     从内存清空
     */
    func clearAction(){
        imgView?.image=nil;
        
        dowloadManager?.cache.removeImageForkey(imageURL.absoluteString);
        
    }
    
    /**
     取消下载
     */
    func cancelDownload(){
     self.imgView?.TL_cancelDownloadTask()
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
        
       
       
//        self.imgView?.TL_setImageWithURL(imageURL, placeholderImage: UIImage(named: "placeholder"));
        
        self.imgView?.TL_setImageWithURL(imageURL, placeholderImage: UIImage(named: "placeholder"), options: nil, progrocessBlock: nil, completionHander: { (image, error, cacheType, imageUrl) in
            print("下载完毕了")
            self.imgView?.frame = CGRectMake(0, 0, image!.size.width, image!.size.height)
        })
        
    }
    
    func createBtn(rect:CGRect,title:String)->UIButton{
        let btn1=UIButton(frame: rect)
        btn1.setTitle(title, forState: .Normal)
        btn1.setTitleColor(UIColor.redColor(), forState: .Normal)
        btn1.backgroundColor=UIColor.yellowColor()
        
        return btn1
    }

}
