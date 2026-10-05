import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeschooling/core/app_version.dart';
import 'package:homeschooling/core/config.dart';
import 'package:homeschooling/features/common/theme_picker.dart';
import 'package:homeschooling/features/parent/parent_scaffold.dart';
import 'package:homeschooling/features/pin/pin_set_screen.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/models/remote_config.dart';
import 'package:homeschooling/state/auth_providers.dart';
import 'package:homeschooling/state/config_providers.dart';
import 'package:homeschooling/state/family_providers.dart';
import 'package:homeschooling/state/router_guard.dart';
import 'package:homeschooling/state/theme_providers.dart';
import 'package:homeschooling/strings.dart';
import 'package:homeschooling/theme/theme_options.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text(Str.signOutConfirmTitle),
        content: const Text(Str.signOutConfirmBody),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text(Str.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text(Str.settingsSignOut)),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go(Routes.login);
    }
  }

  Future<void> _deleteChild(BuildContext context, WidgetRef ref, Child child) async {
    final String? token = await context.push<String>(Routes.pinVerify);
    if (token == null || !context.mounted) return;
    await ref.read(familyProvider.notifier).deleteChild(child.id, token);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FamilyState family = ref.watch(familyProvider);
    final AsyncValue<RemoteConfig> config = ref.watch(remoteConfigProvider);
    final ThemeOption parentTheme = ref.watch(themeSettingsProvider.select((ThemeSettings s) => s.parent));

    return ParentScaffold(
      currentPath: '/parent/settings',
      title: Str.settingsTitle,
      body: ListView(
        children: <Widget>[
          ListTile(title: const Text(Str.settingsAppVersion), subtitle: Text(kAppVersion)),
          if (!AppConfig.isProd)
            ListTile(
              title: const Text(Str.settingsEnvironment),
              subtitle: Text(AppConfig.envName),
              leading: const Icon(Icons.bug_report_outlined),
            ),
          const Divider(),
          ListTile(
            key: const ValueKey<String>('settings-theme'),
            title: const Text(Str.settingsTheme),
            subtitle: Text('${parentTheme.emoji}  ${parentTheme.name}'),
            leading: const Icon(Icons.palette_outlined),
            onTap: () => showThemePicker(
              context,
              title: Str.themeChooseParent,
              selectedId: parentTheme.id,
              onSelected: (String id) => ref.read(themeSettingsProvider.notifier).setParent(id),
            ),
          ),
          ListTile(
            title: const Text(Str.settingsChangePin),
            leading: const Icon(Icons.pin_outlined),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (BuildContext ctx) => const PinSetScreen(isChange: true)),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(Str.settingsConsents, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final MapEntry<String, String> purpose in const <String, String>{
            'media_capture': Str.consentMediaCapture,
            'ai_personalization': Str.consentAiPersonalization,
            'product_analytics': Str.consentProductAnalytics,
          }.entries)
            SwitchListTile(
              title: Text(purpose.value),
              value: family.consentGranted(purpose.key),
              onChanged: (bool v) {
                final String? noticeVersion = config.value?.declarationNoticeVersion;
                if (noticeVersion == null) return;
                ref.read(familyProvider.notifier).setConsent(purpose: purpose.key, granted: v, noticeVersion: noticeVersion);
              },
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(Str.settingsDeleteChild, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final Child child in family.children)
            ListTile(
              title: Text(child.displayName),
              trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteChild(context, ref, child)),
            ),
          const Divider(),
          ListTile(
            title: const Text(Str.settingsSignOut, style: TextStyle(color: Colors.red)),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }
}
