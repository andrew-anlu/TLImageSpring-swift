//
//  TLImageSpringDownloader.swift
//  Pods
//
//  Created by Andrew on 16/4/6.
//
//

import Foundation



private let barrierName="com.tongli.tlimageSpring.Barrier"
private let processQueueName="com.tongli.tlimageSpring.processQueue"


/**
 *  下载图片的返回结果
 */
public struct DownloadIMGResult{
    //下载的主力 sessionDataTask
    public let sessionDataTask:NSURLSessionDataTask;
    
    private weak var ownerDownloader:TLImageSpringDownloader?
    
    /**
     取消这个下载任务
     */
    public func cancel(){
        ownerDownloader?.cancelTASK(self);
    }
    /// 返回请求服务器的URL地址
    public var URL:NSURL?{
        return sessionDataTask.originalRequest?.URL;
    }
    
    /// 下载任务的优先权
    /*
    NSURLSessionTaskPriorityDefault
    NSURLSessionTaskPriorityLow
    NSURLSessionTaskPriorityHigh
    */
    public var priority:Float{
        get{
            return sessionDataTask.priority;
        }
        
        set{
            sessionDataTask.priority=newValue;
        }
    }
}
/**
 *  代理方法
 */
@objc public protocol TLImageSpringDownloadDelegate{
  
    /**
     通过提供的URL地址，成功的从服务器下载到图片后的代理方法
     
     - parameter downloader: 下载处理类
     - parameter image:      下载好的图片
     - parameter URL:        图片的服务器地址
     - parameter response:   响应数据
     */
    optional func imageDownloader(downloader:TLImageSpringDownloader,didDownlaodImage image:UIImage,forURL URL:NSURL,withResponse response:NSURLResponse)
}

/**
 *  如果是进行https请求时候的代理方法
 */
public protocol HTTPSChallengeResponseDelegate:class{
    
    /**
     当调用https请求的时候该代理被调用
     
     - parameter downloader:       下载器
     - parameter challenge:        带有加密协议的请求
     - parameter completionHander: 回调函数
     */
    func downloader(downloader:TLImageSpringDownloader,didReceiveChallenge challenge:NSURLAuthenticationChallenge,completionHander:(NSURLSessionAuthChallengeDisposition,NSURLCredential?) -> Void)
}

extension HTTPSChallengeResponseDelegate{
    
    /**
     NSURLSessionAuthChallengeUseCredential = 0,                     使用证书
     NSURLSessionAuthChallengePerformDefaultHandling = 1,            忽略证书(默认的处理方式)
     NSURLSessionAuthChallengeCancelAuthenticationChallenge = 2,     忽略书证, 并取消这次请求
     NSURLSessionAuthChallengeRejectProtectionSpace = 3,            拒绝当前这一次, 下一次再询问

     */
    func downloader(downloader:TLImageSpringDownloader,didReceiveChallenge challenge:NSURLAuthenticationChallenge,completionHander:(NSURLSessionAuthChallengeDisposition,NSURLCredential?) -> Void){
        //判断服务器返回的证书类型，是否是服务器信任
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust{
            if let trustHosts = downloader.trustedHosts where trustHosts.contains(challenge.protectionSpace.host){
             
                let credential=NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!);
                
                completionHander( .UseCredential,credential);
                
            }
        }
        completionHander( .PerformDefaultHandling,nil);
    }
}

//MARK: - TLImageSpringDownloader类定义
public class TLImageSpringDownloader: NSObject {

    class ImageFetchLoad {
        var callbacks=[CallBackPair]();
        var responseData=NSMutableData();
        
        
        var options:TLImgDownloadOpions?
        var downloadTaskCount=0;
        var downloadTask:DownloadIMGResult?
    }
    
    /// 信任证书的集合，如果使用https协议的话
    public var trustedHosts: Set<String>?
     /// 它可以被用于开启HTTP管道，这可以显着降低请求的加载时间，但是由于没有被服务器广泛支持，默认是禁用的
    public var requestsUsePipeling = false

