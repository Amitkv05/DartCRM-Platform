class GeographyItem {
  final int countryId;
  final String country;
  final int stateId;
  final String state;
  final int districtId;
  final String district;
  final int cityId;
  final String city;

  GeographyItem({
    required this.countryId,
    required this.country,
    required this.stateId,
    required this.state,
    required this.districtId,
    required this.district,
    required this.cityId,
    required this.city,
  });

  factory GeographyItem.fromJson(Map<String, dynamic> json) {
    return GeographyItem(
      countryId: json['CountryId'] as int? ?? 0,
      country: json['Country'] as String? ?? '',
      stateId: json['StateId'] as int? ?? 0,
      state: json['State'] as String? ?? '',
      districtId: json['DistrictId'] as int? ?? 0,
      district: json['District'] as String? ?? '',
      cityId: json['CityId'] as int? ?? 0,
      city: json['City'] as String? ?? '',
    );
  }
}

class GeographyResponse {
  final String status;
  final List<GeographyItem> geography;

  GeographyResponse({
    required this.status,
    required this.geography,
  });

  factory GeographyResponse.fromJson(Map<String, dynamic> json) {
    return GeographyResponse(
      status: json['Status'] as String? ?? '',
      geography: (json['Geography'] as List<dynamic>? ?? [])
          .map((item) => GeographyItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
