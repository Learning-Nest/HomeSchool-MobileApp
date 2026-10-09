import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/core/api_exception.dart';
import 'package:homeschooling/features/common/state_views.dart';
import 'package:homeschooling/features/pin/pin_set_screen.dart';
import 'package:homeschooling/models/user.dart';
import 'package:homeschooling/state/auth_providers.dart';
import 'package:homeschooling/state/environment.dart';
import 'package:homeschooling/strings.dart';
import 'package:mocktail/mocktail.dart';

import 'support/mock_repositories.dart';

const UserInfo _kUser = UserInfo(id: 'u1', email: 'a@b.com', fullName: 'A B');

/// `PUT /v1/me/pin` answers `409 pin_already_set` when the account already has a PIN. The first-time form must
/// say so (not "check the highlighted fields") and hand the parent back to PIN entry.
void main() {
  late TestEnvironment testEnv;

  setUpAll(() {
    registerFallbackValue('x');
  });

  setUp(() {
    testEnv = TestEnvironment();
  });

  test('pin_already_set has its own explanation', () {
    const ApiException e = ServerException('pin_already_set', '', status: 409);
    expect(errorText(e), Str.errorPinAlreadySet);
    expect(errorText(e), isNot(Str.errorValidation));
  });

  testWidgets('first-time form: an existing PIN refreshes the profile and returns to PIN entry', (
    WidgetTester tester,
  ) async {
    when(() => testEnv.pin.setPin(any(), currentPin: any(named: 'currentPin'))).thenThrow(
      const ServerException('pin_already_set', '', status: 409),
    );
    when(() => testEnv.auth.me()).thenAnswer(
      (_) async => const Me(user: _kUser, memberships: <Membership>[], pinSet: true),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[environmentProvider.overrideWithValue(testEnv.build())],
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext ctx) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(ctx).push(MaterialPageRoute<void>(builder: (_) => const PinSetScreen())),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    // Let the auth notifier finish restoring (no stored session) before the form refreshes the profile.
    final ProviderContainer container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    container.read(authProvider);
    await tester.pump();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(PinSetScreen), findsOneWidget);

    final Finder fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '1234');
    await tester.enterText(fields.at(1), '1234');
    await tester.tap(find.text(Str.pinSetCta));
    await tester.pumpAndSettle();

    verify(() => testEnv.auth.me()).called(1);
    expect(container.read(authProvider).pinSet, isTrue);
    expect(find.byType(PinSetScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
