import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:homeschooling/models/images.dart';
import 'package:homeschooling/models/steps.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads activity pictures once and keeps them on the device, named by their SHA-256.
///
/// * A picture that is already stored is never downloaded again, whichever activity or session it came from.
/// * Every download is checked against the hash the server announced; a file that does not match is discarded.
/// * The signed links never carry the app's login token (this uses its own plain HTTP client).
/// * Nothing here throws: a picture that cannot be had is `null`, and the screens fall back to the text label.
/// * The folder is a cache. It is trimmed to [maxCacheBytes], oldest first, and may be wiped by Android at any
///   time; the next activity simply downloads what it needs again.
class ImageStore {
  ImageStore({
    Future<Directory> Function()? directory,
    Dio? dio,
    this.maxCacheBytes = defaultMaxCacheBytes,
    this.maxFileBytes = defaultMaxFileBytes,
  })  : _resolveDirectory = directory ?? _defaultDirectory,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 30),
                responseType: ResponseType.bytes,
              ),
            );

  static const int defaultMaxCacheBytes = 150 * 1024 * 1024;

  /// The API accepts uploads up to 5 MB; anything much bigger than that is not one of ours.
  static const int defaultMaxFileBytes = 6 * 1024 * 1024;

  final Future<Directory> Function() _resolveDirectory;
  final Dio _dio;
  final int maxCacheBytes;
  final int maxFileBytes;

  final Map<String, Future<File?>> _inFlight = <String, Future<File?>>{};
  Future<Directory>? _directory;

  static Future<Directory> _defaultDirectory() async {
    final Directory base = await getTemporaryDirectory();
    return Directory('${base.path}${Platform.pathSeparator}activity_images');
  }

  static final RegExp _sha256Hex = RegExp(r'^[0-9a-f]{64}$');

  /// The cache folder, created if it is missing (Android may wipe it at any time). A failed lookup is not remembered.
  Future<Directory> _dir() async {
    final Directory dir = await (_directory ??= _resolveDirectory().catchError((Object e, StackTrace st) {
      _directory = null;
      throw e;
    }));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// The stored file for [sha256], or null when it has not been downloaded (or was wiped).
  Future<File?> cached(String sha256) async {
    final String key = sha256.toLowerCase();
    if (!_sha256Hex.hasMatch(key)) return null;
    try {
      final File file = File('${(await _dir()).path}${Platform.pathSeparator}$key');
      if (!await file.exists()) return null;
      unawaited(_markUsed(file));
      return file;
    } catch (_) {
      return null;
    }
  }

  /// The picture as a local file, downloading it first if needed. Null when it cannot be had.
  Future<File?> fetch(ImageAsset asset) {
    final String key = asset.sha256.toLowerCase();
    if (!_sha256Hex.hasMatch(key)) return Future<File?>.value(null);
    // Two screens asking for the same picture share one download.
    return _inFlight.putIfAbsent(key, () {
      final Future<File?> job = _load(asset, key);
      unawaited(job.whenComplete(() {
        _inFlight.remove(key);
      }));
      return job;
    });
  }

  /// Starts downloading every picture of [definition] that the child will see, a few at a time, ahead of use.
  /// Completes when all have finished or failed.
  Future<void> prefetch(ActivityDefinition definition, {int concurrency = 3}) async {
    final List<ImageAsset> queue = definition.childImages;
    if (queue.isEmpty) return;
    int next = 0;
    Future<void> worker() async {
      while (next < queue.length) {
        final ImageAsset asset = queue[next++];
        await fetch(asset);
      }
    }

    final int workers = concurrency.clamp(1, queue.length);
    await Future.wait<void>(<Future<void>>[for (int i = 0; i < workers; i++) worker()]);
  }

  Future<File?> _load(ImageAsset asset, String key) async {
    try {
      final File? have = await cached(key);
      if (have != null) return have;
      if (asset.bytes > maxFileBytes) return null;
      if (!_isFetchable(asset.url)) return null;

      final Response<ResponseBody> response = await _dio.get<ResponseBody>(
        asset.url,
        options: Options(responseType: ResponseType.stream, followRedirects: true, maxRedirects: 3),
      );
      if (!_isFetchable(response.realUri.toString())) return null;
      final ResponseBody? body = response.data;
      if (body == null) return null;
      final BytesBuilder collected = BytesBuilder(copy: false);
      await for (final Uint8List chunk in body.stream) {
        collected.add(chunk);
        if (collected.length > maxFileBytes) return null; // leaving the loop stops the download
      }
      final Uint8List bytes = collected.takeBytes();
      if (bytes.isEmpty) return null;
      if (crypto.sha256.convert(bytes).toString() != key) return null;

      final Directory dir = await _dir();
      final File target = File('${dir.path}${Platform.pathSeparator}$key');
      final File partial = File('${target.path}.part');
      await partial.writeAsBytes(bytes, flush: true);
      await partial.rename(target.path);
      unawaited(_trim());
      return target;
    } catch (_) {
      return null;
    }
  }

  /// Signed links are https in production; plain http is only for a developer's own machine.
  bool _isFetchable(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority) return false;
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' && (uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '10.0.2.2');
  }

  Future<void> _markUsed(File file) async {
    try {
      await file.setLastModified(DateTime.now());
    } catch (_) {
      // Only the cache's age order suffers.
    }
  }

  Future<void> _trim() async {
    try {
      final Directory dir = await _dir();
      final List<File> files = <File>[];
      int total = 0;
      await for (final FileSystemEntity e in dir.list()) {
        if (e is! File) continue;
        if (e.path.endsWith('.part')) {
          // Left behind by a download that was cut off; a live one is younger than this.
          if (DateTime.now().difference(await e.lastModified()) > const Duration(hours: 1)) await e.delete();
          continue;
        }
        files.add(e);
        total += await e.length();
      }
      if (total <= maxCacheBytes) return;
      final Map<File, DateTime> age = <File, DateTime>{for (final File f in files) f: await f.lastModified()};
      files.sort((File a, File b) => age[a]!.compareTo(age[b]!));
      final int target = (maxCacheBytes * 0.8).floor();
      for (final File f in files) {
        if (total <= target) break;
        final int size = await f.length();
        await f.delete();
        total -= size;
      }
    } catch (_) {
      // A cache that cannot be trimmed is still a working cache.
    }
  }
}
