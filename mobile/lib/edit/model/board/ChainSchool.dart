class ChainSchool {
  ChainSchool({
    this.chainSchoolId,
    this.chainSchoolName,
  });

  ChainSchool.fromJson(dynamic json) {
    chainSchoolId = json['ChainSchoolId'];
    chainSchoolName = json['ChainSchoolName'];
  }
  int? chainSchoolId;
  String? chainSchoolName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ChainSchoolId'] = chainSchoolId;
    map['ChainSchoolName'] = chainSchoolName;
    return map;
  }
}
