# TLImageSpring-swift
<<<<<<< HEAD

[![CI Status](http://img.shields.io/travis/Andrew/TLImageSpring-swift.svg?style=flat)](https://travis-ci.org/Andrew/TLImageSpring-swift)
[![Version](https://img.shields.io/cocoapods/v/TLImageSpring-swift.svg?style=flat)](http://cocoapods.org/pods/TLImageSpring-swift)
[![License](https://img.shields.io/cocoapods/l/TLImageSpring-swift.svg?style=flat)](http://cocoapods.org/pods/TLImageSpring-swift)
[![Platform](https://img.shields.io/cocoapods/p/TLImageSpring-swift.svg?style=flat)](http://cocoapods.org/pods/TLImageSpring-swift)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

##preview


## Requirements

##How to use

导入 `import TLImageSpring_swift`模块，你便拥有了下载图片的功能


在tableviewCell中代码调用如下:

```
let placeImg=UIImage(named: "placeholder")
self.imgView?.TL_setImageWithURL(NSURL(string: imgUrl)!, placeholderImage: placeImg)
```

###传入一个结构体

其中TLParam是一个结构体，封装了你将要缓存的key和URL地址，
如果key不传入，默认将用URL地址作为key
```
let url=NSURL(string: imgUrl)
        self.imgView?.TL_setImageURLWithParam(TLParam(downloadURL: url!), placeHolderImage: placeImg)
```

###指定下载策略

下载可以采用几种方式:

```
 /**
  * 
   case  ForceRefresh = 100
   case  CacheMemoryOnly = 101
   case  BackgroundDecode = 102
   case  PlaceholdImage=103
   case  ProgressDownload=104
   case  RetryFailed=105
   case  LowPriority=106
   case  HighPriority=107
   */
self.imgView?.TL_setImageWithURL(url!, placeholderImage: placeImg, options: .CacheMemoryOnly)
```

###增加下载前的转子样式选择效果

默认加载的时候是带有转子效果的，但是不能选择，这个api提供选择不同的样式去开始转子动画效果
```
self.imgView?.TL_setImageWithURL(url!, placeHolderImage: placeImg, options: .CacheMemoryOnly, style: .Gray)
```

###带有回调函数-进度条监控-下载完成的回调处理

```
 self.imgView?.TL_setImageWithURL(url!, placeholderImage: placeImg, options: .CacheMemoryOnly, progrocessBlock: { (receivedSize, totalSize) -> () in
            
              print("接收到的:\(receivedSize),总共:\(totalSize)");
            }, completionHander: { (image, error, cacheType, imageUrl) -> () in
                //成功的处理函数
        })
```

###取消正在下载的任务

```
self.imgView?.TL_cancelDownloadTask()
```



## Installation

TLImageSpring-swift is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "TLImageSpring-swift"
```

## Author

Andrew, anluanlu123@163.com
我的邮箱:Andrewswift1987@gmail.com

## License

TLImageSpring-swift is available under the MIT license. See the LICENSE file for more info.
=======
从远程服务器上读取图片的框架，简单易用，支持缓存，异步下载等功能
>>>>>>> fb96f9d0ae05cb21096a4a66d9293e7f1b006fed
