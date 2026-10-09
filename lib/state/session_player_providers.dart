import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeschooling/core/api_exception.dart';
import 'package:homeschooling/core/auth_tokens.dart';
import 'package:homeschooling/core/ids.dart';
import 'package:homeschooling/core/pending_item.dart';
import 'package:homeschooling/models/activity.dart';
import 'package:homeschooling/models/session.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:homeschooling/state/environment.dart';
import 'package:homeschooling/state/image_providers.dart';
import 'package:homeschooling/state/pending_queue_providers.dart';
import 'package:homeschooling/state/plan_providers.dart';

/// One activity attempt, from opening the player to a finished (possibly still-queued) submit.
///
/// Offline design: the app never blocks on the network while the child is playing. `POST /sessions` is
/// attempted best-effort in the background (so autosave has somewhere to write); if it never succeeds, the
/// whole attempt — start included — is handed to [PendingQueue] on [finish], which starts *and* submits it
/// once connectivity returns (see [PendingSender] in pending_queue.dart).
class PlayerState {
  const PlayerState({
    required this.activityId,
    this.definition,
    this.summary,
    this.sessionId,
    this.answers = const <String, dynamic>{},
    this.hintsUsed = 0,
    this.parentAssist = false,
    this.stepIndex = 0,
    this.loading = true,
    this.submitting = false,
    this.submitted = false,
    this.queuedOffline = false,
    this.result,
    this.error,
  });

  final String activityId;
  final ActivityDefinition? definition;
  final ActivitySummary? summary;
  final String? sessionId;
  final Map<String, dynamic> answers;
  final int hintsUsed;
  final bool parentAssist;
  final int stepIndex;
  final bool loading;
  final bool submitting;
  final bool submitted;

  /// True when [finish] could not reach the server: the child still sees a completion screen, but a sync
  /// badge should show until [PendingQueue] flushes it.
  final bool queuedOffline;
  final SessionResult? result;
  final ApiException? error;

  List<ActivityStep> get childSteps => definition?.childSteps ?? const <ActivityStep>[];

  PlayerState copyWith({
    ActivityDefinition? definition,
    ActivitySummary? summary,
    String? sessionId,
    Map<String, dynamic>? answers,
    int? hintsUsed,
    bool? parentAssist,
    int? stepIndex,
    bool? loading,
    bool? submitting,
    bool? submitted,
    bool? queuedOffline,
    SessionResult? result,
    ApiException? error,
    bool clearError = false,
  }) {
    return PlayerState(
      activityId: activityId,
      definition: definition ?? this.definition,
      summary: summary ?? this.summary,
      sessionId: sessionId ?? this.sessionId,
      answers: answers ?? this.answers,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      parentAssist: parentAssist ?? this.parentAssist,
      stepIndex: stepIndex ?? this.stepIndex,
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      submitted: submitted ?? this.submitted,
      queuedOffline: queuedOffline ?? this.queuedOffline,
      result: result ?? this.result,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PlayerNotifier extends Notifier<PlayerState?> {
  Timer? _autosaveTimer;
  String _clientOpId = '';
  String _childId = '';
  String? _planItemId;
  AuthKind _auth = AuthKind.child;
  DateTime _openedAt = DateTime.now();

  @override
  PlayerState? build() {
    ref.onDispose(() => _autosaveTimer?.cancel());
    return null;
  }

  AppEnvironment get _env => ref.read(environmentProvider);

  /// Starts a fresh attempt. Call once when the player screen opens.
  void open({
    required String childId,
    required ActivitySummary summary,
    String? planItemId,
    AuthKind auth = AuthKind.child,
  }) {
    _autosaveTimer?.cancel();
    _clientOpId = newUuid();
    _childId = childId;
    _planItemId = planItemId;
    _auth = auth;
    _openedAt = DateTime.now();
    state = PlayerState(activityId: summary.id, summary: summary, loading: true);
    _loadDefinition(summary.id);
  }

  Future<void> _loadDefinition(String activityId) async {
    try {
      final detail = await _env.catalogueRepository.detail(activityId, auth: _auth);
      if (state?.activityId != activityId) return;
      state = state?.copyWith(definition: detail.definition, summary: detail.summary, loading: false);
      // Pictures download in the background while the child reads the first exercise; each screen shows its
      // picture as soon as it is there, and the words work without it.
      unawaited(ref.read(imageStoreProvider).prefetch(detail.definition));
      unawaitedStart();
    } on ApiException catch (e) {
      if (state?.activityId != activityId) return;
      state = state?.copyWith(loading: false, error: e);
    }
  }

  /// Best-effort background session start, so autosave has a session to write to. Never surfaces an error:
  /// if this fails the attempt is simply started (and submitted) later by the pending queue.
  void unawaitedStart() {
    if (state == null || state!.sessionId != null) return;
    _env.sessionRepository
        .startSession(childId: _childId, activityId: state!.activityId, planItemId: _planItemId, clientOpId: _clientOpId, auth: _auth)
        .then((session) {
      if (state != null && state!.activityId == session.activity.id) {
        state = state?.copyWith(sessionId: session.id);
      }
    }).catchError((Object _) {
      // Offline or the server is unreachable: stays null, handled by finish()/PendingQueue.
    });
  }

  void setAnswer(String stepId, Object? value) {
    final PlayerState? s = state;
    if (s == null) return;
    state = s.copyWith(answers: <String, dynamic>{...s.answers, stepId: value});
    _scheduleAutosave();
  }

  void useHint() {
    final PlayerState? s = state;
    if (s == null) return;
    state = s.copyWith(hintsUsed: s.hintsUsed + 1);
    _scheduleAutosave();
  }

  void setParentAssist(bool value) {
    final PlayerState? s = state;
    if (s == null) return;
    state = s.copyWith(parentAssist: value);
    _scheduleAutosave();
  }

  void goToStep(int index) {
    final PlayerState? s = state;
    if (s == null) return;
    final int clamped = index.clamp(0, s.childSteps.isEmpty ? 0 : s.childSteps.length - 1);
    state = s.copyWith(stepIndex: clamped);
  }

  void nextStep() => goToStep((state?.stepIndex ?? 0) + 1);

  void previousStep() => goToStep((state?.stepIndex ?? 0) - 1);

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 1200), _autosaveNow);
  }

