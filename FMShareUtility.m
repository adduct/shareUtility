//
//  FMShareUtility.m
//
//
//  Created by hawkhe on 17/1/8.
//  Copyright © 2017 All rights reserved.
//

#import "FMShareUtility.h"
//your app id register on QQConnect platform
//you should replace the following id:"100100100" with your own one
#define k_appId @"100100100"


@implementation FMShareUtility

//width,height and size limit of image thumbnail
static CGFloat widthLimit = 20.0;
static CGFloat heightLimit = 120.0;
static float sizeLimit = 1024.0*1024.0;

-(id)init
{
    if (self = [super init]) {
        TencentOAuth *tencent = [[TencentOAuth alloc] initWithAppId:k_appId
                                                        andDelegate:self];
        self.tencentOAuth = tencent;
    }
    return self;
}

+ (FMShareUtility *)shareInstance
{
    static dispatch_once_t pred;
    static FMShareUtility* _instance = nil;
    
    dispatch_once(&pred, ^{
        _instance = [[FMShareUtility alloc] init];
    });
    
    return _instance;
}

- (void)shareURLToQQFriend:(NSString *)url
                previewUrl:(NSString *)prviewUrl
               description:(NSString *)descriptionText
{
    [self checkQQInstalled];
    
    NSURL *shareURL = [NSURL URLWithString:url];
    NSData *previewData = [NSData dataWithContentsOfURL:prviewUrl];
    
    QQApiNewsObject *newsObj = [QQApiNewsObject objectWithURL:shareURL
                                                        title:ftnFile.name
                                                  description:descriptionText
                                             previewImageData:previewData];
    SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
    
    QQApiSendResultCode sent = [QQApiInterface sendReq:req];
    [self handleSendResult:sent];
}

- (void)shareImageToQQFriend:(UIImage *)image
{
    [self checkQQInstalled];
    
    QQApiImageObject *imageObject =
        [self scaleImageWithSizeLimit:image
                                    imageDataPath:nil
                                        sizeLimit:sizeLimit];
    SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:imageObject];
    
    QQApiSendResultCode sent = [QQApiInterface sendReq:req];
    [self handleSendResult:sent];
}

- (void)shareDataToQQFriend:(NSData *)data
                   fileName:(NSString *)fileName
                   dataType:(NSString *)dataType
{
    [self checkQQInstalled];
    
    QQApiFileObject *fileObject = [QQApiFileObject
                                   objectWithData:data
                                   previewImageData:nil
                                   title:nil
                                   description:nil];
    NSString *dataFileName = [NSString stringWithFormat:@"share.%@",dataType];
    if (fileName) {
        dataFileName = [NSString stringWithFormat:@"%@.%@",fileName,dataType];
    }
    fileObject.fileName = dataFileName;
    
    NSData *previewImageData = [self getPreviewImageDataByFileName:dataFileName
                                                     iconSizeLimit:sizeLimit];
    [fileObject setPreviewImageData:previewImageData];
    [fileObject setCflag:kQQAPICtrlFlagQQShareDataline];
    
    SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:fileObject];
    QQApiSendResultCode sent = [QQApiInterface sendReq:req];
    [self handleSendResult:sent];
}

- (void)checkQQInstalled
{
    if (![TencentOAuth iphoneQQInstalled]) {
        NSURL *qqUrl = [NSURL URLWithString:
                        @"itms-apps://itunes.apple.com/cn/app/id444934666?mt=8"];
        [[UIApplication sharedApplication] openURL:qqUrl];
        return;
    }
}

/**
 *Display share result:succeess or the reason of failure
 */
