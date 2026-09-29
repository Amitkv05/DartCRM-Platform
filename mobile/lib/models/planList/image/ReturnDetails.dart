class ReturnDetails {
  ReturnDetails({
    this.fileName,
    this.module,
  });

  ReturnDetails.fromJson(dynamic json) {
    fileName = json['FileName'];
    module = json['Module'];
  }
  String? fileName;
  String? module;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['FileName'] = fileName;
    map['Module'] = module;
    return map;
  }
}
