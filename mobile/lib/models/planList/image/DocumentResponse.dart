import 'ReturnDetails.dart';

class DocumentResponse {
  DocumentResponse({
    this.status,
    this.returnDetails,
  });

  DocumentResponse.fromJson(dynamic json) {
    status = json['Status'];
    if (json['ReturnDetails'] != null) {
      returnDetails = [];
      json['ReturnDetails'].forEach((v) {
        returnDetails?.add(ReturnDetails.fromJson(v));
      });
    }
  }

  String? status;
  List<ReturnDetails>? returnDetails;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['Status'] = status;
    if (returnDetails != null) {
      map['ReturnDetails'] = returnDetails?.map((v) => v.toJson()).toList();
    }

    return map;
  }
}
