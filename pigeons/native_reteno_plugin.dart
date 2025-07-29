import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/native_reteno_plugin.g.dart',
    swiftOut: 'ios/Classes/pigeons/RetenoNativePlugin.swift',
    kotlinOptions: KotlinOptions(
      package: 'com.reteno.reteno_plugin',
    ),
    kotlinOut: 'android/src/main/kotlin/com/reteno/reteno_plugin/RetenoHostApi.kt',
  ),
)
@HostApi()
abstract class RetenoHostApi {
  void initWith({
    required String accessKey,
    NativeLifecycleTrackingOptions? lifecycleTrackingOptions,
    bool isPausedInAppMessages = false,
    bool useCustomDeviceIdProvider = false,
    bool isDebug = false,
  });
  void setUserAttributes(String externalUserId, NativeRetenoUser? user);
  void setAnonymousUserAttributes(NativeAnonymousUserAttributes anonymousUserAttributes);
  void logEvent(NativeCustomEvent event);
  void updatePushPermissionStatus();
  void pauseInAppMessages(bool isPaused);
  Map<String, Object>? getInitialNotification();
  @async
  List<NativeRecommendation> getRecommendations({
    required String recomVariantId,
    required List<String> productIds,
    String? categoryId,
    List<NativeRecomFilter>? filters,
    List<String>? fields,
  });
  void logRecommendationsEvent(NativeRecomEvents events);
  @async
  NativeAppInboxMessages getAppInboxMessages({int? page, int? pageSize});
  @async
  int getAppInboxMessagesCount();
  void markAsOpened(String messageId);
  @async
  void markAllMessagesAsOpened();
  void subscribeOnMessagesCountChanged();
  void unsubscribeAllMessagesCountChanged();
  // Ecommerce
  void logEcommerceProductViewed(NativeEcommerceProduct product, String? currency);
  void logEcommerceProductCategoryViewed(NativeEcommerceCategory category);
  void logEcommerceProductAddedToWishlist(NativeEcommerceProduct product, String? currency);
  void logEcommerceCartUpdated(String cartId, List<NativeEcommerceProductInCart> products, String? currency);
  void logEcommerceOrderCreated(NativeEcommerceOrder order, String? currency);
  void logEcommerceOrderUpdated(NativeEcommerceOrder order, String? currency);
  void logEcommerceOrderDelivered(String externalOrderId);
  void logEcommerceOrderCancelled(String externalOrderId);
  void logEcommerceSearchRequest(String query, bool? isFound);
}

@FlutterApi()
abstract class RetenoFlutterApi {
  void onNotificationReceived(Map<String, Object?> payload);
  void onNotificationClicked(Map<String, Object?> payload);
  void onNotificationActionHandler(NativeUserNotificationAction action);

  void onInAppMessageStatusChanged(
    NativeInAppMessageStatus status,
    NativeInAppMessageAction? action,
    String? error,
  );
  void onMessagesCountChanged(int count);
  @async
  String? getDeviceId();
}

class NativeRetenoUser {
  NativeRetenoUser({
    this.subscriptionKeys,
    this.userAttributes,
    this.groupNamesExclude,
    this.groupNamesInclude,
  });

  final NativeUserAttributes? userAttributes;
  final List<String?>? subscriptionKeys;
  final List<String?>? groupNamesInclude;
  final List<String?>? groupNamesExclude;
}

class NativeUserAttributes {
  NativeUserAttributes({
    this.lastName,
    this.firstName,
    this.address,
    this.email,
    this.fields,
    this.languageCode,
    this.phone,
    this.timeZone,
  });
  final String? phone;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? languageCode;
  final String? timeZone;
  final NativeAddress? address;
  final List<NativeUserCustomField?>? fields;
}

class NativeAddress {
  NativeAddress({
    this.address,
    this.postcode,
    this.region,
    this.town,
  });
  final String? region;
  final String? town;
  final String? address;
  final String? postcode;
}

