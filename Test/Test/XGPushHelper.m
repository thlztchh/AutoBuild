//
//  XGPushHelper.m
//  AirCleaner
//
//  Created by HuYong on 15/10/22.
//  Copyright © 2015年 HadLinks. All rights reserved.
//

#import "XGPushHelper.h"
//#import "MessageManager.h"

#define _IPHONE80_ 80000

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0

#	import <UserNotifications/UserNotifications.h>
@interface XGPushHelper () <UNUserNotificationCenterDelegate>
@end
#endif

@interface XGPushHelper ()

@property (strong, nonatomic) NSData *deviceToken;
@property (strong, nonatomic) NSString *account;

@end

@implementation XGPushHelper

+ (instancetype)sharedInstance {
	static XGPushHelper *singleInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		singleInstance = [XGPushHelper new];
	});
	return singleInstance;
}

- (instancetype)init {
	// 启动KVO
	if (self = [super init]) {
		[self addObserver:self forKeyPath:@"account" options:NSKeyValueObservingOptionNew context:nil];
		[self addObserver:self forKeyPath:@"deviceToken" options:NSKeyValueObservingOptionNew context:nil];
	}
	return self;
}

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"account"];
	[self removeObserver:self forKeyPath:@"deviceToken"];
}

// 观察到account或devicetoken的变化
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *, id> *)change
                       context:(void *)context {
	if (self.account.length < 1 || self.deviceToken.length < 1)
		return;
	[self doRegister];
}

/**
 * 注册（推送）
 */
- (void)initForRegister {
	void (^successCallback)(void) = ^(void) {
		[self registerAPNS];
		//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= _IPHONE80_
		//        float sysVer = [[[UIDevice currentDevice] systemVersion]
		//        floatValue]; if(sysVer < 8) { // iOS8之前注册push方法
		//            [self registerPush];
		//        } else { // iOS8注册push方法
		//            [self registerPushForIOS8];
		//        }
		//#else
		//        [self registerPush];    // iOS8之前注册push方法
		//#endif
	};
	[XGPush initForReregister:successCallback];
}

/**
 * 推送注册
 * 用户注册
 */
- (void)registerWithAccount:(NSString *)account {

	if (!account)
		return;
	self.account = [account copy];
	if (self.deviceToken)
		return;
	[self initForRegister];
}
// 取消注册
- (void)unregister {
	__weak typeof(self) wself = self;
	void (^successBlock)(void) = ^(void) {
		// 成功之后的处理
		wself.account = nil;
		wself.deviceToken = nil;
		if ([wself.msgdelegate respondsToSelector:@selector(helper:okayOfUnregister:)]) {
			[wself.msgdelegate helper:wself
			         okayOfUnregister:[NSString stringWithFormat:@"[xgpush]register "
			                                                     @"success block code"]];
		}
	};
	void (^errorBlock)(void) = ^(void) {
		// 失败之后的处理
		if ([wself.msgdelegate respondsToSelector:@selector(helper:failureOfUnregister:)]) {
			[wself.msgdelegate helper:wself
			      failureOfUnregister:[NSString stringWithFormat:@"[xgpush]register error block code"]];
		}
	};

	[XGPush unRegisterDevice:successBlock errorCallback:errorBlock];
}
- (void)doRegister {
	__weak typeof(self) wself = self;
	void (^successBlock)(void) = ^(void) {
		// 成功之后的处理
		if ([wself.msgdelegate respondsToSelector:@selector(helper:okayOfRegister:)]) {
			[wself.msgdelegate helper:wself
			           okayOfRegister:[NSString stringWithFormat:@"[xgpush]register success block code"]];
		}
	};
	void (^errorBlock)(void) = ^(void) {
		// 失败之后的处理
		wself.account = nil;
		wself.deviceToken = nil;
		if ([wself.msgdelegate respondsToSelector:@selector(helper:failureOfRegister:)]) {
			[wself.msgdelegate helper:wself
			        failureOfRegister:[NSString stringWithFormat:@"[xgpush]register error block code"]];
		}
	};
	// 注册设备
	[XGPush setAccount:self.account];

	[XGPush registerDevice:self.deviceToken successCallback:successBlock errorCallback:errorBlock];
}

/**
 * 推送注册时回调处理
 */
// 推送通知设置回调
- (void)application:(UIApplication *)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
	// 用户已经允许接收以下类型的推送
	if ([self.msgdelegate respondsToSelector:@selector(helper:message:)]) {
		[self.msgdelegate helper:self
		                 message:[NSString stringWithFormat:@"[xgpush]user has permited to receive "
		                                                    @"remote push notification"]];
	}
}

// 注册成功回调
- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	if ([self.msgdelegate respondsToSelector:@selector(helper:message:)]) {
		[self.msgdelegate helper:self message:[NSString stringWithFormat:@"[xgpush]did register"]];
	}
	self.deviceToken = [deviceToken copy];
}

