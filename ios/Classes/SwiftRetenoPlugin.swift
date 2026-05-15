import Flutter
import Reteno
import UIKit
import UserNotifications

#if canImport(FirebaseMessaging)
import FirebaseMessaging
typealias RetenoMessagingDelegate = MessagingDelegate
#else
protocol RetenoMessagingDelegate: AnyObject {}
#endif

public class SwiftRetenoPlugin: NSObject, FlutterPlugin, RetenoHostApi, UIApplicationDelegate, RetenoMessagingDelegate {
    static var _initialNotification : [String: Any]?
    private static var _flutterApi: RetenoFlutterApi?
    private static let retenoDidBecomeActiveNotification = Notification.Name(
        "com.reteno.didBecomeActive.after.delayed.initialization"
    )
    private typealias PendingFlutterEvent = (RetenoFlutterApi) -> Void
    private var didStart: Bool = false
    private var isFlutterReady: Bool = false
    private var isRetenoReady: Bool = false
    private var isApplicationActive: Bool = false
    private var currentDeviceTokenHandlingMode: NativeDeviceTokenHandlingMode = .automatic
    private var pendingDeviceToken: String?
    private var pendingFlutterEvents: [PendingFlutterEvent] = []

    private func processPushToken(_ token: String) {
        if isRetenoReady {
            Reteno.userNotificationService.processRemoteNotificationsToken(token)
        } else {
            pendingDeviceToken = token
        }
    }

    private func emitFlutterEvent(_ event: @escaping PendingFlutterEvent) {
        guard let flutterApi = SwiftRetenoPlugin._flutterApi else {
            return
        }

        guard isFlutterReady, isApplicationActive else {
            pendingFlutterEvents.append(event)
            return
        }

        DispatchQueue.main.async {
            event(flutterApi)
        }
    }

    private func flushPendingFlutterEvents() {
        guard isFlutterReady,
              isApplicationActive,
              let flutterApi = SwiftRetenoPlugin._flutterApi,
              !pendingFlutterEvents.isEmpty else {
            return
        }

        let events = pendingFlutterEvents
        pendingFlutterEvents.removeAll()
        DispatchQueue.main.async {
            events.forEach { $0(flutterApi) }
        }
    }

    private func flushPendingDeviceTokenIfNeeded() {
        guard isRetenoReady, let token = pendingDeviceToken else {
            return
        }

        pendingDeviceToken = nil
        Reteno.userNotificationService.processRemoteNotificationsToken(token)
    }

#if canImport(FirebaseMessaging)
    private func forwardFirebaseTokenIfAvailable() {
        Messaging.messaging().token { [weak self] token, _ in
            guard let token = token else { return }
            self?.processPushToken(token)
        }
    }
#endif

    private func toRetenoDeviceTokenHandlingMode(_ mode: NativeDeviceTokenHandlingMode) -> DeviceTokenHandlingMode {
        switch mode {
        case .automatic:
            return .automatic
        case .manual:
            return .manual
        }
    }

    private func toRetenoSessionConfiguration(_ options: NativeLifecycleTrackingOptions) -> RetenoSessionConfiguration {
        guard options.sessionEventsEnabled else { return .disabled }
        return RetenoSessionConfiguration(
            sessionDuration: RetenoSessionConfiguration.default.sessionDuration,
            isSessionStartReportingEnabled: true,
            isSessionEndReportingEnabled: true
        )
    }

