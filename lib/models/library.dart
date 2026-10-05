import 'package:homeschooling/core/dates.dart';
import 'package:homeschooling/models/activity.dart';
import 'package:homeschooling/models/json.dart';

/// One row of the parent's Activity library for a particular child: the activity plus what that child has
/// already done with it (`GET /v1/children/{id}/library`).
class LibraryActivity {
  const LibraryActivity({required this.activity, this.timesDone = 0, this.lastDoneAt, this.plannedFor});

  final ActivitySummary activity;

  /// How many times the child has finished it (0 = never done).
  final int timesDone;
  final DateTime? lastDoneAt;

  /// The next day it is planned for this child, if it is.
  final DateTime? plannedFor;

  bool get isDone => timesDone > 0;
  bool get isPlanned => plannedFor != null;

  factory LibraryActivity.fromJson(Map<String, dynamic> j) => LibraryActivity(
        activity: ActivitySummary.fromJson(j),
        timesDone: optInt(j, 'times_done') ?? 0,
        lastDoneAt: optDateTime(j, 'last_done_at'),
        plannedFor: j['planned_for'] is String ? reqDate(j, 'planned_for') : null,
      );

  /// "Done once, last Mon, Sep 21" / "Done 3 times, last Today" / "Not done yet".
  String doneLabel(DateTime today) {
    if (!isDone) return '';
    final DateTime? last = lastDoneAt == null ? null : dateOnly(lastDoneAt!.toLocal());
    final String when = last == null ? '' : ', last ${friendlyDate(last, today)}';
    return timesDone == 1 ? 'Done once$when' : 'Done $timesDone times$when';
  }
}
