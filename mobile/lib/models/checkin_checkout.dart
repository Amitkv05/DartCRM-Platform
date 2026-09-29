// lib/models/checkin_checkout.dart
class CheckinCheckoutRequest {
  final int executiveId;
  final String date;
  final String type;
  final String dateTime;
  final String longEntry;
  final String latEntry;
  final int enteredBy;

  CheckinCheckoutRequest({
    required this.executiveId,
    required this.date,
    required this.type,
    required this.dateTime,
    required this.longEntry,
    required this.latEntry,
    required this.enteredBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'ExecutiveId': executiveId,
      'Date': date,
      'Type': type,
      'DateTime': dateTime,
      'longEntry': longEntry,
      'latEntry': latEntry,
      'EnteredBy': enteredBy,
    };
  }
}

class CheckinCheckoutState {
  final bool isCheckedIn;
  final bool isLoading;
  final String? message;
  final List<Map<String, String>> locationHistory;
  final String? event;
  final bool hasShownCheckinSnackbar;

  CheckinCheckoutState({
    this.isCheckedIn = false,
    this.isLoading = false,
    this.message,
    this.locationHistory = const [],
    this.event,
    this.hasShownCheckinSnackbar = false,
  });

  CheckinCheckoutState copyWith({
    bool? isCheckedIn,
    bool? isLoading,
    String? message,
    List<Map<String, String>>? locationHistory,
    String? event,
    bool? hasShownCheckinSnackbar,
  }) {
    return CheckinCheckoutState(
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      locationHistory: locationHistory ?? this.locationHistory,
      event: event ?? this.event,
      hasShownCheckinSnackbar:
          hasShownCheckinSnackbar ?? this.hasShownCheckinSnackbar,
    );
  }
}
