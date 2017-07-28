//
//  opencvManger.m
//  OCR
//
//  Created by CBS on 2017/5/2.
//  Copyright © 2017年 CBS. All rights reserved.
//

#define MAXRATIO 2.5 //2.25 2.30
#define MINRATIO 2.0



#import <opencv2/opencv.hpp>

#import <opencv2/videoio/cap_ios.h>
#import <opencv2/objdetect/objdetect.hpp>
#import <opencv2/imgproc/imgproc_c.h>

#import <opencv2/highgui.hpp>

#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgcodecs/ios.h>


#import <TesseractOCR/TesseractOCR.h>


//#import "AssetsLibrary.h "
#import <AssetsLibrary/AssetsLibrary.h>

#import "Moment.h"
#import "MJExtension.h"
#import "MomentCachesTool.h"

#import "opencvManger.h"

@implementation opencvManger


int Otsu(unsigned char*, int, int, int);
int otsub(IplImage*);
bool GetHistogram(unsigned char*, int, int, int, int*);





+ (instancetype)Manger{
    static opencvManger *manger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manger = [[opencvManger alloc] init];
    });
    return manger;
}



- (void)recognizeCardImage:(UIImage *)cardImage compleate:(Compleate)compleate fault:(Fault)fault{
    
    
    UIImage *numberImage = [self locationNumPicWithCard:cardImage];
    NSString *cardNumber = [self tesseractImage:numberImage Language:@"eng"];
    
//    UIImage *nameImage = [self locationNamePicWithCard:cardImage];
//    NSString *cardName = [self tesseractImage:nameImage Language:@"idcard_name"];
//    
//    NSLog(@"name:%@\nnumber:%@", cardName,cardNumber);
//    
//    if (cardNumber.length && [opencvManger isRightCardNumber:[opencvManger delSpaceAndNewline:cardNumber]] && cardName.length){
//        
//        IdCardInfo *card = [[IdCardInfo alloc] init];
//        card.number = cardNumber;
//        card.name = cardName;
//        compleate(card);
//    }else{
//        fault(@"失败");
//        [self saveImage:cardImage WithName:@"21"];
//        NSLog(@"fault---------------------------------");
//        Moment *data = [[Moment alloc] init];
//        data.momentId = [Moment makeUUID];
//        data.picData = [self picData:cardImage];
//        data.time = [self timeNow];
//        data.timestamp = [self timeStamp];
//        data.error = cardNumber;
//        data.phoneType = [self phoneType];
//        data.screenType = [self screenStr];
//        data.errorName = cardName;
//        [MomentCachesTool addMoment:data];
//    }
    
    
    
    
//    UIImage *nameImage = [self locationNamePicWithCard:cardImage];
//    NSString *cardName = [self tesseractImage:nameImage Language:@"idcard_name"];
//    
//    NSLog(@"name:%@\nnumber:%@", cardName,cardNumber);
    
    if (cardNumber.length && [opencvManger isRightCardNumber:[opencvManger delSpaceAndNewline:cardNumber]] ){
        
        IdCardInfo *card = [[IdCardInfo alloc] init];
        card.number = cardNumber;
//        card.name = cardName;
        compleate(card);
    }else{
        fault(@"失败");
        [self saveImage:cardImage WithName:@"21"];
        NSLog(@"fault---------------------------------");
        Moment *data = [[Moment alloc] init];
        data.momentId = [Moment makeUUID];
        data.picData = [self picData:cardImage];
        data.time = [self timeNow];
        data.timestamp = [self timeStamp];
        data.error = cardNumber;
        data.phoneType = [self phoneType];
        data.screenType = [self screenStr];
//        data.errorName = cardName;
        [MomentCachesTool addMoment:data];
    }
    
    
    
}

- (NSString *)tesseractImage:(UIImage *)image Language:(NSString *)language{
    
    
    G8Tesseract *tesseract = [[G8Tesseract alloc]initWithLanguage:language];
            tesseract.engineMode = G8OCREngineModeTesseractOnly;
            tesseract.maximumRecognitionTime = 10;
            tesseract.pageSegmentationMode = G8PageSegmentationModeAuto;
            tesseract.image = [image g8_blackAndWhite];
            [tesseract recognize];
    
//    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:language];
//    tesseract.image = [image g8_blackAndWhite];
//    tesseract.image = image;
//    [tesseract recognize];
    return tesseract.recognizedText;
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//        G8Tesseract *tesseract = [[G8Tesseract alloc]initWithLanguage:@"eng"];
//        tesseract.engineMode = G8OCREngineModeTesseractOnly;
//        tesseract.maximumRecognitionTime = 10;
//        tesseract.pageSegmentationMode = G8PageSegmentationModeAuto;
//        tesseract.image = [image g8_blackAndWhite];
//        [tesseract recognize];
//        block(tesseract.recognizedText);
//    });
}










