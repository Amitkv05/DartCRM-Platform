class ExecutiveLocationRequest {
  final int executiveId;
  final double latitude;
  final double longitude;
  final String? executiveLocationXml;
  final int? enteredBy;

  ExecutiveLocationRequest({
    required this.executiveId,
    required this.latitude,
    required this.longitude,
    this.executiveLocationXml,
    this.enteredBy,
  });

  Map<String, dynamic> toJson() => {
        'ExecutiveId': executiveId,
        'Latitude': latitude,
        'Longitude': longitude,
        'ExecutiveLocationXml': executiveLocationXml,
        'EnteredBy': enteredBy,
      };
}

class ExecutiveLocationResponse {
  final String status;
  final List<String> success; // Adjust based on actual response

  ExecutiveLocationResponse({
    required this.status,
    required this.success,
  });

  factory ExecutiveLocationResponse.fromJson(Map<String, dynamic> json) {
    return ExecutiveLocationResponse(
      status: json['Status'] ?? 'error',
      success: (json['Success'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
