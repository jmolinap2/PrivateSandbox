import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Publishes a stream as a complete file without exposing partially-written
/// bytes under the final name.
///
/// Bytes are first flushed to a uniquely-named sibling file. Only after the
/// expected length has been written is that file renamed into place. Existing
/// destination files are never intentionally replaced: a numbered name is
/// selected instead.
class AtomicFileWriter {
  const AtomicFileWriter._();

  static const partialSuffix = '.psv-partial';
  static const _uuid = Uuid();

  static Future<File> writeStream({
    required Directory destinationDirectory,
    required String preferredName,
    required Stream<List<int>> bytes,
    required int expectedLength,
    DateTime? modifiedAt,
  }) async {
    if (expectedLength < 0) {
      throw ArgumentError.value(
        expectedLength,
        'expectedLength',
        'must not be negative',
      );
    }
    if (!await destinationDirectory.exists()) {
      throw FileSystemException(
        'Destination directory does not exist',
        destinationDirectory.path,
      );
    }

    final safeName = sanitizeFileName(preferredName);
    final partial = await _createUniquePartial(destinationDirectory, safeName);
    RandomAccessFile? writer;
    var published = false;
    try {
      writer = await partial.open(mode: FileMode.writeOnly);
      var written = 0;
      await for (final chunk in bytes) {
        if (chunk.isEmpty) continue;
        await writer.writeFrom(chunk);
        written += chunk.length;
      }
      await writer.flush();
      await writer.close();
      writer = null;

      if (written != expectedLength) {
        throw FileSystemException(
          'Incomplete output: expected $expectedLength bytes, wrote $written',
          partial.path,
        );
      }

      final destination = await _nextAvailableDestination(
        destinationDirectory,
        safeName,
      );
      final result = await partial.rename(destination.path);
      published = true;

      if (modifiedAt != null) {
        try {
          await result.setLastModified(modifiedAt);
        } catch (_) {
          // Some document-provider-backed destinations do not expose mtime.
        }
      }
      return result;
    } finally {
      if (writer != null) {
        try {
          await writer.close();
        } catch (_) {
          // The operation is already failing; continue to partial cleanup.
        }
      }
      if (!published) {
        try {
          if (await partial.exists()) await partial.delete();
        } catch (_) {
          // A later export to the same directory can remove stale partials.
        }
      }
    }
  }

  /// Removes only this application's old partial files. It deliberately does
  /// not touch other hidden files in a user-selected destination.
  static Future<int> cleanupStalePartials(
    Directory directory, {
    Duration minimumAge = const Duration(days: 1),
    DateTime? now,
  }) async {
    if (!await directory.exists()) return 0;
    final cutoff = (now ?? DateTime.now()).subtract(minimumAge);
    var removed = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !p.basename(entity.path).endsWith(partialSuffix)) {
        continue;
      }
      try {
        if ((await entity.lastModified()).isAfter(cutoff)) continue;
        await entity.delete();
        removed++;
      } on FileSystemException {
        // Best-effort cleanup; inability to remove one partial must not make
        // a subsequent export fail.
      }
    }
    return removed;
  }

  static String sanitizeFileName(String preferredName) {
    var safe = preferredName.replaceAll(RegExp(r'[/\\\x00-\x1F]'), '_').trim();
    if (safe.isEmpty || safe == '.' || safe == '..') {
      safe = 'archivo';
    }
    return safe;
  }

  static Future<File> _createUniquePartial(
    Directory directory,
    String safeName,
  ) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final candidate = File(
        p.join(directory.path, '.$safeName.${_uuid.v4()}$partialSuffix'),
      );
      try {
        await candidate.create(exclusive: true);
        return candidate;
      } on FileSystemException {
        // UUID collisions are exceptionally unlikely, but retrying also
        // handles a stale file with the same generated name.
      }
    }
    throw FileSystemException(
      'Could not allocate a temporary output file',
      directory.path,
    );
  }

  static Future<File> _nextAvailableDestination(
    Directory directory,
    String safeName,
  ) async {
    final extension = p.extension(safeName);
    final stem = extension.isEmpty
        ? safeName
        : safeName.substring(0, safeName.length - extension.length);
    for (var index = 0; index < 10000; index++) {
      final name = index == 0 ? safeName : '$stem ($index)$extension';
      final candidate = File(p.join(directory.path, name));
      if (!await candidate.exists()) return candidate;
    }
    throw FileSystemException(
      'Could not find an available destination name',
      directory.path,
    );
  }
}
