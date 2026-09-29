class TeacherUpdateRequest {
  TeacherUpdateRequest({
    this.customerType,
    this.primaryContact,
    this.salutationId,
    this.contactDesignationId,
    this.firstName,
    this.lastName,
    this.contactEmailId,
    this.contactMobile,
    this.contactStatus,
    this.enteredBy,
    this.customerId,
    this.validated,
    this.resAddress,
    this.resCity,
    this.resPincode,
    this.birthDay,
    this.anniversary,
    this.xmlSubjectClassDM,
    this.dataSourceId,
    this.customerContactId,
  });

  TeacherUpdateRequest.fromJson(dynamic json) {
    customerType = json['CustomerType'];
    primaryContact = json['PrimaryContact'];
    salutationId = json['SalutationId'];
    contactDesignationId = json['ContactDesignationId'];
    firstName = json['FirstName'];
    lastName = json['LastName'];
    contactEmailId = json['ContactEmailId'];
    contactMobile = json['ContactMobile'];
    contactStatus = json['ContactStatus'];
    enteredBy = json['EnteredBy'];
    customerId = json['CustomerId'];
    validated = json['Validated'];
    resAddress = json['resAddress'];
    resCity = json['resCity'];
    resPincode = json['resPincode'];
    birthDay = json['BirthDay'];
    anniversary = json['Anniversary'];
    xmlSubjectClassDM = json['xmlSubjectClassDM'];
    dataSourceId = json['DataSourceId'];
    customerContactId = json['CustomerContactId'];
  }

  String? customerType;
  String? primaryContact;
  int? salutationId;
  int? contactDesignationId;
  String? firstName;
  String? lastName;
  String? contactEmailId;
  String? contactMobile;
  String? contactStatus;
  int? enteredBy;
  int? customerId;
  String? validated;
  String? resAddress;
  int? resCity;
  int? resState;
  int? resCountry;
  int? resDistrict;
  String? resPincode;
  String? birthDay;
  String? anniversary;
  String? xmlSubjectClassDM;
  int? dataSourceId;
  int? customerContactId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['CustomerType'] = customerType;
    map['PrimaryContact'] = primaryContact;
    map['SalutationId'] = salutationId;
    map['ContactDesignationId'] = contactDesignationId;
    map['FirstName'] = firstName;
    map['LastName'] = lastName;
    map['ContactEmailId'] = contactEmailId;
    map['ContactMobile'] = contactMobile;
    map['ContactStatus'] = contactStatus;
    map['EnteredBy'] = enteredBy;
    map['CustomerId'] = customerId;
    map['Validated'] = validated;
    map['resAddress'] = resAddress;
    map['resCity'] = resCity;
    map['resPincode'] = resPincode;
    map['BirthDay'] = birthDay;
    map['Anniversary'] = anniversary;
    map['xmlSubjectClassDM'] = xmlSubjectClassDM;
    map['DataSourceId'] = dataSourceId;
    map['CustomerContactId'] = customerContactId;
    return map;
  }
}
