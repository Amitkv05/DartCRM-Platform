class SchoolContactDetails {
  SchoolContactDetails({
    this.primaryContact,
    this.contactStatus,
    this.firstName,
    this.lastName,
    this.salutationId,
    this.contactDesignationId,
    this.contactEmailId,
    this.contactMobile,
    this.schoolContactId,
    this.resAddress,
    this.resCountry,
    this.resState,
    this.resDistrict,
    this.resCity,
    this.resPincode,
    this.subjectId,
    this.decisionId,
    this.classNumId,
    this.dataSourceId,
    this.birthDay,
    this.anniversary,
    this.msgWarning,
    this.existence,
  });

  SchoolContactDetails.fromJson(dynamic json) {
    primaryContact = json['PrimaryContact'];
    contactStatus = json['ContactStatus'];
    firstName = json['FirstName'];
    lastName = json['LastName'];
    salutationId = json['SalutationId'];
    contactDesignationId = json['ContactDesignationId'];
    contactEmailId = json['ContactEmailId'];
    contactMobile = json['ContactMobile'];
    schoolContactId = json['SchoolContactId'];
    resAddress = json['resAddress'];
    resCountry = json['resCountry'];
    resState = json['resState'];
    resDistrict = json['resDistrict'];
    resCity = json['resCity'];
    resPincode = json['resPincode'];
    subjectId = json['SubjectId'];
    decisionId = json['DecisionId'];
    classNumId = json['ClassNumId'];
    dataSourceId = json['DataSourceId'];
    birthDay = json['BirthDay'];
    anniversary = json['Anniversary'];
    msgWarning = json['MsgWarning'];
    existence = json['Existence'];
  }
  String? primaryContact;
  String? contactStatus;
  String? firstName;
  String? lastName;
  int? salutationId;
  int? contactDesignationId;
  String? contactEmailId;
  String? contactMobile;
  String? schoolContactId;
  String? resAddress;
  int? resCountry;
  int? resState;
  int? resDistrict;
  int? resCity;
  String? resPincode;
  dynamic subjectId;
  dynamic decisionId;
  dynamic classNumId;
  dynamic dataSourceId;
  dynamic birthDay;
  dynamic anniversary;
  String? msgWarning;
  int? existence;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['PrimaryContact'] = primaryContact;
    map['ContactStatus'] = contactStatus;
    map['FirstName'] = firstName;
    map['LastName'] = lastName;
    map['SalutationId'] = salutationId;
    map['ContactDesignationId'] = contactDesignationId;
    map['ContactEmailId'] = contactEmailId;
    map['ContactMobile'] = contactMobile;
    map['SchoolContactId'] = schoolContactId;
    map['resAddress'] = resAddress;
    map['resCountry'] = resCountry;
    map['resState'] = resState;
    map['resDistrict'] = resDistrict;
    map['resCity'] = resCity;
    map['resPincode'] = resPincode;
    map['SubjectId'] = subjectId;
    map['DecisionId'] = decisionId;
    map['ClassNumId'] = classNumId;
    map['DataSourceId'] = dataSourceId;
    map['BirthDay'] = birthDay;
    map['Anniversary'] = anniversary;
    map['MsgWarning'] = msgWarning;
    map['Existence'] = existence;
    return map;
  }
}
