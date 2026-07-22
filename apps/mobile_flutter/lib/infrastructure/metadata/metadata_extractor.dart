import 'package:mime/mime.dart';

import '../../domain/entities/file_category.dart';

class MetadataExtractor {
  const MetadataExtractor._();

  static String mimeTypeFor(String fileName) {
    return lookupMimeType(fileName) ?? 'application/octet-stream';
  }

  static FileCategory categoryFor(String mimeType) {
    return FileCategoryMime.fromMimeType(mimeType);
  }
}
