import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeschooling/state/child_mode_providers.dart';
import 'package:homeschooling/state/theme_providers.dart';
import 'package:homeschooling/theme.dart';
import 'package:homeschooling/theme/theme_options.dart';

/// Gives a child screen its playful theme and a painted backdrop, using the theme this child picked. Wrap the
/// whole screen (including its Scaffold): child-theme scaffolds are transparent so the backdrop shows through.
class ChildThemed extends ConsumerWidget {
  const ChildThemed({super.key, required this.child, this.childId});

  final Widget child;

  /// The child whose theme to use; defaults to the child the device is currently handed to.
  final String? childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeSettings settings = ref.watch(themeSettingsProvider);
    final String? activeId = ref.watch(activeChildProvider.select((ActiveChildState a) => a.child?.id));
    final ThemeOption option = settings.forChild(childId ?? activeId);
    return Theme(
      data: AppTheme.childTheme(option),
      child: ChildBackdrop(option: option, child: child),
    );
  }
}

class _Sprinkle {
  const _Sprinkle(this.alignment, this.size, this.index);

  final Alignment alignment;
  final double size;
  final int index;
}

const List<_Sprinkle> _sprinkles = <_Sprinkle>[
  _Sprinkle(Alignment(-0.9, -0.85), 44, 0),
  _Sprinkle(Alignment(0.85, -0.7), 56, 1),
  _Sprinkle(Alignment(-0.7, -0.2), 36, 2),
  _Sprinkle(Alignment(0.9, 0.1), 40, 3),
  _Sprinkle(Alignment(-0.85, 0.55), 52, 4),
  _Sprinkle(Alignment(0.7, 0.85), 44, 5),
];

/// A vertical gradient with a few faint emoji from the theme scattered over it.
class ChildBackdrop extends StatelessWidget {
  const ChildBackdrop({super.key, required this.option, required this.child});

  final ThemeOption option;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[option.backdropTop, option.backdropBottom],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            for (final _Sprinkle s in _sprinkles)
              Align(
                alignment: s.alignment,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: option.dark ? 0.35 : 0.3,
                    child: Text(
                      option.scatter[s.index % option.scatter.length],
                      style: TextStyle(fontSize: s.size),
                    ),
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