  Future<void> _autosaveNow() async {
    final PlayerState? s = state;
    if (s == null) return;
    if (s.sessionId == null) {
      unawaitedStart();
      return; // the just-started session will hold stale answers; the next debounce tick will autosave them
    }
    try {
      await _env.sessionRepository.autosave(
        s.sessionId!,
        answers: s.answers,
        hintsUsed: s.hintsUsed,
        parentAssist: s.parentAssist,
        auth: _auth,
      );
    } on ApiException {
      // Best effort only; the final submit (queued if needed) is what must not be lost.
    }
  }

  /// Submits (or, if offline, enqueues) the finished attempt. Always returns normally: the caller shows the
  /// completion screen either way and reads [PlayerState.queuedOffline] for the sync badge.
  Future<void> finish() async {
    final PlayerState? s = state;
    if (s == null || s.submitting || s.submitted) return;
    _autosaveTimer?.cancel();
    state = s.copyWith(submitting: true, clearError: true);
    final int durationSec = DateTime.now().difference(_openedAt).inSeconds;
    final Map<String, dynamic> body = <String, dynamic>{
      'answers': s.answers,
      'hints_used': s.hintsUsed,
      'parent_assist': s.parentAssist,
      'duration_sec': durationSec < 0 ? 0 : durationSec,
    };

    // Try once, right now, if we already have a session: gives the parent an immediate mastery/score update
    // instead of waiting for the next queue flush.
    if (s.sessionId != null) {
      try {
        final SessionOut out = await _env.sessionRepository.submitSession(s.sessionId!, body, auth: _auth);
        state = state?.copyWith(submitting: false, submitted: true, queuedOffline: false, result: out.result);
        _refreshTodayIfPossible();
        return;
      } on ApiException {
        // Fall through to the queue below (covers offline, timeouts and transient server errors alike).
      }
    }

    final PendingSubmit item = PendingSubmit(
      id: newUuid(),
      sessionId: s.sessionId,
      childId: _childId,
      activityId: s.activityId,
      planItemId: _planItemId,
      clientOpId: _clientOpId,
      body: body,
      occurredAt: DateTime.now().toUtc(),
      createdAt: DateTime.now().toUtc(),
      auth: _auth == AuthKind.parent ? 'parent' : 'child',
    );
    await _env.pendingQueue.enqueue(item);
    state = state?.copyWith(submitting: false, submitted: true, queuedOffline: true);
    _refreshTodayIfPossible();
    ref.read(pendingQueueProvider.notifier).flushNow();
  }

  void _refreshTodayIfPossible() {
    if (_planItemId != null) ref.read(todayProvider.notifier).markCompletedLocally(_planItemId!);
  }

  void close() {
    _autosaveTimer?.cancel();
    state = null;
  }
}

final NotifierProvider<PlayerNotifier, PlayerState?> playerProvider = NotifierProvider<PlayerNotifier, PlayerState?>(
  PlayerNotifier.new,
);
