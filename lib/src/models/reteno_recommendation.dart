class RetenoRecommendation {
  final String productId;
  final String? name;
  final String? description;
  final String? imageUrl;
  final double? price;

  RetenoRecommendation({
    required this.productId,
    this.price,
    this.name,
    this.description,
    this.imageUrl,
  });

  @override
  String toString() {
    return 'RetenoRecommendation(productId: $productId, name: $name, description: $description, imageUrl: $imageUrl, price: $price)';
  }
}

class RetenoRecomendationFilter {
  final String name;
  final List<String> values;

  RetenoRecomendationFilter({
    required this.name,
    required this.values,
  });

  @override
  String toString() {
    return 'RetenoRecomendationFilter(name: $name, values: $values)';
  }
}
