class InstituteType {
  InstituteType({
    this.id,
    this.instituteType,
  });

  InstituteType.fromJson(dynamic json) {
    id = json['ID'];
    instituteType = json['InstituteType'];
  }
  String? id;
  String? instituteType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ID'] = id;
    map['InstituteType'] = instituteType;
    return map;
  }
}
