import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeschooling/features/common/child_themed.dart';
import 'package:homeschooling/features/common/state_views.dart';
import 'package:homeschooling/features/player/step_views/capture_step_view.dart';
import 'package:homeschooling/features/player/step_views/instruction_step_view.dart';
import 'package:homeschooling/features/player/step_views/match_pairs_step_view.dart';
import 'package:homeschooling/features/player/step_views/media_prompt_step_view.dart';
import 'package:homeschooling/features/player/step_views/multi_choice_step_view.dart';
import 'package:homeschooling/features/player/step_views/numeric_input_step_view.dart';
import 'package:homeschooling/features/player/step_views/reflection_step_view.dart';
import 'package:homeschooling/features/player/step_views/sequence_order_step_view.dart';
import 'package:homeschooling/features/player/step_views/short_text_step_view.dart';
import 'package:homeschooling/features/player/step_views/single_choice_step_view.dart';
import 'package:homeschooling/features/player/step_views/timer_task_step_view.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:homeschooling/state/session_player_providers.dart';
import 'package:homeschooling/strings.dart';
import 'package:homeschooling/theme/kid_palette.dart';

/// True once [step] has whatever the server needs to score it (steps that take no answer are always "ready").
bool _isAnswered(ActivityStep step, Map<String, dynamic> answers) {
  if (!step.takesAnswer) return true;
  final Object? value = answers[step.id];
  return switch (step) {
    MultiChoiceStep() => value is List && value.isNotEmpty,
    SequenceOrderStep s => value is List && value.length == s.items.length,
    MatchPairsStep s => value is List && value.length == s.left.length,
    TimerTaskStep() => value == true,
    _ => value != null && value != '',
  };
}

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  Future<bool> _confirmExit(BuildContext context) async {
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text(Str.playerExitTitle),
        content: const Text(Str.playerExitBody),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text(Str.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text(Str.playerExitCta)),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayerState? state = ref.watch(playerProvider);

    if (state == null || state.loading) {
      return const ChildThemed(child: Scaffold(body: LoadingView()));
    }
    if (state.error != null && state.definition == null) {
      return ChildThemed(
        child: Scaffold(
          appBar: AppBar(),
          body: ErrorView.fromException(state.error!, onRetry: () => context.pop()),
        ),
      );
    }
    if (state.submitted) {
      return ChildThemed(child: _CompletionView(state: state));
    }

    final List<ActivityStep> steps = state.childSteps;
    if (steps.isEmpty) {
      return ChildThemed(
        child: Scaffold(
          appBar: AppBar(),
          body: const EmptyView(message: Str.emptyGeneric),
        ),
      );
    }
    final ActivityStep step = steps[state.stepIndex.clamp(0, steps.length - 1)];
    final bool isLast = state.stepIndex >= steps.length - 1;
    final bool answered = _isAnswered(step, state.answers);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final bool leave = await _confirmExit(context);
        if (leave && context.mounted) {
          ref.read(playerProvider.notifier).close();
          context.pop();
        }
      },
      child: ChildThemed(
        child: Scaffold(
        appBar: AppBar(
          title: Text('${Str.stepOfLabel} ${state.stepIndex + 1}/${steps.length}'),
          actions: <Widget>[
            if (step.hint != null)
              IconButton(
                icon: const Icon(Icons.lightbulb_outline),
                tooltip: Str.hintButton,
                onPressed: () => _showHint(context, ref, step.hint!),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: <Widget>[
                _StepProgress(current: state.stepIndex, total: steps.length),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: KidPalette.of(context).paper,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _stepBody(context, ref, step, state),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  dense: true,
                  value: state.parentAssist,
                  title: const Text(Str.grownUpHelped),
                  onChanged: (bool v) => ref.read(playerProvider.notifier).setParentAssist(v),
                ),
                Row(
                  children: <Widget>[
                    if (state.stepIndex > 0) ...<Widget>[
                      OutlinedButton.icon(
                        onPressed: () => ref.read(playerProvider.notifier).previousStep(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text(Str.back),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: !answered
                            ? null
                            : () {
                                if (isLast) {
                                  ref.read(playerProvider.notifier).finish();
                                } else {
                                  ref.read(playerProvider.notifier).nextStep();
                                }
                              },
                        child: state.submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(isLast ? Str.playerSubmit : Str.next),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  void _showHint(BuildContext context, WidgetRef ref, String hint) {
    ref.read(playerProvider.notifier).useHint();
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text(Str.hintButton),
        content: Text(hint),
        actions: <Widget>[TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text(Str.ok))],
      ),
    );
  }

  Widget _stepBody(BuildContext context, WidgetRef ref, ActivityStep step, PlayerState state) {
    final notifier = ref.read(playerProvider.notifier);
    final Object? value = state.answers[step.id];
    // Keyed by step id so a view's own state (shuffled order, typed digits) never leaks into the next step.
    return KeyedSubtree(key: ValueKey<String>(step.id), child: _stepView(notifier, step, value));
  }

  Widget _stepView(PlayerNotifier notifier, ActivityStep step, Object? value) {
    return switch (step) {
      InstructionStep s => InstructionStepView(step: s),
      MediaPromptStep s => MediaPromptStepView(step: s),
      SingleChoiceStep s => SingleChoiceStepView(
          step: s,
          answer: value as String?,
          onChanged: (String v) => notifier.setAnswer(s.id, v),
        ),
      MultiChoiceStep s => MultiChoiceStepView(
          step: s,
          answer: (value as List?)?.cast<String>() ?? const <String>[],
          onChanged: (List<String> v) => notifier.setAnswer(s.id, v),
        ),
      NumericInputStep s => NumericInputStepView(
          step: s,
          answer: value as num?,
          onChanged: (num? v) => notifier.setAnswer(s.id, v),
        ),
      ShortTextStep s => ShortTextStepView(
          step: s,
          answer: value as String?,
          onChanged: (String v) => notifier.setAnswer(s.id, v),
        ),
      SequenceOrderStep s => SequenceOrderStepView(
          step: s,
          answer: (value as List?)?.cast<String>(),
          onChanged: (List<String> v) => notifier.setAnswer(s.id, v),
        ),
      MatchPairsStep s => MatchPairsStepView(
          step: s,
          answer: value == null ? const <List<String>>[] : (value as List).map((Object? e) => (e as List).cast<String>()).toList(),
          onChanged: (List<List<String>> v) => notifier.setAnswer(s.id, v),
        ),
      TimerTaskStep s => TimerTaskStepView(
          step: s,
          done: value == true,
          onChanged: (bool v) => notifier.setAnswer(s.id, v),
        ),
      ReflectionStep s => ReflectionStepView(
          step: s,
          answer: value as String?,
          onChanged: (String v) => notifier.setAnswer(s.id, v),
        ),
      CaptureStep s => CaptureStepView(
          step: s,
          onDone: () => notifier.nextStep(),
          onSkip: () => notifier.nextStep(),
        ),
      ParentChecklistStep() || UnknownStep() => const SizedBox.shrink(),
    };
  }
}

/// Rounded segments, one per step: done ones are filled, the current one is highlighted.
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final KidPalette p = KidPalette.of(context);
    final Color off = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18);
    return Row(
      children: <Widget>[
        for (int i = 0; i < total; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: i == current ? 14 : 10,
              decoration: BoxDecoration(
                color: i <= current ? p.tile(i) : off,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}

class _CompletionView extends ConsumerWidget {
  const _CompletionView({required this.state});

  final PlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double? score = state.result?.score;
    final KidPalette p = KidPalette.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(p.mascot, style: const TextStyle(fontSize: 96)),
                const SizedBox(height: 8),
                Text('${p.cheer} ${Str.resultTitle} ${p.cheer}', textAlign: TextAlign.center, style: text.headlineMedium),
                if (score != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _Stars(score: score),
                ],
                if (state.result != null && state.result!.needsReview.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  const Text(Str.resultReviewPending, textAlign: TextAlign.center),
                ],
                if (state.queuedOffline) ...<Widget>[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.cloud_off, size: 18, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(width: 6),
                      Flexible(child: Text(Str.playerOfflineQueued, style: text.bodySmall)),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ref.read(playerProvider.notifier).close();
                      context.pop();
                    },
                    child: const Text(Str.done),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three stars; how many are lit follows the score. Never shows a percentage or a "wrong" message to a child.
class _Stars extends StatelessWidget {
  const _Stars({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final int lit = score >= 0.8 ? 3 : (score >= 0.5 ? 2 : 1);
    return Row(
      key: const ValueKey<String>('result-stars'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < 3; i++)
          Icon(i < lit ? Icons.star_rounded : Icons.star_outline_rounded, size: 52, color: i < lit ? Colors.amber : Colors.white54),
      ],
    );
  }
}