    let barrierQueue:dispatch_queue_t
    let processQueue:dispatch_queue_t
    
    /// 定义下载的超时时间，默认15秒
    public var downloadTimeout:NSTimeInterval = 15.0
    public var session:NSURLSession?
    private var sessionHander:TLIMGSessionDownloadHandler?
    /// 下载代理
    public weak var delegate:TLImageSpringDownloadDelegate?
    public weak var httpsChallengeResponseDelegate:HTTPSChallengeResponseDelegate?
    //创建一个字典，key:NSURL value:一个自定义的数据封装类
    var fetchLoads=[NSURL:ImageFetchLoad]();
    
    typealias CallBackPair=(progressBlock:TLImgSpringDownloadProgressBlock?,completionBlock:TLIMGDownloadCompletionHandler);
    
    
    public var sessionConfiguration=NSURLSessionConfiguration.defaultSessionConfiguration(){
        didSet{
            session=NSURLSession(configuration: sessionConfiguration, delegate: sessionHander, delegateQueue: NSOperationQueue.mainQueue());
        }
    }
    
    
    public override init() {
        
        barrierQueue = dispatch_queue_create(barrierName, DISPATCH_QUEUE_CONCURRENT);
        processQueue = dispatch_queue_create(processQueueName, DISPATCH_QUEUE_CONCURRENT);
        
        sessionHander=TLIMGSessionDownloadHandler()
        
        //提供一个默认实现https协议的处理方法
        httpsChallengeResponseDelegate=sessionHander
        
        session=NSURLSession(configuration: sessionConfiguration, delegate: sessionHander, delegateQueue: NSOperationQueue.mainQueue())
        
         super.init();
        
        
    }
    /**
     单例方法
     
     - returns:
     */
  public  class func STACICINSTANCE()->TLImageSpringDownloader {
        struct Singleton{
            static var onceToken:dispatch_once_t=0;
            static var instance:TLImageSpringDownloader?;
        }
        
        dispatch_once(&Singleton.onceToken) { () -> Void in
            Singleton.instance=TLImageSpringDownloader();
        }
        return Singleton.instance!;
    }
    
    func fetchLoadForkey(key:NSURL) ->ImageFetchLoad?{
        var fetchLoad:ImageFetchLoad?
//        dispatch_async(barrierQueue) { () -> Void in
//            fetchLoad=self.fetchLoads[key];
//        }
         fetchLoad=self.fetchLoads[key];
        return fetchLoad;
    }

}


//对TLImageSpringDownloader进行扩展
//MARK: - 下载的API
extension TLImageSpringDownloader{

    public func downloadImageWithURL(URL:NSURL,
           progressBlock:TLImgSpringDownloadProgressBlock?,
        completionHander:TLIMGDownloadCompletionHandler?)->DownloadIMGResult?{
    
        return downloadImageWithURL(URL, options: nil, retrieveImageTask: nil, progressBlock: progressBlock, completionHander: completionHander)
    }
    
   
    public func downloadImageWithURL(URL:NSURL,
                                   options:TLImgDownloadOpions?,
                        retrieveImageTask:RetrieveImageTask?,
                             progressBlock:TLImgSpringDownloadProgressBlock?,
        completionHander:TLIMGDownloadCompletionHandler?)->DownloadIMGResult?{
    
            if let retrieveImageTask=retrieveImageTask where retrieveImageTask.canceled{
               return nil
            }
            
            let timeout=self.downloadTimeout == 0.0 ? 15.0 : self.downloadTimeout
            var downloadTaskResult:DownloadIMGResult?
            
            
            let request=NSMutableURLRequest(URL: URL, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: timeout)
            request.HTTPShouldUsePipelining=requestsUsePipeling
            
            if request.URL == nil || request.URL!.absoluteString.isEmpty{
                
                let error=NSError(domain: TLImageSpringErrorDomain, code: TLIMGERROR.TLIMGERROR_INVALIDURL.rawValue, userInfo: nil);
                
                completionHander?(image: nil, error: error, imageURL: nil, originalData: nil);
                return nil
            }
            
            //嵌套一层闭包调用（为了实现一个url只下载一次）
            self.setupProgressBlock(progressBlock, completionHander: completionHander, forURL: URL) { (session, fetchLoad) -> () in
                
                if fetchLoad.downloadTask == nil{
                    let dataTask=session.dataTaskWithRequest(request);
                    
                    fetchLoad.downloadTask=DownloadIMGResult(sessionDataTask: dataTask, ownerDownloader: self)
                    fetchLoad.options=options;
                    //下载的优先级 为了兼容ios8
                    //dataTask.priority=NSURLSessionTaskPriorityDefault;
                    
                    //启动下载命令
                    dataTask.resume();
                    
                    //设置这个session的代理
                    self.sessionHander?.tlImgDownloader=self;
                }
                
                fetchLoad.downloadTaskCount+=1
                downloadTaskResult=fetchLoad.downloadTask
                retrieveImageTask?.downloadTask=downloadTaskResult
            }
            
            return downloadTaskResult;
    }
    
