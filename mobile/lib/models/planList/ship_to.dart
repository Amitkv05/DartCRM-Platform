import 'dart:convert';

class ShipToAddress {
  final String resAddress;
  final String officeAddress;

  ShipToAddress({
    required this.resAddress,
    required this.officeAddress,
  });

  factory ShipToAddress.fromJson(Map<String, dynamic> json) {
    return ShipToAddress(
      resAddress: json['ResAddress'] ?? '',
      officeAddress: json['OfficeAddress'] ?? '',
    );
  }

  @override
  String toString() => 'ShipToAddress(resAddress: $resAddress, officeAddress: $officeAddress)';
}

class ShipToResponse {
  final String status;
  final List<ShipToAddress> shipTo;
  final List<dynamic> list;

  ShipToResponse({
    required this.status,
    required this.shipTo,
    required this.list,
  });

  factory ShipToResponse.fromJson(Map<String, dynamic> json) {
    return ShipToResponse(
      status: json['Status'] ?? 'error',
      shipTo: (json['ShipTo'] as List<dynamic>?)
              ?.map((e) => ShipToAddress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      list: json['List'] as List<dynamic>? ?? [],
    );
  }
}