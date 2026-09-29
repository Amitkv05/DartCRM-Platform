import 'dart:convert';

class EProductVisitEntryRequest {
  final String customerId;
  final String customerType;
  final String loggedInExecutiveId;
  final String loggedInExecutiveProfileCode;
  final String executiveId;
  final String visitDate;
  final String visitPurpose;
  final String visitFeedBack;
  final String customerContact;
  final String? academicSessionId;
  final String addressEntry;
  final String longEntry;
  final String latEntry;
  final String enteredBy;
  final String? uploadedDocumentXML;
  final String? otherVisitPurpose;
  final String? requestRemarks;
  final String? shippingInstructions;
  final String? shipmentMode;
  final String? totalPrice;
  final String? totalQty;
  final String? followUpActionXML;
  final String? visitDetailsXMLforSampleGiven;
  final String? jointVisitWith;
  final String? sendThankyouMail;
  final String? mailContentType;
  final String? mailBody;
  final String? webEntry;
  final String? visitDetailsXMLforToBeDispatched;
  final String? competingDataXML;
  final String? eProductPromotionDetailsXML;

  EProductVisitEntryRequest({
    required this.customerId,
    required this.customerType,
    required this.loggedInExecutiveId,
    required this.loggedInExecutiveProfileCode,
    required this.executiveId,
    required this.visitDate,
    required this.visitPurpose,
    required this.visitFeedBack,
    required this.customerContact,
    required this.academicSessionId,
    required this.addressEntry,
    required this.longEntry,
    required this.latEntry,
    required this.enteredBy,
    this.uploadedDocumentXML,
    this.otherVisitPurpose,
    this.requestRemarks,
    this.shippingInstructions,
    this.shipmentMode,
    this.totalPrice,
    this.totalQty,
    this.followUpActionXML,
    this.visitDetailsXMLforSampleGiven,
    this.jointVisitWith,
    this.sendThankyouMail,
    this.mailContentType,
    this.mailBody,
    this.webEntry,
    this.visitDetailsXMLforToBeDispatched,
    this.competingDataXML,
    this.eProductPromotionDetailsXML,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'CustomerType': customerType,
      'CustomerId': customerId,
      'LoggedInExecutiveid': loggedInExecutiveId,
      'LoggedInExecutiveProfileCode': loggedInExecutiveProfileCode,
      'ExecutiveId': executiveId,
      'VisitDate': visitDate,
      'VisitPurpose': visitPurpose,
      'VisitFeedBack': visitFeedBack,
      'CustomerContact': customerContact,
      'AcademicSessionId': academicSessionId,
      'addressEntry': addressEntry,
      'LongEntry': longEntry,
      'LatEntry': latEntry,
      'EnteredBy': enteredBy,
    };

    if (uploadedDocumentXML != null) {
      map['UploadedDocumentXML'] = uploadedDocumentXML!;
    }
    if (otherVisitPurpose != null) {
      map['OtherVisitPurpose'] = otherVisitPurpose!;
    }
    if (requestRemarks != null) {
      map['RequestRemarks'] = requestRemarks!;
    }
    if (shippingInstructions != null) {
      map['ShippingInstructions'] = shippingInstructions!;
    }
    if (shipmentMode != null) {
      map['ShipmentMode'] = shipmentMode!;
    }
    if (totalPrice != null) {
      map['TotalPrice'] = totalPrice!;
    }
    if (totalQty != null) {
      map['TotalQty'] = totalQty!;
    }
    if (followUpActionXML != null) {
      map['FollowUpActionXML'] = followUpActionXML!;
    }
    if (visitDetailsXMLforSampleGiven != null) {
      map['VisitDetailsXMLforSampleGiven'] = visitDetailsXMLforSampleGiven!;
    }
    if (jointVisitWith != null) {
      map['JointVisitWith'] = jointVisitWith!;
    }
    if (sendThankyouMail != null) {
      map['SendThankyouMail'] = sendThankyouMail!;
    }
    if (mailContentType != null) {
      map['MailContentType'] = mailContentType!;
    }
    if (mailBody != null) {
      map['MailBody'] = mailBody!;
    }
    if (webEntry != null) {
      map['WebEntry'] = webEntry!;
    }
    if (visitDetailsXMLforToBeDispatched != null) {
      map['VisitDetailsXMLforToBeDispatched'] = visitDetailsXMLforToBeDispatched!;
    }
    if (competingDataXML != null) {
      map['CompetingDataXML'] = competingDataXML!;
    }
    if (eProductPromotionDetailsXML != null) {
      map['EProductPromotionDetailsXML'] = eProductPromotionDetailsXML!;
    }

    return map;
  }
}

class EProductVisitEntryResponse {
  final String status;
  final String message;
  final List<dynamic> visitEntryData;

  EProductVisitEntryResponse({
    required this.status,
    required this.message,
    required this.visitEntryData,
  });

  factory EProductVisitEntryResponse.fromJson(Map<String, dynamic> json) {
    return EProductVisitEntryResponse(
      status: json['Status'] ?? 'error',
      message: json['s'] ?? 'Submission failed',
      visitEntryData: json['VisitEntryData'] ?? [],
    );
  }
}