- (void)handleSendResult:(QQApiSendResultCode)sendResult
{
    NSArray *errorMsg = @[@"Share success",
                          @"Not install QQ",
                          @"API not supported",
                          @"Parameter error",
                          @"Parameter error",
                          @"Parameter error",
                          @"App not registered.",
                          @"EQQAPIAPPSHAREASYNC",
                          @"EQQAPIQQNOTSUPPORTAPI_WITH_ERRORSHOW",
                          @"Send failed"];
    
    static NSString *sendToQQFailed = @"Share Result";
    NSString *errMessage = nil;
    if (EQQAPISENDFAILD == sendResult) {
        errMessage = (NSString *)[errorMsg lastObject];
    } else {
        errMessage = (NSString *)[errorMsg objectAtIndex:sendResult];
    }
    
    UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:sendToQQFailed
                                                     message:errMessage
                                                    delegate:nil
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:nil];
    [msgbox show];
}

- (QQApiImageObject *)scaleImageWithSizeLimit:(UIImage *)originalImage
                                            imageDataPath:(NSString *)imagePath
                                                sizeLimit:(float)sizeLimit
{
    NSData *originalImageData = nil;
    if (imagePath) {
        originalImageData = [NSData dataWithContentsOfFile:imagePath];
    } else {
        originalImageData = UIImageJPEGRepresentation(originalImage, 1.0);
    }
    
    UIImage *scaledImage = [self genPreviewImageByOriginalImage:originalImage
                                                      sizeLimit:sizeLimit
                                                     widthLimit:widthLimit
                                                    heightLimit:heightLimit];
    NSData *scaledImageData = UIImageJPEGRepresentation(scaledImage, 1.0);
    
    NSString *imageName = nil;
    if (imagePath) {
        imageName = imagePath.lastPathComponent;
    }
    QQApiImageObject *imageObject =
            [QQApiImageObject objectWithData:originalImageData
                            previewImageData:scaledImageData
                                       title:imageName
                                 description:nil];
    return imageObject;
}