    /**
     一个URL可能被多次调用，但是同一个key应该只被下载一次
     
     - parameter progressBlock:    进度条回调函数
     - parameter completionHander: 下载完成的回调函数
     - parameter URL:              服务器地址
     - parameter createHander:     创建回调
     */
    private func setupProgressBlock(progressBlock:TLImgSpringDownloadProgressBlock?,completionHander:TLIMGDownloadCompletionHandler?,forURL URL:NSURL,createHander:(session:NSURLSession,imageFetchLoad:ImageFetchLoad)->()){
        dispatch_barrier_sync(barrierQueue) { () -> Void in
            //先从全局字典中查找ImageFetchLoad，如果找不到则创建一个新的
            let loadObjectForURL = self.fetchLoadForkey(URL) ?? ImageFetchLoad();
            let callbackPair:CallBackPair=(progressBlock:progressBlock,completionBlock:completionHander!);
            loadObjectForURL.callbacks.append(callbackPair);
            
            self.fetchLoads[URL]=loadObjectForURL;
            
            if let session=self.session{
                createHander(session: session, imageFetchLoad: loadObjectForURL);
            }
        }
    }
    /**
     取消正在下载的任务
     
     - parameter Task:DownloadIMGResult
     */
    public func cancelTASK(Task:DownloadIMGResult?){
        dispatch_barrier_sync(barrierQueue) { () -> Void in
            if let URL=Task?.sessionDataTask.originalRequest?.URL, imageFetchLoad=self.fetchLoads[URL]{
                imageFetchLoad.downloadTaskCount--;
                if imageFetchLoad.downloadTaskCount == 0{
                 Task?.sessionDataTask.cancel()
                }
            }
        }
    }
    
    func cleanForURL(URL:NSURL){
        dispatch_barrier_sync(barrierQueue) { () -> Void in
            self.fetchLoads.removeValueForKey(URL);
            return;
        }
    }
    
    
    
}

//MARK: - NSURLSessionDataDelegate
/// 这个类将会处理sessionData 的代理方法，并且还会处理https协议的代理
class  TLIMGSessionDownloadHandler: NSObject,NSURLSessionDataDelegate,HTTPSChallengeResponseDelegate {
    
     var tlImgDownloader:TLImageSpringDownloader?

