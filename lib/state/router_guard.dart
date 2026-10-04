import 'package:homeschooling/state/auth_providers.dart';

/// Route path constants, kept in one place so the guard and the router agree.
class Routes {
  const Routes._();

  static const String splash = '/splash';
  static const String updateRequired = '/update-required';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String changePassword = '/change-password';
  static const String profiles = '/profiles';
  static const String addChild = '/profiles/add';
  static const String guardian = '/guardian';
  static const String pinVerify = '/pin-verify';
  static const String child = '/child';
  static const String player = '/player';
  static const String parentDashboard = '/parent/dashboard';

  static String editChild(String childId) => '/profiles/edit/$childId';
}

enum ConfigPhase { loading, updateRequired, ready }

/// Pure decision function behind `GoRouter.redirect` (app.dart wires it to the live providers). Testable
/// without a widget pump: see test/router_guard_test.dart.
///
/// Returns the path to redirect to, or null to allow [location] as-is.
String? computeRedirect({
  required ConfigPhase configPhase,
  required AuthStatus authStatus,
  required bool isChildMode,
  required String location,
  bool tempLogin = false,
}) {
  if (configPhase == ConfigPhase.loading) {
    return location == Routes.splash ? null : Routes.splash;
  }
  if (configPhase == ConfigPhase.updateRequired) {
    return location == Routes.updateRequired ? null : Routes.updateRequired;
  }

  if (authStatus == AuthStatus.restoring) {
    return location == Routes.splash ? null : Routes.splash;
  }

  if (authStatus == AuthStatus.signedOut) {
    final bool onAuthScreen =
        location == Routes.login || location == Routes.signup || location == Routes.forgotPassword;
    return onAuthScreen ? null : Routes.login;
  }

  // Signed in from here on. After signing in with an emailed temporary password the only reachable screen is
  // the one that sets a new password (the server enforces the same rule: 403 password_change_required).
  if (tempLogin) {
    return location == Routes.changePassword ? null : Routes.changePassword;
  }

  final bool onEntryScreen = location == Routes.splash ||
      location == Routes.login ||
      location == Routes.signup ||
      location == Routes.forgotPassword ||
      location == Routes.changePassword ||
      location == Routes.updateRequired;
  if (onEntryScreen) {
    return isChildMode ? Routes.child : Routes.profiles;
  }

  if (isChildMode) {
    // Child-mode lock: only the child's own screens and the PIN pad (the one door back to parent screens)
    // are reachable. Everything else — including the profile switcher, planner, settings — is off limits.
    final bool allowed = location == Routes.child || location.startsWith(Routes.player) || location == Routes.pinVerify;
    return allowed ? null : Routes.child;
  }

  // Parent mode: /child is only valid while isChildMode is true.
  if (location == Routes.child) return Routes.profiles;

  return null;
}
