//
//  TLImageCache.swift
//  Pods
//  缓存类 1.支持NSCache缓存  2.硬盘缓存
//  Created by Andrew on 16/4/6.
//
//

import UIKit


/// 自定义AutoNSCache类
class AutoNSCache:NSCache {
    override init() {
       super.init();
       //当收到缓存警告的时候，主动调用NSCatch的`removeAllObjects`去清空缓存
        NSNotificationCenter.defaultCenter().addObserver(self, selector:Selector("removeAllObjects"), name: UIApplicationDidReceiveMemoryWarningNotification, object: nil);
    }
    //当程序退出的时候，调用反初始化函数
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }
}

private let kDefaultCatchMaxCatchAge:NSTimeInterval=60 * 60 * 24 * 7;//默认保存一周
private var kPNGSignatureData:NSData?
private var kPNGSignatureBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];


/*
{(parameters) -> return type in
statements
}
*/
//定义闭包
let TLImageSpringNoParamsBlock={()->Void in
}



/**
 计算图片的尺寸大小
 
 - parameter image: 要计算的图片
 
 - returns: 返回图片的尺寸大小
 */
private func TLCacheCostForImage(image: UIImage)-> CGFloat{
    return image.size.height * image.size.width * image.scale * image.scale;
}

private func ImageDataHasPNGPreffix(nsdata nsdata:NSData)->Bool{
    let pngSignatrueLength:Int=kPNGSignatureBytes.count;
    if(nsdata.length>=pngSignatrueLength){
        if(nsdata.subdataWithRange(NSMakeRange(0, pngSignatrueLength)).isEqualToData(kPNGSignatureData!)){
            return true;
        }
    }
    return false;
}


public class TLImageCache: NSObject {
    
    /// 是否使用内存进行存储
    var shouldCatchImagesInMemory:Bool=true
    /// 设置能够使用内存存储的最大量
    var maxMemeoryCost:NSInteger?
    /// 在缓存中保存的时间周期，以秒为单位
    var maxCatchAge:NSTimeInterval!
    /// 在缓存中存储支持的最大容量
    var maxCatcheSize:UInt?
    
    
   
    private var tlNSCache:AutoNSCache?
    private var diskCachePath:String?;
    private var ioQueue:dispatch_queue_t!
    private var fileManager:NSFileManager!;
    
    
    /**
     根据一个命名空间初始化实例的方法
     
     - parameter nameSpace: 命名空间
     
     - returns: 对象实例
     */
    func initWithNameSpace(ns nameSpace:String)->TLImageCache{
        let path:NSString=self.makeDiskCachePath(nameSpace);
        return self.initWithNameSpace(ns: nameSpace, diskCatchDirectory: path);
    }
    
