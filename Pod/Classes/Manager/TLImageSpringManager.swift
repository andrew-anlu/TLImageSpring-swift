//
//  TLImageSpringManager.swift
//  Pods
//
//  Created by Andrew on 16/4/6.
//
//

import Foundation

public struct TLParam {
    public let cacheKey:String?
    public let downloadURL:NSURL
    
    
    public init(cacheKey:String?=nil, downloadURL:NSURL){
        self.downloadURL=downloadURL
        self.cacheKey = cacheKey
    }
}


/// 检索图片的类，它会监控图片下载的进度
/// 1.从内存中检索  2.从网络中检索
public class RetrieveImageTask{
    var canceled:Bool=false
    
    //开启一个线程检索，从内存中检索图片
    public var diskRetrieveTask : RetrieveBlock?
    
    //从网络中异步下载图片
    public var downloadTask:DownloadIMGResult?
    
    /**
     取消一个下载任务
     */
    public func cancel(){
        //取消一个线程
        if let diskRetieveTask = diskRetrieveTask{
         dispatch_block_cancel(diskRetieveTask)
        }
        if let download=downloadTask{
            download.cancel()
        }else{
            canceled=true
        }
    }
    
}

private let instance=TLImageSpringManager()
public class TLImageSpringManager: NSObject {

    
    public var cache:TLImageCache
    public var downloader:TLImageSpringDownloader
    
    var failedUrls: Set<NSURL>?;
    
    public convenience override init() {
        let tlImgdownlaoder=TLImageSpringDownloader.STACICINSTANCE()
        let tlCache=TLImageCache.defaultCache;
        self.init(downloader: tlImgdownlaoder, cache:tlCache)
    }
    //MARK: - 单例
    public class var sharedManager:TLImageSpringManager{
        return instance;
    }
    
    private init(downloader:TLImageSpringDownloader,cache:TLImageCache) {
        self.downloader=downloader
        self.cache=cache
    }
    
    
    //MARK: - 下载的工具方法
    /**
     先从内存中获取，如果内存中没有则从服务器下载
     
     - parameter URL:               图片的服务器地址
     - parameter key:               key
     - parameter retieveImageTask:  自己封装检索的task
     - parameter progressBlock:     进度条的block
     - parameter completionHanlder: 完成时的回调函数
     - parameter options:           下载策略
     
     - returns: 下载结果的结构体
     */
    private func downloadImageWithParam(param: TLParam,
        progressBlock:TLImgSpringDownloadProgressBlock?,
        completionHanlder:TLImgSpringCompleteBlock?,
        options:TLImgDownloadOpions?)->RetrieveImageTask?{

            let task = RetrieveImageTask()
            if let optionsInfo = options where options==TLImgDownloadOpions.ForceRefresh{
                downloadImageWithURL(param.downloadURL,
                    forKey: param.cacheKey!,
                    retieveImageTask: task,
                    progressBlock:progressBlock,
                    completionHanlder: completionHanlder,
                    options: optionsInfo);
            }else{
               retrieveImageFromCacheForkey(param.cacheKey!,
                withURL:param.downloadURL,
                retrieveImageTask: task,
                progressBlock: progressBlock,
                completionHander: completionHanlder,
                options: options)
            }
            
            return task;
    }
    
    /**
      下载的工具方法
     
     - parameter url:               图片的服务器地址
     - parameter options:          下载策略
     - parameter progoressBlock:   进度条回调函数
     - parameter completionHander: 完成的回调函数
     
     - returns:检索图片的类
     */
    
    public func downloadImageWithURL(url:NSURL,
        options:TLImgDownloadOpions,
        progoressBlock:TLImgSpringDownloadProgressBlock,
        completionHander:TLImgSpringCompleteBlock)->RetrieveImageTask?{
            
     return self.downloadImageWithParam(TLParam(downloadURL: url),
        progressBlock: progoressBlock,
        completionHanlder: completionHander,
        options: options)
    }
    
