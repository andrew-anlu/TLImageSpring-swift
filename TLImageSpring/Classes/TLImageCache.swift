//
//  TLImageCache.swift
//  Pods
//  缓存类 1.支持NSCache缓存  2.硬盘缓存
//  Created by Andrew on 16/4/6.
//
//

import UIKit

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}



/// 自定义AutoNSCache类
class AutoNSCache:NSCache<AnyObject, AnyObject> {
    override init() {
        super.init();
        //当收到缓存警告的时候，主动调用NSCatch的`removeAllObjects`去清空缓存
        NotificationCenter.default.addObserver(self, selector:#selector(NSMutableArray.removeAllObjects), name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil);
    }
    //当程序退出的时候，调用反初始化函数
    deinit{
        NotificationCenter.default.removeObserver(self);
    }
}

private let kDefaultCatchMaxCatchAge:TimeInterval=60 * 60 * 24 * 7;//默认保存一周
private var kPNGSignatureData:Data?
private var kPNGSignatureBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

public typealias RetrieveBlock=()->();

public typealias RetrieveImageDiskTask = DispatchWorkItem




/**
 计算图片的尺寸大小
 
 - parameter image: 要计算的图片
 
 - returns: 返回图片的尺寸大小
 */
private func TLCacheCostForImage(_ image: UIImage)-> Int{
    return (Int)(image.size.height) * (Int)(image.size.width) * (Int)(image.scale) * (Int)(image.scale);
}

private func ImageDataHasPNGPreffix(nsdata:Data)->Bool{
    let pngSignatrueLength:Int=kPNGSignatureBytes.count;
    if(nsdata.count>=pngSignatrueLength){
//        if(nsdata.subdata(in: NSMakeRange(0, pngSignatrueLength)) == kPNGSignatureData!){
//            return true;
//        }

        let range = Range(uncheckedBounds: (lower: 0, upper: pngSignatrueLength))
        
        if nsdata.subdata(in: range) == kPNGSignatureData!{
          return true
        }
    }
    return false;
}




private let cacheInstance = TLImageCache(nameSpace: "default");

open class TLImageCache: NSObject {
    
    /// 是否使用内存进行存储
    var shouldCatchImagesInMemory:Bool=true
    /// 设置能够使用内存存储的最大量
    var maxMemeoryCost:NSInteger?
    /// 在缓存中保存的时间周期，以秒为单位
    var maxCatchAge:TimeInterval!
    /// 在缓存中存储支持的最大容量
    var maxCatcheSize:UInt?
    
    
    
    
    
    
    
    fileprivate var tlNSCache:AutoNSCache?
    fileprivate var diskCachePath:String?;
    fileprivate var ioQueue:DispatchQueue!
    fileprivate var processQueue:DispatchQueue!
    fileprivate var fileManager:FileManager!;
    
    open class var defaultCache:TLImageCache{
      return cacheInstance
    }
    
    /**
     根据一个命名空间初始化实例的方法
     
     - parameter nameSpace: 命名空间
     
     - returns: 对象实例
     */
     public init(nameSpace:String?,  diskCatchDirectory:NSString?=nil){
         super.init();
        let fullPath:String="com.tongli.tlImageSpringcache" + nameSpace!;
        
        kPNGSignatureData=Data(bytes: UnsafePointer(kPNGSignatureBytes), count: 8);
        //创建IO队列
        ioQueue=DispatchQueue(label: "com.tongli.tlImageSpringCatch.ioQueue", attributes: []);
        
        processQueue=DispatchQueue(label: "com.tongli.tlImageSpringCache.processQueue", attributes: DispatchQueue.Attributes.concurrent)
        
        //初始化缓存的周期
        maxCatchAge=kDefaultCatchMaxCatchAge;
        tlNSCache=AutoNSCache();
        tlNSCache?.name=fullPath as String;
        
        if(diskCatchDirectory==nil){
            let path=self.makeDiskCachePath(nameSpace!);
            diskCachePath=path;
        }else{
            diskCachePath=diskCatchDirectory?.appendingPathComponent(fullPath);
        }
        
        //是否支持缓存
        shouldCatchImagesInMemory=true;
        
        //初始化Filemanager
        ioQueue!.sync { () -> Void in
            self.fileManager=FileManager()
        }
        
        //在收到内存警告后，主动清空缓存
        NotificationCenter.default.addObserver(self, selector: #selector(TLImageCache.clearMemory), name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(TLImageCache.cleanDisk), name: NSNotification.Name.UIApplicationWillTerminate, object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(TLImageCache.backgroundCleanDisk), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil);
        

    }
    deinit{
     NotificationCenter.default.removeObserver(self)
    }

    
    /**
     初始化的方法
     
     - parameter nameSpace:          存储空间
     - parameter diskCatchDirectory: 硬盘的存储目录
     
     - returns: 类实例
     */
//    func initWithNameSpace(ns nameSpace:String?,  diskCatchDirectory:NSString?)->TLImageCache{
//        
//        
//        
//        return self;
//    }
//    
    //MARK: - 初始化硬盘缓存的路径
    func makeDiskCachePath(_ nameSpace: String)->String{
        var array:Array=NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true);
        let cacheDir:NSString=array[0] as NSString;
        return cacheDir.appendingPathComponent(nameSpace);
    }
    
