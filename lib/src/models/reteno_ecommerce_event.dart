sealed class RetenoEcommerceEvent {}

/// Track a product card a user is viewing to rank items / categories
/// and send triggers for abandoned browses.
class RetenoEcommerceProductViewed extends RetenoEcommerceEvent {
  RetenoEcommerceProductViewed({
    required this.product,
    this.currency,
  });

  final RetenoEcommerceProduct product;

  /// Currency in ISO 4217 format. Supported currencies: USD, EUR, UAH. If is not set then org's default is used
  final String? currency;
}

/// Track a product category a user is viewing for triggers
/// like Website visit with a category view and Website visit without a category view.
class RetenoEcommerceProductCategoryViewed extends RetenoEcommerceEvent {
  RetenoEcommerceProductCategoryViewed({
    required this.category,
  });

  final RetenoEcommerceCategory category;
}

/// Track adding product to a wishlist to calculate and display
/// recoms and send triggers related to a wishlist.
class RetenoEcommerceProductAddedToWishlist extends RetenoEcommerceEvent {
  RetenoEcommerceProductAddedToWishlist({required this.product, this.currency});

  final RetenoEcommerceProduct product;

  /// Currency in ISO 4217 format. Supported currencies: USD, EUR, UAH. If is not set then org's default is used
  final String? currency;
}

/// Track updating a shopping cart for triggers.
class RetenoEcommerceCartUpdated extends RetenoEcommerceEvent {
  RetenoEcommerceCartUpdated({
    required this.cartId,
    required this.products,
    this.currency,
  });

  final String cartId;
  final List<RetenoEcommerceProductInCart> products;

  /// Currency in ISO 4217 format. Supported currencies: USD, EUR, UAH. If is not set then org's default is used
  final String? currency;
}

/// Create an order.
class RetenoEcommerceOrderCreated extends RetenoEcommerceEvent {
  RetenoEcommerceOrderCreated({required this.order, this.currency});
  final RetenoEcommerceOrder order;

  /// Currency in ISO 4217 format. Supported currencies: USD, EUR, UAH. If is not set then org's default is used
  final String? currency;
}

/// Update an order.
class RetenoEcommerceOrderUpdated extends RetenoEcommerceEvent {
  RetenoEcommerceOrderUpdated({required this.order, this.currency});

  final RetenoEcommerceOrder order;

  /// Currency in ISO 4217 format. Supported currencies: USD, EUR, UAH. If is not set then org's default is used
  final String? currency;
}

/// Change an existing order status to DELIVERED.
class RetenoEcommerceOrderDelivered extends RetenoEcommerceEvent {
  RetenoEcommerceOrderDelivered({
    required this.externalOrderId,
  });

  final String externalOrderId;
}

/// Change an existing order status to CANCELLED.
class RetenoEcommerceOrderCancelled extends RetenoEcommerceEvent {
  RetenoEcommerceOrderCancelled({
    required this.externalOrderId,
  });

  final String externalOrderId;
}

/// Track search requests for triggers like Abandoned search.
class RetenoEcommerceSearchRequest extends RetenoEcommerceEvent {
  RetenoEcommerceSearchRequest({
    required this.query,
    this.isFound,
  });

  final String query;
  final bool? isFound;
}

class RetenoEcommerceProduct {
  const RetenoEcommerceProduct({
    required this.productId,
    required this.price,
    required this.inStock,
    required this.attributes,
  });

  final String productId;
  final double price;
  final bool inStock;
  final Map<String, List<String>>? attributes;
}

class RetenoEcommerceCategory {
  const RetenoEcommerceCategory({
    required this.productCategoryId,
    this.attributes,
  });

  final String productCategoryId;
  final Map<String, List<String>>? attributes;
}

class RetenoEcommerceProductInCart {
  const RetenoEcommerceProductInCart({
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
  final Map<String, List<String>>? attributes;
}

class RetenoEcommerceItem {
  const RetenoEcommerceItem({
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

//public enum Status: String {
//     case INITIALIZED, IN_PROGRESS, DELIVERED, CANCELLED
// }

enum RetenoEcommerceOrderStatus {
  initialized(),
  inProgress(),
  delivered(),
  cancelled();

  const RetenoEcommerceOrderStatus();

  String get toNativeString {
    switch (this) {
      case RetenoEcommerceOrderStatus.initialized:
        return 'INITIALIZED';
      case RetenoEcommerceOrderStatus.inProgress:
        return 'IN_PROGRESS';
      case RetenoEcommerceOrderStatus.delivered:
        return 'DELIVERED';
      case RetenoEcommerceOrderStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

class RetenoEcommerceOrder {
  const RetenoEcommerceOrder({
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
  final RetenoEcommerceOrderStatus status;
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
  final List<RetenoEcommerceItem>? items;
  final Map<String, List<String>>? attributes;
}
