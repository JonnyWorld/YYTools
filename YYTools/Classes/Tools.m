
//
//  Tools.m
//  FreeBird
//
//  Created by baozhou on 15/8/12.
//  Copyright (c) 2015年 liepin. All rights reserved.
//

#import "Tools.h"
//Utils
#import <objc/runtime.h>
//#import <SDWebImage/SDImageCache.h>
//Authorization
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <AddressBook/AddressBook.h>
#import <CommonCrypto/CommonCrypto.h>
//Device
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#import <sys/utsname.h>
#import <sys/sockio.h>
#import <sys/ioctl.h>
#import <arpa/inet.h>
#include <net/if.h>
#include <net/if_dl.h>
#import <mach/mach.h>
#import <mach/mach_host.h>
#import <netinet/in.h>
#import <SystemConfiguration/CaptiveNetwork.h>
//#import "KeychainItemWrapper.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
//#import <Reachability/Reachability.h>
//JS
#import <JavaScriptCore/JavaScriptCore.h>

@implementation Tools

#pragma mark - Utils
//切换运行在主线程
+(void)runMainThread:(void(^)(void))block {
    if([NSThread isMainThread]){
        if(block){
            block();
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(block){
                block();
            }
        });
    }
}

//获取当前屏幕显示的viewcontroller
+ (UIViewController *)currentController {
    //获取Window
    UIViewController *result = nil;
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal){
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows){
            if (tmpWin.windowLevel == UIWindowLevelNormal){
                window = tmpWin;
                break;
            }
        }
    }
    
    //获取当前Controller
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]){
        result = nextResponder;
    }
    else{
        result = window.rootViewController;
        while (result.presentedViewController) {
            result = result.presentedViewController;
        }
    }
    
    if([result isKindOfClass:[UINavigationController class]]){
        result = ((UINavigationController *)result).topViewController;
    } else if ([result isKindOfClass:[UITabBarController class]]){
        result = [(UITabBarController *)result selectedViewController];
        if([result isKindOfClass:[UINavigationController class]]){
            result = ((UINavigationController *)result).topViewController;
        }
    }
    return result;
}


//能否打电话
+(BOOL)canTel {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel:"]];
}
//拨打电话
+(void)tel:(NSString *)telNo {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", telNo]]];
}
//能否打开这个URL
+(BOOL)canOpenURL:(NSString *)url {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:url]];
}

//打开某个URL
+(void)openURL:(NSString *)url {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

//字符串是否有效
+(BOOL)stringIsAvailable:(NSString *)string {
    if(string && [string isKindOfClass:[NSString class]] && [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0){
        return YES;
    }
    return NO;
}

//数组是否有效
+(BOOL)arrayIsAvailable:(NSArray *)array {
    if(array && [array isKindOfClass:[NSArray class]] && [array count] > 0){
        return YES;
    }
    return NO;
}

//字典是否有效
+(BOOL)dictionaryIsAvailable:(NSDictionary *)dictionary {
    if(dictionary && [dictionary isKindOfClass:[NSDictionary class]] && [dictionary count] > 0){
        return YES;
    }
    return NO;
}

//复制字符串
+(void)pasteString:(NSString *)string {
    [[UIPasteboard generalPasteboard] setString:string];
}

//复制图片
+(void)pasteImage:(UIImage *)image {
    [[UIPasteboard generalPasteboard] setImage:image];
}

//获取拼音首字母(传入汉字字符串, 返回大写拼音首字母)
+ (NSString *)firstCharactor:(NSString *)aString{
    NSMutableString *str = [NSMutableString stringWithString:aString];
    //先转换为带声调的拼音
    CFStringTransform((CFMutableStringRef)str,NULL, kCFStringTransformMandarinLatin,NO);
    //再转换为不带声调的拼音
    CFStringTransform((CFMutableStringRef)str,NULL, kCFStringTransformStripDiacritics,NO);
    //转化为大写拼音
    NSString *pinYin = [str capitalizedString];
    //获取并返回首字母
    if (pinYin.length>=1) {
       return [pinYin substringToIndex:1];
    }else {
       return @"";
    }
    
}

//格式话金额，限制小数点后2位数，格式如1,100,200.38
+ (NSString *)formatCoinString:(double)coin {
    NSNumberFormatter *numFormat = [[NSNumberFormatter alloc] init];
    numFormat.positiveFormat = @"###,##0.00";
    return [numFormat stringFromNumber:[NSNumber numberWithDouble:coin]];
}

//格式话金额，指定格式化样式，如###,##0.00
+ (NSString *)formatNumberString:(double)coin format:(NSString *)format {
    NSNumberFormatter *numFormat = [[NSNumberFormatter alloc] init];
    numFormat.positiveFormat = format;
    return [numFormat stringFromNumber:[NSNumber numberWithDouble:coin]];
}


+ (UIImage*)getImageCache:(NSString*)url
{
//    UIImage* image = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:url];
//    if (image) {
//        return image;
//    }
//    image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:url];
//    return image;
        return nil;
}


//DES加密
+ (NSString *)encryptUseDES:(NSString *)plainText key:(NSString *)key {
    NSString *ciphertext = nil;
    NSData *cipherData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    const char *textBytes = [cipherData bytes];
    size_t dataLength = [cipherData length];
    
    uint8_t *bufferPtr = NULL;
    size_t bufferPtrSize = 0;
    size_t movedBytes = 0;
    
    bufferPtrSize = (dataLength + kCCBlockSizeDES) & ~(kCCBlockSizeDES - 1);
    bufferPtr = malloc( bufferPtrSize * sizeof(uint8_t));
    memset((void *)bufferPtr, 0x0, bufferPtrSize);
    
    NSString *testString = key;
    NSData *testData = [testString dataUsingEncoding: NSUTF8StringEncoding];
    Byte *iv = (Byte *)[testData bytes];
    
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          [key UTF8String], kCCKeySizeDES,
                                          iv,
                                          textBytes, dataLength,
                                          (void *)bufferPtr, bufferPtrSize,
                                          &movedBytes);
    if (cryptStatus == kCCSuccess) {
        //如果是十六进制
        ciphertext= [Tools parseByte2HexString:bufferPtr :(int)movedBytes];
    }
    free(bufferPtr);
    return ciphertext ;
}

+ (NSString *)parseByte2HexString:(Byte *) bytes  :(int)len{
    NSString *hexStr = @"";
    if(bytes) {
        for(int i=0;i<len;i++) {
            NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff]; ///16进制数
            if([newHexStr length]==1)
                hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
            else {
                hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
            }
        }
    }
    return hexStr;
}


