//
//  TLNetworkActivityIndicator.swift
//  Pods
//
//  Created by Andrew on 16/4/6.
//
//

import UIKit
import Foundation


public class TLNetworkActivityIndicator: NSObject {
    
    
    var count : Int=0;
    
    /// 单例模式
    public class var shardActivityIndicator:TLNetworkActivityIndicator{
        struct Static {
            static var onceToken:dispatch_once_t=0;
            static var instance:TLNetworkActivityIndicator?=nil
        }
        
        dispatch_once(&Static.onceToken) { () -> Void in
            Static.instance=TLNetworkActivityIndicator()
        }
        
        return Static.instance!;
    }
    
    /**
     开始启动
     */
    public func startActivity(){
      TLThreadUtils().mySynchronized(self) { () -> () in
        self.count++;
        UIApplication.sharedApplication().networkActivityIndicatorVisible=true;
        }
    }
    
    /**
     结束
     */
    public func stopActivity(){
        TLThreadUtils().mySynchronized(self) { () -> () in
            if(self.count > 0 && --self.count==0){
                UIApplication.sharedApplication().networkActivityIndicatorVisible=false;
            }
        }
    }
    
    public func stopAllActivity(){
    TLThreadUtils().mySynchronized(self) { () -> () in
        self.count=0;
        UIApplication.sharedApplication().networkActivityIndicatorVisible=false;
        }
    }
    
    
  
    
    

    
    
    
    
    
    
    
}
