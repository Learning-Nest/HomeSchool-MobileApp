import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeschooling/models/images.dart';
import 'package:homeschooling/state/image_providers.dart';
import 'package:homeschooling/theme/kid_palette.dart';

/// A picture that belongs to a step or to one choice, loaded from the on-device cache.
///
/// Shows nothing at all when the step has no picture, the server marked it missing, or it cannot be loaded and
/// [showAltWhenMissing] is false (choices already show their text). Never throws and never blocks the exercise:
/// the child can always answer from the words.
class StepPicture extends ConsumerStatefulWidget {
  const StepPicture({
    super.key,
    required this.image,
    this.maxHeight = 220,
    this.radius = 20,
    this.showAltWhenMissing = true,
  });

  /// May be null; then this is an empty box of no size.
  final ImageRef? image;
  final double maxHeight;
  final double radius;

  /// When the file cannot be had: show a small card with the description (true for the picture of a step) or
  /// nothing (false for a thumbnail next to a label that says the same thing).
  final bool showAltWhenMissing;

  @override
  ConsumerState<StepPicture> createState() => _StepPictureState();
}

class _StepPictureState extends ConsumerState<StepPicture> {
  Future<File?>? _file;

  @override
  void initState() {
    super.initState();
    _file = _load();
  }

  @override
  void didUpdateWidget(StepPicture old) {
    super.didUpdateWidget(old);
    if (old.image?.asset?.sha256 != widget.image?.asset?.sha256) _file = _load();
  }

  Future<File?>? _load() {
    final ImageRef? image = widget.image;
    final ImageAsset? asset = image?.asset;
    if (image == null || !image.usable || asset == null) return null;
    return ref.read(imageStoreProvider).fetch(asset);
  }

  @override
  Widget build(BuildContext context) {
    final ImageRef? image = widget.image;
    final Future<File?>? future = _file;
    if (image == null) return const SizedBox.shrink();
    if (future == null) return _fallback(context, image);

    final double? ratio = image.asset?.aspectRatio;
    return FutureBuilder<File?>(
      future: future,
      builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
        final File? file = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return _frame(
            ratio,
            const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3))),
            label: image.alt,
            key: const Key('step-picture-loading'),
          );
        }
        if (file == null) return _fallback(context, image);
        return _frame(
          ratio,
          Image.file(
            file,
            fit: BoxFit.contain,
            semanticLabel: image.alt.isEmpty ? null : image.alt,
            excludeFromSemantics: image.alt.isEmpty,
            errorBuilder: (BuildContext context, Object error, StackTrace? stack) => _fallback(context, image),
          ),
          label: null,
          key: const Key('step-picture'),
        );
      },
    );
  }

  Widget _frame(double? ratio, Widget child, {required String? label, required Key key}) {
    final Widget box = ratio == null
        ? SizedBox(height: widget.maxHeight / 2, child: child)
        : AspectRatio(aspectRatio: ratio, child: child);
    return Semantics(
      label: label,
      child: ConstrainedBox(
        key: key,
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        child: ClipRRect(borderRadius: BorderRadius.circular(widget.radius), child: box),
      ),
    );
  }

  Widget _fallback(BuildContext context, ImageRef image) {
    if (!widget.showAltWhenMissing) return const SizedBox.shrink();
    return PictureMissingCard(alt: image.alt, radius: widget.radius);
  }
}

/// Stands in for a step picture that is not available: just its description. Needs no providers.
class PictureMissingCard extends StatelessWidget {
  const PictureMissingCard({super.key, required this.alt, this.radius = 20});

  final String alt;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (alt.trim().isEmpty) return const SizedBox.shrink();
    final KidPalette p = KidPalette.of(context);
    return Container(
      key: const Key('step-picture-missing'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.tile(0).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.image_outlined, color: p.tileText),
          const SizedBox(width: 10),
          Flexible(child: Text(alt, style: TextStyle(color: p.tileText, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