//DES解密
+(NSString *)decryptUseDES:(NSString *)cipherText key:(NSString *)key {
//    NSData* cipherData = [cipherText dataUsingEncoding:NSUTF8StringEncoding];
    NSData* cipherData = [Tools convertHexStrToData:cipherText];
    NSLog(@"++++++++///%@",cipherData);
    unsigned char buffer[1024];
    memset(buffer, 0, sizeof(char));
    size_t numBytesDecrypted = 0;
    NSString *testString = key;
    NSData *testData = [testString dataUsingEncoding: NSUTF8StringEncoding];
    Byte *iv = (Byte *)[testData bytes];
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          [key UTF8String],
                                          kCCKeySizeDES,
                                          iv,
                                          [cipherData bytes],
                                          [cipherData length],
                                          buffer,
                                          1024,
                                          &numBytesDecrypted);
    NSString* plainText = nil;
    if (cryptStatus == kCCSuccess) {
        NSData* data = [NSData dataWithBytes:buffer length:(NSUInteger)numBytesDecrypted];
        plainText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return plainText;
    
}

+ (NSData *)convertHexStrToData:(NSString *)str {
    if (!str || [str length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    
    NSLog(@"hexdata: %@", hexData);
    return hexData;
}


#pragma mark - Authorization

//是否允许push通知提醒
+ (BOOL)isAllowedNotification {
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        UIUserNotificationSettings *setting = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (UIUserNotificationTypeNone == setting.types) {
            return NO;
        }
        return YES;
    }else{
        UIRemoteNotificationType type = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        if(UIRemoteNotificationTypeNone == type) {
            return NO;
        }
        return YES;
    }
}

//是否有权限访问相册
+ (BOOL)canAuthorizationAssetLibrary{
    //验证图片库权限
    if(@available(iOS 11, *)) {
        //默认iOS 11上是打开权限
        return YES;
    } else {
        ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
        if (author == ALAuthorizationStatusRestricted || author == ALAuthorizationStatusDenied){
            //无权限,提示
            NSString *prodName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
            NSString *message = [NSString stringWithFormat:@"照片权限未授权，请到设置->隐私->照片开启【%@】照片权限。",prodName];
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alertView show];
            return NO;
        }
        return YES;
    }
}

//是否有权限访问相机，带有编辑功能时需要判断照片库权限
+ (BOOL)canAuthorizationCamera{
    //验证相机权限
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        //无权限
        NSString *prodName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
        NSString *message = [NSString stringWithFormat:@"相机权限未授权，请到设置->隐私->相机开启【%@】相机权限。",prodName];
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
        return NO;
    }
    return YES;
}


