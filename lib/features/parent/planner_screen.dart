import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeschooling/core/dates.dart';
import 'package:homeschooling/features/common/state_views.dart';
import 'package:homeschooling/features/parent/parent_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:homeschooling/features/common/subject_emoji.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/models/plan.dart';
import 'package:homeschooling/state/parent_view_providers.dart';
import 'package:homeschooling/state/plan_providers.dart';
import 'package:homeschooling/strings.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  DateTime _selectedDay = dateOnly(DateTime.now());
  String? _loadedForChildId;
  DateTime? _loadedWeek;

  @override
  Widget build(BuildContext context) {
    final Child? child = ref.watch(parentViewedChildProvider);
    final WeekPlanState week = ref.watch(weekPlanProvider);
    final DateTime weekStart = weekStartOf(_selectedDay);

    if (child != null && (_loadedForChildId != child.id || _loadedWeek != weekStart)) {
      _loadedForChildId = child.id;
      _loadedWeek = weekStart;
      Future<void>.microtask(() => ref.read(weekPlanProvider.notifier).loadWeek(child.id, _selectedDay));
    }

    return ParentScaffold(
      currentPath: '/parent/planner',
      title: Str.plannerTitle,
      body: child == null
          ? const EmptyView(message: Str.emptyGeneric, icon: Icons.face_outlined)
          : Column(
              children: <Widget>[
                _WeekHeader(
                  weekStart: weekStart,
                  onPrev: () => _goToWeek(addDays(weekStart, -7)),
                  onNext: () => _goToWeek(addDays(weekStart, 7)),
                  onThisWeek: () => setState(() => _selectedDay = dateOnly(DateTime.now())),
                ),
                _WeekStrip(
                  weekStart: weekStart,
                  selected: _selectedDay,
                  onSelect: (DateTime d) => setState(() => _selectedDay = d),
                ),
                const Divider(height: 1),
                Expanded(
                  child: week.loading
                      ? const LoadingView()
                      : week.error != null && week.items.isEmpty
                          ? ErrorView.fromException(
                              week.error!,
                              onRetry: () => ref.read(weekPlanProvider.notifier).loadWeek(child.id, _selectedDay),
                            )
                          : _DayList(day: _selectedDay, items: week.itemsOn(_selectedDay), weekIsEmpty: week.items.isEmpty),
                ),
              ],
            ),
    );
  }

  /// Moves to another week. Lands on today if that week is the current one, otherwise on its Monday.
  void _goToWeek(DateTime weekStart) {
    final DateTime today = dateOnly(DateTime.now());
    setState(() => _selectedDay = isSameDay(weekStartOf(today), weekStart) ? today : weekStart);
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.weekStart, required this.onPrev, required this.onNext, required this.onThisWeek});

  final DateTime weekStart;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onThisWeek;

  @override
  Widget build(BuildContext context) {
    final bool isCurrentWeek = isSameDay(weekStart, weekStartOf(DateTime.now()));
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: <Widget>[
          IconButton(
            key: const ValueKey<String>('planner-prev-week'),
            icon: const Icon(Icons.chevron_left),
            tooltip: Str.plannerPrevWeek,
            onPressed: onPrev,
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                Text(weekRangeLabel(weekStart), style: Theme.of(context).textTheme.titleMedium),
                if (!isCurrentWeek) TextButton(onPressed: onThisWeek, child: const Text(Str.plannerThisWeek)),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey<String>('planner-next-week'),
            icon: const Icon(Icons.chevron_right),
            tooltip: Str.plannerNextWeek,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.weekStart, required this.selected, required this.onSelect});

  final DateTime weekStart;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final List<DateTime> days = weekDays(weekStart);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          for (final DateTime d in days)
            InkWell(
              onTap: () => onSelect(d),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSameDay(d, selected) ? Theme.of(context).colorScheme.primaryContainer : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: <Widget>[Text(weekdayShort(d)), Text('${d.day}')],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The plan for one day. Remove-only: adding happens in the Activity library.
class _DayList extends ConsumerWidget {
  const _DayList({required this.day, required this.items, required this.weekIsEmpty});

  final DateTime day;
  final List<PlanItem> items;
  final bool weekIsEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return EmptyView(
        message: weekIsEmpty ? Str.plannerEmptyWeek : Str.plannerEmptyDay,
        icon: Icons.event_available_outlined,
        action: FilledButton.icon(
          key: const ValueKey<String>('planner-open-library'),
          onPressed: () => context.go('/parent/catalogue'),
          icon: const Icon(Icons.menu_book_outlined),
          label: const Text(Str.plannerOpenLibrary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final PlanItem item = items[index];
        return Card(
          child: ListTile(
            leading: Text(subjectEmoji(item.activity.subjectCode), style: const TextStyle(fontSize: 28)),
            title: Text(item.activity.title),
            subtitle: Text('${item.activity.durationMin} min · ${Str.planStatus(item.status)}'),
            trailing: item.canDelete
                ? IconButton(
                    key: ValueKey<String>('planner-remove-${item.id}'),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: Str.plannerRemove,
                    onPressed: () => _remove(context, ref, item),
                  )
                : Tooltip(message: Str.plannerCannotRemove, child: Icon(item.isCompleted ? Icons.check_circle : Icons.lock_outline)),
          ),
        );
      },
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, PlanItem item) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text(Str.plannerRemoveConfirmTitle),
        content: Text('${item.activity.title}\n\n${Str.plannerRemoveConfirmBody}'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text(Str.cancel)),
          FilledButton(
            key: const ValueKey<String>('planner-remove-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(Str.plannerRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final bool ok = await ref.read(weekPlanProvider.notifier).deleteItem(item.id);
    if (!ok) messenger.showSnackBar(const SnackBar(content: Text(Str.errorGeneric)));
  }
}
