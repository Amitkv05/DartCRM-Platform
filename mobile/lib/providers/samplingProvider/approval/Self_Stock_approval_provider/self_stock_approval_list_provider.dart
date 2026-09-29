import 'package:dart_crm/core/api/legacy_api_adapter.dart';
import 'package:dart_crm/models/sampling_models/approval/self_stock_approval_models/self_stock_approval_list.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelfStockApprovalListState {
  final bool isLoading;
  final SelfStockApprovalResponse? response;
  final String? errorMessage;

  SelfStockApprovalListState({
    this.isLoading = false,
    this.response,
    this.errorMessage,
  });

  SelfStockApprovalListState copyWith({
    bool? isLoading,
    SelfStockApprovalResponse? response,
    String? errorMessage,
  }) {
    return SelfStockApprovalListState(
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
      errorMessage: errorMessage,
    );
  }
}

class SelfStockApprovalListNotifier extends StateNotifier<SelfStockApprovalListState> {
  final Ref ref;

  SelfStockApprovalListNotifier(this.ref) : super(SelfStockApprovalListState());

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
      final request = SelfStockApprovalRequest(
        executiveId: executiveId,
        listFor: listFor,
      );
      final data = await LegacyApiAdapter.instance.post(
        '/SelfstockApprovalList',
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
        response: SelfStockApprovalResponse.fromJson(data),
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

final selfStockApprovalListProvider =
    StateNotifierProvider<SelfStockApprovalListNotifier, SelfStockApprovalListState>((ref) {
  return SelfStockApprovalListNotifier(ref);
});