//是否有权限访问定位服务
+ (BOOL)canAuthorizationLocation{
    CLAuthorizationStatus author = [CLLocationManager authorizationStatus];
    if (![CLLocationManager locationServicesEnabled] || author == kCLAuthorizationStatusDenied || author == kCLAuthorizationStatusRestricted) {
        NSString *prodName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
        NSString *message = [NSString stringWithFormat:@"定位权限未授权，请在设置->隐私->定位开启【%@】定位权限。",prodName];
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
        return NO;
    }
    return YES;
}

//是否有权限访问麦克风
+ (BOOL)canAuthorizationMicrophone{
    //尝试唤起
    AVAudioSession *avSession = [AVAudioSession sharedInstance];
    if ([avSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [avSession requestRecordPermission:^(BOOL granted) {}];
    }
    
    //麦克风权限
    AVAuthorizationStatus authorStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if(authorStatus == AVAuthorizationStatusRestricted || authorStatus == AVAuthorizationStatusDenied){
        NSString *prodName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
        NSString *message = [NSString stringWithFormat:@"麦克风权限未授权，请在设置-隐私-麦克风开启【%@】麦克风权限。",prodName];
        [[[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        return NO;
    }
    return YES;
}

//是否有权限访问通讯录
+ (BOOL)canAuthorizationContact{
    //尝试唤起
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error){
    });
    //通讯录权限
    ABAuthorizationStatus authStatus = ABAddressBookGetAuthorizationStatus();
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        NSString *prodName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
        NSString *message = [NSString stringWithFormat:@"通讯录权限未授权，请在设置-隐私-通讯录开启【%@】通讯录权限。",prodName];
        [[[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        return NO;
    }
    return YES;
}

#pragma mark - AutoLayout
//AutoLayout Methods
//边距辅助方法，相等概念
+ (void)setEdge:(UIView*)superview view:(UIView*)view attr:(NSLayoutAttribute)attr constant:(CGFloat)constant
{
    [superview addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:attr relatedBy:NSLayoutRelationEqual toItem:superview attribute:attr multiplier:1.0 constant:constant]];
}

//相等辅助方法 宽高相等
+ (void)setWidthEqualHeightWithView:(UIView*)view
{
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
}

#pragma mark - Device

//屏幕缩放率
+(CGFloat)screenScale{
    return 1/[UIScreen mainScreen].scale;
}

//屏幕宽带
+(CGFloat)screenWidth{
    return [UIScreen mainScreen].bounds.size.width;
}

//屏幕高度
+(CGFloat)screenHeight{
    return [UIScreen mainScreen].bounds.size.height;
}

//状态栏高度
+(CGFloat)statusBarHeight {
    return [UIApplication sharedApplication].statusBarFrame.size.height;
}
//底部安全区域高度
+(CGFloat)bottomSafeHeight {
    if (@available(iOS 11, *)) {
        return [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    }
    return 0;
}

//顶部安全区域高度
+(CGFloat)topSafeHeight {
    if (@available(iOS 11, *)) {
        return [UIApplication sharedApplication].statusBarFrame.size.height + 44;
    }
    return 64;
}


+(BOOL)isIPhone4{
    return ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO) || [self screenHeight] == 480;
}
+(BOOL)isIPhone5{
    return ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO) || [self screenHeight] == 568;
}

+(BOOL)isIPhone6{
    return ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size) : NO) || [self screenHeight] == 667;
}

+(BOOL)isIPhone6Plus{
    return ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? (CGSizeEqualToSize(CGSizeMake(1125, 2001), [[UIScreen mainScreen] currentMode].size) || CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size)) : NO) || [self screenHeight] == 736;
}

+(BOOL)isIPhoneX {
    return ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? (CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size)) : NO) || [self screenHeight] == 2436;
}

+(BOOL)isIPad {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}



//+ (NSString*)guidString
//{
//    NSString* guid = [self GetGUIDString];
//    return guid;
//}

#pragma mark - deviceInfo
//设备信息
+ (NSString*)deviceInfo
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char* machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString* platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    return [self platformType:platform];
}

