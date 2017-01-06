//
//  TLImageThread.swift
//  Pods
//
//  Created by Andrew on 2017/1/6.
//
//

import UIKit

public class TLImageThread: NSObject {
    
    open class var shardThread:TLImageThread{
        return TLImageThread();
    }
    fileprivate override init() {
        super.init()
    }
    
    /**
     线程锁，等同于objc中的@Synchronized
     
     - parameter lock:  要锁的对象
     - parameter f:    函数调用
     */
    open func mySynchronized(_ lock:AnyObject,f:()->()){
        objc_sync_enter(lock);
        f();
        objc_sync_exit(lock);
    }
    
    /**
     同步调用主线程
     
     - parameter f:回调函数
     */
    open func disSyncMainThread(_ f:()->()){
        if(Thread.isMainThread){
            f();
        }else{
            DispatchQueue.main.sync(execute: f);
        }
    }
    
    
    /**
     异步调用主线程
     
     - parameter f:回调函数
     */
    open func disAsyncMainThread(_ f:@escaping ()->()){
        if(Thread.isMainThread){
            f();
        }else{
            DispatchQueue.main.async(execute: f);
        }
    }
    
    /**
     在指定的队列中执行回调
     
     - parameter queue: 指定的队列
     - parameter block: 回调函数
     */
    open func disSafe_Async_toQueue(_ queue:DispatchQueue,_ block: @escaping ()->()){
        if queue === DispatchQueue.main && Thread.isMainThread{
            block();
        }else{
            queue.async{
                block();
            }
        }
    }
    
    

}
