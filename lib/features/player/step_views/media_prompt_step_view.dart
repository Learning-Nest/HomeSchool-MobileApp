import 'package:flutter/material.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:homeschooling/theme/kid_palette.dart';

/// MVP has no real media pipeline yet: shows the caption/alt text as a placeholder card instead of an image.
class MediaPromptStepView extends StatelessWidget {
  const MediaPromptStepView({super.key, required this.step});

  final MediaPromptStep step;

  @override
  Widget build(BuildContext context) {
    final KidPalette p = KidPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
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
