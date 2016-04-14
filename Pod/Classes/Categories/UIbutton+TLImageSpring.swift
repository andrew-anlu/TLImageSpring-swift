//
//  UIbutton+TLImageSpring.swift
//  Pods
//
//  Created by Andrew on 16/4/6.
//
//

import Foundation

extension UIButton{
    
    /**
     设置按钮的图片服务器地址
     
     - parameter param: 结构体，封装了缓存key和服务器地址
     - parameter state: 按钮的状态
     
     - returns:自定义的检索图片的类
     */
    public func TL_setImageWithParam(param:TLParam,forstate state:UIControlState) -> RetrieveImageTask?{
        return TL_setImageWithParam(param, forState: state, placeHolderImage: nil, options: nil, progressBlock: nil, completionHander: nil)
    }
    /**
      设置按钮的图片服务器地址
     
     - parameter URL:   图片的服务器地址
     - parameter state: 按钮的状态
     
     - returns:自定义的检索图片的类
     */
    public func TL_setImageWithURL(URL:NSURL,forstate state:UIControlState) -> RetrieveImageTask?{
      return TL_setImageWithParam(TLParam(downloadURL: URL), forState: state, placeHolderImage: nil, options: nil, progressBlock: nil, completionHander: nil)
    }
    /**
     设置按钮的图片服务器地址，没有加载完成之后用一个占位符图片展示

     
     - parameter URL:              图片的服务器地址
     - parameter state:            按钮的状态
     - parameter placeHolderImage: 占位符图片
     
     - returns:自定义的检索图片的类
     */
    public func TL_setImageWithURL(URL:NSURL,forstate state:UIControlState,placeHolderImage:UIImage?)->RetrieveImageTask?{
     return TL_setImageWithParam(TLParam(downloadURL: URL), forState: state, placeHolderImage: placeHolderImage, options: nil, progressBlock: nil, completionHander: nil)
    }
    
    /**
     设置按钮的图片服务器地址，没有加载完成之后用一个占位符图片展示
     
     - parameter URL:              图片的服务器地址
     - parameter state:            按钮的状态
     - parameter placeHolderImage: 占位符图片
     - parameter options:          下载策略
     
     - returns: 自定义的检索图片的类
     */
    public func TL_setImageWithURL(URL:NSURL,
        forstate state:UIControlState,
        placeHolderImage:UIImage?,
        options:TLImgDownloadOpions?)->RetrieveImageTask?{
     return TL_setImageWithParam(TLParam(downloadURL: URL), forState: state, placeHolderImage: placeHolderImage, options: options, progressBlock: nil, completionHander: nil)
    }
    
    /**
      设置按钮的图片服务器地址，没有加载完成之后用一个占位符图片展示
     
     - parameter URL:              图片的服务器地址
     - parameter state:            按钮的状态
     - parameter placeHolderImage: 占位符图片
     - parameter options:          下载策略
     - parameter completionHander: 完成的回调函数
     
     - returns: 自定义的检索图片的类
     */
    public func TL_setImageWithURL(URL:NSURL,
        forstate state:UIControlState,
        placeHolderImage:UIImage?,
        options:TLImgDownloadOpions?,
        completionHander:TLImgSpringCompleteBlock?) ->RetrieveImageTask?{
            
            return TL_setImageWithParam(TLParam(downloadURL: URL), forState: state, placeHolderImage: placeHolderImage, options: options, progressBlock: nil, completionHander: completionHander);
    }
    
    /**
     设置按钮的图片服务器地址，没有加载完成之后用一个占位符图片展示
     
     - parameter URL:              图片的服务器地址
     - parameter state:            按钮的状态
     - parameter placeHolderImage: 占位符图片
     - parameter options:          下载策略
     - parameter progressBlock:    进度条回调函数
     - parameter completionHander: 完成的回调函数
     
     - returns: 自定义的检索图片的类
     */
    public func TL_setImageWithURL(URL:NSURL,
        forstate state:UIControlState,
        placeHolderImage:UIImage?,
        options:TLImgDownloadOpions?,
        progressBlock:TLImgSpringDownloadProgressBlock?,
        completionHander:TLImgSpringCompleteBlock?) ->RetrieveImageTask?{
            
            return TL_setImageWithParam(TLParam(downloadURL: URL), forState: state, placeHolderImage: placeHolderImage, options: options, progressBlock: progressBlock, completionHander: completionHander);
    }

    /**
     设置按钮的图片服务器地址，没有加载完成之后用一个占位符图片展示
     
     - parameter param:            自定义的结构体
     - parameter state:            按钮的状态
     - parameter placeHolderImage: 占位符图片
     - parameter options:          下载策略
     - parameter progressBlock:    进度条回调函数
     - parameter completionHander: 下载完成的回调函数
     
     - returns: 自定义的检索图片的类
     */
    public func TL_setImageWithParam(param:TLParam,
        forState state:UIControlState,
        placeHolderImage:UIImage?,
        options:TLImgDownloadOpions?,
        progressBlock:TLImgSpringDownloadProgressBlock?,
        completionHander:TLImgSpringCompleteBlock?)->RetrieveImageTask?{
    
            setImage(placeHolderImage, forState: state)
            
            tl_setWebURL(param.downloadURL, forstate: state)
            let task = TLImageSpringManager.sharedManager.downloadImageWithParam(param, progressBlock: { (receivedSize, totalSize) -> () in
                if let progressBlock = progressBlock{
                    progressBlock(receivedSize: receivedSize, totalSize: totalSize)
                }
                }, completionHanlder: {[weak self] image, error, cacheType, imageUrl  in
                    
                    TLThreadUtils.shardThreadUtil.disAsyncMainThread({ () -> () in
                        if let weakSelf=self{
                          weakSelf.tl_setImageTask(nil)
                             if imageUrl == weakSelf.tl_webURLForState(state) && image != nil{
                              weakSelf.setImage(image, forState: state)
                            }
                        }
                        completionHander?(image: image, error: error, cacheType: cacheType, imageUrl: imageUrl);
                    })
                    
                }, options: options)
            
            tl_setImageTask(task)
            return task
    }
    
    
    
    //MARK: - 取消正在下载的任务
    public func TL_cancelDownloadTask(){
     tl_imageTask?.downloadTask?.cancel()
    }
    
    
}


private var tlURLKEY : Void?
private var tlIMGTaskKEY:Void?

extension UIButton{
    private var tl_webUrls:NSMutableDictionary{
      var dictionary = objc_getAssociatedObject(self, &tlURLKEY) as? NSMutableDictionary
        if dictionary == nil{
          dictionary=NSMutableDictionary()
          tl_setWebUrls(dictionary!)
        }
      return dictionary!
    }
    
    private func tl_setWebUrls(URLS:NSMutableDictionary){
      objc_setAssociatedObject(self, &tlURLKEY, URLS, .OBJC_ASSOCIATION_RETAIN)
    }
    
    private var tl_imageTask:RetrieveImageTask?{
      return objc_getAssociatedObject(self, &tlIMGTaskKEY) as? RetrieveImageTask
    }
    
    private func tl_setImageTask(task:RetrieveImageTask?){
      objc_setAssociatedObject(self, &tlIMGTaskKEY, task, .OBJC_ASSOCIATION_RETAIN)
    }
    
    public func tl_webURLForState(state:UIControlState) -> NSURL?{
        return tl_webUrls[NSNumber(unsignedLong:state.rawValue)] as? NSURL
    }
    
    private func tl_setWebURL(URL:NSURL,forstate state:UIControlState){
      tl_webUrls[NSNumber(unsignedLong: state.rawValue)] = URL
    }
    
    
}
