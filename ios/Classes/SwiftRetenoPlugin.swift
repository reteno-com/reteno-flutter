import Flutter
import Reteno
import UIKit

public class SwiftRetenoPlugin: NSObject, FlutterPlugin, RetenoHostApi {

    static var _initialNotification : [String: Any]?

    public static func register(with registrar: FlutterPluginRegistrar) {

        let messenger : FlutterBinaryMessenger = registrar.messenger()

        let instance = SwiftRetenoPlugin()

        let api : RetenoHostApi & NSObjectProtocol = SwiftRetenoPlugin.init()

        RetenoHostApiSetup.setUp(binaryMessenger: messenger, api: api)

        let _flutterApi = RetenoFlutterApi(binaryMessenger: messenger)

        NotificationCenter.default.addObserver(instance, selector: #selector(application_onDidFinishLaunchingNotification), name: UIApplication.didFinishLaunchingNotification, object: nil)
        Reteno.userNotificationService.didReceiveNotificationResponseHandler = { response in
            let userInfo = response.notification.request.content.userInfo
            if userInfo.keys.contains("es_interaction_id") == false{
                return
            }
            let openId = userInfo["es_interaction_id"]
            if(openId != nil && (openId as! String) != _initialNotification?["es_interaction_id"] as? String){
                var convertedUserInfo = [String: Any?]()

                for (key, value) in userInfo {
                    if let stringKey = key.base as? String {
                        convertedUserInfo[stringKey] = value
                    } else {
                        fatalError("Key is not a String")
                    }
                }

                _flutterApi.onNotificationClicked(payload: convertedUserInfo) { _ in }
            }
        }
        //TODO: change to didReceiveNotificationUserInfo
        Reteno.userNotificationService.willPresentNotificationHandler = { notification in
            let presentationOptions: UNNotificationPresentationOptions
            if #available(iOS 14.0, *) {
                presentationOptions = [.badge, .sound, .banner]
            } else {
                presentationOptions = [.badge, .sound, .alert]
            }
            let userInfo = notification.request.content.userInfo
            if userInfo.keys.contains("es_interaction_id") {
                var convertedUserInfo = [String: Any?]()

                for (key, value) in userInfo {
                    if let stringKey = key.base as? String {
                        convertedUserInfo[stringKey] = value
                    } else {
                        fatalError("Key is not a String")
                    }
                }
                _flutterApi.onNotificationReceived(payload: convertedUserInfo) {_ in}
            }

            return presentationOptions
        }

        Reteno.addInAppStatusHandler { inAppMessageStatus in
           switch inAppMessageStatus {
               case .inAppShouldBeDisplayed:
                   _flutterApi.onInAppMessageStatusChanged(
                        status: NativeInAppMessageStatus.inAppShouldBeDisplayed,
                        action: nil,
                        error: nil
                   ){_ in}

               case .inAppIsDisplayed:
                   _flutterApi.onInAppMessageStatusChanged(
                        status: NativeInAppMessageStatus.inAppIsDisplayed,
                        action: nil,
                        error: nil
                   ){_ in}

               case .inAppShouldBeClosed(let action):
                   _flutterApi.onInAppMessageStatusChanged(
                        status: NativeInAppMessageStatus.inAppShouldBeClosed,
                        action: action.toNativeInAppMessageAction(),
                        error: nil
                   ){_ in}

               case .inAppIsClosed(let action):
                   _flutterApi.onInAppMessageStatusChanged(
                        status: NativeInAppMessageStatus.inAppIsClosed,
                        action: action.toNativeInAppMessageAction(),
                        error: nil
                   ){_ in}

               case .inAppReceivedError(let error):
                   _flutterApi.onInAppMessageStatusChanged(
                        status: NativeInAppMessageStatus.inAppReceivedError,
                        action: nil,
                        error: error
                   ){_ in}
           }
       }
    }

    func setUserAttributes(externalUserId: String, user: NativeRetenoUser?) throws {
        Reteno.updateUserAttributes(
            externalUserId: externalUserId,
            userAttributes: user == nil ? nil : UserAttributes(
                phone: user?.userAttributes?.phone,
                email: user?.userAttributes?.email,
                firstName: user?.userAttributes?.firstName,
                lastName: user?.userAttributes?.lastName,
                languageCode: user?.userAttributes?.languageCode,
                timeZone: user?.userAttributes?.timeZone,
                address: user?.userAttributes?.address?.convertToAddress(),
                fields: user?.userAttributes?.fields?.compactMap({ nativeField in
                    UserCustomField(key: nativeField?.key ?? "", value: nativeField?.value ?? "")
                }) ?? []
            ),
            subscriptionKeys: user?.subscriptionKeys?.compactMap { $0 } ?? [],
            groupNamesInclude: user?.groupNamesInclude?.compactMap{ $0 } ?? [],
            groupNamesExclude: user?.groupNamesExclude?.compactMap{ $0 } ?? []
        )
    }

