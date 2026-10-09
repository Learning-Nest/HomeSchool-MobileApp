import 'package:flutter/material.dart';
import 'package:homeschooling/features/player/step_views/step_picture.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:homeschooling/theme/kid_palette.dart';

/// Shows the step's picture with its caption. Without a picture it shows the colourful placeholder card, as before;
/// a picture that cannot be loaded shows its description instead.
class MediaPromptStepView extends StatelessWidget {
  const MediaPromptStepView({super.key, required this.step});

  final MediaPromptStep step;

  @override
  Widget build(BuildContext context) {
    final KidPalette p = KidPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (step.image?.usable == true)
          StepPicture(image: step.image, maxHeight: 300, radius: 28)
        else
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: <Color>[p.tile(0), p.tile(2)]),
              borderRadius: BorderRadius.circular(28),
            ),
            alignment: Alignment.center,
            child: const Text('🖼️', style: TextStyle(fontSize: 64)),
          ),
        const SizedBox(height: 16),
        if (step.caption.isNotEmpty)
          Text(
            step.caption,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
