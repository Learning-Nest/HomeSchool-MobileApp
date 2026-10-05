import 'dart:math';

import 'package:flutter/material.dart';
import 'package:homeschooling/features/player/step_views/kid_widgets.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:homeschooling/strings.dart';
import 'package:homeschooling/theme/kid_palette.dart';

/// `sequence_order`: put `items[{id,label}]` in order. The server sends items in the correct order, so this
/// view shuffles them once for display (docs/client-guide.md) and reports ids in the child's current order.
///
/// Two ways to move an item, both working on a plain touch: grab the handle on the right and drag (it starts
/// at once, no long press), or tap the up and down arrows. (The old version relied on Flutter's default long
/// press to start a drag, which children never found.)
class SequenceOrderStepView extends StatefulWidget {
  const SequenceOrderStepView({super.key, required this.step, required this.answer, required this.onChanged});

  final SequenceOrderStep step;

  /// Item ids in the child's current order, or null before the first shuffle.
  final List<String>? answer;
  final ValueChanged<List<String>> onChanged;

  @override
  State<SequenceOrderStepView> createState() => _SequenceOrderStepViewState();
}

class _SequenceOrderStepViewState extends State<SequenceOrderStepView> {
  late List<Choice> _order;

  @override
  void initState() {
    super.initState();
    final Map<String, Choice> byId = <String, Choice>{for (final Choice c in widget.step.items) c.id: c};
    final List<String>? existing = widget.answer;
    if (existing != null && existing.length == widget.step.items.length && existing.every(byId.containsKey)) {
      _order = <Choice>[for (final String id in existing) byId[id]!];
    } else {
      _order = List<Choice>.of(widget.step.items)..shuffle(Random());
      WidgetsBinding.instance.addPostFrameCallback((_) => _report());
    }
  }

  void _report() => widget.onChanged(_order.map((Choice c) => c.id).toList());

  void _move(int from, int to) {
    if (to < 0 || to >= _order.length || from == to) return;
    setState(() {
      final Choice item = _order.removeAt(from);
      _order.insert(to, item);
    });
    _report();
  }

  void _onReorder(int oldIndex, int newIndex) {
    // ReorderableListView reports the slot *before* removal, so a downward move is one too far.
    final int target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    _move(oldIndex, target);
  }

  @override
  Widget build(BuildContext context) {
    final KidPalette p = KidPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        KidPrompt(widget.step.prompt),
        const SizedBox(height: 4),
        const KidHint(Str.sequenceHint),
        const SizedBox(height: 16),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: _onReorder,
          proxyDecorator: (Widget child, int index, Animation<double> animation) => Material(
            color: Colors.transparent,
            elevation: 8,
            shadowColor: Colors.black54,
            borderRadius: BorderRadius.circular(22),
            child: child,
          ),
          children: <Widget>[
            for (int i = 0; i < _order.length; i++)
              Padding(
                key: ValueKey<String>(_order[i].id),
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: p.paper,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: p.tile(i), width: 3),
                  ),
                  child: Row(
                    children: <Widget>[
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: p.tile(i),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(color: p.tileText, fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            _order[i].label,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: p.tileText, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      IconButton(
                        key: Key('seq-up-$i'),
                        tooltip: Str.sequenceMoveUp,
                        iconSize: 32,
                        color: p.tileText,
                        disabledColor: p.tileText.withValues(alpha: 0.2),
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: i > 0 ? () => _move(i, i - 1) : null,
                        icon: const Icon(Icons.keyboard_arrow_up_rounded),
                      ),
                      IconButton(
                        key: Key('seq-down-$i'),
                        tooltip: Str.sequenceMoveDown,
                        iconSize: 32,
                        color: p.tileText,
                        disabledColor: p.tileText.withValues(alpha: 0.2),
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: i < _order.length - 1 ? () => _move(i, i + 1) : null,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                      ReorderableDragStartListener(
                        index: i,
                        child: SizedBox(
                          key: Key('seq-handle-$i'),
                          width: 56,
                          height: 64,
                          child: Icon(Icons.drag_indicator_rounded, size: 34, color: p.tileText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
