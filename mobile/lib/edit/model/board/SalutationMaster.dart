class SalutationMaster {
  SalutationMaster({
    this.salutationId,
    this.salutationName,
  });

  SalutationMaster.fromJson(dynamic json) {
    salutationId = json['SalutationId'];
    salutationName = json['SalutationName'];
  }
  int? salutationId;
  String? salutationName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['SalutationId'] = salutationId;
    map['SalutationName'] = salutationName;
    return map;
  }
}
