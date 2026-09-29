class ContactDesignation {
  ContactDesignation({
    this.contactDesignationId,
    this.contactDesignationName,
  });

  ContactDesignation.fromJson(dynamic json) {
    contactDesignationId = json['ContactDesignationId'];
    contactDesignationName = json['ContactDesignationName'];
  }
  int? contactDesignationId;
  String? contactDesignationName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ContactDesignationId'] = contactDesignationId;
    map['ContactDesignationName'] = contactDesignationName;
    return map;
  }
}
