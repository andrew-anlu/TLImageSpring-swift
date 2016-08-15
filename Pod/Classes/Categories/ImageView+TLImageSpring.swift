//
//  ImageView+TLImageSpring.swift
//  Pods
//
//  Created by Andrew on 16/4/6.
//
//

import Foundation
import UIKit

/// 存储图片对应的服务器var址的key
private var tlImageRuntimeKey:Void?
/// 存储自定义下载的RetrieveImageTask的key
private var tlImageTaskKey:Void?
/// 存储运行时UIActivityIndicatorView的key
private var tlImageIndicatorViewKey:Void?

private var indicatorView:UIActivityIndicatorView?

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
    
    private var TL_indicatorView:UIActivityIndicatorView?{
      return (objc_getAssociatedObject(self, &tlImageIndicatorViewKey) as?UIActivityIndicatorView)
    }
    
    private func  TL_setIndicatorView(activityIndicator:UIActivityIndicatorView?){
      objc_setAssociatedObject(self, &tlImageIndicatorViewKey, activityIndicator, .OBJC_ASSOCIATION_RETAIN)
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
        completionHander: nil,
        style: nil)
    }
    
    /**
     提供一个带有设置UIActivityIndicatorViewStyle样式的方法
     
     - parameter URL:              图片的服务器地址
     - parameter placeHolderImage: 占位符图片
     - parameter options:          下载策略
     - parameter style:            转子的样式
     
     - returns: 检索图片的自定义类
     */
    public func TL_setImageWithURL(URL:NSURL,placeHolderImage:UIImage?,
        options:TLImgDownloadOpions?,style:UIActivityIndicatorViewStyle?)->RetrieveImageTask{
            
            return TL_setImageWithParam(TLParam(downloadURL: URL), placeHolderImage: placeHolderImage, options: nil, progressBlock: nil, completionHander: nil, style: style)
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
            
            return TL_setImageWithParam(param, placeHolderImage: placeholderImage, options: options, progressBlock: progrocessBlock, completionHander: completionHander,style: nil);
    }
    /**
     设置图片的URL地址，没下载完成的时候用一个占位符图片顶替
     
     - parameter URL:              图片的URL地址
     - parameter placeholderImage: 占位符图片
     
     - returns: 检索图片的类
     */
    public func TL_setImageWithURL(URL:NSURL,placeholderImage:UIImage?,options:TLImgDownloadOpions?)->RetrieveImageTask{
        
        let param=TLParam(cacheKey: URL.absoluteString, downloadURL: URL)
        
        return TL_setImageWithParam(param, placeHolderImage: placeholderImage, options: options, progressBlock: nil, completionHander: nil, style: nil)
    }
   
    /**
     设置图片的URL地址，没下载完成的时候用一个占位符图片顶替
     
     - parameter URL:              图片的服务器地址
     - parameter placeholderImage: 占位符图片
     
     - returns: 检索图片的类
     */
    public func TL_setImageWithURL(URL:NSURL,placeholderImage:UIImage?)->RetrieveImageTask{
        
        return TL_setImageWithParam(TLParam(downloadURL: URL), placeHolderImage: placeholderImage, options: nil, progressBlock: nil, completionHander: nil,style: nil)
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
        completionHander:TLImgSpringCompleteBlock?,
        var style:UIActivityIndicatorViewStyle?)->RetrieveImageTask{
            if style==nil{
               style = .Gray
            }
            self.addActivityIndicator(style!)
            
            //把图片的服务器地址绑定到运行时
            TL_setImageWithURL(param.downloadURL)
            
            image=placeHolderImage
            
            let task=TLImageSpringManager.sharedManager.downloadImageWithParam(param, progressBlock: { (receivedSize, totalSize) -> () in
                if let progressHandler=progressBlock{
                    progressHandler(receivedSize:receivedSize,totalSize:totalSize);
                }
                }, completionHanlder: { [weak self] image, error, cacheType, imageUrl in
                    if let weakSelf = self{
                        //让转子停止动画
                        let activityIndicator = weakSelf.TL_indicatorView
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            activityIndicator?.stopAnimating()
                        })
                    }
                    
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
                        
                        completionHander?(image: image, error: error, cacheType: cacheType, imageUrl: imageUrl);
                        
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



extension UIImageView{
    func addActivityIndicator(style:UIActivityIndicatorViewStyle){
        //从运行时得到UIActivityIndicatorView
        var indicatorView=TL_indicatorView
        if(indicatorView==nil){
            indicatorView = UIActivityIndicatorView(activityIndicatorStyle: style)
            indicatorView!.autoresizingMask=[.FlexibleBottomMargin,.FlexibleLeftMargin,.FlexibleTopMargin,.FlexibleRightMargin]
            
            indicatorView!.center=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
            indicatorView!.hidden=false
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.addSubview(indicatorView!)
            })
            //绑定到运行时
            TL_setIndicatorView(indicatorView)
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            indicatorView?.startAnimating()
        })
    }
    
    func removeActivityIndicator(){
        var acitityIndicator=TL_indicatorView
        acitityIndicator?.removeFromSuperview()
        acitityIndicator=nil
    }

}


//MARK: - 对UIActivityIndicatorView扩展
extension UIActivityIndicatorView{

    

}