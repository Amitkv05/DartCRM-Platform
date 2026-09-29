import 'SchoolContactDetails.dart';
import 'TeacherSubjectsList.dart';

class ContactDetailResponse {
  ContactDetailResponse({
    this.status,
    this.schoolContactDetails,
    this.teacherSubjects,
  });

  ContactDetailResponse.fromJson(dynamic json) {
    status = json['Status'];
    if (json['SchoolContactDetails'] != null) {
      schoolContactDetails = [];
      json['SchoolContactDetails'].forEach((v) {
        schoolContactDetails?.add(SchoolContactDetails.fromJson(v));
      });
    }
    if (json['CustomerContactDetails'] != null) {
      schoolContactDetails = [];
      json['CustomerContactDetails'].forEach((v) {
        schoolContactDetails?.add(SchoolContactDetails.fromJson(v));
      });
    }
    if (json['TeacherSubjects'] != null) {
      teacherSubjects = [];
      json['TeacherSubjects'].forEach((v) {
        teacherSubjects?.add(TeacherSubjects.fromJson(v));
      });
    }
  }

  String? status;
  List<SchoolContactDetails>? schoolContactDetails;
  List<TeacherSubjects>? teacherSubjects;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['Status'] = status;
    if (schoolContactDetails != null) {
      map['SchoolContactDetails'] =
          schoolContactDetails?.map((v) => v.toJson()).toList();
    }
    if (teacherSubjects != null) {
      map['TeacherSubjects'] = teacherSubjects?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
