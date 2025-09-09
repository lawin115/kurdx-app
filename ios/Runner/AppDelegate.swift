import UIKit
import Flutter
import Firebase // ← Import Firebase
import FirebaseMessaging // ← بۆ FCM

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 1️⃣ Firebase configure
    FirebaseApp.configure()
    
    // 2️⃣ Register plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // 3️⃣ FCM setup
    if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                print("Push permission granted: \(granted)")
            }
        )
    } else {
        let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    Messaging.messaging().delegate = self
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 4️⃣ FCM token refresh
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("FCM token: \(String(describing: fcmToken))")
      // دەتوانیت token بفرستی backend
  }
  
  // 5️⃣ Handle foreground notifications (optional)
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      completionHandler([.alert, .badge, .sound])
  }
}
