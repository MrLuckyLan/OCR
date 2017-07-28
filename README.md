
<h3>OpenCV是一个开源跨平台的的计算机视觉和机器学习库，可以用来做图片视频的处理、图形识别、机器学习等应用</h3>

<h5>安装<h5>

第一种方式很简单，再podfile中加入pod 'OpenCV-iOS', '~> 3.1'，然后运行pod install就行，网速慢成功率很低。
ps:安装前可以先 pod search OpenCV 查看当前最新版本

第二种方式就是去官网下载，http://opencv.org/releases.html。将下载的opencv2.framework.zip解压拖入工程

配置依赖库
首先将下载好的opencv2.framework添加到项目中，并且将OpenCV所需的依赖库添加到项目中。

* libc++.tbd
* AVFoundation.framework
* CoreImage.framework
* CoreGraphics.framework
* QuartzCore.framework
* Accelerate.framework
如果要使用摄像头做视频处理，还需要添加以下两个依赖库：

* CoreVideo.framework
* CoreMedia.framework
* AssetsLibrary.framework



配置头文件

为了避免import的麻烦。接下来在开发过程中想要使用OpenCV时，只需要把要使用的文件改为.mm格式以支持C++，就可以直接编写代码了

打开项目中的Prefix.pch文件，在两段文字中间加入下列语句：

1. #import <Availability.h>  
2.   
3. #ifndef __IPHONE_5_0  
4. #warning "This project uses features only available in iOS SDK 5.0 and later."  
5. #endif  
6.   
7. #ifdef __cplusplus  
8.     #include <opencv2/opencv.hpp> //需要添加的语句  
9.   
10. #endif  
11.   
12. #ifdef __OBJC__  
13.   #import <UIKit/UIKit.h>  
14.   #import <Foundation/Foundation.h>  
15. #endif#import <Availability.h>  
16.   
17. #ifndef __IPHONE_5_0  
18. #warning "This project uses features only available in iOS SDK 5.0 and later."  
19. #endif  
20.   
21. #ifdef __cplusplus  
22.     #include <opencv2/opencv.hpp> //需要添加的语句  
23. #endif  
24.   
25. #ifdef __OBJC__  
26.   #import <UIKit/UIKit.h>  
27.   #import <Foundation/Foundation.h>  
28. #endif  


可能碰到的问题

以前的版本，比如我以前使用的2.4.11的版本，在导入``opencv2.framework```添加到项目后，运行可能碰到以下错误:
Undefined symbols for architecture x86_64:
"_jpeg_free_large", referenced from:
_free_pool in opencv2(jmemmgr.o)
"_jpeg_free_small", referenced from:
_free_pool in opencv2(jmemmgr.o)
_self_destruct in opencv2(jmemmgr.o)
"_jpeg_get_large", referenced from:
_alloc_large in opencv2(jmemmgr.o)
_alloc_barray in opencv2(jmemmgr.o)
"_jpeg_get_small", referenced from:
_jinit_memory_mgr in opencv2(jmemmgr.o)
_alloc_small in opencv2(jmemmgr.o)
"_jpeg_mem_available", referenced from:
_realize_virt_arrays in opencv2(jmemmgr.o)
"_jpeg_mem_init", referenced from:
_jinit_memory_mgr in opencv2(jmemmgr.o)
"_jpeg_mem_term", referenced from:
_jinit_memory_mgr in opencv2(jmemmgr.o)
_self_destruct in opencv2(jmemmgr.o)
"_jpeg_open_backing_store", referenced from:
_realize_virt_arrays in opencv2(jmemmgr.o)
ld: symbol(s) not found for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
经过网上搜索得知是缺少了libjpeg.a依赖库，你可以在网上搜索这个a文件，下载后使用lipo -info libjpeg.a查看是否包含armv6 armv7 armv7s arm64支持。当然也可以直接下载libjpeg-turbo，安装后直接从此路径/opt/libjpeg-turbo/lib/libjpeg.a复制加入到项目中。不过在最新的OpenCV 2.4.13版本已经不会这个错误提示了。

如果运行上面的例子出现出现以下错误:

Undefined symbols for architecture arm64:
"_OBJC_CLASS_$_ALAssetsLibrary", referenced from:
objc-class-ref in opencv2(cap_ios_video_camera.o)
"_CMSampleBufferGetPresentationTimeStamp", referenced from:
-[CvVideoCamera captureOutput:didOutputSampleBuffer:fromConnection:] in opencv2(cap_ios_video_camera.o)
"_CMTimeMake", referenced from:
-[CvVideoCamera createVideoDataOutput] in opencv2(cap_ios_video_camera.o)
"_CMSampleBufferGetImageBuffer", referenced from:
-[CaptureDelegate captureOutput:didOutputSampleBuffer:fromConnection:] in opencv2(cap_avfoundation.o)
-[CvVideoCamera captureOutput:didOutputSampleBuffer:fromConnection:] in opencv2(cap_ios_video_camera.o)
ld: symbol(s) not found for architecture arm64
clang: error: linker command failed with exit code 1 (use -v to see invocation)

这是因为我们使用了摄像头和视频， 需要导入CoreVideo.framework，CoreMedia.framework，AssetsLibrary.framework三个库即不会出错了。


补充:

顺序很重要

#import <opencv2/opencv.hpp>

#import <opencv2/videoio/cap_ios.h>

#import <opencv2/objdetect/objdetect.hpp>

#import <opencv2/imgproc/imgproc_c.h>

#import <opencv2/highgui.hpp>

#import <opencv2/imgproc/types_c.h>

#import <opencv2/imgcodecs/ios.h>


如果同时使用tesseractOCR  

1.pod   tesseractOCR 
报错记得设置   target buildsetting   搜索 bitcode  设置为NO

2.opencv 官网下载最新opencv.framwork


注意: 项目中如果有pch的话, y要在里面j加上
#ifdef __cplusplus  
    #include <opencv2/opencv.hpp> //需要添加的语句  
#endif  











