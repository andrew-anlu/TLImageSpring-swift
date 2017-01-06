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
    public let sessionDataTask:URLSessionDataTask;
    
    fileprivate weak var ownerDownloader:TLImageSpringDownloader?
    
    /**
     取消这个下载任务
     */
    public func cancel(){
        ownerDownloader?.cancelTASK(self);
    }
    /// 返回请求服务器的URL地址
    public var URL:Foundation.URL?{
        return sessionDataTask.originalRequest?.url;
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
    @objc optional func imageDownloader(_ downloader:TLImageSpringDownloader,didDownlaodImage image:UIImage,forURL URL:URL,withResponse response:URLResponse)
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
    func downloader(_ downloader:TLImageSpringDownloader,didReceiveChallenge challenge:URLAuthenticationChallenge,completionHander:(URLSession.AuthChallengeDisposition,URLCredential?) -> Void)
}

extension HTTPSChallengeResponseDelegate{
    
    /**
     NSURLSessionAuthChallengeUseCredential = 0,                     使用证书
     NSURLSessionAuthChallengePerformDefaultHandling = 1,            忽略证书(默认的处理方式)
     NSURLSessionAuthChallengeCancelAuthenticationChallenge = 2,     忽略书证, 并取消这次请求
     NSURLSessionAuthChallengeRejectProtectionSpace = 3,            拒绝当前这一次, 下一次再询问

     */
    func downloader(_ downloader:TLImageSpringDownloader,didReceiveChallenge challenge:URLAuthenticationChallenge,completionHander:(URLSession.AuthChallengeDisposition,URLCredential?) -> Void){
        //判断服务器返回的证书类型，是否是服务器信任
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust{
            if let trustHosts = downloader.trustedHosts, trustHosts.contains(challenge.protectionSpace.host){
             
                let credential=URLCredential(trust: challenge.protectionSpace.serverTrust!);
                
                completionHander( .useCredential,credential);
                
            }
        }
        completionHander( .performDefaultHandling,nil);
    }
}

//MARK: - TLImageSpringDownloader类定义
open class TLImageSpringDownloader: NSObject {

    static let shardInstance = TLImageSpringDownloader()

    class ImageFetchLoad {
        var callbacks=[CallBackPair]();
        var responseData=NSMutableData();
        
        
        var options:TLImgDownloadOpions?
        var downloadTaskCount=0;
        var downloadTask:DownloadIMGResult?
    }
    
    /// 信任证书的集合，如果使用https协议的话
    open var trustedHosts: Set<String>?
     /// 它可以被用于开启HTTP管道，这可以显着降低请求的加载时间，但是由于没有被服务器广泛支持，默认是禁用的
    open var requestsUsePipeling = false

    let barrierQueue:DispatchQueue
    let processQueue:DispatchQueue
    
    /// 定义下载的超时时间，默认15秒
    open var downloadTimeout:TimeInterval = 15.0
    open var session:URLSession?
    fileprivate var sessionHander:TLIMGSessionDownloadHandler?
    /// 下载代理
    open weak var delegate:TLImageSpringDownloadDelegate?
    open weak var httpsChallengeResponseDelegate:HTTPSChallengeResponseDelegate?
    //创建一个字典，key:NSURL value:一个自定义的数据封装类
    var fetchLoads=[URL:ImageFetchLoad]();
    
    typealias CallBackPair=(progressBlock:TLImgSpringDownloadProgressBlock?,completionBlock:TLIMGDownloadCompletionHandler);
    
    
    open var sessionConfiguration=URLSessionConfiguration.default{
        didSet{
            session=URLSession(configuration: sessionConfiguration, delegate: sessionHander, delegateQueue: OperationQueue.main);
        }
    }
    
    
    public override init() {
        
        barrierQueue = DispatchQueue(label: barrierName, attributes: DispatchQueue.Attributes.concurrent);
        processQueue = DispatchQueue(label: processQueueName, attributes: DispatchQueue.Attributes.concurrent);
        
        sessionHander=TLIMGSessionDownloadHandler()
        
        //提供一个默认实现https协议的处理方法
        httpsChallengeResponseDelegate=sessionHander
        
        session=URLSession(configuration: sessionConfiguration, delegate: sessionHander, delegateQueue: OperationQueue.main)
        
         super.init();
        
        
    }
    /**
     单例方法
     
     - returns:
     */
  open  class func STACICINSTANCE()->TLImageSpringDownloader {
        struct Singleton{
            static var onceToken:Int=0;
            static var instance:TLImageSpringDownloader?;
        }
        
