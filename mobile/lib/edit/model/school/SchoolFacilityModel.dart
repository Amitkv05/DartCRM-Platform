class SchoolFacilityModel {
  SchoolFacilityModel({
    this.customerFacilityId,
    this.customerFacilityName,
    this.facilityAvailable,
  });

  SchoolFacilityModel.fromJson(dynamic json) {
    customerFacilityId = json['CustomerFacilityId'];
    customerFacilityName = json['CustomerFacilityName'];
    facilityAvailable = json['FacilityAvailable'];
  }

  int? customerFacilityId;
  String? customerFacilityName;
  String? facilityAvailable;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['CustomerFacilityId'] = customerFacilityId;
    map['CustomerFacilityName'] = customerFacilityName;
    map['FacilityAvailable'] = facilityAvailable;
    return map;
  }
}
