// lib/models/token_response.dart
class TokenResponse {
  final String token;
  final String? status;
  final String? message;

  TokenResponse({
    required this.token,
    this.status,
    this.message,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      token: json['token'] ?? '',
      status: json['Status'],
      message: json['Message'],
    );
  }
}