    //MARK: - 缓存路径
    open func cachePathForKey(_ key:String,inPath:NSString)->String{
        //对文件名进行MD5加密
        let md5Name:String=key.kf.md5
        return inPath.appendingPathComponent(md5Name);
    }
    
    func defaultCachepathForKey(_ key:String)->String{
        return self.cachePathForKey(key, inPath: self.diskCachePath! as NSString);
    }
    
    //MARK: - 清理缓存
    /**
    完全清空缓存
    */
    open func clearMemory(){
        self.tlNSCache?.removeAllObjects();
    }
    
    /**
     清理硬盘缓存--部分清理
     */
    open func cleanDisk(){
        cleanDiskWithCompletionHandler { () -> () in
            
        };
    }
    
    /**
     后台清理缓存
     */
    open func backgroundCleanDisk(){
        
        guard let sharedApplication = TLImageSpring<UIApplication>.shared else { return }


        
        
            func endBackgroundTask(_ task:inout UIBackgroundTaskIdentifier){
                sharedApplication.endBackgroundTask(task)
                task=UIBackgroundTaskInvalid
            }
            
            var bgTask:UIBackgroundTaskIdentifier!
            bgTask=sharedApplication.beginBackgroundTask(expirationHandler: { () -> Void in
                endBackgroundTask(&bgTask!);
                
                self.cleanDiskWithCompletionHandler({ () -> () in
                    endBackgroundTask(&bgTask!);
                })
            });
        
    }
    