+ (NSString*)platformType:(NSString*)platform
{
    if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 2G";
    
    if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
    
    if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
    
    if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
    
    if ([platform isEqualToString:@"iPhone3,2"]) return @"iPhone 4";
    
    if ([platform isEqualToString:@"iPhone3,3"]) return @"iPhone 4";
    
    if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";
    
    if ([platform isEqualToString:@"iPhone5,1"]) return @"iPhone 5";
    
    if ([platform isEqualToString:@"iPhone5,2"]) return @"iPhone 5 (GSM+CDMA)";
    
    if ([platform isEqualToString:@"iPhone5,3"]) return @"iPhone 5c (GSM)";
    
    if ([platform isEqualToString:@"iPhone5,4"]) return @"iPhone 5c (GSM+CDMA)";
    
    if ([platform isEqualToString:@"iPhone6,1"]) return @"iPhone 5s(GSM)";
    
    if ([platform isEqualToString:@"iPhone6,2"]) return @"iPhone 5s (GSM+CDMA)";
    
    if ([platform isEqualToString:@"iPhone7,1"]) return @"iPhone 6 Plus";
    
    if ([platform isEqualToString:@"iPhone7,2"]) return @"iPhone 6";
    
    if ([platform isEqualToString:@"iPhone8,1"]) return @"iPhone 6s";
    
    if ([platform isEqualToString:@"iPhone8,2"]) return @"iPhone 6s Plus";
    
    if ([platform isEqualToString:@"iPhone8,4"]) return @"iPhone SE";
    
    if ([platform isEqualToString:@"iPhone9,1"]) return @"iPhone 7";
    
    if ([platform isEqualToString:@"iPhone9,2"]) return @"iPhone 7 Plus";
    
    if ([platform isEqualToString:@"iPhone10,1"]) return @"iPhone 8";
    
    if ([platform isEqualToString:@"iPhone10,4"]) return @"iPhone 8";
    
    if ([platform isEqualToString:@"iPhone10,2"]) return @"iPhone 8 Plus";
    
    if ([platform isEqualToString:@"iPhone10,5"]) return @"iPhone 8 Plus";
    
    if ([platform isEqualToString:@"iPhone10,3"]) return @"iPhone X";
    
    if ([platform isEqualToString:@"iPhone10,6"]) return @"iPhone X";
    if ([platform isEqualToString:@"iPhone11,2"])   return @"iPhone XS";
    if ([platform isEqualToString:@"iPhone11,4"])   return @"iPhone XS Max";
    if ([platform isEqualToString:@"iPhone11,6"])   return @"iPhone XS Max";
    if ([platform isEqualToString:@"iPhone11,8"])   return @"iPhone XR";


    if ([platform isEqualToString:@"iPod1,1"]) return @"iPod Touch 1G";
    
    if ([platform isEqualToString:@"iPod2,1"]) return @"iPod Touch 2G";
    
    if ([platform isEqualToString:@"iPod3,1"]) return @"iPod Touch 3G";
    
    if ([platform isEqualToString:@"iPod4,1"]) return @"iPod Touch 4G";
    
    if ([platform isEqualToString:@"iPod5,1"]) return @"iPod Touch 5G";
    
    if ([platform isEqualToString:@"iPad1,1"]) return @"iPad 1G";
    
    if ([platform isEqualToString:@"iPad2,1"]) return @"iPad 2 (WiFi)";
    
    if ([platform isEqualToString:@"iPad2,2"]) return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,3"]) return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,4"]) return @"iPad 2";
    
    if ([platform isEqualToString:@"iPad2,5"]) return @"iPad Mini  (WiFi)";
    
    if ([platform isEqualToString:@"iPad2,6"]) return @"iPad Mini";
    
    if ([platform isEqualToString:@"iPad2,7"]) return @"iPad Mini (GSM+CDMA)";
    
    if ([platform isEqualToString:@"iPad3,1"]) return @"iPad 3(WiFi)";
    
    if ([platform isEqualToString:@"iPad3,2"]) return @"iPad 3 (GSM+CDMA)";
    
    if ([platform isEqualToString:@"iPad3,3"]) return @"iPad 3";
    
    if ([platform isEqualToString:@"iPad3,4"]) return @"iPad 4 (WiFi)";
    
    if ([platform isEqualToString:@"iPad3,5"]) return @"iPad 4";
    
    if ([platform isEqualToString:@"iPad3,6"]) return @"iPad 4 (GSM+CDMA)";
    
    if ([platform isEqualToString:@"iPad4,1"]) return @"iPad Air (WiFi)";
    
    if ([platform isEqualToString:@"iPad4,2"]) return @"iPad Air (Cellular)";
    
    if ([platform isEqualToString:@"iPad4,3"]) return @"iPad Air";
    
    if ([platform isEqualToString:@"iPad4,4"]) return @"iPad Mini 2 (WiFi)";
    
    if ([platform isEqualToString:@"iPad4,5"]) return @"iPad Mini 2  (Cellular)";
    
    if ([platform isEqualToString:@"iPad4,6"]) return @"iPad Mini 2G";
    
    if([platform isEqualToString:@"iPad4,7"])  return @"iPad Mini 3";
    
    if([platform isEqualToString:@"iPad4,8"])  return @"iPad Mini 3";
    
    if([platform isEqualToString:@"iPad4,9"])  return @"iPad Mini 3";
    
    if([platform isEqualToString:@"iPad5,1"])  return @"iPad Mini 4 (WiFi)";
    
    if([platform isEqualToString:@"iPad5,2"])  return @"iPad Mini 4 (LTE)";
    
    if([platform isEqualToString:@"iPad5,3"])  return @"iPad Air 2";
    
    if([platform isEqualToString:@"iPad5,4"])  return @"iPad Air 2";
    
    if([platform isEqualToString:@"iPad6,3"])  return @"iPad Pro 9.7";
    
    if([platform isEqualToString:@"iPad6,4"])  return @"iPad Pro 9.7";
    
    if([platform isEqualToString:@"iPad6,7"])  return @"iPad Pro 12.9";
    
    if([platform isEqualToString:@"iPad6,8"])  return @"iPad Pro 12.9";
    
    if ([platform isEqualToString:@"i386"]) return @"iPhone Simulator";
    
    if ([platform isEqualToString:@"x86_64"]) return @"iPhone Simulator";
    
    return platform;
    
}

