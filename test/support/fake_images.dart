import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:homeschooling/core/image_store.dart';
import 'package:homeschooling/models/images.dart';

/// A tiny but valid 1x1 PNG.
final Uint8List kPngBytes = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0, 0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D,
  0x1D, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

String sha256Of(List<int> bytes) => crypto.sha256.convert(bytes).toString();

/// An [ImageAsset] whose hash really is the hash of [bytes].
ImageAsset assetFor(Uint8List bytes, {String id = 'img1', String url = 'https://blob.example/img1?sig=x'}) => ImageAsset(
      id: id,
      url: url,
      sha256: sha256Of(bytes),
      bytes: bytes.length,
      width: 1,
      height: 1,
      contentType: 'image/png',
    );

/// Answers every GET with fixed bytes (or a status code) and counts the calls. No network involved.
class FakeImageAdapter implements HttpClientAdapter {
  FakeImageAdapter(this.bytes, {this.status = 200});

  Uint8List bytes;
  int status;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromBytes(bytes, status, headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>['image/png'],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// An [ImageStore] over a throw-away folder and a [FakeImageAdapter].
class StoreHarness {
  StoreHarness(Uint8List served, {int maxCacheBytes = ImageStore.defaultMaxCacheBytes})
      : directory = Directory.systemTemp.createTempSync('image_store_test'),
        adapter = FakeImageAdapter(served) {
    store = ImageStore(
      directory: () async => directory,
      dio: Dio()..httpClientAdapter = adapter,
      maxCacheBytes: maxCacheBytes,
    );
  }

  final Directory directory;
  final FakeImageAdapter adapter;
  late final ImageStore store;

  void dispose() {
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  }
}
