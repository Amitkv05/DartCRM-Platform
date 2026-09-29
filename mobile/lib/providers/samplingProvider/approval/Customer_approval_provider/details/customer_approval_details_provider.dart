import 'package:dart_crm/core/api/legacy_api_adapter.dart';
import 'package:dart_crm/models/sampling_models/approval/customer_approval_models/customer_approval_details.dart'
    as customer;
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerApprovalDetailsState {
  final bool isLoading;
  final customer.CustomerApprovalDetailsResponse? response;
  final String? errorMessage;

  CustomerApprovalDetailsState({
    this.isLoading = false,
    this.response,
    this.errorMessage,
  });

  CustomerApprovalDetailsState copyWith({
    bool? isLoading,
    customer.CustomerApprovalDetailsResponse? response,
    String? errorMessage,
  }) {
    return CustomerApprovalDetailsState(
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
      errorMessage: errorMessage,
    );
  }
}

class CustomerApprovalDetailsNotifier extends StateNotifier<CustomerApprovalDetailsState> {
  final Ref ref;

  CustomerApprovalDetailsNotifier(this.ref) : super(CustomerApprovalDetailsState());

  Future<void> fetchRequestDetails({
    required int customerId,
    required String customerType,
    required int requestId,
    required String module,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (ref.read(authProvider).token == null) {
        if (mounted) {
          state = state.copyWith(isLoading: false, errorMessage: 'Please login first');
        }
        return;
      }

      final request = customer.CustomerApprovalDetailsRequest(
        customerId: customerId,
        customerType: customerType,
        requestId: requestId,
        module: module,
      );
      final data = await LegacyApiAdapter.instance.post(
        '/CustomerSamplingApprovalDetails',
        data: request.toJson(),
      );
      if (!mounted) return;
      if (data['Status'] != 'Success') {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['Message']?.toString() ?? 'Failed to fetch details',
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        response: customer.CustomerApprovalDetailsResponse.fromJson(data),
        errorMessage: null,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to fetch details: $e',
        );
      }
    }
  }
}

final customerApprovalDetailsProvider = StateNotifierProvider.autoDispose
    .family<CustomerApprovalDetailsNotifier, CustomerApprovalDetailsState, String>(
  (ref, requestId) => CustomerApprovalDetailsNotifier(ref),
);
