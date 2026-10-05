import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/state/family_providers.dart';
import 'package:homeschooling/state/parent_view_providers.dart';
import 'package:homeschooling/state/router_guard.dart';
import 'package:homeschooling/strings.dart';

const List<_Tab> _tabs = <_Tab>[
  _Tab('/parent/dashboard', Icons.today_outlined, Str.dashboardTitle),
  _Tab('/parent/catalogue', Icons.menu_book_outlined, Str.catalogueTitle),
  _Tab('/parent/planner', Icons.calendar_month_outlined, Str.plannerTitle),
  _Tab('/parent/progress', Icons.insights_outlined, Str.progressTitle),
  _Tab('/parent/reviews', Icons.rate_review_outlined, Str.reviewsTitle),
  _Tab('/parent/settings', Icons.settings_outlined, Str.settingsTitle),
];

class _Tab {
  const _Tab(this.path, this.icon, this.label);

  final String path;
  final IconData icon;
  final String label;
}

/// Shared chrome for the parent-facing screens: an app bar with the child switcher and a bottom nav bar.
/// Not a `ShellRoute` (each tab is its own top-level `GoRoute`) so navigation state stays simple.
class ParentScaffold extends ConsumerWidget {
  const ParentScaffold({super.key, required this.currentPath, required this.title, required this.body, this.actions});

  final String currentPath;
  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FamilyState family = ref.watch(familyProvider);
    final Child? viewed = ref.watch(parentViewedChildProvider);
    final int index = _tabs.indexWhere((_Tab t) => t.path == currentPath).clamp(0, _tabs.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.switch_account_outlined),
          tooltip: Str.switchProfile,
          onPressed: () => context.go(Routes.profiles),
        ),
        actions: <Widget>[
          if (family.children.length > 1)
            PopupMenuButton<Child>(
              icon: const Icon(Icons.face),
              tooltip: viewed?.displayName,
              onSelected: (Child c) => ref.read(parentViewedChildProvider.notifier).select(c),
              itemBuilder: (BuildContext ctx) => <PopupMenuEntry<Child>>[
                for (final Child c in family.children) PopupMenuItem<Child>(value: c, child: Text(c.displayName)),
              ],
            ),
          ...?actions,
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (int i) {
          if (_tabs[i].path != currentPath) context.go(_tabs[i].path);
        },
        destinations: <Widget>[
          for (final _Tab t in _tabs) NavigationDestination(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}
