# shareUtitlity
qqShareUtility class is a useful utility for share image,url and binary data to qq friends.
It is now used in QQMail app project.

# Features
share image, binary data and url to QQ without use sophisticated TencentOpenApi API.
# Installation
1. add TencentOpenApi. Read instruction for more detail:
http://blog.csdn.net/HeYingShu/article/details/54577061
2. add qqShareUtility class and related images into your project.

#Usage:
1. share image
[[FMShareToQQUtility shareInstance] shareImageToQQFriend:demoImage];
where:
"demoImage" is a nonnull UIImage object.

2. share binary data:
[[FMShareToQQUtility shareInstance] shareDataToQQFriend:demoData 
                                    fileName:demoFileName 
                                    dataType:demoType];
where:
"demoData" is a nonull NSData object;
      "demoFileName" is a nullable NSString object;
      "demoType" is the type of binary data. Use suffix directly for file.
      
3. share url:
[[FMShareToQQUtility shareInstance] shareURLToQQFriend:demoUrl
                                    previewUrl:demoPrviewUrl
                                    description:demoDescription];
where:
"demoUrl" is nonnull NSString object;
"demoPrviewUrl" is nonnull  NSString object;
"demoDescription" is nonnull  NSString object.

#Licence
shareUtility is available under the MIT license. See the LICENSE file for detail.