    /**
    先从内存中获取，如果内存中没有则从服务器下载
     
     - parameter URL:               图片的服务器地址
     - parameter key:               key
     - parameter retieveImageTask:  自己封装检索的task
     - parameter progressBlock:     进度条的block
     - parameter completionHanlder: 完成时的回调函数
     - parameter options:           下载策略
     
     - returns: 下载结果的结构体
     */
    private func downloadImageWithURL(URL: NSURL?,
                              forKey key:String,
                        retieveImageTask:RetrieveImageTask,
                           progressBlock:TLImgSpringDownloadProgressBlock?,
                       completionHanlder:TLImgSpringCompleteBlock?,
                                 options:TLImgDownloadOpions?)->DownloadIMGResult?{
    
                           
                                    if URL == nil{
                                        completionHanlder?(image:nil,error: NSError(domain: TLImageSpringErrorDomain, code: NSURLErrorFileDoesNotExist, userInfo: nil),cacheType: TLImageCacheType.TLImageCatchTypeNone,imageUrl: nil)
                                        return nil;
                                    }
                                    
                                    var isFailUrl:Bool=false;
                                    TLThreadUtils.shardThreadUtil.mySynchronized(self.failedUrls!) { () -> () in
                                        isFailUrl = (self.failedUrls?.contains(URL!))!
                                    }
                                    
                                  
                                    
           return downloader.downloadImageWithURL(URL!,
            options: options,
            progressBlock: { (receivedSize, totalSize) -> () in
                progressBlock?(receivedSize: receivedSize, totalSize: totalSize);
            }, completionHander: { (image, error, imageURL, originalData) -> () in
                
                if let error = error where error.code == TLIMGERROR.TLIMGERROR_NOTMODIFIED.rawValue{
                  self.cache.queryImgFromDiskCacheForkey(key, completionHandler: { (image, cacheType) -> () in
                //从内存个中获取图片
                    if let handler=completionHanlder{
                        handler(image:image,error: nil,cacheType: cacheType,imageUrl: URL);
                    }
                  })
                    return
                }
                
                if let image=image, originData = originalData{
                   //把图片缓存起来
                    self.cache.storeImage(image, recalculateFromImage: false, imageData: originData, key: key, toDisk: true, complateHander: nil)
                }
                //执行回调函数
                completionHanlder?(image:image,error: error,cacheType: TLImageCacheType.TLImageCatchTypeNone,imageUrl: URL);
                
                
           })
    }
    
    /**
     从内存中查找图片
     
     - parameter key:               存储图片的key,一般是URL
     - parameter URL:               图片的服务器地址
     - parameter retrieveImageTask: 自己封装的检索图片的类
     - parameter progressBlock:     进度条的回调函数
     - parameter completionHander:  完成回调函数
     - parameter options:           下载策略
     */
    private func retrieveImageFromCacheForkey(key:String,
        withURL URL:NSURL,
        retrieveImageTask:RetrieveImageTask,
        progressBlock:TLImgSpringDownloadProgressBlock?,
        completionHander:TLImgSpringCompleteBlock?,
        options:TLImgDownloadOpions?){
    
            
            let diskTask=self.cache.queryImgFromDiskCacheForkey(key, completionHandler: { (image, cacheType) -> () in
                if image != nil{
                    completionHander?(image: image, error: nil, cacheType: cacheType, imageUrl: URL);
                }else{
                  self.downloadImageWithURL(URL,
                    forKey: key,
                    retieveImageTask: retrieveImageTask,
                    progressBlock: progressBlock,
                    completionHanlder: completionHander,
                    options: options)
                }
            })
            retrieveImageTask.diskRetrieveTask=diskTask
    }
    
    
    /**
     检查图片是不是在硬盘上缓存了
     
     - parameter URL: 图片对应的服务器地址
     */
    
    //MARK: - 从缓存中检索图片
    public func checkImageIsExistInDiskForKey(URL:NSURL)->Bool{
        let key = self.getStringByURL(url: URL);
        return self.cache.diskImageExistWithKey(key);
    }
    
    /**
     检查图片是否在内存中
     
     - parameter URL:  图片对应的服务器地址
     
     - returns: 是否存在
     */
    public func checkImageIsExistInMemoryForKey(URL:NSURL)->Bool{
     
        let key = self.getStringByURL(url: URL)
        if  self.cache.imageFromMemoryCacheForkey(key) != nil{
            return true;
        }else{
            return false;
        }
      
    }
    
    /**
     检查图片是否在内存或者硬盘中缓存
     
     - parameter url:              图片的服务器地址
     - parameter completionHander: 回调函数
     */
    public  func checkImgIsEsistForURL(url: NSURL,completionHander:((isInCache:Bool)->())?){
        let key = self.getStringByURL(url: url);
        
        var isInMemory=false;
        //检查内存中是否存在
        if self.cache.imageFromMemoryCacheForkey(key) != nil{
          isInMemory=true
        }
        
        if(isInMemory){
            TLThreadUtils.shardThreadUtil.disAsyncMainThread({ () -> () in
                if let handler=completionHander{
                    handler(isInCache: true)
                }
            })
            return;
        }
        
        //检查硬盘中是否存在
        self.cache.diskImageExistWithKey(key) { (isInDisk) -> Void in
            TLThreadUtils.shardThreadUtil.disAsyncMainThread({ () -> () in
                if let handler=completionHander{
                  handler(isInCache: isInDisk)
                }
            })
        }
    }
    
    
    private func getStringByURL(url url:NSURL)->String{
        return url.absoluteString;
    }
  
    
    
}




