    open func clearDiskOnCompletion(_ completionHandler:(()->())?){
        //异步处理
        self.ioQueue!.async { () -> Void in
            do{
                //删除文件或者目录
                try self.fileManager.removeItem(atPath: self.diskCachePath! as String);
                //然后创建一个空的目录，下次就不用再次创建了。
                try self.fileManager.createDirectory(atPath: self.diskCachePath! as String, withIntermediateDirectories: true, attributes: nil);
            }catch _{
                
            }
            if let completionHandler=completionHandler{
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHandler();
                })
            }
            
            
        }
    }
    
    
    /**
     清空部分硬盘缓存
     - parameter compleHandler: 完成的回调函数
     */
    func cleanDiskWithCompletionHandler(_ compleHandler:@escaping ()->()){
        self.ioQueue.async { () -> Void in
            let diskCacheUrl:URL = URL(fileURLWithPath: self.diskCachePath! , isDirectory: true);
            //获取文件的一些属性
            /**
            *  @ NSURLIsDirectoryKey 是否是目录的key
            @ NSURLContentModificationDateKey 文件的更新日期的key
            @ NSURLTotalFileAllocatedSizeKey 文件的size的key
            */
            
            let resouceKeys:Array=[URLResourceKey.isDirectoryKey,URLResourceKey.contentModificationDateKey,URLResourceKey.totalFileAllocatedSizeKey];
            
            //算出过期日期
            let expirateData:Date=Date(timeIntervalSinceNow: -self.maxCatchAge!);
            //表明缓存的字典
            var cacheFiles=[URL:[AnyHashable: Any]]()
            var currentCacheSize:UInt=0;
            
            //遍历目录中所有的文件，删除过期的文件，按照文件的大小进行排序
            var urlDeleteFiles=[URL]()
            
            if let fileEnumerator=self.fileManager.enumerator(at: diskCacheUrl, includingPropertiesForKeys: resouceKeys, options: .skipsHiddenFiles, errorHandler: nil){
                
                let urls=fileEnumerator.allObjects as! [URL];
                for fileURL in urls{
                    do{
                        let resourceValues=try (fileURL as NSURL).resourceValues(forKeys: resouceKeys);
                        
                        if let isDirectory = resourceValues[URLResourceKey.isDirectoryKey] as? NSNumber{
                            if(isDirectory.boolValue){
                                continue;
                            }
                        }
                        //过期的文件加入到urlDeleteFiles中
                        if let modifyDate:Date=resourceValues[URLResourceKey.contentModificationDateKey] as? Date{
                            if (modifyDate as NSDate).laterDate(expirateData) == expirateData{
                                urlDeleteFiles.append(fileURL);
                                continue;
                            }
                        }
                        
                        if let totalAllocatedSize=resourceValues[URLResourceKey.totalFileAllocatedSizeKey] as? NSNumber{
                            currentCacheSize += totalAllocatedSize.uintValue;
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
                    try  self.fileManager.removeItem(at: fileURL);
                }catch{
                    
                }
            }
            
            //当前缓存的大小大于规定的容纳的最大值
            if(self.maxCatcheSize>0 && currentCacheSize>self.maxCatcheSize){
                let disiredCacheSize=self.maxCatcheSize!/2;
                
                //按照时间排序，最新的时间在最前面
                let sortedFiles=cacheFiles.keySortedByValue({ (resouceValue1, resouceValue2) -> Bool in
                    if let date1=resouceValue1[URLResourceKey.contentModificationDateKey] as? Date,
                        let date2=resouceValue2[URLResourceKey.contentModificationDateKey] as? Date{
                            return date1.compare(date2) == .orderedAscending
                    }
                    return true;
                })
                
                //删除文件直到达到我们期望的缓存大小
                for fileURL in sortedFiles{
                    do{
                        try self.fileManager.removeItem(at: fileURL);
                    }catch{
                        
                    }
                    if let resourceValues=cacheFiles[fileURL]{
                        let totalAllocatedSize=resourceValues[URLResourceKey.totalFileAllocatedSizeKey] as! NSNumber;
                        currentCacheSize-=totalAllocatedSize.uintValue;
                        
                        if(currentCacheSize<disiredCacheSize){
                            break;
                        }
                    }
                }
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                compleHandler();
            })
            
        }
        
    }
    
    //MARK: - 查询API
   open func diskImageExistWithKey(_ key:String)->Bool{
        var isExist=false;
        isExist=FileManager.default.fileExists(atPath: defaultCachepathForKey(key));
        
        if (!isExist){
            let path:NSString=defaultCachepathForKey(key) as NSString;
            
            isExist=FileManager.default.fileExists(atPath: path.deletingPathExtension);
        }
        return isExist;
    }
    
    
   open func diskImageExistWithKey(_ key:String,completion:((Bool)->Void)?){
        self.ioQueue.async { () -> Void in
            
            let path=self.defaultCachepathForKey(key) as NSString;
            
            var exists=self.fileManager.fileExists(atPath: path as String);
            
            if(exists==false){
                exists=self.fileManager.fileExists(atPath: path.deletingPathExtension);
            }
            
            if let completionHandler = completion{
                completionHandler(exists);
            }
            
        }
    }
    
    open func imageFromDiskcacheForkey(_ key:String)->UIImage?{
        
        //先从内存中读取
        if let image=self.imageFromMemoryCacheForkey(key){
            return image;
        }
        
        //如果内存中没有，再从硬盘上读取
        if let image=self.diskImageForkey(key){
            if(self.shouldCatchImagesInMemory){
                let cost=TLCacheCostForImage(image);
                self.tlNSCache?.setObject(image, forKey: key as AnyObject, cost: cost);
            }
            return image;
        }
        
        return nil;
    }
    
    open func imageFromMemoryCacheForkey(_ key:String)->UIImage?{
        return self.tlNSCache?.object(forKey: key as AnyObject) as? UIImage;
    }
    
    func diskImageForkey(_ key:String)->UIImage?{
        if let data=self.diskImageFromAllpathsForkey(key){
            let image=UIImage(data: data);
            return image;
        }
        
        return nil;
    }
    
    func diskImageFromAllpathsForkey(_ key:String)->Data?{
        let defaultPath=self.defaultCachepathForKey(key) as NSString;
        
        if let data=try? Data(contentsOf: URL(fileURLWithPath: defaultPath as String)){
            return data;
        }
        
        if let data=try? Data(contentsOf: URL(fileURLWithPath: defaultPath.deletingLastPathComponent)) {
            return data ;
        }
        
        
        return nil;
        
    }

    //MARK:根据一个key，从内存或者硬盘中查询是否存在图片
    /**
     根据一个key，从内存或者硬盘中查询是否存在图片
     
     - parameter key:               存储图片资源对应的key
     - parameter completionHandler: 完成的回调函数
     - parameter cacheType:         缓存类型
     */
    open func queryImgFromDiskCacheForkey(_ key:String?,
        completionHandler: ((_ image:UIImage?,_ cacheType:TLImageCacheType)->())?)->RetrieveBlock?{
            guard let completionHandler = completionHandler else{
                return nil;
            }
            
            guard let key=key else{
                completionHandler(nil, TLImageCacheType.tlImageCatchTypeNone);
                return nil;
            }
//            var block:RetrieveBlock?
        var block:RetrieveImageDiskTask?
            //首先检查内存中的key
            if let image=self.imageFromMemoryCacheForkey(key){
                TLImageThread.shardThread.disAsyncMainThread({ () -> () in
                    completionHandler(image, TLImageCacheType.tlImageCatchTypeMemory);
                })
                return nil;
            }else{
                var sSelf: TLImageCache! = self
                
                block = DispatchWorkItem(block: {
                    sSelf.processQueue.async(execute: { () -> Void in
                        if let image=self.imageFromDiskcacheForkey(key){
                            if(self.shouldCatchImagesInMemory){
                                let cost=TLCacheCostForImage(image);
                                self.tlNSCache?.setObject(image, forKey: key as AnyObject, cost: cost);
                            }
                            TLImageThread.shardThread.disAsyncMainThread({ () -> () in
                                completionHandler(image, TLImageCacheType.tlImageCatchDisk);
                                sSelf=nil
                            })
                            return;
                        }else{//如果没有找到图片在缓存和硬盘上
                            TLImageThread.shardThread.disAsyncMainThread({ () -> () in
                                completionHandler(nil, TLImageCacheType.tlImageCatchTypeNone);
                                sSelf=nil
                            })
                        }
                    })
                })
                
                
                sSelf.ioQueue.async(execute: block!)
            }
        return nil
        
    }
    
    
    //MARK: - 存储和删除的API
    open func storeImage(_ image:UIImage,forKey:String){
        self.storeImage(image, recalculateFromImage: false, imageData: nil, key: forKey, toDisk: true, complateHander: nil);
        
    }
    
    open func storeImage(_ image:UIImage,forKey:String,toDisk:Bool){
        self.storeImage(image, recalculateFromImage: false, imageData: nil, key: forKey, toDisk: toDisk, complateHander: nil
        );
    }
    
    open func storeImage(_ image:UIImage,recalculateFromImage:Bool,imageData:Data?,key:String,toDisk:Bool,complateHander:(()->())?){
        guard  image==image||key==key else{
            return;
        }
        
        func callHandlerInMainThread(){
            if let handler=complateHander{
                DispatchQueue.main.async(execute: { () -> Void in
                    handler();
                })
            }
        }
        
        //存储到内存中
        if(self.shouldCatchImagesInMemory){
            let cost=TLCacheCostForImage(image);
            self.tlNSCache?.setObject(image, forKey: key as AnyObject, cost: cost);
        }
        //如果要存储到硬盘上
        if(toDisk){
            //异步操作
            self.ioQueue.async(execute: { () -> Void in
                var data=imageData;
                if(recalculateFromImage){
                    let alphaInfo=image.cgImage?.alphaInfo;
                    let hasAlpha = !(alphaInfo == CGImageAlphaInfo.none ||
                        alphaInfo == CGImageAlphaInfo.noneSkipFirst ||
                        alphaInfo == CGImageAlphaInfo.noneSkipLast);
                    
                    var imageIsPng=hasAlpha;
                    
                    if(imageData!.count>=kPNGSignatureData?.count){
                        imageIsPng=ImageDataHasPNGPreffix(nsdata: imageData!);
                    }
                    
                    //如果是PNG图片
                    if(imageIsPng){
                        data=UIImagePNGRepresentation(image)!;
                    }else{
                        data=UIImageJPEGRepresentation(image,1)!;
                    }
                }
                
                guard let resultData = data else{
                    return;
                }
                let isExist:Bool=self.fileManager.fileExists(atPath: self.diskCachePath!);
                if(isExist==false){
                    do{
                        try self.fileManager.createDirectory(atPath: self.diskCachePath!, withIntermediateDirectories: true, attributes: nil);
                    }catch _{
                    }
                }
                //获取图片的缓存路径
                let cachePathForkey=self.defaultCachepathForKey(key);
                self.fileManager.createFile(atPath: cachePathForkey, contents: resultData, attributes: nil);
                callHandlerInMainThread();
            });
            
        }else{
            callHandlerInMainThread();
        }
        
    }
    
    open func removeImageForkey(_ key:String){
        self.removeImageForkey(key, fromDisk: true, completionHander: nil);
    }
    open func removeImageForkey(_ key:String,fromDisk:Bool){
        self.removeImageForkey(key, fromDisk: fromDisk, completionHander: nil);
    }
    
    open func removeImageForkey(_ key:String?,fromDisk:Bool,completionHander:(()->())?){
        guard let key = key else{
            return;
        }
        
        func callHandlerInMainThread(){
            if let handler=completionHander{
                DispatchQueue.main.async(execute: { () -> Void in
                    handler();
                })
            }
        }
        
        if (self.shouldCatchImagesInMemory){
            self.tlNSCache?.removeObject(forKey: key as AnyObject);
            
        }
        if(fromDisk){
            DispatchQueue.main.async(execute: { () -> Void in
                do{
                    try self.fileManager.removeItem(atPath: self.defaultCachepathForKey(key))
                    callHandlerInMainThread();
                } catch{
                    
                }
            })
        }else{
            callHandlerInMainThread();
        }
        
    }
    
}

