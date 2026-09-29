// customer_creation_provider.dart
import 'package:dart_crm/models/customer_creation_model.dart';
import 'package:dart_crm/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dart_crm/core/api/legacy_api_adapter.dart';

final customerCreationProvider = Provider((ref) => CustomerCreationService(ref));

class CustomerCreationService {
  final Ref ref;

  CustomerCreationService(this.ref);

  Future<void> createOrUpdateCustomer(CustomerCreationModel customer) async {
    final authState = ref.read(authProvider);
    if (authState.token == null || authState.token!.isEmpty) {
      throw Exception('Authentication token is missing');
    }

    final data = await LegacyApiAdapter.instance.post(
      '/CustomerCreationAPI',
      data: customer.toJson(),
    );
    if (data['Status'] != 'Success') {
      throw Exception(
        data['Message'] ?? data['e'] ?? data['w'] ?? 'Failed to save customer',
      );
    }
  }
}
