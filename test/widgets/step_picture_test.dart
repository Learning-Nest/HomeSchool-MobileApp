import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/core/image_store.dart';
import 'package:homeschooling/features/player/step_views/match_pairs_step_view.dart';
import 'package:homeschooling/features/player/step_views/media_prompt_step_view.dart';
import 'package:homeschooling/features/player/step_views/single_choice_step_view.dart';
import 'package:homeschooling/features/player/step_views/step_picture.dart';
import 'package:homeschooling/models/images.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:homeschooling/state/image_providers.dart';

import '../support/fake_images.dart';

void main() {
  late StoreHarness h;
  late ImageAsset asset;

  setUp(() {
    h = StoreHarness(kPngBytes);
    asset = assetFor(kPngBytes);
  });

  tearDown(() => h.dispose());

  /// Lets the real file and HTTP work finish, then rebuilds. Polls instead of guessing a delay.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (int i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        if (h.adapter.requests.isNotEmpty || h.directory.listSync().isNotEmpty) break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pump();
  }

  ImageRef ref(String alt) => ImageRef(assetId: asset.id, alt: alt, asset: asset);

  Widget host(Widget child, {ImageStore? store}) => ProviderScope(
        overrides: [imageStoreProvider.overrideWithValue(store ?? h.store)],
        child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
      );

  testWidgets('shows the downloaded picture with its description for screen readers', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await h.store.fetch(asset); // already on the device
    });
    await tester.pumpWidget(host(StepPicture(image: ref('Four shapes'))));
    await settle(tester);

    expect(find.byType(Image), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).semanticLabel, 'Four shapes');
  });

  testWidgets('shows nothing for a step without a picture', (WidgetTester tester) async {
    await tester.pumpWidget(host(const StepPicture(image: null)));
    expect(find.byType(Image), findsNothing);
    expect(find.byKey(const Key('step-picture-missing')), findsNothing);
  });

  testWidgets('a step picture that cannot be loaded shows its description instead', (WidgetTester tester) async {
    h.adapter.status = 404;
    await tester.pumpWidget(host(StepPicture(image: ref('A red apple'))));
    await settle(tester);

    expect(find.byType(Image), findsNothing);
    expect(find.text('A red apple'), findsOneWidget);
  });

  testWidgets('a choice picture that cannot be loaded just disappears; the words stay and still work', (WidgetTester tester) async {
    h.adapter.status = 404;
    String? picked;
    final SingleChoiceStep step = SingleChoiceStep(
      id: 's1',
      prompt: 'Which is a ball?',
      options: <Choice>[Choice('o1', 'Ball', image: ref('A ball')), const Choice('o2', 'Box')],
    );
    await tester.pumpWidget(host(SingleChoiceStepView(step: step, answer: null, onChanged: (String id) => picked = id)));
    await settle(tester);

    expect(find.text('Ball'), findsOneWidget);
    expect(find.text('A ball'), findsNothing);
    await tester.tap(find.text('Ball'));
    expect(picked, 'o1');
  });

  testWidgets('a choice with a picture shows the picture and the words', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await h.store.fetch(asset);
    });
    final SingleChoiceStep step = SingleChoiceStep(
      id: 's1',
      prompt: 'Which is a ball?',
      image: ref('Some toys'),
      options: <Choice>[Choice('o1', 'Ball', image: ref('A ball')), const Choice('o2', 'Box')],
    );
    await tester.pumpWidget(host(SingleChoiceStepView(step: step, answer: null, onChanged: (String _) {})));
    await settle(tester);

    expect(find.byType(StepPicture), findsNWidgets(2)); // the step picture and one choice picture
    expect(find.text('Which is a ball?'), findsOneWidget);
    expect(find.text('Ball'), findsOneWidget);
    expect(find.text('Box'), findsOneWidget);
  });

  testWidgets('match items show their pictures', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await h.store.fetch(asset);
    });
    final MatchPairsStep step = MatchPairsStep(
      id: 's2',
      prompt: 'Match',
      left: <Choice>[Choice('l1', 'Cat', image: ref('A cat'))],
      right: const <Choice>[Choice('r1', 'Meow')],
    );
    await tester.pumpWidget(host(MatchPairsStepView(step: step, answer: const <List<String>>[], onChanged: (List<List<String>> _) {})));
    await tester.pump();

    expect(find.byType(StepPicture), findsOneWidget);
    expect(find.text('Cat'), findsOneWidget);
    expect(find.text('Meow'), findsOneWidget);
  });

  testWidgets('a media prompt shows its picture instead of the placeholder card', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await h.store.fetch(asset);
    });
    final MediaPromptStep withPicture = MediaPromptStep(id: 's1', caption: 'A cat', altText: 'A cat on a mat', image: ref('A cat on a mat'));
    await tester.pumpWidget(host(MediaPromptStepView(step: withPicture)));
    await tester.pump();
    expect(find.byType(StepPicture), findsOneWidget);
    expect(find.text('🖼️'), findsNothing);

    await tester.pumpWidget(host(const MediaPromptStepView(step: MediaPromptStep(id: 's1', caption: 'A cat', altText: ''))));
    await tester.pump();
    expect(find.byType(StepPicture), findsNothing);
    expect(find.text('🖼️'), findsOneWidget);
  });
}
