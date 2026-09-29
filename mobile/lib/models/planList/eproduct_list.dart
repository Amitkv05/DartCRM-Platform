import 'dart:convert';

class EProductListRequest {
  final String brandId;

  EProductListRequest({
    required this.brandId,
  });

  Map<String, dynamic> toJson() {
    return {
      'BrandId': brandId,
    };
  }
}

class EProductListResponse {
  final String status;
  final List<ProductData> productList;
  final List<dynamic> products;

  EProductListResponse({
    required this.status,
    required this.productList,
    required this.products,
  });

  factory EProductListResponse.fromJson(Map<String, dynamic> json) {
    return EProductListResponse(
      status: ((json['Status'] ?? json['status'] ?? 'error').toString().toLowerCase() == 'success') ? 'Success' : (json['Status'] ?? json['status'] ?? 'error').toString(),
      productList: ((json['ProductList'] ?? json['productList']) as List<dynamic>?)
              ?.map((item) => ProductData.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
      products: (json['Products'] ?? json['products']) as List<dynamic>? ?? [],
    );
  }
}

class ProductData {
  final int id;
  final String productName;
  final String brandName;

  ProductData({
    required this.id,
    required this.productName,
    required this.brandName,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      id: int.tryParse((json['Id'] ?? json['id'] ?? 0).toString()) ?? 0,
      productName: (json['ProductName'] ?? json['productName'] ?? '').toString(),
      brandName: (json['BrandName'] ?? json['brandName'] ?? '').toString(),
    );
  }
}
