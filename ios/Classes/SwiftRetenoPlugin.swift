import Flutter
import Reteno
import UIKit

public class SwiftRetenoPlugin: NSObject, FlutterPlugin {
    
    static var _initialNotification : [String: Any]?
    var _flutterResult : FlutterResult?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        let channel = FlutterMethodChannel(name: "reteno_plugin", binaryMessenger: registrar.messenger())
        let instance = SwiftRetenoPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        NotificationCenter.default.addObserver(instance, selector: #selector(application_onDidFinishLaunchingNotification), name: UIApplication.didFinishLaunchingNotification, object: nil)
        Reteno.userNotificationService.didReceiveNotificationResponseHandler = { response in
            let remoteNotification = response.notification.request.content.userInfo
            let openId = remoteNotification["gcm.message_id"]
            if(openId != nil && (openId as! String) != _initialNotification?["gcm.message_id"] as? String){
                channel.invokeMethod("onRetenoNotificationClicked", arguments: remoteNotification)
            }
        }
        Reteno.userNotificationService.willPresentNotificationHandler = { notification in
            let userInfo = notification.request.content.userInfo
            channel.invokeMethod("onRetenoNotificationReceived", arguments: userInfo)
            let presentationOptions: UNNotificationPresentationOptions
            if #available(iOS 14.0, *) {
                presentationOptions = [.badge, .sound, .banner]
            } else {
                presentationOptions = [.badge, .sound, .alert]
            }
            return presentationOptions
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method == "setUserAttributes"){
            let args = call.arguments as! NSDictionary
            let userId = args["externalUserId"] as? String
            let userInfo = args["user_info"] as? [String: Any]
            let userAttributes = userInfo?["userAttributes"] as? NSDictionary
            let address = userAttributes?["address"] as? NSDictionary
            Reteno.updateUserAttributes(externalUserId: userId,
                                        userAttributes: userAttributes == nil ? nil : UserAttributes(
                                            phone: getStringOrNil(input: userAttributes?["phone"] as? String),
                                            email: getStringOrNil(input: userAttributes?["email"] as? String),
                                            firstName: getStringOrNil(input: userAttributes?["firstName"] as? String),
                                            lastName: getStringOrNil(input: userAttributes?["lastName"] as? String),
                                            languageCode: getStringOrNil(input: userAttributes?["languageCode"] as? String),
                                            timeZone: getStringOrNil(input: userAttributes?["timeZone"] as? String),
                                            address: address == nil ? nil : Address(region: address!["region"] as? String,
                                                                                    town: address!["town"] as? String,
                                                                                    address: address!["address"] as? String,
                                                                                    postcode: address!["postcode"] as? String
                                                                                   ),
                                            fields: (userAttributes?["fields"] as? [[String: String]])?.map({ customField in
                                                UserCustomField(key: customField["key"] ?? "",
                                                                value: customField["value"] ?? "")
                                            }) ?? []
                                        ),
                                        subscriptionKeys: userInfo?["subscriptionKeys"] as? [String] ?? [],
                                        groupNamesInclude: userInfo?["groupNamesInclude"] as? [String] ?? [],
                                        groupNamesExclude: userInfo?["groupNamesExclude"] as? [String] ?? [])
            result(true)
            
        }
        else if(call.method == "setAnonymousUserAttributes"){
            let args = call.arguments as! NSDictionary
            let anonymousUserAttributes = args["anonymousUserAttributes"] as? NSDictionary
            let address = anonymousUserAttributes?["address"] as? NSDictionary
            Reteno.updateAnonymousUserAttributes(userAttributes: AnonymousUserAttributes(
                firstName: getStringOrNil(input: anonymousUserAttributes?["firstName"] as? String),
                lastName: getStringOrNil(input: anonymousUserAttributes?["lastName"] as? String),
                languageCode: getStringOrNil(input: anonymousUserAttributes?["languageCode"] as? String),
                timeZone: getStringOrNil(input: anonymousUserAttributes?["timeZone"] as? String),
                address: address == nil ? nil : Address(region: address!["region"] as? String,
                                                        town: address!["town"] as? String,
                                                        address: address!["address"] as? String,
                                                        postcode: address!["postcode"] as? String
                                                       ),
                fields: (anonymousUserAttributes?["fields"] as? [[String: String]])?.map({ customField in
                    UserCustomField(key: customField["key"] ?? "",
                                    value: customField["value"] ?? "")
                }) ?? []
            ))
            result(true)
        }
        else if(call.method == "logEvent"){
            let args = call.arguments as! NSDictionary
            let eventDictionary = args["event"] as? NSDictionary
            if(eventDictionary == nil){
                result(false)
            }else{
                do {
                    let requestPayload = try RetenoEvent.buildEventPayload(payload: eventDictionary!);
                    Reteno.logEvent(
                        eventTypeKey: requestPayload.eventName,
                        date: requestPayload.date,
                        parameters: requestPayload.parameters,
                        forcePush: requestPayload.forcePush
                    );
                    result(true);
                } catch {
                    result(FlutterError(code:"100", message:"Reteno iOS SDK Error",details: error))
                }
                
                result(true)
            }
        }
        else if(call.method == "getInitialNotification"){
            _flutterResult = result
            updateInitialResult()
        }
    }
    
    private func updateInitialResult() -> Void {
        if(_flutterResult != nil && SwiftRetenoPlugin._initialNotification != nil){
            _flutterResult?(SwiftRetenoPlugin._initialNotification)
            SwiftRetenoPlugin._initialNotification = nil
        }
        else{
            _flutterResult?(nil)
            _flutterResult = nil
        }
    }
    
    private func getStringOrNil(input: String?) -> String? {
        return input?.isEmpty == true ? nil : input
    }
    
    @objc func application_onDidFinishLaunchingNotification(notification: NSNotification){
        if let remoteNotification = notification.userInfo?[UIApplication.LaunchOptionsKey.remoteNotification] as? NSDictionary {
            SwiftRetenoPlugin._initialNotification = remoteNotification as? [String: Any]
        }
    }
}
