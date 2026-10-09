import 'package:flutter/material.dart';
import 'package:homeschooling/features/player/step_views/step_picture.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:homeschooling/theme/kid_palette.dart';

class InstructionStepView extends StatelessWidget {
  const InstructionStepView({super.key, required this.step});

  final InstructionStep step;

  @override
  Widget build(BuildContext context) {
    final KidPalette p = KidPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (step.image?.usable == true)
          StepPicture(image: step.image, maxHeight: 240)
        else
          Text(p.mascot, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        Text(
          step.text,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
