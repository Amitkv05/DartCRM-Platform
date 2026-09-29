import 'GeographyModel.dart';

class GeoResponse {
  GeoResponse({
    this.status,
    this.geography,
  });

  GeoResponse.fromJson(dynamic json) {
    status = json['Status'];
    if (json['Geography'] != null) {
      geography = [];
      json['Geography'].forEach((v) {
        geography?.add(GeographyModel.fromJson(v));
      });
    }
  }

  String? status;
  List<GeographyModel>? geography;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['Status'] = status;
    if (geography != null) {
      map['Geography'] = geography?.map((v) => v.toJson()).toList();
    }

    return map;
  }
}
