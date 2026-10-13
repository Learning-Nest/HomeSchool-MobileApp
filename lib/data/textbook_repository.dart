import 'package:homeschooling/core/api_client.dart';
import 'package:homeschooling/core/auth_tokens.dart';
import 'package:homeschooling/models/textbooks.dart';

/// Boards, textbooks and a child's progress through them (see api-contracts client guide, "Textbook progress").
class TextbookRepository {
  TextbookRepository(this._api);

  final ApiClient _api;

  Future<List<Board>> boards() async => parseList(await _api.get('/v1/curriculum/boards'), Board.fromJson);

  Future<List<Book>> books({String? board, String? grade, String? subject}) async {
    final Object? data = await _api.get(
      '/v1/curriculum/books',
      query: <String, dynamic>{'board': board, 'grade': grade, 'subject': subject},
    );
    return parseList(data, Book.fromJson);
  }

  Future<List<ChildBook>> childBooks(String childId) async =>
      parseList(await _api.get('/v1/children/$childId/books'), ChildBook.fromJson);

  /// Parent: starts a child on a textbook (safe to repeat). The first lesson that has activities is unlocked.
  Future<BookPath> enrol(String childId, String bookCode) async =>
      parseObject(await _api.put('/v1/children/$childId/books/$bookCode'), BookPath.fromJson);

  Future<void> leave(String childId, String bookCode) async {
    await _api.delete('/v1/children/$childId/books/$bookCode');
  }

  Future<BookPath> path(String childId, String bookCode, {AuthKind auth = AuthKind.parent}) async =>
      parseObject(await _api.get('/v1/children/$childId/books/$bookCode/path', auth: auth), BookPath.fromJson);

  /// Parent: opens the next lesson. A 409 `lesson_incomplete` means an unlocked lesson is still open; repeat with
  /// [force] once the parent has confirmed.
  Future<BookPath> unlockNext(String childId, String bookCode, {bool force = false}) async => parseObject(
        await _api.post('/v1/children/$childId/books/$bookCode/unlock-next', body: <String, dynamic>{'force': force}),
        BookPath.fromJson,
      );

  /// The next activities in textbook order. Works with the child's own token.
  Future<List<NextUpItem>> nextUp(String childId, {int limit = 5, AuthKind auth = AuthKind.child}) async =>
      parseList(
        await _api.get('/v1/children/$childId/next-up', query: <String, dynamic>{'limit': limit}, auth: auth),
        NextUpItem.fromJson,
      );
}
