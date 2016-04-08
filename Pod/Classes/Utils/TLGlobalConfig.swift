//
//  TLGlobalConfig.swift
//  Pods
//
//  Created by Andrew on 16/4/6.
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
  case TLIMGERROR_BADDATA = 500
  case TLIMGERROR_NOTMODIFIED = 501
  case TLIMGERROR_INVALIDURL = 502
}

public enum TLImgDownloadOpions:UInt{
  case  ForceRefresh = 100
  case  CacheMemoryOnly = 101
  case  BackgroundDecode = 102
}


 /// 下载图片进度条的闭包
public typealias TLImgSpringDownloadProgressBlock=((receivedSize:Int64,totalSize:Int64)->())
 /// 在manager中下载完成的回调函数
public typealias TLImgSpringCompleteBlock=((image:UIImage?,error:NSError?,cacheType:TLImageCacheType,imageUrl:NSURL?))


 /// 在downloader中下载完成的回调函数
public typealias TLIMGDownloadCompletionHandler=((image: UIImage?, error: NSError?, imageURL: NSURL?, originalData: NSData?) -> ())




