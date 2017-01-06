//
//  NormalController.swift
//  TLImageSpring
//
//  Created by Andrew on 2017/1/6.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit
import TLImageSpring

class NormalController: UIViewController {
    
    var imageView:UIImageView!
    
    var task:RetrieveImageTask?
    
    var manager:TLImageSpringManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white

        initView()
        
        initManager()
    }
    
    func initManager() -> Void {
        manager = TLImageSpringManager.sharedManager
    }
    
    
    func initView() -> Void {
        
        var rect = CGRect(x: 20, y: 70, width: 100, height: 30)
        let btn1 = UIButton(frame: rect)
        btn1.setTitle("加载方式1", for: .normal)
        btn1.setTitleColor(UIColor.red, for: .normal)
        self.view.addSubview(btn1)
        
        btn1.addTarget(self, action: #selector(loadingStyle1(btn:)), for: .touchUpInside)
        
        
        rect = CGRect(x: btn1.frame.maxX+20, y: 70, width: 100, height: 30)
        let btn2 = UIButton(frame: rect)
        btn2.setTitle("加载方式2", for: .normal)
        btn2.setTitleColor(UIColor.red, for: .normal)
        self.view.addSubview(btn2)
        
        btn2.addTarget(self, action: #selector(loadingStyle2(btn:)), for: .touchUpInside)
        
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 200, width: 200, height: 200))
        self.view.addSubview(imageView)
        
        
        rect = CGRect(x: 20, y: btn1.frame.maxY+10, width: 100, height: 30)
        let clearBtn = UIButton(frame: rect)
        clearBtn.setTitleColor(UIColor.blue, for: .normal)
        clearBtn.setTitle("清空图片", for: .normal)
        self.view.addSubview(clearBtn)
        
        clearBtn.addTarget(self, action: #selector(clearPicture(btn:) ), for: .touchUpInside)
    }
    
    //MARK: - Helper methods
    
    func loadingStyle1(btn:UIButton) -> Void {
        
        let url = URL(string: "https://koenig-media.raywenderlich.com/uploads/2015/07/starter_screenshots1.png")!
        
        let placeImg = UIImage(named: "sea")!
        
   
        imageView.tl.setImage(with: url, placeholderImage: placeImg)
//        task.cancel()
    }
    
    func loadingStyle2(btn:UIButton) -> Void {
        let url = URL(string: "https://koenig-media.raywenderlich.com/uploads/2015/07/starter_screenshots1.png")!
        
    
       imageView.tl.setImage(with: url, placeholderImage: nil, options: nil, progrocessBlock: nil) { (image, error, type, url) in
        
        DispatchQueue.main.async {
            self.imageView.image = image
            
         }
        }
    }
    
    
    func stopLoading(btn:UIButton) -> Void {
        task?.cancel()
    }
    
    func clearPicture(btn:UIButton) -> Void {
        manager?.cache.clearMemory()
        imageView.image = nil
    }



}
