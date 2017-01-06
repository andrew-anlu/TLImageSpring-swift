//
//  TLActivityIndicator.swift
//  Pods
//
//  Created by Andrew on 2017/1/6.
//
//

import UIKit

class TLActivityIndicator: NSObject {

    //单例方法1
    static let shardInstance:TLActivityIndicator = TLActivityIndicator()
    
    //禁用外部调用初始化方法
    private override init() {
        
    }
    
    var count : Int=0;
    
    func startActivity() -> Void {
        TLImageThread.shardThread.mySynchronized(self) { 
            if(self.count > 0 && self.count==0){
                UIApplication.shared.isNetworkActivityIndicatorVisible=true;
            }
        }
    }
    
    func stopActivity() -> Void {
        TLImageThread.shardThread.mySynchronized(self) {
            if(self.count > 0 && self.count==0){
                UIApplication.shared.isNetworkActivityIndicatorVisible=false;
            }
        }
    }
    
    
    open func stopAllActivity(){
        TLImageThread.shardThread.mySynchronized(self) { () -> () in
            self.count=0;
            UIApplication.shared.isNetworkActivityIndicatorVisible=false;
        }
    }
    
    func myWorld() -> Void {
        print("我的世界充满阳光")
    }
    
}
