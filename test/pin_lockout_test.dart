import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/core/api_exception.dart';
import 'package:homeschooling/models/user.dart';
import 'package:homeschooling/state/environment.dart';
import 'package:homeschooling/state/pin_providers.dart';
import 'package:mocktail/mocktail.dart';

import 'support/mock_repositories.dart';

/// How `PUT /me/pin/verify`'s errors (docs/client-guide.md "Parent PIN and child mode") map onto
/// [PinState], which the PIN pad and lockout countdown read.
void main() {
  late TestEnvironment testEnv;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue('000000');
  });

  setUp(() {
    testEnv = TestEnvironment();
    container = ProviderContainer(overrides: <Override>[environmentProvider.overrideWithValue(testEnv.build())]);
  });

  tearDown(() => container.dispose());

  test('a correct PIN clears any previous lockout/error state', () async {
    when(() => testEnv.pin.verify(any())).thenAnswer((_) async => const Elevation(token: 'tok', expiresIn: 300));

    final String? token = await container.read(pinProvider.notifier).verify('1234');

    expect(token, 'tok');
    final PinState state = container.read(pinProvider);
    expect(state.error, isNull);
    expect(state.isLocked(DateTime.now()), isFalse);
  });

  test('a wrong PIN surfaces attempts_remaining without locking', () async {
    when(() => testEnv.pin.verify(any())).thenThrow(
      const ServerException('pin_invalid', '', status: 401, extras: <String, dynamic>{'attempts_remaining': 3}),
    );

    final String? token = await container.read(pinProvider.notifier).verify('0000');

    expect(token, isNull);
    final PinState state = container.read(pinProvider);
    expect(state.attemptsRemaining, 3);
    expect(state.isLocked(DateTime.now()), isFalse);
  });

  test('pin_locked sets a lockout that expires after retry_after_seconds', () async {
    when(() => testEnv.pin.verify(any())).thenThrow(
      const ServerException('pin_locked', '', status: 429, extras: <String, dynamic>{'retry_after_seconds': 900}),
    );

    await container.read(pinProvider.notifier).verify('0000');

    final PinState state = container.read(pinProvider);
    final DateTime now = DateTime.now();
    expect(state.isLocked(now), isTrue);
    expect(state.remainingLockout(now).inSeconds, closeTo(900, 3));

    final DateTime wayLater = now.add(const Duration(seconds: 901));
    expect(state.isLocked(wayLater), isFalse);
    expect(state.remainingLockout(wayLater), Duration.zero);
  });

  test('a cached elevation token from a recent verify is reused without asking the repository again', () async {
    when(() => testEnv.pin.verify(any())).thenAnswer((_) async => const Elevation(token: 'tok', expiresIn: 300));
    await container.read(pinProvider.notifier).verify('1234');

    final String? cached = container.read(pinProvider.notifier).cachedElevationToken();
    expect(cached, 'tok');
    verify(() => testEnv.pin.verify(any())).called(1);
  });
}
