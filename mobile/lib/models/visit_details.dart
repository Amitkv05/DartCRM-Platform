// lib/models/visit_details.dart
class VisitDetailsRequest {
  final int? visitId;
  final int? customerId;

  VisitDetailsRequest({this.visitId, this.customerId});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (visitId != null) data['VisitId'] = visitId;
    if (customerId != null) data['CustomerId'] = customerId;
    return data;
  }
}

class CustomerDetail {
  final int customerId;
  final String customerName;
  final String address;
  final String name;
  final String emailId;
  final String mobile;

  CustomerDetail({
    required this.customerId,
    required this.customerName,
    required this.address,
    required this.name,
    required this.emailId,
    required this.mobile,
  });

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    return CustomerDetail(
      customerId: json['CustomerId'] ?? 0,
      customerName: json['CustomerName'] ?? '',
      address: json['Address'] ?? '',
      name: json['Name'] ?? '',
      emailId: json['EmailId'] ?? '',
      mobile: json['Mobile'] ?? '',
    );
  }
}

class VisitDetail {
  final int executiveId;
  final int visitId;
  final String executiveName;
  final String jointVisitWith;
  final String personMet;
  final String visitDate;
  final String visitPurpose;
  final String visitEntryDate;
  final String visitFeedback;
  final int customerId;
  final int customerContactId;
  final String customerType;
  final String webEntry;
  final String lat;
  final String long;

  VisitDetail({
    required this.executiveId,
    required this.visitId,
    required this.executiveName,
    required this.jointVisitWith,
    required this.personMet,
    required this.visitDate,
    required this.visitPurpose,
    required this.visitEntryDate,
    required this.visitFeedback,
    required this.customerId,
    required this.customerContactId,
    required this.customerType,
    required this.webEntry,
    required this.lat,
    required this.long,
  });

  factory VisitDetail.fromJson(Map<String, dynamic> json) {
    return VisitDetail(
      executiveId: json['ExecutiveId'] ?? 0,
      visitId: json['VisitId'] ?? 0,
      executiveName: json['ExecutiveName'] ?? '',
      jointVisitWith: json['JointVisitWith'] ?? '',
      personMet: json['PersonMet'] ?? '',
      visitDate: json['VisitDate'] ?? '',
      visitPurpose: json['VisitPurpose'] ?? '',
      visitEntryDate: json['VisitEntryDate'] ?? '',
      visitFeedback: json['VisitFeedback'] ?? '',
      customerId: json['CustomerId'] ?? 0,
      customerContactId: json['CustomerContactId'] ?? 0,
      customerType: json['CustomerType'] ?? '',
      webEntry: json['WebEntry'] ?? '',
      lat: json['Lat'] ?? '',
      long: json['Long'] ?? '',
    );
  }
}

class UploadedDocument {
  final int sno;
  final String documentName;
  final String uploadedFile;
  final String action;

  UploadedDocument({
    required this.sno,
    required this.documentName,
    required this.uploadedFile,
    required this.action,
  });

  factory UploadedDocument.fromJson(Map<String, dynamic> json) {
    return UploadedDocument(
      sno: json['SNO'] ?? 0,
      documentName: json['DocumentName'] ?? '',
      uploadedFile: json['UploadedFile'] ?? '',
      action: json['Action'] ?? '',
    );
  }
}

class VisitDetailsResponse {
  final String status;
  final List<CustomerDetail> customerDetails;
  final List<VisitDetail> visitDetails;
  final List<UploadedDocument> uploadedDocuments;

  VisitDetailsResponse({
    required this.status,
    required this.customerDetails,
    required this.visitDetails,
    required this.uploadedDocuments,
  });

  factory VisitDetailsResponse.fromJson(Map<String, dynamic> json) {
    return VisitDetailsResponse(
      status: json['Status'] ?? '',
      customerDetails: (json['CustomerDetails'] as List<dynamic>?)
              ?.map((e) => CustomerDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      visitDetails: (json['VisitDetails'] as List<dynamic>?)
              ?.map((e) => VisitDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      uploadedDocuments: (json['UploadedDocuments'] as List<dynamic>?)
              ?.map((e) => UploadedDocument.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
