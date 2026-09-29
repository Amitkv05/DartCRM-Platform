// lib/models/login_request.dart
class LoginRequest {
  final String emailId;
  final String password;
  final String ipAddress;
  final String browserInformation;
  final bool deviceInfo;

  LoginRequest({
    required this.emailId,
    required this.password,
    required this.ipAddress,
    required this.browserInformation,
    this.deviceInfo = false,
  });

  Map<String, dynamic> toJson() => {
        'EmailId': emailId,
        'Password': password,
        'IPAddress': ipAddress,
        'BrowserInformation': browserInformation,
        'DeviceInfo': deviceInfo,
      };
}