    func setAnonymousUserAttributes(anonymousUserAttributes: NativeAnonymousUserAttributes) throws {
        Reteno.updateAnonymousUserAttributes(
            userAttributes: AnonymousUserAttributes(
                firstName: anonymousUserAttributes.firstName,
                lastName: anonymousUserAttributes.lastName,
                languageCode: anonymousUserAttributes.languageCode,
                timeZone: anonymousUserAttributes.timeZone,
                address: anonymousUserAttributes.address?.convertToAddress(),
                fields: anonymousUserAttributes.fields?.compactMap({ nativeField in
                    UserCustomField(key: nativeField?.key ?? "", value: nativeField?.value ?? "")
                }) ?? []
            )
        )
    }

    func logEvent(event: NativeCustomEvent) throws {
        let dateFormatter = ISO8601DateFormatter();

        Reteno.logEvent(
            eventTypeKey: event.eventTypeKey,
            date: dateFormatter.date(from: event.dateOccurred) ?? Date(),
            parameters: event.parameters.map({ p in
                Event.Parameter(name: p!.name, value: p?.value ?? "")
            }),
            forcePush: event.forcePush
        )
    }

    func updatePushPermissionStatus() throws {

    }

    func getInitialNotification() throws -> [String : Any]? {
        if(SwiftRetenoPlugin._initialNotification != nil){
            let notification = SwiftRetenoPlugin._initialNotification
            SwiftRetenoPlugin._initialNotification = nil
            return notification
        }
        return nil
    }

    func pauseInAppMessages(isPaused: Bool) throws {
        Reteno.pauseInAppMessages(isPaused: isPaused)
    }

    func getRecommendations(
        recomVariantId: String,
        productIds: [String],
        categoryId: String,
        filters: [NativeRecomFilter]?,
        fields: [String]?,
        completion: @escaping (Result<[NativeRecommendation], Error>
    ) -> Void) {
       Reteno.recommendations().getRecoms(
           recomVariantId: recomVariantId,
           productIds: productIds,
           categoryId: categoryId,
           filters: [],
           fields: fields
       ) { (result: Result<[Recommendation], Error>)  in
           switch result {
           case .success(let recoms):
               let nativeRecoms = recoms.map { $0.toNativeRecomendation() }
               completion(.success(nativeRecoms))
               break
           case .failure(let error):
               completion(.failure(error))
               break
           }
       }
    }

    func logRecommendationsEvent(events: NativeRecomEvents) throws {
        let recomEventContainer = events.toRecomEventContainer()
        
        Reteno.recommendations().logEvent(
            recomVariantId: recomEventContainer.recomVariantId,
            impressions: recomEventContainer.impressions,
            clicks: recomEventContainer.clicks
        );
    }

    @objc func application_onDidFinishLaunchingNotification(notification: NSNotification){
        guard let userInfo = notification.userInfo else {
          return
        }
        if userInfo.keys.contains("es_interaction_id") {
            return
        }
        if let remoteNotification = userInfo[UIApplication.LaunchOptionsKey.remoteNotification] as? NSDictionary {
            SwiftRetenoPlugin._initialNotification = remoteNotification as? [String: Any]
        }
    }
}

extension FlutterError: Swift.Error {}

extension NativeAddress {
    func convertToAddress() -> Address {
        return Address(
            region: self.region,
            town: self.town,
            address: self.address,
            postcode: self.postcode
        )
    }
}

extension InAppMessageAction {
    func toNativeInAppMessageAction() -> NativeInAppMessageAction {
        return NativeInAppMessageAction(
            isCloseButtonClicked: self.isCloseButtonClicked,
            isButtonClicked: self.isButtonClicked,
            isOpenUrlClicked: self.isOpenUrlClicked
        );
    }
}

extension Recommendation {
    func toNativeRecomendation() -> NativeRecommendation {
        return NativeRecommendation(
            productId: self.productId,
            name: self.name,
            description: self.description,
            imageUrl: self.imageUrl?.absoluteString,
            price: self.price != nil ? Double(self.price!) : nil
        );
    }
}

extension NativeRecomEvents {
    func toRecomEventContainer() -> RecomEventContainer {
        let dateFormatter = ISO8601DateFormatter();
        let impressions = self.events.compactMap { $0.flatMap { $0.eventType == .impression ? RecomEvent(date: dateFormatter.date(from: $0.dateOccurred) ?? Date(), productId: $0.productId) : nil } }
        let clicks = self.events.compactMap { $0.flatMap { $0.eventType == .click ? RecomEvent(date: dateFormatter.date(from: $0.dateOccurred) ?? Date(), productId: $0.productId) : nil } }
        return RecomEventContainer(recomVariantId: self.recomVariantId, impressions: impressions, clicks: clicks)
    }
}
