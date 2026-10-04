import 'package:homeschooling/models/json.dart';

const List<String> kOptionalConsentPurposes = <String>['media_capture', 'ai_personalization', 'product_analytics'];

class Family {
  const Family({required this.id, required this.name, required this.timezone, required this.version});

  final String id;
  final String name;
  final String timezone;
  final int version;

  factory Family.fromJson(Map<String, dynamic> j) => Family(
        id: reqString(j, 'id'),
        name: reqString(j, 'name'),
        timezone: optString(j, 'timezone') ?? 'Asia/Kolkata',
        version: optInt(j, 'version') ?? 1,
      );
}

class ConsentRecord {
  const ConsentRecord({
    required this.purpose,
    required this.granted,
    required this.noticeVersion,
    this.recordedAt,
  });

  final String purpose;
  final bool granted;
  final String noticeVersion;
  final DateTime? recordedAt;

  factory ConsentRecord.fromJson(Map<String, dynamic> j) => ConsentRecord(
        purpose: reqString(j, 'purpose'),
        granted: boolOr(j, 'granted'),
        noticeVersion: optString(j, 'notice_version') ?? '',
        recordedAt: optDateTime(j, 'recorded_at'),
      );
}

class GuardianStart {
  const GuardianStart({
    required this.verificationId,
    required this.expiresIn,
    this.devCode,
    this.channel = 'sms',
    this.destinationHint,
  });

  final String verificationId;
  final int expiresIn;

  /// 'sms' or 'email'.
  final String channel;

  /// Masked place the code went to, e.g. "p***@gmail.com" or "******5678".
  final String? destinationHint;

  /// Only present when the server runs in `dev`. Never shown in a prod build.
  final String? devCode;

  factory GuardianStart.fromJson(Map<String, dynamic> j) => GuardianStart(
        verificationId: reqString(j, 'verification_id'),
        expiresIn: optInt(j, 'expires_in') ?? 600,
        devCode: optString(j, 'dev_code'),
        channel: optString(j, 'channel') ?? 'sms',
        destinationHint: optString(j, 'destination_hint'),
      );
}