/**
 * 号码区域计算
 */

- (UIImage *)locationNumPicWithCard:(UIImage *)image {
    
    //将UIImage转换成Mat
    cv::Mat resultImage;
    cv::Mat Imagegray;
    cv::Mat Imagebin;
    cv::Mat Imageerode;
    
    std::vector<std::vector<cv::Point>>contours;
    cv::Rect numberRect = cv::Rect(0, 0, 0, 0);
    //转为灰度图
    cvtColor([opencvManger cvMatFromUIImage:image],Imagegray,6);
    //利用阈值二值化
    cv::threshold(Imagegray,Imagebin,100,255,1);
    //腐蚀，填充
    cv::Mat erodeElement = getStructuringElement(cv::MORPH_RECT,cv::Size(35, 35));
    cv::dilate(Imagebin, Imageerode, erodeElement);
    //容器
    cv::findContours(Imageerode,contours,CV_RETR_TREE,CV_CHAIN_APPROX_SIMPLE,cvPoint(0, 0));
    cv::Mat result(Imageerode.size(),CV_8U,cv::Scalar(255));
    cv::drawContours( result, contours, -1, cv::Scalar(0),2);
    //取出身份证号码区域
    std::vector<std::vector<cv::Point>>::const_iterator
    itContours = contours.begin();
    //std::cout << "图像区域：" << std::endl;
    for (; itContours != contours.end(); ++itContours)
    {
        cv::Rect rect = cv::boundingRect(*itContours);
        if (rect.width > numberRect.width &&
            rect.x > 35 &&
            rect.width > rect.height * 5 &&
            rect.height > 20 &&
            rect.height < 300 &&
            rect.width < [opencvManger cvMatFromUIImage:image].cols*0.65)
        {
            numberRect = rect;
        }
    }
    
    //定位成功成功，去原图截取身份证号码区域，并转换成灰度图、进行二值化处理
    cv::Mat matImage;
    UIImageToMat(image, matImage);
    resultImage = matImage(numberRect);
    cvtColor(resultImage, resultImage, cv::COLOR_BGR2GRAY);
    cv::threshold(resultImage, resultImage, 80, 255, CV_THRESH_BINARY);
    
    //将Mat转换成UIImage
    UIImage *numberImage = MatToUIImage(resultImage);
    return numberImage;
}

/**
 * 姓名区域计算
 */

