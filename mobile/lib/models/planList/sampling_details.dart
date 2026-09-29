import 'package:dart_crm/models/planList/dsr_sampling_details.dart';

class SamplingType {
  final String samplingType;
  final String samplingTypeValue;

  SamplingType({
    required this.samplingType,
    required this.samplingTypeValue,
  });

  factory SamplingType.fromJson(Map<String, dynamic> json) {
    return SamplingType(
      samplingType: (json['SamplingType'] ?? json['name'] ?? json['label'] ?? '').toString(),
      samplingTypeValue: (json['SamplingTypeValue'] ?? json['name'] ?? json['value'] ?? '').toString(),
    );
  }
}

class SampleGiven {
  final String sampleGiven;
  final String sampleGivenValue;

  SampleGiven({
    required this.sampleGiven,
    required this.sampleGivenValue,
  });

  factory SampleGiven.fromJson(Map<String, dynamic> json) {
    return SampleGiven(
      sampleGiven: (json['SampleGiven'] ?? json['label'] ?? '').toString(),
      sampleGivenValue: (json['SampleGivenValue'] ?? json['value'] ?? '').toString(),
    );
  }
}

class ClassLevel {
  final int classLevelId;
  final String classLevelName;

  ClassLevel({
    required this.classLevelId,
    required this.classLevelName,
  });

  factory ClassLevel.fromJson(Map<String, dynamic> json) {
    return ClassLevel(
      classLevelId: int.tryParse((json['ClassLevelId'] ?? json['id'] ?? 0).toString()) ?? 0,
      classLevelName: (json['ClassLevelName'] ?? json['name'] ?? '').toString(),
    );
  }
}

class Series {
  final int seriesId;
  final String seriesName;

  Series({
    required this.seriesId,
    required this.seriesName,
  });

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      seriesId: int.tryParse((json['SeriesId'] ?? json['id'] ?? 0).toString()) ?? 0,
      seriesName: (json['SeriesName'] ?? json['name'] ?? '').toString(),
    );
  }
}

class SeriesAndClassLevelRequest {
  final int profileId;
  final int? executiveId;
  final int? classLevelId;

  SeriesAndClassLevelRequest({
    required this.profileId,
    required this.executiveId,
    this.classLevelId,
  });

  Map<String, dynamic> toJson() {
    return {
      'ProfileId': profileId,
      'ExecutiveId': executiveId,
      if (classLevelId != null) 'ClassLevelId': classLevelId,
    };
  }
}

class SeriesAndClassLevelResponse {
  final String status;
  final List<ClassLevel> classLevelList;
  final List<Series> seriesList;

  SeriesAndClassLevelResponse({
    required this.status,
    required this.classLevelList,
    required this.seriesList,
  });

