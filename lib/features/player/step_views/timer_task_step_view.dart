import 'dart:async';

import 'package:flutter/material.dart';
import 'package:homeschooling/core/dates.dart';
import 'package:homeschooling/features/player/step_views/kid_widgets.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:homeschooling/strings.dart';
import 'package:homeschooling/theme/kid_palette.dart';

/// `timer_task`: a countdown ring of `duration_sec` plus an optional checklist the child can tick. The answer
/// (if any) is just `true` once the child marks it done — there is no score to compute client side.
class TimerTaskStepView extends StatefulWidget {
  const TimerTaskStepView({super.key, required this.step, required this.done, required this.onChanged});

  final TimerTaskStep step;
  final bool done;
  final ValueChanged<bool> onChanged;

  @override
  State<TimerTaskStepView> createState() => _TimerTaskStepViewState();
}

class _TimerTaskStepViewState extends State<TimerTaskStepView> {
  late int _remaining = widget.step.durationSec;
  Timer? _timer;
  bool _running = false;
  final Set<int> _ticked = <int>{};

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final KidPalette p = KidPalette.of(context);
    final int total = widget.step.durationSec <= 0 ? 1 : widget.step.durationSec;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        KidPrompt(widget.step.prompt, image: widget.step.image),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: _remaining / total,
                    strokeWidth: 16,
                    strokeCap: StrokeCap.round,
                    backgroundColor: p.tile(2).withValues(alpha: 0.25),
                    color: _remaining == 0 ? p.tile(3) : p.tile(2),
                  ),
                ),
                Text(
                  formatMinSec(_remaining),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: _remaining == 0 ? null : _toggle,
            icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
            label: Text(_running ? Str.timerPause : Str.timerStart),
          ),
        ),
        if (widget.step.checklist.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          for (int i = 0; i < widget.step.checklist.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: _ticked.contains(i) ? p.tile(3) : p.paper,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: p.tile(3), width: 3),
                ),
                child: InkWell(
                  customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onTap: () => setState(() {
                    if (!_ticked.remove(i)) _ticked.add(i);
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          _ticked.contains(i) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 30,
                          color: p.tileText,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.step.checklist[i],
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: p.tileText, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: widget.done ? null : () => widget.onChanged(true),
          child: Text(widget.done ? '${Str.done} ✓' : Str.done),
        ),
      ],
    );
  }
}
