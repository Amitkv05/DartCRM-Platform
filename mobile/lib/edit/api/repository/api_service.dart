import 'dart:convert';

import 'package:dart_crm/core/api/api_client.dart';

import 'package:dart_crm/edit/model/pin/CityPincodeResponse.dart';
import 'package:dart_crm/edit/model/pin/PincodeRequest.dart';
import 'package:dart_crm/edit/model/teacherUpdate/TeacherUpdateRequest.dart';
import 'package:dart_crm/models/login_request.dart';
import 'package:dart_crm/models/login_response.dart';
import 'package:dart_crm/models/planList/sampling_details.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../models/customer/customer_master_list_model.dart';
import '../../../models/planList/EProduct_visit_entry_request.dart';
import '../../../models/planList/image/DocumentResponse.dart';
import '../../../models/planList/image/upload/UploadDocumentRequest.dart';
import '../../model/Geo/GeoResponse.dart';
import '../../model/board/BoardResponse.dart';
import '../../model/school/SchoolListResponse.dart';
import '../../model/schoolUpdate/AllUpdateRequest.dart';
import '../../model/schoolUpdate/StateResponse.dart';
import '../../model/seller/BookSellerData.dart';
import '../../model/seller/BookSellerListResponse.dart';
import '../../model/seller/BookSellerRequest.dart';
import '../../model/teacher/ContactListResponse.dart';
import '../../model/teacher/detail/ContactDetailResponse.dart';
import '../../utils/AppUtils.dart';
import 'api_repository.dart';
import 'api_result.dart';

class ApiService {
  Future<SchoolListResponse?> fetchData(
      int? id, String? customerType, String? validated) async {
    Map? map = <String, dynamic>{};
    map.putIfAbsent('CustomerId', () => id);
    map.putIfAbsent('Validated', () => AppUtils.onlyChar(validated));
    map.putIfAbsent('CustomerType', () => customerType);

    ApiResult result = await ApiRepository()
        .postRequest('$BASE_URL/FetchCustomerDetails', data: map);

    if (result.isSuccess) {
      var school = SchoolListResponse.fromJson(result.response?.data);
      print('customerDetails ${school?.customerDetails?.length}');
      print('school ${school?.schoolDetails?.length}');
      return school;
    } else {
      if (result.response != null && result.response?.data is Map) {
        var error = result.response?.data['Message'];
        AppUtils.showToast(error);
      }
    }
    return null;
  }

  Future<bool> updateAPI(AllUpdateRequest? request) async {
    request?.latEntry = LAT_DATA ?? '';
    request?.longEntry = LONG_DATA ?? '';

    ApiResult result = await ApiRepository()
        .postRequest('$BASE_URL/CustomerCreationAPI', data: request);

    if (result.isSuccess) {
      var d = result.response?.data;
      try {
        var s = d['s'];
        if (s != null) {
          AppUtils.showToast(s);
          return true;
        } else {
          var e = d['e'];
          var w = d['w'];
          if (e != null) {
            AppUtils.showToast(e);
          } else if (w != null) {
            AppUtils.showToast(w);
          } else {
            AppUtils.showToast('Successfully update');
            return true;
          }
        }
      } catch (e) {
        var e = d['e'];
        if (e != null) {
          AppUtils.showToast(e);
        }
        var w = d['w'];
        if (w != null) {
          AppUtils.showToast(w);
        }
      }
    } else {
      if (result.response != null && result.response?.data is Map) {
        var error = result.response?.data['Message'];
        AppUtils.showToast(error);
      }
    }
    return false;
  }

  Future<GeoResponse?> getAllGeoGraphy() async {
    final List<int> executive = [];
    USER_LOGIN_DATA?.executiveBasicData?.forEach((action) {
      var d = action.executiveId;
      executive.add(d);
    });
    final List<String?> city = [];
    USER_LOGIN_DATA?.cityAccess?.forEach((action) {
      var d = action.cityAccess;
      city.add(d);
    });

    String? reqExecutiveId;
    if (executive.isNotEmpty) {
      reqExecutiveId = executive.join(',');
    }
    String? reqCity;
    if (executive.isNotEmpty) {
      reqCity = city.join(',');
    }

    Map<String, dynamic> map = <String, dynamic>{};
    map.putIfAbsent('Executiveid', () => reqExecutiveId);
    map.putIfAbsent('CityAccess', () => reqCity);

    ApiResult result =
        await ApiRepository().postRequest('$BASE_URL/GeographyAPI', data: map);

    if (result.isSuccess) {
      final responseData = result.response?.data;
      return GeoResponse.fromJson(responseData);
    }
    return null;
  }

