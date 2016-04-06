//
//  TLThreadUtils.swift
//  Pods
//
//  Created by Andrew on 16/4/6.
//
//

import UIKit
import Foundation


public class TLThreadUtils: NSObject {
    /**
     线程锁，等同于objc中的@Synchronized
     
     - parameter lock:  要锁的对象
     - parameter f:    函数调用
     */
   public func mySynchronized(lock:AnyObject,f:()->()){
        objc_sync_enter(lock);
        f();
        objc_sync_exit(lock);
    }
    
    /**
     同步调用主线程
     
     - parameter f:回调函数
     */
    public func disSyncMainThread(f:()->()){
        if(NSThread.isMainThread()){
            f();
        }else{
            dispatch_sync(dispatch_get_main_queue(),f);
        }
    }
    
    
    /**
     同步调用主线程
     
     - parameter f:回调函数
     */
    public func disAsyncMainThread(f:()->()){
        if(NSThread.isMainThread()){
            f();
        }else{
            dispatch_async(dispatch_get_main_queue(),f);
        }
    }
    
    
    
    
    
    
    
    
    
    
    
}
