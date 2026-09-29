class CityPincodeResponse {
  final double cityId;
  final String cityName;
  final double districtId;
  final String districtName;
  final double stateId;
  final String stateName;
  final double countryId;
  final String countryName;

  CityPincodeResponse({
    required this.cityId,
    required this.cityName,
    required this.districtId,
    required this.districtName,
    required this.stateId,
    required this.stateName,
    required this.countryId,
    required this.countryName,
  });

  factory CityPincodeResponse.fromJson(Map<String, dynamic> json) {
    return CityPincodeResponse(
      cityId: (json['CityId'] as num).toDouble(),
      cityName: json['CityName'] as String,
      districtId: (json['DistrictId'] as num).toDouble(),
      districtName: json['DistrictName'] as String,
      stateId: (json['StateId'] as num).toDouble(),
      stateName: json['StateName'] as String,
      countryId: (json['CountryId'] as num).toDouble(),
      countryName: json['CountryName'] as String,
    );
  }
}
