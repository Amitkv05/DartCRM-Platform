class SchoolUpdateModel {
  SchoolUpdateModel({
    this.customerId,
    this.customerType,
    this.customerName,
    this.refCode,
    this.address,
    this.cityId,
    this.districtId,
    this.stateId,
    this.countryId,
    this.pincode,
    this.emailId,
    this.mobile,
    this.keyCustomer,
    this.customerStatus,
    this.xmlCustomerCategoryId,
    this.xmlAccountTableExecutiveId,
    this.primaryContact,
    this.contactStatus,
    this.salutationId,
    this.contactDesignationId,
    this.comment,
    this.firstName,
    this.lastName,
    this.contactEmailId,
    this.contactMobile,
    this.resAddress,
    this.resCity,
    this.resDistrict,
    this.resState,
    this.resCountry,
    this.resPincode,
    this.birthDay,
    this.anniversary,
    this.pANNumber,
    this.gSTNumber,
    this.enteredBy,
    this.approvedCustomerMasterNew,
    this.approvedCustomerMasterUpdate,
    this.adoptionRoleId,
    this.departmentId,
    this.latEntry,
    this.longEntry,
    this.dataSourceId,
    this.xmlClassName,
    this.xmlSubjectClassDM,
    this.boardId,
    this.chainSchoolId,
    this.startClassId,
    this.endClassId,
    this.mediumInstruction,
    this.ranking,
    this.samplingMonth,
    this.decisionMonth,
    this.purchaseMode,
    this.approvedContactsUpdate,
    this.approvedContactsNew,
    this.schoolFacility,
  });

  SchoolUpdateModel.fromJson(dynamic json) {
    customerId = json['CustomerId'];
    customerType = json['CustomerType'];
    customerName = json['CustomerName'];
    refCode = json['RefCode'];
    address = json['Address'];
    cityId = json['CityId'];
    districtId = json['DistrictId'];
    stateId = json['StateId'];
    countryId = json['CountryId'];
    pincode = json['Pincode'];
    emailId = json['EmailId'];
    mobile = json['Mobile'];
    keyCustomer = json['KeyCustomer'];
    customerStatus = json['CustomerStatus'];
    xmlCustomerCategoryId = json['xmlCustomerCategoryId'];
    xmlAccountTableExecutiveId = json['xmlAccountTableExecutiveId'];
    primaryContact = json['PrimaryContact'];
    contactStatus = json['ContactStatus'];
    salutationId = json['SalutationId'];
    contactDesignationId = json['ContactDesignationId'];
    comment = json['Comment'];
    firstName = json['FirstName'];
    lastName = json['LastName'];
    contactEmailId = json['ContactEmailId'];
    contactMobile = json['ContactMobile'];
    resAddress = json['resAddress'];
    resCity = json['resCity'];
    resDistrict = json['resDistrict'];
    resState = json['resState'];
    resCountry = json['resCountry'];
    resPincode = json['resPincode'];
    birthDay = json['BirthDay'];
    anniversary = json['Anniversary'];
    pANNumber = json['PANNumber'];
    gSTNumber = json['GSTNumber'];
    enteredBy = json['EnteredBy'];
    approvedCustomerMasterNew = json['ApprovedCustomerMasterNew'];
    approvedCustomerMasterUpdate = json['ApprovedCustomerMasterUpdate'];
    adoptionRoleId = json['AdoptionRoleId'];
    departmentId = json['DepartmentId'];
    latEntry = json['latEntry'];
    longEntry = json['longEntry'];
    dataSourceId = json['DataSourceId'];
    xmlClassName = json['xmlClassName'];
    xmlSubjectClassDM = json['xmlSubjectClassDM'];
    boardId = json['BoardId'];
    chainSchoolId = json['ChainSchoolId'];
    startClassId = json['StartClassId'];
    endClassId = json['EndClassId'];
    mediumInstruction = json['MediumInstruction'];
    ranking = json['Ranking'];
    samplingMonth = json['SamplingMonth'];
    decisionMonth = json['DecisionMonth'];
    purchaseMode = json['PurchaseMode'];
    approvedContactsUpdate = json['ApprovedContactsUpdate'];
    approvedContactsNew = json['ApprovedContactsNew'];
    schoolFacility = json['SchoolFacility'];
  }
  int? customerId;
  String? customerType;
  String? customerName;
  String? refCode;
  String? address;
  int? cityId;
  int? districtId;
  int? stateId;
  int? countryId;
  String? pincode;
  String? emailId;
  String? mobile;
  String? keyCustomer;
  String? customerStatus;
  String? xmlCustomerCategoryId;
  String? xmlAccountTableExecutiveId;
  String? primaryContact;
  String? contactStatus;
  int? salutationId;
  int? contactDesignationId;
  String? comment;
  String? firstName;
  String? lastName;
  String? contactEmailId;
  String? contactMobile;
  String? resAddress;
  int? resCity;
  int? resDistrict;
  int? resState;
  int? resCountry;
  String? resPincode;
  String? birthDay;
  String? anniversary;
  String? pANNumber;
  String? gSTNumber;
  int? enteredBy;
  String? approvedCustomerMasterNew;
  String? approvedCustomerMasterUpdate;
  int? adoptionRoleId;
  int? departmentId;
  String? latEntry;
  String? longEntry;
  int? dataSourceId;
  String? xmlClassName;
  String? xmlSubjectClassDM;
  int? boardId;
  int? chainSchoolId;
  int? startClassId;
  int? endClassId;
  String? mediumInstruction;
  String? ranking;
  int? samplingMonth;
  int? decisionMonth;
  String? purchaseMode;
  String? approvedContactsUpdate;
  String? approvedContactsNew;
  String? schoolFacility;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['CustomerId'] = customerId;
    map['CustomerType'] = customerType;
    map['CustomerName'] = customerName;
    map['RefCode'] = refCode;
    map['Address'] = address;
    map['CityId'] = cityId;
    map['DistrictId'] = districtId;
    map['StateId'] = stateId;
    map['CountryId'] = countryId;
    map['Pincode'] = pincode;
    map['EmailId'] = emailId;
    map['Mobile'] = mobile;
    map['KeyCustomer'] = keyCustomer;
    map['CustomerStatus'] = customerStatus;
    map['xmlCustomerCategoryId'] = xmlCustomerCategoryId;
    map['xmlAccountTableExecutiveId'] = xmlAccountTableExecutiveId;
    map['PrimaryContact'] = primaryContact;
    map['ContactStatus'] = contactStatus;
    map['SalutationId'] = salutationId;
    map['ContactDesignationId'] = contactDesignationId;
    map['Comment'] = comment;
    map['FirstName'] = firstName;
    map['LastName'] = lastName;
    map['ContactEmailId'] = contactEmailId;
    map['ContactMobile'] = contactMobile;
    map['resAddress'] = resAddress;
    map['resCity'] = resCity;
    map['resDistrict'] = resDistrict;
    map['resState'] = resState;
    map['resCountry'] = resCountry;
    map['resPincode'] = resPincode;
    map['BirthDay'] = birthDay;
    map['Anniversary'] = anniversary;
    map['PANNumber'] = pANNumber;
    map['GSTNumber'] = gSTNumber;
    map['EnteredBy'] = enteredBy;
    map['ApprovedCustomerMasterNew'] = approvedCustomerMasterNew;
    map['ApprovedCustomerMasterUpdate'] = approvedCustomerMasterUpdate;
    map['AdoptionRoleId'] = adoptionRoleId;
    map['DepartmentId'] = departmentId;
    map['latEntry'] = latEntry;
    map['longEntry'] = longEntry;
    map['DataSourceId'] = dataSourceId;
    map['xmlClassName'] = xmlClassName;
    map['xmlSubjectClassDM'] = xmlSubjectClassDM;
    map['BoardId'] = boardId;
    map['ChainSchoolId'] = chainSchoolId;
    map['StartClassId'] = startClassId;
    map['EndClassId'] = endClassId;
    map['MediumInstruction'] = mediumInstruction;
    map['Ranking'] = ranking;
    map['SamplingMonth'] = samplingMonth;
    map['DecisionMonth'] = decisionMonth;
    map['PurchaseMode'] = purchaseMode;
    map['ApprovedContactsUpdate'] = approvedContactsUpdate;
    map['ApprovedContactsNew'] = approvedContactsNew;
    map['SchoolFacility'] = schoolFacility;
    return map;
  }
}
