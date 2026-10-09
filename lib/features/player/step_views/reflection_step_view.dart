import 'package:flutter/material.dart';
import 'package:homeschooling/features/player/step_views/kid_widgets.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:homeschooling/strings.dart';
import 'package:homeschooling/theme/kid_palette.dart';

class ReflectionStepView extends StatelessWidget {
  const ReflectionStepView({super.key, required this.step, required this.answer, required this.onChanged});

  final ReflectionStep step;
  final String? answer;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final KidPalette p = KidPalette.of(context);
    final List<String> emojis = step.emojiOptions.isEmpty ? const <String>['😃', '🙂', '😐', '😕'] : step.emojiOptions;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        KidPrompt(step.prompt.isEmpty ? Str.reflectionPrompt : step.prompt, image: step.image),
        const SizedBox(height: 24),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: <Widget>[
            for (int i = 0; i < emojis.length; i++)
              Semantics(
                button: true,
                selected: answer == emojis[i],
                label: emojis[i],
                child: GestureDetector(
                  onTap: () => onChanged(emojis[i]),
                  child: AnimatedScale(
                    scale: answer == emojis[i] ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 160),
                    child: Container(
                      width: 84,
                      height: 84,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: answer == emojis[i] ? p.tile(i) : p.paper,
                        border: Border.all(color: p.tile(i), width: answer == emojis[i] ? 5 : 3),
                      ),
                      child: Text(emojis[i], style: const TextStyle(fontSize: 44)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
