import 'dart:convert';

class EProductDetailsRequest {
  final String eProductId;
  final String academicSessionId;
  final String customerId;

  EProductDetailsRequest({
    required this.eProductId,
    required this.academicSessionId,
    required this.customerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'eProductId': eProductId,
      'AcademicSessionId': academicSessionId,
      'Customerid': customerId,
    };
  }
}

class EProductDetailsResponse {
  final String status;
  final List<ProductDetail> productDetails;
  final List<ClassDetail> classes;
  final List<dynamic> products;

  EProductDetailsResponse({
    required this.status,
    required this.productDetails,
    required this.classes,
    required this.products,
  });

  factory EProductDetailsResponse.fromJson(Map<String, dynamic> json) {
    return EProductDetailsResponse(
      status: ((json['Status'] ?? json['status'] ?? 'error').toString().toLowerCase() == 'success') ? 'Success' : (json['Status'] ?? json['status'] ?? 'error').toString(),
      productDetails: ((json['ProductDetails'] ?? json['productDetails']) as List<dynamic>?)
              ?.map((item) => ProductDetail.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
      classes: ((json['classes'] ?? json['Classes']) as List<dynamic>?)
              ?.map((item) => ClassDetail.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
      products: (json['Products'] ?? json['products']) as List<dynamic>? ?? [],
    );
  }
}

class ProductDetail {
  final int eProductId;
  final String eProductName;
  final double listPrice;
  final String subjectName;
  final String previousSalesStage;
  final int previousStageSequenceNum;

  ProductDetail({
    required this.eProductId,
    required this.eProductName,
    required this.listPrice,
    required this.subjectName,
    required this.previousSalesStage,
    required this.previousStageSequenceNum,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      eProductId: int.tryParse((json['eProductId'] ?? json['EProductId'] ?? 0).toString()) ?? 0,
      eProductName: (json['eProductName'] ?? json['EProductName'] ?? '').toString(),
      listPrice: num.tryParse((json['ListPrice'] ?? json['listPrice'] ?? 0).toString())?.toDouble() ?? 0,
      subjectName: (json['SubjectName'] ?? json['subjectName'] ?? '').toString(),
      previousSalesStage: (json['PreviousSalesStage'] ?? json['previousSalesStage'] ?? '').toString(),
      previousStageSequenceNum: int.tryParse((json['PreviousStageSequenceNum'] ?? json['previousStageSequenceNum'] ?? 0).toString()) ?? 0,
    );
  }
}

class ClassDetail {
  final int classNumId;
  final String className;
  bool isCheck = false;

  ClassDetail({
    required this.classNumId,
    required this.className,
  });

  factory ClassDetail.fromJson(Map<String, dynamic> json) {
    return ClassDetail(
      classNumId: int.tryParse((json['ClassNumId'] ?? json['classNumId'] ?? 0).toString()) ?? 0,
      className: (json['ClassName'] ?? json['className'] ?? '').toString(),
    );
  }
}

class EProductDetails {
  final List<String> brandNames;
  final List<String> productNames;
  final List<String> classes;
  final List<String> currentSalesStages;
  final List<String> previousSalesStages;

  EProductDetails({
    required this.brandNames,
    required this.productNames,
    required this.classes,
    required this.currentSalesStages,
    required this.previousSalesStages,
  });

  factory EProductDetails.fromJson(Map<String, dynamic> json) {
    return EProductDetails(
      brandNames: (json['BrandNames'] as List<dynamic>?)?.cast<String>() ?? [],
      productNames: (json['ProductNames'] as List<dynamic>?)?.cast<String>() ?? [],
      classes: (json['Classes'] as List<dynamic>?)?.cast<String>() ?? [],
      currentSalesStages:
          (json['CurrentSalesStages'] as List<dynamic>?)?.cast<String>() ?? [],
      previousSalesStages:
          (json['PreviousSalesStages'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
