class SetupValue {
  final int id;
  final String keyName;
  final String keyValue;
  final bool keyStatus;
  final String keyDescription;

  SetupValue({
    required this.id,
    required this.keyName,
    required this.keyValue,
    required this.keyStatus,
    required this.keyDescription,
  });

  factory SetupValue.fromJson(Map<String, dynamic> json) {
    return SetupValue(
      id: (json['Id'] is int) ? json['Id'] : int.tryParse(json['Id'].toString()) ?? 0,
      keyName: json['KeyName']?.toString() ?? '',
      keyValue: json['KeyValue']?.toString() ?? '',
      keyStatus:
          json['KeyStatus'] is bool ? json['KeyStatus'] : json['KeyStatus'] == true,
      keyDescription: json['KeyDescription']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'KeyName': keyName,
      'KeyValue': keyValue,
      'KeyStatus': keyStatus,
      'KeyDescription': keyDescription,
    };
  }
}
