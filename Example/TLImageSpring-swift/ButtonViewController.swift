//
//  ButtonViewController.swift
//  TLImageSpring-swift
//
//  Created by Andrew on 16/4/14.
//  Copyright © 2016年 CocoaPods. All rights reserved.
//

import UIKit
import TLImageSpring_swift 

class ButtonViewController: UIViewController {

    var imgBtn:UIButton?
    
    var dowloadManager:TLImageSpringManager?
    
    private let imageURL:NSURL = NSURL(string: "http://www.bz55.com/uploads/allimg/130304/1-1303040Z528.jpg")!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor=UIColor.whiteColor()
        self.title="按钮加载图片"
        dowloadManager=TLImageSpringManager.sharedManager
        initView()
        
    }
    
    func initView(){
        imgBtn=UIButton(frame: CGRectMake(10, 10+64, 200, 200))
        imgBtn?.backgroundColor=UIColor.blueColor()
        self.view.addSubview(imgBtn!);
        
        var rect = CGRectMake(10, 300, 150, 40)
        let btn:UIButton=UIButton(frame: rect);
        btn.addTarget(self, action: #selector(ButtonViewController.testManager), forControlEvents: .TouchUpInside);
        btn.setTitle("用Manager下载", forState: .Normal);
        btn.setTitleColor(UIColor.redColor(), forState: .Normal);
        btn.backgroundColor=UIColor.yellowColor();
        self.view.addSubview(btn);
        
        //用UIImageView加载
        rect = CGRectMake(10, CGRectGetMaxY(btn.frame)+15, 200, 40)
        let btnLoadImgView=self.createBtn(rect, title: "用UIbutton加载")
        btnLoadImgView.addTarget(self, action: #selector(ButtonViewController.testButton), forControlEvents: .TouchUpInside)
        btnLoadImgView.sizeToFit()
        self.view .addSubview(btnLoadImgView)
        
        //取消下载
        rect = CGRectMake(10, CGRectGetMaxY(btnLoadImgView.frame)+15, 200, 40)
        let cancelBtn=self.createBtn(rect, title: "取消下载")
        cancelBtn.addTarget(self, action: #selector(ButtonViewController.cancelDownload), forControlEvents: .TouchUpInside);
        self.view.addSubview(cancelBtn)
        
        
        rect=CGRectMake(CGRectGetMaxX(btn.frame)+20, 300, btn.frame.size.width, btn.frame.size.height);
        let clearBtn=UIButton(frame: rect);
        clearBtn.addTarget(self, action: #selector(ButtonViewController.clearAction), forControlEvents: .TouchUpInside)
        clearBtn.backgroundColor=UIColor.yellowColor()
        clearBtn .setTitle("从内存中清空", forState: .Normal);
        clearBtn.setTitleColor(UIColor.redColor(), forState: .Normal)
        self.view.addSubview(clearBtn)
    }
    
    /**
     从内存清空
     */
    func clearAction(){
        imgBtn?.setImage(nil, forState: .Normal)
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
                        self.imgBtn?.setImage(image, forState: .Normal)
                    })
                    
                }
        }
    }
    
    
    /**
     取消下载
     */
    func cancelDownload(){
        
    }
    
 
    
    func testButton(){
        
        self.imgBtn?.TL_setImageWithURL(imageURL, forstate: .Normal, placeHolderImage: UIImage(named: "placeholder"))
    }
    
    func createBtn(rect:CGRect,title:String)->UIButton{
        let btn1=UIButton(frame: rect)
        btn1.setTitle(title, forState: .Normal)
        btn1.setTitleColor(UIColor.redColor(), forState: .Normal)
        btn1.backgroundColor=UIColor.yellowColor()
        
        return btn1
    }


}
