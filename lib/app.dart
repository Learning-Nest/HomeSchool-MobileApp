import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homeschooling/features/auth/change_password_screen.dart';
import 'package:homeschooling/features/auth/forgot_password_screen.dart';
import 'package:homeschooling/features/auth/login_screen.dart';
import 'package:homeschooling/features/auth/signup_screen.dart';
import 'package:homeschooling/features/child_home/child_home_screen.dart';
import 'package:homeschooling/features/common/splash_screen.dart';
import 'package:homeschooling/features/common/update_required_screen.dart';
import 'package:homeschooling/features/guardian/guardian_screen.dart';
import 'package:homeschooling/features/parent/catalogue_screen.dart';
import 'package:homeschooling/features/parent/dashboard_screen.dart';
import 'package:homeschooling/features/parent/planner_screen.dart';
import 'package:homeschooling/features/parent/progress_screen.dart';
import 'package:homeschooling/features/parent/reviews_screen.dart';
import 'package:homeschooling/features/parent/settings_screen.dart';
import 'package:homeschooling/features/pin/pin_verify_screen.dart';
import 'package:homeschooling/features/player/player_screen.dart';
import 'package:homeschooling/features/profiles/child_form_screen.dart';
import 'package:homeschooling/features/profiles/profiles_screen.dart';
import 'package:homeschooling/models/child.dart';
import 'package:homeschooling/state/auth_providers.dart';
import 'package:homeschooling/state/child_mode_providers.dart';
import 'package:homeschooling/state/config_providers.dart';
import 'package:homeschooling/state/environment.dart';
import 'package:homeschooling/state/router_guard.dart';
import 'package:homeschooling/state/theme_providers.dart';
import 'package:homeschooling/strings.dart';
import 'package:homeschooling/theme.dart';
import 'package:homeschooling/theme/theme_options.dart';

/// Bridges Riverpod state changes into a [Listenable] so `GoRouter(refreshListenable: ...)` re-evaluates
/// `redirect` whenever auth, config or child-mode state changes — not only when the user navigates.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(remoteConfigProvider, (Object? previous, Object? next) => notifyListeners());
    ref.listen(authProvider, (AuthState? previous, AuthState next) => notifyListeners());
    ref.listen(activeChildProvider, (ActiveChildState? previous, ActiveChildState next) => notifyListeners());
  }
}

final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final _RouterRefresh refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final ConfigPhase phase = ref.read(remoteConfigProvider).when(
            data: (config) => updateIsRequired(config) ? ConfigPhase.updateRequired : ConfigPhase.ready,
            loading: () => ConfigPhase.loading,
            error: (Object _, StackTrace __) => ConfigPhase.loading,
          );
      return computeRedirect(
        configPhase: phase,
        authStatus: ref.read(authProvider).status,
        isChildMode: ref.read(activeChildProvider).isChildMode,
        location: state.uri.path,
        tempLogin: ref.read(authProvider).tempLogin,
      );
    },
    routes: <RouteBase>[
      GoRoute(path: Routes.splash, builder: (BuildContext c, GoRouterState s) => const SplashScreen()),
      GoRoute(
        path: Routes.updateRequired,
        builder: (BuildContext c, GoRouterState s) => const UpdateRequiredScreen(),
      ),
      GoRoute(path: Routes.login, builder: (BuildContext c, GoRouterState s) => const LoginScreen()),
      GoRoute(path: Routes.signup, builder: (BuildContext c, GoRouterState s) => const SignupScreen()),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (BuildContext c, GoRouterState s) =>
            ForgotPasswordScreen(initialEmail: s.extra is String ? s.extra as String : null),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (BuildContext c, GoRouterState s) => const ChangePasswordScreen(),
      ),
      GoRoute(path: Routes.guardian, builder: (BuildContext c, GoRouterState s) => const GuardianScreen()),
      GoRoute(path: Routes.pinVerify, builder: (BuildContext c, GoRouterState s) => const PinVerifyScreen()),
      GoRoute(path: Routes.profiles, builder: (BuildContext c, GoRouterState s) => const ProfilesScreen()),
      GoRoute(
        path: Routes.addChild,
        builder: (BuildContext c, GoRouterState s) => const ChildFormScreen(),
      ),
      GoRoute(
        path: '/profiles/edit/:childId',
        builder: (BuildContext c, GoRouterState s) => ChildFormScreen(existing: s.extra as Child?),
      ),
      GoRoute(path: Routes.child, builder: (BuildContext c, GoRouterState s) => const ChildHomeScreen()),
      GoRoute(
        path: '${Routes.player}/:activityId',
        builder: (BuildContext c, GoRouterState s) => const PlayerScreen(),
      ),
      GoRoute(path: Routes.parentDashboard, builder: (BuildContext c, GoRouterState s) => const DashboardScreen()),
      GoRoute(path: '/parent/planner', builder: (BuildContext c, GoRouterState s) => const PlannerScreen()),
      GoRoute(path: '/parent/catalogue', builder: (BuildContext c, GoRouterState s) => const CatalogueScreen()),
      GoRoute(path: '/parent/progress', builder: (BuildContext c, GoRouterState s) => const ProgressScreen()),
      GoRoute(path: '/parent/reviews', builder: (BuildContext c, GoRouterState s) => const ReviewsScreen()),
      GoRoute(path: '/parent/settings', builder: (BuildContext c, GoRouterState s) => const SettingsScreen()),
    ],
    errorBuilder: (BuildContext c, GoRouterState s) =>
        Scaffold(body: Center(child: Text('${s.error}'))),
  );
});

class HomeSchoolingApp extends ConsumerStatefulWidget {
  const HomeSchoolingApp({super.key});

  @override
  ConsumerState<HomeSchoolingApp> createState() => _HomeSchoolingAppState();
}

class _HomeSchoolingAppState extends ConsumerState<HomeSchoolingApp> {
  @override
  void initState() {
    super.initState();
    // The one place TokenManager's "refresh token was rejected" signal reaches Riverpod state.
    ref.read(environmentProvider).setSessionExpiredHandler(() {
      ref.read(authProvider.notifier).handleSessionExpired();
    });
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(routerProvider);
    final ThemeOption parentTheme = ref.watch(themeSettingsProvider.select((ThemeSettings s) => s.parent));
    return MaterialApp.router(
      title: Str.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.parentLight(parentTheme),
      darkTheme: AppTheme.parentDark(parentTheme),
      routerConfig: router,
    );
  }
}
