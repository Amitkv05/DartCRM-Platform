import 'package:dart_crm/core/api/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeographyItem {
  final int countryId;
  final String country;
  final int stateId;
  final String stateName;
  final int districtId;
  final String district;
  final int cityId;
  final String city;

  const GeographyItem({
    required this.countryId,
    required this.country,
    required this.stateId,
    required this.stateName,
    required this.districtId,
    required this.district,
    required this.cityId,
    required this.city,
  });

  factory GeographyItem.fromJson(Map<String, dynamic> json) {
    dynamic pick(String legacy, String modern) => json[legacy] ?? json[modern];
    int asInt(dynamic value) => int.tryParse((value ?? 0).toString()) ?? 0;
    return GeographyItem(
      countryId: asInt(pick('CountryId', 'country_id')),
      country: pick('Country', 'country')?.toString() ?? '',
      stateId: asInt(pick('StateId', 'state_id')),
      stateName: pick('State', 'state')?.toString() ?? '',
      districtId: asInt(pick('DistrictId', 'district_id')),
      district: pick('District', 'district')?.toString() ?? '',
      cityId: asInt(pick('CityId', 'city_id')),
      city: pick('City', 'city')?.toString() ?? '',
    );
  }
}

class GeographyState {
  final List<GeographyItem> geography;
  final bool isLoading;
  final String? error;
  const GeographyState({required this.geography, this.isLoading = false, this.error});

  GeographyState copyWith({
    List<GeographyItem>? geography,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => GeographyState(
        geography: geography ?? this.geography,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class GeographyNotifier extends StateNotifier<GeographyState> {
  GeographyNotifier(this.ref) : super(const GeographyState(geography: [])) {
    fetchGeography();
  }
  final Ref ref;
  final CrmApiClient _api = CrmApiClient.instance;

  Future<void> fetchGeography() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.get('/geography');
      final data = Map<String, dynamic>.from(response.data as Map);
      final rows = data['geography'] is List ? List<dynamic>.from(data['geography']) : <dynamic>[];
      state = state.copyWith(
        isLoading: false,
        geography: rows
            .whereType<Map>()
            .map((e) => GeographyItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: CrmApiClient.messageFrom(e));
    }
  }

  List<String> getCountries() => state.geography.map((e) => e.country).toSet().toList();

  List<String> getStates(String? country) => country == null
      ? []
      : state.geography.where((e) => e.country == country).map((e) => e.stateName).toSet().toList();

  List<String> getDistricts(String? country, String? stateName) =>
      country == null || stateName == null
          ? []
          : state.geography
              .where((e) => e.country == country && e.stateName == stateName)
              .map((e) => e.district)
              .toSet()
              .toList();

  List<String> getCities(String? country, String? stateName, [String? district]) {
    if (country == null || stateName == null) return [];
    return state.geography
        .where((e) => e.country == country && e.stateName == stateName && (district == null || e.district == district))
        .map((e) => e.city)
        .toSet()
        .toList();
  }

  int? getCityId(String? country, String? stateName, String? district, String? city) {
    if (country == null || stateName == null || city == null) return null;
    for (final item in state.geography) {
      if (item.country == country && item.stateName == stateName && item.city == city &&
          (district == null || item.district == district)) {
        return item.cityId;
      }
    }
    return null;
  }
}

final geographyProvider = StateNotifierProvider<GeographyNotifier, GeographyState>((ref) => GeographyNotifier(ref));
