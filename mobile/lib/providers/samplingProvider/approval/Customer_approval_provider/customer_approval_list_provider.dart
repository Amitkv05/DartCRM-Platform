import 'package:dart_crm/core/api/legacy_api_adapter.dart';
import 'package:dart_crm/models/sampling_models/approval/customer_approval_models/customer_approval_list.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerApprovalListState {
  final bool isLoading;
  final CustomerApprovalResponse? response;
  final String? errorMessage;

  CustomerApprovalListState({
    this.isLoading = false,
    this.response,
    this.errorMessage,
  });

  CustomerApprovalListState copyWith({
    bool? isLoading,
    CustomerApprovalResponse? response,
    String? errorMessage,
  }) {
    return CustomerApprovalListState(
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
      errorMessage: errorMessage,
    );
  }
}

class CustomerApprovalListNotifier extends StateNotifier<CustomerApprovalListState> {
  final Ref ref;

  CustomerApprovalListNotifier(this.ref) : super(CustomerApprovalListState());

  Future<void> fetchApprovalList({
    required int executiveId,
    required String listFor,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (ref.read(authProvider).token == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Please login first');
        return;
      }

      final request = CustomerApprovalRequest(
        executiveId: executiveId,
        listFor: listFor,
      );
      final data = await LegacyApiAdapter.instance.post(
        '/CustomerSamplingApprovalList',
        data: request.toJson(),
      );
      if (data['Status'] != 'Success') {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['Message']?.toString() ?? 'Failed to fetch approval list',
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        response: CustomerApprovalResponse.fromJson(data),
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch approval list: $e',
      );
    }
  }
}

final customerApprovalListProvider =
    StateNotifierProvider<CustomerApprovalListNotifier, CustomerApprovalListState>((ref) {
  return CustomerApprovalListNotifier(ref);
});
