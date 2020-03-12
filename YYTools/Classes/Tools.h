//
//  Tools.h
//  FreeBird
//
//  Created by baozhou on 15/8/12.
//  Copyright (c) 2015年 liepin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, UCPlaceHolderType) {
    UCPlaceHolderType_Gray      = 0,//灰色占位图
    UCPlaceHolderType_Custom    = 1,//自定义占位图
    UCPlaceHolderType_DefaultCarList = 2,//车源列表默认占位图
};
@interface Tools : NSObject

#pragma mark - Utils
//切换运行在主线程
+(void)runMainThread:(void(^)(void))block;
/**获取应用视图所在的Controller*/
+ (UIViewController *)currentController;

//能否打电话
+(BOOL)canTel;
//拨打电话
+(void)tel:(NSString *)telNo;
//能否打开这个URL
+(BOOL)canOpenURL:(NSString *)url;
//打开某个URL
+(void)openURL:(NSString *)url;
//字符串是否有效
+(BOOL)stringIsAvailable:(NSString *)string;
//数组是否有效
+(BOOL)arrayIsAvailable:(NSArray *)array;
//字典是否有效
+(BOOL)dictionaryIsAvailable:(NSDictionary *)dictionary;

//复制字符串
+(void)pasteString:(NSString *)string;
//复制图片
+(void)pasteImage:(UIImage *)image;

//获取拼音首字母(传入汉字字符串, 返回大写拼音首字母)
+ (NSString *)firstCharactor:(NSString *)aString;

//格式话金额，限制小数点后2位数，格式如1,000,200.38
+ (NSString *)formatCoinString:(double)coin;
//格式话金额，指定格式化样式，如###,##0.00
+ (NSString *)formatNumberString:(double)coin format:(NSString *)format;

//从SDImageCache缓存中获取图片
+ (UIImage*)getImageCache:(NSString*)url;

//DES加密
+ (NSString *)encryptUseDES:(NSString *)plainText key:(NSString *)key;
//DES解密
+(NSString *)decryptUseDES:(NSString *)cipherText key:(NSString *)key;


#pragma mark - Authorization
+ (BOOL)isAllowedNotification;  //是否允许push通知提醒
+ (BOOL)canAuthorizationAssetLibrary;       //是否有权限访问相册
+ (BOOL)canAuthorizationCamera;       //是否有权限访问相机，带有编辑功能时需要判断照片库权限
+ (BOOL)canAuthorizationLocation;           //是否有权限访问定位服务
+ (BOOL)canAuthorizationMicrophone;           //是否有权限访问麦克风
+ (BOOL)canAuthorizationContact;           //是否有权限访问通讯录

#pragma mark - AutoLayout
+ (void)setEdge:(UIView*)superview view:(UIView*)view attr:(NSLayoutAttribute)attr constant:(CGFloat)constant;
+ (void)setWidthEqualHeightWithView:(UIView*)view;


#pragma mark - Device
//屏幕缩放率
+(CGFloat)screenScale;
//屏幕宽带
+(CGFloat)screenWidth;
//屏幕高度
+(CGFloat)screenHeight;
//状态栏高度
+(CGFloat)statusBarHeight;
//底部安全区域高度
+(CGFloat)bottomSafeHeight;
//顶部安全区域高度
+(CGFloat)topSafeHeight;

+(BOOL)isIPhone4;
+(BOOL)isIPhone5;
+(BOOL)isIPhone6;
+(BOOL)isIPhone6Plus;
+(BOOL)isIPhoneX;
+(BOOL)isIPad;

//+ (NSString*)guidString; //设备唯一标识
+ (NSString*)deviceInfo; //设备信息

//设置网络信息
// 网络接入的方式,0是移动网络，如2、3、4G，1是wifi，2 是无网络
//+ (NSInteger)networkAccessType;
//获取设备IP
+ (NSString *)getDeviceIPAddresses;
//获取设置MAC地址，已废弃，该方法无用，固定值为020000000000
+ (NSString *)getMacAddress;
//手机运营商名字
+ (NSString *)phoneCarrierName;
//手机网络类型，GSM/GPRS/EDGE/HSUPA/HSDPA/ WCDMA
+ (NSString *)phoneCarrierNetworkType;
//手机网络类型，2G、3G、4G
+ (NSString *)phoneNetworkType;
//是否为CDMA网络类型
+ (BOOL)isCDMA;
//手机运营商代码
+ (NSString *)getIMSI;
//获取单个wifi信息
+ (NSDictionary *)currentWifiInfo;
//获取链接的wifi的mac地址
+ (NSString *)wifiMacAddress;
///获取链接的wifi的名称
+ (NSString *)wifiSSID;
//设置是否正在使用wifi
+ (BOOL)isConnectWifi;