    /**
     当收到服务器响应的代理方法
     */
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        //这行代理必须有，不然服务器不会响应以后的操作
        completionHandler(NSURLSessionResponseDisposition.Allow);
    }
    
    
    /**
     服务器成功响应或者失败的调用方法
     
     - parameter session: 当前Session
     - parameter task:    session任务
     - parameter error:   错误信息
     */
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?){
        if let URL = task.originalRequest?.URL{
        
            if let error=error{
              callbackWithImage(nil, error: error, imageUrl: URL, originalData: nil)
            } else {
                processImageForTask(task, URL: URL);
            }
        }
    }
    
    /**
     当接收到数据的时候 的代理方法
     
     - parameter session:  当前Session
     - parameter dataTask: session任务
     - parameter data:     收到服务器的数据
     */
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        guard let downloader=tlImgDownloader else{
         return
        }
        if let URL = dataTask.originalRequest?.URL,fetchLoad = downloader.fetchLoadForkey(URL){
            fetchLoad.responseData.appendData(data);
            
            for callbackPair  in fetchLoad.callbacks{
             TLThreadUtils.shardThreadUtil.disAsyncMainThread({ () -> () in
                //进度条的回调方法
                callbackPair.progressBlock?(receivedSize: Int64(fetchLoad.responseData.length), totalSize: dataTask.response!.expectedContentLength);
             })
            }
        }
    }
    /**
     只要请求的地址是https协议的，就会调用这个方法，我们需要在该方法中告诉系统，是否信任服务器返回的证书
     
     - protectionSpace              受保护区域
     - parameter session:           当前Session
     - parameter task:              session任务
     - parameter challenge:         挑战 质问 (包含了受保护的区域)
     - parameter completionHandler: 回调函数
     */
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        guard let downloader = tlImgDownloader else{
            return;
        }
        
        downloader.httpsChallengeResponseDelegate?.downloader(downloader, didReceiveChallenge: challenge, completionHander: completionHandler);
    }
    
    private func callbackWithImage(image:UIImage?,error:NSError?,imageUrl:NSURL,originalData:NSData?){
        guard let download=tlImgDownloader else{
            return;
        }
        
        
        if let callbackPairs=download.fetchLoadForkey(imageUrl)?.callbacks{
            
            /*
            如果正常回调了（成功或者失败），就把请求URL的数组中删除，下次就能达到下载效果了
            如果不删除，同样的url请求，第二次将不会执行下载命令
            */
            download.cleanForURL(imageUrl)
            
            for callbackPair in callbackPairs{
                dispatch_async(download.processQueue, { () -> Void in
                     callbackPair.completionBlock(image: image, error: error, imageURL: imageUrl, originalData: originalData)
                })
            }
            
            if download.fetchLoads.isEmpty{
               tlImgDownloader=nil
            }
        }
    }
    
    private func processImageForTask(task:NSURLSessionTask,URL:NSURL){
        guard let downloader=tlImgDownloader else{
            return;
        }
        
        print(downloader.fetchLoads);
        dispatch_async(downloader.processQueue, { () -> Void in
            if let fetchLoad = downloader.fetchLoadForkey(URL){
                
               
                if let image=UIImage(data: fetchLoad.responseData){
                    downloader.delegate?.imageDownloader?(downloader, didDownlaodImage: image, forURL: URL, withResponse: task.response!)
                    
                    self.callbackWithImage(image, error: nil, imageUrl: URL, originalData: fetchLoad.responseData)
                }else{//如果没有获取到图片
                    if let res=task.response as? NSHTTPURLResponse where res.statusCode==304{
                        
                    let errorDesc=[NSLocalizedDescriptionKey:"Downloaded image is empty"];
                        
                     self.callbackWithImage(nil, error: NSError(domain: TLImageSpringErrorDomain, code: TLIMGERROR.TLIMGERROR_NOTMODIFIED.rawValue, userInfo: errorDesc), imageUrl: URL, originalData: fetchLoad.responseData)
                        return
                    }
                    
                    self.callbackWithImage(nil, error: NSError(domain: TLImageSpringErrorDomain, code: TLIMGERROR.TLIMGERROR_BADDATA.rawValue, userInfo: nil), imageUrl: URL, originalData: fetchLoad.responseData)
                    
                }
            }else{
                self.callbackWithImage(nil, error: NSError(domain: TLImageSpringErrorDomain, code: TLIMGERROR.TLIMGERROR_BADDATA.rawValue, userInfo: nil), imageUrl: URL, originalData: nil);
            }
        })
    }
    
}









