import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/models/approvals/approval_center_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final approvalListProvider = FutureProvider.family<List<ApprovalSummary>, String>((ref, moduleName) async {
  final response = await CrmApiClient.instance.get(
    '/approvals',
    queryParameters: {'module': moduleName},
  );
  final raw = Map<String, dynamic>.from(response.data as Map);
  final list = raw['approvals'] is List ? List<dynamic>.from(raw['approvals']) : const <dynamic>[];
  return list
      .whereType<Map>()
      .map((e) => ApprovalSummary.fromJson(Map<String, dynamic>.from(e)))
      .toList();
});

final approvalDetailProvider = FutureProvider.family<ApprovalDetailData, int>((ref, approvalId) async {
  final response = await CrmApiClient.instance.get('/approvals/$approvalId');
  return ApprovalDetailData.fromJson(Map<String, dynamic>.from(response.data as Map));
});

Future<String> submitApprovalAction({
  required int approvalId,
  required String action,
  required String remarks,
  required bool sendToNextLevel,
  List<Map<String, dynamic>>? items,
}) async {
  final response = await CrmApiClient.instance.post(
    '/approvals/$approvalId/action',
    data: {
      'action': action,
      'remarks': remarks.trim().isEmpty ? null : remarks.trim(),
      'sendToNextLevel': sendToNextLevel,
      if (items != null) 'items': items,
    },
  );
  final data = Map<String, dynamic>.from(response.data as Map);
  return data['message']?.toString() ?? 'Approval action completed';
}

final approvalRoleListProvider = FutureProvider<List<ApprovalRoleExecutive>>((ref) async {
  final response = await CrmApiClient.instance.get('/admin/executives/approval-roles');
  final raw = Map<String, dynamic>.from(response.data as Map);
  final list = raw['executives'] is List ? List<dynamic>.from(raw['executives']) : const <dynamic>[];
  return list
      .whereType<Map>()
      .map((e) => ApprovalRoleExecutive.fromJson(Map<String, dynamic>.from(e)))
      .toList();
});

Future<String> updateExecutiveApprovalRole({
  required int executiveId,
  required bool approvalEnabled,
}) async {
  final response = await CrmApiClient.instance.patch(
    '/admin/executives/$executiveId/approval-role',
    data: {'approvalEnabled': approvalEnabled},
  );
  final data = Map<String, dynamic>.from(response.data as Map);
  return data['message']?.toString() ?? 'Approval role updated';
}
