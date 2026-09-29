class PincodeRequest {
  PincodeRequest({
    this.pinCode,
    this.cityId,
    this.executiveId,
    this.cityAccess,
  });

  PincodeRequest.fromJson(dynamic json) {
    pinCode = json['PinCode'];
    cityId = json['CityId'];
    executiveId = json['ExecutiveId'];
    cityAccess = json['CityAccess'];
  }
  String? pinCode;
  String? cityId;
  String? executiveId;
  String? cityAccess;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['PinCode'] = pinCode;
    map['CityId'] = cityId;
    map['ExecutiveId'] = executiveId;
    map['CityAccess'] = cityAccess;
    return map;
  }
}
