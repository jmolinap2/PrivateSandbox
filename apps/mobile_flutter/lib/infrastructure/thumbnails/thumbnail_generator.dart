import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../domain/entities/file_category.dart';

/// Generates small preview thumbnails at import time, so the library grid
/// doesn't need to decrypt full-size media just to show a tile.
///
/// Only images are handled here — video frames come from native
/// `MediaMetadataRetriever` instead (see
/// `OriginalLocationChannel.generateVideoThumbnail` /
/// `ThumbnailUseCase.generateAndStore`), since decoding a video frame isn't
/// something the `image` package can do. Audio/PDF/generic tiles still fall
/// back to a category icon.
class ThumbnailGenerator {
  const ThumbnailGenerator._();

  static const int maxDimension = 400;
  static const int jpegQuality = 72;

  static Future<Uint8List?> generate({
    required File source,
    required FileCategory category,
  }) async {
    if (category != FileCategory.image) return null;
    try {
      final bytes = await source.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final isWide = decoded.width >= decoded.height;
      final resized = img.copyResize(
        decoded,
        width: isWide ? maxDimension : null,
        height: isWide ? null : maxDimension,
      );
      return Uint8List.fromList(img.encodeJpg(resized, quality: jpegQuality));
    } catch (_) {
      return null;
    }
  }
}