//+ (NSInteger)networkAccessType {
//    Reachability *reach = [Reachability reachabilityWithHostname:@"www.baidu.com"];
//    //有网
//    if([reach isReachable]) {
//        if([reach isReachableViaWWAN]){
//            return 0;
//        } else if([reach isReachableViaWiFi]){
//            return 1;
//        }
//    }
//    
//    //无网
//    return 2;
//}
//
// 获取ip
+ (NSString *)getDeviceIPAddresses {
    
    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    
    
    NSMutableArray *ips = [NSMutableArray array];
    
    int BUFFERSIZE = 4096;
    
    struct ifconf ifc;
    
    char buffer[BUFFERSIZE], *ptr, lastname[IFNAMSIZ], *cptr;
    
    struct ifreq *ifr, ifrcopy;
    
    ifc.ifc_len = BUFFERSIZE;
    ifc.ifc_buf = buffer;
    
    if (ioctl(sockfd, SIOCGIFCONF, &ifc) >= 0){
        
        for (ptr = buffer; ptr < buffer + ifc.ifc_len; ){
            
            ifr = (struct ifreq *)ptr;
            int len = sizeof(struct sockaddr);
            
            if (ifr->ifr_addr.sa_len > len) {
                len = ifr->ifr_addr.sa_len;
            }
            
            ptr += sizeof(ifr->ifr_name) + len;
            if (ifr->ifr_addr.sa_family != AF_INET) continue;
            if ((cptr = (char *)strchr(ifr->ifr_name, ':')) != NULL) *cptr = 0;
            if (strncmp(lastname, ifr->ifr_name, IFNAMSIZ) == 0) continue;
            
            memcpy(lastname, ifr->ifr_name, IFNAMSIZ);
            ifrcopy = *ifr;
            ioctl(sockfd, SIOCGIFFLAGS, &ifrcopy);
            
            if ((ifrcopy.ifr_flags & IFF_UP) == 0) continue;
            
            NSString *ip = [NSString  stringWithFormat:@"%s", inet_ntoa(((struct sockaddr_in *)&ifr->ifr_addr)->sin_addr)];
            [ips addObject:ip];
        }
    }
    
    close(sockfd);
    NSString *deviceIP = @"";
    
    for (int i=0; i < ips.count; i++) {
        if (ips.count > 0) {
            deviceIP = [NSString stringWithFormat:@"%@",ips.lastObject];
        }
    }
    return deviceIP;
}

/**
 *  获取mac地址
 *
 *  @return mac地址  为了保护用户隐私，每次都不一样，后来固定返回同一个值，苹果官方哄小孩玩的
 */
+ (NSString *)getMacAddress {
    int                    mib[6];
    size_t                len;
    char                *buf;
    unsigned char        *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl    *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error/n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1/n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!/n");
        free(buf);
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    
    NSString *outstring = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    return [outstring uppercaseString];
}


+ (NSString *)phoneCarrierName {
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    return info.subscriberCellularProvider.carrierName;
}

+ (NSString *)phoneCarrierNetworkType {
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    if(!info.currentRadioAccessTechnology){
        return nil;
    }
    if(info.currentRadioAccessTechnology.length>0 && [info.currentRadioAccessTechnology rangeOfString:@"CTRadioAccessTechnology"].length>0){
        return [info.currentRadioAccessTechnology stringByReplacingOccurrencesOfString:@"CTRadioAccessTechnology" withString:@""];
    }
    return nil;
}

+ (NSString *)phoneNetworkType {
    NSString *type = [Tools phoneCarrierNetworkType];
    if(!type){
        return @"无";
    }
    if([@"GPRS" isEqualToString:type] || [@"Edge" isEqualToString:type] || [@"CDMA1x" isEqualToString:type]) {
        return @"2G";
    } else if([@"LTE" isEqualToString:type]){
        return @"4G";
    } else if([@"HRPD" isEqualToString:type]) {
        return @"HRPD";
    } else {
        return @"3G";
    }
}

