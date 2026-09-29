class SchoolDetailsNew {
  SchoolDetailsNew({
    this.schoolId,
    this.schoolName,
    this.refCode,
    this.schoolCode,
    this.address,
    this.cityId,
    this.stateId,
    this.districtId,
    this.countryId,
    this.validationStatus,
    this.emailId,
    this.mobile,
    this.keyCustomer,
    this.customerStatus,
    this.pincode,
    this.latEntry,
    this.longEntry,
    this.startClassId,
    this.endClassId,
    this.boardId,
    this.chainSchoolId,
    this.mediumInstruction,
    this.ranking,
    this.samplingMonth,
    this.decisionMonth,
    this.purchaseMode,
    this.bookSeller1,
    this.bookSeller2,
    this.xmlAccountTableExecutiveId,
    this.msgWarning,
    this.existence,
    this.panNumber,
    this.gstNumber,
    this.averageFee,
    this.xmlCustomerCategoryId,
    this.customerName,
    this.customerId,
    this.customerCode,
  });

  SchoolDetailsNew.fromJson(dynamic json) {
    schoolId = json['SchoolId'];
    schoolName = json['SchoolName'];
    refCode = json['RefCode'];
    schoolCode = json['SchoolCode'];
    address = json['Address'];
    validationStatus = json['ValidationStatus'];
    emailId = json['EmailId'];
    mobile = json['Mobile'];
    keyCustomer = json['KeyCustomer'];
    customerStatus = json['CustomerStatus'];
    pincode = json['Pincode'];
    latEntry = json['LatEntry'];
    longEntry = json['longEntry'];
    startClassId = json['StartClassId'];
    endClassId = json['EndClassId'];
    boardId = json['BoardId'];
    chainSchoolId = json['ChainSchoolId'];
    mediumInstruction = json['MediumInstruction'];
    ranking = json['Ranking'];
    samplingMonth = json['SamplingMonth'];
    decisionMonth = json['DecisionMonth'];
    purchaseMode = json['PurchaseMode'];
    bookSeller1 = json['BookSeller1'];
    bookSeller2 = json['BookSeller2'];
    xmlAccountTableExecutiveId = json['xmlAccountTableExecutiveId'];

    msgWarning = json['MsgWarning'];
    existence = json['Existence'];
    panNumber = json['PanNumber'];
    gstNumber = json['GstNumber'];
    averageFee = json['AverageFee'];
    xmlCustomerCategoryId = json['xmlCustomerCategoryId'];

    customerName = json['CustomerName'];
    customerId = json['CustomerId'];
    customerCode = json['CustomerCode'];

    try {
      var d = json['CityId'];
      if (d is int) {
        cityId = d.toDouble();
        stateId = json['StateId']?.toDouble();
        districtId = json['DistrictId']?.toDouble();
        countryId = json['CountryId']?.toDouble();
      } else {
        cityId = json['CityId'];
        stateId = json['StateId'];
        districtId = json['DistrictId'];
        countryId = json['CountryId'];
      }
    } catch (e) {}
  }

  int? schoolId;
  String? schoolName;
  String? refCode;
  String? schoolCode;
  String? address;
  double? cityId;
  double? stateId;
  double? districtId;
  double? countryId;
  String? validationStatus;
  String? emailId;
  String? mobile;
  String? keyCustomer;
  String? customerStatus;
  String? pincode;
  String? latEntry;
  String? longEntry;
  int? startClassId;
  int? endClassId;
  int? boardId;
  int? chainSchoolId;
  String? mediumInstruction;
  String? ranking;
  int? samplingMonth;
  int? decisionMonth;
  String? purchaseMode;
  int? bookSeller1;
  int? bookSeller2;
  String? xmlAccountTableExecutiveId;
  String? msgWarning;
  int? existence;
  String? panNumber;
  String? gstNumber;
  int? averageFee;
  String? xmlCustomerCategoryId;
  String? customerName;
  int? customerId;
  String? customerCode;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['SchoolId'] = schoolId;
    map['SchoolName'] = schoolName;
    map['RefCode'] = refCode;
    map['SchoolCode'] = schoolCode;
    map['Address'] = address;
    map['CityId'] = cityId;
    map['StateId'] = stateId;
    map['DistrictId'] = districtId;
    map['CountryId'] = countryId;
    map['ValidationStatus'] = validationStatus;
    map['EmailId'] = emailId;
    map['Mobile'] = mobile;
    map['KeyCustomer'] = keyCustomer;
    map['CustomerStatus'] = customerStatus;
    map['Pincode'] = pincode;
    map['LatEntry'] = latEntry;
    map['longEntry'] = longEntry;
    map['StartClassId'] = startClassId;
    map['EndClassId'] = endClassId;
    map['BoardId'] = boardId;
    map['ChainSchoolId'] = chainSchoolId;
    map['MediumInstruction'] = mediumInstruction;
    map['Ranking'] = ranking;
    map['SamplingMonth'] = samplingMonth;
    map['DecisionMonth'] = decisionMonth;
    map['PurchaseMode'] = purchaseMode;
    map['BookSeller1'] = bookSeller1;
    map['BookSeller2'] = bookSeller2;
    map['xmlAccountTableExecutiveId'] = xmlAccountTableExecutiveId;
    map['MsgWarning'] = msgWarning;
    map['Existence'] = existence;
    map['PanNumber'] = panNumber;
    map['GstNumber'] = gstNumber;
    map['AverageFee'] = averageFee;
    map['xmlCustomerCategoryId'] = xmlCustomerCategoryId;

    map['CustomerName'] = customerName;
    map['CustomerCode'] = customerCode;
    map['CustomerId'] = customerId;

    return map;
  }
}
