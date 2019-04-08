//
//  AppDelegate.m
//  Test
//
//  Created by thlztc on 2019/4/8.
//  Copyright © 2019 thlztc. All rights reserved.
//

#import "AppDelegate.h"
#import "XGPushHelper.h"
@interface AppDelegate () <XGPushHelperDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // 注册信鸽推送
    XGPushHelperInstance.msgdelegate = self;
    // 注册远程通知的通知
    [XGPushHelperInstance application:application didFinishLaunchingWithOptions:launchOptions];
//    [XGPushHelperInstance registerWithAccount:@"123456"];


#if TEST
    NSLog(@"test------------------version = %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]);
);
#elif DEBUG
    NSLog(@"DEBUG-----------------version = %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]);
#elif RELEASE
    NSLog(@"RELEASE---------------version = %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]);
#elif Beta
    NSLog(@"Beta------------------version = %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]);
#endif
    
#if TestEnvironment
    NSLog(@"TestEnvironment === 1 测试环境");
#else
    NSLog(@"TestEnvironment === 0 正式环境");
#endif
    
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark 推送控制

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [XGPushHelperInstance application:application didReceiveLocalNotification:notification];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= _IPHONE80_
- (void)application:(UIApplication *)application
didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [XGPushHelperInstance application:application didRegisterUserNotificationSettings:notificationSettings];
}
#endif

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [XGPushHelperInstance application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    NSString *token = [[deviceToken description]
                       stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"deviceToken---%@", token);
}

// 如果deviceToken获取不到会进入此事件
- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    [XGPushHelperInstance application:app didFailToRegisterForRemoteNotificationsWithError:err];
}

// IOS6
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [XGPushHelperInstance application:application didReceiveRemoteNotification:userInfo];
}

// IOS7当设置了"content-available" = 1;字段时会回调此函数
- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [XGPushHelperInstance application:application
         didReceiveRemoteNotification:userInfo
               fetchCompletionHandler:completionHandler];
}

// IOS8
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= _IPHONE80_
- (void)application:(UIApplication *)application
handleActionWithIdentifier:(NSString *)identifier
forRemoteNotification:(NSDictionary *)userInfo
  completionHandler:(void (^)())completionHandler {
    [XGPushHelperInstance application:application
           handleActionWithIdentifier:identifier
                forRemoteNotification:userInfo
                    completionHandler:completionHandler];
}
#endif

#pragma mark 系统控制



- (void)helper:(XGPushHelper *)helper message:(NSString *)message {
    NSLog(@"message ------ %@", message);
}

- (void)helper:(XGPushHelper *)helper okayOfRegister:(NSString *)message {
    
    
    NSLog(@"okay message = %@",message);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                       /** 通知，跳转页面 */
                       
                   });
    
    
}



- (void)helper:(XGPushHelper *)helper failureOfRegister:(NSString *)message {
    NSLog( @"failureOfRegister = %@",message  );
}

- (void)helper:(XGPushHelper *)helper okayOfUnregister:(NSString *)message {
    NSLog( @"okayOfUnregister = %@",message  );

}

- (void)helper:(XGPushHelper *)helper failureOfUnregister:(NSString *)message {
    NSLog( @"failureOfUnregister = %@",message  );

}
@end
