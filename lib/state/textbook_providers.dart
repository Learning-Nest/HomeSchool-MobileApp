import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeschooling/core/auth_tokens.dart';
import 'package:homeschooling/models/textbooks.dart';
import 'package:homeschooling/state/environment.dart';

/// Reference data and per-child progress for textbooks. Plain autoDispose providers: screens call
/// `ref.invalidate(...)` after an enrol / unlock so the next build fetches fresh data.

final boardsProvider = FutureProvider<List<Board>>((Ref ref) {
  return ref.watch(environmentProvider).textbookRepository.boards();
});

/// Textbooks of one board (null board = none loaded; the picker shows nothing until a board is chosen).
final booksOfBoardProvider =
    FutureProvider.autoDispose.family<List<Book>, String>((Ref ref, String board) {
  return ref.watch(environmentProvider).textbookRepository.books(board: board);
});

final childBooksProvider =
    FutureProvider.autoDispose.family<List<ChildBook>, String>((Ref ref, String childId) {
  return ref.watch(environmentProvider).textbookRepository.childBooks(childId);
});

class BookPathQuery {
  const BookPathQuery(this.childId, this.bookCode);

  final String childId;
  final String bookCode;

  @override
  bool operator ==(Object other) => other is BookPathQuery && other.childId == childId && other.bookCode == bookCode;

  @override
  int get hashCode => Object.hash(childId, bookCode);
}

final bookPathProvider =
    FutureProvider.autoDispose.family<BookPath, BookPathQuery>((Ref ref, BookPathQuery q) {
  return ref.watch(environmentProvider).textbookRepository.path(q.childId, q.bookCode);
});

/// What the child can do next in textbook order, fetched with the child's own token. Any failure leaves the
/// list empty on the child's home screen, which then simply shows today's plan.
final nextUpProvider =
    FutureProvider.autoDispose.family<List<NextUpItem>, String>((Ref ref, String childId) {
  return ref.watch(environmentProvider).textbookRepository.nextUp(childId, auth: AuthKind.child);
});
