import 'package:homeschooling/core/api_client.dart';
import 'package:homeschooling/core/auth_tokens.dart';
import 'package:homeschooling/models/activity.dart';
import 'package:homeschooling/models/library.dart';

class CatalogueRepository {
  CatalogueRepository(this._api);

  final ApiClient _api;

  static const int pageSize = 20;

  /// Published activities only. `q` is limited to 80 characters by the API.
  Future<List<ActivitySummary>> list({
    String? subject,
    String? level,
    String? interest,
    String? query,
    int limit = pageSize,
    int offset = 0,
    AuthKind auth = AuthKind.parent,
  }) async {
    String? q = query?.trim();
    if (q != null && q.length > 80) q = q.substring(0, 80);
    final Object? data = await _api.get(
      '/v1/activities',
      query: <String, dynamic>{
        'subject': subject,
        'level': level,
        'interest': interest,
        'q': q,
        'limit': limit,
        'offset': offset,
      },
      auth: auth,
    );
    return parseList(data, ActivitySummary.fromJson);
  }

  /// The Activity library for one child: published activities in [subject] at the child's level (every level when
  /// the child has none), each with how often the child has done it and whether it is already planned.
  Future<List<LibraryActivity>> library(
    String childId, {
    required String subject,
    String? query,
    int limit = pageSize,
    int offset = 0,
  }) async {
    String? q = query?.trim();
    if (q != null && q.isEmpty) q = null;
    if (q != null && q.length > 80) q = q.substring(0, 80);
    final Object? data = await _api.get(
      '/v1/children/$childId/library',
      query: <String, dynamic>{'subject': subject, 'q': q, 'limit': limit, 'offset': offset},
    );
    return parseList(data, LibraryActivity.fromJson);
  }

  Future<ActivityDetail> detail(String activityId, {AuthKind auth = AuthKind.parent}) async {
    final Object? data = await _api.get('/v1/activities/$activityId', auth: auth);
    return parseObject(data, ActivityDetail.fromJson);
  }
}
