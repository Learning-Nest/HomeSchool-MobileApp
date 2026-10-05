import 'package:flutter/material.dart';
import 'package:homeschooling/features/player/step_views/kid_widgets.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:homeschooling/strings.dart';
import 'package:homeschooling/theme/kid_palette.dart';

/// `match_pairs`: tap one on the left, then its match on the right. A finished pair gets its own colour and
/// number on both cards; tap either card of a pair to undo it. Answer is a list of `[left_id, right_id]`.
class MatchPairsStepView extends StatefulWidget {
  const MatchPairsStepView({super.key, required this.step, required this.answer, required this.onChanged});

  final MatchPairsStep step;

  /// Pairs made so far, each `[leftId, rightId]`.
  final List<List<String>> answer;
  final ValueChanged<List<List<String>>> onChanged;

  @override
  State<MatchPairsStepView> createState() => _MatchPairsStepViewState();
}

class _MatchPairsStepViewState extends State<MatchPairsStepView> {
  String? _selectedLeft;

  int _pairOfLeft(String id) => widget.answer.indexWhere((List<String> p) => p[0] == id);

  int _pairOfRight(String id) => widget.answer.indexWhere((List<String> p) => p[1] == id);

  void _undo(int pairIndex) {
    final List<List<String>> next = List<List<String>>.of(widget.answer)..removeAt(pairIndex);
    setState(() => _selectedLeft = null);
    widget.onChanged(next);
  }

  void _tapLeft(String id) {
    final int pair = _pairOfLeft(id);
    if (pair >= 0) {
      _undo(pair);
      return;
    }
    setState(() => _selectedLeft = _selectedLeft == id ? null : id);
  }

  void _tapRight(String id) {
    final int pair = _pairOfRight(id);
    if (pair >= 0) {
      _undo(pair);
      return;
    }
    final String? left = _selectedLeft;
    if (left == null) return;
    setState(() => _selectedLeft = null);
    widget.onChanged(<List<String>>[...widget.answer, <String>[left, id]]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        KidPrompt(widget.step.prompt),
        const SizedBox(height: 4),
        const KidHint(Str.matchLeftHint),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  for (final Choice c in widget.step.left)
                    _MatchTile(
                      label: c.label,
                      pair: _pairOfLeft(c.id),
                      selected: _selectedLeft == c.id,
                      onTap: () => _tapLeft(c.id),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: <Widget>[
                  for (final Choice c in widget.step.right)
                    _MatchTile(
                      label: c.label,
                      pair: _pairOfRight(c.id),
                      selected: false,
                      onTap: () => _tapRight(c.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.label, required this.pair, required this.selected, required this.onTap});

  final String label;

  /// Index of the finished pair this card belongs to, or -1.
  final int pair;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final KidPalette p = KidPalette.of(context);
    final bool matched = pair >= 0;
    final Color accent = matched ? p.tile(pair) : Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: matched ? accent : (selected ? accent.withValues(alpha: 0.35) : p.paper),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accent, width: matched || selected ? 4 : 2),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              child: Row(
                children: <Widget>[
                  if (matched)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: p.paper,
                        child: Text(
                          '${pair + 1}',
                          style: TextStyle(color: p.tileText, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      label,
                      textAlign: matched ? TextAlign.start : TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: p.tileText, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
