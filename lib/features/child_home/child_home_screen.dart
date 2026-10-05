import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeschooling/core/auth_tokens.dart';
import 'package:homeschooling/core/dates.dart';
import 'package:homeschooling/features/common/child_themed.dart';
import 'package:homeschooling/features/common/state_views.dart';
import 'package:homeschooling/features/common/subject_emoji.dart';
import 'package:homeschooling/features/common/theme_picker.dart';
import 'package:homeschooling/features/player/step_views/kid_widgets.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/models/plan.dart';
import 'package:homeschooling/state/child_mode_providers.dart';
import 'package:homeschooling/state/plan_providers.dart';
import 'package:homeschooling/state/router_guard.dart';
import 'package:homeschooling/state/session_player_providers.dart';
import 'package:homeschooling/state/theme_providers.dart';
import 'package:homeschooling/strings.dart';
import 'package:homeschooling/theme/kid_palette.dart';
import 'package:homeschooling/theme/theme_options.dart';

/// The child's whole world while the device is in child mode: today's plan and nothing else — no settings,
/// no navigation to parent screens. Leaving requires a grown-up's PIN (see `_switchProfile`).
class ChildHomeScreen extends ConsumerStatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  ConsumerState<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends ConsumerState<ChildHomeScreen> {
  String? _loadedForChildId;

  @override
  Widget build(BuildContext context) {
    final ActiveChildState active = ref.watch(activeChildProvider);
    final Child? child = active.child;

    if (child != null && _loadedForChildId != child.id) {
      _loadedForChildId = child.id;
      Future<void>.microtask(() => ref.read(todayProvider.notifier).load(child.id, auth: AuthKind.child));
    }

    final ThemeOption option = ref.watch(themeSettingsProvider.select((ThemeSettings t) => t.forChild(child?.id)));

    return PopScope(
      canPop: false,
      child: ChildThemed(
        child: Scaffold(
          appBar: AppBar(
            title: Text(child == null ? Str.appName : Str.greeting(dayPart(DateTime.now()), child.displayName)),
            automaticallyImplyLeading: false,
            actions: <Widget>[
              IconButton(
                key: const ValueKey<String>('child-theme-button'),
                icon: const Icon(Icons.palette_rounded),
                tooltip: Str.themeButtonTooltip,
                onPressed: child == null ? null : () => _pickTheme(context, ref, child.id, option.id),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                tooltip: Str.backToParent,
                onPressed: () => _switchProfile(context, ref),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                // A clear, labelled button: the small icon in the app bar is easy to miss for a child.
                if (child != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        key: const ValueKey<String>('child-theme-bar'),
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                        onPressed: () => _pickTheme(context, ref, child.id, option.id),
                        icon: Text(option.emoji, style: const TextStyle(fontSize: 22)),
                        label: Text(Str.themeCurrent(option.name)),
                      ),
                    ),
                  ),
                Expanded(child: _body(active)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickTheme(BuildContext context, WidgetRef ref, String childId, String currentId) {
    showThemePicker(
      context,
      title: Str.themeChooseKid,
      selectedId: currentId,
      onSelected: (String id) => ref.read(themeSettingsProvider.notifier).setChild(childId, id),
    );
  }

  Widget _body(ActiveChildState active) {
    if (active.busy || active.child == null) return const LoadingView();
    final TodayState today = ref.watch(todayProvider);
    if (today.loading && today.items.isEmpty) return const LoadingView();
    if (today.error != null && today.items.isEmpty) {
      return ErrorView.fromException(
        today.error!,
        onRetry: () => ref.read(todayProvider.notifier).load(active.child!.id, auth: AuthKind.child),
      );
    }
    if (today.items.isEmpty) return const _EmptyToday();

    return RefreshIndicator(
      onRefresh: () => ref.read(todayProvider.notifier).load(active.child!.id, auth: AuthKind.child),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: today.items.length,
        itemBuilder: (BuildContext context, int index) => _ActivityCard(item: today.items[index], index: index),
      ),
    );
  }

  Future<void> _switchProfile(BuildContext context, WidgetRef ref) async {
    final String? token = await context.push<String>(Routes.pinVerify);
    if (token == null || !context.mounted) return;
    final bool ok = await ref.read(activeChildProvider.notifier).exitToParentMode(token);
    if (ok && context.mounted) context.go(Routes.profiles);
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday();

  @override
  Widget build(BuildContext context) {
    final KidPalette p = KidPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(p.mascot, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text(Str.noActivitiesToday, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard({required this.item, required this.index});

  final PlanItem item;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool done = item.isCompleted;
    final KidPalette p = KidPalette.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: p.paper,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: done ? null : () => _start(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          // Dark themes have light default text: OnPaper keeps the card readable on its light background.
          child: OnPaper(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: p.tile(index), shape: BoxShape.circle),
                  child: done
                      ? Icon(Icons.check_rounded, size: 34, color: p.tileText)
                      : Text(subjectEmoji(item.activity.subjectCode), style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                // The title column gets all the remaining width; the button sits under the text (not beside it)
                // so a long title never gets squeezed into a sliver on a narrow phone.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.activity.title,
                        key: ValueKey<String>('activity-title-${item.id}'),
                        // Theme.of(context) here is the screen's (light-on-dark) theme, not OnPaper's, so set the ink explicitly.
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: p.tileText, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text('${item.activity.durationMin} min'),
                      const SizedBox(height: 10),
                      if (done)
                        const Text('\u2B50 ${Str.activityDone}', style: TextStyle(fontWeight: FontWeight.w800))
                      else
                        FilledButton(
                          key: ValueKey<String>('activity-start-${item.id}'),
                          onPressed: () => _start(context, ref),
                          child: Text(item.status == 'in_progress' ? Str.continueActivity : Str.startActivity),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _start(BuildContext context, WidgetRef ref) {
    final Child? child = ref.read(activeChildProvider).child;
    if (child == null) return;
    ref.read(playerProvider.notifier).open(
          childId: child.id,
          summary: item.activity,
          planItemId: item.id,
        );
    context.push('${Routes.player}/${item.activity.id}');
  }
}
