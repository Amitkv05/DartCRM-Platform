class TeacherSubjects {
  int? subjectId;
  String? subjectName;
  String? decisionId;
  String? decisionValue;
  List<String>? classNumId;
  List<String>? classNames;

  TeacherSubjects(
      {this.subjectId,
      this.subjectName,
      this.decisionId,
      this.decisionValue,
      this.classNumId,
      this.classNames});

  TeacherSubjects.fromJson(Map<String, dynamic> json) {
    subjectId = json['SubjectId'];
    subjectName = json['SubjectName'];
    decisionId = json['DecisionId'];
    decisionValue = json['DecisionValue'];
    classNumId = json['ClassNumId'].cast<String>();
    classNames = json['ClassNames'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['SubjectId'] = this.subjectId;
    data['SubjectName'] = this.subjectName;
    data['DecisionId'] = this.decisionId;
    data['DecisionValue'] = this.decisionValue;
    data['ClassNumId'] = this.classNumId;
    data['ClassNames'] = this.classNames;
    return data;
  }
}
