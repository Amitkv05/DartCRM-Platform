class CustomerContactRequest {
  final String customerType;
  final String primaryContact;
  final int salutationId;
  final int contactDesignationId;
  final String firstName;
  final String lastName;
  final String contactEmailId;
  final String contactMobile;
  final String contactStatus;
  final int enteredBy;
  final int customerId;
  final String validated;
  final String? resAddress;
  final int? resCity;
  final String? resPincode;
  final String? birthDay;
  final String? anniversary;
  final String? customerContactId;
  final String? xmlSubjectClassDM;
  final int? dataSourceId;

  CustomerContactRequest({
    required this.customerType,
    required this.primaryContact,
    required this.salutationId,
    required this.contactDesignationId,
    required this.firstName,
    required this.lastName,
    required this.contactEmailId,
    required this.contactMobile,
    required this.contactStatus,
    required this.enteredBy,
    required this.customerId,
    required this.validated,
    this.resAddress,
    this.resCity,
    this.resPincode,
    this.birthDay,
    this.anniversary,
    this.customerContactId,
    this.xmlSubjectClassDM,
    this.dataSourceId,
  });

  Map<String, dynamic> toJson() => {
        'CustomerType': customerType,
        'PrimaryContact': primaryContact,
        'SalutationId': salutationId,
        'ContactDesignationId': contactDesignationId,
        'FirstName': firstName,
        'LastName': lastName,
        'ContactEmailId': contactEmailId,
        'ContactMobile': contactMobile,
        'ContactStatus': contactStatus,
        'EnteredBy': enteredBy,
        'CustomerId': customerId,
        'Validated': validated,
        if (resAddress != null) 'resAddress': resAddress,
        if (resCity != null) 'resCity': resCity,
        if (resPincode != null) 'resPincode': resPincode,
        if (birthDay != null) 'BirthDay': birthDay,
        if (anniversary != null) 'Anniversary': anniversary,
        if (customerContactId != null) 'CustomerContactId': customerContactId,
        if (xmlSubjectClassDM != null) 'xmlSubjectClassDM': xmlSubjectClassDM,
        if (dataSourceId != null) 'DataSourceId': dataSourceId,
      };
}

class CustomerContactResponse {
  final String status;
  final String s;
  final List<dynamic> contactsEntry;

  CustomerContactResponse(
      {required this.status, required this.s, required this.contactsEntry});

  factory CustomerContactResponse.fromJson(Map<String, dynamic> json) =>
      CustomerContactResponse(
        status: json['Status'],
        s: json['s'],
        contactsEntry: json['ContactsEntry'],
      );
}
