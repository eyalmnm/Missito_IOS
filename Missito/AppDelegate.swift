//
//  AppDelegate.swift
//  Missito
//
//  Created by Georg on 23/05/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import UserNotifications
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // Keep here sender phone number if contacts are not yet loaded when receiving remote notification
    private var phoneToOpenChatScreen: String?
    private var isInitialized = false
    var window: UIWindow?

    let gcmMessageIDKey = "gcm.message_id"
    
    let mqttStartDebouncer = Debouncer(delay: 0.5) { dispatchedWorkItem in
        guard !dispatchedWorkItem.isCancelled else {
            return
        }
        
        DispatchQueue.main.async {
            if !dispatchedWorkItem.isCancelled {
                if let authService = CoreServices.authService, authService.authState == .loggedIn {
                    authService.brokerConnection.connect(userId: authService.userId!, deviceId: authService.userDeviceId,
                                                         token: authService.backendToken!)
                }
            }
        }
    }
    
    override init() {
        super.init()
        
        // Add observer for InstanceID token refresh callback.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.tokenRefreshNotification),
                                               name: .MessagingRegistrationTokenRefreshed,
                                               object: nil)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        IQKeyboardManager.sharedManager().enable = true
        IQKeyboardManager.sharedManager().enableAutoToolbar = false
        NotificationCenter.default.addObserver(self, selector: #selector(onContactsReady),
                                               name: ContactsManager.CONTACTS_READY_NOTIF, object: nil)
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {granted, error in
                    NSLog("requestAuthorization = " + String(granted) + ", error = " + (error?.localizedDescription ?? "-")!)
            })
            
            // For iOS 10 data message (sent via FCM)
            Messaging.messaging().delegate = self
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        // Trying to mitigate the problem with missing keychain data by delaying the first usage of iOS Keychain
        // See https://github.com/evgenyneu/keychain-swift/issues/15
        self.window?.rootViewController = UIStoryboard(name: "Launch Screen", bundle: nil).instantiateInitialViewController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.startApp()
        }
        return true
    }
    
    func startApp() {
        if MissitoHelper.wasAppReinstalled() {
            KeyChainHelper.cleanKeychain()
            let uuid = UUID().uuidString
            DefaultsHelper.saveInstallId(uuid)
            KeyChainHelper.saveInstallId(uuid)
        }
        
        CoreServices.setup()
        if CoreServices.authService?.authState == .loggedIn {
            if DefaultsHelper.getUserName() == nil {
                self.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "nameInput")
            } else {
                self.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
            }
        } else {
            self.window?.rootViewController = UIStoryboard(name: "Auth", bundle: nil).instantiateInitialViewController()
        }
        
        isInitialized = true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NSLog("FCM token OK: \(Messaging.messaging().fcmToken ?? "")")
    }
    
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("FCM token FAIL: %@", error.localizedDescription)
    }
    
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = InstanceID.instanceID().token() {
            print("InstanceID token: \(refreshedToken)")
            runWhenInitialized {
                if let cloudToken = Messaging.messaging().fcmToken, CoreServices.authService?.authState == .loggedIn {
                    APIRequests.updateCloudToken(cloudToken: cloudToken) {
                        error in
                        if let error = error {
                            NSLog(error.localizedDescription)
                        }
                    }
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        runWhenInitialized {
            self.handleRemoteNotification(userInfo)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        runWhenInitialized {
            self.handleRemoteNotification(userInfo)
        }
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func runWhenInitialized(_ closure: @escaping ()->()) {
        if (isInitialized) {
            closure()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.runWhenInitialized {
                    self.runWhenInitialized(closure)
                }
            })
        }
    }
    
    // Called by tapping on notification
    func handleRemoteNotification(_ userInfo: [AnyHashable : Any]) {
        //Print MessageID
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        //Print notification data
        print(userInfo)
        
        if let userId = getUserId(from: userInfo), CoreServices.authService?.authState == .loggedIn {
            print(userId)
            // TODO: do not add "+" when backend will send phone numbers with "+"
            let phone = userId.trimmingCharacters(in: .whitespacesAndNewlines).starts(with: "+") ? userId : "+" + userId
            if !ContactsManager.contactsByPhone.isEmpty, let contact = ContactsManager.contactsByPhone[phone] {
                openChatController(with: contact)
            } else {
                phoneToOpenChatScreen = phone
            }
        }
    }
    
    @objc private func onContactsReady() {
        if let phoneToOpenChatScreen = self.phoneToOpenChatScreen, let contact = ContactsManager.contactsByPhone[phoneToOpenChatScreen] {
            openChatController(with: contact)
        }
    }
    
    private func openChatController(with contact: Contact) {
        if let rootVC = window?.rootViewController, let customTabBarController = rootVC as? CustomTabBarController {
            let selectedVC = (customTabBarController.selectedViewController as! UINavigationController).topViewController
            
            if let contactsController = selectedVC as? ChatPresenting {
                contactsController.openChat(with: contact, animated: false)
            } else if let chatController = selectedVC as? ChatController {
                if chatController.contact?.phone != contact.phone {
                    let parent = (chatController.parent as! UINavigationController)
                    parent.popViewController(animated: false)
                    
                    if let chatPresentingVC = parent.viewControllers.last as? ChatPresenting {
                        chatPresentingVC.openChat(with: contact, animated: false)
                    }
                }
            } else if let navigationVC = selectedVC?.navigationController {
                let storyboard = UIStoryboard(name: "Chats", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "chatController") as! ChatController
                controller.contact = contact
                navigationVC.pushViewController(controller, animated: false)
            } else {
                reinitMainAndOpenChat(with: contact)
            }
        } else {
            reinitMainAndOpenChat(with: contact)
        }
    }
    
    private func getUserId(from userInfo: [AnyHashable : Any]) -> String? {
        return userInfo["phone"] as? String
    }

    private func reinitMainAndOpenChat(with contact: Contact) {
        window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        if let tabController = window?.rootViewController as? CustomTabBarController {
            tabController.selectedIndex = 0
            if let viewCtrls = tabController.viewControllers, !viewCtrls.isEmpty,
                let navController = viewCtrls[0] as? UINavigationController, let contactsController = navController.topViewController as? ContactsController {
                contactsController.openChat(with: contact, animated: false)
            }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        if (isInitialized) {
            CoreServices.authService?.brokerConnection.disconnect()
            mqttStartDebouncer.stop()
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        UserDefaults.standard.synchronize()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        // connectToFcm()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        runWhenInitialized {
            self.mqttStartDebouncer.call()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        runWhenInitialized {
            self.handleRemoteNotification(notification.request.content.userInfo)
        }
        // Change this to your preferred presentation option
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        runWhenInitialized {
            self.handleRemoteNotification(response.notification.request.content.userInfo)
        }
        completionHandler()
    }
}
// [END ios_10_message_handling]


// [START ios_10_data_message_handling]
extension AppDelegate : MessagingDelegate {
    //MARK: FCM Token Refreshed
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        APIRequests.updateCloudToken(cloudToken: fcmToken) { error in
            if let error = error {
                NSLog(error.localizedDescription)
            }
        }
    }
    
    // Receive data message on iOS 10 devices while app is in the foreground.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("remoteMessage: \(remoteMessage)")
    }
}
// [END ios_10_data_message_handling]

