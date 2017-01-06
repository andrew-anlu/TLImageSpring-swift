//
//  RetrieveImageTask.swift
//  Pods
//
//  Created by Andrew on 2017/1/6.
//
//

import UIKit

open class RetrieveImageTask: NSObject {
    open var canceled:Bool=false
    
    public static let empty = RetrieveImageTask()
    
    //开启一个线程检索，从内存中检索图片
    open var diskRetrieveTask : RetrieveBlock?
    
    var retrieveImageDiskTask:RetrieveImageDiskTask?
    
    
    
    //从网络中异步下载图片
    open var downloadTask:DownloadIMGResult?
    
    /**
     取消一个下载任务
     */
    open func cancel(){
        //取消一个线程
        //        if let diskRetieveTask = diskRetrieveTask{
        //         dispatch_block_cancel(diskRetieveTask)
        //
        //            RetrieveImageDiskTask.cancel(<#T##DispatchWorkItem#>)
        //        }
        
        if let retrieveImageDiskTask = retrieveImageDiskTask{
            retrieveImageDiskTask.cancel()
            
        }
        if let download=downloadTask{
            download.cancel()
        }else{
            canceled=true
        }
    }

}
