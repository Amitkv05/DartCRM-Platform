class AffiliateType {
  AffiliateType({
    this.id,
    this.affiliateType,
  });

  AffiliateType.fromJson(dynamic json) {
    id = json['ID'];
    affiliateType = json['AffiliateType'];
  }
  String? id;
  String? affiliateType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ID'] = id;
    map['AffiliateType'] = affiliateType;
    return map;
  }
}