  Future<GeoResponse?> getAllGeoGraphyAll() async {
    final List<int> executive = [];
    USER_LOGIN_DATA?.executiveBasicData?.forEach((action) {
      var d = action.executiveId;
      executive.add(d);
    });

    String? reqExecutiveId;
    if (executive.isNotEmpty) {
      reqExecutiveId = executive.join(',');
    }

    Map<String, dynamic> map = <String, dynamic>{};
    map.putIfAbsent('Executiveid', () => reqExecutiveId);
    map.putIfAbsent('CityAccess', () => null);

    ApiResult result =
        await ApiRepository().postRequest('$BASE_URL/GeographyAPI', data: map);

    if (result.isSuccess) {
      final responseData = result.response?.data;
      return GeoResponse.fromJson(responseData);
    }
    return null;
  }

  Future<BoardResponse?> getBoardData() async {
    final List<String> downHierarchy = [];
    USER_LOGIN_DATA?.downHierarchy?.forEach((action) {
      var d = action.downHierarchy;
      downHierarchy.add(d ?? '');
    });

    String? req;
    if (downHierarchy.isNotEmpty) {
      req = downHierarchy.join(',');
    }
    Map<String, dynamic> map = <String, dynamic>{};
    map.putIfAbsent('DownHierarchy', () => req);

    ApiResult result = await ApiRepository()
        .postRequest('$BASE_URL/CustomerEntryMasterAPI', data: map);

    print('getAllState responseData ${result.isSuccess}');

    if (result.isSuccess) {
      final responseData = result.response?.data;
      print('getAllState responseData ${responseData}');
      return BoardResponse.fromJson(responseData);
    } else {
      if (result.response != null && result.response?.data is Map) {
        var error = result.response?.data['Message'];
        AppUtils.showToast(error);
      }
    }
    return null;
  }

  Future<ContactListResponse?> getContactList(
    int customerId,
    String? customerType,
    String? action,
  ) async {
    Map<String, dynamic> map = <String, dynamic>{};
    map.putIfAbsent('CustomerId', () => customerId);
    map.putIfAbsent('CustomerType', () => customerType);
    map.putIfAbsent('Validated', () => AppUtils.onlyChar(action));
    map.putIfAbsent('PageSize', () => 100);
    map.putIfAbsent('PageNumber', () => 1);

    ApiResult result = await ApiRepository()
        .postRequest('$BASE_URL/FetchCustomerContactList', data: map);

    if (result.isSuccess) {
      final responseData = result.response?.data;
      return ContactListResponse.fromJson(responseData);
    } else {
      if (result.response != null && result.response?.data is Map) {
        var error = result.response?.data['Message'];
        AppUtils.showToast(error);
      }
    }
    return null;
  }

  Future<bool> updateContactAPI(TeacherUpdateRequest? request) async {
    ApiResult result = await ApiRepository()
        .postRequest('$BASE_URL/ContactEntryorUpdateAPI', data: request);
    if (result.isSuccess) {
      var d = result.response?.data;
      try {
        var s = d['s'];
        if (s != null) {
          AppUtils.showToast(s);
          return true;
        } else {
          var e = d['e'];
          var w = d['w'];
          if (e != null) {
            AppUtils.showToast(e);
          } else if (w != null) {
            AppUtils.showToast(w);
          } else {
            AppUtils.showToast('Successfully update');
            return true;
          }
        }
      } catch (e) {
        var e = d['e'];
        if (e != null) {
          AppUtils.showToast(e);
        }
        var w = d['w'];
        if (w != null) {
          AppUtils.showToast(w);
        }
        return false;
      }
    } else {
      if (result.response != null && result.response?.data is Map) {
        var error = result.response?.data['Message'];
        AppUtils.showToast(error);
      }
    }
    return false;
  }

  Future<Object> pincodeAPI(
    Map<String, dynamic>? queryParameters,
  ) async {
    ApiResult result = await ApiRepository().getRequest(
        '$BASE_URL/CityPinCodeAPI',
        queryParameters: queryParameters);
    if (result.isSuccess) {
      return true;
    } else {
      if (result.response != null && result.response?.data is Map) {
        var error = result.response?.data['Message'];
        AppUtils.showToast(error);
      }
    }
    return false;
  }

  Future<List<CityPincodeResponse>?> pincodeAPI2(String pincode, int cityId,
      String? executiveId, String? cityAccess) async {
    try {
      final response = await ApiRepository().getCityByPincode(
        pinCode: pincode,
        cityId: '0',
        executiveId: executiveId,
        cityAccess: cityAccess,
      );
      print(response.data);
      final body = response.data;
      if (body['Status'] == 'Success') {
        final cities = (body['CityList'] as List)
            .map((e) => CityPincodeResponse.fromJson(e as Map<String, dynamic>))
            .toList();
        return cities;
      } else {
        throw Exception('API returned error status');
      }
    } on DioError catch (e) {
      print('ERROR [${e.response?.statusCode}]: ${e.response?.data}');
    }
    return null;
  }