  factory SeriesAndClassLevelResponse.fromJson(Map<String, dynamic> json) {
    return SeriesAndClassLevelResponse(
      status: ((json['Status'] ?? json['status'] ?? 'error').toString().toLowerCase() == 'success' ? 'Success' : (json['Status'] ?? json['status'] ?? 'error').toString()),
      classLevelList: ((json['ClassLavelList'] ?? json['classLevels']) as List<dynamic>?)
              ?.map((e) => ClassLevel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      seriesList: ((json['SeriesList'] ?? json['series']) as List<dynamic>?)
              ?.map((e) => Series.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// class Title {
//   final int bookId;
//   final String title;
//   final String isbn;
//   final String author;
//   final String price;
//   final double listPrice;
//   final String bookNum;
//   final String image;
//   final String imageUrl;
//   final String bookType;
//   final int physicalStock;
//   final int? seriesId;
//   final int? maxSamplingQty;
//   int quantity;
//   final String? seriesName; // Added to store series name

//   Title({
//     required this.bookId,
//     required this.title,
//     required this.isbn,
//     required this.author,
//     required this.price,
//     required this.listPrice,
//     required this.bookNum,
//     required this.image,
//     required this.imageUrl,
//     required this.bookType,
//     required this.physicalStock,
//     this.seriesId,
//     this.maxSamplingQty,
//     this.quantity = 0,
//     this.seriesName, // Added to constructor
//   });

//   factory Title.fromJson(Map<String, dynamic> json) {
//     double parsePriceToDouble(dynamic value) {
//       if (value == null) return 0.0;
//       if (value is num) return value.toDouble();
//       if (value is String) {
//         final cleanedValue = value.replaceAll(RegExp(r'[₹,\s]'), '');
//         return double.tryParse(cleanedValue) ?? 0.0;
//       }
//       return 0.0;
//     }

//     String parsePriceToString(dynamic value) {
//       if (value == null) return '0.0';
//       if (value is String) {
//         return value.isEmpty ? '0.0' : value;
//       }
//       if (value is num) {
//         return '₹ ${value.toDouble().toStringAsFixed(2)}';
//       }
//       return '0.0';
//     }

//     return Title(
//       bookId: json['BookId'] ?? 0,
//       title: json['Title'] ?? '',
//       isbn: json['ISBN'] ?? '',
//       author: json['Author'] ?? '',
//       price: parsePriceToString(json['Price']),
//       listPrice: parsePriceToDouble(json['ListPrice'] ?? json['Price']),
//       bookNum: json['Booknum'] ?? '',
//       image: json['Image'] ?? '',
//       imageUrl: json['ImageUrl'] ?? '',
//       bookType: json['BookType'] ?? '',
//       physicalStock: json['PhysicalStock'] ?? 0,
//       seriesId: json['SeriesId'] as int?,
//       maxSamplingQty: json['MaxSamplingQty'] as int?,
//       seriesName: json['SeriesName'] as String?, // Added to parse from JSON
//     );
//   }

//   Title copyWith({
//     int? bookId,
//     String? title,
//     String? isbn,
//     String? author,
//     String? price,
//     double? listPrice,
//     String? bookNum,
//     String? image,
//     String? imageUrl,
//     String? bookType,
//     int? physicalStock,
//     int? seriesId,
//     int? maxSamplingQty,
//     int? quantity,
//     String? seriesName, // Added to copyWith
//   }) {
//     return Title(
//       bookId: bookId ?? this.bookId,
//       title: title ?? this.title,
//       isbn: isbn ?? this.isbn,
//       author: author ?? this.author,
//       price: price ?? this.price,
//       listPrice: listPrice ?? this.listPrice,
//       bookNum: bookNum ?? this.bookNum,
//       image: image ?? this.image,
//       imageUrl: imageUrl ?? this.imageUrl,
//       bookType: bookType ?? this.bookType,
//       physicalStock: physicalStock ?? this.physicalStock,
//       seriesId: seriesId ?? this.seriesId,
//       maxSamplingQty: maxSamplingQty ?? this.maxSamplingQty,
//       quantity: quantity ?? this.quantity,
//       seriesName: seriesName ?? this.seriesName, // Added to copyWith
//     );
//   }
// }

// class FetchTitlesRequest {
//   final int executiveId;
//   final String? seriesId;
//   final String? bookISBN;
//   final int? classLevel;
//   final String? sampleGiven;

//   FetchTitlesRequest({
//     required this.executiveId,
//     this.seriesId,
//     this.bookISBN,
//     this.classLevel,
//     this.sampleGiven,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'ExecutiveId': executiveId,
//       if (seriesId != null) 'SeriesId': seriesId,
//       if (bookISBN != null) 'BookISBN': bookISBN,
//       if (classLevel != null) 'ClassLevel': classLevel,
//       if (sampleGiven != null) 'SampleGiven': sampleGiven,
//     };
//   }
// }

class TitleNotInSeriesRequest {
  final int executiveId;
  final String titleOrISBN;
  final String? sampleGiven;

  TitleNotInSeriesRequest({
    required this.executiveId,
    required this.titleOrISBN,
    this.sampleGiven,
  });

  Map<String, dynamic> toJson() {
    return {
      'ExecutiveId': executiveId,
      'BookISBN': titleOrISBN,
      if (sampleGiven != null) 'SampleGiven': sampleGiven,
    };
  }
}

class TitlesResponse {
  final String status;
  final List<TitleData> titleList;

  TitlesResponse({
    required this.status,
    required this.titleList,
  });

  factory TitlesResponse.fromJson(Map<String, dynamic> json) {
    return TitlesResponse(
      status: ((json['Status'] ?? json['status'] ?? 'error').toString().toLowerCase() == 'success' ? 'Success' : (json['Status'] ?? json['status'] ?? 'error').toString()),
      titleList: ((json['TitleList'] ?? json['titles']) as List<dynamic>?)
              ?.map((e) => TitleData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SamplingContact {
  final String customerName;
  final int customerContactId;

  SamplingContact({
    required this.customerName,
    required this.customerContactId,
  });

  factory SamplingContact.fromJson(Map<String, dynamic> json) {
    return SamplingContact(
      customerName: (json['CustomerName'] ?? json['customer_name'] ?? '').toString(),
      customerContactId: int.tryParse((json['CustomerContactId'] ?? json['customer_contact_id'] ?? 0).toString()) ?? 0,
    );
  }

  @override
  String toString() =>
      'SamplingContact(name: $customerName, contactId: $customerContactId)';
}

class SamplingDetailsResponse {
  final String status;
  final List<SamplingType> samplingType;
  final List<SampleGiven> sampleGiven;
  final List<TitleData> titleList;
  final List<SamplingContact> sampleTo;

  SamplingDetailsResponse({
    required this.status,
    required this.samplingType,
    required this.sampleGiven,
    required this.titleList,
    required this.sampleTo,
  });

  factory SamplingDetailsResponse.fromJson(Map<String, dynamic> json) {
    return SamplingDetailsResponse(
      status: ((json['Status'] ?? json['status'] ?? 'error').toString().toLowerCase() == 'success' ? 'Success' : (json['Status'] ?? json['status'] ?? 'error').toString()),
      samplingType: ((json['SamplingType'] ?? json['samplingTypes']) as List<dynamic>?)
              ?.map((e) => SamplingType.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sampleGiven: ((json['SampleGiven'] ?? json['sampleGiven']) as List<dynamic>?)
              ?.map((e) => SampleGiven.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      titleList: ((json['TitleList'] ?? json['titles']) as List<dynamic>?)
              ?.map((e) => TitleData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sampleTo: ((json['SampleTo'] ?? json['sampleTo']) as List<dynamic>?)
              ?.map((e) => SamplingContact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SamplingDetailsRequest {
  final int? titleId;
  final int? classLevelId;
  final String? seriesId;
  final int customerId;
  final String requestType;
  final int profileId;
  final String customerType;
  final int executiveId;

  SamplingDetailsRequest({
    this.titleId,
    this.classLevelId,
    this.seriesId,
    required this.customerId,
    required this.requestType,
    required this.profileId,
    required this.customerType,
    required this.executiveId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (titleId != null) 'TitleId': titleId,
      if (classLevelId != null) 'ClassLevelId': classLevelId,
      if (seriesId != null) 'SeriesId': seriesId,
      'CustomerId': customerId,
      'RequestType': requestType,
      'ProfileId': profileId,
      'CustomerType': customerType,
      'ExecutiveId': executiveId,
    };
  }
}

class SampleTo {
  final String sampleToId;
  final String sampleToName;

  SampleTo({required this.sampleToId, required this.sampleToName});

  @override
  String toString() => 'SampleTo(id: $sampleToId, name: $sampleToName)';
}
