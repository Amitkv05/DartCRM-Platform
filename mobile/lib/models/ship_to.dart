class ShipToRequest {
  final int customerId;
  final String customerType;
  final int customerContactId;
  final String? sampleGiven;
  final int executiveId;

  ShipToRequest({
    required this.customerId,
    required this.customerType,
    required this.customerContactId,
    this.sampleGiven,
    required this.executiveId,
  });

  Map<String, dynamic> toJson() => {
        'CustomerId': customerId,
        'CustomerType': customerType,
        'CustomerContactId': customerContactId,
        'SampleGiven': sampleGiven,
        'ExecutiveId': executiveId,
      };
}

class ShipToResponse {
  final String status;
  final List<ShipTo> shipTo;

  ShipToResponse({required this.status, required this.shipTo});

  factory ShipToResponse.fromJson(Map<String, dynamic> json) {
    final shipToList = <ShipTo>[];
    final raw = json['ShipTo'] ?? json['shipTo'];

    // Legacy API shape: ShipTo: [{ResAddress, OfficeAddress}]
    if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        final item = raw[i];
        if (item is Map) {
          shipToList.addAll(
            ShipTo.fromJson(Map<String, dynamic>.from(item), i),
          );
        }
      }
    }

    // Backend V2 shape: shipTo: {residentialAddress, officeAddress}
    if (raw is Map) {
      shipToList.addAll(
        ShipTo.fromJson(
          {
            'ResAddress': raw['residentialAddress'] ?? raw['ResAddress'],
            'OfficeAddress': raw['officeAddress'] ?? raw['OfficeAddress'],
          },
          0,
        ),
      );
    }

    return ShipToResponse(
      status: ((json['Status'] ?? json['status'] ?? 'error').toString().toLowerCase() == 'success'
          ? 'Success'
          : (json['Status'] ?? json['status'] ?? 'error').toString()),
      shipTo: shipToList,
    );
  }
}

class ShipTo {
  final String shipToId;
  final String shipToName;
  final String? shipToAddress;

  ShipTo({
    required this.shipToId,
    required this.shipToName,
    this.shipToAddress,
  });

  static List<ShipTo> fromJson(Map<String, dynamic> json, int index) {
    final shipToList = <ShipTo>[];

    String cleanAddress(dynamic address) {
      final value = address?.toString().trim() ?? '';
      if (value.isEmpty || value.toLowerCase() == 'null') return '';
      var cleaned = value.replaceAll(RegExp(r'[\r\n~]+'), ', ').trim();
      cleaned = cleaned.replaceAll(RegExp(r',\s*,'), ',');
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
      if (cleaned.endsWith(',')) {
        cleaned = cleaned.substring(0, cleaned.length - 1);
      }
      return cleaned;
    }

    final officeAddress = cleanAddress(json['OfficeAddress'] ?? json['officeAddress']);
    if (officeAddress.isNotEmpty) {
      shipToList.add(ShipTo(
        shipToId: '${index}_office',
        shipToName: 'Official Address',
        shipToAddress: officeAddress,
      ));
    }

    final resAddress = cleanAddress(
      json['ResAddress'] ?? json['residentialAddress'],
    );
    if (resAddress.isNotEmpty) {
      shipToList.add(ShipTo(
        shipToId: '${index}_res',
        shipToName: 'Residential Address',
        shipToAddress: resAddress,
      ));
    }

    return shipToList;
  }

  Map<String, dynamic> toJson() => {
        'shipToId': shipToId,
        'shipToName': shipToName,
        'shipToAddress': shipToAddress,
      };

  @override
  String toString() =>
      'ShipTo(shipToId: $shipToId, shipToName: $shipToName, shipToAddress: $shipToAddress)';
}
