import UIKit
import Flutter
import Reteno
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        //FirebaseApp.configure()
        Messaging.messaging().delegate = self
        Reteno.start(apiKey: "630A66AF-C1D3-4F2A-ACC1-0D51C38D2B05")
        
        Reteno.userNotificationService.registerForRemoteNotifications(with: [.sound, .alert, .badge], application: application)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        Reteno.userNotificationService.processRemoteNotificationsToken(fcmToken)
    }
}
