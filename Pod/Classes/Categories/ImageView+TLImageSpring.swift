//
//  ImageView+TLImageSpring.swift
//  Pods
//
//  Created by Andrew on 16/4/6.
//
//

import Foundation

/// 存储图片对应的服务器var址的key
private var tlImageRuntimeKey:Void?
/// 存储自定义下载的RetrieveImageTask的key
private var tlImageTaskKey:Void?

public extension UIImageView{

    /// 获取运行时的下载任务的检索图片的类
    private var TL_imageTask : RetrieveImageTask?{
       return objc_getAssociatedObject(self, &tlImageTaskKey) as? RetrieveImageTask
    }
    
    /**
     设置运行时检索图片的类
     - parameter task: 检索图片的类
     */
    private func TL_setImageTask(task : RetrieveImageTask?){
      objc_setAssociatedObject(self, &tlImageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    /// 获取运行时图片的服务器地址
    private var TL_imageWithURL:NSURL?{
       return objc_getAssociatedObject(self, &tlImageRuntimeKey) as? NSURL
    }
    /**
     设置运行时图片的服务器地址
     
     - parameter URL: 图片服务器地址
     */
    private func TL_setImageWithURL(URL:NSURL?){
      objc_setAssociatedObject(self, &tlImageRuntimeKey, URL, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
  
    
    /**
     设置图片的URL地址和缓存的key,如果没有设置该key,则默认为URL字符串，没下载完成的时候用一个占位符图片顶替
     
     - parameter param:            结构体，封装了缓存的key和URL地址
     - parameter placeHolderImage: 占位符图片
     
     - returns: 检索图片的类
     */
    public func TL_setImageURLWithParam(var param:TLParam,placeHolderImage:UIImage?)->RetrieveImageTask{
 
        if param.cacheKey == nil{
            param.cacheKey = param.downloadURL.absoluteString
        }
        
      return TL_setImageWithParam(param,
        placeHolderImage: placeHolderImage,
        options: nil,
        progressBlock: nil,
        completionHander: nil)
    }
    
    /**
     设置图片的URL地址，没下载完成的时候用一个占位符图片顶替
     
     - parameter URL:              图片的服务器地址
     - parameter placeholderImage: 占位符图片
     - parameter options:          下载策略
     - parameter progrocessBlock:  进度条的回调函数
     - parameter completionHander: 下载完成的回调函数
     
     - returns: 检索图片的类
     */
    public func TL_setImageWithURL(URL:NSURL,
        placeholderImage:UIImage?,
        options:TLImgDownloadOpions?,
        progrocessBlock:TLImgSpringDownloadProgressBlock?,
        completionHander:TLImgSpringCompleteBlock?) ->RetrieveImageTask{
            
            let param=TLParam(cacheKey: URL.absoluteString, downloadURL: URL)
            
            return TL_setImageWithParam(param, placeHolderImage: placeholderImage, options: options, progressBlock: progrocessBlock, completionHander: completionHander);
    }
    /**
     设置图片的URL地址，没下载完成的时候用一个占位符图片顶替
     
     - parameter URL:              图片的URL地址
     - parameter placeholderImage: 占位符图片
     
     - returns: 检索图片的类
     */
    public func TL_setImageWithURL(URL:NSURL,placeholderImage:UIImage?,options:TLImgDownloadOpions?)->RetrieveImageTask{
        
        let param=TLParam(cacheKey: URL.absoluteString, downloadURL: URL)
        
        return TL_setImageWithParam(param, placeHolderImage: placeholderImage, options: options, progressBlock: nil, completionHander: nil)
    }
   
    /**
     设置图片的URL地址，没下载完成的时候用一个占位符图片顶替
     
     - parameter URL:              图片的服务器地址
     - parameter placeholderImage: 占位符图片
     
     - returns: 检索图片的类
     */
    public func TL_setImageWithURL(URL:NSURL,placeholderImage:UIImage?)->RetrieveImageTask{
        
        return TL_setImageWithParam(TLParam(downloadURL: URL), placeHolderImage: placeholderImage, options: nil, progressBlock: nil, completionHander: nil)
    }
    /**
     设置图片的URL地址，没下载完成的时候用一个占位符图片顶替
     
     - parameter param:            一个参数结构，封装了缓存key和下载的服务器地址
     - parameter placeHolderImage: 占位符图案品
     - parameter options:          下载策略
     - parameter progressBlock:    进度条的回调函数
     - parameter completionHander: 下载完成的回调函数
     
     - returns: 检索图片的类
     */
    public func TL_setImageWithParam(param:TLParam,
        placeHolderImage:UIImage?,
        options:TLImgDownloadOpions?,
        progressBlock:TLImgSpringDownloadProgressBlock?,
        completionHander:TLImgSpringCompleteBlock?)->RetrieveImageTask{
    
            //把图片的服务器地址绑定到运行时
            TL_setImageWithURL(param.downloadURL)
            
            image=placeHolderImage
            
            let task=TLImageSpringManager.sharedManager.downloadImageWithParam(param, progressBlock: { (receivedSize, totalSize) -> () in
                if let progressHandler=progressBlock{
                    progressHandler(receivedSize:receivedSize,totalSize:totalSize);
                }
                }, completionHanlder: { [weak self] image, error, cacheType, imageUrl in
                    TLThreadUtils.shardThreadUtil.disAsyncMainThread({ () -> () in
                        guard let weakSelf = self where imageUrl == weakSelf.TL_imageWithURL else{
                            completionHander?(image: image, error: error, cacheType: cacheType, imageUrl: imageUrl);
                            return
                        }
                        
                        weakSelf.TL_setImageTask(nil);
                        
                    
                        //如果没有得到图片，则回调
                        guard let image = image else{
                            completionHander?(image: nil, error: error, cacheType: cacheType, imageUrl: imageUrl);
                            return
                        }
                        
                        weakSelf.image=image;
                        
                        
                    })
                    
                }, options: options)
            
            self.TL_setImageTask(task)
            return task;
    }
    
    /**
       取消正在下载任务
     */
    public func TL_cancelDownloadTask(){
      TL_imageTask?.downloadTask?.cancel()
    }
}