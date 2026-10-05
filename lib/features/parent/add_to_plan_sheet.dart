import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeschooling/core/dates.dart';
import 'package:homeschooling/features/common/subject_emoji.dart';
import 'package:homeschooling/models/activity.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/state/family_providers.dart';
import 'package:homeschooling/state/parent_view_providers.dart';
import 'package:homeschooling/state/plan_providers.dart';
import 'package:homeschooling/state/progress_providers.dart';
import 'package:homeschooling/strings.dart';

/// What the sheet reports back when an activity was added, so the caller can show a confirmation.
class AddedToPlan {
  const AddedToPlan({required this.activityTitle, required this.child, required this.date});

  final String activityTitle;
  final Child child;
  final DateTime date;
}

/// How many days ahead (including today) a parent can schedule from the library.
const int kPlanAheadDays = 14;

/// Opens the "Add to plan" sheet for [activity]. Resolves to what was added, or null if dismissed.
///
/// Pass [child] to plan for that child only (the library already shows one child's activities); otherwise the
/// parent picks a child when the family has more than one.
Future<AddedToPlan?> showAddToPlanSheet(BuildContext context, ActivitySummary activity, {Child? child}) {
  return showModalBottomSheet<AddedToPlan>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) => AddToPlanSheet(activity: activity, child: child),
  );
}

/// Pick a child and a day, then add the activity to that child's plan.
class AddToPlanSheet extends ConsumerStatefulWidget {
  const AddToPlanSheet({super.key, required this.activity, this.child});

  final ActivitySummary activity;

  /// When set, the activity is planned for this child and there is no child picker.
  final Child? child;

  @override
  ConsumerState<AddToPlanSheet> createState() => _AddToPlanSheetState();
}

class _AddToPlanSheetState extends ConsumerState<AddToPlanSheet> {
  String? _childId;
  late DateTime _date = dateOnly(DateTime.now());
  bool _saving = false;
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final List<Child> children = widget.child != null ? <Child>[widget.child!] : ref.watch(familyProvider).children;
    final Child? viewed = ref.watch(parentViewedChildProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final DateTime today = dateOnly(DateTime.now());

    if (children.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Text(Str.planNoChild),
      );
    }

    final String selectedId = widget.child?.id ?? _childId ?? viewed?.id ?? children.first.id;
    final Child selected = children.firstWhere((Child c) => c.id == selectedId, orElse: () => children.first);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(Str.planAddSheetTitle, style: text.titleLarge),
              const SizedBox(height: 4),
              Text('${subjectEmoji(widget.activity.subjectCode)}  ${widget.activity.title}', style: text.titleMedium),
              const SizedBox(height: 20),
              if (widget.child != null) ...<Widget>[
                Text(Str.planAddForChild(widget.child!.displayName), style: text.labelLarge),
                const SizedBox(height: 20),
              ] else if (children.length > 1) ...<Widget>[
                Text(Str.planAddFor, style: text.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final Child c in children)
                      ChoiceChip(
                        key: ValueKey<String>('plan-child-${c.id}'),
                        label: Text(c.displayName),
                        selected: c.id == selected.id,
                        onSelected: (bool _) => setState(() => _childId = c.id),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              Text(Str.planAddDay, style: text.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (int i = 0; i < kPlanAheadDays; i++)
                    ChoiceChip(
                      key: ValueKey<String>('plan-day-$i'),
                      label: Text(friendlyDate(addDays(today, i), today)),
                      selected: isSameDay(addDays(today, i), _date),
                      onSelected: (bool _) => setState(() => _date = addDays(today, i)),
                    ),
                ],
              ),
              if (_failed) ...<Widget>[
                const SizedBox(height: 12),
                Text(Str.planAddFailed, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey<String>('plan-add-confirm'),
                  onPressed: _saving ? null : () => _confirm(selected),
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.event_available),
                  label: const Text(Str.planAddConfirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(Child child) async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    final bool ok = await ref
        .read(weekPlanProvider.notifier)
        .addItem(childId: child.id, activityId: widget.activity.id, date: _date);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _saving = false;
        _failed = true;
      });
      return;
    }
    // The dashboard shows today's plan and recommendations for this child: make it re-fetch.
    ref.invalidate(dashboardProvider(child.id));
    ref.read(parentViewedChildProvider.notifier).select(child);
    Navigator.of(context).pop(AddedToPlan(activityTitle: widget.activity.title, child: child, date: _date));
  }
}
