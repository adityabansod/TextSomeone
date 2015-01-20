//
//  AppDelegate.swift
//  TextSomeone
//
//  Created by Aditya Bansod on 1/7/15.
//  Copyright (c) 2015 Aditya Bansod. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        NSLog("launchOptions \(launchOptions)")
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Sound|UIUserNotificationType.Alert|UIUserNotificationType.Badge, categories: nil))
        
        if let options = launchOptions {
            if let notification = options[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
                NSLog("application launched because of a notification", notification)
            }
            if let location: AnyObject = options[UIApplicationLaunchOptionsLocationKey]  {
                NSLog("application launched because of a location event")
            }
        }
        return true
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        // http://nshipster.com/launch-options/ seems like this is all we need
        // as it's called regarless of the app being open or closed
        
        NSLog("application did recieve a local notif")
        if let info = notification.userInfo as? [String:String] {
            let phone = info["phone"] as String!
            let message = info["message"] as String!
            
            let url = NSURL(string: "sms:\(phone)")
            NSLog("opening URL sms:\(phone)")
            UIApplication.sharedApplication().openURL(url!)
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

