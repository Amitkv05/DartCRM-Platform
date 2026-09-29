import 'package:dart_crm/core/api/api_client.dart';

class AdminV4Service {
  AdminV4Service._();

  static Future<Map<String, dynamic>> meta() async {
    final response = await CrmApiClient.instance.get('/admin/role-management/meta');
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<List<Map<String, dynamic>>> users({String? search, String? status}) async {
    final response = await CrmApiClient.instance.get(
      '/admin/users',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.isNotEmpty && status != 'ALL') 'status': status,
      },
    );
    final raw = Map<String, dynamic>.from(response.data as Map);
    final list = raw['executives'] is List ? List<dynamic>.from(raw['executives']) : const <dynamic>[];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<Map<String, dynamic>> user(int executiveId) async {
    final response = await CrmApiClient.instance.get('/admin/users/$executiveId');
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<String> createUser(Map<String, dynamic> data) async {
    final response = await CrmApiClient.instance.post('/admin/users', data: data);
    return (response.data['message'] ?? 'Account created').toString();
  }

  static Future<String> updateUser(int executiveId, Map<String, dynamic> data) async {
    final response = await CrmApiClient.instance.patch('/admin/users/$executiveId', data: data);
    return (response.data['message'] ?? 'Account updated').toString();
  }

  static Future<String> deactivate(int executiveId) async {
    final response = await CrmApiClient.instance.delete('/admin/users/$executiveId');
    return (response.data['message'] ?? 'Account deactivated').toString();
  }

  static Future<String> reactivate(int executiveId) async {
    final response = await CrmApiClient.instance.post('/admin/users/$executiveId/reactivate');
    return (response.data['message'] ?? 'Account reactivated').toString();
  }

  static Future<List<Map<String, dynamic>>> adminHistory({String? status, String? module, String? search}) async {
    final response = await CrmApiClient.instance.get(
      '/admin/request-history',
      queryParameters: {
        if (status != null && status.isNotEmpty && status != 'ALL') 'status': status,
        if (module != null && module.isNotEmpty && module != 'ALL') 'module': module,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final raw = Map<String, dynamic>.from(response.data as Map);
    final list = raw['history'] is List ? List<dynamic>.from(raw['history']) : const <dynamic>[];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<String> deleteHistory(int historyId) async {
    final response = await CrmApiClient.instance.delete('/admin/request-history/$historyId');
    return (response.data['message'] ?? 'History removed').toString();
  }

  static Future<String> bulkDeleteHistory(List<int> historyIds) async {
    final response = await CrmApiClient.instance.post(
      '/admin/request-history/bulk-delete',
      data: {'historyIds': historyIds},
    );
    return (response.data['message'] ?? 'Selected history removed').toString();
  }

  static Future<List<Map<String, dynamic>>> myRequestHistory({String? status, String? module}) async {
    final response = await CrmApiClient.instance.get(
      '/approvals/mine/history',
      queryParameters: {
        if (status != null && status.isNotEmpty && status != 'ALL') 'status': status,
        if (module != null && module.isNotEmpty && module != 'ALL') 'module': module,
      },
    );
    final raw = Map<String, dynamic>.from(response.data as Map);
    final list = raw['requests'] is List ? List<dynamic>.from(raw['requests']) : const <dynamic>[];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