+ (BOOL)isCDMA {
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    NSString *type = info.currentRadioAccessTechnology;
    if(type.length>0 && [type rangeOfString:@"CDMA"].length>0) {
        return YES;
    } else {
        return NO;
    }
}

+ (NSString *)getIMSI{
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [info subscriberCellularProvider];
    NSString *mcc = [carrier mobileCountryCode];
    NSString *mnc = [carrier mobileNetworkCode];
    NSString *imsi = [NSString stringWithFormat:@"%@%@", mcc, mnc];
    return imsi;
}

+ (NSDictionary *)currentWifiInfo {
    NSArray *ifs = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
    NSDictionary *info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) {
            break;
        }
    }
    return info;
}

+ (NSString *)wifiMacAddress {
    return [self currentWifiInfo][@"BSSID"];
}

+ (NSString *)wifiSSID {
    return [self currentWifiInfo][@"SSID"];
    
}
+ (BOOL)isConnectWifi {
    NSString *ssid = [[self currentWifiInfo] objectForKey:@"SSID"];
    return ssid.length > 0;
}

#pragma mark - System FileDir
+ (NSString*)getDocumentDir
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths.lastObject;
}

+ (NSString*)getTempDir
{
    return NSTemporaryDirectory();
}

+ (NSString*)getCacheDir
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.lastObject;
}

#pragma mark - Label Size
+ (CGSize)sizeOfLabelWithSize:(CGSize)size fontSize:(int)fontSize content:(NSString*)content
{
    if (![Tools stringIsAvailable:content]) {
        return CGSizeZero;
    }
    CGRect rect = [content boundingRectWithSize:size
                                        options:NSStringDrawingUsesLineFragmentOrigin|
                                                NSStringDrawingUsesFontLeading|
                                                NSStringDrawingTruncatesLastVisibleLine
                                     attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize],NSKernAttributeName:@(0)}
                                        context:nil];
    return CGSizeMake(ceil(rect.size.width), ceil(rect.size.height));
}

+ (CGSize)getHeightSize:(CGSize)size fontSize:(int)fontSize content:(NSString*)content {
    NSStringDrawingOptions options =  NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
    CGRect rect = [content boundingRectWithSize:size options:options attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]} context:nil];
//    CGFloat realHeight = ceilf(rect.size.height);
    return CGSizeMake(ceilf(rect.size.width), ceilf(rect.size.height));
}

//计算Label的高度
+ (CGFloat)heightOfLabelWithWidth:(float)width fontSize:(int)fontSize content:(NSString*)content minHeight:(float)minHeight
{
    if (![Tools stringIsAvailable:content]) {
        return minHeight;
    }
    
    NSAttributedString* attributedText = [[NSAttributedString alloc] initWithString:content attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:fontSize],NSKernAttributeName:@(0)}];
    CGRect rect = [attributedText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|
                   NSStringDrawingUsesFontLeading|
                   NSStringDrawingTruncatesLastVisibleLine
                                               context:nil];
    CGFloat height = (rect.size.height <= minHeight) ? minHeight : (rect.size.height);
    return ceil(height);
}

//计算Label的宽度
+ (CGFloat)widthOfLabelWithHeight:(float)height fontSize:(int)fontSize content:(NSString*)content minWidth:(float)minWidth
{
    if (![Tools stringIsAvailable:content]) {
        return minWidth;
    }
    
    NSAttributedString* attributedText = [[NSAttributedString alloc] initWithString:content attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:fontSize],NSKernAttributeName:@(0) }];
    CGRect rect = [attributedText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, height) options:NSStringDrawingUsesLineFragmentOrigin|
                   NSStringDrawingUsesFontLeading|
                   NSStringDrawingTruncatesLastVisibleLine
                                               context:nil];
    CGFloat width = (rect.size.width <= minWidth) ? minWidth : (rect.size.width);
    return ceil(width);
}

#pragma mark - Validate

//验证手机号是否正确
+ (BOOL)validateMobile:(NSString *)mobile{
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES '1\\\\d{10}'"] evaluateWithObject:mobile];
}

//验证字符串是否为有效的email地址
+ (BOOL)validateEmail:(NSString *)email{
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES '^([a-zA-Z0-9_\\.\\-])+\\@(([a-zA-Z0-9\\-])+\\.)+([a-zA-Z0-9]{2,4})+$'"] evaluateWithObject:email];
}

//验证字符串是否为纯英文字符串
+ (BOOL)validateOnyEnglishWord:(NSString *)string{
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES '^([a-zA-Z])'"] evaluateWithObject:string];
}

