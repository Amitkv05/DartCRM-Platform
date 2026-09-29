import 'package:flutter/cupertino.dart';

class EnrolmentList {
  EnrolmentList({
    this.classNumId,
    this.className,
    this.enrolValue,
    this.totalEnrolment,
  });

  EnrolmentList.fromJson(dynamic json) {
    classNumId = json['ClassNumId'];
    className = json['ClassName'];
    enrolValue = json['EnrolValue'];
    totalEnrolment = json['TotalEnrolment'];
  }
  int? classNumId;
  String? className;
  int? enrolValue;
  int? totalEnrolment;
  TextEditingController editingController = TextEditingController();
  bool? readOnly;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ClassNumId'] = classNumId;
    map['ClassName'] = className;
    map['EnrolValue'] = enrolValue;
    map['TotalEnrolment'] = totalEnrolment;
    return map;
  }
}
