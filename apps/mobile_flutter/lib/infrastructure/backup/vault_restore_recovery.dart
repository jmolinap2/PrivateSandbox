import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;

typedef StoredKeyFingerprintReader = Future<String?> Function();

/// Durable, idempotent recovery for a process killed during a full-vault
/// restore.
///
/// The live DB/blobs, same-volume staging, and rollback directories cannot be
/// atomically swapped as a single filesystem object, and Secure Storage is a
/// second transactional domain. Before moving anything, restore writes a
/// bounded journal describing the old filesystem shape and both key
/// fingerprints. Append-only phase markers are flushed after each gate.
///
/// On the next process start [recoverAll] reads the *actual* Secure Storage
/// fingerprint supplied by the caller:
///
/// * restored key present -> the complete new vault is retained;
/// * old key present -> old DB/blobs are restored from rollback;
/// * same key on both sides -> the `new-installed` marker breaks the tie.
///
/// Recovery itself tolerates being killed and can be called repeatedly.
class VaultRestoreRecovery {
  const VaultRestoreRecovery._();

  static const journalVersion = 1;
  static const stagingPrefix = '.vault_restore_staging_';
  static const rollbackPrefix = '.vault_restore_rollback_';
  static const cleanupPrefix = '.vault_restore_cleanup_';
  static const journalFileName = '.restore-journal-v1.json';
  static const phasePrepared = '.phase-prepared';
  static const phaseOldMoved = '.phase-old-moved';
  static const phaseNewInstalled = '.phase-new-installed';
  static const phaseKeyInstalled = '.phase-key-installed';
  static const keyMarkerFileName = '.vault-key-fingerprint-v1';

  static const _databaseSuffixes = <String>['', '-wal', '-shm', '-journal'];
  static final _operationIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
  static final _fingerprintPattern = RegExp(r'^[0-9a-f]{64}$');

  static String fingerprint(Uint8List keyBytes) =>
      crypto.sha256.convert(keyBytes).toString();

  static Directory stagingDirectory(
    Directory supportDirectory,
    String operationId,
  ) => Directory(p.join(supportDirectory.path, '$stagingPrefix$operationId'));

  static Directory rollbackDirectory(
    Directory supportDirectory,
    String operationId,
  ) => Directory(p.join(supportDirectory.path, '$rollbackPrefix$operationId'));

