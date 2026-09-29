import 'package:dart_crm/edit/model/seller/BookSellerData.dart';

import 'EnrolmentList.dart';
import 'SchoolDetailsNew.dart';
import 'CommentsModel.dart';
import 'SchoolFacilityModel.dart';

class SchoolListResponse {
  SchoolListResponse(
      {this.status,
      this.schoolDetails,
      this.bookSellerList,
      this.enrolmentList,
      this.comments,
      this.list,
      this.customerDetails,
      this.schoolFacility});

  SchoolListResponse.fromJson(dynamic json) {
    status = json['Status'];
    if (json['SchoolDetails'] != null) {
      schoolDetails = [];
      json['SchoolDetails'].forEach((v) {
        schoolDetails?.add(SchoolDetailsNew.fromJson(v));
      });
    }
    if (json['BookSellerList'] != null) {
      bookSellerList = [];
      json['BookSellerList'].forEach((v) {
        bookSellerList?.add(BookSellerData.fromJson(v));
      });
    }
    if (json['EnrolmentList'] != null) {
      enrolmentList = [];
      json['EnrolmentList'].forEach((v) {
        enrolmentList?.add(EnrolmentList.fromJson(v));
      });
    }

    if (json['CustomerDetails'] != null) {
      customerDetails = [];
      json['CustomerDetails'].forEach((v) {
        customerDetails?.add(SchoolDetailsNew.fromJson(v));
      });
    }

    if (json['SchoolFacility'] != null) {
      schoolFacility = [];
      json['SchoolFacility'].forEach((v) {
        schoolFacility?.add(SchoolFacilityModel.fromJson(v));
      });
    }
    if (json['Comments'] != null) {
      comments = [];
      json['Comments'].forEach((v) {
        comments?.add(CommentsModel.fromJson(v));
      });
    }
  }

  String? status;
  List<SchoolDetailsNew>? schoolDetails;
  List<SchoolDetailsNew>? customerDetails;
  List<BookSellerData>? bookSellerList;
  List<EnrolmentList>? enrolmentList;
  List<SchoolFacilityModel>? schoolFacility;
  List<CommentsModel>? comments;

  List<dynamic>? list;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['Status'] = status;
    if (schoolDetails != null) {
      map['SchoolDetails'] = schoolDetails?.map((v) => v.toJson()).toList();
    }
    if (customerDetails != null) {
      map['CustomerDetails'] = customerDetails?.map((v) => v.toJson()).toList();
    }
    if (bookSellerList != null) {
      map['BookSellerList'] = bookSellerList?.map((v) => v.toJson()).toList();
    }
    if (enrolmentList != null) {
      map['EnrolmentList'] = enrolmentList?.map((v) => v.toJson()).toList();
    }
    if (comments != null) {
      map['Comments'] = comments?.map((v) => v.toJson()).toList();
    }
    if (list != null) {
      map['List'] = list?.map((v) => v.toJson()).toList();
    }

    if (schoolFacility != null) {
      map['SchoolFacility'] = schoolFacility?.map((v) => v.toJson()).toList();
    }
    if (comments != null) {
      map['Comments'] = comments?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
