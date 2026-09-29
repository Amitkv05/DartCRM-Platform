import 'package:dart_crm/core/api/legacy_api_adapter.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/samplingProvider/approval/Customer_approval_provider/customer_approval_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerBulkApprovalState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;

  CustomerBulkApprovalState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
  });

  CustomerBulkApprovalState copyWith({
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
  }) {
    return CustomerBulkApprovalState(
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

class CustomerBulkApprovalNotifier extends StateNotifier<CustomerBulkApprovalState> {
  final Ref ref;

  CustomerBulkApprovalNotifier(this.ref) : super(CustomerBulkApprovalState());

  Future<void> submitBulkApproval({
    required String requestIds,
    required String approvalFor,
    required String executiveProfile,
    required String loggedInExecutiveId,
    required String enteredBy,
    required String approvalRemarks,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      if (ref.read(authProvider).token == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Please login first');
        return;
      }

      final data = await LegacyApiAdapter.instance.post(
        '/SubmitCustomerSamplingRequestBulkApproval',
        data: {
          'ApprovalFor': approvalFor,
          'ExecutiveProfile': executiveProfile,
          'LoggedInExecutiveId': loggedInExecutiveId,
          'EnteredBy': enteredBy,
          'RequestIds': requestIds,
          if (approvalRemarks.isNotEmpty || approvalFor.toLowerCase() == 'reject')
            'ApporvalRemarks': approvalRemarks,
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
        successMessage: messages.isEmpty ? 'Bulk approval completed' : messages,
      );

      final authState = ref.read(authProvider);
      final executiveId = authState.loginResponse?.executiveBasicData?.first.executiveId;
      if (executiveId != null) {
        await ref.read(customerApprovalListProvider.notifier).fetchApprovalList(
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

final customerBulkApprovalProvider =
    StateNotifierProvider<CustomerBulkApprovalNotifier, CustomerBulkApprovalState>((ref) {
  return CustomerBulkApprovalNotifier(ref);
});
