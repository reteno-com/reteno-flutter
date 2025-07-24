class RetenoRecommendation {
  RetenoRecommendation({
    required this.productId,
    this.price,
    this.name,
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
    this.productIdAlt,
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

  @override
  String toString() {
    return 'RetenoRecommendation(productId: $productId, name: $name, description: $description, imageUrl: $imageUrl, price: $price)';
  }
}

class RetenoRecomendationFilter {
  RetenoRecomendationFilter({
    required this.name,
    required this.values,
  });

  final String name;
  final List<String> values;

  @override
  String toString() {
    return 'RetenoRecomendationFilter(name: $name, values: $values)';
  }
}
