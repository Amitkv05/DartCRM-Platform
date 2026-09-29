// lib/models/sampling_models/approval/customer_approval_models/customer_approval_details.dart
import 'package:dart_crm/models/sampling_models/approval/self_stock_approval_models/self_stock_request_details.dart'
    as selfStock;

class CustomerApprovalDetailsRequest {
  final int customerId;
  final String customerType;
  final int requestId;
  final String module;

  CustomerApprovalDetailsRequest({
    required this.customerId,
    required this.customerType,
    required this.requestId,
    required this.module,
  });

  Map<String, dynamic> toJson() => {
        'CustomerId': customerId,
        'CustomerType': customerType,
        'RequestId': requestId,
        'Module': module,
      };
}

class CustomerApprovalDetailsResponse {
  final String status;
  final List<RequestDetail> requestDetails;
  final List<TitleDetail> titleDetails;

  CustomerApprovalDetailsResponse({
    required this.status,
    required this.requestDetails,
    required this.titleDetails,
  });

  factory CustomerApprovalDetailsResponse.fromJson(Map<String, dynamic> json) {
    return CustomerApprovalDetailsResponse(
      status: json['Status'] ?? '',
      requestDetails: (json['RequestDetails'] as List? ?? [])
          .map((item) => RequestDetail.fromJson(item))
          .toList(),
      titleDetails: (json['TitleDetails'] as List? ?? [])
          .map((item) => TitleDetail.fromJson(item))
          .toList(),
    );
  }
}

class RequestDetail {
  final int requestId;
  final String requestDate;
  final String requestNumber;
  final String requestStatus;
  final String? requestRemarks;
  final String? shipmentStatus;
  final String shippingAddress;
  final String? shippingInstructions;
  final String? shipmentMode;
  final String areaName;
  final String wareHouseName;
  final String customerName;
  final int customerId;
  final String customerType;
  final String refCode;
  final String executiveName;
  final double requestedBudget;
  final double budget;

  RequestDetail({
    required this.requestId,
    required this.requestDate,
    required this.requestNumber,
    required this.requestStatus,
    this.requestRemarks,
    this.shipmentStatus,
    required this.shippingAddress,
    this.shippingInstructions,
    this.shipmentMode,
    required this.areaName,
    required this.wareHouseName,
    required this.customerName,
    required this.customerId,
    required this.customerType,
    required this.refCode,
    required this.executiveName,
    required this.requestedBudget,
    required this.budget,
  });

  factory RequestDetail.fromJson(Map<String, dynamic> json) {
    return RequestDetail(
      requestId: json['RequestId'] ?? 0,
      requestDate: json['RequestDate'] ?? '',
      requestNumber: json['RequestNumber'] ?? '',
      requestStatus: json['RequestStatus'] ?? '',
      requestRemarks: json['RequestRemarks'],
      shipmentStatus: json['ShipmentStatus'],
      shippingAddress: json['ShippingAddress'] ?? '',
      shippingInstructions: json['ShippingInstructions'],
      shipmentMode: json['ShipmentMode'],
      areaName: json['AreaName'] ?? '',
      wareHouseName: json['WareHouseName'] ?? '',
      customerName: json['CustomerName'] ?? '',
      customerId: json['CustomerId'] ?? 0,
      customerType: json['CustomerType'] ?? '',
      refCode: json['RefCode'] ?? '',
      executiveName: json['ExecutiveName'] ?? '',
      requestedBudget: (json['RequestedBudget'] ?? 0.0).toDouble(),
      budget: (json['Budget'] ?? 0.0).toDouble(),
    );
  }
}

class TitleDetail {
  final int requestId;
  final int requestedQty;
  final int shippedQty;
  final int shipmentRejectQty; // Ensure this is included
  final String isbn;
  final int bookId;
  final String title;
  final int? previousApprovedQty;
  final String author;
  final String series; // Ensure this is included
  final int approvedQty;
  final double budget;
  final double requestedBudget;
  final double bookMRP;

  TitleDetail({
    required this.requestId,
    required this.requestedQty,
    required this.shippedQty,
    required this.shipmentRejectQty,
    required this.isbn,
    required this.bookId,
    required this.title,
    this.previousApprovedQty,
    required this.author,
    required this.series,
    required this.approvedQty,
    required this.budget,
    required this.requestedBudget,
    required this.bookMRP,
  });

  factory TitleDetail.fromJson(Map<String, dynamic> json) {
    return TitleDetail(
      requestId: json['RequestId'] ?? 0,
      requestedQty: json['RequestedQty'] ?? 0,
      shippedQty: json['ShippedQty'] ?? 0,
      shipmentRejectQty: json['ShipmentRejectQty'] ?? 0,
      isbn: json['ISBN'] ?? '',
      bookId: json['BookId'] ?? 0,
      title: json['Title'] ?? '',
      previousApprovedQty: json['PreviousApprovedQty'],
      author: json['Author'] ?? '',
      series: json['Series'] ?? '',
      approvedQty: json['ApprovedQty'] ?? 0,
      budget: (json['Budget'] ?? 0.0).toDouble(),
      requestedBudget: (json['RequestedBudget'] ?? 0.0).toDouble(),
      bookMRP: (json['BookMRP'] ?? 0.0).toDouble(),
    );
  }
}
