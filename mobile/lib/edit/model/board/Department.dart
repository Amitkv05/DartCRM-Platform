class Department {
  Department({
    this.departmentId,
    this.departmentName,
  });

  Department.fromJson(dynamic json) {
    departmentId = json['DepartmentId'];
    departmentName = json['DepartmentName'];
  }
  int? departmentId;
  String? departmentName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['DepartmentId'] = departmentId;
    map['DepartmentName'] = departmentName;
    return map;
  }
}
