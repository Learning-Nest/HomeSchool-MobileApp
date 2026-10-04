import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/state/auth_providers.dart';
import 'package:homeschooling/state/router_guard.dart';

/// Pure-function tests for the route guard behind `app.dart`'s `GoRouter.redirect` — no widget pump needed.
void main() {
  String? decide({
    ConfigPhase configPhase = ConfigPhase.ready,
    AuthStatus authStatus = AuthStatus.signedIn,
    bool isChildMode = false,
    bool tempLogin = false,
    required String location,
  }) {
    return computeRedirect(
      configPhase: configPhase,
      authStatus: authStatus,
      isChildMode: isChildMode,
      tempLogin: tempLogin,
      location: location,
    );
  }

  group('config gating', () {
    test('while config loads, everything redirects to splash', () {
      expect(decide(configPhase: ConfigPhase.loading, location: Routes.login), Routes.splash);
      expect(decide(configPhase: ConfigPhase.loading, location: Routes.splash), isNull);
    });

    test('update required overrides everything else, even mid-flow screens', () {
      expect(decide(configPhase: ConfigPhase.updateRequired, location: Routes.profiles), Routes.updateRequired);
      expect(decide(configPhase: ConfigPhase.updateRequired, location: Routes.updateRequired), isNull);
    });
  });

  group('auth gating', () {
    test('restoring a session always shows splash', () {
      expect(decide(authStatus: AuthStatus.restoring, location: Routes.profiles), Routes.splash);
    });

    test('signed out can only reach login/signup', () {
      expect(decide(authStatus: AuthStatus.signedOut, location: Routes.login), isNull);
      expect(decide(authStatus: AuthStatus.signedOut, location: Routes.signup), isNull);
      expect(decide(authStatus: AuthStatus.signedOut, location: Routes.profiles), Routes.login);
      expect(decide(authStatus: AuthStatus.signedOut, location: Routes.child), Routes.login);
    });

    test('signed in on an entry screen lands on profiles (or child home in child mode)', () {
      expect(decide(location: Routes.login), Routes.profiles);
      expect(decide(location: Routes.splash), Routes.profiles);
      expect(decide(isChildMode: true, location: Routes.login), Routes.child);
    });
  });

  group('forgot password / temporary password', () {
    test('signed out can reach the forgot-password screen but not the change-password screen', () {
      expect(decide(authStatus: AuthStatus.signedOut, location: Routes.forgotPassword), isNull);
      expect(decide(authStatus: AuthStatus.signedOut, location: Routes.changePassword), Routes.login);
    });

    test('after a temporary-password sign-in only the change-password screen is reachable', () {
      expect(decide(tempLogin: true, location: Routes.changePassword), isNull);
      for (final String route in <String>[
        Routes.profiles,
        Routes.login,
        Routes.splash,
        Routes.guardian,
        Routes.parentDashboard,
        Routes.child,
      ]) {
        expect(decide(tempLogin: true, location: route), Routes.changePassword, reason: route);
      }
      expect(decide(tempLogin: true, isChildMode: true, location: Routes.child), Routes.changePassword);
    });

    test('once the password is changed the change-password screen sends you on', () {
      expect(decide(location: Routes.changePassword), Routes.profiles);
      expect(decide(isChildMode: true, location: Routes.changePassword), Routes.child);
    });

    test('a signed-out temp flag changes nothing (sign-in comes first)', () {
      expect(decide(authStatus: AuthStatus.signedOut, tempLogin: true, location: Routes.login), isNull);
    });
  });

  group('child-mode lock', () {
    test('child mode only allows /child, /player/* and the PIN pad', () {
      expect(decide(isChildMode: true, location: Routes.child), isNull);
      expect(decide(isChildMode: true, location: '${Routes.player}/abc-123'), isNull);
      expect(decide(isChildMode: true, location: Routes.pinVerify), isNull);
    });

    test('child mode redirects away from every parent screen', () {
      for (final String parentRoute in <String>[
        Routes.profiles,
        Routes.addChild,
        Routes.guardian,
        Routes.parentDashboard,
        '/parent/planner',
        '/parent/settings',
      ]) {
        expect(decide(isChildMode: true, location: parentRoute), Routes.child, reason: parentRoute);
      }
    });

    test('parent mode cannot sit on /child (only reachable via child mode)', () {
      expect(decide(location: Routes.child), Routes.profiles);
    });

    test('parent mode is untouched for its own screens', () {
      expect(decide(location: Routes.profiles), isNull);
      expect(decide(location: Routes.parentDashboard), isNull);
      expect(decide(location: '/parent/reviews'), isNull);
    });
  });
}
