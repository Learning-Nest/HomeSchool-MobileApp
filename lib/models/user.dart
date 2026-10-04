import 'package:homeschooling/models/json.dart';

class UserInfo {
  const UserInfo({required this.id, required this.email, required this.fullName, this.platformRole});

  final String id;
  final String email;
  final String fullName;
  final String? platformRole;

  factory UserInfo.fromJson(Map<String, dynamic> j) => UserInfo(
        id: reqString(j, 'id'),
        email: reqString(j, 'email'),
        fullName: reqString(j, 'full_name'),
        platformRole: optString(j, 'platform_role'),
      );

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'id': id, 'email': email, 'full_name': fullName, 'platform_role': platformRole};
}

class Membership {
  const Membership({
    required this.familyId,
    required this.familyName,
    required this.guardianVerified,
    required this.role,
  });

  final String familyId;
  final String familyName;
  final bool guardianVerified;
  final String role;

  factory Membership.fromJson(Map<String, dynamic> j) => Membership(
        familyId: reqString(j, 'family_id'),
        familyName: optString(j, 'family_name') ?? '',
        guardianVerified: boolOr(j, 'guardian_verified'),
        role: optString(j, 'role') ?? 'owner',
      );
}

/// Response of POST /auth/signup, /auth/login and /auth/refresh.
class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
    required this.memberships,
    this.tempLogin = false,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserInfo user;
  final List<Membership> memberships;

  /// True when this sign-in used an emailed temporary password: the server then allows nothing except
  /// changing the password, so the app must route to the change-password screen.
  final bool tempLogin;

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        accessToken: reqString(j, 'access_token'),
        refreshToken: reqString(j, 'refresh_token'),
        expiresIn: optInt(j, 'expires_in') ?? 900,
        user: UserInfo.fromJson(asJsonMap(j['user'], 'user')),
        memberships: mapList<Membership>(j['memberships'], Membership.fromJson),
        tempLogin: boolOr(j, 'temp_login'),
      );
}

/// Response of GET /me.
class Me {
  const Me({required this.user, required this.memberships, required this.pinSet, this.tempLogin = false});

  final UserInfo user;
  final List<Membership> memberships;
  final bool pinSet;
  final bool tempLogin;

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        user: UserInfo.fromJson(asJsonMap(j['user'], 'user')),
        memberships: mapList<Membership>(j['memberships'], Membership.fromJson),
        pinSet: boolOr(j, 'pin_set'),
        tempLogin: boolOr(j, 'temp_login'),
      );
}

class Elevation {
  const Elevation({required this.token, required this.expiresIn});

  final String token;
  final int expiresIn;

  factory Elevation.fromJson(Map<String, dynamic> j) =>
      Elevation(token: reqString(j, 'elevation_token'), expiresIn: optInt(j, 'expires_in') ?? 300);
}
