import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/core/api_exception.dart';
import 'package:homeschooling/models/user.dart';
import 'package:homeschooling/state/auth_providers.dart';
import 'package:homeschooling/state/environment.dart';
import 'package:mocktail/mocktail.dart';

import 'support/mock_repositories.dart';

const UserInfo _kUser = UserInfo(id: 'u1', email: 'a@b.com', fullName: 'A B');
const Membership _kMembership =
    Membership(familyId: 'f1', familyName: 'The Bs', guardianVerified: false, role: 'owner');

void main() {
  late TestEnvironment testEnv;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue('x');
  });

  setUp(() {
    testEnv = TestEnvironment();
    container = ProviderContainer(overrides: <Override>[environmentProvider.overrideWithValue(testEnv.build())]);
  });

  tearDown(() => container.dispose());

  test('with no stored session, restore lands on signedOut', () async {
    // The default (in-memory) TokenManager in TestEnvironment has no refresh token yet.
    container.read(authProvider); // triggers build()
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authProvider).status, AuthStatus.signedOut);
  });

  test('a successful login stores the session and exposes the user/memberships', () async {
    when(() => testEnv.auth.login(email: any(named: 'email'), password: any(named: 'password'))).thenAnswer(
      (_) async => const AuthResult(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresIn: 900,
        user: _kUser,
        memberships: <Membership>[_kMembership],
      ),
    );

    final bool ok = await container.read(authProvider.notifier).login(email: 'a@b.com', password: 'password123');

    expect(ok, isTrue);
    final AuthState state = container.read(authProvider);
    expect(state.status, AuthStatus.signedIn);
    expect(state.user?.email, 'a@b.com');
    expect(state.family?.familyId, 'f1');
    expect(state.busy, isFalse);
  });

  test('a failed login keeps the user signed out and surfaces the error', () async {
    when(() => testEnv.auth.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenThrow(const ServerException('unauthorized', '', status: 401));

    final bool ok = await container.read(authProvider.notifier).login(email: 'a@b.com', password: 'wrong');

    expect(ok, isFalse);
    final AuthState state = container.read(authProvider);
    expect(state.status, isNot(AuthStatus.signedIn));
    expect(state.error, isNotNull);
    expect(state.busy, isFalse);
  });

  test('logout clears the session even when the server call fails', () async {
    when(() => testEnv.auth.login(email: any(named: 'email'), password: any(named: 'password'))).thenAnswer(
      (_) async => const AuthResult(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresIn: 900,
        user: _kUser,
        memberships: <Membership>[_kMembership],
      ),
    );
    await container.read(authProvider.notifier).login(email: 'a@b.com', password: 'password123');

    when(() => testEnv.auth.logout(any())).thenThrow(const NetworkException());
    await container.read(authProvider.notifier).logout();

    expect(container.read(authProvider).status, AuthStatus.signedOut);
    expect(container.read(authProvider).user, isNull);
  });

  test('handleSessionExpired (triggered by a rejected refresh token) forces signedOut', () async {
    when(() => testEnv.auth.login(email: any(named: 'email'), password: any(named: 'password'))).thenAnswer(
      (_) async => const AuthResult(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresIn: 900,
        user: _kUser,
        memberships: <Membership>[_kMembership],
      ),
    );
    await container.read(authProvider.notifier).login(email: 'a@b.com', password: 'password123');
    expect(container.read(authProvider).status, AuthStatus.signedIn);

    container.read(authProvider.notifier).handleSessionExpired();

    expect(container.read(authProvider).status, AuthStatus.signedOut);
  });

  group('temporary password (forgot password)', () {
    const AuthResult tempResult = AuthResult(
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresIn: 900,
      user: _kUser,
      memberships: <Membership>[_kMembership],
      tempLogin: true,
    );

    Future<void> signInWithTemp() async {
      when(() => testEnv.auth.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => tempResult);
      await container.read(authProvider.notifier).login(email: 'a@b.com', password: 'Temp-Pass-123');
    }

    test('signing in with a temporary password flags the session and remembers it in memory only', () async {
      await signInWithTemp();

      final AuthState state = container.read(authProvider);
      expect(state.status, AuthStatus.signedIn);
      expect(state.tempLogin, isTrue);
      expect(container.read(authProvider.notifier).tempPasswordInUse, 'Temp-Pass-123');
    });

    test('a normal sign-in is not flagged and remembers nothing', () async {
      when(() => testEnv.auth.login(email: any(named: 'email'), password: any(named: 'password'))).thenAnswer(
        (_) async => const AuthResult(
          accessToken: 'access',
          refreshToken: 'refresh',
          expiresIn: 900,
          user: _kUser,
          memberships: <Membership>[_kMembership],
        ),
      );
      await container.read(authProvider.notifier).login(email: 'a@b.com', password: 'password123');

      expect(container.read(authProvider).tempLogin, isFalse);
      expect(container.read(authProvider.notifier).tempPasswordInUse, isNull);
    });

    test('changing the password clears the flag and reloads /me', () async {
      await signInWithTemp();
      when(
        () => testEnv.auth.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer(
        (_) async => const AuthResult(
          accessToken: 'access2',
          refreshToken: 'refresh2',
          expiresIn: 900,
          user: _kUser,
          memberships: <Membership>[_kMembership],
        ),
      );
      when(() => testEnv.auth.me()).thenAnswer(
        (_) async => const Me(user: _kUser, memberships: <Membership>[_kMembership], pinSet: true),
      );

      final bool ok = await container
          .read(authProvider.notifier)
          .changePassword(currentPassword: 'Temp-Pass-123', newPassword: 'a-brand-new-passphrase');

      expect(ok, isTrue);
      final AuthState state = container.read(authProvider);
      expect(state.tempLogin, isFalse);
      expect(state.pinSet, isTrue);
      expect(state.busy, isFalse);
      expect(container.read(authProvider.notifier).tempPasswordInUse, isNull);
    });

    test('a wrong temporary password keeps the forced-change state and surfaces the error', () async {
      await signInWithTemp();
      when(
        () => testEnv.auth.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenThrow(const ServerException('invalid_credentials', '', status: 401));

      final bool ok = await container
          .read(authProvider.notifier)
          .changePassword(currentPassword: 'wrong', newPassword: 'a-brand-new-passphrase');

      expect(ok, isFalse);
      final AuthState state = container.read(authProvider);
      expect(state.tempLogin, isTrue);
      expect(state.error?.code, 'invalid_credentials');
      expect(state.busy, isFalse);
    });

    test('forgotPassword reports success, and failure with the error kept', () async {
      when(() => testEnv.auth.forgotPassword(any())).thenAnswer((_) async {});
      expect(await container.read(authProvider.notifier).forgotPassword('a@b.com'), isTrue);
      expect(container.read(authProvider).busy, isFalse);

      when(() => testEnv.auth.forgotPassword(any())).thenThrow(const NetworkException());
      expect(await container.read(authProvider.notifier).forgotPassword('a@b.com'), isFalse);
      expect(container.read(authProvider).error, isNotNull);
    });
  });
}
