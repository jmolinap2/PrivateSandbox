enum FileCategory { image, video, audio, pdf, generic }

extension FileCategoryMime on FileCategory {
  static FileCategory fromMimeType(String mimeType) {
    if (mimeType.startsWith('image/')) return FileCategory.image;
    if (mimeType.startsWith('video/')) return FileCategory.video;
    if (mimeType.startsWith('audio/')) return FileCategory.audio;
    if (mimeType == 'application/pdf') return FileCategory.pdf;
    return FileCategory.generic;
  }
}
