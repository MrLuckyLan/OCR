//
//  opencvManger.h
//  OCR
//
//  Created by CBS on 2017/5/2.
//  Copyright © 2017年 CBS. All rights reserved.
//

#import "IdCardInfo.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>




typedef void (^Fault)(NSString *error);
typedef void (^Compleate)(IdCardInfo *card);





@interface opencvManger : NSObject


+ (instancetype)Manger;

/**
 *  识别身份证信息
 */
- (void)recognizeCardImage:(UIImage *)cardImage compleate:(Compleate)compleate fault:(Fault)fault;

/**
 *  opencv 定位不同区域
 */
- (UIImage *)locationNumPicWithCard:(UIImage *)image;
- (UIImage *)locationNamePicWithCard:(UIImage *)image;

/**
 *  tesseract 识别图片中文字
 */
- (NSString *)tesseractImage:(UIImage *)image Language:(NSString *)language;

// 身份证校验
+  (BOOL)isRightCardNumber:(NSString *)checkString;
// 去空格
+ (NSString *)delSpaceAndNewline:(NSString *)string;




- (NSData *)picData:(UIImage *)img;
- (NSString *)timeStamp;
- (NSString *)timeNow;
- (NSString *)phoneType;
- (NSString *)screenStr;

@end
