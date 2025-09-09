import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        
        // UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification authorization
        let authOptions: UNAuthorizationOptions
        if #available(iOS 14.0, *) {
            authOptions = [.alert, .badge, .sound, .banner]
        } else {
            authOptions = [.alert, .badge, .sound]
        }
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions
        ) { granted, error in
            print("Permission granted: \(granted)")
        }
        
        application.registerForRemoteNotifications()
        
        GeneratedPluginRegistrant.register(with: self)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - FCM Token
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}

// UNUserNotificationCenterDelegate extension
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
