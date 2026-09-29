import 'package:dart_crm/core/api/legacy_api_adapter.dart';
import 'package:dart_crm/models/visit_details.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VisitDetailsState {
  final bool isLoading;
  final VisitDetailsResponse? visitDetailsResponse;
  final String? errorMessage;

  VisitDetailsState({
    this.isLoading = false,
    this.visitDetailsResponse,
    this.errorMessage,
  });

  VisitDetailsState copyWith({
    bool? isLoading,
    VisitDetailsResponse? visitDetailsResponse,
    String? errorMessage,
  }) {
    return VisitDetailsState(
      isLoading: isLoading ?? this.isLoading,
      visitDetailsResponse: visitDetailsResponse ?? this.visitDetailsResponse,
      errorMessage: errorMessage,
    );
  }
}

class VisitDetailsNotifier extends StateNotifier<VisitDetailsState> {
  final Ref ref;

  VisitDetailsNotifier(this.ref) : super(VisitDetailsState());

  Future<void> fetchVisitDetails(VisitDetailsRequest request) async {
    // Clear stale data from the previously opened customer before loading.
    state = VisitDetailsState(isLoading: true);
    try {
      if (ref.read(authProvider).token == null) {
        state = VisitDetailsState(isLoading: false, errorMessage: 'Please login first');
        return;
      }
      final data = await LegacyApiAdapter.instance.post(
        '/VisitDetails',
        data: request.toJson(),
      );
      if (data['Status'] != 'Success') {
        state = VisitDetailsState(
          isLoading: false,
          errorMessage: data['Message']?.toString() ?? 'Failed to fetch visit details',
        );
        return;
      }
      state = VisitDetailsState(
        isLoading: false,
        visitDetailsResponse: VisitDetailsResponse.fromJson(data),
      );
    } catch (e) {
      state = VisitDetailsState(
        isLoading: false,
        errorMessage: 'Failed to fetch visit details: $e',
      );
    }
  }
}

final visitDetailsProvider =
    StateNotifierProvider<VisitDetailsNotifier, VisitDetailsState>((ref) {
  return VisitDetailsNotifier(ref);
});