class NativeUserCustomField {
  NativeUserCustomField({
    required this.key,
    this.value,
  });
  final String key;
  final String? value;
}

class NativeAnonymousUserAttributes {
  NativeAnonymousUserAttributes({
    this.lastName,
    this.firstName,
    this.address,
    this.fields,
    this.languageCode,
    this.timeZone,
  });
  final String? firstName;
  final String? lastName;
  final String? languageCode;
  final String? timeZone;
  final NativeAddress? address;
  final List<NativeUserCustomField?>? fields;
}

class NativeCustomEvent {
  NativeCustomEvent({
    required this.eventTypeKey,
    required this.dateOccurred,
    this.forcePush = false,
    required this.parameters,
  });

  final String eventTypeKey;
  final String dateOccurred;
  final List<NativeCustomEventParameter?> parameters;
  final bool forcePush;
}

class NativeCustomEventParameter {
  NativeCustomEventParameter(this.name, this.value);

  final String name;
  final String? value;
}

enum NativeInAppMessageStatus {
  inAppShouldBeDisplayed,
  inAppIsDisplayed,
  inAppShouldBeClosed,
  inAppIsClosed,
  inAppReceivedError
}

class NativeInAppMessageAction {
  NativeInAppMessageAction({
    required this.isCloseButtonClicked,
    required this.isButtonClicked,
    required this.isOpenUrlClicked,
  });

  final bool isCloseButtonClicked;
  final bool isButtonClicked;
  final bool isOpenUrlClicked;
}

class NativeRecomFilter {
  const NativeRecomFilter({required this.name, required this.values});
  final String name;
  final List<String?> values;
}

class NativeRecommendation {
  const NativeRecommendation({
    required this.productId,
    this.name,
    this.price,
    this.description,
    this.imageUrl,
    this.category,
    this.categoryAncestor,
    this.categoryLayout,
    this.categoryParent,
    this.dateCreatedAs,
    this.dateCreatedEs,
    this.dateModifiedAs,
    this.itemGroup,
    this.nameKeyword,
    this.productIdAlt, // Alternative product_id field
    this.tagsAllCategoryNames,
    this.tagsBestseller,
    this.tagsCashback,
    this.tagsCategoryBestseller,
    this.tagsCredit,
    this.tagsDelivery,
    this.tagsDescriptionPriceRange,
    this.tagsDiscount,
    this.tagsHasPurchases21Days,
    this.tagsIsBestseller,
    this.tagsIsBestsellerByCategories,
    this.tagsItemGroupId,
    this.tagsNumPurchases21Days,
    this.tagsOldPrice,
    this.tagsOldprice,
    this.tagsPriceRange,
    this.tagsRating,
    this.tagsSale,
    this.url,
  });
  final String productId;
  final String? name;
  final String? description;
  final String? imageUrl;
  final double? price;
  final List<String>? category;
  final List<String>? categoryAncestor;
  final List<String>? categoryLayout;
  final List<String>? categoryParent;
  final String? dateCreatedAs;
  final String? dateCreatedEs;
  final String? dateModifiedAs;
  final String? itemGroup;
  final String? nameKeyword;
  final String? productIdAlt; // Alternative product_id field
  final String? tagsAllCategoryNames;
  final String? tagsBestseller;
  final String? tagsCashback;
  final String? tagsCategoryBestseller;
  final String? tagsCredit;
  final String? tagsDelivery;
  final String? tagsDescriptionPriceRange;
  final String? tagsDiscount;
  final String? tagsHasPurchases21Days;
  final String? tagsIsBestseller;
  final String? tagsIsBestsellerByCategories;
  final String? tagsItemGroupId;
  final String? tagsNumPurchases21Days;
  final String? tagsOldPrice;
  final String? tagsOldprice;
  final String? tagsPriceRange;
  final String? tagsRating;
  final String? tagsSale;
  final String? url;
}

enum NativeRecomEventType {
  impression,
  click,
}

