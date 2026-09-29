class ShipmentMode {
  final int shipmentModeId;
  final String shipmentModeName;
  final String? description;
  final double? cost;
  final String? code;

  ShipmentMode({
    required this.shipmentModeId,
    required this.shipmentModeName,
    this.description,
    this.cost,
    this.code,
  });

  factory ShipmentMode.fromJson(Map<String, dynamic> json) {
    final rawId = json['ShipmentModeId'] ?? json['shipment_mode_id'] ?? json['id'];
    final rawName = json['ShipmentMode'] ?? json['shipment_mode'] ?? json['name'];
    final rawCost = json['cost'];

    return ShipmentMode(
      shipmentModeId: rawId is num ? rawId.toInt() : int.tryParse('$rawId') ?? 0,
      shipmentModeName: rawName?.toString() ?? '',
      description: json['description']?.toString(),
      cost: rawCost is num ? rawCost.toDouble() : double.tryParse('${rawCost ?? ''}'),
      code: json['code']?.toString(),
    );
  }
}

class ShipmentModeResponse {
  final String status;
  final List<ShipmentMode> shipmentModes;

  ShipmentModeResponse({
    required this.status,
    required this.shipmentModes,
  });

  factory ShipmentModeResponse.fromJson(Map<String, dynamic> json) {
    final modesList = json['ShipmentMode'] ??
        json['shipmentModes'] ??
        json['ShipmentModes'] ??
        const [];

    return ShipmentModeResponse(
      status: ((json['Status'] ?? json['status'] ?? 'error').toString().toLowerCase() == 'success'
          ? 'Success'
          : (json['Status'] ?? json['status'] ?? 'error').toString()),
      shipmentModes: modesList is List
          ? modesList
              .whereType<Map>()
              .map((e) => ShipmentMode.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
