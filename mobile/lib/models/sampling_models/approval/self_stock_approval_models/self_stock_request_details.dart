// lib/models/self_stock_request_details.dart
import 'dart:convert';

class SelfStockRequestDetailsRequest {
  final String requestId;
  final String module;

  SelfStockRequestDetailsRequest({
    required this.requestId,
    required this.module,
  });

  Map<String, dynamic> toJson() => {
        'RequestId': requestId,
        'Module': module,
      };
}

class RequestDetail {
  final int requestId;
  final String requestNumber;
  final String requestDate;
  final int executiveId;
  final String executiveName;
  final String executiveCode;
  final int shipmentModeId;
  final String shipmentMode;
  final String shipTo;
  final int? booksellerId;
  final String? booksellerName;
  final String? booksellerCode;
  final int areaId;
  final String areaName;
  final int wareHouseId;
  final String wareHouseName;
  final String shippingAddress;
  final String? shippingInstructions;
  final String? requestRemarks;
  final String approvalStatus;
  final String? shipmentStatus;
  final String requestStatus;
  final double requestedBudget;
  final int budget;

  RequestDetail({
    required this.requestId,
    required this.requestNumber,
    required this.requestDate,
    required this.executiveId,
    required this.executiveName,
    required this.executiveCode,
    required this.shipmentModeId,
    required this.shipmentMode,
    required this.shipTo,
    this.booksellerId,
    this.booksellerName,
    this.booksellerCode,
    required this.areaId,
    required this.areaName,
    required this.wareHouseId,
    required this.wareHouseName,
    required this.shippingAddress,
    this.shippingInstructions,
    this.requestRemarks,
    required this.approvalStatus,
    this.shipmentStatus,
    required this.requestStatus,
    required this.requestedBudget,
    required this.budget,
  });

  factory RequestDetail.fromJson(Map<String, dynamic> json) {
    return RequestDetail(
      areaName: json['AreaName'] ?? '',
      requestId: (json['RequestId'] as num?)?.toInt() ?? 0,
      requestNumber: json['RequestNumber'] ?? '',
      requestDate: json['RequestDate'] ?? '',
      executiveId: (json['ExecutiveId'] as num?)?.toInt() ?? 0,
      executiveName: json['ExecutiveName'] ?? '',
      executiveCode: json['ExecutiveCode'] ?? '',
      shipmentModeId: (json['ShipmentModeId'] as num?)?.toInt() ?? 0,
      shipmentMode: json['ShipmentMode'] ?? '',
      shipTo: json['ShipTo'] ?? '',
      booksellerId: json['BooksellerId'] != null
          ? (json['BooksellerId'] as num?)?.toInt()
          : null,
      booksellerName: json['BooksellerName'],
      booksellerCode: json['BooksellerCode'],
      areaId: (json['AreaId'] as num?)?.toInt() ?? 0,
      wareHouseId: (json['WareHouseId'] as num?)?.toInt() ?? 0,
      wareHouseName: json['WareHouseName'] ?? '',
      shippingAddress: json['ShippingAddress'] ?? '',
      shippingInstructions: json['ShippingInstructions'],
      requestRemarks: json['RequestRemarks'],
      approvalStatus: json['ApprovalStatus'] ?? '',
      shipmentStatus: json['ShipmentStatus'],
      requestStatus: json['RequestStatus'] ?? '',
      requestedBudget: (json['RequestedBudget'] as num?)?.toDouble() ?? 0.0,
      budget: (json['Budget'] as num?)?.toInt() ?? 0,
    );
  }
}

class TitleDetail {
  final int requestId;
  final int bookId;
  final String isbn;
  final String title;
  final String author;
  final String bookTypeName;
  final String bookNum;
  final String seriesName;
  final int requestedQty;
  final int? previousApprovedQty;
  final int? approvedQty;
  final int shippedQty;
  final int budget;
  final double requestedBudget;
  final double bookMRP;

  TitleDetail({
    required this.requestId,
    required this.bookId,
    required this.isbn,
    required this.title,
    required this.author,
    required this.bookTypeName,
    required this.bookNum,
    required this.seriesName,
    required this.requestedQty,
    this.previousApprovedQty,
    this.approvedQty,
    required this.shippedQty,
    required this.budget,
    required this.requestedBudget,
    required this.bookMRP,
  });

  factory TitleDetail.fromJson(Map<String, dynamic> json) {
    return TitleDetail(
      requestId: (json['RequestId'] as num?)?.toInt() ?? 0,
      bookId: (json['BookId'] as num?)?.toInt() ?? 0,
      isbn: json['ISBN'] ?? '',
      title: json['Title'] ?? '',
      author: json['Author'] ?? '',
      bookTypeName: json['BookTypeName'] ?? '',
      bookNum: json['BookNum'] ?? '',
      seriesName: json['SeriesName'] ?? '',
      requestedQty: (json['RequestedQty'] as num?)?.toInt() ?? 0,
      previousApprovedQty: (json['PreviousApprovedQty'] as num?)?.toInt(),
      approvedQty: (json['ApprovedQty'] as num?)?.toInt(),
      shippedQty: (json['ShippedQty'] as num?)?.toInt() ?? 0,
      budget: (json['Budget'] as num?)?.toInt() ?? 0,
      requestedBudget: (json['RequestedBudget'] as num?)?.toDouble() ?? 0.0,
      bookMRP: (json['BookMRP'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SelfStockRequestDetailsResponse {
  final String status;
  final List<RequestDetail> requestDetails;
  final List<TitleDetail> titleDetails;
  final List<dynamic> list;

  SelfStockRequestDetailsResponse({
    required this.status,
    required this.requestDetails,
    required this.titleDetails,
    required this.list,
  });

  factory SelfStockRequestDetailsResponse.fromJson(Map<String, dynamic> json) {
    return SelfStockRequestDetailsResponse(
      status: json['Status'] ?? 'error',
      requestDetails: (json['RequestDetails'] as List? ?? [])
          .map((item) => RequestDetail.fromJson(item))
          .toList(),
      titleDetails: (json['TitleDetails'] as List? ?? [])
          .map((item) => TitleDetail.fromJson(item))
          .toList(),
      list: json['List'] ?? [],
    );
  }
}
