class GeographyModel {
  GeographyModel({
    this.countryId,
    this.country,
    this.stateId,
    this.state,
    this.districtId,
    this.district,
    this.cityId,
    this.city,
  });

  GeographyModel.fromJson(dynamic json) {
    countryId = json['CountryId'];
    country = json['Country'];
    stateId = json['StateId'];
    state = json['State'];
    districtId = json['DistrictId'];
    district = json['District'];
    cityId = json['CityId'];
    city = json['City'];
  }
  int? countryId;
  String? country;
  int? stateId;
  String? state;
  int? districtId;
  String? district;
  int? cityId;
  String? city;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['CountryId'] = countryId;
    map['Country'] = country;
    map['StateId'] = stateId;
    map['State'] = state;
    map['DistrictId'] = districtId;
    map['District'] = district;
    map['CityId'] = cityId;
    map['City'] = city;
    return map;
  }
}