  Future<CustomerMasterListResponse?> fetchCustomers(
      {required String customerType, required int currentPage}) async {
    final executiveProfileCode =
        USER_LOGIN_DATA?.executiveBasicData![0].profileCode ?? '';

    final downHierarchyExecutive = USER_LOGIN_DATA?.downHierarchy;
    List<String?> down = [];
    downHierarchyExecutive?.forEach((action) {
      down.add(action.downHierarchy);
    });

    final cityAccess = USER_LOGIN_DATA?.cityAccess;
    List<String?> cityId = [];
    cityAccess?.forEach((action) {
      cityId.add(action.cityAccess);
    });

    final request = CustomerMasterListRequest(
      pageSize: 100,
      pageNumber: currentPage,
      customerType: customerType,
      executiveProfileCode: executiveProfileCode,
      cityAccess: cityId.join(","),
      downHierarchyExecutive: down.join(","),
    );

    ApiResult result = await ApiRepository()
        .postRequest('$BASE_URL/CustomerListAPI', data: request);

    if (result.isSuccess) {
      final data = result.response?.data;
      final result1 = CustomerMasterListResponse.fromJson(data, customerType);
      return result1;
    } else {
      if (result.response != null && result.response?.data is Map) {
        var error = result.response?.data['Message'];
        AppUtils.showToast(error);
      }
      return null;
    }
  }

  Future<ContactDetailResponse?> contactDetailAPI(
      int? id, String? customerType, String? validated, int? customerId) async {
    Map? map = <String, dynamic>{};
    map.putIfAbsent('CustomerContactId', () => id);
    map.putIfAbsent('Validated', () => AppUtils.onlyChar(validated));
    map.putIfAbsent('CustomerType', () => customerType);
    map.putIfAbsent('CustomerId', () => customerId);

    ApiResult result = await ApiRepository()
        .postRequest('$BASE_URL/FetchCustomerContactDetails', data: map);

    if (result.isSuccess) {
      var school = ContactDetailResponse.fromJson(result.response?.data);
      print('customerDetails ${school?.schoolContactDetails?.length}');
      return school;
    } else {
      if (result.response != null && result.response?.data is Map) {
        var error = result.response?.data['Message'];
        AppUtils.showToast(error);
      }
    }
    return null;
  }

  Future<bool> deleteCustomer({
    required BuildContext context,
    required int? customerId,
    required int? enteredBy,
    required int? customerContactId,
    required String? validated,
    required String? remarks,
    String? customerType,
  }) async {
    final executiveId =
        USER_LOGIN_DATA?.executiveBasicData![0].executiveId ?? 0;
    Map<String, dynamic> map = {
      'ExecutiveId': executiveId,
      'CustomerId': customerId,
      'CustomerContactId': customerContactId,
      'EnteredBy': enteredBy,
      'Validated': validated,
      'CustomerType': customerType,
      'Remarks': remarks,
    };

    ApiResult result = await ApiRepository()
        .postRequest('$BASE_URL/DeleteCustomerAPI', data: map);

    if (result.isSuccess) {
      var d = result.response?.data;
      try {
        var s1 = d['ReturnMessage'];
        if (s1 != null && s1 is List && s1.isNotEmpty) {
          var msgText = s1[0]['MsgText'];
          print('SSS DD $msgText');
          print('SSS response $map');
          AppUtils.showToast(msgText);
          return true;
        }
        return false;
      } catch (e) {
        var error = d['e'] ?? 'Unknown error occurred';
        AppUtils.showToast(error);
        return false;
      }
    } else {
      if (result.response != null && result.response?.data is Map) {
        var error =
            result.response?.data['Message'] ?? 'Failed to delete customer';
        AppUtils.showToast(error);
      }
      return false;
    }
  }

  Future<bool> deleteContact(
    int? customerId,
    String? action,
    int? enteredBy,
    String? customerType,
  ) async {
    final executiveId =
        USER_LOGIN_DATA?.executiveBasicData![0].executiveId ?? 0;
    Map? map = <String, dynamic>{};
    map.putIfAbsent('ExecutiveId', () => executiveId);
    map.putIfAbsent('CustomerId', () => customerId);
    map.putIfAbsent('CustomerContactId', () => AppUtils.onlyInt(action));
    map.putIfAbsent('EnteredBy', () => enteredBy);
    map.putIfAbsent('Validated', () => AppUtils.onlyChar(action));
    map.putIfAbsent('CustomerType', () => customerType);

    ApiResult result = await ApiRepository()
        .postRequest('$BASE_URL/DeleteCustomerContactAPI', data: map);

    if (result.isSuccess) {
      var d = result.response?.data;
      try {
        var s1 = d['ReturnMessage'];
        if (s1 != null) {
          if (s1 is List) {
            var msgText = s1[0]['MsgText'];
            print('SSS DD $msgText');
            AppUtils.showToast(msgText);
          }
          return true;
        }
        return false;
      } catch (e) {
        var e = d['e'];
        AppUtils.showToast(e);
        return false;
      }
    } else {
      if (result.response != null && result.response?.data is Map) {
        var error = result.response?.data['Message'];
        AppUtils.showToast(error);
      }
    }
    return false;
  }

