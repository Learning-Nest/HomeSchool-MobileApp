import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeschooling/core/image_store.dart';

/// The on-device picture cache shared by the player and everything else that shows activity pictures.
/// Tests override this with an [ImageStore] that points at a temporary folder and a fake HTTP adapter.
final Provider<ImageStore> imageStoreProvider = Provider<ImageStore>((Ref ref) => ImageStore());
