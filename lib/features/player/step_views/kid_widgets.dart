import 'package:flutter/material.dart';
import 'package:homeschooling/features/player/step_views/step_picture.dart';
import 'package:homeschooling/models/images.dart';
import 'package:homeschooling/theme/kid_palette.dart';

/// Makes everything inside readable on the light "paper" cards used in child mode. The dark themes (Space) have
/// light default text, which is invisible on paper, so text and icons here get the dark palette colour.
/// Wrap any content that sits on [KidPalette.paper] in this.
class OnPaper extends StatelessWidget {
  const OnPaper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color ink = KidPalette.of(context).tileText;
    final ThemeData theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(bodyColor: ink, displayColor: ink),
        iconTheme: theme.iconTheme.copyWith(color: ink),
      ),
      child: DefaultTextStyle.merge(style: TextStyle(color: ink), child: child),
    );
  }
}

/// The question or instruction at the top of an exercise: big, bold and left-aligned. An optional [image] sits
/// right under the words.
class KidPrompt extends StatelessWidget {
  const KidPrompt(this.text, {super.key, this.image});

  final String text;
  final ImageRef? image;

  @override
  Widget build(BuildContext context) {
    final Text words = Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
    );
    final ImageRef? pic = image;
    if (pic == null || (!pic.usable && pic.alt.trim().isEmpty)) return words;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        words,
        const SizedBox(height: 12),
        Center(child: pic.usable ? StepPicture(image: pic) : PictureMissingCard(alt: pic.alt)),
      ],
    );
  }
}

/// A small line of help under the prompt.
class KidHint extends StatelessWidget {
  const KidHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium);
  }
}

/// One big answer button used by single choice and multiple choice. Colourful, at least 68 px tall, and
/// clearly marked when picked (thicker border, strong fill and a tick). [multi] shows a checkbox on the left
/// instead of the A/B/C badge.
class KidChoiceButton extends StatelessWidget {
  const KidChoiceButton({
    super.key,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
    this.multi = false,
    this.image,
  });

  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final bool multi;

  /// A small picture shown between the badge and the words. The words always stay.
  final ImageRef? image;

  @override
  Widget build(BuildContext context) {
    final KidPalette p = KidPalette.of(context);
    final Color accent = p.tile(index);
    final Widget leading = multi
        ? Icon(selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: 32, color: p.tileText)
        : CircleAvatar(
            radius: 18,
            backgroundColor: accent,
            child: Text(
              String.fromCharCode(65 + (index % 26)),
              style: TextStyle(color: p.tileText, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          );
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(68),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: selected ? accent : p.paper,
        foregroundColor: p.tileText,
        side: BorderSide(color: accent, width: selected ? 5 : 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      child: Row(
        children: <Widget>[
          leading,
          const SizedBox(width: 12),
          if (image?.usable == true) ...<Widget>[
            SizedBox(
              width: 76,
              child: StepPicture(image: image, maxHeight: 64, radius: 12, showAltWhenMissing: false),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: p.tileText, fontWeight: FontWeight.w800),
            ),
          ),
          if (selected && !multi) Icon(Icons.check_circle_rounded, size: 32, color: p.tileText),
        ],
      ),
    );
  }
}
