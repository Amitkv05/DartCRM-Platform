import 'package:dart_crm/edit/utils/AppUtils.dart';

class CustomerMasterListRequest {
  final int pageSize;
  final int pageNumber;
  final String customerType;
  final String executiveProfileCode;
  final String? cityAccess;
  final String? validated;
  final String? downHierarchyExecutive;

  CustomerMasterListRequest({
    required this.pageSize,
    required this.pageNumber,
    required this.customerType,
    required this.executiveProfileCode,
    this.cityAccess,
    this.validated,
    this.downHierarchyExecutive,
  });

  Map<String, dynamic> toJson() => {
        'PageSize': pageSize.toString(),
        'PageNumber': pageNumber.toString(),
        'CustomerType': customerType,
        'ExecutiveProfileCode': executiveProfileCode,
        'CityAccess': cityAccess ?? '1084',
        'DownHierarchyExecutive': downHierarchyExecutive ?? 'HDA',
      };
}

class CustomerMasterListItem {
  final int sNo;
  final String customerCode;
  final int customerId;
  final String refCode;
  final String customerName;
  final String city;
  final String state;
  final String? district;
  final int existence;
  final String action;
  final String validationStatus;
  final String? contactEmail;
  final String? contactMobile;
  final String address;
  final int? cityId;
  final int? stateId;
  final String? pincode;
  final int? countryId;
  final String? birthDay;
  final String? anniversary;

  CustomerMasterListItem({
    required this.sNo,
    required this.customerCode,
    required this.customerName,
    required this.refCode,
    required this.address,
    required this.city,
    required this.state,
    required this.district,
    required this.validationStatus,
    required this.existence,
    required this.action,
    required this.customerId,
    this.contactEmail,
    this.contactMobile,
    this.cityId,
    this.stateId,
    this.pincode,
    this.countryId,
    this.birthDay,
    this.anniversary,
  });

  factory CustomerMasterListItem.fromJson(
      Map<String, dynamic> json, String customerType) {
    final action = json['Action'] as String? ?? '';
    final customerId =
        int.tryParse(RegExp(r'\d+').firstMatch(action)?.group(0) ?? '0') ?? 0;

    return CustomerMasterListItem(
      sNo: json['SNo'] as int? ?? 0,
      customerCode: (customerType == 'School'
              ? json['SchoolCode']
              : json['CustomerCode']) as String? ??
          '',
      customerName: (customerType == 'School'
              ? json['SchoolName']
              : json['CustomerName']) as String? ??
          '',
      refCode: json['RefCode'] as String? ?? '',
      address: json['Address'] as String? ?? '',
      city: json['City'] as String? ?? '',
      state: json['State'] as String? ?? '',
      district: json['District'] as String? ?? '',
      validationStatus: json['ValidationStatus'] as String? ?? '',
      existence: json['Existence'] as int? ?? 0,
      action: action,
      customerId: customerId,
      contactEmail: json['ContactEmailId'],
      contactMobile: json['ContactMobile'],
      cityId: json['resCity'],
      stateId: json['resState'],
      pincode: json['resPincode'],
      countryId: json['resCountry'],
      birthDay: json['BirthDay'],
      anniversary: json['Anniversary'],
    );
  }

  // NEW: Add toJson method
  Map<String, dynamic> toJson() {
    return {
      'SNo': sNo,
      'CustomerCode': customerCode,
      'SchoolCode': customerCode, // For School customerType compatibility
      'CustomerName': customerName,
      'SchoolName': customerName, // For School customerType compatibility
      'RefCode': refCode,
      'Address': address,
      'City': city,
      'State': state,
      'District': district,
      'ValidationStatus': validationStatus,
      'Existence': existence,
      'Action': action,
      'CustomerId': customerId,
      'ContactEmailId': contactEmail,
      'ContactMobile': contactMobile,
      'resCity': cityId,
      'resState': stateId,
      'resPincode': pincode,
      'resCountry': countryId,
      'BirthDay': birthDay,
      'Anniversary': anniversary,
    };
  }
}

class CustomerMasterListResponse {
  final String status;
  final List<CustomerMasterListItem> customerList;
  final int customerCount;

  CustomerMasterListResponse({
    required this.status,
    required this.customerList,
    required this.customerCount,
  });

  factory CustomerMasterListResponse.fromJson(
      Map<String, dynamic> json, String customerType) {
    return CustomerMasterListResponse(
      status: json['Status'] as String? ?? '',
      customerList: (json['CustomerList'] as List<dynamic>? ?? [])
          .map((item) => CustomerMasterListItem.fromJson(item, customerType))
          .toList(),
      customerCount:
          AppUtils.parseIntSafe(json['CustomerCount'] as String? ?? ''),
    );
  }

  // NEW: Add toJson method
  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'CustomerList': customerList.map((item) => item.toJson()).toList(),
      'CustomerCount': customerList.length, // Fallback if API doesn't provide
    };
  }
}
