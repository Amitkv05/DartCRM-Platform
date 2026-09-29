import 'ContactModel.dart';

class ContactListResponse {
  ContactListResponse({
    this.status,
    this.contactList,
  });

  ContactListResponse.fromJson(dynamic json) {
    status = json['Status'];
    if (json['ContactList'] != null) {
      contactList = [];
      json['ContactList'].forEach((v) {
        contactList?.add(ContactModel.fromJson(v));
      });
    }
  }

  String? status;
  List<ContactModel>? contactList;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['Status'] = status;
    if (contactList != null) {
      map['ContactList'] = contactList?.map((v) => v.toJson()).toList();
    }

    return map;
  }
}