  /// Creates and flushes the pre-swap journal before any live path is moved.
  static Future<VaultRestoreJournalHandle> begin({
    required Directory supportDirectory,
    required String operationId,
    required String? oldKeyFingerprint,
    required String newKeyFingerprint,
  }) async {
    _validateOperationId(operationId);
    _validateFingerprint(oldKeyFingerprint, allowNull: true);
    _validateFingerprint(newKeyFingerprint, allowNull: false);

    final rollback = rollbackDirectory(supportDirectory, operationId);
    if (await rollback.exists()) {
      throw StateError('Ya existe un journal para esta restauración.');
    }
    await rollback.create();

    final liveDb = File(p.join(supportDirectory.path, 'vault.sqlite'));
    final oldSuffixes = <String>[];
    for (final suffix in _databaseSuffixes) {
      if (await File('${liveDb.path}$suffix').exists()) {
        oldSuffixes.add(suffix);
      }
    }
    final oldBlobsExisted = await Directory(
      p.join(supportDirectory.path, 'vault_blobs'),
    ).exists();
    final data = _RestoreJournalData(
      version: journalVersion,
      operationId: operationId,
      oldKeyFingerprint: oldKeyFingerprint,
      newKeyFingerprint: newKeyFingerprint,
      oldDatabaseSuffixes: oldSuffixes,
      oldBlobsExisted: oldBlobsExisted,
    );

    try {
      await _writeDurableJson(
        File(p.join(rollback.path, journalFileName)),
        data.toJson(),
      );
      final handle = VaultRestoreJournalHandle._(
        supportDirectory: supportDirectory,
        rollbackDirectory: rollback,
        data: data,
      );
      await handle.markPrepared();
      return handle;
    } catch (_) {
      if (await rollback.exists()) {
        await rollback.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Resolves every journal before the application opens the live SQLite DB.
  /// Returns the number of restore operations recovered.
  static Future<int> recoverAll({
    required Directory supportDirectory,
    required StoredKeyFingerprintReader readStoredKeyFingerprint,
  }) async {
    if (!await supportDirectory.exists()) return 0;
    await _cleanupRetiredDirectories(supportDirectory);

    final rollbackDirectories = <Directory>[];
    await for (final entity in supportDirectory.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (name.startsWith(rollbackPrefix)) {
        rollbackDirectories.add(entity);
      }
    }
    rollbackDirectories.sort((a, b) => a.path.compareTo(b.path));
    if (rollbackDirectories.length > 16) {
      throw const VaultRestoreRecoveryException(
        'Hay demasiados journals de restauración pendientes.',
      );
    }
    if (rollbackDirectories.isEmpty) {
      await _cleanupOrphanedStaging(supportDirectory, const {});
      return 0;
    }

    final storedFingerprint = await readStoredKeyFingerprint();
    _validateFingerprint(storedFingerprint, allowNull: true);
    final activeOperationIds = <String>{};
    var recovered = 0;
    for (final rollback in rollbackDirectories) {
      final handle = await _readHandle(supportDirectory, rollback);
      activeOperationIds.add(handle.operationId);
      await _recoverOne(handle, storedFingerprint);
      recovered++;
    }

    // Staging created before `begin` contains only authenticated copies and
    // never touched the live vault. Once no journal references it, deletion
    // is always safe and makes pre-swap crash cleanup idempotent too.
    await _cleanupOrphanedStaging(supportDirectory, activeOperationIds);
    return recovered;
  }

  static Future<void> _cleanupOrphanedStaging(
    Directory supportDirectory,
    Set<String> activeOperationIds,
  ) async {
    await for (final entity in supportDirectory.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (!name.startsWith(stagingPrefix)) continue;
      final operationId = name.substring(stagingPrefix.length);
      if (activeOperationIds.contains(operationId)) continue;
      await entity.delete(recursive: true);
    }
  }

  static Future<VaultRestoreJournalHandle> _readHandle(
    Directory supportDirectory,
    Directory rollback,
  ) async {
    final directoryName = p.basename(rollback.path);
    final operationId = directoryName.substring(rollbackPrefix.length);
    _validateOperationId(operationId);
    final journal = File(p.join(rollback.path, journalFileName));
    if (!await journal.exists() || await journal.length() > 16 * 1024) {
      throw const VaultRestoreRecoveryException(
        'El journal de restauración está ausente o fuera de límites.',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(await journal.readAsString());
    } catch (_) {
      throw const VaultRestoreRecoveryException(
        'El journal de restauración no contiene JSON válido.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const VaultRestoreRecoveryException(
        'El journal de restauración tiene una estructura inválida.',
      );
    }
    final data = _RestoreJournalData.fromJson(decoded);
    if (data.operationId != operationId) {
      throw const VaultRestoreRecoveryException(
        'El journal no corresponde con su directorio.',
      );
    }
    return VaultRestoreJournalHandle._(
      supportDirectory: supportDirectory,
      rollbackDirectory: rollback,
      data: data,
    );
  }

  static Future<void> _recoverOne(
    VaultRestoreJournalHandle handle,
    String? storedFingerprint,
  ) async {
    final oldFingerprint = handle.oldKeyFingerprint;
    final newFingerprint = handle.newKeyFingerprint;
    final newWasInstalled = await handle.hasPhase(phaseNewInstalled);
    final keyWasInstalled = await handle.hasPhase(phaseKeyInstalled);

    final matchesNew = storedFingerprint == newFingerprint;
    final matchesOld =
        oldFingerprint != null && storedFingerprint == oldFingerprint;
    final keepNew =
        matchesNew && (!matchesOld || newWasInstalled || keyWasInstalled);
    final rollBackOld =
        matchesOld ||
        (storedFingerprint == null && !keyWasInstalled) ||
        (matchesNew && matchesOld && !newWasInstalled && !keyWasInstalled);

    if (keepNew) {
      await _finishNewVault(handle, storedFingerprint);
      return;
    }
    if (rollBackOld) {
      await _rollBackOldVault(handle, storedFingerprint);
      return;
    }
    if (storedFingerprint == null && keyWasInstalled) {
      // The restore reached its key commit marker, but Secure Storage was
      // subsequently lost. Keep the matching new filesystem; a portable
      // backup restore remains the only valid way to provision a key again.
      await _finishNewVault(handle, storedFingerprint);
      return;
    }
    throw const VaultRestoreRecoveryException(
      'La clave almacenada no corresponde con el journal de restauración.',
    );
  }

  static Future<void> _finishNewVault(
    VaultRestoreJournalHandle handle,
    String? storedFingerprint,
  ) async {
    final liveDb = File(p.join(handle.supportDirectory.path, 'vault.sqlite'));
    final liveBlobs = Directory(
      p.join(handle.supportDirectory.path, 'vault_blobs'),
    );
    if (!await liveDb.exists() || !await liveBlobs.exists()) {
      throw const VaultRestoreRecoveryException(
        'El journal indica commit, pero la bóveda nueva está incompleta.',
      );
    }
    await _deleteDirectoryIfExists(handle.stagingDirectory);
    await _reconcileKeyMarker(handle.supportDirectory, storedFingerprint);
    await _retireRollback(handle);
  }

  static Future<void> _rollBackOldVault(
    VaultRestoreJournalHandle handle,
    String? storedFingerprint,
  ) async {
    final liveDb = File(p.join(handle.supportDirectory.path, 'vault.sqlite'));
    final oldSuffixes = handle.oldDatabaseSuffixes.toSet();
    for (final suffix in _databaseSuffixes) {
      final live = File('${liveDb.path}$suffix');
      final rollback = File(
        p.join(handle.rollbackDirectory.path, 'vault.sqlite$suffix'),
      );
      if (await rollback.exists()) {
        if (await live.exists()) await live.delete();
        await rollback.rename(live.path);
      } else if (!oldSuffixes.contains(suffix) && await live.exists()) {
        await live.delete();
      }
      // If an old path was recorded but no rollback copy remains, an earlier
      // recovery attempt already moved it back. Leaving the live path makes
      // this operation safe to repeat after another process kill.
    }

    final liveBlobs = Directory(
      p.join(handle.supportDirectory.path, 'vault_blobs'),
    );
    final rollbackBlobs = Directory(
      p.join(handle.rollbackDirectory.path, 'vault_blobs'),
    );
    if (await rollbackBlobs.exists()) {
      if (await liveBlobs.exists()) {
        await liveBlobs.delete(recursive: true);
      }
      await rollbackBlobs.rename(liveBlobs.path);
    } else if (!handle.oldBlobsExisted && await liveBlobs.exists()) {
      await liveBlobs.delete(recursive: true);
    }

    await _deleteDirectoryIfExists(handle.stagingDirectory);
    await _reconcileKeyMarker(handle.supportDirectory, storedFingerprint);
    await _retireRollback(handle);
  }

  static Future<void> _reconcileKeyMarker(
    Directory supportDirectory,
    String? storedFingerprint,
  ) async {
    if (storedFingerprint == null) return;
    final marker = File(p.join(supportDirectory.path, keyMarkerFileName));
    final pending = File('${marker.path}.pending');
    final writer = await pending.open(mode: FileMode.write);
    try {
      await writer.writeFrom(utf8.encode(storedFingerprint));
      await writer.flush();
    } finally {
      await writer.close();
    }
    if (await marker.exists()) await marker.delete();
    await pending.rename(marker.path);
  }

  static Future<void> _retireRollback(VaultRestoreJournalHandle handle) async {
    if (!await handle.rollbackDirectory.exists()) return;
    final retired = Directory(
      p.join(
        handle.supportDirectory.path,
        '$cleanupPrefix${handle.operationId}',
      ),
    );
    if (await retired.exists()) {
      try {
        await retired.delete(recursive: true);
      } on FileSystemException {
        return;
      }
    }
    await handle.rollbackDirectory.rename(retired.path);
    try {
      await retired.delete(recursive: true);
    } on FileSystemException {
      // The atomic rename already retired the journal. Startup cleanup can
      // retry deleting private rollback bytes without re-running the swap.
    }
  }

  static Future<void> _cleanupRetiredDirectories(
    Directory supportDirectory,
  ) async {
    await for (final entity in supportDirectory.list(followLinks: false)) {
      if (entity is! Directory ||
          !p.basename(entity.path).startsWith(cleanupPrefix)) {
        continue;
      }
      try {
        await entity.delete(recursive: true);
      } on FileSystemException {
        // Best effort; a live DB must not be blocked by already-retired bytes.
      }
    }
  }

  static Future<void> _writeDurableJson(
    File file,
    Map<String, dynamic> json,
  ) async {
    final bytes = utf8.encode(jsonEncode(json));
    final writer = await file.open(mode: FileMode.write);
    try {
      await writer.writeFrom(bytes);
      await writer.flush();
    } finally {
      await writer.close();
    }
  }

  static Future<void> _writeDurableMarker(File file) async {
    if (await file.exists()) return;
    final writer = await file.open(mode: FileMode.write);
    try {
      await writer.writeByte(1);
      await writer.flush();
    } finally {
      await writer.close();
    }
  }

  static Future<void> _deleteDirectoryIfExists(Directory directory) async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  static void _validateOperationId(String operationId) {
    if (!_operationIdPattern.hasMatch(operationId)) {
      throw const VaultRestoreRecoveryException(
        'Identificador de restauración inválido.',
      );
    }
  }

  static void _validateFingerprint(
    String? fingerprint, {
    required bool allowNull,
  }) {
    if (fingerprint == null && allowNull) return;
    if (fingerprint == null || !_fingerprintPattern.hasMatch(fingerprint)) {
      throw const VaultRestoreRecoveryException(
        'Huella de clave inválida en el journal.',
      );
    }
  }
}

class VaultRestoreJournalHandle {
  final Directory supportDirectory;
  final Directory rollbackDirectory;
  final _RestoreJournalData _data;

  const VaultRestoreJournalHandle._({
    required this.supportDirectory,
    required this.rollbackDirectory,
    required this._data,
  });

  String get operationId => _data.operationId;
  String? get oldKeyFingerprint => _data.oldKeyFingerprint;
  String get newKeyFingerprint => _data.newKeyFingerprint;
  List<String> get oldDatabaseSuffixes => _data.oldDatabaseSuffixes;
  bool get oldBlobsExisted => _data.oldBlobsExisted;
  Directory get stagingDirectory =>
      VaultRestoreRecovery.stagingDirectory(supportDirectory, operationId);

  Future<void> markPrepared() => _mark(VaultRestoreRecovery.phasePrepared);
  Future<void> markOldMoved() => _mark(VaultRestoreRecovery.phaseOldMoved);
  Future<void> markNewInstalled() =>
      _mark(VaultRestoreRecovery.phaseNewInstalled);
  Future<void> markKeyInstalled() =>
      _mark(VaultRestoreRecovery.phaseKeyInstalled);
  Future<void> retire() => VaultRestoreRecovery._retireRollback(this);

  Future<bool> hasPhase(String phaseFileName) =>
      File(p.join(rollbackDirectory.path, phaseFileName)).exists();

  Future<void> _mark(String phaseFileName) =>
      VaultRestoreRecovery._writeDurableMarker(
        File(p.join(rollbackDirectory.path, phaseFileName)),
      );
}

class VaultRestoreRecoveryException implements Exception {
  final String message;

  const VaultRestoreRecoveryException(this.message);

  @override
  String toString() => message;
}

class _RestoreJournalData {
  final int version;
  final String operationId;
  final String? oldKeyFingerprint;
  final String newKeyFingerprint;
  final List<String> oldDatabaseSuffixes;
  final bool oldBlobsExisted;

  const _RestoreJournalData({
    required this.version,
    required this.operationId,
    required this.oldKeyFingerprint,
    required this.newKeyFingerprint,
    required this.oldDatabaseSuffixes,
    required this.oldBlobsExisted,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'operationId': operationId,
    'oldKeyFingerprint': oldKeyFingerprint,
    'newKeyFingerprint': newKeyFingerprint,
    'oldDatabaseSuffixes': oldDatabaseSuffixes,
    'oldBlobsExisted': oldBlobsExisted,
  };

  factory _RestoreJournalData.fromJson(Map<String, dynamic> json) {
    const expectedKeys = {
      'version',
      'operationId',
      'oldKeyFingerprint',
      'newKeyFingerprint',
      'oldDatabaseSuffixes',
      'oldBlobsExisted',
    };
    if (json.length != expectedKeys.length ||
        !json.keys.toSet().containsAll(expectedKeys)) {
      throw const VaultRestoreRecoveryException(
        'El journal contiene campos inesperados o ausentes.',
      );
    }
    final version = json['version'];
    final operationId = json['operationId'];
    final oldKeyFingerprint = json['oldKeyFingerprint'];
    final newKeyFingerprint = json['newKeyFingerprint'];
    final oldSuffixes = json['oldDatabaseSuffixes'];
    final oldBlobsExisted = json['oldBlobsExisted'];
    if (version != VaultRestoreRecovery.journalVersion ||
        operationId is! String ||
        (oldKeyFingerprint != null && oldKeyFingerprint is! String) ||
        newKeyFingerprint is! String ||
        oldSuffixes is! List<dynamic> ||
        oldBlobsExisted is! bool) {
      throw const VaultRestoreRecoveryException(
        'El journal contiene tipos o versión no compatibles.',
      );
    }

    VaultRestoreRecovery._validateOperationId(operationId);
    VaultRestoreRecovery._validateFingerprint(
      oldKeyFingerprint as String?,
      allowNull: true,
    );
    VaultRestoreRecovery._validateFingerprint(
      newKeyFingerprint,
      allowNull: false,
    );
    final suffixes = <String>[];
    for (final value in oldSuffixes) {
      if (value is! String ||
          !VaultRestoreRecovery._databaseSuffixes.contains(value) ||
          suffixes.contains(value)) {
        throw const VaultRestoreRecoveryException(
          'El journal contiene sidecars SQLite inválidos.',
        );
      }
      suffixes.add(value);
    }
    return _RestoreJournalData(
      version: version,
      operationId: operationId,
      oldKeyFingerprint: oldKeyFingerprint,
      newKeyFingerprint: newKeyFingerprint,
      oldDatabaseSuffixes: List.unmodifiable(suffixes),
      oldBlobsExisted: oldBlobsExisted,
    );
  }
}
