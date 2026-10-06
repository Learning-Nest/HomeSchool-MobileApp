import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeschooling/core/dates.dart';
import 'package:homeschooling/features/common/state_views.dart';
import 'package:homeschooling/features/common/subject_emoji.dart';
import 'package:homeschooling/features/parent/add_to_plan_sheet.dart';
import 'package:homeschooling/features/parent/parent_scaffold.dart';
import 'package:homeschooling/models/activity.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/models/curriculum.dart';
import 'package:homeschooling/models/library.dart';
import 'package:homeschooling/state/curriculum_providers.dart';
import 'package:homeschooling/state/library_providers.dart';
import 'package:homeschooling/state/parent_view_providers.dart';
import 'package:homeschooling/strings.dart';

/// The Activity library: pick a subject, then see the activities that suit the child's level, marked with what
/// the child has already done. Each one can be added to the plan from here (the Planner is for removing).
class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  final TextEditingController _query = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String? _subject;

  /// What the list on screen was last loaded for, so a change of child reloads it.
  String? _shownChildId;
  String? _shownSubject;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.pixels > _scroll.position.maxScrollExtent - 200) {
        ref.read(libraryProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _chooseSubject(String? subject) {
    setState(() => _subject = subject);
    _query.clear();
  }

  Future<void> _addToPlan(Child child, LibraryActivity item) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final GoRouter router = GoRouter.of(context);
    final AddedToPlan? added = await showAddToPlanSheet(context, item.activity, child: child);
    if (added == null) return;
    ref.read(libraryProvider.notifier).refresh(); // it now shows as planned
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            Str.planAdded(added.activityTitle, added.child.displayName, friendlyDate(added.date, dateOnly(DateTime.now()))),
          ),
          action: SnackBarAction(label: Str.planViewPlanner, onPressed: () => router.go('/parent/planner')),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final Child? child = ref.watch(parentViewedChildProvider);
    final LibraryState state = ref.watch(libraryProvider);
    final AsyncValue<List<Subject>> subjects = ref.watch(subjectsProvider);

    if (child?.id != _shownChildId || _subject != _shownSubject) {
      _shownChildId = child?.id;
      _shownSubject = _subject;
      Future<void>.microtask(() => ref.read(libraryProvider.notifier).show(childId: child?.id, subject: _subject));
    }

    return ParentScaffold(
      currentPath: '/parent/catalogue',
      title: Str.catalogueTitle,
      body: child == null
          ? const EmptyView(message: Str.planNoChild, icon: Icons.face_outlined)
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Str.libraryHeader(child.displayName, child.levelCode),
                      key: const ValueKey<String>('library-header'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                if (child.levelCode == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(Str.libraryNoLevel(child.displayName), style: Theme.of(context).textTheme.bodySmall),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: subjects.when(
                      data: (List<Subject> options) => DropdownMenu<String>(
                        key: const ValueKey<String>('library-subject'),
                        expandedInsets: EdgeInsets.zero,
                        label: const Text(Str.librarySubjectLabel),
                        hintText: Str.librarySubjectHint,
                        initialSelection: _subject,
                        requestFocusOnTap: false,
                        enableSearch: false,
                        dropdownMenuEntries: <DropdownMenuEntry<String>>[
                          for (final Subject s in options)
                            DropdownMenuEntry<String>(value: s.code, label: '${subjectEmoji(s.code)} ${s.name}'),
                        ],
                        onSelected: _chooseSubject,
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (Object e, StackTrace st) => TextButton(
                        onPressed: () => ref.invalidate(subjectsProvider),
                        child: const Text(Str.libraryLoadFailedSubjects),
                      ),
                    ),
                  ),
                ),
                if (_subject != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: TextField(
                      controller: _query,
                      decoration: const InputDecoration(labelText: Str.catalogueSearchHint, prefixIcon: Icon(Icons.search)),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (String q) =>
                          ref.read(libraryProvider.notifier).show(childId: child.id, subject: _subject, query: q),
                    ),
                  ),
                const Divider(height: 24),
                Expanded(child: _content(child, state)),
              ],
            ),
    );
  }

  Widget _content(Child child, LibraryState state) {
    if (_subject == null) {
      return EmptyView(message: Str.libraryPickSubject(child.displayName), icon: Icons.menu_book_outlined);
    }
    if (state.loading) return const LoadingView();
    if (state.error != null && state.results.isEmpty) {
      return ErrorView.fromException(
        state.error!,
        onRetry: () => ref.read(libraryProvider.notifier).show(childId: child.id, subject: _subject, query: state.query),
      );
    }
    if (state.results.isEmpty) return const EmptyView(message: Str.libraryNoResults, icon: Icons.search_off);

    final DateTime today = dateOnly(DateTime.now());
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: state.results.length + (state.hasMore ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index >= state.results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final LibraryActivity item = state.results[index];
        return _ActivityCard(item: item, today: today, onAdd: () => _addToPlan(child, item));
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item, required this.today, required this.onAdd});

  final LibraryActivity item;
  final DateTime today;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ActivitySummary a = item.activity;
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(subjectEmoji(a.subjectCode), style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                // The text gets the whole width; the button sits below it so a long title never gets squeezed.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(a.title, key: ValueKey<String>('library-title-${a.id}'), style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text('${a.levelRange} · ${a.durationMin} min', style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                if (item.isDone)
                  _Badge(
                    key: ValueKey<String>('library-done-${a.id}'),
                    icon: Icons.check_circle,
                    label: item.doneLabel(today),
                    color: scheme.tertiary,
                  )
                else
                  _Badge(
                    key: ValueKey<String>('library-new-${a.id}'),
                    icon: Icons.fiber_new,
                    label: Str.libraryNew,
                    color: scheme.primary,
                  ),
                if (item.isPlanned)
                  _Badge(
                    key: ValueKey<String>('library-planned-${a.id}'),
                    icon: Icons.event,
                    label: Str.libraryPlanned(friendlyDate(item.plannedFor!, today)),
                    color: scheme.secondary,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                key: ValueKey<String>('add-to-plan-${a.id}'),
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text(Str.catalogueAddToPlan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({super.key, required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
        ],
      ),
    );
  }
}
