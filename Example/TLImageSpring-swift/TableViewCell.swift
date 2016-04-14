//
//  TableViewCell.swift
//  TLImageSpring-swift
//
//  Created by Andrew on 16/4/14.
//  Copyright © 2016年 CocoaPods. All rights reserved.
//

import UIKit
import TLImageSpring_swift

public class TableViewCell: UITableViewCell {
    private var SCREENT_WIDTH = UIScreen.mainScreen().bounds.width
    private var SCREENT_HEIGHT = UIScreen.mainScreen().bounds.height
     var imgView:UIImageView?
     var namelb:UILabel?
    
    override  init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        imgView=UIImageView(frame: CGRectMake(SCREENT_WIDTH-210, 10, 200, 200))
        self.addSubview(imgView!)
        
        namelb=UILabel(frame: CGRectMake(10, 10, 100, 20));
        self.addSubview(namelb!)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
  
   


    override public func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
   

}

extension TableViewCell{
    public func setDataSource(source:NSDictionary){
        
        guard let name=source["name"] else{
            return
        }
        
        guard let imgUrl = source["url"] as? String else{
            return
        }
        
        namelb?.text=name as? String
        
        let placeImg=UIImage(named: "placeholder")
        self.imgView?.TL_setImageWithURL(NSURL(string: imgUrl)!, placeholderImage: placeImg)
        
        let url=NSURL(string: imgUrl)
        self.imgView?.TL_setImageURLWithParam(TLParam(downloadURL: url!), placeHolderImage: placeImg)
        
        /**
        * 
        case  ForceRefresh = 100
        case  CacheMemoryOnly = 101
        case  BackgroundDecode = 102
        case  PlaceholdImage=103
        case  ProgressDownload=104
        case  RetryFailed=105
        case  LowPriority=106
        case  HighPriority=107
        */
        self.imgView?.TL_setImageWithURL(url!, placeholderImage: placeImg, options: .CacheMemoryOnly)
        
        self.imgView?.TL_setImageWithURL(url!, placeholderImage: placeImg, options: .CacheMemoryOnly, progrocessBlock: { (receivedSize, totalSize) -> () in
            
              print("接收到的:\(receivedSize),总共:\(totalSize)");
            }, completionHander: { (image, error, cacheType, imageUrl) -> () in
                //成功的处理函数
        })
        
        self.imgView?.TL_setImageWithURL(url!, placeHolderImage: placeImg, options: .CacheMemoryOnly, style: .Gray)
        
        self.imgView?.TL_cancelDownloadTask()
    }
}


