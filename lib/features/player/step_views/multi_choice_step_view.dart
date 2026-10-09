import 'package:flutter/material.dart';
import 'package:homeschooling/features/player/step_views/kid_widgets.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:homeschooling/strings.dart';

class MultiChoiceStepView extends StatelessWidget {
  const MultiChoiceStepView({super.key, required this.step, required this.answer, required this.onChanged});

  final MultiChoiceStep step;

  /// Selected option ids.
  final List<String> answer;
  final ValueChanged<List<String>> onChanged;

  void _toggle(String id) {
    final List<String> next = List<String>.of(answer);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        KidPrompt(step.prompt, image: step.image),
        const SizedBox(height: 4),
        const KidHint(Str.multiChoiceHint),
        const SizedBox(height: 16),
        for (int i = 0; i < step.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KidChoiceButton(
              label: step.options[i].label,
              image: step.options[i].image,
              index: i,
              multi: true,
              selected: answer.contains(step.options[i].id),
              onTap: () => _toggle(step.options[i].id),
            ),
          ),
      ],
    );
  }
}
