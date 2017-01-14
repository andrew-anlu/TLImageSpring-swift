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

//private var indicatorView:UIActivityIndicatorView?


//MARK: - 对TLImageSrping进行扩展
extension TLImageSpring where Base:UIImageView{
    /**
     设置图片的URL地址，没下载完成的时候用一个占位符图片顶替
     
     - parameter param:            一个参数结构，封装了缓存key和下载的服务器地址
     - parameter placeHolderImage: 占位符图案品
     - parameter options:          下载策略
     - parameter progressBlock:    进度条的回调函数
     - parameter completionHander: 下载完成的回调函数
     
     - returns: 检索图片的类
     */
    public func setImage(_ param:TLParam?,
                         placeHolderImage:UIImage? = nil,
                         options:TLImgDownloadOpions? = nil,
                         progressBlock:TLImgSpringDownloadProgressBlock? = nil,
                         completionHander:TLImgSpringCompleteBlock? = nil,
                         style:UIActivityIndicatorViewStyle?)->RetrieveImageTask{
        var style = style
        if style==nil{
            style = .gray
        }
        
        guard let param = param else {
            base.image = placeHolderImage
            completionHander?(nil,nil,.tlImageCatchTypeNone,nil)
            return .empty
        }
        
        self.indicatorView = createIndicatorView()
        self.indicatorView?.startAnimating()
        
        print("self.indicatorView:\(self.indicatorView)")
        
        //把图片的服务器地址绑定到运行时
        self.setImageWithURL(param.downloadURL)

        
        base.image=placeHolderImage
        
        let task=TLImageSpringManager.sharedManager.downloadImageWithParam(param, progressBlock: { (receivedSize, totalSize) -> () in
            if let progressHandler=progressBlock{
                progressHandler(receivedSize,totalSize);
            }
        }, completionHanlder: { [weak base] image, error, cacheType, imageUrl in
            
            guard let strongBase = base, imageUrl == self.imageURL else {
                return
            }
            
//            guard let weakSelf = self else {
//                fatalError("当前实例是空")
//              return
//            }
            //让转子停止动画
           
            let activityIndicator = self.indicatorView
            
            DispatchQueue.main.async(execute: { () -> Void in
                activityIndicator?.stopAnimating()
            })
            
          
            if imageUrl == nil{
                completionHander?(image, error, cacheType, imageUrl);
                return
            }
            self.setImageTask(nil)
            
            //如果没有得到图片，则回调
            guard let image = image else{
                completionHander?(nil, error, cacheType, imageUrl);
                return
            }
            strongBase.image = image
           
            completionHander?(image, error, cacheType, imageUrl);
            
            }, options: options)
        
        self.setImageTask(task)
        return task;
    }
    
    /// 根据指定的URL加载图片
    ///
    /// - Parameters:
    ///   - URL: 图片的路径
    ///   - placeholderImage: 默认图片
    ///   - options: 加载策略
    /// - Returns: 返回图片加载任务
    @discardableResult
    public func setImage(with URL:Foundation.URL,placeholderImage:UIImage?)->RetrieveImageTask{
    
        let param = TLParam(downloadURL: URL)
        
        return self.setImage(param, placeHolderImage: placeholderImage, options: nil, progressBlock: nil, completionHander: nil, style: nil)
    }
    
    /// 根据指定的URL加载图片
    ///
    /// - Parameters:
    ///   - URL: 图片的路径
    ///   - placeholderImage: 默认图片
    ///   - options: 加载策略
    ///   - progrocessBlock:下载进度的回调
    ///   - completionHander: 下载成功回调函数
    /// - Returns:返回图片加载任务
    @discardableResult
    public func setImage(with URL:Foundation.URL,
                                   placeholderImage:UIImage?,
                                   options:TLImgDownloadOpions?,
                                   progrocessBlock:TLImgSpringDownloadProgressBlock?,
                                   completionHander:TLImgSpringCompleteBlock?) ->RetrieveImageTask{
        let param = TLParam(downloadURL: URL)
        return self.setImage(param, placeHolderImage: placeholderImage, options: options, progressBlock: nil, completionHander: nil, style: nil)
    }
    /**
     取消正在下载任务
     */
    public func cancelDownloadTask(){
        imageTask?.downloadTask?.cancel()
    }
    
    
    //MARK: - Helper methods
    /// 获取运行时的下载任务的检索图片的类
    fileprivate var imageTask : RetrieveImageTask?{
        return objc_getAssociatedObject(self, &tlImageTaskKey) as? RetrieveImageTask
    }
    