- (UIImage *)locationNamePicWithCard:(UIImage *)image {
    
    static cv::Mat Imagegray;
    static cv::Mat Imagebin;
    static cv::Mat Imageerode;
    static int Value = 100;
    static int Type = 8;
    int erSize;
    
    
//    cv::Mat Imagejpg = [opencvManger cvMatFromUIImage:image];// image - >Mat
    
    cv::Mat Imagejpgsource = [opencvManger cvMatFromUIImage:image];// image - >Mat
    cv::Mat Imagejpg = cv::Mat::zeros(540*1.5, 856*1.5, CV_8UC3);
    cv::resize(Imagejpgsource, Imagejpg, Imagejpg.size());
    
    
    
    erSize = cv::min(Imagejpg.cols / 30, 50); // 25
    std::vector<std::vector<cv::Point>> contours;
    cv::Rect nameRect = cv::Rect(0, 0, 0, 0);
    
   
    cv::cvtColor(Imagejpg,
                 Imagegray,
                 6,
                 0);
    
    
//    IplImage *src;
//    src = &IplImage(Imagejpg);
    IplImage temp = (IplImage)Imagejpg;
    IplImage *src=&temp;
    
    Value = otsub(src);
    
    cv::threshold(
                  Imagegray,
                  Imagebin,
                  Value,
                  255,
                  8);
    
    cv::Mat erodeElement =
    getStructuringElement(
                          cv::MORPH_RECT,
                          cv::Size(erSize, erSize)); //15
    
    if ((Type == 0) || (Type == 2) || (Type == 3) || (Type == 4) || (Type == 8))
        cv::erode(Imagebin, Imageerode, erodeElement);
    if (Type == 1)
        cv::dilate(Imagebin, Imageerode, erodeElement);
    
//    cv::waitKey(0);
    cv::findContours(
                     Imageerode,
                     contours,
                     cv::RETR_TREE, //RETR_EXTERNAL RETR_TREE RETR_LIST
                     cv::CHAIN_APPROX_SIMPLE, //CHAIN_APPROX_SIMPLE CHAIN_APPROX_NONE
                     cvPoint(0, 0));
    cv::Mat result(
                   Imageerode.size(),
                   CV_8U,
                   cv::Scalar(255));
    cv::drawContours(
                     result,
                     contours,
                     -1,
                     cv::Scalar(50),
                     2);
    
    std::vector<std::vector<cv::Point>>::const_iterator
    itContours = contours.begin();
    
    for (; itContours != contours.end(); ++itContours)
    {
        cv::Rect rect = cv::boundingRect(*itContours);
        
        if (rect.x < 350 &&
            rect.y < 200 &&
            rect.height > 80 &&
            rect.height < 106 &&
            rect.width > 160 &&
            rect.width < 225 &&
            (double(rect.width) / double(rect.height)) < MAXRATIO &&
            (double(rect.width) / double(rect.height)) > MINRATIO
            )
        {
            nameRect = rect;
        }
    }
    
    
    
    NSLog(@"\n---------姓名区域计算nameRect-------\nx=%.d\n,y=%.d\n,width=%.d\n,height=%.d\n",nameRect.x,nameRect.y,nameRect.width,nameRect.height);
    cv::Mat matImage;
    cv::Mat resultImage;
    UIImageToMat(image, matImage);
    resultImage = Imagejpg(nameRect);
//    resultImage = matImage(nameRect);
    cvtColor(resultImage, resultImage, cv::COLOR_BGR2GRAY);
    cv::threshold(resultImage, resultImage, 80, 255, CV_THRESH_BINARY);
    
//    cv::Mat imagelogo = Imagejpg(nameRect);
//    cv::Mat imageROI = Imagejpg(cv::Rect(
//                                         nameRect.x,
//                                         nameRect.y,
//                                         nameRect.width,
//                                         nameRect.height));
//    cv::addWeighted(
//                    imageROI, 
//                    0.5, 
//                    imagelogo,
//                    0.1, 
//                    0., 
//                    imageROI);
    
    
    UIImage *nameCutImage = MatToUIImage(resultImage);
    NSLog(@"\n---------处理后姓名区域图片-------\nwidth=%f\n,height=%.f\n",nameCutImage.size.width,nameCutImage.size.height);
    return nameCutImage;
    
    
//    static cv::Mat Imagegray;
//    static cv::Mat Imagebin;
//    static cv::Mat Imageerode;
//    static int Value = 100;
//    static int Type = 8;
//    
//    cv::Mat Imagejpgsource = [opencvManger cvMatFromUIImage:image];// image - >Mat
//    cv::Mat Imagejpg = cv::Mat::zeros(540*1.5, 856*1.5, CV_8UC3);
//    cv::resize(Imagejpgsource, Imagejpg, Imagejpg.size());
//    
//    int erSize;
//
//    //定义
//    erSize = cv::min(Imagejpg.cols / 30, 50); // 25
//    std::vector<std::vector<cv::Point>> contours;
//    cv::Rect nameRect = cv::Rect(2000, 2000, 2000, 2000);
//    
//    //转为灰度图
//    cv::cvtColor(Imagejpg, Imagegray, 6); //cv::COLOR_RGB2GRAY
//    
//    // 取图像阀值
//    IplImage temp = (IplImage)Imagejpg;
//    IplImage *src=&temp;
////    IplImage *src;
////    src = &IplImage(Imagejpg);
//    
//    
//    
//    Value = otsub(src);
//    
//    cv::threshold(Imagegray,Imagebin,Value,255,8);
//    cv::Mat erodeElement =  getStructuringElement(cv::MORPH_RECT, cv::Size(erSize, erSize)); //15
//    
//    
//    if ((Type == 0) || (Type == 2) || (Type == 3) || (Type == 4) || (Type == 8))
//        cv::erode(Imagebin, Imageerode, erodeElement);
//    if (Type == 1)
//        cv::dilate(Imagebin, Imageerode, erodeElement);
//    
////    cv::waitKey(0);
//    cv::findContours(Imageerode,contours,cv::RETR_TREE,cv::CHAIN_APPROX_SIMPLE,cvPoint(0, 0));
//    cv::Mat result(Imageerode.size(),CV_8U,cv::Scalar(255));
//    cv::drawContours(result,contours,-1,cv::Scalar(50),2);
//    
//    //取出身份证号码区域
//    std::vector<std::vector<cv::Point>>::const_iterator
//    itContours = contours.begin();
//    
//    for (; itContours != contours.end(); ++itContours)
//    {
//        cv::Rect rect = cv::boundingRect(*itContours);
//        if (rect.x < (nameRect.x + 50) &&
//            rect.width < 1000 &&
//            rect.y < nameRect.y
//            )
//        {
//            nameRect = rect;
//        }
//    }
//    
//    cv::Rect resultRect = cv::Rect(nameRect.x + 125, nameRect.y - 20, nameRect.width + 150, nameRect.height + 20);
//    NSLog(@"\n---------姓名区域计算resultRect-------\nx=%.d\n,y=%.d\n,width=%.d\n,height=%.d\n",resultRect.x,resultRect.y,resultRect.width,resultRect.height);
//
//    cv::Mat matImage;
//    cv::Mat resultImage;
//    UIImageToMat(image, matImage);
//    resultImage = matImage(resultRect);
//    cvtColor(resultImage, resultImage, cv::COLOR_BGR2GRAY);
//    cv::threshold(resultImage, resultImage, 80, 255, CV_THRESH_BINARY);
//    
//    
//    UIImage *nameCutImage = MatToUIImage(resultImage);
//    NSLog(@"\n---------处理后姓名区域图片-------\nwidth=%f\n,height=%.f\n",nameCutImage.size.width,nameCutImage.size.height);
//    return nameCutImage;
}










