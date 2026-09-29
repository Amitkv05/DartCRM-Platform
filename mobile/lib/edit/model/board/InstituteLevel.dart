class InstituteLevel {
  InstituteLevel({
    this.id,
    this.instituteLevel,
  });

  InstituteLevel.fromJson(dynamic json) {
    id = json['ID'];
    instituteLevel = json['InstituteLevel'];
  }
  String? id;
  String? instituteLevel;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ID'] = id;
    map['InstituteLevel'] = instituteLevel;
    return map;
  }
}
