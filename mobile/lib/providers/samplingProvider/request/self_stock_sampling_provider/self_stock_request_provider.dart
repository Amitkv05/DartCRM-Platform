import 'package:dart_crm/core/api/legacy_api_adapter.dart';
import 'package:dart_crm/models/sampling_models/request/self_stock_sampling_models/self_stock_request_response.dart';
import 'package:dart_crm/models/sampling_models/request/self_stock_sampling_models/self_stock_sampling.dart'
    as self_stock;
import 'package:riverpod/riverpod.dart';

class SelfStockRequestState {
  final SelfStockRequestResponse? selfStockRequestResponse;
  final self_stock.SelfStockResponse? submitResponse;
  final String? error;
  final bool isLoading;
  final List<Map<String, dynamic>> tradeAddresses;
  final String? selectedTradeAddress;

  SelfStockRequestState({
    this.selfStockRequestResponse,
    this.submitResponse,
    this.error,
    this.isLoading = false,
    this.tradeAddresses = const [],
    this.selectedTradeAddress,
  });

  SelfStockRequestState copyWith({
    SelfStockRequestResponse? selfStockRequestResponse,
    self_stock.SelfStockResponse? submitResponse,
    String? error,
    bool? isLoading,
    List<Map<String, dynamic>>? tradeAddresses,
    String? selectedTradeAddress,
  }) {
    return SelfStockRequestState(
      selfStockRequestResponse: selfStockRequestResponse ?? this.selfStockRequestResponse,
      submitResponse: submitResponse ?? this.submitResponse,
      error: error,
      isLoading: isLoading ?? this.isLoading,
      tradeAddresses: tradeAddresses ?? this.tradeAddresses,
      selectedTradeAddress: selectedTradeAddress ?? this.selectedTradeAddress,
    );
  }
}

class SelfStockRequestNotifier extends StateNotifier<SelfStockRequestState> {
  SelfStockRequestNotifier() : super(SelfStockRequestState());

  Future<void> fetchSelfStockRequestData({
    required String token,
    required String executiveId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await LegacyApiAdapter.instance.post(
        '/SelfStockRequestAPI',
        data: {'ExecutiveId': executiveId},
      );
      state = state.copyWith(
        selfStockRequestResponse: SelfStockRequestResponse.fromJson(data),
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error fetching self stock request data: $e',
        isLoading: false,
      );
    }
  }

  Future<void> fetchTradeAddresses({
    required String executiveId,
    required String shipTo,
    required String token,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await LegacyApiAdapter.instance.post(
        '/selfstockRequesttradeAPI',
        data: {
          'ExecutiveId': executiveId,
          'territoryids': '',
          'ShipTo': shipTo,
        },
      );
      if (data['Status'] != 'Success') {
        state = state.copyWith(
          tradeAddresses: const [],
          selectedTradeAddress: null,
          error: 'Failed to load trade addresses',
          isLoading: false,
        );
        return;
      }
      final raw = (data['ShipmentAddress'] as List?) ?? const [];
      final addresses = raw.map<Map<String, dynamic>>((value) {
        final addr = Map<String, dynamic>.from(value as Map);
        return {
          'value': '${addr['CustomerId']}_${addr['ShippingAddress']}',
          'label': addr['CustomerName'],
          'customerId': addr['CustomerId'],
          'customerName': addr['CustomerName'],
          'shippingAddress': addr['ShippingAddress'],
        };
      }).toList();
      state = state.copyWith(
        tradeAddresses: addresses,
        selectedTradeAddress: addresses.isNotEmpty ? addresses.first['value']?.toString() : null,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        tradeAddresses: const [],
        selectedTradeAddress: null,
        error: 'Error fetching trade addresses: $e',
        isLoading: false,
      );
    }
  }

  Future<void> submitSelfStockRequest({
    required self_stock.SelfStockRequest request,
    required String token,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await LegacyApiAdapter.instance.post(
        '/selfstockSampling',
        data: request.toJson(),
      );
      state = state.copyWith(
        submitResponse: self_stock.SelfStockResponse.fromJson(data),
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error submitting self stock request: $e',
        isLoading: false,
      );
    }
  }

  void setSelectedTradeAddress(String? value) {
    state = state.copyWith(selectedTradeAddress: value);
  }

  void clearSubmitResponse() {
    state = SelfStockRequestState(
      selfStockRequestResponse: state.selfStockRequestResponse,
      tradeAddresses: state.tradeAddresses,
      selectedTradeAddress: state.selectedTradeAddress,
    );
  }
}

final selfStockRequestProvider =
    StateNotifierProvider<SelfStockRequestNotifier, SelfStockRequestState>(
  (ref) => SelfStockRequestNotifier(),
);
