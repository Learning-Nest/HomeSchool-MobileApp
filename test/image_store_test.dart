import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/core/image_store.dart';
import 'package:homeschooling/models/images.dart';
import 'package:homeschooling/models/steps.dart';

import 'support/fake_images.dart';

void main() {
  late StoreHarness h;
  late ImageAsset asset;

  setUp(() {
    h = StoreHarness(kPngBytes);
    asset = assetFor(kPngBytes);
  });

  tearDown(() => h.dispose());

  test('downloads a picture, checks its hash and keeps it under that hash', () async {
    final File? file = await h.store.fetch(asset);

    expect(file, isNotNull);
    expect(file!.path.endsWith(asset.sha256), isTrue);
    expect(await file.readAsBytes(), kPngBytes);
    expect(h.adapter.requests, hasLength(1));
    expect(h.adapter.requests.single.uri.toString(), asset.url);
  });

  test('a stored picture is not downloaded again, not even through another asset id', () async {
    await h.store.fetch(asset);
    final ImageAsset sameBytesOtherId = assetFor(kPngBytes, id: 'other', url: 'https://blob.example/other?sig=2');
    final File? again = await h.store.fetch(sameBytesOtherId);

    expect(again, isNotNull);
    expect(h.adapter.requests, hasLength(1));
  });

  test('two screens asking for the same picture at once share one download', () async {
    final List<File?> both = await Future.wait<File?>(<Future<File?>>[h.store.fetch(asset), h.store.fetch(asset)]);

    expect(both.every((File? f) => f != null), isTrue);
    expect(h.adapter.requests, hasLength(1));
  });

  test('bytes that do not match the announced hash are thrown away', () async {
    h.adapter.bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);

    expect(await h.store.fetch(asset), isNull);
    expect(await h.store.cached(asset.sha256), isNull);
    expect(h.directory.listSync().whereType<File>(), isEmpty);
  });

  test('a cache folder that disappears while the app runs is created again', () async {
    await h.store.fetch(asset);
    h.directory.deleteSync(recursive: true);

    final File? again = await h.store.fetch(asset);

    expect(again, isNotNull);
    expect(h.adapter.requests, hasLength(2));
  });

  test('a download that turns out larger than the limit is abandoned, whatever the manifest claimed', () async {
    final Directory dir = Directory.systemTemp.createTempSync('image_store_big');
    addTearDown(() => dir.deleteSync(recursive: true));
    final Uint8List big = Uint8List(2048);
    final FakeImageAdapter adapter = FakeImageAdapter(big);
    final ImageStore limited = ImageStore(
      directory: () async => dir,
      dio: Dio()..httpClientAdapter = adapter,
      maxFileBytes: 1024,
    );
    final ImageAsset liar = ImageAsset(id: 'x', url: 'https://blob.example/x', sha256: sha256Of(big), bytes: 10);

    expect(await limited.fetch(liar), isNull);
    expect(dir.listSync().whereType<File>(), isEmpty);
  });

  test('a failing download is null, never an exception, and is retried next time', () async {
    h.adapter.status = 403;
    expect(await h.store.fetch(asset), isNull);

    h.adapter.status = 200;
    expect(await h.store.fetch(asset), isNotNull);
    expect(h.adapter.requests, hasLength(2));
  });

  test('refuses links that are not https (except a developer machine) and hashes that are not hashes', () async {
    expect(await h.store.fetch(assetFor(kPngBytes, url: 'http://cdn.example/a.png')), isNull);
    expect(await h.store.fetch(assetFor(kPngBytes, url: 'file:///etc/passwd')), isNull);
    expect(await h.store.fetch(ImageAsset(id: 'x', url: 'https://blob.example/x', sha256: '../../etc/passwd')), isNull);
    expect(h.adapter.requests, isEmpty);

    expect(await h.store.fetch(assetFor(kPngBytes, url: 'http://10.0.2.2:8000/files/a.png')), isNotNull);
  });

  test('does not download something far larger than any upload the API allows', () async {
    final ImageAsset huge = ImageAsset(id: 'big', url: 'https://blob.example/big', sha256: asset.sha256, bytes: 50 * 1024 * 1024);
    expect(await h.store.fetch(huge), isNull);
    expect(h.adapter.requests, isEmpty);
  });

  test('prefetch downloads each distinct picture of an activity once', () async {
    final ActivityDefinition def = ActivityDefinition.fromJson(<String, dynamic>{
      'slug': 's',
      'title': 'S',
      'images': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'a1', 'url': asset.url, 'sha256': asset.sha256, 'bytes': asset.bytes},
      ],
      'steps': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 's1',
          'type': 'single_choice',
          'prompt': 'p',
          'image': <String, dynamic>{'asset': 'a1', 'alt': 'x'},
          'options': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'o1', 'label': 'A', 'image': <String, dynamic>{'asset': 'a1', 'alt': 'x'}},
          ],
        },
      ],
    });

    await h.store.prefetch(def);

    expect(h.adapter.requests, hasLength(1));
    expect(await h.store.cached(asset.sha256), isNotNull);
  });

  test('the cache is trimmed, oldest first, when it grows past its limit', () async {
    final StoreHarness small = StoreHarness(kPngBytes, maxCacheBytes: 100);
    addTearDown(small.dispose);
    final Directory dir = small.directory;
    final File old = File('${dir.path}/${'1' * 64}')..writeAsBytesSync(Uint8List(80));
    old.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 2)));
    final File newer = File('${dir.path}/${'2' * 64}')..writeAsBytesSync(Uint8List(80));
    newer.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 1)));

    await small.store.fetch(asset);
    for (int i = 0; i < 80 && old.existsSync(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25)); // the trim runs after the download returns
    }

    expect(old.existsSync(), isFalse);
    expect(File('${dir.path}/${asset.sha256}').existsSync(), isTrue);
  });
}
