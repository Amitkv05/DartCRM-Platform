import 'package:dart_crm/core/api/legacy_api_adapter.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/samplingProvider/approval/Customer_approval_provider/details/customer_approval_details_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerApprovalActionState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final Map<int, int> approvedQuantities;

  CustomerApprovalActionState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
    this.approvedQuantities = const {},
  });

  CustomerApprovalActionState copyWith({
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
    Map<int, int>? approvedQuantities,
  }) {
    return CustomerApprovalActionState(
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
      approvedQuantities: approvedQuantities ?? this.approvedQuantities,
    );
  }
}

class CustomerApprovalActionNotifier extends StateNotifier<CustomerApprovalActionState> {
  final Ref ref;
  final String requestId;

  CustomerApprovalActionNotifier(this.ref, this.requestId)
      : super(CustomerApprovalActionState());

  void updateApprovedQty({required int bookId, required int approvedQty}) {
    final newQuantities = Map<int, int>.from(state.approvedQuantities);
    newQuantities[bookId] = approvedQty < 0 ? 0 : approvedQty;
    state = state.copyWith(approvedQuantities: newQuantities);
  }

  Future<void> submitApproval({
    required String requestId,
    required String approvalFor,
    required String executiveProfile,
    required String loggedInExecutiveId,
    required String enteredBy,
    required String approvalRemarks,
    required String approvedBooksAndQtyXML,
    required String customerType,
    required int customerId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      if (ref.read(authProvider).token == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Please login first');
        return;
      }
      final data = await LegacyApiAdapter.instance.post(
        '/SubmitCustomerSamplingRequestApproval',
        data: {
          'ApprovalFor': approvalFor,
          'ExecutiveProfile': executiveProfile,
          'LoggedInExecutiveId': loggedInExecutiveId,
          'EnteredBy': enteredBy,
          'RequestId': requestId,
          'ApporvalRemarks': approvalRemarks,
          if (approvalFor.toLowerCase() == 'approve')
            'ApprovedBooksAndQtyXML': approvedBooksAndQtyXML,
        },
      );
      if (data['Status'] != 'Success') {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['Message']?.toString() ?? 'Approval action failed',
        );
        return;
      }
      final messages = ((data['ReturnMessage'] as List?) ?? const [])
          .map((msg) => (msg as Map)['MsgText']?.toString() ?? '')
          .where((msg) => msg.isNotEmpty)
          .join('\n');
      state = state.copyWith(
        isLoading: false,
        successMessage: messages.isEmpty ? 'Approval action completed' : messages,
      );
      await ref.read(customerApprovalDetailsProvider(requestId).notifier).fetchRequestDetails(
            customerId: customerId,
            customerType: customerType,
            requestId: int.parse(requestId),
            module: 'Approval',
          );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to submit approval: $e',
      );
    }
  }
}

final customerApprovalActionProvider = StateNotifierProvider.autoDispose.family<
    CustomerApprovalActionNotifier,
    CustomerApprovalActionState,
    String>((ref, requestId) {
  return CustomerApprovalActionNotifier(ref, requestId);
});
