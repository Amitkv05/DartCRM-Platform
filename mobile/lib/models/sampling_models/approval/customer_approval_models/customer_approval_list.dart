// lib/models/sampling_models/approval/customer_approval_models/customer_approval_list.dart
class CustomerApprovalRequest {
  final int executiveId;
  final String listFor;

  CustomerApprovalRequest({
    required this.executiveId,
    required this.listFor,
  });

  Map<String, dynamic> toJson() => {
        'ExecutiveId': executiveId,
        'ListFor': listFor,
      };
}

class CustomerApprovalResponse {
  final String status;
  final List<ApprovalListItem> approvalList;

  CustomerApprovalResponse({
    required this.status,
    required this.approvalList,
  });

  factory CustomerApprovalResponse.fromJson(Map<String, dynamic> json) {
    return CustomerApprovalResponse(
      status: json['Status'] ?? '',
      approvalList: (json['ApprovalList'] as List? ?? [])
          .map((item) => ApprovalListItem.fromJson(item))
          .toList(),
    );
  }
}

class ApprovalListItem {
  final int sNo;
  final int requestId;
  final String requestDate;
  final String requestNumber;
  final String executiveName;
  final String customerName;
  final int customerId;
  final String customerType;
  final String customerCode;
  final String refCode;
  final String address;
  final String city;
  final String state;
  final String requestStatus;
  final String inBudget;
  final double finalBudget;
  final int availableBudget;

  ApprovalListItem({
    required this.sNo,
    required this.requestId,
    required this.requestDate,
    required this.requestNumber,
    required this.executiveName,
    required this.customerName,
    required this.customerId,
    required this.customerType,
    required this.customerCode,
    required this.refCode,
    required this.address,
    required this.city,
    required this.state,
    required this.requestStatus,
    required this.inBudget,
    required this.finalBudget,
    required this.availableBudget,
  });

  factory ApprovalListItem.fromJson(Map<String, dynamic> json) {
    return ApprovalListItem(
      sNo: json['SNo'] ?? 0,
      requestId: json['RequestId'] ?? 0,
      requestDate: json['RequestDate'] ?? '',
      requestNumber: json['RequestNumber'] ?? '',
      executiveName: json['ExecutiveName'] ?? '',
      customerName: json['CustomerName'] ?? '',
      customerId: json['CustomerId'] ?? 0,
      customerType: json['CustomerType'] ?? '',
      customerCode: json['CustomerCode'] ?? '',
      refCode: json['RefCode'] ?? '',
      address: json['Address'] ?? '',
      city: json['City'] ?? '',
      state: json['State'] ?? '',
      requestStatus: json['RequestStatus'] ?? '',
      inBudget: json['InBudget'] ?? '',
      finalBudget: (json['FinalBudget'] ?? 0.0).toDouble(),
      availableBudget: json['AvailableBudget'] ?? 0,
    );
  }
}