+ (UIImage *)genPreviewImageByOriginalImage:(UIImage *)sourceImage
                                  sizeLimit:(float)sizeLimit
                                 widthLimit:(float)widthLimit
                                heightLimit:(float) heightLimit
{
    CGFloat width = roundf(sourceImage.size.width/
                           sourceImage.size.height*heightLimit);
    //Largest bit depth:32
    //estimated image size ＝ width*height*32／8
    float maximumWidth = sizeLimit/4/heightLimit;
    
    if (widthLimit > width) {
        width = widthLimit;
    }
    if (maximumWidth < width) {
        width = maximumWidth;
    }
    
    UIGraphicsBeginImageContext(CGSizeMake(width, heightLimit));
    [sourceImage drawInRect:CGRectMake(0, 0, width, heightLimit)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *previewImageData = UIImagePNGRepresentation(scaledImage);
    float lengthOfImage = [previewImageData length];
    if (sizeLimit < lengthOfImage) {
        static float compressRatioStep = 0.2;
        static float maximumQuality = 1.0;
        static float lowestQuality = 0.0;
        for (float compressRatio = maximumQuality;
             lowestQuality <= compressRatio;
             compressRatio -= compressRatioStep) {
            previewImageData = UIImageJPEGRepresentation(scaledImage,compressRatio);
            lengthOfImage = [previewImageData length];
            
            if (sizeLimit < lengthOfImage) {
                scaledImage = [UIImage imageWithData:previewImageData];
                break;
            }
        }
    }
    
    if (sizeLimit < lengthOfImage) {
        float imageHeightLimit = 40;
        if (0.001 < heightLimit - 40) {
            imageHeightLimit = heightLimit - 40;
        }
        
        return [self genPreviewImageByOriginalImage:scaledImage
                                          sizeLimit:sizeLimit
                                         widthLimit:widthLimit
                                        heightLimit:imageHeightLimit];
    }
    
    return scaledImage;
}

- (NSData *)getPreviewImageDataByFileName:(NSString *)fileName
                            iconSizeLimit:(float)iconSizeLimit
{
    NSString *fileExtension = [self attachFileSufix:fileName];
    UIImage *iconImage = [self thumbnaiImageWithFileName:fileExtension
                                                  suffix:@"_icon"];
    NSData *previewImageData = nil;
    if (iconImage) {
        previewImageData = UIImagePNGRepresentation(iconImage);
        if (iconSizeLimit < [previewImageData length]) {
            float scale = iconSizeLimit/[previewImageData length];
            previewImageData = UIImageJPEGRepresentation(iconImage,scale);
        }
    }
    
    return previewImageData;
}

- (UIImage *)thumbnaiImageWithFileName:(NSString *)name
                                suffix:(NSString *)suffix
{
    return [UIImage imageNamed:[self thumbnaiNameWithFileName:name
                                                       suffix:suffix]];
}

- (NSString *)thumbnaiNameWithFileName:(NSString *)name
                                suffix:(NSString *)suffix
{
    NSString *nameString = nil;
    NSString *suffixString = suffix ? suffix : @"_51h";
    
    NSString *fileSuffix = [self attachFileSufix:name];
    
    NSArray *pptName = [NSArray arrayWithObjects:@"ppt",@"pptx",@"pps",@"pptm",
                        @"dpt",@"dps",nil];
    NSArray *xlsName = [NSArray arrayWithObjects:@"xls",@"xlsx",@"xlsm",@"csv",
                        @"ett",@"et",nil];
    NSArray *wordName = [NSArray arrayWithObjects:@"doc",@"docx",@"docm",@"dot"
                        ,@"rtf",@"wps",@"wpt",nil];
    
    NSString *mName = name;
    if ( [self isImageSufix:fileSuffix] ) {
        nameString = @"filetype_image";
    } else if ( [self isVideo:mName] ) {
        nameString = @"filetype_video";
    } else if ( [self isAudio:mName] ) {
        nameString = @"filetype_audio";
    } else if ( [self isKeynoteFile:mName] ) {
        nameString = @"filetype_keynote";
    } else if ( [self isNumbersFile:mName] ) {
        nameString = @"filetype_numbers";
    } else if ( [self isPagesFile:mName] ) {
        nameString = @"filetype_pages";
    } else if ( [self isZipSufix:fileSuffix] ) {
        nameString = @"filetype_compress";
    } else if( [self isTxtFileType:mName]){
        nameString = @"filetype_txt";
    } else if ([pptName containsObject:fileSuffix]) {
        nameString = @"filetype_ppt";
    } else if ( [fileSuffix isEqualToString:@"pdf"] ) {
        nameString = @"filetype_pdf";
    } else if ( [xlsName containsObject:fileSuffix]) {
        nameString = @"filetype_excel";
    } else if ( [wordName containsObject:fileSuffix]) {
        nameString = @"filetype_word";
    } else if ( [fileSuffix isEqualToString:@"html"] ||
             [fileSuffix isEqualToString:@"htm"] ) {
        nameString = @"filetype_html";
    } else if ( [fileSuffix isEqualToString:@"eml"] ) {
        nameString = @"filetype_eml";
    } else if ( [fileSuffix isEqualToString:@"psd"] ) {
        nameString = @"filetype_psd";
    } else if([self isIcsFileSufix:fileSuffix]){
        nameString = @"filetype_calendar";
    } else {
        nameString = @"filetype_others";
    }
    
    return [NSString stringWithFormat:@"%@%@", nameString, suffixString];
}

- (NSString *) attachFileSufix:(NSString*)attachName
{
    if (!attachName) {
        return nil;
    }
    
    attachName = [attachName stringByReplacingOccurrencesOfString:@" "
                                                       withString:@""];
    
    NSArray * array = [attachName componentsSeparatedByString:@"."];
    if (array.count > 0) {
        return [[array lastObject] lowercaseString];
    } else {
        return nil;
    }
    
}

- (BOOL)isImageSufix:(NSString *)fileSufix
{
    NSArray * _imgFileSufix = [NSArray arrayWithObjects:@"png", @"gif", @"jpg",
                               @"jpeg", @"bmp", @"tif",@"tiff", @"ico",nil];
    
    return [_imgFileSufix containsObject:[fileSufix lowercaseString]];
}

- (BOOL) isVideo:(NSString *)attachName
{
    NSArray * _videoFileSufix = [NSArray arrayWithObjects: @"mkv",@"mp4",@"m4v",
                                 @"mov",@"mpv",@"3gp",@"avi",@"wmv",@"rmvb",
                                 @"swf",@"mpg",@"flv",nil];
    return [_videoFileSufix containsObject:
            [self attachFileSufix:attachName]];
}

- (BOOL) isAudio:(NSString *)attachName
{
    NSArray * _audioFileSufix =
    [NSArray arrayWithObjects: @"mp3",@"wma",@"wav",@"aiff",@"m4a",nil];
    return [_audioFileSufix containsObject:
            [self attachFileSufix:attachName]];
}

- (BOOL)isKeynoteFile:(NSString *)fileName
{
    return [self isIWorkFile:fileName OfType:@"key"];
}

- (BOOL)isNumbersFile:(NSString *)fileName
{
    return [self isIWorkFile:fileName OfType:@"numbers"];
}

- (BOOL)isPagesFile:(NSString *)fileName
{
    return [self isIWorkFile:fileName OfType:@"pages"];
}

- (BOOL)isZipSufix:(NSString *)fileSufix
{
    NSArray *zipFileSufix = [NSArray arrayWithObjects:@"zip",@"rar",@"7z",
                             @"tar",@"gz",@"bz2",@"xz",@"lzh",nil];
    return [zipFileSufix containsObject:fileSufix];
}

- (BOOL) isTxtFileType:(NSString *)attachName
{
    NSArray *_txtFileSufix = [NSArray arrayWithObjects: @"txt", @"xml",@"ini",
                              @"cpp",@"java",@"c",@"h",@"m",@"plist",@"stp",
                              @"ini",@"log",@"js",nil];
    return [_txtFileSufix containsObject:[self attachFileSufix:attachName]];
}

-(BOOL)isIWorkFile:(NSString *)fileName OfType:(NSString *)type
{
    // iWork09 or above
    NSString *iWorkSuffix = [NSString stringWithFormat:@"%@", type];
    // iWork09 lower
    NSString *iWorkZipSuffix = [NSString stringWithFormat:@"%@.zip", type];
    
    NSString *last2PathComponent = [self attachFileLast2Suffix:fileName];
    NSArray *iWork09LowerSuffix =[NSArray arrayWithObjects: @"key.zip",
                                  @"numbers.zip",@"pages.zip",nil];
    BOOL isSupportIWork09LowerFile =
        [iWork09LowerSuffix containsObject:last2PathComponent];
    
    NSArray *iWorkSuffix =[NSArray arrayWithObjects: @"key",@"numbers",
                           @"pages",nil];
    NSString *fileSuffix = [self attachFileSufix:fileName];
    BOOL isSupportIWork09Or13File = [iWorkSuffix containsObject:fileSuffix];
    
    BOOL isSupportIWorkFile = isSupportIWork09LowerFile ||
                              isSupportIWork09Or13File;
    if (isSupportIWorkFile) {
        if (isSupportIWork09LowerFile) {
            // *.iwork.zip
            return [last2PathComponent isEqualToString:iWorkZipSuffix];
        } else {
            // .iwork
            return [fileSuffix isEqualToString:iWorkSuffix];
        }
    } else {
        return NO;
    }
}

- (BOOL)isIcsFileSufix:(NSString *)fileSufix
{
    if (fileSufix && [[fileSufix lowercaseString] isEqual:@"ics"]) {
        return YES;
    }
    return NO;
}

- (NSString *) attachFileLast2Suffix:(NSString*)attachName;
{
    NSString *attachName = [self trimAttachFileName:attachName];
    NSArray * array = [attachName componentsSeparatedByString:@"."];
    if (array.count > 1) {
        NSString *last1Suffix = [[array lastObject] lowercaseString];
        NSString *last2Suffix = [[array objectAtIndex:array.count - 2]
                                 lowercaseString];
        return [[last2Suffix stringByAppendingString:@"."]
                stringByAppendingString: last1Suffix];
    } else {
        return nil;
    }
}

- (NSString *)trimAttachFileName:(NSString *)attachName
{
    return [attachName stringByReplacingOccurrencesOfString:@" " withString:@""];
}
@end
