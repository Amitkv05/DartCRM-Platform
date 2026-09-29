import 'package:dart_crm/core/api/legacy_api_adapter.dart';
import 'package:dart_crm/models/sampling_models/approval/self_stock_approval_models/self_stock_request_details.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelfStockRequestDetailsState {
  final bool isLoading;
  final SelfStockRequestDetailsResponse? response;
  final String? errorMessage;

  SelfStockRequestDetailsState({
    this.isLoading = false,
    this.response,
    this.errorMessage,
  });

  SelfStockRequestDetailsState copyWith({
    bool? isLoading,
    SelfStockRequestDetailsResponse? response,
    String? errorMessage,
  }) {
    return SelfStockRequestDetailsState(
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
      errorMessage: errorMessage,
    );
  }
}

class SelfStockRequestDetailsNotifier extends StateNotifier<SelfStockRequestDetailsState> {
  final Ref ref;
  final String requestId;

  SelfStockRequestDetailsNotifier(this.ref, this.requestId)
      : super(SelfStockRequestDetailsState()) {
    fetchRequestDetails(module: 'Approval');
  }

  Future<void> fetchRequestDetails({required String module}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (ref.read(authProvider).token == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Please login first');
        return;
      }
      final request = SelfStockRequestDetailsRequest(
        requestId: requestId,
        module: module,
      );
      final data = await LegacyApiAdapter.instance.post(
        '/SelfStockSamplingApprovalDetails',
        data: request.toJson(),
      );
      if (data['Status'] != 'Success') {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['Message']?.toString() ?? 'Failed to fetch request details',
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        response: SelfStockRequestDetailsResponse.fromJson(data),
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch request details: $e',
      );
    }
  }
}

final selfStockRequestDetailsProvider = StateNotifierProvider.autoDispose
    .family<SelfStockRequestDetailsNotifier, SelfStockRequestDetailsState, String>(
  (ref, requestId) => SelfStockRequestDetailsNotifier(ref, requestId),
);