//验证字符串是否为纯数字字符串
+ (BOOL)validateOnlyNumberWord:(NSString *)string{
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES '^([0-9\\n]+)'"] evaluateWithObject:string];
}

//验证是否只包含英文和汉字
+ (BOOL)validateOnlyEnglishAndChineseWord:(NSString *)string{
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES '[/a-zA-Z\u4e00-\u9fa5\\\\s]{1,99}'"] evaluateWithObject:string];
}

//验证是否只包含英文和数字
+ (BOOL)validateOnlyEnglishAndNumberWord:(NSString *)string{
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES '^[A-Za-z0-9\\\\s\\n]+$'"] evaluateWithObject:string];
}


//检查身份证号是否合法
+ (NSString*)getStringWithRange:(NSString*)str Value1:(NSInteger)value1 Value2:(NSInteger)value2;
{
    return [str substringWithRange:NSMakeRange(value1, value2)];
}

+ (BOOL)areaCode:(NSString*)code
{
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    [dic setObject:@"北京" forKey:@"11"];
    [dic setObject:@"天津" forKey:@"12"];
    [dic setObject:@"河北" forKey:@"13"];
    [dic setObject:@"山西" forKey:@"14"];
    [dic setObject:@"内蒙古" forKey:@"15"];
    [dic setObject:@"辽宁" forKey:@"21"];
    [dic setObject:@"吉林" forKey:@"22"];
    [dic setObject:@"黑龙江" forKey:@"23"];
    [dic setObject:@"上海" forKey:@"31"];
    [dic setObject:@"江苏" forKey:@"32"];
    [dic setObject:@"浙江" forKey:@"33"];
    [dic setObject:@"安徽" forKey:@"34"];
    [dic setObject:@"福建" forKey:@"35"];
    [dic setObject:@"江西" forKey:@"36"];
    [dic setObject:@"山东" forKey:@"37"];
    [dic setObject:@"河南" forKey:@"41"];
    [dic setObject:@"湖北" forKey:@"42"];
    [dic setObject:@"湖南" forKey:@"43"];
    [dic setObject:@"广东" forKey:@"44"];
    [dic setObject:@"广西" forKey:@"45"];
    [dic setObject:@"海南" forKey:@"46"];
    [dic setObject:@"重庆" forKey:@"50"];
    [dic setObject:@"四川" forKey:@"51"];
    [dic setObject:@"贵州" forKey:@"52"];
    [dic setObject:@"云南" forKey:@"53"];
    [dic setObject:@"西藏" forKey:@"54"];
    [dic setObject:@"陕西" forKey:@"61"];
    [dic setObject:@"甘肃" forKey:@"62"];
    [dic setObject:@"青海" forKey:@"63"];
    [dic setObject:@"宁夏" forKey:@"64"];
    [dic setObject:@"新疆" forKey:@"65"];
    [dic setObject:@"台湾" forKey:@"71"];
    [dic setObject:@"香港" forKey:@"81"];
    [dic setObject:@"澳门" forKey:@"82"];
    [dic setObject:@"国外" forKey:@"91"];
    
    if ([dic objectForKey:code] == nil) {
        
        return NO;
    }
    return YES;
}

+ (BOOL)chk18PaperId:(NSString*)sPaperId
{
    //判断位数
    if ([sPaperId length] != 15 && [sPaperId length] != 18) {
        return NO;
    }
    
    NSString* carid = sPaperId;
    long lSumQT = 0;
    //加权因子
    int R[] = { 7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2 };
    //校验码
    unsigned char sChecker[11] = { '1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2' };
    
    //将15位身份证号转换成18位
    
    NSMutableString* mString = [NSMutableString stringWithString:sPaperId];
    if ([sPaperId length] == 15) {
        [mString insertString:@"19" atIndex:6];
        
        long p = 0;
        const char* pid = [mString UTF8String];
        for (int i = 0; i <= 16; i++) {
            p += (pid[i] - 48) * R[i];
        }
        
        int o = p % 11;
        NSString* string_content = [NSString stringWithFormat:@"%c", sChecker[o]];
        [mString insertString:string_content atIndex:[mString length]];
        carid = mString;
    }
    
    //判断地区码
    NSString* sProvince = [carid substringToIndex:2];
    
    if (![Tools areaCode:sProvince]) {
        return NO;
    }
    
    //判断年月日是否有效
    
    //年份
    int strYear = [[Tools getStringWithRange:carid Value1:6 Value2:4] intValue];
    //月份
    int strMonth = [[Tools getStringWithRange:carid Value1:10 Value2:2] intValue];
    //日
    int strDay = [[Tools getStringWithRange:carid Value1:12 Value2:2] intValue];
    
    NSTimeZone* localZone = [NSTimeZone localTimeZone];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeZone:localZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate* date = [dateFormatter dateFromString:[NSString stringWithFormat:@"%d-%d-%d 12:01:01", strYear, strMonth, strDay]];
    if (date == nil) {
        return NO;
    }
    
    const char* PaperId = [carid.uppercaseString UTF8String];
    
    //检验长度
    if (18 != strlen(PaperId))
        return NO;
    //校验数字
    for (int i = 0; i < 18; i++) {
        if (!isdigit(PaperId[i]) && !(('X' == PaperId[i] || 'x' == PaperId[i]) && 17 == i)) {
            return NO;
        }
    }
    //验证最末的校验码
    for (int i = 0; i <= 16; i++) {
        lSumQT += (PaperId[i] - 48) * R[i];
    }
    if (sChecker[lSumQT % 11] != PaperId[17]) {
        return NO;
    }
    
    return YES;
}

