class CustomerCategory {
  CustomerCategory({
    this.customerCategoryId,
    this.customerCategoryName,
  });

  CustomerCategory.fromJson(dynamic json) {
    customerCategoryId = json['CustomerCategoryId'];
    customerCategoryName = json['CustomerCategoryName'];
  }
  int? customerCategoryId;
  String? customerCategoryName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['CustomerCategoryId'] = customerCategoryId;
    map['CustomerCategoryName'] = customerCategoryName;
    return map;
  }
}
