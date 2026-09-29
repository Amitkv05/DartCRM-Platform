// lib/models/token_request.dart
class TokenRequest {
  final String emailId;
  final String password;

  TokenRequest({
    required this.emailId,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'EmailId': emailId,
        'Password': password,
      };
}