    /**
     初始化的方法
     
     - parameter nameSpace:          存储空间
     - parameter diskCatchDirectory: 硬盘的存储目录
     
     - returns: 类实例
     */
    func initWithNameSpace(ns nameSpace:String?,  diskCatchDirectory:NSString?)->TLImageCache{
    
        let fullPath:String="com.tongli.tlImageSpringcache".stringByAppendingString(nameSpace!);
        
        kPNGSignatureData=NSData(bytes: kPNGSignatureBytes, length: 8);
        //创建IO队列
        ioQueue=dispatch_queue_create("com.tongli.tlImageSpringCatch", DISPATCH_QUEUE_SERIAL);
        
        //初始化缓存的周期
        maxCatchAge=kDefaultCatchMaxCatchAge;
        tlNSCache=AutoNSCache();
        tlNSCache?.name=fullPath as String;
        
        if(diskCatchDirectory==nil){
            let path=self.makeDiskCachePath(nameSpace!);
            diskCachePath=path;
        }else{
            diskCachePath=diskCatchDirectory?.stringByAppendingPathComponent(fullPath);
        }
        
        //是否支持缓存
        shouldCatchImagesInMemory=true;
        
        //初始化Filemanager
        dispatch_sync(ioQueue!) { () -> Void in
            self.fileManager=NSFileManager()
        }
        
        //在收到内存警告后，主动清空缓存
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("clearMemory"), name: UIApplicationDidReceiveMemoryWarningNotification, object: nil);
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("cleanDisk"), name: UIApplicationWillTerminateNotification, object: nil);
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("backgroundCleanDisk"), name: UIApplicationDidEnterBackgroundNotification, object: nil);
        
    
        return self;
    }
    
    //MARK: - 初始化硬盘缓存的路径
    func makeDiskCachePath(nameSpace: String)->String{
        var array:Array=NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true);
        let cacheDir:NSString=array[0];
        return cacheDir.stringByAppendingPathComponent(nameSpace);
    }
    
    //MARK: - 缓存
    public func cachePathForKey(key:String,inPath:NSString)->String{
     //对文件名进行MD5加密
        let md5Name:String=key.TL_MD5;
        return inPath.stringByAppendingPathComponent(md5Name);
    }
    
    func defaultCachepathForKey(key:String)->String{
        return self.cachePathForKey(key, inPath: self.diskCachePath!);
    }
    
    //MARK: - 清理缓存
    /**
     完全清空缓存
     */
    public func clearMemory(){
        self.tlNSCache?.removeAllObjects();
    }
    
    /**
     清理硬盘缓存--部分清理
     */
    public func cleanDisk(){
    
    }
    
    /**
     后台清理缓存
     */
    public func backgroundCleanDisk(){
        if let UIApplication=NSClassFromString("UIApplication"){
            let application=UIApplication.sharedApplication();
            
            func endBackgroundTask(inout task:UIBackgroundTaskIdentifier){
                UIApplication.sharedApplication().endBackgroundTask(task);
                task=UIBackgroundTaskInvalid
            }
            
             var bgTask:UIBackgroundTaskIdentifier!
             bgTask=application.beginBackgroundTaskWithExpirationHandler({ () -> Void in
                endBackgroundTask(&bgTask!);
                
                self.cleanDiskWithCompletionHandler({ () -> () in
                    endBackgroundTask(&bgTask!);
                })
            });
        }
    
    }
    
    public func clearDiskOnCompletion(completionHandler:(()->())?){
     //异步处理
        dispatch_async(self.ioQueue!) { () -> Void in
            do{
                //删除文件或者目录
                try self.fileManager.removeItemAtPath(self.diskCachePath! as String);
                //然后创建一个空的目录，下次就不用再次创建了。
                try self.fileManager.createDirectoryAtPath(self.diskCachePath! as String, withIntermediateDirectories: true, attributes: nil);
            }catch _{
                
            }
            if let completionHandler=completionHandler{
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler();
                })
             }
    }
  }
    
    /**
     清空部分硬盘缓存
     - parameter compleHandler: 完成的回调函数
     */
    func cleanDiskWithCompletionHandler(compleHandler:()->()){
      dispatch_async(self.ioQueue) { () -> Void in
        let diskCacheUrl:NSURL = NSURL(fileURLWithPath: self.diskCachePath! , isDirectory: true);
        //获取文件的一些属性
        /**
         *  @ NSURLIsDirectoryKey 是否是目录的key
            @ NSURLContentModificationDateKey 文件的更新日期的key
           @ NSURLTotalFileAllocatedSizeKey 文件的size的key
        */
        
        let resouceKeys:Array=[NSURLIsDirectoryKey,NSURLContentModificationDateKey,NSURLTotalFileAllocatedSizeKey];
        
        //算出过期日期
        let expirateData:NSDate=NSDate(timeIntervalSinceNow: -self.maxCatchAge!);
        //表明缓存的字典
        var cacheFiles=[NSURL:[NSObject:AnyObject]]()
        var currentCacheSize:UInt=0;
        
        //遍历目录中所有的文件，删除过期的文件，按照文件的大小进行排序
        var urlDeleteFiles=[NSURL]()
        
        if let fileEnumerator=self.fileManager.enumeratorAtURL(diskCacheUrl, includingPropertiesForKeys: resouceKeys, options: .SkipsHiddenFiles, errorHandler: nil){
         
           let urls=fileEnumerator.allObjects as! [NSURL];
            for fileURL in urls{
                do{
                    let resourceValues=try fileURL.resourceValuesForKeys(resouceKeys);
                    
                    if let isDirectory = resourceValues[NSURLIsDirectoryKey] as? NSNumber{
                        if(isDirectory.boolValue){
                            continue;
                        }
                    }
                    //过期的文件加入到urlDeleteFiles中
                    if let modifyDate:NSDate=resourceValues[NSURLContentModificationDateKey] as? NSDate{
                        if modifyDate.laterDate(expirateData) == expirateData{
                            urlDeleteFiles.append(fileURL);
                            continue;
                        }
                    }
                    
                    if let totalAllocatedSize=resourceValues[NSURLTotalFileAllocatedSizeKey] as? NSNumber{
                        currentCacheSize += totalAllocatedSize.unsignedIntegerValue;
                    }
                    //向字典中插入对象
                    cacheFiles[fileURL]=resourceValues;
                } catch{
                
                }
            }
        }
        
        //删除过期的文件
        for fileURL in urlDeleteFiles{
            do{
               try  self.fileManager.removeItemAtURL(fileURL);
            }catch{
            
            }
        }
        
        //当前缓存的大小大于规定的容纳的最大值
        if(self.maxCatcheSize>0 && currentCacheSize>self.maxCatcheSize){
            let disiredCacheSize=self.maxCatcheSize!/2;
            
            //按照时间排序，最新的时间在最前面
            let sortedFiles=cacheFiles.keySortedByValue({ (resouceValue1, resouceValue2) -> Bool in
                if let date1=resouceValue1[NSURLContentModificationDateKey] as? NSDate,
                    date2=resouceValue2[NSURLContentModificationDateKey] as? NSDate{
                 return date1.compare(date2) == .OrderedAscending
                }
                return true;
            })
            
            //删除文件直到达到我们期望的缓存大小
            for fileURL in sortedFiles{
                do{
                    try self.fileManager.removeItemAtURL(fileURL);
                }catch{
                
                }
                if let resourceValues=cacheFiles[fileURL]{
                    let totalAllocatedSize=resourceValues[NSURLContentModificationDateKey] as! NSNumber;
                    currentCacheSize-=totalAllocatedSize.unsignedIntegerValue;
                    
                    if(currentCacheSize<disiredCacheSize){
                        break;
                    }
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            compleHandler();
        })
        
    }
        
}
    
    
}


extension Dictionary{
    func keySortedByValue(isOrderedBefore:(Value,Value)->Bool)->[Key]{
          return Array(self).sort{ isOrderedBefore($0.1, $1.1) }.map{ $0.0 }
    }
}




