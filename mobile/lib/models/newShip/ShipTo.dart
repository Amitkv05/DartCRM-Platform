class dsrShipTo {
  dsrShipTo({this.resAddress, this.officeAddress});

  dsrShipTo.fromJson(dynamic json) {
    resAddress = (json['ResAddress'] ?? json['residentialAddress'])?.toString();
    officeAddress = (json['OfficeAddress'] ?? json['officeAddress'])?.toString();
  }

  String? resAddress;
  String? officeAddress;

  Map<String, dynamic> toJson() => {
        'ResAddress': resAddress,
        'OfficeAddress': officeAddress,
      };
}
