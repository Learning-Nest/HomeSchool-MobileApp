import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/models/activity.dart';
import 'package:homeschooling/models/images.dart';
import 'package:homeschooling/models/steps.dart';

/// What `GET /activities/{id}` returns for an activity with pictures: the flat step shape, `image` on steps and
/// on options/items (`{asset, alt, sha256, width, height}`), and the `images` manifest inside the definition.
Map<String, dynamic> definitionJson() => <String, dynamic>{
      'slug': 'shapes',
      'title': 'Shapes',
      'subject': 'MAT',
      'duration_min': 10,
      'images': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'a1',
          'url': 'https://blob.example/a1?sig=1',
          'sha256': 'AB' * 32,
          'bytes': 2048,
          'width': 400,
          'height': 200,
          'content_type': 'image/png',
        },
        <String, dynamic>{
          'id': 'a2',
          'url': 'https://blob.example/a2?sig=1',
          'sha256': 'cd' * 32,
          'bytes': 1024,
          'width': 100,
          'height': 100,
          'content_type': 'image/jpeg',
        },
        <String, dynamic>{'id': 'broken'}, // no url or hash: must not take the rest down
      ],
      'steps': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 's1',
          'type': 'single_choice',
          'prompt': 'Which is a circle?',
          'image': <String, dynamic>{'asset': 'a1', 'alt': 'Four shapes', 'sha256': 'ab' * 32, 'width': 400, 'height': 200},
          'options': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'o1',
              'label': 'Ball',
              'image': <String, dynamic>{'asset': 'a2', 'alt': 'A ball'},
            },
            <String, dynamic>{'id': 'o2', 'label': 'Box'},
            <String, dynamic>{
              'id': 'o3',
              'label': 'Moon',
              'image': <String, dynamic>{'asset': 'gone', 'alt': 'The moon', 'missing': true},
            },
          ],
        },
        <String, dynamic>{
          'id': 's2',
          'type': 'match_pairs',
          'prompt': 'Match',
          'left': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'l1', 'label': 'Cat', 'image': <String, dynamic>{'asset': 'a2', 'alt': 'A cat'}},
          ],
          'right': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'r1', 'label': 'Meow'},
          ],
        },
        <String, dynamic>{'id': 's3', 'type': 'parent_checklist', 'prompt': 'Did they?', 'skill_code': 'MAT.X'},
      ],
    };

void main() {
  test('reads the images manifest by asset id and lower-cases the hash', () {
    final ActivityDefinition def = ActivityDefinition.fromJson(definitionJson());
    expect(def.images.keys, <String>['a1', 'a2']);
    final ImageAsset a1 = def.images['a1']!;
    expect(a1.url, 'https://blob.example/a1?sig=1');
    expect(a1.sha256, 'ab' * 32);
    expect(a1.bytes, 2048);
    expect(a1.aspectRatio, 2.0);
    expect(a1.contentType, 'image/png');
  });

  test('a step picture is resolved against the manifest', () {
    final SingleChoiceStep step = ActivityDefinition.fromJson(definitionJson()).steps.first as SingleChoiceStep;
    expect(step.image, isNotNull);
    expect(step.image!.assetId, 'a1');
    expect(step.image!.alt, 'Four shapes');
    expect(step.image!.usable, isTrue);
    expect(step.image!.asset!.id, 'a1');
  });

  test('choices keep their words and optionally a picture', () {
    final SingleChoiceStep step = ActivityDefinition.fromJson(definitionJson()).steps.first as SingleChoiceStep;
    expect(step.options.map((Choice c) => c.label), <String>['Ball', 'Box', 'Moon']);
    expect(step.options[0].image!.usable, isTrue);
    expect(step.options[0].image!.alt, 'A ball');
    expect(step.options[1].image, isNull);
  });

  test('a picture the server could not find is not usable, and its words are still there', () {
    final SingleChoiceStep step = ActivityDefinition.fromJson(definitionJson()).steps.first as SingleChoiceStep;
    final Choice moon = step.options[2];
    expect(moon.label, 'Moon');
    expect(moon.image!.missing, isTrue);
    expect(moon.image!.usable, isFalse);
  });

  test('a picture that is not in the manifest is not usable either', () {
    final ImageRef? ref = ImageRef.tryParse(<String, dynamic>{'asset': 'zzz', 'alt': 'x'}, const <String, ImageAsset>{});
    expect(ref, isNotNull);
    expect(ref!.usable, isFalse);
  });

  test('match items carry pictures too', () {
    final MatchPairsStep step = ActivityDefinition.fromJson(definitionJson()).steps[1] as MatchPairsStep;
    expect(step.left.single.image!.usable, isTrue);
    expect(step.right.single.image, isNull);
  });

  test('childImages lists each downloadable picture once and skips missing and parent-only steps', () {
    final ActivityDefinition def = ActivityDefinition.fromJson(definitionJson());
    expect(def.childImages.map((ImageAsset a) => a.id), <String>['a1', 'a2']);
  });

  test('an activity without pictures parses exactly as before', () {
    final ActivityDefinition def = ActivityDefinition.fromJson(<String, dynamic>{
      'slug': 'x',
      'title': 'X',
      'steps': <Map<String, dynamic>>[
        <String, dynamic>{'id': 's1', 'type': 'instruction', 'text': 'Hello'},
        <String, dynamic>{
          'id': 's2',
          'type': 'single_choice',
          'prompt': 'Pick',
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'a', 'label': 'A'},
          ],
        },
      ],
    });
    expect(def.images, isEmpty);
    expect(def.childImages, isEmpty);
    expect((def.steps.first as InstructionStep).image, isNull);
    expect((def.steps[1] as SingleChoiceStep).options.single.image, isNull);
  });

  test('an image reference without an asset id is ignored instead of failing the activity', () {
    final ImageRef? ref = ImageRef.tryParse(<String, dynamic>{'alt': 'x'}, const <String, ImageAsset>{});
    expect(ref, isNull);
    expect(ImageRef.tryParse('nonsense', const <String, ImageAsset>{}), isNull);
    expect(ImageRef.tryParse(null, const <String, ImageAsset>{}), isNull);
  });

  test('the activity detail response carries the manifest through', () {
    final Map<String, dynamic> json = <String, dynamic>{
      'id': 'act1',
      'title': 'Shapes',
      'slug': 'shapes',
      'skills': <String>['MAT.X'],
      'definition': definitionJson(),
    };
    final ActivityDetail detail = ActivityDetail.fromJson(json);
    expect(detail.definition.childImages, hasLength(2));
  });
}
