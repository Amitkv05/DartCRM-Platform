// lib/provider/customer_data_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerData {
  final Map<String, dynamic> customerDetails;
  final Map<String, dynamic> schoolDetails;
  final Map<String, dynamic> classEnrollments;
  final Map<String, dynamic> teacherContact;

  CustomerData({
    this.customerDetails = const {},
    this.schoolDetails = const {},
    this.classEnrollments = const {},
    this.teacherContact = const {},
  });

  CustomerData copyWith({
    Map<String, dynamic>? customerDetails,
    Map<String, dynamic>? schoolDetails,
    Map<String, dynamic>? classEnrollments,
    Map<String, dynamic>? teacherContact,
  }) {
    return CustomerData(
      customerDetails: customerDetails ?? this.customerDetails,
      schoolDetails: schoolDetails ?? this.schoolDetails,
      classEnrollments: classEnrollments ?? this.classEnrollments,
      teacherContact: teacherContact ?? this.teacherContact,
    );
  }
}

final customerDataProvider =
    StateProvider<CustomerData>((ref) => CustomerData());