//获取设备缓存目录
+ (NSString*)getDocumentDir;
+ (NSString*)getTempDir;
+ (NSString*)getCacheDir;

#pragma mark - LabelSize
/**
 *  宽度和高度
 *
 *  @param size     宽度和最大高度
 *  @param fontSize 字体
 *  @param content  计算的字符串
 *
 *  @return 宽度和高度
 */
+ (CGSize)sizeOfLabelWithSize:(CGSize)size fontSize:(int)fontSize content:(NSString*)content;

+ (CGSize)getHeightSize:(CGSize)size fontSize:(int)fontSize content:(NSString*)content;

//计算Label的高度
+ (CGFloat)heightOfLabelWithWidth:(float)width fontSize:(int)fontSize content:(NSString*)content minHeight:(float)minHeight;
//计算Label的宽度
+ (CGFloat)widthOfLabelWithHeight:(float)height fontSize:(int)fontSize content:(NSString*)content minWidth:(float)minWidth;

#pragma mark - Validate
//验证手机号是否正确
+ (BOOL)validateMobile:(NSString *)mobile;
//验证字符串是否为有效的email地址
+ (BOOL)validateEmail:(NSString *)email;
//验证字符串是否为纯英文字符串
+ (BOOL)validateOnyEnglishWord:(NSString *)string;
//验证字符串是否为纯数字字符串
+ (BOOL)validateOnlyNumberWord:(NSString *)string;
//验证是否只包含英文和汉字
+ (BOOL)validateOnlyEnglishAndChineseWord:(NSString *)string;
//验证是否只包含英文和数字
+ (BOOL)validateOnlyEnglishAndNumberWord:(NSString *)string;

//检查身份证号是否合法
+ (BOOL)chk18PaperId:(NSString *)sPaperId;

#pragma mark - JS
//执行本地JS语句，单纯的执行js表达式语句
//应用场景：如服务端返回了一串JS代码，客户端需要执行js得到相应返回值做它用
+ (id)executeJSWithString:(NSString *)js;
//执行本地JS方法，并传入参数，单纯的执行js表达式语句
//应用场景：同上，但如果js代码中是一个方法，则需要在method中执行方法的名字和param参数，则会执行js方法并得到返回值
+ (id)executeJSWithString:(NSString *)js method:(NSString *)methodName param:(id)param;

#pragma mark - 获取对象的成员变量列表 属性列表 方法列表
/**
 获取对象的成员变量列表
 
 @param objc 被获取属性列表的对象
 @return 包含成员变量名的数组
 */
+ (NSArray <NSString*>*)getAllIvarWith:(NSObject *)objc;

/**
 获取对象的方法列表
 
 @param objc 被获取方法列表的对象
 @return 返回包含方法名的数组
 */
+ (NSArray <NSString*>*)getAllMethodsWith:(NSObject *)objc;

/**
 获取对象的属性列表
 
 @param objc 被获取属性列表的对象
 @return 返回包含属性名的数组
 */
+ (NSArray <NSString*> *)getAllPropertysWith:(NSObject *)objc;

+ (NSString *)getCurrentDate;


/**
 获取当前城市cityId
 */
+ (NSString *)getCurrentCityId;

/**
 加载视图

 @param imageView 需要加载的imageVIew
 @param urlString 加载的视图url
 @param type 加载的占位图方式
 0 灰色占位图
 1 本地图片-图片名为placeHoldImgName
 */
+ (void)setUpImageViewWithView:(UIImageView *)imageView urlString:(nullable NSString *)urlString placeHolderimageWithType:(UCPlaceHolderType)type PlaceHoldImageName:(NSString *_Nullable)placeHoldImgName;

/**
 跳转本地scheme协议

 @param urlString url
 */
+ (void)jumpLocolSchemeWithUrl:(NSString *)urlString;

+ (NSMutableAttributedString *)appendContent:(NSString *)content;

+ (NSMutableAttributedString *)appendDetailContent:(NSString *)content;
@end