// c++ image 与ios image 转换
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}
// ios image 与c++ image 转换
+(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    //    CGBitmapInfo bitmapInfo;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        88 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}



// 去空格
+ (NSString *)delSpaceAndNewline:(NSString *)string{
    NSMutableString *mutStr = [NSMutableString stringWithString:string];
    NSRange range = {0,mutStr.length};
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    return mutStr;
}


// 身份证校验
+  (BOOL)isRightCardNumber:(NSString *)checkString {
    if (checkString.length != 18) return NO; //18位
    NSString *regex = @"^[1-9]\\d{5}[1-9]\\d{3}((0\\d)|(1[0-2]))(([0|1|2]\\d)|3[0-1])\\d{3}([0-9]|X)$";
    NSPredicate *identityStringPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    if(![identityStringPredicate evaluateWithObject:checkString]) return NO;
    NSArray *idCardWiArray = @[@"7", @"9", @"10", @"5", @"8", @"4", @"2", @"1", @"6", @"3", @"7", @"9", @"10", @"5", @"8", @"4", @"2"];
    NSArray *idCardYArray = @[@"1", @"0", @"10", @"9", @"8", @"7", @"6", @"5", @"4", @"3", @"2"];
    NSInteger idCardWiSum = 0;
    for(int i = 0;i < 17;i++) {
        NSInteger subStrIndex = [[checkString substringWithRange:NSMakeRange(i, 1)] integerValue];
        NSInteger idCardWiIndex = [[idCardWiArray objectAtIndex:i] integerValue];
        idCardWiSum+= subStrIndex * idCardWiIndex;
    }
    NSInteger idCardMod=idCardWiSum%11;
    NSString *idCardLast= [checkString substringWithRange:NSMakeRange(17, 1)];
    if(idCardMod==2) {
        if(![idCardLast isEqualToString:@"X"]||[idCardLast isEqualToString:@"x"]) {
            return NO;
        }
    }
    else{
        if(![idCardLast isEqualToString: [idCardYArray objectAtIndex:idCardMod]]) {
            return NO;
        }
    }
    return YES;
}


// demo 用的

- (NSString *)timeStamp
{
    NSDate *datenow = [NSDate date];
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]];
    return timeSp;
}