    public static func register(with registrar: FlutterPluginRegistrar) {

        let messenger : FlutterBinaryMessenger = registrar.messenger()

        let instance = SwiftRetenoPlugin()

        RetenoHostApiSetup.setUp(binaryMessenger: messenger, api: instance)

        _flutterApi = RetenoFlutterApi(binaryMessenger: messenger)

        registrar.addApplicationDelegate(instance)

        NotificationCenter.default.addObserver(instance, selector: #selector(application_onDidFinishLaunchingNotification), name: UIApplication.didFinishLaunchingNotification, object: nil)
        NotificationCenter.default.addObserver(instance, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(instance, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(instance, selector: #selector(retenoDidBecomeActive), name: SwiftRetenoPlugin.retenoDidBecomeActiveNotification, object: nil)
        Reteno.delayedStart()
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

                instance.emitFlutterEvent { flutterApi in
                    flutterApi.onNotificationClicked(payload: convertedUserInfo) { _ in }
                }
            }
        }
        
        //
        
        Reteno.userNotificationService.notificationActionHandler = { userInfo, action in
            var convertedUserInfo = [String: Any?]()
            
            for (key, value) in userInfo {
                if let stringKey = key.base as? String {
                    convertedUserInfo[stringKey] = value
                } else {
                    fatalError("Key is not a String")
                }
            }
            
            instance.emitFlutterEvent { flutterApi in
                flutterApi.onNotificationActionHandler(action: action.toNativeUserNotificationAction()) {_ in }
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
                instance.emitFlutterEvent { flutterApi in
                    flutterApi.onNotificationReceived(payload: convertedUserInfo) {_ in}
                }
            }

            return presentationOptions
        }

        Reteno.addInAppStatusHandler { inAppMessageStatus in
           switch inAppMessageStatus {
               case .inAppShouldBeDisplayed:
               instance.emitFlutterEvent { flutterApi in
                   flutterApi.onInAppMessageStatusChanged(
                       status: NativeInAppMessageStatus.inAppShouldBeDisplayed,
                       action: nil,
                       error: nil
                   ){_ in}
               }

               case .inAppIsDisplayed:
               instance.emitFlutterEvent { flutterApi in
                   flutterApi.onInAppMessageStatusChanged(
                       status: NativeInAppMessageStatus.inAppIsDisplayed,
                       action: nil,
                       error: nil
                   ){_ in}
               }

               case .inAppShouldBeClosed(let action):
               instance.emitFlutterEvent { flutterApi in
                   flutterApi.onInAppMessageStatusChanged(
                       status: NativeInAppMessageStatus.inAppShouldBeClosed,
                       action: action.toNativeInAppMessageAction(),
                       error: nil
                   ){_ in}
               }

               case .inAppIsClosed(let action):
               instance.emitFlutterEvent { flutterApi in
                   flutterApi.onInAppMessageStatusChanged(
                       status: NativeInAppMessageStatus.inAppIsClosed,
                       action: action.toNativeInAppMessageAction(),
                       error: nil
                   ){_ in}
               }

               case .inAppReceivedError(let error):
               instance.emitFlutterEvent { flutterApi in
                   flutterApi.onInAppMessageStatusChanged(
                       status: NativeInAppMessageStatus.inAppReceivedError,
                       action: nil,
                       error: error
                   ){_ in}
               }
           }
       }
    }

    func initWith(
        accessKey: String,
        lifecycleTrackingOptions: NativeLifecycleTrackingOptions?,
        isPausedInAppMessages: Bool,
        useCustomDeviceIdProvider: Bool,
        customDeviceIdValue: String?,
        isDebug: Bool,
        deviceTokenHandlingMode: NativeDeviceTokenHandlingMode,
        defaultNotificationChannelConfig: NativeDefaultNotificationChannelConfig?
    ) throws {
        currentDeviceTokenHandlingMode = deviceTokenHandlingMode
        if !didStart {
            let trackingOptions = lifecycleTrackingOptions ?? NativeLifecycleTrackingOptions(
                appLifecycleEnabled: true,
                pushSubscriptionEnabled: true,
                sessionEventsEnabled: true
            )
            let configuration = RetenoConfiguration(
                isAutomaticAppLifecycleReportingEnabled: trackingOptions.appLifecycleEnabled,
                isApplicationForegroundLifecycleReportingEnabled: trackingOptions.appLifecycleEnabled,
                isAutomaticPushSubsriptionReportingEnabled: trackingOptions.pushSubscriptionEnabled,
                sessionConfiguration: toRetenoSessionConfiguration(trackingOptions),
                isPausedInAppMessages: isPausedInAppMessages,
                isDebugMode: isDebug,
                useCustomDeviceId: useCustomDeviceIdProvider,
                deviceTokenHandlingMode: toRetenoDeviceTokenHandlingMode(deviceTokenHandlingMode)
            )
            Reteno.delayedSetup(apiKey: accessKey, configuration: configuration)
            didStart = true
        }
        isFlutterReady = true

#if canImport(FirebaseMessaging)
        if currentDeviceTokenHandlingMode == .manual
            || Messaging.messaging().delegate == nil
            || Messaging.messaging().delegate === self {
            Messaging.messaging().delegate = self
        }
        forwardFirebaseTokenIfAvailable()
#endif
        if isRetenoReady {
            Reteno.pauseInAppMessages(isPaused: isPausedInAppMessages)
        }
        flushPendingFlutterEvents()
        flushPendingDeviceTokenIfNeeded()
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

    func diagnose(completion: @escaping (Result<[String], Error>) -> Void) {
        var issues = [String]()
        if !didStart {
            issues.append("SDK_NOT_INITIALIZED")
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .denied:
                issues.append("PUSH_PERMISSION_DENIED")
            case .notDetermined:
                issues.append("PUSH_PERMISSION_NOT_DETERMINED")
            default:
                break
            }

            DispatchQueue.main.async {
                let isEphemeralAuthorized: Bool
                if #available(iOS 14.0, *) {
                    isEphemeralAuthorized = settings.authorizationStatus == .ephemeral
                } else {
                    isEphemeralAuthorized = false
                }
                let authorized = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
                    || isEphemeralAuthorized

                if authorized && !UIApplication.shared.isRegisteredForRemoteNotifications {
                    issues.append("REMOTE_NOTIFICATIONS_NOT_REGISTERED")
                }
                completion(.success(issues))
            }
        }
    }

    func requestPushPermission(provisional: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        let options: UNAuthorizationOptions = {
            var options: UNAuthorizationOptions = [.alert, .badge, .sound]
            if provisional, #available(iOS 12.0, *) {
                options.insert(.provisional)
            }
            return options
        }()

        if currentDeviceTokenHandlingMode == .automatic {
            Reteno.userNotificationService.registerForRemoteNotifications(
                with: options,
                application: UIApplication.shared,
                userResponse: { granted in
#if canImport(FirebaseMessaging)
                    if granted {
                        self.forwardFirebaseTokenIfAvailable()
                    }
#endif
                    completion(.success(granted))
                }
            )
            return
        }

        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            let isAlreadyAuthorized: Bool
            if #available(iOS 14.0, *) {
                isAlreadyAuthorized = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
                    || settings.authorizationStatus == .ephemeral
            } else {
                isAlreadyAuthorized = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
            }