// 如果deviceToken获取不到会进入此事件
- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
	if ([self.msgdelegate respondsToSelector:@selector(helper:message:)]) {
		[self.msgdelegate
		     helper:self
		    message:[NSString stringWithFormat:@"[xgpush]did fail to register with error = %@", err]];
	}
}

/**
 * 接受推送消息
 * 启动时
 */
// 启动时
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	//初始化app
	[XGPush startApp:XG_AppId appKey:XG_AppKey];
	NSLog(@"XG_AppId：%ld", XG_AppId);
    
	[self initForRegister];
	[XGPush handleLaunching:launchOptions successCallback:nil errorCallback:nil];
	if (!launchOptions)
		return YES;

	NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
	if (!userInfo)
		return YES;

	// 这里定义自己的处理方式
	[[NSNotificationCenter defaultCenter] postNotificationName:NewMessageNotificationKey
	                                                    object:@"启动时"
	                                                  userInfo:userInfo];
	return YES;
}

/**
 * 接受推送消息
 * 运行时
 */
// iOS 10 新增 API
// iOS 10 会走新 API, iOS 10 以前会走到老 API
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
// App 用户点击通知的回调
// 无论本地推送还是远程推送都会走这个回调
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
    didReceiveNotificationResponse:(UNNotificationResponse *)response
             withCompletionHandler:(void (^)())completionHandler {
	NSLog(@"[XGDemo] click notification");
	NSDictionary *userInfo = response.notification.request.content.userInfo;
	[XGPush handleReceiveNotification:userInfo];

	++XGPushHelperInstance.numberOfBadge;
	[[NSNotificationCenter defaultCenter] postNotificationName:NewMessageNotificationKey
	                                                    object:@"click"
	                                                  userInfo:userInfo];
	// 推送反馈(app运行时)
	[self handleReceiveNotification:userInfo];
	completionHandler();
}

// App 在前台弹通知需要调用这个接口
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
	NSDictionary *userInfo = notification.request.content.userInfo;
	++XGPushHelperInstance.numberOfBadge;
	[[NSNotificationCenter defaultCenter] postNotificationName:NewMessageNotificationKey
	                                                    object:nil
	                                                  userInfo:userInfo];
	// 推送反馈(app运行时)
	[self handleReceiveNotification:userInfo];
	completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound |
	                  UNNotificationPresentationOptionAlert);
}
#endif
// IOS 6
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	if ([self.msgdelegate respondsToSelector:@selector(helper:message:)]) {
		[self.msgdelegate
		     helper:self
		    message:[NSString stringWithFormat:@"[xgpush]did receive remote userinfo : %@", userInfo]];
	}
	if (application.applicationState == UIApplicationStateActive) {
		// 第二种情况， app处于前台时处理
	} else {
		// 第三种情况:程序处于后台运行时接收到消息
	}
	++XGPushHelperInstance.numberOfBadge;
	[[NSNotificationCenter defaultCenter] postNotificationName:NewMessageNotificationKey
	                                                    object:nil
	                                                  userInfo:userInfo];
	// 推送反馈(app运行时)
	[self handleReceiveNotification:userInfo];
}

// IOS 7当设置了"content-available" = 1;字段时会回调此函数
- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
	if ([self.msgdelegate respondsToSelector:@selector(helper:message:)]) {
		[self.msgdelegate helper:self
		                 message:[NSString stringWithFormat:@"[xgpush]did receive userinfo : %@", userInfo]];
	}
	if (application.applicationState == UIApplicationStateActive) {
		// 第二种情况， app处于前台时处理
	} else {
		// 第三种情况:程序处于后台运行时接收到消息
		// 清除所有通知(包含本地通知)
	}
	++XGPushHelperInstance.numberOfBadge;
	[[NSNotificationCenter defaultCenter] postNotificationName:NewMessageNotificationKey
	                                                    object:nil
	                                                  userInfo:userInfo];
	// 推送反馈(app运行时
	[self handleReceiveNotification:userInfo];
	// 数据处理完成
	completionHandler(UIBackgroundFetchResultNewData);
}

// IOS 8
- (void)application:(UIApplication *)application
    handleActionWithIdentifier:(NSString *)identifier
         forRemoteNotification:(NSDictionary *)userInfo
             completionHandler:(void (^)())completionHandler {
	if ([self.msgdelegate respondsToSelector:@selector(helper:message:)]) {
		[self.msgdelegate helper:self
		                 message:[NSString stringWithFormat:@"[xgpush]handle action with "
		                                                    @"identifier = %@, userinfo = %@",
		                                                    identifier, userInfo]];
		if ([identifier isEqualToString:@"ACCEPT_IDENTIFIER"]) {
			[self.msgdelegate helper:self message:@"ACCEPT_IDENTIFIER is clicked"];
		}
	}
	if (application.applicationState == UIApplicationStateActive) {
		// 处于前端
	} else {
		// 处于后端
	}
	// 处理数据
	++XGPushHelperInstance.numberOfBadge;
	[[NSNotificationCenter defaultCenter] postNotificationName:NewMessageNotificationKey
	                                                    object:nil
	                                                  userInfo:userInfo];
	// 推送反馈(app运行时)
	[self handleReceiveNotification:userInfo];
	// 数据处理完成
	completionHandler();
}
// 本地推送
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
	if ([self.msgdelegate respondsToSelector:@selector(helper:message:)]) {
		[self.msgdelegate helper:self message:[NSString stringWithFormat:@"[xgpush]did receive local"]];
	}
	// 清空推送列表
	if (application.applicationState ==
	    UIApplicationStateActive) { // app前端时弹出的窗口，此时是app主动弹出，不进行移除处理
		[XGPush localNotificationAtFrontEnd:notification userInfoKey:@"clockID" userInfoValue:@"myid"];
	} else {
		[XGPush delLocalNotification:notification];
	}
}

