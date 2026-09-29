// lib/models/self_stock_approval_list.dart
import 'dart:convert';

class SelfStockApprovalRequest {
  final int executiveId;
  final String listFor;

  SelfStockApprovalRequest({
    required this.executiveId,
    required this.listFor,
  });

  Map<String, dynamic> toJson() => {
        'ExecutiveId': executiveId,
        'ListFor': listFor,
      };
}

class ApprovalListItem {
  final int sNo;
  final int requestId;
  final String requestNumber;
  final String requestDate;
  final String executiveName;
  final String executiveCode;
  final String mobile;
  final String emailId;
  final String requestStatus;
  final String column1;
  final String inBudget;
  final double finalBudget;
  final int availableBudget;

  ApprovalListItem({
    required this.sNo,
    required this.requestId,
    required this.requestNumber,
    required this.requestDate,
    required this.executiveName,
    required this.executiveCode,
    required this.mobile,
    required this.emailId,
    required this.requestStatus,
    required this.column1,
    required this.inBudget,
    required this.finalBudget,
    required this.availableBudget,
  });

  factory ApprovalListItem.fromJson(Map<String, dynamic> json) {
    return ApprovalListItem(
      sNo: (json['SNo'] as num).toInt(),
      requestId: (json['RequestId'] as num).toInt(),
      requestNumber: json['RequestNumber'] ?? '',
      requestDate: json['RequestDate'] ?? '',
      executiveName: json['ExecutiveName'] ?? '',
      executiveCode: json['ExecutiveCode'] ?? '',
      mobile: json['Mobile'] ?? '',
      emailId: json['EmailId'] ?? '',
      requestStatus: json['RequestStatus'] ?? '',
      column1: json['Column1'] ?? '',
      inBudget: json['InBudget'] ?? '',
      finalBudget: (json['FinalBudget'] as num?)?.toDouble() ?? 0.0,
      availableBudget: (json['AvailableBudget'] as num?)?.toInt() ?? 0,
    );
  }
}

class SelfStockApprovalResponse {
  final String status;
  final List<ApprovalListItem> approvalList;
  final List<dynamic> list;

  SelfStockApprovalResponse({
    required this.status,
    required this.approvalList,
    required this.list,
  });

  factory SelfStockApprovalResponse.fromJson(Map<String, dynamic> json) {
    return SelfStockApprovalResponse(
      status: json['Status'] ?? 'error',
      approvalList: (json['ApprovalList'] as List? ?? [])
          .map((item) => ApprovalListItem.fromJson(item))
          .toList(),
      list: json['List'] ?? [],
    );
  }
}