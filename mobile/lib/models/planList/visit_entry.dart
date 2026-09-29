class VisitEntryRequest {
  final int executiveId;
  final int loggedInExecutiveId;
  final int customerId;
  final int enteredBy;
  final int customerContact;
  final int academicSessionId;
  final String loggedInExecutiveProfileCode;
  final String? jointVisitWith;
  final int visitPurpose;
  final String visitFeedBack;
  final String visitDate;
  final String addressEntry;
  final String longEntry;
  final String latEntry;
  final String customerType;
  final String uploadedDocumentXML;
  final String requestRemarks;
  final String followUpActionXML;
  final String visitDetailsXMLforToBeDispatched;
  final int totalQty;
  final double totalPrice;

  VisitEntryRequest({
    required this.executiveId,
    required this.loggedInExecutiveId,
    required this.customerId,
    required this.enteredBy,
    required this.customerContact,
    required this.academicSessionId,
    required this.loggedInExecutiveProfileCode,
    this.jointVisitWith,
    required this.visitPurpose,
    required this.visitFeedBack,
    required this.visitDate,
    required this.addressEntry,
    required this.longEntry,
    required this.latEntry,
    required this.customerType,
    required this.uploadedDocumentXML,
    required this.requestRemarks,
    required this.followUpActionXML,
    required this.visitDetailsXMLforToBeDispatched,
    required this.totalQty,
    required this.totalPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'ExecutiveId': executiveId,
      'LoggedInExecutiveid': loggedInExecutiveId,
      'CustomerId': customerId,
      'EnteredBy': enteredBy,
      'CustomerContact': customerContact,
      'AcademicSessionId': academicSessionId,
      'LoggedInExecutiveProfileCode': loggedInExecutiveProfileCode,
      'JointVisitWith': jointVisitWith,
      'VisitPurpose': visitPurpose,
      'VisitFeedBack': visitFeedBack,
      'VisitDate': visitDate,
      'addressEntry': addressEntry,
      'LongEntry': longEntry,
      'LatEntry': latEntry,
      'CustomerType': customerType,
      'UploadedDocumentXML': uploadedDocumentXML,
      'RequestRemarks': requestRemarks,
      'FollowUpActionXML': followUpActionXML,
      'VisitDetailsXMLforToBeDispatched': visitDetailsXMLforToBeDispatched,
      'TotalQty': totalQty,
      'TotalPrice': totalPrice,
    };
  }
}

class VisitEntryResponse {
  final String status;
  final String? message;

  VisitEntryResponse({
    required this.status,
    this.message,
  });

  factory VisitEntryResponse.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['Status'] ?? json['status'] ?? 'error').toString();
    return VisitEntryResponse(
      status: rawStatus.toLowerCase() == 'success' ? 'Success' : rawStatus,
      message: (json['Message'] ?? json['message'])?.toString(),
    );
  }

  // Add toJson method
  Map<String, dynamic> toJson() => {
        'Status': status,
        'Message': message,
      };
}
