import 'dart:convert';

class SelfStockRequestResponse {
  final String status;
  final List<ShipmentMode> shipmentMode;
  final List<ShipTo> shipTo;
  final List<ShipmentAddress> shipmentAddress; // Added ShipmentAddress field
  final List<dynamic> list;

  SelfStockRequestResponse({
    required this.status,
    required this.shipmentMode,
    required this.shipTo,
    required this.shipmentAddress,
    required this.list,
  });

  factory SelfStockRequestResponse.fromJson(Map<String, dynamic> json) {
    return SelfStockRequestResponse(
      status: json['Status'] ?? 'error',
      shipmentMode: (json['ShipmentMode'] as List? ?? [])
          .map((item) => ShipmentMode.fromJson(item))
          .toList(),
      shipTo: (json['ShipTo'] as List? ?? [])
          .map((item) => ShipTo.fromJson(item))
          .toList(),
      shipmentAddress: (json['ShipmentAddress'] as List? ?? [])
          .map((item) => ShipmentAddress.fromJson(item))
          .toList(), // Parse ShipmentAddress
      list: json['List'] ?? [],
    );
  }
}

class ShipmentMode {
  final int shipmentModeId;
  final String shipmentMode;

  ShipmentMode({
    required this.shipmentModeId,
    required this.shipmentMode,
  });

  factory ShipmentMode.fromJson(Map<String, dynamic> json) {
    return ShipmentMode(
      shipmentModeId: json['ShipmentModeId'] ?? 0,
      shipmentMode: json['ShipmentMode'] ?? '',
    );
  }
}

class ShipTo {
  final String id;
  final String shipTo;

  ShipTo({
    required this.id,
    required this.shipTo,
  });

  factory ShipTo.fromJson(Map<String, dynamic> json) {
    return ShipTo(
      id: json['ID'] ?? '',
      shipTo: json['ShipTo'] ?? '',
    );
  }
}

class ShipmentAddress {
  final String addressType;
  final String shipmentAddress;

  ShipmentAddress({
    required this.addressType,
    required this.shipmentAddress,
  });

  factory ShipmentAddress.fromJson(Map<String, dynamic> json) {
    return ShipmentAddress(
      addressType: json['AddressType'] ?? '',
      shipmentAddress: json['ShipmentAddress'] ?? '',
    );
  }
}