  Future<bool> addDsrEntryAPI(request) async {
    final result = await ApiRepository()
        .postRequest('$BASE_URL/ApiVisitEntry', data: request);

    if (result.isSuccess) {
      final data = result.response?.data;
      if (data is Map) {
        final status = (data['Status'] ?? data['status'] ?? '').toString();
        if (status.toLowerCase() == 'success') {
          final message = data['s'] ?? data['message'] ??
              'Visit Details inserted successfully';
          AppUtils.showToast(message.toString());
          return true;
        }
        final message = data['Message'] ?? data['message'] ?? data['e'] ?? data['w'];
        if (message != null) AppUtils.showToast(message.toString());
      }
      return false;
    }

    final data = result.response?.data;
    String message = 'DSR entry request failed';
    if (data is Map) {
      message = (data['Message'] ?? data['message'] ?? data['error'] ?? message).toString();
    } else if (result.error?.message?.isNotEmpty == true) {
      message = result.error!.message!;
    }
    AppUtils.showToast(message);
    return false;
  }

  Future<SamplingDetailsResponse?> getSamplingData(request) async {
    ApiResult result = await ApiRepository()
        .postRequest('$BASE_URL/SamplingDetails', data: request);
    if (result.isSuccess) {
      var d = result.response?.data;
      var dddd = SamplingDetailsResponse.fromJson(result.response?.data);
      print('SSSSSSS samplingType ${dddd.samplingType?.length}');

      try {
        var s = d['s'];
        if (s != null) {
          AppUtils.showToast(s);
          return dddd;
        } else {
          var e = d['e'];
          var w = d['w'];
          if (e != null) {
            AppUtils.showToast(e);
          } else if (w != null) {
            AppUtils.showToast(w);
          } else {
            AppUtils.showToast('Successfully update');
            return dddd;
          }
        }
      } catch (e) {
        var e = d['e'];
        if (e != null) {
          AppUtils.showToast(e);
        }
        var w = d['w'];
        if (w != null) {
          AppUtils.showToast(w);
        }
        return null;
      }
    } else {
      if (result.response != null && result.response?.data is Map) {
        var error = result.response?.data['Message'];
        AppUtils.showToast(error);
      }
    }
    return null;
  }

  Future<DocumentResponse?> uploadDocumentAPI(
      UploadDocumentRequest request) async {
    final result =
        await ApiRepository().postRequest(
      '$BASE_URL/savefile',
      data: request.toJson(),
    );

    if (result.isSuccess && result.response?.data is Map) {
      final data = Map<String, dynamic>.from(result.response!.data as Map);
      final response = DocumentResponse.fromJson(data);
      if ((data['Status'] ?? data['status'] ?? '').toString().toLowerCase() ==
          'success') {
        return response;
      }
      final message = data['Message'] ?? data['message'] ?? data['e'] ?? data['w'];
      if (message != null) AppUtils.showToast(message.toString());
      return null;
    }

    final data = result.response?.data;
    String message = 'Document upload failed';
    if (data is Map) {
      message = (data['Message'] ?? data['message'] ?? data['error'] ?? message).toString();
    } else if (result.error?.message?.isNotEmpty == true) {
      message = result.error!.message!;
    }
    AppUtils.showToast(message);
    return null;
  }

  Future<List<BookSellerData>?> bookSellerSearchAPI(
      BookSellerRequest? request) async {
    try {
      final result = await ApiRepository().postRequest(
        '$BASE_URL/booksellersearchapi',
        data: request?.toJson() ?? <String, dynamic>{},
      );
      if (result.isSuccess && result.response?.data is Map) {
        final book = BookSellerListResponse.fromJson(
          Map<String, dynamic>.from(result.response!.data as Map),
        );
        return book.bookSellers ?? <BookSellerData>[];
      }
      final message = result.response?.data is Map
          ? (result.response?.data['Message'] ?? result.response?.data['message'])
          : result.error?.message;
      AppUtils.showToast(message?.toString() ?? 'Unable to load book sellers');
    } catch (error) {
      AppUtils.showToast(CrmApiClient.messageFrom(error));
    }
    return <BookSellerData>[];
  }
}
