// lib/models/sampling_models/request/customer_sampling_models/customer_sampling.dart
import 'dart:convert';

import 'package:dart_crm/edit/utils/AppUtils.dart';

class CustomerSamplingRequest {
  final String customerId;
  final String loggedInExecutiveId;
  final String loggedInExecutiveProfileCode;
  final String executiveId;
  final String customerSamplingDetailsXml;
  final String customerType;
  final String? requestRemarks;
  final String? shippingInstructions;
  final String shipmentMode;
  final String totalPrice;
  final String totalQty;
  final String enteredBy;

  CustomerSamplingRequest({
    required this.customerId,
    required this.loggedInExecutiveId,
    required this.loggedInExecutiveProfileCode,
    required this.executiveId,
    required this.customerSamplingDetailsXml,
    required this.customerType,
    this.requestRemarks,
    this.shippingInstructions,
    required this.shipmentMode,
    required this.totalPrice,
    required this.totalQty,
    required this.enteredBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'CustomerId': customerId,
      'LoggedInExecutiveid': loggedInExecutiveId,
      'LoggedInExecutiveProfileCode': loggedInExecutiveProfileCode,
      'ExecutiveId': executiveId,
      'CustomerSamplingDetailsXML': customerSamplingDetailsXml,
      'CustomerType': customerType,
      'RequestRemarks': requestRemarks,
      'ShippingInstructions': shippingInstructions,
      'ShipmentMode': shipmentMode,
      'TotalPrice': totalPrice,
      'TotalQty': totalQty,
      'EnteredBy': enteredBy,
    }..removeWhere((key, value) => value == null);
  }
}

class CustomerSamplingResponse {
  final String status;
  final List<Map<String, dynamic>>
      returnMessage; // Explicitly typed as a list of maps

  CustomerSamplingResponse({
    required this.status,
    required this.returnMessage,
  });

  factory CustomerSamplingResponse.fromJson(Map<String, dynamic> json) {
    return CustomerSamplingResponse(
      status: json['Status'] ?? 'error',
      returnMessage: (json['ReturnMessage'] as List<dynamic>? ?? [])
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
  }
}

class CustomerSamplingRequestDetail {
  final int seriesId;
  final int bookId;
  final int requestedQty;
  final String shipTo;
  final String shippingAddress;
  final String samplingType;
  final String sampleTo;
  final double mrp;

  CustomerSamplingRequestDetail({
    required this.seriesId,
    required this.bookId,
    required this.requestedQty,
    required this.shipTo,
    required this.shippingAddress,
    required this.samplingType,
    required this.sampleTo,
    required this.mrp,
  });

  String toXml() {
    return '<CustomerSamplingRequestDetails>'
        '<SeriesId>$seriesId</SeriesId>'
        '<BookId>$bookId</BookId>'
        '<RequestedQty>$requestedQty</RequestedQty>'
        '<ShipTo>$shipTo</ShipTo>'
        '<ShippingAddress>$shippingAddress</ShippingAddress>'
        '<SamplingType>$samplingType</SamplingType>'
        '<SampleTo>$sampleTo</SampleTo>'
        '<MRP>$mrp</MRP>'
        '</CustomerSamplingRequestDetails>';
  }
}
