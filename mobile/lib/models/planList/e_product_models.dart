class EProduct {
  final String? productName;
  final String? productCode;
  final double? price;

  EProduct({
    this.productName,
    this.productCode,
    this.price,
  });

  factory EProduct.fromJson(Map<String, dynamic> json) {
    return EProduct(
      productName: json['ProductName'] as String?,
      productCode: json['ProductCode'] as String?,
      price: (json['Price'] as num?)?.toDouble(),
    );
  }
}
