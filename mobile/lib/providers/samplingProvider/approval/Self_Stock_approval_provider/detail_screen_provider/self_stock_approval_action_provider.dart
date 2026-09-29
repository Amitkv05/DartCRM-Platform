import 'package:dart_crm/core/api/legacy_api_adapter.dart';
import 'package:dart_crm/models/sampling_models/approval/self_stock_approval_models/self_stock_request_details.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:dart_crm/providers/samplingProvider/approval/Self_Stock_approval_provider/detail_screen_provider/self_stock_request_details_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelfStockApprovalActionState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final Map<int, int> approvedQuantities;

  SelfStockApprovalActionState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
    this.approvedQuantities = const {},
  });

  SelfStockApprovalActionState copyWith({
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
    Map<int, int>? approvedQuantities,
  }) {
    return SelfStockApprovalActionState(
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
      approvedQuantities: approvedQuantities ?? this.approvedQuantities,
    );
  }
}

class SelfStockApprovalActionNotifier extends StateNotifier<SelfStockApprovalActionState> {
  final Ref ref;
  final String requestId;

  SelfStockApprovalActionNotifier(this.ref, this.requestId)
      : super(SelfStockApprovalActionState());

  void updateApprovedQty({required int bookId, required int approvedQty}) {
    final newQuantities = Map<int, int>.from(state.approvedQuantities);
    newQuantities[bookId] = approvedQty < 0 ? 0 : approvedQty;
    state = state.copyWith(approvedQuantities: newQuantities);
  }

  Future<void> submitApproval({
    required String requestId,
    required String requestFor,
    required String enteredBy,
    required String loggedInExecutiveId,
    required String profileCode,
    required String remarks,
    required List<TitleDetail> titleDetails,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      if (ref.read(authProvider).token == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Please login first');
        return;
      }

      String? detailsXml;
      if (requestFor.toLowerCase() == 'approve') {
        final xmlItems = titleDetails.map((title) {
          final approvedQty = state.approvedQuantities[title.bookId] ?? title.requestedQty;
          return '<ApprovedBooksAndQty><RequestId>$requestId</RequestId>'
              '<BookId>${title.bookId}</BookId>'
              '<RequestedQty>${title.requestedQty}</RequestedQty>'
              '<ApprovedQty>$approvedQty</ApprovedQty></ApprovedBooksAndQty>';
        }).join();
        detailsXml = '<DocumentElement>$xmlItems</DocumentElement>';
      }

      final data = await LegacyApiAdapter.instance.post(
        '/SubmitSelfStockSamplingApproval',
        data: {
          'RequestFor': requestFor,
          'EnteredBy': enteredBy,
          'LoggedInExecutiveid': loggedInExecutiveId,
          'ProfileCode': profileCode,
          'SelfStockRequestIds': requestId,
          if (detailsXml != null) 'SelfStockDetailsxml': detailsXml,
          'Remarks': remarks.trim(),
        },
      );
      if (data['Status'] != 'Success') {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['Message']?.toString() ?? 'Self Stock approval failed',
        );
        return;
      }
      final messages = ((data['ReturnMessage'] as List?) ?? const [])
          .map((msg) => (msg as Map)['MsgText']?.toString() ?? '')
          .where((msg) => msg.isNotEmpty)
          .join('\n');
      state = state.copyWith(
        isLoading: false,
        successMessage: messages.isEmpty ? 'Self Stock approval completed' : messages,
      );

      await ref
          .read(selfStockRequestDetailsProvider(requestId).notifier)
          .fetchRequestDetails(module: 'Approval');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to submit approval: $e',
      );
    }
  }
}

final selfStockApprovalActionProvider = StateNotifierProvider.autoDispose.family<
    SelfStockApprovalActionNotifier,
    SelfStockApprovalActionState,
    String>((ref, requestId) {
  return SelfStockApprovalActionNotifier(ref, requestId);
});