        let instance = TLImageSpringDownloader.shardInstance
        return instance
    }
    
    func fetchLoadForkey(_ key:URL) ->ImageFetchLoad?{
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

    public func downloadImageWithURL(_ URL:Foundation.URL,
           progressBlock:TLImgSpringDownloadProgressBlock?,
        completionHander:TLIMGDownloadCompletionHandler?)->DownloadIMGResult?{
    
        return downloadImageWithURL(URL, options: nil, retrieveImageTask: nil, progressBlock: progressBlock, completionHander: completionHander)
    }
    
   
    public func downloadImageWithURL(_ URL:URL,
                                   options:TLImgDownloadOpions?,
                        retrieveImageTask:RetrieveImageTask?,
                             progressBlock:TLImgSpringDownloadProgressBlock?,
        completionHander:TLIMGDownloadCompletionHandler?)->DownloadIMGResult?{
    
            if let retrieveImageTask=retrieveImageTask, retrieveImageTask.canceled{
               return nil
            }
            
            let timeout=self.downloadTimeout == 0.0 ? 15.0 : self.downloadTimeout
            var downloadTaskResult:DownloadIMGResult?
            
            
//            let request=NSMutableURLRequest(url: URL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        var request = URLRequest(url: URL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        
        
    
            request.httpShouldUsePipelining=requestsUsePipeling
            
            if request.url == nil || request.url!.absoluteString.isEmpty{
                
                let error=NSError(domain: TLImageSpringErrorDomain, code: TLIMGERROR.tlimgerror_INVALIDURL.rawValue, userInfo: nil);
                
                completionHander?(nil, error, nil, nil);
                return nil
            }
            
            //嵌套一层闭包调用（为了实现一个url只下载一次）
            self.setupProgressBlock(progressBlock, completionHander: completionHander, forURL: URL) { (session, fetchLoad) -> () in
                
                if fetchLoad.downloadTask == nil{
                    let dataTask = session.dataTask(with: request)
                    
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
    fileprivate func setupProgressBlock(_ progressBlock:TLImgSpringDownloadProgressBlock?,completionHander:TLIMGDownloadCompletionHandler?,forURL URL:Foundation.URL,createHander:(_ session:URLSession,_ imageFetchLoad:ImageFetchLoad)->()){
        barrierQueue.sync(flags: .barrier, execute: { () -> Void in
            //先从全局字典中查找ImageFetchLoad，如果找不到则创建一个新的
            let loadObjectForURL = self.fetchLoadForkey(URL) ?? ImageFetchLoad();
            let callbackPair:CallBackPair=(progressBlock:progressBlock,completionBlock:completionHander!);
            loadObjectForURL.callbacks.append(callbackPair);
            
            self.fetchLoads[URL]=loadObjectForURL;
            
            if let session=self.session{
                createHander(session, loadObjectForURL);
            }
        }) 
    }
    /**
     取消正在下载的任务
     
     - parameter Task:DownloadIMGResult
     */
    public func cancelTASK(_ Task:DownloadIMGResult?){
        barrierQueue.sync(flags: .barrier, execute: { () -> Void in
            if let URL=Task?.sessionDataTask.originalRequest?.url, let imageFetchLoad=self.fetchLoads[URL]{
                imageFetchLoad.downloadTaskCount -= 1;
                if imageFetchLoad.downloadTaskCount == 0{
                 Task?.sessionDataTask.cancel()
                }
            }
        }) 
    }
    
    func cleanForURL(_ URL:Foundation.URL){
        barrierQueue.sync(flags: .barrier, execute: { () -> Void in
            self.fetchLoads.removeValue(forKey: URL);
            return;
        }) 
    }
    
    
    
}

//MARK: - NSURLSessionDataDelegate
/// 这个类将会处理sessionData 的代理方法，并且还会处理https协议的代理
class  TLIMGSessionDownloadHandler: NSObject,URLSessionDataDelegate,HTTPSChallengeResponseDelegate {
    
     var tlImgDownloader:TLImageSpringDownloader?

    /**
     当收到服务器响应的代理方法
     */
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        //这行代理必须有，不然服务器不会响应以后的操作
        completionHandler(Foundation.URLSession.ResponseDisposition.allow);
    }
    
    
    /**
     服务器成功响应或者失败的调用方法
     
     - parameter session: 当前Session
     - parameter task:    session任务
     - parameter error:   错误信息
     */
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?){
        if let URL = task.originalRequest?.url{
        
            if let error=error{
              callbackWithImage(nil, error: error as NSError?, imageUrl: URL, originalData: nil)
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
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let downloader=tlImgDownloader else{
         return
        }
        if let URL = dataTask.originalRequest?.url,let fetchLoad = downloader.fetchLoadForkey(URL){
            fetchLoad.responseData.append(data);
            
            for callbackPair  in fetchLoad.callbacks{
                
                TLImageThread.shardThread.disAsyncMainThread {
                    //进度条的回调方法
                    callbackPair.progressBlock?(Int64(fetchLoad.responseData.length), dataTask.response!.expectedContentLength);
                }
                
             
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
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let downloader = tlImgDownloader else{
            return;
        }
        
        downloader.httpsChallengeResponseDelegate?.downloader(downloader, didReceiveChallenge: challenge, completionHander: completionHandler);
    }
    
    fileprivate func callbackWithImage(_ image:UIImage?,error:NSError?,imageUrl:URL,originalData:Data?){
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
                download.processQueue.async(execute: { () -> Void in
                     callbackPair.completionBlock(image, error, imageUrl, originalData)
                })
            }
            
            if download.fetchLoads.isEmpty{
               tlImgDownloader=nil
            }
        }
    }
    
    fileprivate func processImageForTask(_ task:URLSessionTask,URL:Foundation.URL){
        guard let downloader=tlImgDownloader else{
            return;
        }
        
        downloader.processQueue.async(execute: { () -> Void in
            if let fetchLoad = downloader.fetchLoadForkey(URL){
                
               
                if let image=UIImage(data: fetchLoad.responseData as Data){
                    downloader.delegate?.imageDownloader?(downloader, didDownlaodImage: image, forURL: URL, withResponse: task.response!)
                    
                    self.callbackWithImage(image, error: nil, imageUrl: URL, originalData: fetchLoad.responseData as Data)
                }else{//如果没有获取到图片
                    if let res=task.response as? HTTPURLResponse, res.statusCode==304{
                        
                    let errorDesc=[NSLocalizedDescriptionKey:"Downloaded image is empty"];
                        
                     self.callbackWithImage(nil, error: NSError(domain: TLImageSpringErrorDomain, code: TLIMGERROR.tlimgerror_NOTMODIFIED.rawValue, userInfo: errorDesc), imageUrl: URL, originalData: fetchLoad.responseData as Data)
                        return
                    }
                    
                    self.callbackWithImage(nil, error: NSError(domain: TLImageSpringErrorDomain, code: TLIMGERROR.tlimgerror_BADDATA.rawValue, userInfo: nil), imageUrl: URL, originalData: fetchLoad.responseData as Data)
                    
                }
            }else{
                self.callbackWithImage(nil, error: NSError(domain: TLImageSpringErrorDomain, code: TLIMGERROR.tlimgerror_BADDATA.rawValue, userInfo: nil), imageUrl: URL, originalData: nil);
            }
        })
    }
    
}









