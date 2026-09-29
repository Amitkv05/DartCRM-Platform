import 'package:dart_crm/core/api/legacy_api_adapter.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/samplingProvider/approval/Self_Stock_approval_provider/self_stock_approval_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelfStockBulkApprovalState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;

  SelfStockBulkApprovalState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
  });

  SelfStockBulkApprovalState copyWith({
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
  }) {
    return SelfStockBulkApprovalState(
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

class SelfStockBulkApprovalNotifier extends StateNotifier<SelfStockBulkApprovalState> {
  final Ref ref;

  SelfStockBulkApprovalNotifier(this.ref) : super(SelfStockBulkApprovalState());

  Future<void> submitBulkApproval({
    required String requestIds,
    required String requestFor,
    required String enteredBy,
    required String loggedInExecutiveId,
    required String profileCode,
    required String remarks,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      if (ref.read(authProvider).token == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Please login first');
        return;
      }
      final data = await LegacyApiAdapter.instance.post(
        '/SubmitSelfStockSamplingBulkApproval',
        data: {
          'RequestFor': requestFor,
          'EnteredBy': enteredBy,
          'LoggedInExecutiveid': loggedInExecutiveId,
          'ProfileCode': profileCode,
          'SelfStockRequestIds': requestIds,
          if (remarks.isNotEmpty || requestFor.toLowerCase() == 'reject') 'Remarks': remarks,
        },
      );
      if (data['Status'] != 'Success') {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['Message']?.toString() ?? 'Bulk approval failed',
        );
        return;
      }
      final messages = ((data['ReturnMessage'] as List?) ?? const [])
          .map((msg) => (msg as Map)['MsgText']?.toString() ?? '')
          .where((msg) => msg.isNotEmpty)
          .join('\n');
      state = state.copyWith(
        isLoading: false,
        successMessage: messages.isEmpty ? 'Bulk Self Stock action completed' : messages,
      );
      final executiveId = ref.read(authProvider).loginResponse?.executiveBasicData?.first.executiveId;
      if (executiveId != null) {
        await ref.read(selfStockApprovalListProvider.notifier).fetchApprovalList(
              executiveId: executiveId,
              listFor: 'Approval',
            );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to submit bulk approval: $e',
      );
    }
  }
}

final selfStockBulkApprovalProvider =
    StateNotifierProvider<SelfStockBulkApprovalNotifier, SelfStockBulkApprovalState>((ref) {
  return SelfStockBulkApprovalNotifier(ref);
});
