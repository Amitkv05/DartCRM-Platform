class Subject {
  Subject({
    this.subjectId,
    this.subjectName,
  });

  Subject.fromJson(dynamic json) {
    subjectId = json['SubjectId'];
    subjectName = json['SubjectName'];
  }
  int? subjectId;
  String? subjectName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['SubjectId'] = subjectId;
    map['SubjectName'] = subjectName;
    return map;
  }
}
