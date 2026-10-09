import 'package:homeschooling/models/json.dart';

/// One downloadable picture of the `images` manifest the API adds to an activity definition.
///
/// The [url] is a short-lived signed link (about an hour), so the app downloads each picture once and keeps it
/// on the device under its [sha256]; the same bytes are never fetched twice, even across activities.
class ImageAsset {
  const ImageAsset({
    required this.id,
    required this.url,
    required this.sha256,
    this.bytes = 0,
    this.width = 0,
    this.height = 0,
    this.contentType = '',
  });

  final String id;
  final String url;

  /// Lower-case hex SHA-256 of the file. Downloads that do not match it are thrown away.
  final String sha256;
  final int bytes;
  final int width;
  final int height;
  final String contentType;

  factory ImageAsset.fromJson(Map<String, dynamic> j) => ImageAsset(
        id: reqString(j, 'id'),
        url: reqString(j, 'url'),
        sha256: reqString(j, 'sha256').toLowerCase(),
        bytes: optInt(j, 'bytes') ?? 0,
        width: optInt(j, 'width') ?? 0,
        height: optInt(j, 'height') ?? 0,
        contentType: optString(j, 'content_type') ?? '',
      );

  /// Width divided by height, or null when the server did not say.
  double? get aspectRatio => width > 0 && height > 0 ? width / height : null;
}

/// Reads the manifest leniently: one malformed entry only loses that picture, never the whole activity.
Map<String, ImageAsset> parseImageManifest(Object? value) {
  final Map<String, ImageAsset> out = <String, ImageAsset>{};
  if (value is! List) return out;
  for (final Object? entry in value) {
    if (entry is! Map) continue;
    try {
      final ImageAsset asset = ImageAsset.fromJson(asJsonMap(entry));
      out[asset.id] = asset;
    } on FormatException {
      continue;
    }
  }
  return out;
}

/// A picture used by a step, option or item: `{asset, alt, sha256, width, height, missing?}` on the wire.
class ImageRef {
  const ImageRef({required this.assetId, this.alt = '', this.asset, this.missing = false});

  final String assetId;

  /// What the picture shows, for screen readers and for when it cannot be loaded.
  final String alt;

  /// The manifest entry for [assetId], when the server sent one.
  final ImageAsset? asset;

  /// The server could not find the picture any more; show the text instead.
  final bool missing;

  /// True when there is something to download.
  bool get usable => !missing && asset != null;

  /// Reads `image` from a step or choice. Returns null when there is none (or it is malformed).
  static ImageRef? tryParse(Object? value, Map<String, ImageAsset> manifest) {
    if (value is! Map) return null;
    final Map<String, dynamic> j = asJsonMap(value);
    final String? id = optString(j, 'asset');
    if (id == null || id.isEmpty) return null;
    return ImageRef(
      assetId: id,
      alt: optString(j, 'alt') ?? '',
      asset: manifest[id],
      missing: boolOr(j, 'missing'),
    );
  }
}