//MARK: - 扩展
extension Dictionary{
    func keySortedByValue(_ isOrderedBefore:(Value,Value)->Bool)->[Key]{
        return Array(self).sorted{ isOrderedBefore($0.1, $1.1) }.map{ $0.0 }
    }
}

extension TLImageCache{
    
 
    
    func getSize(_ completionHander:((_ Size:UInt)->())?){
        self.ioQueue.sync { () -> Void in
            let fileEnumerator=self.fileManager.enumerator(atPath: self.diskCachePath!);
            
            let urls=fileEnumerator?.allObjects as? [NSString];
            func callHanderler(_ fileSize:UInt){
                if let hander=completionHander{
                    hander(fileSize);
                }
            }
            var size:UInt=0;
            for fileName in urls!{

                if var filePath=self.diskCachePath{
                    filePath=(filePath as NSString).appendingPathComponent(fileName as String);
                    do{
                        let attrs=try FileManager.default.attributesOfFileSystem(forPath: filePath) as Dictionary;
                        
                      
                        
                        let fileSize=attrs[FileAttributeKey.size] as! UInt;
                        
                        
                        size+=fileSize;
                        
                    }catch _{
                        
                    }
                    
                }
            }
            callHanderler(size);
        }
    }
    
    
    func getCount(_ compleationHander:((_ Count:Int)->())?){
        DispatchQueue.main.sync { () -> Void in
            
            var count : Int=0;
            
            func callHanderInMainThread(_ count:Int){
                if let hander=compleationHander{
                    hander(count);
                }
            }
            
            if let fileEnumerator=self.fileManager.enumerator(atPath: self.diskCachePath!){
                count=fileEnumerator.allObjects.count;
                
                callHanderInMainThread(count);
            }
        }
    }
    /**
     计算缓存文件的大小和总数量
     
     - parameter completionHander:  完成的回调函数
     - parameter totalSize:        <#totalSize description#>
     */
    public func calculateSizeAndCountInDiskWIthCompletion(_ completionHander:((_ fileCount:Int,_ totalSize:Int)->())?){
        
        let diskCacheUrl=URL(fileURLWithPath: self.diskCachePath!, isDirectory: true);
        
        func callHanderInMainThread(_ count:Int,size:Int){
            if let hander=completionHander{
                hander(count, size);
            }
        }
        
        let resourceKeys = [URLResourceKey.isDirectoryKey, URLResourceKey.contentAccessDateKey, URLResourceKey.totalFileAllocatedSizeKey]
        
        var fileCount=0;
        var totalSize:Int=0;
        
        let fileManager = FileManager()
        
        
        if let fileEnumerator = fileManager.enumerator(at: diskCacheUrl, includingPropertiesForKeys: resourceKeys, options: .skipsHiddenFiles, errorHandler: nil)
        {
            let urls=fileEnumerator.allObjects as! [NSString];
            for fileUrl in urls{
                
                do{
                    let attrs=try FileManager.default.attributesOfFileSystem(forPath: fileUrl as String)
                    
               
                    
                    if let fileSize=attrs[FileAttributeKey.size] as? Int {
                        totalSize=totalSize+fileSize;
                    }
                    fileCount += 1;
                    
                }catch{
                    
                }
                
            }
        }
        callHanderInMainThread(fileCount, size: totalSize);
       
    }
    
}




