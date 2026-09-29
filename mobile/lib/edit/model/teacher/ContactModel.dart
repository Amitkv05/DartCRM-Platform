class ContactModel {
  ContactModel({
    this.sNo,
    this.contactName,
    this.designation,
    this.mobile,
    this.email,
    this.primaryContact,
    this.validationStatus,
    this.edit,
    this.delete,
  });

  ContactModel.fromJson(dynamic json) {
    sNo = json['SNo'];
    contactName = json['ContactName'];
    designation = json['Designation'];
    mobile = json['Mobile'];
    email = json['Email'];
    primaryContact = json['PrimaryContact'];
    validationStatus = json['ValidationStatus'];
    edit = json['Edit'];
    delete = json['Delete'];
  }
  int? sNo;
  String? contactName;
  String? designation;
  String? mobile;
  String? email;
  String? primaryContact;
  String? validationStatus;
  String? edit;
  String? delete;
  int? salutationId;
  int? contactDesignationId;
  String? address;
  String? pincode;
  int? dataSourceId;
  int? resCity;
  String? contactStatus;
  String? birthDay;
  String? anniversary;

  double? countryId;
  double? stateId;
  double? districtId;
  double? cityId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['SNo'] = sNo;
    map['ContactName'] = contactName;
    map['Designation'] = designation;
    map['Mobile'] = mobile;
    map['Email'] = email;
    map['PrimaryContact'] = primaryContact;
    map['ValidationStatus'] = validationStatus;
    map['Edit'] = edit;
    map['Delete'] = delete;
    return map;
  }
}