    /**
     设置运行时检索图片的类
     - parameter task: 检索图片的类
     */
    fileprivate func setImageTask(_ task : RetrieveImageTask?){
        objc_setAssociatedObject(self, &tlImageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    /// 获取运行时图片的服务器地址
    public var imageURL:URL?{
        return objc_getAssociatedObject(self, &tlImageRuntimeKey) as? URL
    }
    

    /**
     设置运行时图片的服务器地址
     
     - parameter URL: 图片服务器地址
     */
    fileprivate func setImageWithURL(_ URL:URL?){
        objc_setAssociatedObject(self, &tlImageRuntimeKey, URL, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    public var indicatorView:UIActivityIndicatorView?{
        get{
          return (objc_getAssociatedObject(self, &tlImageIndicatorViewKey) as?UIActivityIndicatorView)
        }
        set{
            // Remove previous
            if let previousIndicator = indicatorView {
                previousIndicator.removeFromSuperview()
            }
            //Add new
            if var newIndicator = newValue{
                newIndicator.frame = CGRect(x: 0, y: 0, width: base.frame.size.width, height: base.frame.size.height)
                print("newIndicator.center:\(newIndicator.center)")
                base.addSubview(newIndicator)
                
            }
               objc_setAssociatedObject(self, &tlImageIndicatorViewKey, indicatorView, .OBJC_ASSOCIATION_RETAIN)
        }
        
    }
    
    fileprivate func  setIndicatorView(_ activityIndicator:UIActivityIndicatorView?){
        objc_setAssociatedObject(self, &tlImageIndicatorViewKey, activityIndicator, .OBJC_ASSOCIATION_RETAIN)
    }
    
    func createIndicatorView() -> UIActivityIndicatorView {
        let indicatorView =  UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicatorView.hidesWhenStopped = true
        indicatorView.frame = CGRect(x: 0, y: 0, width: base.frame.size.width, height: base.frame.size.height)
//        self.base.addSubview(indicatorView)
        
        indicatorView.backgroundColor = UIColor.red
        
        print("self.base.frame:\(self.base.frame);indicatorView.frame:\(indicatorView.frame)")
        return indicatorView
    }
    
}


extension UIImageView : TLImageSpringCompatible{
    


    /**
     设置图片的URL地址和缓存的key,如果没有设置该key,则默认为URL字符串，没下载完成的时候用一个占位符图片顶替
     
     - parameter param:            结构体，封装了缓存的key和URL地址
     - parameter placeHolderImage: 占位符图片
     
     - returns: 检索图片的类
     */
    @available(* ,deprecated, message: "TL_setImageWithURL method is deprecated,use tl.setImage instead",renamed: "tl.setImage")
    public func TL_setImageURLWithParam(_ param:TLParam,placeHolderImage:UIImage?)->RetrieveImageTask{
        var param = param
 
        if param.cacheKey == nil{
            param.cacheKey = param.downloadURL.absoluteString
        }
        
    
        
       return tl.setImage(param, placeHolderImage: placeHolderImage, options: nil, progressBlock: nil, completionHander: nil, style: nil)
    }
    
    /**
     提供一个带有设置UIActivityIndicatorViewStyle样式的方法
     
     - parameter URL:              图片的服务器地址
     - parameter placeHolderImage: 占位符图片
     - parameter options:          下载策略
     - parameter style:            转子的样式
     
     - returns: 检索图片的自定义类
     */
    @available(* , deprecated, message: "TL_setImageWithURL method is deprecated",renamed: "tl.imageWithUrl")
    public func TL_setImageWithURL(_ URL:URL,placeHolderImage:UIImage?,
        options:TLImgDownloadOpions?,style:UIActivityIndicatorViewStyle?)->RetrieveImageTask{

        let param = TLParam(downloadURL: URL)
        
       return tl.setImage(param, placeHolderImage: placeHolderImage, options: options, progressBlock: nil, completionHander: nil, style: style)
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
    
    @available(* , deprecated, message: "TL_setImageWithURL method is deprecated",renamed: "tl.imageWithUrl")
    public func TL_setImageWithURL(_ URL:Foundation.URL,
        placeholderImage:UIImage?,
        options:TLImgDownloadOpions?,
        progrocessBlock:TLImgSpringDownloadProgressBlock?,
        completionHander:TLImgSpringCompleteBlock?) ->RetrieveImageTask{
            
            let param=TLParam(cacheKey: URL.absoluteString, downloadURL: URL)
        
        return tl.setImage(param, placeHolderImage: placeholderImage, options: options, progressBlock: progrocessBlock, completionHander: completionHander,style: nil);
    }
    /**
     设置图片的URL地址，没下载完成的时候用一个占位符图片顶替
     
     - parameter URL:              图片的URL地址
     - parameter placeholderImage: 占位符图片
     
     - returns: 检索图片的类
     */
    @available(*, deprecated, message: "`TL_setImageWithURL` method is deprecated,use tl.setImage instead ",renamed: "tl.setImage")
    public func TL_setImageWithURL(_ URL:Foundation.URL,placeholderImage:UIImage?,options:TLImgDownloadOpions?)->RetrieveImageTask{
        
        let param=TLParam(cacheKey: URL.absoluteString, downloadURL: URL)
 
        return tl.setImage(param, placeHolderImage: placeholderImage, options: options, progressBlock: nil, completionHander: nil, style: nil)
    }
   
    /**
     设置图片的URL地址，没下载完成的时候用一个占位符图片顶替
     
     - parameter URL:              图片的服务器地址
     - parameter placeholderImage: 占位符图片
     
     - returns: 检索图片的类
     */
    @available(* , deprecated, message: "TL_setImageWithURL method is deprecated,use tl.setImage instead.",renamed: "tl.setImage")
    public func TL_setImageWithURL(_ URL:Foundation.URL,placeholderImage:UIImage?)->RetrieveImageTask{
        
        return tl.setImage(TLParam(downloadURL: URL), placeHolderImage: placeholderImage, options: nil, progressBlock: nil, completionHander: nil,style: nil)
        
    }
    
    @available(*, deprecated, message: "`TL_setImageWithParam` method is deprecated,use tl.setImage instead ",renamed: "tl.setImage")
    @discardableResult
    public func TL_setImageWithParam(_ param:TLParam,
                                     placeHolderImage:UIImage?,
                                     options:TLImgDownloadOpions?,
                                     progressBlock:TLImgSpringDownloadProgressBlock?,
                                     completionHander:TLImgSpringCompleteBlock?,
                                     style:UIActivityIndicatorViewStyle?)->RetrieveImageTask{
        
        return tl.setImage(param, placeHolderImage: placeHolderImage, options: options, progressBlock: progressBlock, completionHander: completionHander, style: style)
    
    }
    
   
}