/**
 * 角标处理
 * 通知移除处理
 */
- (void)setNumberOfBadge:(NSInteger)numberOfBadge {
	_numberOfBadge = numberOfBadge;
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:numberOfBadge];
}
- (void)setApplicationIconBadgeNumber:(NSInteger)number {
	self.numberOfBadge = number;
}
- (void)clearAllNotifications {
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
	[[UIApplication sharedApplication] cancelAllLocalNotifications];
}
- (void)handleReceiveNotification:(NSDictionary *)userInfo {
	[XGPush handleReceiveNotification:userInfo];
}

/**
 * 推送注册
 * 手机设备注册
 */

/** iOS10的注册方法*/
- (void)registerAPNS {
	float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
	if (sysVer >= 10) {
		// iOS 10
		[self registerPush10];
	} else if (sysVer >= 8) {
		// iOS 8-9
		[self registerPush8to9];
	} else {
		// before iOS 8
		[self registerPushBefore8];
	}
#else
	if (sysVer < 8) {
		// before iOS 8
		[self registerPushBefore8];
	} else {
		// iOS 8-9
		[self registerPush8to9];
	}
#endif
}

- (void)registerPush10 {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
	if ([self.msgdelegate respondsToSelector:@selector(helper:message:)]) {
		[self.msgdelegate helper:self message:@"[xgpush]register for iOS10"];
	}
	UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
	center.delegate = self;
	[center requestAuthorizationWithOptions:UNAuthorizationOptionBadge | UNAuthorizationOptionSound |
	                                        UNAuthorizationOptionAlert
	                      completionHandler:^(BOOL granted, NSError *_Nullable error) {
		                      if (granted) {
                                  NSLog(@"granted === %d",granted);
		                      }
	                      }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    });
#endif
}

- (void)registerPush8to9 {
	if ([self.msgdelegate respondsToSelector:@selector(helper:message:)]) {
		[self.msgdelegate helper:self message:@"[xgpush]register for iOS8"];
	}
	UIUserNotificationType types =
	    UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
	UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
	[[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
	[[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)registerPushBefore8 {
	if ([self.msgdelegate respondsToSelector:@selector(helper:message:)]) {
		[self.msgdelegate helper:self message:@"[xgpush]registerPush"];
	}
	[[UIApplication sharedApplication]
	    registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge |
	                                        UIRemoteNotificationTypeSound)];
}

/******* iOS10 之前的注册方法 */
// 推送注册：iOS8
- (void)registerPushForIOS8 {
	if ([self.msgdelegate respondsToSelector:@selector(helper:message:)]) {
		[self.msgdelegate helper:self message:@"[xgpush]register for iOS8"];
	}
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= _IPHONE80_
	// Types
	UIUserNotificationType types =
	    UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;

	// Actions
	UIMutableUserNotificationAction *acceptAction = [[UIMutableUserNotificationAction alloc] init];
	acceptAction.identifier = @"ACCEPT_IDENTIFIER";
	acceptAction.title = @"Accept";
	acceptAction.activationMode = UIUserNotificationActivationModeForeground;
	acceptAction.destructive = NO;
	acceptAction.authenticationRequired = NO;

	// Categories
	UIMutableUserNotificationCategory *inviteCategory = [[UIMutableUserNotificationCategory alloc] init];
	inviteCategory.identifier = @"INVITE_CATEGORY";
	[inviteCategory setActions:@[ acceptAction ] forContext:UIUserNotificationActionContextDefault];
	[inviteCategory setActions:@[ acceptAction ] forContext:UIUserNotificationActionContextMinimal];

	NSSet *categories = [NSSet setWithObjects:inviteCategory, nil];
	UIUserNotificationSettings *mySettings =
	    [UIUserNotificationSettings settingsForTypes:types categories:categories];
	[[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
	[[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
}

// 推送注册：< iOS8
- (void)registerPush {
	if ([self.msgdelegate respondsToSelector:@selector(helper:message:)]) {
		[self.msgdelegate helper:self message:@"[xgpush]registerPush"];
	}
	[[UIApplication sharedApplication]
	    registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge |
	                                        UIRemoteNotificationTypeSound)];
}

@end
