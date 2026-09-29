class Months {
  Months({
    this.id,
    this.name,
  });

  Months.fromJson(dynamic json) {
    id = json['ID'];
    name = json['Name'];
  }
  int? id;
  String? name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ID'] = id;
    map['Name'] = name;
    return map;
  }
}
