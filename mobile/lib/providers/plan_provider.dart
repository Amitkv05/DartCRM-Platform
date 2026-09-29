import 'package:dart_crm/core/api/api_client.dart';
import 'package:dart_crm/models/planList/plan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlanState {
  final bool isLoading;
  final PlanResponse? planResponse;
  final String? errorMessage;

  const PlanState({this.isLoading = false, this.planResponse, this.errorMessage});

  PlanState copyWith({
    bool? isLoading,
    PlanResponse? planResponse,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlanState(
      isLoading: isLoading ?? this.isLoading,
      planResponse: planResponse ?? this.planResponse,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PlanNotifier extends StateNotifier<PlanState> {
  PlanNotifier(this.ref) : super(const PlanState());
  final Ref ref;
  final CrmApiClient _api = CrmApiClient.instance;

  Future<void> getPlanList({required int executiveId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.get('/plans', queryParameters: {'executiveId': executiveId});
      final data = Map<String, dynamic>.from(response.data as Map);
      state = state.copyWith(
        isLoading: false,
        planResponse: PlanResponse.fromJson(data),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: CrmApiClient.messageFrom(e),
      );
    }
  }
}

final planProvider = StateNotifierProvider<PlanNotifier, PlanState>((ref) => PlanNotifier(ref));
