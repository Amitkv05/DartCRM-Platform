import 'package:dart_crm/core/api/legacy_api_adapter.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../edit/utils/AppUtils.dart';

final cityProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final token = ref.watch(authProvider).token;
  if (token == null || token.isEmpty) {
    throw Exception('No authentication token available');
  }
  final data = await LegacyApiAdapter.instance.post(
    '/CityListForSearchCustomer',
    data: {
      'ExecutiveId': AppUtils.getExecutiveStr(),
      'ExecutiveDownHierarchy': AppUtils.getDownStr(),
    },
  );
  if (data['Status'] != 'Success') {
    throw Exception(data['Message'] ?? 'Failed to load cities');
  }
  final rows = (data['CityList'] as List?) ?? const [];
  return rows.map<Map<String, dynamic>>((raw) {
    final city = Map<String, dynamic>.from(raw as Map);
    final value = city['CityId'];
    city['CityId'] = value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? value;
    return city;
  }).toList();
});

final customerResultProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>(
  (ref, searchParams) async {
    final token = ref.watch(authProvider).token;
    if (token == null || token.isEmpty) {
      throw Exception('No authentication token available');
    }
    final data = await LegacyApiAdapter.instance.post(
      '/SearchCustomerResult',
      data: {
        'ExecutiveDownHierarchy': AppUtils.getDownStr(),
        'ExecutiveId': AppUtils.getExecutiveStr(),
        'CityId': searchParams['CityId'],
        'CityAccess': AppUtils.getCityAccess(),
        'TerritoryAccess': AppUtils.getTerritoryAccess(),
        'CustomerType': searchParams['CustomerType'] ?? '',
        'CustomerContactName': searchParams['CustomerContactName'] ?? '',
        'CustomerCode': searchParams['CustomerCode'] ?? '',
        'CustomerName': searchParams['CustomerName'] ?? '',
      },
    );
    if (data['Status'] != 'Success') {
      throw Exception(data['Message'] ?? 'Failed to load customers');
    }
    final raw = (data['Result'] ?? data['SearchCustomerResult'] ?? data['CustomerList']) as List? ?? const [];
    return raw.map<Map<String, dynamic>>((value) => Map<String, dynamic>.from(value as Map)).toList();
  },
);
