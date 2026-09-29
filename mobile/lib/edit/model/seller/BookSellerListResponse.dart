import 'BookSellerData.dart';

class BookSellerListResponse {
  BookSellerListResponse({
    this.status,
    this.bookSellers,
  });

  BookSellerListResponse.fromJson(dynamic json) {
    status = json['Status'];
    if (json['BookSellers'] != null) {
      bookSellers = [];
      json['BookSellers'].forEach((v) {
        bookSellers?.add(BookSellerData.fromJson(v));
      });
    }
  }

  String? status;
  List<BookSellerData>? bookSellers;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['Status'] = status;
    if (bookSellers != null) {
      map['BookSellers'] = bookSellers?.map((v) => v.toJson()).toList();
    }

    return map;
  }
}