class NativeRecomEvent {
  NativeRecomEvent({
    required this.eventType,
    required this.dateOccurred,
    required this.productId,
  });

  final NativeRecomEventType eventType;
  final String dateOccurred;
  final String productId;
}

class NativeRecomEvents {
  NativeRecomEvents({
    required this.recomVariantId,
    required this.events,
  });

  final String recomVariantId;
  final List<NativeRecomEvent?> events;
}

class NativeLifecycleTrackingOptions {
  NativeLifecycleTrackingOptions({
    required this.appLifecycleEnabled,
    required this.pushSubscriptionEnabled,
    required this.sessionEventsEnabled,
  });

  final bool appLifecycleEnabled;
  final bool pushSubscriptionEnabled;
  final bool sessionEventsEnabled;
}

class NativeAppInboxMessages {
  NativeAppInboxMessages({
    required this.messages,
    required this.totalPages,
  });
  final List<NativeAppInboxMessage?> messages;
  final int totalPages;
}

class NativeAppInboxMessage {
  NativeAppInboxMessage({
    required this.id,
    required this.title,
    required this.createdDate,
    required this.isNewMessage,
    this.content,
    this.imageUrl,
    this.linkUrl,
    this.category,
    this.customData,
  });

  final String id;
  final String title;
  final String createdDate;
  final bool isNewMessage;
  final String? content;
  final String? imageUrl;
  final String? linkUrl;
  final String? category;
  final Map<String?, Object?>? customData;
}

class NativeUserNotificationAction {
  NativeUserNotificationAction({
    this.actionId,
    this.customData,
    this.link,
  });

  final String? actionId;
  final Map<String?, Object?>? customData;
  final String? link;
}

class NativeEcommerceProduct {
  NativeEcommerceProduct({
    required this.productId,
    required this.price,
    required this.inStock,
    this.attributes,
  });

  final String productId;
  final double price;
  final bool inStock;
  final Map<String?, List<String>?>? attributes;
}

class NativeEcommerceCategory {
  NativeEcommerceCategory({
    required this.productCategoryId,
    this.attributes,
  });

  final String productCategoryId;
  final Map<String?, List<String>?>? attributes;
}

class NativeEcommerceProductInCart {
  NativeEcommerceProductInCart({
    required this.productId,
    required this.price,
    required this.quantity,
    this.discount,
    this.name,
    this.category,
    this.attributes,
  });

  final String productId;
  final double price;
  final int quantity;
  final double? discount;
  final String? name;
  final String? category;
  final Map<String?, List<String>?>? attributes;
}

class NativeEcommerceItem {
  NativeEcommerceItem({
    required this.externalItemId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.cost,
    required this.url,
    this.imageUrl,
    this.description,
  });

  final String externalItemId;
  final String name;
  final String category;
  final double quantity;
  final double cost;
  final String url;
  final String? imageUrl;
  final String? description;
}

class NativeEcommerceOrder {
  NativeEcommerceOrder({
    required this.externalOrderId,
    required this.totalCost,
    required this.status,
    required this.date,
    this.cartId,
    this.email,
    this.phone,
    this.firstName,
    this.lastName,
    this.shipping,
    this.discount,
    this.taxes,
    this.restoreUrl,
    this.statusDescription,
    this.storeId,
    this.source,
    this.deliveryMethod,
    this.paymentMethod,
    this.deliveryAddress,
    this.items,
    this.attributes,
  });

  final String externalOrderId;
  final double totalCost;
  final String status;
  final String date;
  final String? cartId;
  final String? email;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final double? shipping;
  final double? discount;
  final double? taxes;
  final String? restoreUrl;
  final String? statusDescription;
  final String? storeId;
  final String? source;
  final String? deliveryMethod;
  final String? paymentMethod;
  final String? deliveryAddress;
  final List<NativeEcommerceItem?>? items;
  final Map<String?, List<String>?>? attributes;
}
