import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeschooling/core/api_exception.dart';
import 'package:homeschooling/features/common/state_views.dart';
import 'package:homeschooling/features/parent/parent_scaffold.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/models/textbooks.dart';
import 'package:homeschooling/state/environment.dart';
import 'package:homeschooling/state/parent_view_providers.dart';
import 'package:homeschooling/state/textbook_providers.dart';
import 'package:homeschooling/strings.dart';

/// Where a parent chooses the textbook(s) a child follows and sees how far the child has got.
class TextbooksScreen extends ConsumerWidget {
  const TextbooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Child? child = ref.watch(parentViewedChildProvider);
    return ParentScaffold(
      currentPath: '/parent/textbooks',
      title: Str.textbooksTitle,
      body: child == null
          ? const EmptyView(message: Str.emptyGeneric, icon: Icons.face_outlined)
          : _Books(child: child),
    );
  }
}

class _Books extends ConsumerWidget {
  const _Books({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ChildBook>> books = ref.watch(childBooksProvider(child.id));
    return books.when(
      loading: () => const LoadingView(),
      error: (Object e, StackTrace st) => ErrorView(
        message: errorTextFromAny(e),
        onRetry: () => ref.invalidate(childBooksProvider(child.id)),
      ),
      data: (List<ChildBook> items) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(childBooksProvider(child.id)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            Text(Str.textbooksIntro, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text(Str.textbooksNone))),
            for (final ChildBook item in items) _BookCard(child: child, item: item),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const ValueKey<String>('textbooks-add'),
              onPressed: () => _addBook(context, ref, child, items),
              icon: const Icon(Icons.add),
              label: const Text(Str.textbooksAdd),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addBook(BuildContext context, WidgetRef ref, Child child, List<ChildBook> have) async {
    final Book? picked = await showModalBottomSheet<Book>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _AddBookSheet(taken: have.map((ChildBook b) => b.book.code).toSet()),
    );
    if (picked == null || !context.mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(environmentProvider).textbookRepository.enrol(child.id, picked.code);
      ref.invalidate(childBooksProvider(child.id));
      messenger.showSnackBar(const SnackBar(content: Text(Str.textbooksAdded)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }
}

class _BookCard extends ConsumerWidget {
  const _BookCard({required this.child, required this.item});

  final Child child;
  final ChildBook item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double value = item.lessonsTotal == 0 ? 0 : item.lessonsComplete / item.lessonsTotal;
    return Card(
      child: InkWell(
        onTap: () => context.push('/parent/textbooks/${item.book.code}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(item.book.label, style: Theme.of(context).textTheme.titleMedium),
              Text(item.book.boardCode, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: value),
              const SizedBox(height: 4),
              Text(Str.lessonsProgress(item.lessonsComplete, item.lessonsTotal)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/parent/textbooks/${item.book.code}'),
                  child: const Text(Str.textbooksOpen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Board, then textbook. Boards and books come from the server, so a new board needs no app update.
class _AddBookSheet extends ConsumerStatefulWidget {
  const _AddBookSheet({required this.taken});

  final Set<String> taken;

  @override
  ConsumerState<_AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends ConsumerState<_AddBookSheet> {
  String? _board;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Board>> boards = ref.watch(boardsProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(Str.textbooksAdd, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            boards.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: LoadingView()),
              error: (Object e, StackTrace st) => ErrorView(
                message: errorTextFromAny(e),
                onRetry: () => ref.invalidate(boardsProvider),
              ),
              data: (List<Board> list) => Wrap(
                spacing: 8,
                runSpacing: 4,
                children: <Widget>[
                  for (final Board b in list)
                    ChoiceChip(
                      key: ValueKey<String>('board-${b.code}'),
                      label: Text(b.name),
                      selected: _board == b.code,
                      onSelected: (bool on) => setState(() => _board = on ? b.code : null),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_board == null)
              const Text(Str.textbooksPickBoard)
            else
              Flexible(child: _BookList(board: _board!, taken: widget.taken)),
          ],
        ),
      ),
    );
  }
}

class _BookList extends ConsumerStatefulWidget {
  const _BookList({required this.board, required this.taken});

  final String board;
  final Set<String> taken;

  @override
  ConsumerState<_BookList> createState() => _BookListState();
}

class _BookListState extends ConsumerState<_BookList> {
  String? _grade;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Book>> books = ref.watch(booksOfBoardProvider(widget.board));
    return books.when(
      loading: () => const Padding(padding: EdgeInsets.all(16), child: LoadingView()),
      error: (Object e, StackTrace st) => ErrorView(
        message: errorTextFromAny(e),
        onRetry: () => ref.invalidate(booksOfBoardProvider(widget.board)),
      ),
      data: (List<Book> list) {
        final List<Book> free = list.where((Book b) => !widget.taken.contains(b.code)).toList();
        if (free.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text(Str.textbooksNoBooks));
        final List<String> grades = free.map((Book b) => b.grade).toSet().toList()
          ..sort((String a, String b) {
            final int? x = int.tryParse(a);
            final int? y = int.tryParse(b);
            return x != null && y != null ? x.compareTo(y) : a.compareTo(b);
          });
        final List<Book> shown = _grade == null ? free : free.where((Book b) => b.grade == _grade).toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (grades.length > 1)
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final String g in grades)
                    FilterChip(
                      key: ValueKey<String>('grade-$g'),
                      label: Text(Str.classLabel(g)),
                      selected: _grade == g,
                      onSelected: (bool on) => setState(() => _grade = on ? g : null),
                    ),
                ],
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  for (final Book b in shown)
                    ListTile(
                      key: ValueKey<String>('book-${b.code}'),
                      title: Text(b.label),
                      subtitle: Text(
                        b.publisher == null ? '${b.lessonCount} lessons' : '${b.publisher} \u00B7 ${b.lessonCount} lessons',
                      ),
                      onTap: () => Navigator.of(context).pop(b),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The lessons of one textbook for the viewed child, with "Add the next lesson".
class TextbookPathScreen extends ConsumerWidget {
  const TextbookPathScreen({super.key, required this.bookCode});

  final String bookCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Child? child = ref.watch(parentViewedChildProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(Str.textbooksTitle)),
      body: SafeArea(
        child: child == null
            ? const EmptyView(message: Str.emptyGeneric, icon: Icons.face_outlined)
            : _Path(child: child, bookCode: bookCode),
      ),
    );
  }
}

class _Path extends ConsumerStatefulWidget {
  const _Path({required this.child, required this.bookCode});

  final Child child;
  final String bookCode;

  @override
  ConsumerState<_Path> createState() => _PathState();
}

class _PathState extends ConsumerState<_Path> {
  bool _busy = false;

  BookPathQuery get _query => BookPathQuery(widget.child.id, widget.bookCode);

  void _refresh() {
    ref.invalidate(bookPathProvider(_query));
    ref.invalidate(childBooksProvider(widget.child.id));
  }

  Future<void> _unlock({bool force = false}) async {
    setState(() => _busy = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(environmentProvider).textbookRepository.unlockNext(widget.child.id, widget.bookCode, force: force);
      _refresh();
    } on ApiException catch (e) {
      if (e.code == 'lesson_incomplete' && !force) {
        if (mounted) setState(() => _busy = false);
        final bool? sure = await _confirmEarly();
        if (sure == true && mounted) await _unlock(force: true);
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(errorText(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmEarly() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text(Str.unlockEarlyTitle),
        content: const Text(Str.unlockEarlyBody),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text(Str.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text(Str.unlockEarlyCta)),
        ],
      ),
    );
  }

  Future<void> _leave() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text(Str.textbooksLeaveTitle),
        content: const Text(Str.textbooksLeaveBody),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text(Str.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text(Str.textbooksLeave)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final GoRouter router = GoRouter.of(context);
    try {
      await ref.read(environmentProvider).textbookRepository.leave(widget.child.id, widget.bookCode);
      ref.invalidate(childBooksProvider(widget.child.id));
      router.pop();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<BookPath> path = ref.watch(bookPathProvider(_query));
    return path.when(
      loading: () => const LoadingView(),
      error: (Object e, StackTrace st) => ErrorView(message: errorTextFromAny(e), onRetry: _refresh),
      data: (BookPath p) => RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            Text(p.book.label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(Str.passScoreNote(p.passScore), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            for (final PathLesson lesson in p.lessons) _LessonTile(lesson: lesson),
            const SizedBox(height: 12),
            if (p.hasMoreLessons)
              FilledButton.icon(
                key: const ValueKey<String>('unlock-next'),
                onPressed: _busy ? null : () => _unlock(),
                icon: const Icon(Icons.lock_open),
                label: const Text(Str.unlockNextCta),
              )
            else
              const Center(child: Text(Str.unlockNextDone)),
            const SizedBox(height: 8),
            TextButton(onPressed: _leave, child: const Text(Str.textbooksLeave)),
          ],
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson});

  final PathLesson lesson;

  @override
  Widget build(BuildContext context) {
    final bool locked = lesson.state == LessonState.locked;
    final IconData icon = switch (lesson.state) {
      LessonState.complete => Icons.check_circle,
      LessonState.open => Icons.play_circle_outline,
      LessonState.locked => Icons.lock_outline,
    };
    final String stateText = switch (lesson.state) {
      LessonState.complete => Str.lessonComplete,
      LessonState.open => Str.lessonOpen,
      LessonState.locked => Str.lessonLocked,
    };
    return Card(
      child: ExpansionTile(
        key: ValueKey<String>('lesson-${lesson.position}'),
        leading: Icon(icon),
        title: Text('${Str.lessonNumber(lesson.position)}: ${lesson.heading}'),
        subtitle: Text(stateText),
        initiallyExpanded: lesson.state == LessonState.open,
        children: <Widget>[
          if (lesson.activities.isEmpty)
            ListTile(title: Text(locked && lesson.activityCount > 0 ? '${lesson.activityCount} activities' : Str.lessonNoActivities))
          else
            for (final PathActivity a in lesson.activities)
              ListTile(
                dense: true,
                leading: Icon(a.status == PathStatus.passed ? Icons.check_circle : Icons.circle_outlined, size: 20),
                title: Text(a.title),
                subtitle: Text(
                  a.bestScore == null ? '${a.durationMin} min' : '${a.durationMin} min · ${Str.scoreLabel(a.bestScore!)}',
                ),
              ),
        ],
      ),
    );
  }
}
