import 'package:flutter/material.dart';
import 'package:homeschooling/theme/theme_options.dart';

/// A wrap of cards, one per theme in [kThemeOptions], with the chosen one marked.
class ThemePickerGrid extends StatelessWidget {
  const ThemePickerGrid({super.key, required this.selectedId, required this.onSelected});

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: <Widget>[
        for (final ThemeOption o in kThemeOptions)
          _ThemeCard(option: o, selected: o.id == selectedId, onTap: () => onSelected(o.id)),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.option, required this.selected, required this.onTap});

  final ThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color ink = option.dark ? Colors.white : const Color(0xFF1F1B3D);
    return Semantics(
      button: true,
      selected: selected,
      label: option.name,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 150,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[option.backdropTop, option.backdropBottom],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? option.seed : Colors.transparent, width: 4),
            boxShadow: selected
                ? <BoxShadow>[BoxShadow(color: option.seed.withValues(alpha: 0.4), blurRadius: 12)]
                : const <BoxShadow>[],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(option.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 4),
              Text(
                option.scatter.take(3).join(' '),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                option.name,
                textAlign: TextAlign.center,
                style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (final Color c in option.tiles.take(4))
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                    ),
                ],
              ),
              SizedBox(
                height: 24,
                child: selected ? Icon(Icons.check_circle, color: option.seed, size: 22) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with the theme cards. Calls [onSelected] and closes when one is tapped.
Future<void> showThemePicker(
  BuildContext context, {
  required String title,
  required String selectedId,
  required ValueChanged<String> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, style: Theme.of(ctx).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ThemePickerGrid(
              selectedId: selectedId,
              onSelected: (String id) {
                onSelected(id);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}
