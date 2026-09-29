class BookSellerData {
  BookSellerData({
    this.sNo,
    this.bookSellerName,
    this.address,
    this.city,
    this.state,
    this.country,
    this.action,
  });

  BookSellerData.fromJson(dynamic json) {
    sNo = json['SNo']?.toString();
    bookSellerName = json['BookSellerName']?.toString();
    address = json['Address']?.toString();
    city = json['City']?.toString();
    state = json['State']?.toString();
    country = json['Country']?.toString();
    action = int.tryParse((json['Action'] ?? '').toString());
  }

  String? sNo;
  String? bookSellerName;
  String? address;
  String? city;
  String? state;
  String? country;
  int? action;
  bool isSelected = false;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['SNo'] = sNo;
    map['BookSellerName'] = bookSellerName;
    map['Address'] = address;
    map['City'] = city;
    map['State'] = state;
    map['Country'] = country;
    map['Action'] = action;
    return map;
  }
}
