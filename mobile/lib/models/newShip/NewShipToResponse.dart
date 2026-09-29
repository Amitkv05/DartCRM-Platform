import 'ShipTo.dart';

class NewShipToResponse {
  NewShipToResponse({this.status, this.dsrshipTo});

  NewShipToResponse.fromJson(dynamic json) {
    final rawStatus = (json['Status'] ?? json['status'] ?? 'error').toString();
    status = rawStatus.toLowerCase() == 'success' ? 'Success' : rawStatus;
    dsrshipTo = [];
    final raw = json['ShipTo'] ?? json['shipTo'];
    if (raw is List) {
      for (final value in raw) {
        if (value is Map) {
          dsrshipTo?.add(dsrShipTo.fromJson(Map<String, dynamic>.from(value)));
        }
      }
    } else if (raw is Map) {
      dsrshipTo?.add(dsrShipTo.fromJson({
        'ResAddress': raw['residentialAddress'] ?? raw['ResAddress'],
        'OfficeAddress': raw['officeAddress'] ?? raw['OfficeAddress'],
      }));
    }
  }

  String? status;
  List<dsrShipTo>? dsrshipTo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'Status': status};
    if (dsrshipTo != null) {
      map['ShipTo'] = dsrshipTo?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
