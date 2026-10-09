import 'package:flutter/material.dart';
import 'package:homeschooling/features/player/step_views/kid_widgets.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:homeschooling/strings.dart';
import 'package:homeschooling/theme/kid_palette.dart';

class ShortTextStepView extends StatefulWidget {
  const ShortTextStepView({super.key, required this.step, required this.answer, required this.onChanged});

  final ShortTextStep step;
  final String? answer;
  final ValueChanged<String> onChanged;

  @override
  State<ShortTextStepView> createState() => _ShortTextStepViewState();
}

class _ShortTextStepViewState extends State<ShortTextStepView> {
  late final TextEditingController _controller = TextEditingController(text: widget.answer ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final KidPalette p = KidPalette.of(context);
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: p.tile(2), width: 3),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        KidPrompt(widget.step.prompt, image: widget.step.image),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          maxLength: widget.step.maxLen,
          maxLines: 3,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: p.tileText, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: Str.shortTextHint,
            filled: true,
            fillColor: p.paper,
            counterStyle: TextStyle(color: p.tileText),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(borderSide: BorderSide(color: p.tile(1), width: 4)),
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
