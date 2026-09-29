class BookSellerRequest {
  BookSellerRequest(
      {this.bookSellerName,
      this.bookSellerCode,
      this.countryId,
      this.stateId,
      this.districtId,
      this.cityId,
      this.regionId,
      this.areaId,
      this.territoryId,
      this.downHierarchy,
      this.territoryAccess,
      this.loggedInExecutiveId});

  BookSellerRequest.fromJson(dynamic json) {
    bookSellerName = json['BookSellerName'];
    bookSellerCode = json['BookSellerCode'];
    countryId = json['CountryId'];
    stateId = json['StateId'];
    districtId = json['DistrictId'];
    cityId = json['CityId'];
    regionId = json['RegionId'];
    areaId = json['AreaId'];
    territoryId = json['TerritoryId'];
    downHierarchy = json['downHierarchy'];
    territoryAccess = json['territoryAccess'];
    loggedInExecutiveId = json['loggedInExecutiveId'];
  }

  String? bookSellerName;
  String? bookSellerCode;
  int? countryId;
  int? stateId;
  int? districtId;
  int? cityId;
  String? regionId;
  String? areaId;
  String? territoryId;
  String? downHierarchy;
  String? territoryAccess;
  String? loggedInExecutiveId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['BookSellerName'] = bookSellerName;
    map['BookSellerCode'] = bookSellerCode;
    map['CountryId'] = countryId;
    map['StateId'] = stateId;
    map['DistrictId'] = districtId;
    map['CityId'] = cityId;
    map['RegionId'] = regionId;
    map['AreaId'] = areaId;
    map['TerritoryId'] = territoryId;
    map['downHierarchy'] = downHierarchy;
    map['territoryAccess'] = territoryAccess;
    map['loggedInExecutiveId'] = loggedInExecutiveId;

    return map;
  }
}
