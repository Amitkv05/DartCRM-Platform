class CustomerEntryState {
  final Map<String, dynamic> customerDetails;
  final Map<String, dynamic> schoolDetails;
  final Map<String, dynamic> classEnrollments;
  final Map<String, dynamic> teacherContact;
  final bool isLoading;
  final String? errorMessage;

  CustomerEntryState({
    this.customerDetails = const {},
    this.schoolDetails = const {},
    this.classEnrollments = const {},
    this.teacherContact = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  CustomerEntryState copyWith({
    Map<String, dynamic>? customerDetails,
    Map<String, dynamic>? schoolDetails,
    Map<String, dynamic>? classEnrollments,
    Map<String, dynamic>? teacherContact,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CustomerEntryState(
      customerDetails: customerDetails ?? this.customerDetails,
      schoolDetails: schoolDetails ?? this.schoolDetails,
      classEnrollments: classEnrollments ?? this.classEnrollments,
      teacherContact: teacherContact ?? this.teacherContact,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
