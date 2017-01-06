//
//  TLImageConfig.swift
//  Pods
//
//  Created by Andrew on 2017/1/5.
//
//

import Foundation

public let TLImageSpringErrorDomain = "com.tongli.tlImageSpring.error"

/**
 错误枚举
 
 - TLIMGERROR_BADDATA:     下载的不是不是合法的图片，或者压根就不是图片
 - TLIMGERROR_NOTMODIFIED: 远程服务器返回304错误
 - TLIMGERROR_INVALIDURL:  不合法的URL地址
 */
public enum TLIMGERROR:Int{
    case tlimgerror_BADDATA = 500
    case tlimgerror_NOTMODIFIED = 501
    case tlimgerror_INVALIDURL = 502
}

public enum TLImgDownloadOpions:UInt{
    case  forceRefresh = 100
    case  cacheMemoryOnly = 101
    case  backgroundDecode = 102
    case  placeholdImage=103
    case  progressDownload=104
    case  retryFailed=105
    case  lowPriority=106
    case  highPriority=107
}


/**
 缓存类型
 
 - TLImageCatchTypeNone:   还没有缓存
 - TLImageCatchTypeMemory: 在内存中缓存
 - TLImageCatchDisk:       在硬盘上缓存
 */
public enum TLImageCacheType{
    case  tlImageCatchTypeNone,tlImageCatchTypeMemory,tlImageCatchDisk
}

/// 下载图片进度条的闭包
public typealias TLImgSpringDownloadProgressBlock=((_ receivedSize:Int64,_ totalSize:Int64)->())
/// 在manager中下载完成的回调函数
public typealias TLImgSpringCompleteBlock=((_ image:UIImage?, _ error:NSError?,_ cacheType:TLImageCacheType, _ imageUrl:URL?)->())


/// 在downloader中下载完成的回调函数
public typealias TLIMGDownloadCompletionHandler=((_ image: UIImage?, _ error: NSError?, _ imageURL: URL?, _ originalData: Data?) -> ())



public final class TLImageSpring<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

extension TLImageSpring where Base:UIApplication{
    public static var shared: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        guard Base.responds(to: selector) else { return nil }
        return Base.perform(selector).takeUnretainedValue() as? UIApplication
    }
}


/**
 A type that has Kingfisher extensions.
 */
public protocol TLImageSpringCompatible {
    associatedtype CompatibleType
    var tl: CompatibleType { get }
}

public extension TLImageSpringCompatible {
    public var tl: TLImageSpring<Self> {
        get { return TLImageSpring(self) }
    }
}