#pragma mark - JS

//执行JS语句
+ (id)executeJSWithString:(NSString *)js {
    JSContext *context = [[JSContext alloc] init];
    JSValue *value = [context evaluateScript:js];
    return [value toObject];
}

//执行JS方法，并传入参数
+ (id)executeJSWithString:(NSString *)js method:(NSString *)methodName param:(id)param {
    JSContext *context = [[JSContext alloc] init];
    [context evaluateScript:js];
    JSValue *jsFuncation = context[methodName];
    JSValue *result = [jsFuncation callWithArguments:@[param]];
    return [result toObject];
}

//for webView





#pragma mark - 获取对象的成员变量列表 属性列表 方法列表

/**
 获取对象的成员变量列表
 
 @param objc 被获取成员变量列表的对象
 @return 包含成员变量名的数组
 */
+ (NSArray <NSString*>*)getAllIvarWith:(NSObject *)objc {
    
    NSMutableArray *allIvas = [[NSMutableArray alloc] init];
    
    unsigned int outCount =0;
    
    Ivar*ivars =class_copyIvarList(objc.class, &outCount);
    
    for(unsigned int i =0; i < outCount; ++i) {
        Ivar ivar = ivars[i];
        const char*ivarName =ivar_getName(ivar);
        
        const char*ivarEncoder =ivar_getTypeEncoding(ivar);
        NSString *ivarStr = [[NSString alloc] initWithUTF8String:ivarName];
        NSLog(@"## className:%@ \nIvar name:%@ \nIvar TypeEncoder:%s",NSStringFromClass(objc.class),ivarStr,ivarEncoder);
        [allIvas addObject:ivarStr];
             }
    free(ivars);
    return allIvas;
}

/**
 获取对象的方法列表
 
 @param objc 被获取方法列表的对象
 @return 返回包含方法名的数组
 */
+ (NSArray <NSString*>*)getAllMethodsWith:(NSObject *)objc {
    
    NSMutableArray *allMethods = [[NSMutableArray alloc] init];
    
    unsigned int methCount = 0;
    Method *meths = class_copyMethodList([objc class], &methCount);
    
    for(int i = 0; i < methCount; i++) {
        
        Method meth = meths[i];
        
        SEL sel = method_getName(meth);
        
        const char *name = sel_getName(sel);
        NSString *methodNameStr = [[NSString alloc] initWithUTF8String:name];
        [allMethods addObject:methodNameStr];
        NSLog(@"## methodName:%s", name);
    }
    
    free(meths);
    
    return allMethods;
}


/**
 获取对象的属性列表
 
 @param objc 被获取属性列表的对象
 @return 返回包含属性名的数组
 */
+ (NSArray <NSString*> *)getAllPropertysWith:(NSObject *)objc {
    // 获取当前类的所有属性
    unsigned int count;// 记录属性个数
    objc_property_t *properties = class_copyPropertyList(objc.class, &count);
    // 遍历
    NSMutableArray *mArray = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        // An opaque type that represents an Objective-C declared property.
        // objc_property_t 属性类型
        objc_property_t property = properties[i];
        // 获取属性的名称 C语言字符串
        const char *cName = property_getName(property);
        // 转换为Objective C 字符串
        NSString *name = [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
        NSLog(@"## propertyName:%@",name);
        [mArray addObject:name];
    }
    free(properties);
    return mArray.copy;
}

+ (NSString *)getCurrentDate {
     NSDate *date = [NSDate date];
     NSDateFormatter *forMatter = [[NSDateFormatter alloc] init];
       //设置你想要的格式,hh与HH的区别:分别表示12小时制,24小时制
     [forMatter setDateFormat:@"yyyy-MM-dd"];
     NSString *dateStr = [forMatter stringFromDate:date];
     return dateStr;  
}



@end
