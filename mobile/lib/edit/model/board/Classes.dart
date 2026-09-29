class Classes {
  Classes({
    this.classNumId,
    this.className,
  });

  Classes.fromJson(dynamic json) {
    classNumId = json['ClassNumId'];
    className = json['ClassName'];
  }
  int? classNumId;
  String? className;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ClassNumId'] = classNumId;
    map['ClassName'] = className;
    return map;
  }
}
