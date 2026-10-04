import 'package:homeschooling/core/api_client.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/models/family.dart';
import 'package:homeschooling/models/json.dart';

class FamilyRepository {
  FamilyRepository(this._api);

  final ApiClient _api;

  Future<List<Child>> listChildren(String familyId) async {
    final Object? data = await _api.get('/v1/families/$familyId/children');
    return parseList(data, Child.fromJson);
  }

  /// [channel] 'sms' texts the code to [phone]; 'email' emails it to the signed-in account's own address
  /// (the server never takes an address from the request).
  Future<GuardianStart> startGuardianVerification(String familyId, String? phone, {String channel = 'sms'}) async {
    final Object? data = await _api.post(
      '/v1/families/$familyId/guardian-verification',
      body: channel == 'email' ? <String, dynamic>{'channel': 'email'} : <String, dynamic>{'phone': phone},
    );
    return parseObject(data, GuardianStart.fromJson);
  }

  Future<void> confirmGuardianVerification({
    required String familyId,
    required String verificationId,
    required String code,
    required String noticeVersion,
  }) async {
    await _api.post(
      '/v1/families/$familyId/guardian-verification/confirm',
      body: <String, dynamic>{
        'verification_id': verificationId,
        'code': code,
        'declaration_accepted': true,
        'notice_version': noticeVersion,
      },
    );
  }

  Future<List<ConsentRecord>> consents(String familyId) async {
    final Object? data = await _api.get('/v1/families/$familyId/consents');
    return _parseConsents(data);
  }

  Future<List<ConsentRecord>> setConsent({
    required String familyId,
    required String purpose,
    required bool granted,
    required String noticeVersion,
  }) async {
    final Object? data = await _api.put(
      '/v1/families/$familyId/consents',
      body: <String, dynamic>{'purpose': purpose, 'granted': granted, 'notice_version': noticeVersion},
    );
    return _parseConsents(data);
  }

  List<ConsentRecord> _parseConsents(Object? data) {
    return parseObject<List<ConsentRecord>>(
      data,
      (Map<String, dynamic> json) => mapList<ConsentRecord>(json['consents'], ConsentRecord.fromJson),
    );
  }
}
