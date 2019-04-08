//
//  XGPushHelper.h
//  AirCleaner
//
//  Created by HuYong on 15/10/22.
//  Copyright © 2015年 HadLinks. All rights reserved.
//

#import <XGPush/XGPush.h>
#import <XGPush/XGSetting.h>

#if RELEASE
#    define XG_AppId 0
#    define XG_AppKey @""
#elif BETA
#    define XG_AppId 0
#    define XG_AppKey @""
#else
#    define XG_AppId 0
#    define XG_AppKey @""
#endif

#define XGPushHelperInstance [XGPushHelper sharedInstance]

static NSString *NewMessageNotificationKey = @"NewMessageNotificationKey";

@class XGPushHelper;

@protocol XGPushHelperDelegate <NSObject>
@optional
- (void)helper:(XGPushHelper *)helper message:(NSString *)message;
- (void)helper:(XGPushHelper *)helper okayOfRegister:(NSString *)message;
- (void)helper:(XGPushHelper *)helper failureOfRegister:(NSString *)message;
- (void)helper:(XGPushHelper *)helper okayOfUnregister:(NSString *)message;
- (void)helper:(XGPushHelper *)helper failureOfUnregister:(NSString *)message;

@end

@interface XGPushHelper : NSObject

@property (weak, nonatomic) id<XGPushHelperDelegate> msgdelegate;
@property (assign, nonatomic) NSInteger numberOfBadge;

+ (instancetype)sharedInstance;

// 启动时回调
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

// 接收到本地通知时的回调
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification;

// 注册UserNotification成功的回调
- (void)application:(UIApplication *)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;

// 远程通知注册成功回调
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

// 如果deviceToken获取不到会进入此事件
- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err;

// 接收到推送消息
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;

// IOS7当设置了"content-available" = 1;字段时会回调此函数
- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

// IOS自定义Action
- (void)application:(UIApplication *)application
    handleActionWithIdentifier:(NSString *)identifier
         forRemoteNotification:(NSDictionary *)userInfo
             completionHandler:(void (^)(void))completionHandler;

/**
 * 角标处理
 * 通知移除处理
 */
- (void)setApplicationIconBadgeNumber:(NSInteger)number;
- (void)clearAllNotifications;

/**
 * 注册和取消注册（推送和取消推送）
 */
- (void)unregister;
- (void)registerWithAccount:(NSString *)account;

@end
