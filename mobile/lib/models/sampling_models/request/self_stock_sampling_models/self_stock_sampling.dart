import 'dart:convert';

class SelfStockRequest {
  final String loggedInExecutiveId;
  final String profileCode;
  final String executiveId;
  final String selfStockDetailsXml;
  final String? shippingAddress;
  final String shipTo;
  final String shipmentModeId;
  final String enteredBy;
  final String? tradeId;
  final String? shippingInstructions;
  final String? remarks;

  SelfStockRequest({
    required this.loggedInExecutiveId,
    required this.profileCode,
    required this.executiveId,
    required this.selfStockDetailsXml,
    this.shippingAddress,
    required this.shipTo,
    required this.shipmentModeId,
    required this.enteredBy,
    this.tradeId,
    this.shippingInstructions,
    this.remarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'LoggedInExecutiveid': loggedInExecutiveId,
      'ProfileCode': profileCode,
      'ExecutiveId': executiveId,
      'SelfStockDetailsxml': selfStockDetailsXml,
      'ShippingAddress': shippingAddress,
      'ShipTo': shipTo,
      'ShipmentModeId': shipmentModeId,
      'EnteredBy': enteredBy,
      'TradeId': tradeId,
      'ShippingInstructions': shippingInstructions,
      'Remarks': remarks,
    }..removeWhere((key, value) => value == null);
  }
}

class SelfStockResponse {
  final String status;
  final List<Map<String, dynamic>> returnMessage;

  SelfStockResponse({
    required this.status,
    required this.returnMessage,
  });

  factory SelfStockResponse.fromJson(Map<String, dynamic> json) {
    return SelfStockResponse(
      status: json['Status'] ?? 'error',
      returnMessage: (json['ReturnMessage'] as List? ?? [])
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
  }
}

class SelfStockRequestDetail {
  final int subjectId;
  final int seriesId;
  final int bookId;
  final int requestedQty;

  SelfStockRequestDetail({
    required this.subjectId,
    required this.seriesId,
    required this.bookId,
    required this.requestedQty,
  });

  String toXml() {
    return '<SelfStockRequestDetails>'
        '<SubjectId>$subjectId</SubjectId>'
        '<SeriesId>$seriesId</SeriesId>'
        '<BookId>$bookId</BookId>'
        '<RequestedQty>$requestedQty</RequestedQty>'
        '</SelfStockRequestDetails>';
  }
}
