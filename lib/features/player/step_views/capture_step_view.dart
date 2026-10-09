import 'package:flutter/material.dart';
import 'package:homeschooling/features/player/step_views/kid_widgets.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:homeschooling/strings.dart';
import 'package:homeschooling/theme/kid_palette.dart';

/// `audio_record` / `photo_evidence`: MVP does not record anything in-app. The child does the activity with
/// a grown-up and taps Done (or Skip, if [CaptureStep.optional]). No answer is sent for this step.
class CaptureStepView extends StatelessWidget {
  const CaptureStepView({super.key, required this.step, required this.onDone, required this.onSkip});

  final CaptureStep step;
  final VoidCallback onDone;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final KidPalette p = KidPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Container(
            width: 120,
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: p.tile(step.type == 'audio_record' ? 1 : 2)),
            child: Text(step.type == 'audio_record' ? '🎤' : '📸', style: const TextStyle(fontSize: 60)),
          ),
        ),
        const SizedBox(height: 20),
        if (step.prompt.isNotEmpty) ...<Widget>[
          KidPrompt(step.prompt, image: step.image),
          const SizedBox(height: 8),
        ],
        const KidHint(Str.captureDoneWithGrownUp),
        const SizedBox(height: 24),
        FilledButton(onPressed: onDone, child: const Text(Str.done)),
        if (step.optional) ...<Widget>[
          const SizedBox(height: 8),
          TextButton(onPressed: onSkip, child: const Text(Str.skip)),
        ],
      ],
    );
  }
}
