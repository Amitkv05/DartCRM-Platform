class AccountableExecutive {
  AccountableExecutive({
    this.sNo,
    this.executiveName,
  });

  AccountableExecutive.fromJson(dynamic json) {
    sNo = json['SNo'];
    executiveName = json['ExecutiveName'];
  }
  int? sNo;
  String? executiveName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['SNo'] = sNo;
    map['ExecutiveName'] = executiveName;
    return map;
  }
}
