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





/**
 计算图片的尺寸大小
 
 - parameter image: 要计算的图片
 
 - returns: 返回图片的尺寸大小
 */
private func TLCacheCostForImage(image: UIImage)-> Int{
    return (Int)(image.size.height) * (Int)(image.size.width) * (Int)(image.scale) * (Int)(image.scale);
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
    
    
    public typealias RetrieveBlock=dispatch_block_t;
    
    
    
    
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
    
    //MARK: - 缓存路径
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
        cleanDiskWithCompletionHandler { () -> () in
            
        };
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
                        let totalAllocatedSize=resourceValues[NSURLTotalFileAllocatedSizeKey] as! NSNumber;
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
    
    //MARK: - 查询API
    func diskImageExistWithKey(key:String)->Bool{
        var isExist=false;
        isExist=NSFileManager.defaultManager().fileExistsAtPath(defaultCachepathForKey(key));
        
        if (!isExist){
            let path:NSString=defaultCachepathForKey(key) as NSString;
            
            isExist=NSFileManager.defaultManager().fileExistsAtPath(path.stringByDeletingPathExtension);
        }
        return isExist;
    }
    
    
    func diskImageExistWithKey(key:String,completion:((Bool)->Void)?){
        dispatch_async(self.ioQueue) { () -> Void in
            
            let path=self.defaultCachepathForKey(key) as NSString;
            
            var exists=self.fileManager.fileExistsAtPath(path as String);
            
            if(exists==false){
                exists=self.fileManager.fileExistsAtPath(path.stringByDeletingPathExtension);
            }
            
            if let completionHandler = completion{
                completionHandler(exists);
            }
            
        }
    }
    
    public func imageFromDiskcacheForkey(key:String)->UIImage?{
        
        //先从内存中读取
        if let image=self.imageFromMemoryCacheForkey(key){
            return image;
        }
        
        //如果内存中没有，再从硬盘上读取
        if let image=self.diskImageForkey(key){
            if(self.shouldCatchImagesInMemory){
                let cost=TLCacheCostForImage(image);
                self.tlNSCache?.setObject(image, forKey: key, cost: cost);
            }
            return image;
        }
        
        return nil;
    }
    
    public func imageFromMemoryCacheForkey(key:String)->UIImage?{
        return self.tlNSCache?.objectForKey(key) as? UIImage;
    }
    
    func diskImageForkey(key:String)->UIImage?{
        if let data=self.diskImageFromAllpathsForkey(key){
            let image=UIImage(data: data);
            return image;
        }
        
        return nil;
    }
    
    func diskImageFromAllpathsForkey(key:String)->NSData?{
        let defaultPath=self.defaultCachepathForKey(key) as NSString;
        
        if let data=NSData(contentsOfFile: defaultPath as String){
            return data;
        }
        
        if let data=NSData(contentsOfFile:defaultPath.stringByDeletingLastPathComponent) {
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
    public func queryImgFromDiskCacheForkey(key:String?,
        completionHandler: ((image:UIImage?,cacheType:TLImageCacheType)->())?)->RetrieveBlock?{
            guard let completionHandler = completionHandler else{
                return nil;
            }
            
            guard let key=key else{
                completionHandler(image: nil, cacheType: TLImageCacheType.TLImageCatchTypeNone);
                return nil;
            }
            var block:RetrieveBlock?
            //首先检查内存中的key
            if let image=self.imageFromMemoryCacheForkey(key){
                TLThreadUtils().disAsyncMainThread({ () -> () in
                    completionHandler(image: image, cacheType:TLImageCacheType.TLImageCatchTypeMemory);
                })
                return nil;
            }else{
                block=dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, { () -> Void in
                    //从硬盘中检查,异步调用多线程进行查询，因为速度可能会很慢
                    dispatch_async(self.ioQueue) { () -> Void in
                        if let image=self.imageFromDiskcacheForkey(key){
                            if(self.shouldCatchImagesInMemory){
                                let cost=TLCacheCostForImage(image);
                                self.tlNSCache?.setObject(image, forKey: key, cost: cost);
                            }
                            TLThreadUtils().disAsyncMainThread({ () -> () in
                                completionHandler(image: image, cacheType: TLImageCacheType.TLImageCatchDisk);
                            })
                            return;
                        }else{//如果没有找到图片在缓存和硬盘上
                            TLThreadUtils().disAsyncMainThread({ () -> () in
                                completionHandler(image: nil, cacheType: TLImageCacheType.TLImageCatchTypeNone);
                            })
                        }
                    }
                })
            }
        
            return block;
    }
    
    
    //MARK: - 存储和删除的API
    public func storeImage(image:UIImage,forKey:String){
        self.storeImage(image, recalculateFromImage: false, imageData: nil, key: forKey, toDisk: true, complateHander: nil);
        
    }
    
    public func storeImage(image:UIImage,forKey:String,toDisk:Bool){
        self.storeImage(image, recalculateFromImage: false, imageData: nil, key: forKey, toDisk: toDisk, complateHander: nil
        );
    }
    
    public func storeImage(image:UIImage,recalculateFromImage:Bool,imageData:NSData?,key:String,toDisk:Bool,complateHander:(()->())?){
        guard  image==image||key==key else{
            return;
        }
        
        func callHandlerInMainThread(){
            if let handler=complateHander{
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler();
                })
            }
        }
        
        //存储到内存中
        if(self.shouldCatchImagesInMemory){
            let cost=TLCacheCostForImage(image);
            self.tlNSCache?.setObject(image, forKey: key, cost: cost);
        }
        //如果要存储到硬盘上
        if(toDisk){
            //异步操作
            dispatch_async(self.ioQueue, { () -> Void in
                var data=imageData;
                if(recalculateFromImage){
                    let alphaInfo=CGImageGetAlphaInfo(image.CGImage);
                    let hasAlpha = !(alphaInfo == CGImageAlphaInfo.None ||
                        alphaInfo == CGImageAlphaInfo.NoneSkipFirst ||
                        alphaInfo == CGImageAlphaInfo.NoneSkipLast);
                    
                    var imageIsPng=hasAlpha;
                    
                    if(imageData!.length>=kPNGSignatureData?.length){
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
                let isExist:Bool=self.fileManager.fileExistsAtPath(self.diskCachePath!);
                if(isExist==false){
                    do{
                        try self.fileManager.createDirectoryAtPath(self.diskCachePath!, withIntermediateDirectories: true, attributes: nil);
                    }catch _{
                    }
                }
                //获取图片的缓存路径
                let cachePathForkey=self.defaultCachepathForKey(key);
                self.fileManager.createFileAtPath(cachePathForkey, contents: resultData, attributes: nil);
                callHandlerInMainThread();
            });
            
        }else{
            callHandlerInMainThread();
        }
        
    }
    
    public func removeImageForkey(key:String){
        self.removeImageForkey(key, fromDisk: true, completionHander: nil);
    }
    public func removeImageForkey(key:String,fromDisk:Bool){
        self.removeImageForkey(key, fromDisk: fromDisk, completionHander: nil);
    }
    
    public func removeImageForkey(key:String?,fromDisk:Bool,completionHander:(()->())?){
        guard let key = key else{
            return;
        }
        
        func callHandlerInMainThread(){
            if let handler=completionHander{
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    handler();
                })
            }
        }
        
        if (self.shouldCatchImagesInMemory){
            self.tlNSCache?.removeObjectForKey(key);
            
        }
        if(fromDisk){
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                do{
                    try self.fileManager.removeItemAtPath(self.defaultCachepathForKey(key))
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
    func keySortedByValue(isOrderedBefore:(Value,Value)->Bool)->[Key]{
        return Array(self).sort{ isOrderedBefore($0.1, $1.1) }.map{ $0.0 }
    }
}

extension TLImageCache{
    
    /**
     缓存类型
     
     - TLImageCatchTypeNone:   还没有缓存
     - TLImageCatchTypeMemory: 在内存中缓存
     - TLImageCatchDisk:       在硬盘上缓存
     */
    public enum TLImageCacheType{
      case  TLImageCatchTypeNone,TLImageCatchTypeMemory,TLImageCatchDisk
    }
    
    
    func getSize(completionHander:((Size:UInt)->())?){
        dispatch_sync(self.ioQueue) { () -> Void in
            let fileEnumerator=self.fileManager.enumeratorAtPath(self.diskCachePath!);
            
            let urls=fileEnumerator?.allObjects as? [NSString];
            func callHanderler(fileSize:UInt){
                if let hander=completionHander{
                    hander(Size: fileSize);
                }
            }
            var size:UInt=0;
            for fileName in urls!{
                if var filePath=self.diskCachePath{
                    filePath=(filePath as NSString).stringByAppendingPathComponent(fileName as String);
                    do{
                        let attrs=try NSFileManager.defaultManager().attributesOfFileSystemForPath(filePath) as Dictionary;
                        
                        let fileSize=attrs[NSURLTotalFileAllocatedSizeKey] as! UInt;
                        size+=fileSize;
                        
                    }catch _{
                        
                    }
                    
                }
            }
            callHanderler(size);
        }
    }
    
    
    func getCount(compleationHander:((Count:Int)->())?){
        dispatch_sync(dispatch_get_main_queue()) { () -> Void in
            
            var count : Int=0;
            
            func callHanderInMainThread(count:Int){
                if let hander=compleationHander{
                    hander(Count: count);
                }
            }
            
            if let fileEnumerator=self.fileManager.enumeratorAtPath(self.diskCachePath!){
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
    public func calculateSizeAndCountInDiskWIthCompletion(completionHander:((fileCount:Int,totalSize:Int)->())?){
        
        let diskCacheUrl=NSURL(fileURLWithPath: self.diskCachePath!, isDirectory: true);
        
        func callHanderInMainThread(count:Int,size:Int){
            if let hander=completionHander{
                hander(fileCount: count, totalSize: size);
            }
        }
        dispatch_async(self.ioQueue) { () -> Void in
            var fileCount=0;
            var totalSize:Int=0;
            
            if let fileEnumerator=self.fileManager.enumeratorAtURL(diskCacheUrl, includingPropertiesForKeys: [NSFileSize], options: .SkipsHiddenFiles, errorHandler: nil){
                let urls=fileEnumerator.allObjects as! [NSString];
                for fileUrl in urls{
                    
                    do{
                        let attrs=try NSFileManager.defaultManager().attributesOfFileSystemForPath(fileUrl as String)
                        
                        if let fileSize=attrs[NSURLTotalFileAllocatedSizeKey] as? Int {
                            totalSize=totalSize+fileSize;
                        }
                        fileCount++;
                        
                    }catch{
                        
                    }
                    
                }
            }
            callHanderInMainThread(fileCount, size: totalSize);
            
        }
    }
    
}




