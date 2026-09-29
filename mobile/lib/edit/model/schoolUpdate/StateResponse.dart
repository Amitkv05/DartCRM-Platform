class StateResponse {
  StateResponse({
    this.value,
    this.text,
  });

  StateResponse.fromJson(dynamic json) {
    value = json['Value'];
    text = json['Text'];
  }

  int? value;
  String? text;
  String? label;
  String? section;
  bool isSelected = false;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['Value'] = value;
    map['Text'] = text;
    return map;
  }
}
