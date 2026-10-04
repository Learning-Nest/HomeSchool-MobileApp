import 'package:homeschooling/core/api_client.dart';
import 'package:homeschooling/core/auth_tokens.dart';
import 'package:homeschooling/models/user.dart';

/// [plain] has no auth interceptor (sign-up, login, refresh, logout); [authed] carries the parent token.
class AuthRepository {
  AuthRepository({required ApiClient plain, required ApiClient authed})
      : _plain = plain,
        _authed = authed;

  final ApiClient _plain;
  final ApiClient _authed;

  Future<AuthResult> signup({
    required String email,
    required String password,
    required String fullName,
    required String timezone,
    String? familyName,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'full_name': fullName.trim(),
      'timezone': timezone,
    };
    final String family = (familyName ?? '').trim();
    if (family.isNotEmpty) body['family_name'] = family;
    final Object? data = await _plain.post('/v1/auth/signup', body: body, auth: AuthKind.none);
    return parseObject(data, AuthResult.fromJson);
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final Object? data = await _plain.post(
      '/v1/auth/login',
      body: <String, dynamic>{'email': email.trim(), 'password': password},
      auth: AuthKind.none,
    );
    return parseObject(data, AuthResult.fromJson);
  }

  /// Asks the server to email a temporary password. The server answers the same way whether or not the address
  /// has an account, so success here says nothing about whether an email was actually sent.
  Future<void> forgotPassword(String email) async {
    await _plain.post(
      '/v1/auth/forgot-password',
      body: <String, dynamic>{'email': email.trim()},
      auth: AuthKind.none,
    );
  }

  /// Sets a new password. [currentPassword] is the old password or the emailed temporary one. Every other
  /// session is signed out and a fresh token pair for this device comes back.
  Future<AuthResult> changePassword({required String currentPassword, required String newPassword}) async {
    final Object? data = await _authed.post(
      '/v1/auth/change-password',
      body: <String, dynamic>{'current_password': currentPassword, 'new_password': newPassword},
    );
    return parseObject(data, AuthResult.fromJson);
  }

  /// Rotates the refresh token. Only the [TokenManager] calls this (single flight).
  Future<TokenPair> refresh(String refreshToken) async {
    final Object? data = await _plain.post(
      '/v1/auth/refresh',
      body: <String, dynamic>{'refresh_token': refreshToken},
      auth: AuthKind.none,
    );
    final AuthResult result = parseObject(data, AuthResult.fromJson);
    return TokenPair(result.accessToken, result.refreshToken);
  }

  /// Best effort: revokes the refresh-token chain on the server.
  Future<void> logout(String refreshToken) async {
    await _plain.post('/v1/auth/logout', body: <String, dynamic>{'refresh_token': refreshToken}, auth: AuthKind.none);
  }

  Future<Me> me() async {
    final Object? data = await _authed.get('/v1/me');
    return parseObject(data, Me.fromJson);
  }
}
