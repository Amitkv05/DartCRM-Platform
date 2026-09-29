// customer_creation_model.dart
class CustomerCreationModel {
  final int? customerId;
  final String customerType;
  final String customerName;
  final String? refCode;
  final String address;
  final int enteredBy;
  final int cityId;
  final String pincode;
  final String keyCustomer;
  final String customerStatus;
  final String averageFee;
  final String latEntry;
  final String longEntry;
  final int contactDesignationId;
  final String primaryContact;
  final String? resAddress;
  final int? resCity;
  final String? resPincode;
  final String? mobile;
  final String? emailId;
  final String? contactMobile;
  final String? contactEmailId;
  final String? firstName;
  final String? lastName;
  final String? contactStatus;
  final int? salutationId;

  // School-specific
  final String? xmlAccountTableExecutiveId;
  final String? purchaseMode;
  final int? decisionMonth;
  final int? samplingMonth;
  final String? ranking;
  final String? mediumInstruction;
  final int? startClassId;
  final int? endClassId;
  final String? xmlClassName;

  // Trade/Library-specific
  final String? xmlCustomerCategoryId;

  CustomerCreationModel({
    this.customerId,
    required this.customerType,
    required this.customerName,
    this.refCode,
    required this.address,
    required this.enteredBy,
    required this.cityId,
    required this.pincode,
    required this.keyCustomer,
    required this.customerStatus,
    required this.averageFee,
    required this.latEntry,
    required this.longEntry,
    required this.contactDesignationId,
    required this.primaryContact,
    this.resAddress,
    this.resCity,
    this.resPincode,
    this.mobile,
    this.emailId,
    this.contactMobile,
    this.contactEmailId,
    this.firstName,
    this.lastName,
    this.contactStatus,
    this.salutationId,
    this.xmlAccountTableExecutiveId,
    this.purchaseMode,
    this.decisionMonth,
    this.samplingMonth,
    this.ranking,
    this.mediumInstruction,
    this.startClassId,
    this.endClassId,
    this.xmlClassName,
    this.xmlCustomerCategoryId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'CustomerId': customerId ?? 0,
      'CustomerType': customerType,
      'CustomerName': customerName,
      'RefCode': refCode,
      'Address': address,
      'EnteredBy': enteredBy,
      'CityId': cityId,
      'Pincode': pincode,
      'KeyCustomer': keyCustomer,
      'CustomerStatus': customerStatus,
      'AverageFee': averageFee,
      'latEntry': latEntry,
      'longEntry': longEntry,
      'ContactDesignationId': contactDesignationId,
      'PrimaryContact': primaryContact,
    };
    if (resAddress != null) map['resAddress'] = resAddress;
    if (resCity != null) map['resCity'] = resCity;
    if (resPincode != null) map['resPincode'] = resPincode;
    if (mobile != null) map['Mobile'] = mobile;
    if (emailId != null) map['EmailId'] = emailId;
    if (contactMobile != null) map['ContactMobile'] = contactMobile;
    if (contactEmailId != null) map['ContactEmailId'] = contactEmailId;
    if (firstName != null) map['FirstName'] = firstName;
    if (lastName != null) map['LastName'] = lastName;
    if (contactStatus != null) map['ContactStatus'] = contactStatus;
    if (salutationId != null) map['SalutationId'] = salutationId;
    if (xmlAccountTableExecutiveId != null)
      map['xmlAccountTableExecutiveId'] = xmlAccountTableExecutiveId;
    if (purchaseMode != null) map['PurchaseMode'] = purchaseMode;
    if (decisionMonth != null) map['DecisionMonth'] = decisionMonth;
    if (samplingMonth != null) map['SamplingMonth'] = samplingMonth;
    if (ranking != null) map['Ranking'] = ranking;
    if (mediumInstruction != null) map['MediumInstruction'] = mediumInstruction;
    if (startClassId != null) map['StartClassId'] = startClassId;
    if (endClassId != null) map['EndClassId'] = endClassId;
    if (xmlClassName != null) map['xmlClassName'] = xmlClassName;
    if (xmlCustomerCategoryId != null)
      map['xmlCustomerCategoryId'] = xmlCustomerCategoryId;
    return map;
  }
}
