import 'dart:convert';
import 'package:dart_crm/models/customer/customer_master_list_model.dart';
import 'package:dart_crm/models/customer/geography_model.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_crm/core/api/legacy_http.dart' as http;

import '../../edit/utils/AppUtils.dart';

final customerMasterListProvider = StateNotifierProvider.family<
    CustomerMasterListNotifier, CustomerMasterListState, String>(
  (ref, customerType) => CustomerMasterListNotifier(ref, customerType),
);

class CustomerMasterListState {
  final List<CustomerMasterListItem> customers;
  final bool isLoading;
  final String? error;
  final int pageSize;

  // final int customerId;
  final String customerType;

  CustomerMasterListState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
    this.pageSize = 100,
    // required this.customerId,
    required this.customerType,
  });

  CustomerMasterListState copyWith({
    List<CustomerMasterListItem>? customers,
    bool? isLoading,
    String? error,
    int? pageSize,
    int? customerId,
    String? customerType,
  }) {
    return CustomerMasterListState(
      customers: customers ?? this.customers,
      // customerId: customerId ?? this.customerId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pageSize: pageSize ?? this.pageSize,
      customerType: customerType ?? this.customerType,
    );
  }
}

class CustomerMasterListNotifier extends StateNotifier<CustomerMasterListState> {
  final Ref ref;
  final String initialCustomerType;

  // final int customerId;

  CustomerMasterListNotifier(this.ref, this.initialCustomerType)
      : super(CustomerMasterListState(customerType: initialCustomerType)) {
    // fetchCustomers();
  }

  Future<String?> _fetchCityAccess() async {
    final authState = ref.read(authProvider);
    final token = authState.token ?? '';
    if (token.isEmpty) {
      print('GeographyAPI: No authentication token available');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/GeographyAPI'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = GeographyResponse.fromJson(data);
        if (result.status == 'Success' && result.geography.isNotEmpty) {
          print('GeographyAPI: Successfully fetched ${result.geography.length} cities');
          return result.geography[0].cityId.toString();
        } else {
          print(
              'GeographyAPI: Invalid response - Status: ${result.status}, Geography: ${result.geography}');
          return null;
        }
      } else {
        print(
            'GeographyAPI: Failed with status ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('GeographyAPI: Exception occurred - $e');
      return null;
    }
  }

/*  Future<void> fetchCustomers() async {
    print('SSSSSSSS fetchCustomers error ${state.error}');
    print('SSSSSSSS fetchCustomers ${state.isLoading}');

    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    final authState = ref.read(authProvider);
    final token = authState.token ?? '';
    final executiveProfileCode =
        authState.loginResponse!.executiveBasicData![0].profileCode.toString();

    final downHierarchyExecutive = authState.loginResponse?.downHierarchy;
    List<String?> down = [];
    downHierarchyExecutive?.forEach((action) {
      down.add(action.downHierarchy);
    });

    if (token.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Authentication token is missing');
      return;
    }

    final cityAccess = authState.loginResponse?.cityAccess;
    List<String?> cityId = [];
    cityAccess?.forEach((action) {
      cityId.add(action.cityAccess);
    });

    final request = CustomerMasterListRequest(
      pageSize: state.pageSize,
      pageNumber: 1,
      customerType: state.customerType,
      executiveProfileCode: executiveProfileCode,
      cityAccess: cityId.join(","),
      downHierarchyExecutive: down.join(","),
    );

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/CustomerListAPI'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('CustomerListAPI Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = CustomerMasterListResponse.fromJson(data, state.customerType);
        if (result.status == 'Success') {
          print('SSSSSS resultresult ${result.customerList?.length}');
          print('SSSSSS errorerror ${state.error}');
          state = state.copyWith(
            customers: result.customerList,
            isLoading: false,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'API returned status: ${result.status}',
          );
        }
      } else {
        print('SSSSSS response.statusCode ${response.statusCode}');

        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch customers: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error fetching customers: $e');
    }
  }*/
}
