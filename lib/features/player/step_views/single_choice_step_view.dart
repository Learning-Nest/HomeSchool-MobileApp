import 'package:flutter/material.dart';
import 'package:homeschooling/features/player/step_views/kid_widgets.dart';
import 'package:homeschooling/models/steps.dart';

class SingleChoiceStepView extends StatelessWidget {
  const SingleChoiceStepView({super.key, required this.step, required this.answer, required this.onChanged});

  final SingleChoiceStep step;

  /// The selected option id, or null.
  final String? answer;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        KidPrompt(step.prompt),
        const SizedBox(height: 20),
        for (int i = 0; i < step.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KidChoiceButton(
              label: step.options[i].label,
              index: i,
              selected: answer == step.options[i].id,
              onTap: () => onChanged(step.options[i].id),
            ),
          ),
      ],
    );
  }
}
