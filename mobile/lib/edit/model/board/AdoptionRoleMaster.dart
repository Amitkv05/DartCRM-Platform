class AdoptionRoleMaster {
  AdoptionRoleMaster({
    this.adoptionRoleId,
    this.adoptionRole,
  });

  AdoptionRoleMaster.fromJson(dynamic json) {
    adoptionRoleId = json['AdoptionRoleId'];
    adoptionRole = json['AdoptionRole'];
  }
  int? adoptionRoleId;
  String? adoptionRole;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['AdoptionRoleId'] = adoptionRoleId;
    map['AdoptionRole'] = adoptionRole;
    return map;
  }
}
