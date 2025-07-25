import 'package:reteno_plugin/src/models/anonymous_user_attributes.dart';
import 'package:reteno_plugin/src/models/app_inbox_messages.dart';
import 'package:reteno_plugin/src/models/in_app_message_status.dart';
import 'package:reteno_plugin/src/models/lifecycle_tracking_options.dart';
import 'package:reteno_plugin/src/models/reteno_custom_event.dart';
import 'package:reteno_plugin/src/models/reteno_custom_event_parameter.dart';
import 'package:reteno_plugin/src/models/reteno_ecommerce_event.dart';
import 'package:reteno_plugin/src/models/reteno_recommendation.dart';
import 'package:reteno_plugin/src/models/reteno_recommendation_event.dart';
import 'package:reteno_plugin/src/models/reteno_user.dart';
import 'package:reteno_plugin/src/models/reteno_user_notification_action.dart';
import 'package:reteno_plugin/src/native_reteno_plugin.g.dart';

extension RetenoUserExt on RetenoUser {
  NativeRetenoUser toNativeRetenoUser() {
    return NativeRetenoUser(
      subscriptionKeys: subscriptionKeys,
      userAttributes: userAttributes?.toNativeUserAttributes(),
      groupNamesExclude: groupNamesExclude,
      groupNamesInclude: groupNamesInclude,
    );
  }
}

extension UserAttributesExt on UserAttributes {
  NativeUserAttributes toNativeUserAttributes() {
    return NativeUserAttributes(
      phone: phone,
      email: email,
      firstName: firstName,
      lastName: lastName,
      languageCode: languageCode,
      timeZone: timeZone,
      address: address?.toNativeAddress(),
      fields: fields?.map((e) => e.toNativeUserCustomField()).toList(),
    );
  }
}

extension AnonymousUserAttributesExt on AnonymousUserAttributes {
  NativeAnonymousUserAttributes toNativeAnonymousUserAttributes() {
    return NativeAnonymousUserAttributes(
      firstName: firstName,
      lastName: lastName,
      languageCode: languageCode,
      timeZone: timeZone,
      address: address?.toNativeAddress(),
      fields: fields?.map((e) => e.toNativeUserCustomField()).toList(),
    );
  }
}

extension AddressExt on Address {
  NativeAddress toNativeAddress() {
    return NativeAddress(
      address: address,
      postcode: postcode,
      region: region,
      town: town,
    );
  }
}

extension UserCustomFieldExt on UserCustomField {
  NativeUserCustomField toNativeUserCustomField() {
    return NativeUserCustomField(
      key: key,
      value: value,
    );
  }
}

extension RetenoCustomEventExt on RetenoCustomEvent {
  NativeCustomEvent toCustomEvent() {
    return NativeCustomEvent(
      eventTypeKey: eventTypeKey,
      dateOccurred: dateOccurred.toUtc().toIso8601String(),
      forcePush: forcePush,
      parameters: parameters.map((e) => e.toCustomEventParameter()).toList(),
    );
  }
}

extension RetenoCustomEventParameterExt on RetenoCustomEventParameter {
  NativeCustomEventParameter toCustomEventParameter() {
    return NativeCustomEventParameter(
      name: name,
      value: value,
    );
  }
}

extension NativeInAppMessageStatusExt on NativeInAppMessageStatus {
  InAppMessageStatus toInAppMessageStatus(NativeInAppMessageAction? action, String? error) {
    switch (this) {
      case NativeInAppMessageStatus.inAppShouldBeDisplayed:
        return InAppShouldBeDisplayed();
      case NativeInAppMessageStatus.inAppIsDisplayed:
        return InAppIsDisplayed();
      case NativeInAppMessageStatus.inAppShouldBeClosed:
        return InAppShouldBeClosed(
          action: action!.toInAppMessageAction(),
        );
      case NativeInAppMessageStatus.inAppIsClosed:
        return InAppIsClosed(
          action: action!.toInAppMessageAction(),
        );
      case NativeInAppMessageStatus.inAppReceivedError:
        return InAppReceivedError(
          errorMessage: error!,
        );
    }
  }
}

extension NativeInAppMessageActionExt on NativeInAppMessageAction {
  InAppMessageAction toInAppMessageAction() {
    return InAppMessageAction(
      isCloseButtonClicked: isCloseButtonClicked,
      isButtonClicked: isButtonClicked,
      isOpenUrlClicked: isOpenUrlClicked,
    );
  }
}

extension RetenoRecomendationFilterExt on RetenoRecomendationFilter {
  NativeRecomFilter toNativeRecomFilter() {
    return NativeRecomFilter(
      name: name,
      values: values,
    );
  }
}

