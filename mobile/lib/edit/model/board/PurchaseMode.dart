class PurchaseMode {
  PurchaseMode({
    this.modeValue,
    this.modeName,
  });

  PurchaseMode.fromJson(dynamic json) {
    modeValue = json['ModeValue'];
    modeName = json['ModeName'];
  }
  String? modeValue;
  String? modeName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ModeValue'] = modeValue;
    map['ModeName'] = modeName;
    return map;
  }
}