- (NSString *)timeNow
{
    NSDate *date = [NSDate date];
    NSDateFormatter *forMatter = [[NSDateFormatter alloc] init];
    [forMatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *nowDate = [forMatter stringFromDate:date];
    return nowDate;
}

- (NSData *)picData:(UIImage *)img
{
    NSData *data;
    if (UIImagePNGRepresentation(img) == nil) {
        data = UIImageJPEGRepresentation(img, 1);
        
    } else {
        data = UIImagePNGRepresentation(img);
    }
    return data;
}

- (NSString *)phoneType{
    return [NSString stringWithFormat:@"%@,%@", [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]];
}

- (NSString *)screenStr
{
    CGRect rect_screen = [[UIScreen mainScreen]bounds];
    CGSize size_screen = rect_screen.size;
    CGFloat scale_screen = [UIScreen mainScreen].scale;
    return [NSString stringWithFormat:@"%.f*%.f",size_screen.width * scale_screen, size_screen.height * scale_screen ];
}


// 保存图片到系统相册
-(void)saveImage:(UIImage *)tempImage WithName:(NSString *)imageName {
    UIImageWriteToSavedPhotosAlbum(tempImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}
// 指定回调方法
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if(!error){
        NSLog(@"save success");
    }else{
        NSLog(@"save failed");
    }
}





bool GetHistogram(
                  unsigned char *pImageData,
                  int nWidth,
                  int nHeight,
                  int nWidthStep,
                  int *pHistogram)
{
    int i = 0;
    int j = 0;
    unsigned char *pLine = NULL;
    // 清空直方图
    memset(pHistogram, 0, sizeof(int)* 256);
    for (pLine = pImageData, j = 0; j < nHeight; j++, pLine += nWidthStep)
    {
        for (i = 0; i < nWidth; i++)
        {
            pHistogram[pLine[i]]++;
        }
    }
    return true;
}

int Otsu(
         unsigned char *pImageData,
         int nWidth,
         int nHeight,
         int nWidthStep)
{
    int i = 0;
    int j = 0;
    int nTotal = 0;
    int nSum = 0;
    int A = 0;
    int B = 0;
    double u = 0;
    double v = 0;
    double dVariance = 0;
    double dMaximum = 0;
    int nThreshold = 0;
    int nHistogram[256];
    // 获取直方图
    GetHistogram(
                 pImageData,
                 nWidth,
                 nHeight,
                 nWidthStep,
                 nHistogram);
    for (i = 0; i < 256; i++)
    {
        nTotal += nHistogram[i];
        nSum += (nHistogram[i] * i);
    }
    for (j = 0; j < 256; j++)
    {
        A = 0;
        B = 0;
        for (i = 0; i < j; i++)
        {
            A += nHistogram[i];
            B += (nHistogram[i] * i);
        }
        if (A > 0)
        {
            u = B / A;
        }
        else
        {
            u = 0;
        }
        if (nTotal - A > 0)
        {
            v = (nSum - B) / (nTotal - A);
        }
        else
        {
            v = 0;
        }
        dVariance = A * (nTotal - A) * (u - v) * (u - v);
        if (dVariance > dMaximum)
        {
            dMaximum = dVariance;
            nThreshold = j;
        }
    }
    return nThreshold;
}

int otsub(IplImage *image)
{
    assert(NULL != image);
    
    int width = image->width;
    int height = image->height;
    int x = 0, y = 0;
    int pixelCount[256];
    float pixelPro[256];
    int i, j, pixelSum = width * height, threshold = 0;
    
    uchar* data = (uchar*)image->imageData;
    
    
    //初始化
    for (i = 0; i < 256; i++)
    {
        pixelCount[i] = 0;
        pixelPro[i] = 0;
    }
    
    //统计灰度级中每个像素在整幅图像中的个数
    for (i = y; i < height; i++)
    {
        for (j = x; j < width; j++) //?
        {
            pixelCount[data[i * image->widthStep + j]]++;
        }
    }
    
    
    //计算每个像素在整幅图像中的比例
    for (i = 0; i < 256; i++)
    {
        pixelPro[i] = (float)(pixelCount[i]) / (float)(pixelSum);
    }
    
    //经典ostu算法,得到前景和背景的分割
    //遍历灰度级[0,255],计算出方差最大的灰度值,为最佳阈值
    float w0, w1, u0tmp, u1tmp, u0, u1, u, deltaTmp, deltaMax = 0;
    for (i = 0; i < 256; i++)
    {
        w0 = w1 = u0tmp = u1tmp = u0 = u1 = u = deltaTmp = 0;
        
        for (j = 0; j < 256; j++)
        {
            if (j <= i) //背景部分
            {
                //以i为阈值分类，第一类总的概率
                w0 += pixelPro[j];
                u0tmp += j * pixelPro[j];
            }
            else       //前景部分
            {
                //以i为阈值分类，第二类总的概率
                w1 += pixelPro[j];
                u1tmp += j * pixelPro[j];
            }
        }
        
        u0 = u0tmp / w0;        //第一类的平均灰度
        u1 = u1tmp / w1;        //第二类的平均灰度
        u = u0tmp + u1tmp;      //整幅图像的平均灰度
        //计算类间方差
        deltaTmp = w0 * (u0 - u)*(u0 - u) + w1 * (u1 - u)*(u1 - u);
        //找出最大类间方差以及对应的阈值
        if (deltaTmp > deltaMax)
        {
            deltaMax = deltaTmp;
            threshold = i;
        }
    }
    //返回最佳阈值;
    return threshold;
}







@end
