class CustomerDetailsRequest {
  final int customerId;
  final String customerType;
  final String validated;

  CustomerDetailsRequest(
      {required this.customerId,
      required this.customerType,
      required this.validated});

  Map<String, dynamic> toJson() => {
        'CustomerId': customerId,
        'CustomerType': customerType,
        'Validated': validated,
      };
}

class CustomerDetailsResponse {
  final String status;
  final List<SchoolDetails>? schoolDetails;
  final List<BookSeller>? bookSellerList;

  CustomerDetailsResponse(
      {required this.status, this.schoolDetails, this.bookSellerList});

  factory CustomerDetailsResponse.fromJson(Map<String, dynamic> json) =>
      CustomerDetailsResponse(
        status: json['Status'],
        schoolDetails: json['SchoolDetails'] != null
            ? (json['SchoolDetails'] as List)
                .map((e) => SchoolDetails.fromJson(e))
                .toList()
            : null,
        bookSellerList: json['BookSellerList'] != null
            ? (json['BookSellerList'] as List)
                .map((e) => BookSeller.fromJson(e))
                .toList()
            : null,
      );
}

class SchoolDetails {
  final int schoolId;
  final String schoolName;
  final String schoolCode;
  final String address;
  final double? cityId;
  final double? stateId;
  final double? countryId;
  final String validationStatus;

  SchoolDetails({
    required this.schoolId,
    required this.schoolName,
    required this.schoolCode,
    required this.address,
    this.cityId,
    this.stateId,
    this.countryId,
    required this.validationStatus,
  });

  factory SchoolDetails.fromJson(Map<String, dynamic> json) => SchoolDetails(
        schoolId: json['SchoolId'],
        schoolName: json['SchoolName'],
        schoolCode: json['SchoolCode'],
        address: json['Address'],
        cityId: json['CityId']?.toDouble(),
        stateId: json['StateId']?.toDouble(),
        countryId: json['CountryId']?.toDouble(),
        validationStatus: json['ValidationStatus'],
      );
}

class BookSeller {
  final int sNo;
  final String bookSellerName;
  final String address;
  final String city;
  final String state;
  final String country;

  BookSeller({
    required this.sNo,
    required this.bookSellerName,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
  });

  factory BookSeller.fromJson(Map<String, dynamic> json) => BookSeller(
        sNo: json['SNo'],
        bookSellerName: json['BookSellerName'],
        address: json['Address'],
        city: json['City'],
        state: json['State'],
        country: json['Country'],
      );
}