            if isAlreadyAuthorized {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
#if canImport(FirebaseMessaging)
                self.forwardFirebaseTokenIfAvailable()
#endif
                completion(.success(true))
                return
            }

            center.requestAuthorization(options: options) { granted, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
#if canImport(FirebaseMessaging)
                    self.forwardFirebaseTokenIfAvailable()
#endif
                }
                completion(.success(granted))
            }
        }
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
        categoryId: String?,
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
    
    func getRecommendationsJson(recomVariantId: String, productIds: [String], categoryId: String?, filters: [NativeRecomFilter]?, fields: [String]?, completion: @escaping (Result<[String : Any], any Error>) -> Void) {
        
        Reteno.recommendations().getRecomJSONs(
            recomVariantId: recomVariantId,
            productIds: productIds,
            categoryId: categoryId,
            filters: [],
            fields: fields
        ) { (result: Result<[[String : Any]], Error>)  in
            switch result {
            case .success(let recoms):
                let combinedResult: [String: Any] = ["recoms": recoms]
                completion(.success(combinedResult))
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

    @objc private func retenoDidBecomeActive() {
        isRetenoReady = true
        flushPendingDeviceTokenIfNeeded()
        flushPendingFlutterEvents()
    }

    @objc private func applicationDidBecomeActive() {
        isApplicationActive = true
        flushPendingFlutterEvents()
    }

    @objc private func applicationWillResignActive() {
        isApplicationActive = false
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
#if canImport(FirebaseMessaging)
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)
        forwardFirebaseTokenIfAvailable()
#endif
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        processPushToken(tokenString)
    }

#if canImport(FirebaseMessaging)
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        processPushToken(token)
    }
#endif

    func getAppInboxMessages(page: Int64?, pageSize: Int64?, completion: @escaping (Result<NativeAppInboxMessages, Error>) -> Void) {
        let pageInt = page.flatMap { Int($0) }
        let pageSizeInt = pageSize.flatMap { Int($0) }
        Reteno.inbox().downloadMessages(page: pageInt, pageSize: pageSizeInt) { result in
            switch result {
            case .success(let (messages, totalPages)):
                let nativeMessages = messages.map { $0.toNativeAppInboxMessage() }
                completion(.success(
                    NativeAppInboxMessages(
                        messages: nativeMessages,
                        totalPages: totalPages.map { Int64($0) } ?? 0
                    )
                ))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getAppInboxMessagesCount(completion: @escaping (Result<Int64, Error>) -> Void) {
        Reteno.inbox().getUnreadMessagesCount { result in
            switch result {
            case .success(let item):
                completion(.success(Int64(item)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func markAsOpened(messageId: String) throws {
        Reteno.inbox().markAsOpened(messageIds: [messageId])
    }

    func markAllMessagesAsOpened(completion: @escaping (Result<Void, Error>) -> Void) {
        Reteno.inbox().markAllAsOpened() { (result: Result<Void, Error>)  in
            switch result {
            case .success():
                break
            case .failure(_):
                break
            }
        }
    }

    func subscribeOnMessagesCountChanged() throws {
        Reteno.inbox().onUnreadMessagesCountChanged = { count in
            self.emitFlutterEvent { flutterApi in
                flutterApi.onMessagesCountChanged(count: Int64(count)) {_ in }
            }
        }
    }

    func unsubscribeAllMessagesCountChanged() throws {
        Reteno.inbox().onUnreadMessagesCountChanged = nil
    }
    
    func logEcommerceProductViewed(product: NativeEcommerceProduct, currency: String?) throws {
        Reteno.ecommerce().logEvent(
            type: .productViewed(
                product: Ecommerce.Product(
                    productId: product.productId,
                    price: Float(product.price),
                    isInStock: product.inStock,
                    attributes: product.attributes?.normalized()
                ),
                currencyCode: currency
            )
        )
    }
    
    func logEcommerceProductCategoryViewed(category: NativeEcommerceCategory) throws {
        Reteno.ecommerce().logEvent(
            type: .productCategoryViewed(
                category: Ecommerce.ProductCategory(
                    productCategoryId: category.productCategoryId,
                    attributes: category.attributes?.normalized()
                )
            )
        )
    }
    
    func logEcommerceProductAddedToWishlist(product: NativeEcommerceProduct, currency: String?) throws {
        Reteno.ecommerce().logEvent(
            type: .productAddedToWishlist(
                product: Ecommerce.Product(
                    productId: product.productId,
                    price: Float(product.price),
                    isInStock: product.inStock,
                    attributes: product.attributes?.normalized()),
                currencyCode: currency
            )
        )
    }
    
    func logEcommerceCartUpdated(cartId: String, products: [NativeEcommerceProductInCart], currency: String?) throws {
        Reteno.ecommerce().logEvent(
            type: .cartUpdated(
                cartId: cartId,
                products: products.map({ native in
                    Ecommerce.ProductInCart(
                        productId: native.productId,
                        price: Float(native.price),
                        quantity: Int(native.quantity)
                    )
                }),
                currencyCode: currency
            )
        )
    }
    
    func logEcommerceOrderCreated(order: NativeEcommerceOrder, currency: String?) throws {
        Reteno.ecommerce().logEvent(
            type: .orderCreated(
                order: order.toEcommerceOrder(),
                currencyCode: currency
            )
        )
    }
    
    func logEcommerceOrderUpdated(order: NativeEcommerceOrder, currency: String?) throws {
        Reteno.ecommerce().logEvent(
            type: .orderUpdated(
                order: order.toEcommerceOrder(),
                currencyCode: currency
            )
        )
    }
    
    func logEcommerceOrderDelivered(externalOrderId: String) throws {
        Reteno.ecommerce().logEvent(type: .orderDelivered(externalOrderId: externalOrderId))
    }
    
    func logEcommerceOrderCancelled(externalOrderId: String) throws {
        Reteno.ecommerce().logEvent(type: .orderCancelled(externalOrderId: externalOrderId))
    }
    
    func logEcommerceSearchRequest(query: String, isFound: Bool?) throws {
        Reteno.ecommerce().logEvent(type: .searchRequest(query: query, isFound: isFound))
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
            price: self.price != nil ? Double(self.price!) : nil,
            category: self.category,
            categoryAncestor: self.categoryAncestor,
            categoryLayout: self.categoryLayout,
            categoryParent: self.categoryParent,
            dateCreatedAs: self.dateCreatedAs,
            dateCreatedEs: self.dateCreatedEs,
            dateModifiedAs: self.dateModifiedAs,
            itemGroup: self.itemGroup,
            nameKeyword: self.nameKeyword,
            productIdAlt: self.productIdAlt,
            tagsAllCategoryNames: self.tagsAllCategoryNames,
            tagsBestseller: self.tagsBestseller,
            tagsCashback: self.tagsCashback,
            tagsCategoryBestseller: self.tagsCategoryBestseller,
            tagsCredit: self.tagsCredit,
            tagsDelivery: self.tagsDelivery,
            tagsDescriptionPriceRange: self.tagsDescriptionPriceRange,
            tagsDiscount: self.tagsDiscount,
            tagsHasPurchases21Days: self.tagsHasPurchases21Days,
            tagsIsBestseller: self.tagsIsBestseller,
            tagsIsBestsellerByCategories: self.tagsIsBestsellerByCategories,
            tagsItemGroupId: self.tagsItemGroupId,
            tagsNumPurchases21Days: self.tagsNumPurchases21Days,
            tagsOldPrice: self.tagsOldPrice,
            tagsOldprice: self.tagsOldprice,
            tagsPriceRange: self.tagsPriceRange,
            tagsRating: self.tagsRating,
            tagsSale: self.tagsSale,
            url: self.url?.absoluteString
        );
    }
}

extension AppInboxMessage {
    func toNativeAppInboxMessage() -> NativeAppInboxMessage {
        let dateFormatter = ISO8601DateFormatter();
        return NativeAppInboxMessage(
            id: self.id,
            title: self.title,
            createdDate: self.createdDate.map { dateFormatter.string(from: $0) } ?? "",
            isNewMessage: self.isNew,
            content: self.content,
            imageUrl: self.imageURL?.absoluteString,
            linkUrl: self.linkURL?.absoluteString,
            category: self.category,
            customData: self.customData
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

extension RetenoUserNotificationAction {
    func toNativeUserNotificationAction() -> NativeUserNotificationAction {
        return NativeUserNotificationAction(
            actionId: self.actionId,
            customData: self.customData,
            link: self.link?.absoluteString
        )
    }
}

extension Dictionary where Key == Optional<String>, Value == Optional<[String]> {
    func normalized() -> [String: [String]]? {
        let result = self.compactMap { key, value -> (String, [String])? in
            if let key = key, let value = value {
                return (key, value)
            }
            return nil
        }.reduce(into: [String: [String]]()) { result, pair in
            result[pair.0] = pair.1
        }
        return result.isEmpty ? nil : result
    }
}

extension NativeEcommerceOrder {
    
    func toEcommerceOrder() -> Ecommerce.Order {
        let dateFormatter = ISO8601DateFormatter();

         let orderStatus = Ecommerce.Order.Status(rawValue: self.status)!
        
        var convertedItems: [Ecommerce.Order.Item]? = nil
        if let nativeItems = self.items {
            convertedItems = []
            for nativeItem in nativeItems {
                if let item = nativeItem?.toEcommerceItem() {
                    convertedItems?.append(item)
                }
            }
            if convertedItems?.isEmpty == true {
                convertedItems = nil
            }
        }
        
        var convertedAttributes: [String: [String: Any]]? = nil
        if let nativeAttributes = self.attributes {
            convertedAttributes = [:]
            for (key, value) in nativeAttributes {
                if let unwrappedKey = key, let unwrappedValue = value {
                    let attributeDict: [String: Any] = ["values": unwrappedValue]
                    convertedAttributes?[unwrappedKey] = attributeDict
                }
            }
            if convertedAttributes?.isEmpty == true {
                convertedAttributes = nil
            }
        }
        
        return Ecommerce.Order(
            externalOrderId: self.externalOrderId,
            totalCost: Float(self.totalCost),
            status: orderStatus,
            date: dateFormatter.date(from: date) ?? Date(),
            cartId: self.cartId,
            email: self.email,
            phone: self.phone,
            firstName: self.firstName,
            lastName: self.lastName,
            shipping: self.shipping.map { Float($0) },
            discount: self.discount.map { Float($0) },
            taxes: self.taxes.map { Float($0) },
            restoreUrl: self.restoreUrl,
            statusDescription: self.statusDescription,
            storeId: self.storeId,
            source: self.source,
            deliveryMethod: self.deliveryMethod,
            paymentMethod: self.paymentMethod,
            deliveryAddress: self.deliveryAddress,
            items: convertedItems,
            attributes: convertedAttributes
        )
    }
}

extension NativeEcommerceItem {
    
    func toEcommerceItem() -> Ecommerce.Order.Item? {
        return Ecommerce.Order.Item(
            externalItemId: self.externalItemId,
            name: self.name,
            category: self.category,
            quantity: self.quantity,
            cost: Float(self.cost),
            url: self.url,
            imageUrl: self.imageUrl,
            description: self.description
        )
    }
}
