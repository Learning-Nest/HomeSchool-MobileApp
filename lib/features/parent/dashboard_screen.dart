import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeschooling/features/common/state_views.dart';
import 'package:homeschooling/features/parent/parent_scaffold.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/models/plan.dart';
import 'package:homeschooling/models/progress.dart';
import 'package:homeschooling/state/parent_view_providers.dart';
import 'package:homeschooling/state/progress_providers.dart';
import 'package:homeschooling/strings.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Child? child = ref.watch(parentViewedChildProvider);
    return ParentScaffold(
      currentPath: '/parent/dashboard',
      title: Str.dashboardTitle,
      body: child == null
          ? const EmptyView(message: Str.emptyGeneric, icon: Icons.face_outlined)
          : _DashboardBody(child: child),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Dashboard> dashboard = ref.watch(dashboardProvider(child.id));
    return dashboard.when(
      loading: () => const LoadingView(),
      error: (Object e, StackTrace st) => ErrorView(
        message: errorTextFromAny(e),
        onRetry: () => ref.invalidate(dashboardProvider(child.id)),
      ),
      data: (Dashboard d) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider(child.id)),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _Stat(label: Str.dashboardActivities, value: '${d.overview.activities}'),
                _Stat(label: Str.dashboardMinutes, value: '${d.overview.minutes}'),
                _Stat(label: Str.dashboardNewSkills, value: '${d.overview.newSkills}'),
                _Stat(label: Str.dashboardStreak, value: '${d.overview.streak}'),
              ],
            ),
            const SizedBox(height: 24),
            Text(Str.dashboardWeekProgress, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: d.overview.weekPlanned == 0 ? 0 : d.overview.weekDone / d.overview.weekPlanned,
            ),
            Text('${d.overview.weekDone}/${d.overview.weekPlanned}'),
            const SizedBox(height: 24),
            Text(Str.todaysPlan, style: Theme.of(context).textTheme.titleMedium),
            for (final PlanItem item in d.today)
              ListTile(
                leading: Icon(item.isCompleted ? Icons.check_circle : Icons.circle_outlined),
                title: Text(item.activity.title),
                subtitle: Text('${item.activity.durationMin} min'),
              ),
            const SizedBox(height: 24),
            Text(Str.recommendedForChild, style: Theme.of(context).textTheme.titleMedium),
            for (final Recommendation r in d.recommendations)
              ListTile(leading: const Icon(Icons.auto_awesome), title: Text(r.activity.title), subtitle: Text(r.reason)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                OutlinedButton(onPressed: () => context.go('/parent/progress'), child: const Text(Str.viewFullProgress)),
                FilledButton(onPressed: () => context.go('/parent/catalogue'), child: const Text(Str.planTomorrow)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