extension NativeRecommendationExt on NativeRecommendation {
  RetenoRecommendation toRetenoRecommendation() {
    return RetenoRecommendation(
      productId: productId,
      name: name,
      price: price,
      description: description,
      imageUrl: imageUrl,
      category: category,
      categoryAncestor: categoryAncestor,
      categoryLayout: categoryLayout,
      categoryParent: categoryParent,
      dateCreatedAs: dateCreatedAs,
      dateCreatedEs: dateCreatedEs,
      dateModifiedAs: dateModifiedAs,
      itemGroup: itemGroup,
      nameKeyword: nameKeyword,
      productIdAlt: productIdAlt,
      tagsAllCategoryNames: tagsAllCategoryNames,
      tagsBestseller: tagsBestseller,
      tagsCashback: tagsCashback,
      tagsCategoryBestseller: tagsCategoryBestseller,
      tagsCredit: tagsCredit,
      tagsDelivery: tagsDelivery,
      tagsDescriptionPriceRange: tagsDescriptionPriceRange,
      tagsDiscount: tagsDiscount,
      tagsHasPurchases21Days: tagsHasPurchases21Days,
      tagsIsBestseller: tagsIsBestseller,
      tagsIsBestsellerByCategories: tagsIsBestsellerByCategories,
      tagsItemGroupId: tagsItemGroupId,
      tagsNumPurchases21Days: tagsNumPurchases21Days,
      tagsOldPrice: tagsOldPrice,
      tagsOldprice: tagsOldprice,
      tagsPriceRange: tagsPriceRange,
      tagsRating: tagsRating,
      tagsSale: tagsSale,
      url: url,
    );
  }
}

extension RetenoRecomEventsExt on RetenoRecomEvents {
  NativeRecomEvents toNativeRecomEvents() {
    return NativeRecomEvents(
      recomVariantId: recomVariantId,
      events: events.map((e) => e!.toNativeRecomEvent()).toList(),
    );
  }
}

extension RetenoRecomEventExt on RetenoRecomEvent {
  NativeRecomEvent toNativeRecomEvent() {
    return NativeRecomEvent(
      eventType: eventType.toNativeRecomEventType(),
      dateOccurred: dateOccurred.toUtc().toIso8601String(),
      productId: productId,
    );
  }
}

extension RetenoRecomEventTypeExt on RetenoRecomEventType {
  NativeRecomEventType toNativeRecomEventType() {
    switch (this) {
      case RetenoRecomEventType.impression:
        return NativeRecomEventType.impression;
      case RetenoRecomEventType.click:
        return NativeRecomEventType.click;
    }
  }
}

extension LifecycleTrackingOptionsExt on LifecycleTrackingOptions {
  NativeLifecycleTrackingOptions toNativeLifecycleTrackingOptions() {
    return NativeLifecycleTrackingOptions(
      appLifecycleEnabled: appLifecycleEnabled,
      pushSubscriptionEnabled: pushSubscriptionEnabled,
      sessionEventsEnabled: sessionEventsEnabled,
    );
  }
}

extension NativeAppInboxMessagesExt on NativeAppInboxMessages {
  AppInboxMessages toAppInboxMessages() {
    return AppInboxMessages(
      messages: messages.map((m) => m!.toAppInboxMessage()).toList(),
      totalPages: totalPages,
    );
  }
}

extension NativeAppInboxMessageExt on NativeAppInboxMessage {
  AppInboxMessage toAppInboxMessage() {
    return AppInboxMessage(
      id: id,
      title: title,
      isNewMessage: isNewMessage,
      createdDate: createdDate,
      content: content,
      imageUrl: imageUrl,
      linkUrl: linkUrl,
      category: category,
      customData: customData,
    );
  }
}

extension NativeUserNotificationActionExt on NativeUserNotificationAction {
  RetenoUserNotificationAction toUserNotificationAction() {
    return RetenoUserNotificationAction(
      actionId: actionId,
      customData: customData,
      link: link,
    );
  }
}

extension RetenoEcommerceProductExt on RetenoEcommerceProduct {
  NativeEcommerceProduct toNativeEcommerceProduct() {
    return NativeEcommerceProduct(
      productId: productId,
      price: price,
      inStock: inStock,
      attributes: attributes,
    );
  }
}

extension RetenoEcommerceCategoryExt on RetenoEcommerceCategory {
  NativeEcommerceCategory toNativeEcommerceCategory() {
    return NativeEcommerceCategory(
      productCategoryId: productCategoryId,
      attributes: attributes,
    );
  }
}

extension RetenoEcommerceProductInCartExt on RetenoEcommerceProductInCart {
  NativeEcommerceProductInCart toNativeEcommerceProductInCart() {
    return NativeEcommerceProductInCart(
      productId: productId,
      price: price,
      quantity: quantity,
      discount: discount,
      name: name,
      category: category,
      attributes: attributes,
    );
  }
}

extension RetenoEcommerceOrderExt on RetenoEcommerceOrder {
  NativeEcommerceOrder toNativeEcommerceOrder() {
    return NativeEcommerceOrder(
      externalOrderId: externalOrderId,
      totalCost: totalCost,
      status: status.toNativeString,
      date: date,
      cartId: cartId,
      email: email,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      shipping: shipping,
      discount: discount,
      taxes: taxes,
      restoreUrl: restoreUrl,
      statusDescription: statusDescription,
      storeId: storeId,
      source: source,
      deliveryMethod: deliveryMethod,
      paymentMethod: paymentMethod,
      deliveryAddress: deliveryAddress,
      items: items?.map((i) => i.toNativeEcommerceItem()).toList(),
      attributes: attributes,
    );
  }
}

extension RetenoEcommerceItemExt on RetenoEcommerceItem {
  NativeEcommerceItem toNativeEcommerceItem() {
    return NativeEcommerceItem(
      externalItemId: externalItemId,
      name: name,
      category: category,
      quantity: quantity,
      cost: cost,
      url: url,
      imageUrl: imageUrl,
      description: description,
    );
  }
}
