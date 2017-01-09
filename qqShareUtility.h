//
//  qqShareUtility.h
//
//
//  Created by hawkhe on 17/1/8.
//  Copyright © 2017 All rights reserved.
//

#import <Foundation/Foundation.h>

@interface qqShareUtility : NSObject<TencentSessionDelegate>
@property (retain, nonatomic) TencentOAuth *tencentOAuth;

+ (FMShareToQQUtility *)shareInstance;
/**
 * share url to QQ friend
 \param url URL
 \param prviewUrl url of preview
 \param descriptionText abstract of webpage content
 */
- (void)shareURLToQQFriend:(nonnull NSString *)url
                previewUrl:(nonnull NSString *)prviewUrl
               description:(nonnull NSString *)descriptionText;

/**
 * share image to QQ friend
 \param image UIImage object
 */
- (void)shareImageToQQFriend:(nonnull UIImage *)image;

/**
 * share image to QQ friend,the size limit is:5MB
 \param data NSData content
 \param fileName displayed file's name
 \param dataType binary data type，use @“pdf” if it's pdf file for example
 */
- (void)shareDataToQQFriend:(nonnull NSData *)data
                   fileName:(nullable NSString *)fileName
                   dataType:(nonnull NSString *)dataType;

@end
