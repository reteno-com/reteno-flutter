import UIKit
import Flutter
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        registerNotificationExtensionCategories()
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func registerNotificationExtensionCategories() {
        let categories: Set<UNNotificationCategory> = [
            UNNotificationCategory(identifier: "ImageCarousel", actions: [], intentIdentifiers: []),
            UNNotificationCategory(identifier: "ImageGif", actions: [], intentIdentifiers: []),
        ]
        UNUserNotificationCenter.current().setNotificationCategories(categories)
    }
}
