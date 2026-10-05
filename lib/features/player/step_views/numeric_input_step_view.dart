import 'package:flutter/material.dart';
import 'package:homeschooling/features/player/step_views/kid_widgets.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:homeschooling/strings.dart';
import 'package:homeschooling/theme/kid_palette.dart';

/// `numeric_input`: a big answer box and an on-screen number pad, so a child never has to find the keyboard.
class NumericInputStepView extends StatefulWidget {
  const NumericInputStepView({super.key, required this.step, required this.answer, required this.onChanged});

  final NumericInputStep step;
  final num? answer;
  final ValueChanged<num?> onChanged;

  @override
  State<NumericInputStepView> createState() => _NumericInputStepViewState();
}

class _NumericInputStepViewState extends State<NumericInputStepView> {
  static const int _maxLength = 9;

  late String _text = widget.answer == null ? '' : _format(widget.answer!);

  static String _format(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  void _press(String key) {
    String next = _text;
    if (key == 'back') {
      next = next.isEmpty ? next : next.substring(0, next.length - 1);
    } else if (key == '.') {
      if (next.contains('.')) return;
      next = next.isEmpty ? '0.' : '$next.';
    } else if (next.length < _maxLength) {
      next = next == '0' ? key : '$next$key';
    }
    setState(() => _text = next);
    widget.onChanged(num.tryParse(next));
  }

  @override
  Widget build(BuildContext context) {
    final KidPalette p = KidPalette.of(context);
    const List<String> keys = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'back'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        KidPrompt(widget.step.prompt),
        const SizedBox(height: 4),
        const KidHint(Str.numericInputHint),
        const SizedBox(height: 16),
        Container(
          key: const Key('number-display'),
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.paper,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.tile(2), width: 4),
          ),
          child: Text(
            _text.isEmpty ? Str.numericPlaceholder : _text,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: _text.isEmpty ? p.tileText.withValues(alpha: 0.35) : p.tileText,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: <Widget>[
            for (int i = 0; i < keys.length; i++)
              Material(
                color: keys[i] == 'back' ? p.paper : p.tile(i),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: InkWell(
                  key: Key('pad-${keys[i]}'),
                  customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onTap: () => _press(keys[i]),
                  child: Center(
                    child: keys[i] == 'back'
                        ? Icon(Icons.backspace_rounded, size: 30, color: p.tileText, semanticLabel: Str.numberPadBackspace)
                        : Text(
                            keys[i],
                            style: TextStyle(color: p.tileText, fontSize: 32, fontWeight: FontWeight.w900),
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
