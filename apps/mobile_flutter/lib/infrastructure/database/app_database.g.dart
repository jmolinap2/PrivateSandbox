// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VaultFilesTable extends VaultFiles
    with TableInfo<$VaultFilesTable, VaultFileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalNameMeta = const VerificationMeta(
    'originalName',
  );
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
    'original_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extensionMeta = const VerificationMeta(
    'extension',
  );
  @override
  late final GeneratedColumn<String> extension = GeneratedColumn<String>(
    'extension',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalPathMeta = const VerificationMeta(
    'originalPath',
  );
  @override
  late final GeneratedColumn<String> originalPath = GeneratedColumn<String>(
    'original_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalContentUriMeta =
      const VerificationMeta('originalContentUri');
  @override
  late final GeneratedColumn<String> originalContentUri =
      GeneratedColumn<String>(
        'original_content_uri',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _originalRelativePathMeta =
      const VerificationMeta('originalRelativePath');
  @override
  late final GeneratedColumn<String> originalRelativePath =
      GeneratedColumn<String>(
        'original_relative_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _originalTreeUriMeta = const VerificationMeta(
    'originalTreeUri',
  );
  @override
  late final GeneratedColumn<String> originalTreeUri = GeneratedColumn<String>(
    'original_tree_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalTreeRelativePathMeta =
      const VerificationMeta('originalTreeRelativePath');
  @override
  late final GeneratedColumn<String> originalTreeRelativePath =
      GeneratedColumn<String>(
        'original_tree_relative_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileModifiedAtMeta = const VerificationMeta(
    'fileModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fileModifiedAt =
      GeneratedColumn<DateTime>(
        'file_modified_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _originalCreatedAtMeta = const VerificationMeta(
    'originalCreatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> originalCreatedAt =
      GeneratedColumn<DateTime>(
        'original_created_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _originalAccessedAtMeta =
      const VerificationMeta('originalAccessedAt');
  @override
  late final GeneratedColumn<DateTime> originalAccessedAt =
      GeneratedColumn<DateTime>(
        'original_accessed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _originalMetadataJsonMeta =
      const VerificationMeta('originalMetadataJson');
  @override
  late final GeneratedColumn<String> originalMetadataJson =
      GeneratedColumn<String>(
        'original_metadata_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedFileNameMeta = const VerificationMeta(
    'encryptedFileName',
  );
  @override
  late final GeneratedColumn<String> encryptedFileName =
      GeneratedColumn<String>(
        'encrypted_file_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fileSaltBase64Meta = const VerificationMeta(
    'fileSaltBase64',
  );
  @override
  late final GeneratedColumn<String> fileSaltBase64 = GeneratedColumn<String>(
    'file_salt_base64',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noncePrefixBase64Meta = const VerificationMeta(
    'noncePrefixBase64',
  );
  @override
  late final GeneratedColumn<String> noncePrefixBase64 =
      GeneratedColumn<String>(
        'nonce_prefix_base64',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sha256HashMeta = const VerificationMeta(
    'sha256Hash',
  );
  @override
  late final GeneratedColumn<String> sha256Hash = GeneratedColumn<String>(
    'sha256_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _originalDeletedMeta = const VerificationMeta(
    'originalDeleted',
  );
  @override
  late final GeneratedColumn<bool> originalDeleted = GeneratedColumn<bool>(
    'original_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("original_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playbackPositionMsMeta =
      const VerificationMeta('playbackPositionMs');
  @override
  late final GeneratedColumn<int> playbackPositionMs = GeneratedColumn<int>(
    'playback_position_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailFileNameMeta = const VerificationMeta(
    'thumbnailFileName',
  );
  @override
  late final GeneratedColumn<String> thumbnailFileName =
      GeneratedColumn<String>(
        'thumbnail_file_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _thumbnailNoncePrefixBase64Meta =
      const VerificationMeta('thumbnailNoncePrefixBase64');
  @override
  late final GeneratedColumn<String> thumbnailNoncePrefixBase64 =
      GeneratedColumn<String>(
        'thumbnail_nonce_prefix_base64',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    originalName,
    extension,
    mimeType,
    sizeBytes,
    originalPath,
    originalContentUri,
    originalRelativePath,
    originalTreeUri,
    originalTreeRelativePath,
    importedAt,
    fileModifiedAt,
    originalCreatedAt,
    originalAccessedAt,
    originalMetadataJson,
    category,
    status,
    encryptedFileName,
    fileSaltBase64,
    noncePrefixBase64,
    sha256Hash,
    originalDeleted,
    isFavorite,
    lastOpenedAt,
    playbackPositionMs,
    thumbnailFileName,
    thumbnailNoncePrefixBase64,
    deletedAt,
    folderId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultFileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('original_name')) {
      context.handle(
        _originalNameMeta,
        originalName.isAcceptableOrUnknown(
          data['original_name']!,
          _originalNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalNameMeta);
    }
    if (data.containsKey('extension')) {
      context.handle(
        _extensionMeta,
        extension.isAcceptableOrUnknown(data['extension']!, _extensionMeta),
      );
    } else if (isInserting) {
      context.missing(_extensionMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('original_path')) {
      context.handle(
        _originalPathMeta,
        originalPath.isAcceptableOrUnknown(
          data['original_path']!,
          _originalPathMeta,
        ),
      );
    }
    if (data.containsKey('original_content_uri')) {
      context.handle(
        _originalContentUriMeta,
        originalContentUri.isAcceptableOrUnknown(
          data['original_content_uri']!,
          _originalContentUriMeta,
        ),
      );
    }
    if (data.containsKey('original_relative_path')) {
      context.handle(
        _originalRelativePathMeta,
        originalRelativePath.isAcceptableOrUnknown(
          data['original_relative_path']!,
          _originalRelativePathMeta,
        ),
      );
    }
    if (data.containsKey('original_tree_uri')) {
      context.handle(
        _originalTreeUriMeta,
        originalTreeUri.isAcceptableOrUnknown(
          data['original_tree_uri']!,
          _originalTreeUriMeta,
        ),
      );
    }
    if (data.containsKey('original_tree_relative_path')) {
      context.handle(
        _originalTreeRelativePathMeta,
        originalTreeRelativePath.isAcceptableOrUnknown(
          data['original_tree_relative_path']!,
          _originalTreeRelativePathMeta,
        ),
      );
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('file_modified_at')) {
      context.handle(
        _fileModifiedAtMeta,
        fileModifiedAt.isAcceptableOrUnknown(
          data['file_modified_at']!,
          _fileModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('original_created_at')) {
      context.handle(
        _originalCreatedAtMeta,
        originalCreatedAt.isAcceptableOrUnknown(
          data['original_created_at']!,
          _originalCreatedAtMeta,
        ),
      );
    }
    if (data.containsKey('original_accessed_at')) {
      context.handle(
        _originalAccessedAtMeta,
        originalAccessedAt.isAcceptableOrUnknown(
          data['original_accessed_at']!,
          _originalAccessedAtMeta,
        ),
      );
    }
    if (data.containsKey('original_metadata_json')) {
      context.handle(
        _originalMetadataJsonMeta,
        originalMetadataJson.isAcceptableOrUnknown(
          data['original_metadata_json']!,
          _originalMetadataJsonMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('encrypted_file_name')) {
      context.handle(
        _encryptedFileNameMeta,
        encryptedFileName.isAcceptableOrUnknown(
          data['encrypted_file_name']!,
          _encryptedFileNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedFileNameMeta);
    }
    if (data.containsKey('file_salt_base64')) {
      context.handle(
        _fileSaltBase64Meta,
        fileSaltBase64.isAcceptableOrUnknown(
          data['file_salt_base64']!,
          _fileSaltBase64Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileSaltBase64Meta);
    }
    if (data.containsKey('nonce_prefix_base64')) {
      context.handle(
        _noncePrefixBase64Meta,
        noncePrefixBase64.isAcceptableOrUnknown(
          data['nonce_prefix_base64']!,
          _noncePrefixBase64Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_noncePrefixBase64Meta);
    }
    if (data.containsKey('sha256_hash')) {
      context.handle(
        _sha256HashMeta,
        sha256Hash.isAcceptableOrUnknown(data['sha256_hash']!, _sha256HashMeta),
      );
    }
    if (data.containsKey('original_deleted')) {
      context.handle(
        _originalDeletedMeta,
        originalDeleted.isAcceptableOrUnknown(
          data['original_deleted']!,
          _originalDeletedMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    if (data.containsKey('playback_position_ms')) {
      context.handle(
        _playbackPositionMsMeta,
        playbackPositionMs.isAcceptableOrUnknown(
          data['playback_position_ms']!,
          _playbackPositionMsMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_file_name')) {
      context.handle(
        _thumbnailFileNameMeta,
        thumbnailFileName.isAcceptableOrUnknown(
          data['thumbnail_file_name']!,
          _thumbnailFileNameMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_nonce_prefix_base64')) {
      context.handle(
        _thumbnailNoncePrefixBase64Meta,
        thumbnailNoncePrefixBase64.isAcceptableOrUnknown(
          data['thumbnail_nonce_prefix_base64']!,
          _thumbnailNoncePrefixBase64Meta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultFileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultFileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      originalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_name'],
      )!,
      extension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extension'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      originalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_path'],
      ),
      originalContentUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_content_uri'],
      ),
      originalRelativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_relative_path'],
      ),
      originalTreeUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_tree_uri'],
      ),
      originalTreeRelativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_tree_relative_path'],
      ),
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      fileModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}file_modified_at'],
      ),
      originalCreatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}original_created_at'],
      ),
      originalAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}original_accessed_at'],
      ),
      originalMetadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_metadata_json'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      encryptedFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_file_name'],
      )!,
      fileSaltBase64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_salt_base64'],
      )!,
      noncePrefixBase64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nonce_prefix_base64'],
      )!,
      sha256Hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256_hash'],
      )!,
      originalDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}original_deleted'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      ),
      playbackPositionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playback_position_ms'],
      ),
      thumbnailFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_file_name'],
      ),
      thumbnailNoncePrefixBase64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_nonce_prefix_base64'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
    );
  }

  @override
  $VaultFilesTable createAlias(String alias) {
    return $VaultFilesTable(attachedDatabase, alias);
  }
}

class VaultFileRow extends DataClass implements Insertable<VaultFileRow> {
  final String id;
  final String originalName;
  final String extension;
  final String mimeType;
  final int sizeBytes;
  final String? originalPath;
  final String? originalContentUri;
  final String? originalRelativePath;

  /// Persisted SAF folder-tree grant covering this file's original folder
  /// (explorer-sourced imports whose original was deleted, only). Lets
  /// restore recreate the file in that folder even though
  /// [originalContentUri]'s document is gone.
  final String? originalTreeUri;

  /// The file's folder path relative to [originalTreeUri]'s root. Only
  /// meaningful together with [originalTreeUri].
  final String? originalTreeRelativePath;
  final DateTime importedAt;
  final DateTime? fileModifiedAt;
  final DateTime? originalCreatedAt;
  final DateTime? originalAccessedAt;
  final String? originalMetadataJson;
  final String category;
  final String status;
  final String encryptedFileName;
  final String fileSaltBase64;
  final String noncePrefixBase64;
  final String sha256Hash;
  final bool originalDeleted;
  final bool isFavorite;
  final DateTime? lastOpenedAt;
  final int? playbackPositionMs;
  final String? thumbnailFileName;
  final String? thumbnailNoncePrefixBase64;

  /// When set, the file is in the private trash — hidden from the library
  /// but not yet permanently deleted. Null means "active".
  final DateTime? deletedAt;

  /// Virtual folder this file is filed under. Null means "unfiled" (shown
  /// at the folder root). Purely organizational — never changes where the
  /// ciphertext blob physically lives on disk.
  final String? folderId;
  const VaultFileRow({
    required this.id,
    required this.originalName,
    required this.extension,
    required this.mimeType,
    required this.sizeBytes,
    this.originalPath,
    this.originalContentUri,
    this.originalRelativePath,
    this.originalTreeUri,
    this.originalTreeRelativePath,
    required this.importedAt,
    this.fileModifiedAt,
    this.originalCreatedAt,
    this.originalAccessedAt,
    this.originalMetadataJson,
    required this.category,
    required this.status,
    required this.encryptedFileName,
    required this.fileSaltBase64,
    required this.noncePrefixBase64,
    required this.sha256Hash,
    required this.originalDeleted,
    required this.isFavorite,
    this.lastOpenedAt,
    this.playbackPositionMs,
    this.thumbnailFileName,
    this.thumbnailNoncePrefixBase64,
    this.deletedAt,
    this.folderId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['original_name'] = Variable<String>(originalName);
    map['extension'] = Variable<String>(extension);
    map['mime_type'] = Variable<String>(mimeType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || originalPath != null) {
      map['original_path'] = Variable<String>(originalPath);
    }
    if (!nullToAbsent || originalContentUri != null) {
      map['original_content_uri'] = Variable<String>(originalContentUri);
    }
    if (!nullToAbsent || originalRelativePath != null) {
      map['original_relative_path'] = Variable<String>(originalRelativePath);
    }
    if (!nullToAbsent || originalTreeUri != null) {
      map['original_tree_uri'] = Variable<String>(originalTreeUri);
    }
    if (!nullToAbsent || originalTreeRelativePath != null) {
      map['original_tree_relative_path'] = Variable<String>(
        originalTreeRelativePath,
      );
    }
    map['imported_at'] = Variable<DateTime>(importedAt);
    if (!nullToAbsent || fileModifiedAt != null) {
      map['file_modified_at'] = Variable<DateTime>(fileModifiedAt);
    }
    if (!nullToAbsent || originalCreatedAt != null) {
      map['original_created_at'] = Variable<DateTime>(originalCreatedAt);
    }
    if (!nullToAbsent || originalAccessedAt != null) {
      map['original_accessed_at'] = Variable<DateTime>(originalAccessedAt);
    }
    if (!nullToAbsent || originalMetadataJson != null) {
      map['original_metadata_json'] = Variable<String>(originalMetadataJson);
    }
    map['category'] = Variable<String>(category);
    map['status'] = Variable<String>(status);
    map['encrypted_file_name'] = Variable<String>(encryptedFileName);
    map['file_salt_base64'] = Variable<String>(fileSaltBase64);
    map['nonce_prefix_base64'] = Variable<String>(noncePrefixBase64);
    map['sha256_hash'] = Variable<String>(sha256Hash);
    map['original_deleted'] = Variable<bool>(originalDeleted);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    if (!nullToAbsent || playbackPositionMs != null) {
      map['playback_position_ms'] = Variable<int>(playbackPositionMs);
    }
    if (!nullToAbsent || thumbnailFileName != null) {
      map['thumbnail_file_name'] = Variable<String>(thumbnailFileName);
    }
    if (!nullToAbsent || thumbnailNoncePrefixBase64 != null) {
      map['thumbnail_nonce_prefix_base64'] = Variable<String>(
        thumbnailNoncePrefixBase64,
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    return map;
  }

  VaultFilesCompanion toCompanion(bool nullToAbsent) {
    return VaultFilesCompanion(
      id: Value(id),
      originalName: Value(originalName),
      extension: Value(extension),
      mimeType: Value(mimeType),
      sizeBytes: Value(sizeBytes),
      originalPath: originalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(originalPath),
      originalContentUri: originalContentUri == null && nullToAbsent
          ? const Value.absent()
          : Value(originalContentUri),
      originalRelativePath: originalRelativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(originalRelativePath),
      originalTreeUri: originalTreeUri == null && nullToAbsent
          ? const Value.absent()
          : Value(originalTreeUri),
      originalTreeRelativePath: originalTreeRelativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(originalTreeRelativePath),
      importedAt: Value(importedAt),
      fileModifiedAt: fileModifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fileModifiedAt),
      originalCreatedAt: originalCreatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(originalCreatedAt),
      originalAccessedAt: originalAccessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(originalAccessedAt),
      originalMetadataJson: originalMetadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(originalMetadataJson),
      category: Value(category),
      status: Value(status),
      encryptedFileName: Value(encryptedFileName),
      fileSaltBase64: Value(fileSaltBase64),
      noncePrefixBase64: Value(noncePrefixBase64),
      sha256Hash: Value(sha256Hash),
      originalDeleted: Value(originalDeleted),
      isFavorite: Value(isFavorite),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      playbackPositionMs: playbackPositionMs == null && nullToAbsent
          ? const Value.absent()
          : Value(playbackPositionMs),
      thumbnailFileName: thumbnailFileName == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailFileName),
      thumbnailNoncePrefixBase64:
          thumbnailNoncePrefixBase64 == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailNoncePrefixBase64),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
    );
  }

  factory VaultFileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultFileRow(
      id: serializer.fromJson<String>(json['id']),
      originalName: serializer.fromJson<String>(json['originalName']),
      extension: serializer.fromJson<String>(json['extension']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      originalPath: serializer.fromJson<String?>(json['originalPath']),
      originalContentUri: serializer.fromJson<String?>(
        json['originalContentUri'],
      ),
      originalRelativePath: serializer.fromJson<String?>(
        json['originalRelativePath'],
      ),
      originalTreeUri: serializer.fromJson<String?>(json['originalTreeUri']),
      originalTreeRelativePath: serializer.fromJson<String?>(
        json['originalTreeRelativePath'],
      ),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      fileModifiedAt: serializer.fromJson<DateTime?>(json['fileModifiedAt']),
      originalCreatedAt: serializer.fromJson<DateTime?>(
        json['originalCreatedAt'],
      ),
      originalAccessedAt: serializer.fromJson<DateTime?>(
        json['originalAccessedAt'],
      ),
      originalMetadataJson: serializer.fromJson<String?>(
        json['originalMetadataJson'],
      ),
      category: serializer.fromJson<String>(json['category']),
      status: serializer.fromJson<String>(json['status']),
      encryptedFileName: serializer.fromJson<String>(json['encryptedFileName']),
      fileSaltBase64: serializer.fromJson<String>(json['fileSaltBase64']),
      noncePrefixBase64: serializer.fromJson<String>(json['noncePrefixBase64']),
      sha256Hash: serializer.fromJson<String>(json['sha256Hash']),
      originalDeleted: serializer.fromJson<bool>(json['originalDeleted']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      playbackPositionMs: serializer.fromJson<int?>(json['playbackPositionMs']),
      thumbnailFileName: serializer.fromJson<String?>(
        json['thumbnailFileName'],
      ),
      thumbnailNoncePrefixBase64: serializer.fromJson<String?>(
        json['thumbnailNoncePrefixBase64'],
      ),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      folderId: serializer.fromJson<String?>(json['folderId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'originalName': serializer.toJson<String>(originalName),
      'extension': serializer.toJson<String>(extension),
      'mimeType': serializer.toJson<String>(mimeType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'originalPath': serializer.toJson<String?>(originalPath),
      'originalContentUri': serializer.toJson<String?>(originalContentUri),
      'originalRelativePath': serializer.toJson<String?>(originalRelativePath),
      'originalTreeUri': serializer.toJson<String?>(originalTreeUri),
      'originalTreeRelativePath': serializer.toJson<String?>(
        originalTreeRelativePath,
      ),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'fileModifiedAt': serializer.toJson<DateTime?>(fileModifiedAt),
      'originalCreatedAt': serializer.toJson<DateTime?>(originalCreatedAt),
      'originalAccessedAt': serializer.toJson<DateTime?>(originalAccessedAt),
      'originalMetadataJson': serializer.toJson<String?>(originalMetadataJson),
      'category': serializer.toJson<String>(category),
      'status': serializer.toJson<String>(status),
      'encryptedFileName': serializer.toJson<String>(encryptedFileName),
      'fileSaltBase64': serializer.toJson<String>(fileSaltBase64),
      'noncePrefixBase64': serializer.toJson<String>(noncePrefixBase64),
      'sha256Hash': serializer.toJson<String>(sha256Hash),
      'originalDeleted': serializer.toJson<bool>(originalDeleted),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'playbackPositionMs': serializer.toJson<int?>(playbackPositionMs),
      'thumbnailFileName': serializer.toJson<String?>(thumbnailFileName),
      'thumbnailNoncePrefixBase64': serializer.toJson<String?>(
        thumbnailNoncePrefixBase64,
      ),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'folderId': serializer.toJson<String?>(folderId),
    };
  }

  VaultFileRow copyWith({
    String? id,
    String? originalName,
    String? extension,
    String? mimeType,
    int? sizeBytes,
    Value<String?> originalPath = const Value.absent(),
    Value<String?> originalContentUri = const Value.absent(),
    Value<String?> originalRelativePath = const Value.absent(),
    Value<String?> originalTreeUri = const Value.absent(),
    Value<String?> originalTreeRelativePath = const Value.absent(),
    DateTime? importedAt,
    Value<DateTime?> fileModifiedAt = const Value.absent(),
    Value<DateTime?> originalCreatedAt = const Value.absent(),
    Value<DateTime?> originalAccessedAt = const Value.absent(),
    Value<String?> originalMetadataJson = const Value.absent(),
    String? category,
    String? status,
    String? encryptedFileName,
    String? fileSaltBase64,
    String? noncePrefixBase64,
    String? sha256Hash,
    bool? originalDeleted,
    bool? isFavorite,
    Value<DateTime?> lastOpenedAt = const Value.absent(),
    Value<int?> playbackPositionMs = const Value.absent(),
    Value<String?> thumbnailFileName = const Value.absent(),
    Value<String?> thumbnailNoncePrefixBase64 = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> folderId = const Value.absent(),
  }) => VaultFileRow(
    id: id ?? this.id,
    originalName: originalName ?? this.originalName,
    extension: extension ?? this.extension,
    mimeType: mimeType ?? this.mimeType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    originalPath: originalPath.present ? originalPath.value : this.originalPath,
    originalContentUri: originalContentUri.present
        ? originalContentUri.value
        : this.originalContentUri,
    originalRelativePath: originalRelativePath.present
        ? originalRelativePath.value
        : this.originalRelativePath,
    originalTreeUri: originalTreeUri.present
        ? originalTreeUri.value
        : this.originalTreeUri,
    originalTreeRelativePath: originalTreeRelativePath.present
        ? originalTreeRelativePath.value
        : this.originalTreeRelativePath,
    importedAt: importedAt ?? this.importedAt,
    fileModifiedAt: fileModifiedAt.present
        ? fileModifiedAt.value
        : this.fileModifiedAt,
    originalCreatedAt: originalCreatedAt.present
        ? originalCreatedAt.value
        : this.originalCreatedAt,
    originalAccessedAt: originalAccessedAt.present
        ? originalAccessedAt.value
        : this.originalAccessedAt,
    originalMetadataJson: originalMetadataJson.present
        ? originalMetadataJson.value
        : this.originalMetadataJson,
    category: category ?? this.category,
    status: status ?? this.status,
    encryptedFileName: encryptedFileName ?? this.encryptedFileName,
    fileSaltBase64: fileSaltBase64 ?? this.fileSaltBase64,
    noncePrefixBase64: noncePrefixBase64 ?? this.noncePrefixBase64,
    sha256Hash: sha256Hash ?? this.sha256Hash,
    originalDeleted: originalDeleted ?? this.originalDeleted,
    isFavorite: isFavorite ?? this.isFavorite,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
    playbackPositionMs: playbackPositionMs.present
        ? playbackPositionMs.value
        : this.playbackPositionMs,
    thumbnailFileName: thumbnailFileName.present
        ? thumbnailFileName.value
        : this.thumbnailFileName,
    thumbnailNoncePrefixBase64: thumbnailNoncePrefixBase64.present
        ? thumbnailNoncePrefixBase64.value
        : this.thumbnailNoncePrefixBase64,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    folderId: folderId.present ? folderId.value : this.folderId,
  );
  VaultFileRow copyWithCompanion(VaultFilesCompanion data) {
    return VaultFileRow(
      id: data.id.present ? data.id.value : this.id,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      extension: data.extension.present ? data.extension.value : this.extension,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      originalPath: data.originalPath.present
          ? data.originalPath.value
          : this.originalPath,
      originalContentUri: data.originalContentUri.present
          ? data.originalContentUri.value
          : this.originalContentUri,
      originalRelativePath: data.originalRelativePath.present
          ? data.originalRelativePath.value
          : this.originalRelativePath,
      originalTreeUri: data.originalTreeUri.present
          ? data.originalTreeUri.value
          : this.originalTreeUri,
      originalTreeRelativePath: data.originalTreeRelativePath.present
          ? data.originalTreeRelativePath.value
          : this.originalTreeRelativePath,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      fileModifiedAt: data.fileModifiedAt.present
          ? data.fileModifiedAt.value
          : this.fileModifiedAt,
      originalCreatedAt: data.originalCreatedAt.present
          ? data.originalCreatedAt.value
          : this.originalCreatedAt,
      originalAccessedAt: data.originalAccessedAt.present
          ? data.originalAccessedAt.value
          : this.originalAccessedAt,
      originalMetadataJson: data.originalMetadataJson.present
          ? data.originalMetadataJson.value
          : this.originalMetadataJson,
      category: data.category.present ? data.category.value : this.category,
      status: data.status.present ? data.status.value : this.status,
      encryptedFileName: data.encryptedFileName.present
          ? data.encryptedFileName.value
          : this.encryptedFileName,
      fileSaltBase64: data.fileSaltBase64.present
          ? data.fileSaltBase64.value
          : this.fileSaltBase64,
      noncePrefixBase64: data.noncePrefixBase64.present
          ? data.noncePrefixBase64.value
          : this.noncePrefixBase64,
      sha256Hash: data.sha256Hash.present
          ? data.sha256Hash.value
          : this.sha256Hash,
      originalDeleted: data.originalDeleted.present
          ? data.originalDeleted.value
          : this.originalDeleted,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      playbackPositionMs: data.playbackPositionMs.present
          ? data.playbackPositionMs.value
          : this.playbackPositionMs,
      thumbnailFileName: data.thumbnailFileName.present
          ? data.thumbnailFileName.value
          : this.thumbnailFileName,
      thumbnailNoncePrefixBase64: data.thumbnailNoncePrefixBase64.present
          ? data.thumbnailNoncePrefixBase64.value
          : this.thumbnailNoncePrefixBase64,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultFileRow(')
          ..write('id: $id, ')
          ..write('originalName: $originalName, ')
          ..write('extension: $extension, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('originalPath: $originalPath, ')
          ..write('originalContentUri: $originalContentUri, ')
          ..write('originalRelativePath: $originalRelativePath, ')
          ..write('originalTreeUri: $originalTreeUri, ')
          ..write('originalTreeRelativePath: $originalTreeRelativePath, ')
          ..write('importedAt: $importedAt, ')
          ..write('fileModifiedAt: $fileModifiedAt, ')
          ..write('originalCreatedAt: $originalCreatedAt, ')
          ..write('originalAccessedAt: $originalAccessedAt, ')
          ..write('originalMetadataJson: $originalMetadataJson, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('encryptedFileName: $encryptedFileName, ')
          ..write('fileSaltBase64: $fileSaltBase64, ')
          ..write('noncePrefixBase64: $noncePrefixBase64, ')
          ..write('sha256Hash: $sha256Hash, ')
          ..write('originalDeleted: $originalDeleted, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('playbackPositionMs: $playbackPositionMs, ')
          ..write('thumbnailFileName: $thumbnailFileName, ')
          ..write('thumbnailNoncePrefixBase64: $thumbnailNoncePrefixBase64, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('folderId: $folderId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    originalName,
    extension,
    mimeType,
    sizeBytes,
    originalPath,
    originalContentUri,
    originalRelativePath,
    originalTreeUri,
    originalTreeRelativePath,
    importedAt,
    fileModifiedAt,
    originalCreatedAt,
    originalAccessedAt,
    originalMetadataJson,
    category,
    status,
    encryptedFileName,
    fileSaltBase64,
    noncePrefixBase64,
    sha256Hash,
    originalDeleted,
    isFavorite,
    lastOpenedAt,
    playbackPositionMs,
    thumbnailFileName,
    thumbnailNoncePrefixBase64,
    deletedAt,
    folderId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultFileRow &&
          other.id == this.id &&
          other.originalName == this.originalName &&
          other.extension == this.extension &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.originalPath == this.originalPath &&
          other.originalContentUri == this.originalContentUri &&
          other.originalRelativePath == this.originalRelativePath &&
          other.originalTreeUri == this.originalTreeUri &&
          other.originalTreeRelativePath == this.originalTreeRelativePath &&
          other.importedAt == this.importedAt &&
          other.fileModifiedAt == this.fileModifiedAt &&
          other.originalCreatedAt == this.originalCreatedAt &&
          other.originalAccessedAt == this.originalAccessedAt &&
          other.originalMetadataJson == this.originalMetadataJson &&
          other.category == this.category &&
          other.status == this.status &&
          other.encryptedFileName == this.encryptedFileName &&
          other.fileSaltBase64 == this.fileSaltBase64 &&
          other.noncePrefixBase64 == this.noncePrefixBase64 &&
          other.sha256Hash == this.sha256Hash &&
          other.originalDeleted == this.originalDeleted &&
          other.isFavorite == this.isFavorite &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.playbackPositionMs == this.playbackPositionMs &&
          other.thumbnailFileName == this.thumbnailFileName &&
          other.thumbnailNoncePrefixBase64 == this.thumbnailNoncePrefixBase64 &&
          other.deletedAt == this.deletedAt &&
          other.folderId == this.folderId);
}

class VaultFilesCompanion extends UpdateCompanion<VaultFileRow> {
  final Value<String> id;
  final Value<String> originalName;
  final Value<String> extension;
  final Value<String> mimeType;
  final Value<int> sizeBytes;
  final Value<String?> originalPath;
  final Value<String?> originalContentUri;
  final Value<String?> originalRelativePath;
  final Value<String?> originalTreeUri;
  final Value<String?> originalTreeRelativePath;
  final Value<DateTime> importedAt;
  final Value<DateTime?> fileModifiedAt;
  final Value<DateTime?> originalCreatedAt;
  final Value<DateTime?> originalAccessedAt;
  final Value<String?> originalMetadataJson;
  final Value<String> category;
  final Value<String> status;
  final Value<String> encryptedFileName;
  final Value<String> fileSaltBase64;
  final Value<String> noncePrefixBase64;
  final Value<String> sha256Hash;
  final Value<bool> originalDeleted;
  final Value<bool> isFavorite;
  final Value<DateTime?> lastOpenedAt;
  final Value<int?> playbackPositionMs;
  final Value<String?> thumbnailFileName;
  final Value<String?> thumbnailNoncePrefixBase64;
  final Value<DateTime?> deletedAt;
  final Value<String?> folderId;
  final Value<int> rowid;
  const VaultFilesCompanion({
    this.id = const Value.absent(),
    this.originalName = const Value.absent(),
    this.extension = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.originalContentUri = const Value.absent(),
    this.originalRelativePath = const Value.absent(),
    this.originalTreeUri = const Value.absent(),
    this.originalTreeRelativePath = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.fileModifiedAt = const Value.absent(),
    this.originalCreatedAt = const Value.absent(),
    this.originalAccessedAt = const Value.absent(),
    this.originalMetadataJson = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
    this.encryptedFileName = const Value.absent(),
    this.fileSaltBase64 = const Value.absent(),
    this.noncePrefixBase64 = const Value.absent(),
    this.sha256Hash = const Value.absent(),
    this.originalDeleted = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.playbackPositionMs = const Value.absent(),
    this.thumbnailFileName = const Value.absent(),
    this.thumbnailNoncePrefixBase64 = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.folderId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultFilesCompanion.insert({
    required String id,
    required String originalName,
    required String extension,
    required String mimeType,
    required int sizeBytes,
    this.originalPath = const Value.absent(),
    this.originalContentUri = const Value.absent(),
    this.originalRelativePath = const Value.absent(),
    this.originalTreeUri = const Value.absent(),
    this.originalTreeRelativePath = const Value.absent(),
    required DateTime importedAt,
    this.fileModifiedAt = const Value.absent(),
    this.originalCreatedAt = const Value.absent(),
    this.originalAccessedAt = const Value.absent(),
    this.originalMetadataJson = const Value.absent(),
    required String category,
    required String status,
    required String encryptedFileName,
    required String fileSaltBase64,
    required String noncePrefixBase64,
    this.sha256Hash = const Value.absent(),
    this.originalDeleted = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.playbackPositionMs = const Value.absent(),
    this.thumbnailFileName = const Value.absent(),
    this.thumbnailNoncePrefixBase64 = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.folderId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       originalName = Value(originalName),
       extension = Value(extension),
       mimeType = Value(mimeType),
       sizeBytes = Value(sizeBytes),
       importedAt = Value(importedAt),
       category = Value(category),
       status = Value(status),
       encryptedFileName = Value(encryptedFileName),
       fileSaltBase64 = Value(fileSaltBase64),
       noncePrefixBase64 = Value(noncePrefixBase64);
  static Insertable<VaultFileRow> custom({
    Expression<String>? id,
    Expression<String>? originalName,
    Expression<String>? extension,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<String>? originalPath,
    Expression<String>? originalContentUri,
    Expression<String>? originalRelativePath,
    Expression<String>? originalTreeUri,
    Expression<String>? originalTreeRelativePath,
    Expression<DateTime>? importedAt,
    Expression<DateTime>? fileModifiedAt,
    Expression<DateTime>? originalCreatedAt,
    Expression<DateTime>? originalAccessedAt,
    Expression<String>? originalMetadataJson,
    Expression<String>? category,
    Expression<String>? status,
    Expression<String>? encryptedFileName,
    Expression<String>? fileSaltBase64,
    Expression<String>? noncePrefixBase64,
    Expression<String>? sha256Hash,
    Expression<bool>? originalDeleted,
    Expression<bool>? isFavorite,
    Expression<DateTime>? lastOpenedAt,
    Expression<int>? playbackPositionMs,
    Expression<String>? thumbnailFileName,
    Expression<String>? thumbnailNoncePrefixBase64,
    Expression<DateTime>? deletedAt,
    Expression<String>? folderId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalName != null) 'original_name': originalName,
      if (extension != null) 'extension': extension,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (originalPath != null) 'original_path': originalPath,
      if (originalContentUri != null)
        'original_content_uri': originalContentUri,
      if (originalRelativePath != null)
        'original_relative_path': originalRelativePath,
      if (originalTreeUri != null) 'original_tree_uri': originalTreeUri,
      if (originalTreeRelativePath != null)
        'original_tree_relative_path': originalTreeRelativePath,
      if (importedAt != null) 'imported_at': importedAt,
      if (fileModifiedAt != null) 'file_modified_at': fileModifiedAt,
      if (originalCreatedAt != null) 'original_created_at': originalCreatedAt,
      if (originalAccessedAt != null)
        'original_accessed_at': originalAccessedAt,
      if (originalMetadataJson != null)
        'original_metadata_json': originalMetadataJson,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (encryptedFileName != null) 'encrypted_file_name': encryptedFileName,
      if (fileSaltBase64 != null) 'file_salt_base64': fileSaltBase64,
      if (noncePrefixBase64 != null) 'nonce_prefix_base64': noncePrefixBase64,
      if (sha256Hash != null) 'sha256_hash': sha256Hash,
      if (originalDeleted != null) 'original_deleted': originalDeleted,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (playbackPositionMs != null)
        'playback_position_ms': playbackPositionMs,
      if (thumbnailFileName != null) 'thumbnail_file_name': thumbnailFileName,
      if (thumbnailNoncePrefixBase64 != null)
        'thumbnail_nonce_prefix_base64': thumbnailNoncePrefixBase64,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (folderId != null) 'folder_id': folderId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultFilesCompanion copyWith({
    Value<String>? id,
    Value<String>? originalName,
    Value<String>? extension,
    Value<String>? mimeType,
    Value<int>? sizeBytes,
    Value<String?>? originalPath,
    Value<String?>? originalContentUri,
    Value<String?>? originalRelativePath,
    Value<String?>? originalTreeUri,
    Value<String?>? originalTreeRelativePath,
    Value<DateTime>? importedAt,
    Value<DateTime?>? fileModifiedAt,
    Value<DateTime?>? originalCreatedAt,
    Value<DateTime?>? originalAccessedAt,
    Value<String?>? originalMetadataJson,
    Value<String>? category,
    Value<String>? status,
    Value<String>? encryptedFileName,
    Value<String>? fileSaltBase64,
    Value<String>? noncePrefixBase64,
    Value<String>? sha256Hash,
    Value<bool>? originalDeleted,
    Value<bool>? isFavorite,
    Value<DateTime?>? lastOpenedAt,
    Value<int?>? playbackPositionMs,
    Value<String?>? thumbnailFileName,
    Value<String?>? thumbnailNoncePrefixBase64,
    Value<DateTime?>? deletedAt,
    Value<String?>? folderId,
    Value<int>? rowid,
  }) {
    return VaultFilesCompanion(
      id: id ?? this.id,
      originalName: originalName ?? this.originalName,
      extension: extension ?? this.extension,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      originalPath: originalPath ?? this.originalPath,
      originalContentUri: originalContentUri ?? this.originalContentUri,
      originalRelativePath: originalRelativePath ?? this.originalRelativePath,
      originalTreeUri: originalTreeUri ?? this.originalTreeUri,
      originalTreeRelativePath:
          originalTreeRelativePath ?? this.originalTreeRelativePath,
      importedAt: importedAt ?? this.importedAt,
      fileModifiedAt: fileModifiedAt ?? this.fileModifiedAt,
      originalCreatedAt: originalCreatedAt ?? this.originalCreatedAt,
      originalAccessedAt: originalAccessedAt ?? this.originalAccessedAt,
      originalMetadataJson: originalMetadataJson ?? this.originalMetadataJson,
      category: category ?? this.category,
      status: status ?? this.status,
      encryptedFileName: encryptedFileName ?? this.encryptedFileName,
      fileSaltBase64: fileSaltBase64 ?? this.fileSaltBase64,
      noncePrefixBase64: noncePrefixBase64 ?? this.noncePrefixBase64,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      originalDeleted: originalDeleted ?? this.originalDeleted,
      isFavorite: isFavorite ?? this.isFavorite,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      playbackPositionMs: playbackPositionMs ?? this.playbackPositionMs,
      thumbnailFileName: thumbnailFileName ?? this.thumbnailFileName,
      thumbnailNoncePrefixBase64:
          thumbnailNoncePrefixBase64 ?? this.thumbnailNoncePrefixBase64,
      deletedAt: deletedAt ?? this.deletedAt,
      folderId: folderId ?? this.folderId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (extension.present) {
      map['extension'] = Variable<String>(extension.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (originalPath.present) {
      map['original_path'] = Variable<String>(originalPath.value);
    }
    if (originalContentUri.present) {
      map['original_content_uri'] = Variable<String>(originalContentUri.value);
    }
    if (originalRelativePath.present) {
      map['original_relative_path'] = Variable<String>(
        originalRelativePath.value,
      );
    }
    if (originalTreeUri.present) {
      map['original_tree_uri'] = Variable<String>(originalTreeUri.value);
    }
    if (originalTreeRelativePath.present) {
      map['original_tree_relative_path'] = Variable<String>(
        originalTreeRelativePath.value,
      );
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (fileModifiedAt.present) {
      map['file_modified_at'] = Variable<DateTime>(fileModifiedAt.value);
    }
    if (originalCreatedAt.present) {
      map['original_created_at'] = Variable<DateTime>(originalCreatedAt.value);
    }
    if (originalAccessedAt.present) {
      map['original_accessed_at'] = Variable<DateTime>(
        originalAccessedAt.value,
      );
    }
    if (originalMetadataJson.present) {
      map['original_metadata_json'] = Variable<String>(
        originalMetadataJson.value,
      );
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (encryptedFileName.present) {
      map['encrypted_file_name'] = Variable<String>(encryptedFileName.value);
    }
    if (fileSaltBase64.present) {
      map['file_salt_base64'] = Variable<String>(fileSaltBase64.value);
    }
    if (noncePrefixBase64.present) {
      map['nonce_prefix_base64'] = Variable<String>(noncePrefixBase64.value);
    }
    if (sha256Hash.present) {
      map['sha256_hash'] = Variable<String>(sha256Hash.value);
    }
    if (originalDeleted.present) {
      map['original_deleted'] = Variable<bool>(originalDeleted.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (playbackPositionMs.present) {
      map['playback_position_ms'] = Variable<int>(playbackPositionMs.value);
    }
    if (thumbnailFileName.present) {
      map['thumbnail_file_name'] = Variable<String>(thumbnailFileName.value);
    }
    if (thumbnailNoncePrefixBase64.present) {
      map['thumbnail_nonce_prefix_base64'] = Variable<String>(
        thumbnailNoncePrefixBase64.value,
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultFilesCompanion(')
          ..write('id: $id, ')
          ..write('originalName: $originalName, ')
          ..write('extension: $extension, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('originalPath: $originalPath, ')
          ..write('originalContentUri: $originalContentUri, ')
          ..write('originalRelativePath: $originalRelativePath, ')
          ..write('originalTreeUri: $originalTreeUri, ')
          ..write('originalTreeRelativePath: $originalTreeRelativePath, ')
          ..write('importedAt: $importedAt, ')
          ..write('fileModifiedAt: $fileModifiedAt, ')
          ..write('originalCreatedAt: $originalCreatedAt, ')
          ..write('originalAccessedAt: $originalAccessedAt, ')
          ..write('originalMetadataJson: $originalMetadataJson, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('encryptedFileName: $encryptedFileName, ')
          ..write('fileSaltBase64: $fileSaltBase64, ')
          ..write('noncePrefixBase64: $noncePrefixBase64, ')
          ..write('sha256Hash: $sha256Hash, ')
          ..write('originalDeleted: $originalDeleted, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('playbackPositionMs: $playbackPositionMs, ')
          ..write('thumbnailFileName: $thumbnailFileName, ')
          ..write('thumbnailNoncePrefixBase64: $thumbnailNoncePrefixBase64, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('folderId: $folderId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivityEventsTable extends ActivityEvents
    with TableInfo<$ActivityEventsTable, ActivityEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _successMeta = const VerificationMeta(
    'success',
  );
  @override
  late final GeneratedColumn<bool> success = GeneratedColumn<bool>(
    'success',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("success" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    fileName,
    timestamp,
    success,
    detail,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('success')) {
      context.handle(
        _successMeta,
        success.isAcceptableOrUnknown(data['success']!, _successMeta),
      );
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      success: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}success'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
    );
  }

  @override
  $ActivityEventsTable createAlias(String alias) {
    return $ActivityEventsTable(attachedDatabase, alias);
  }
}

class ActivityEventRow extends DataClass
    implements Insertable<ActivityEventRow> {
  final String id;
  final String type;
  final String fileName;
  final DateTime timestamp;
  final bool success;
  final String? detail;
  const ActivityEventRow({
    required this.id,
    required this.type,
    required this.fileName,
    required this.timestamp,
    required this.success,
    this.detail,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['file_name'] = Variable<String>(fileName);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['success'] = Variable<bool>(success);
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    return map;
  }

  ActivityEventsCompanion toCompanion(bool nullToAbsent) {
    return ActivityEventsCompanion(
      id: Value(id),
      type: Value(type),
      fileName: Value(fileName),
      timestamp: Value(timestamp),
      success: Value(success),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
    );
  }

  factory ActivityEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityEventRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      fileName: serializer.fromJson<String>(json['fileName']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      success: serializer.fromJson<bool>(json['success']),
      detail: serializer.fromJson<String?>(json['detail']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'fileName': serializer.toJson<String>(fileName),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'success': serializer.toJson<bool>(success),
      'detail': serializer.toJson<String?>(detail),
    };
  }

  ActivityEventRow copyWith({
    String? id,
    String? type,
    String? fileName,
    DateTime? timestamp,
    bool? success,
    Value<String?> detail = const Value.absent(),
  }) => ActivityEventRow(
    id: id ?? this.id,
    type: type ?? this.type,
    fileName: fileName ?? this.fileName,
    timestamp: timestamp ?? this.timestamp,
    success: success ?? this.success,
    detail: detail.present ? detail.value : this.detail,
  );
  ActivityEventRow copyWithCompanion(ActivityEventsCompanion data) {
    return ActivityEventRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      success: data.success.present ? data.success.value : this.success,
      detail: data.detail.present ? data.detail.value : this.detail,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityEventRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('fileName: $fileName, ')
          ..write('timestamp: $timestamp, ')
          ..write('success: $success, ')
          ..write('detail: $detail')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, fileName, timestamp, success, detail);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityEventRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.fileName == this.fileName &&
          other.timestamp == this.timestamp &&
          other.success == this.success &&
          other.detail == this.detail);
}

class ActivityEventsCompanion extends UpdateCompanion<ActivityEventRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> fileName;
  final Value<DateTime> timestamp;
  final Value<bool> success;
  final Value<String?> detail;
  final Value<int> rowid;
  const ActivityEventsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.fileName = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.success = const Value.absent(),
    this.detail = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivityEventsCompanion.insert({
    required String id,
    required String type,
    required String fileName,
    required DateTime timestamp,
    this.success = const Value.absent(),
    this.detail = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       fileName = Value(fileName),
       timestamp = Value(timestamp);
  static Insertable<ActivityEventRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? fileName,
    Expression<DateTime>? timestamp,
    Expression<bool>? success,
    Expression<String>? detail,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (fileName != null) 'file_name': fileName,
      if (timestamp != null) 'timestamp': timestamp,
      if (success != null) 'success': success,
      if (detail != null) 'detail': detail,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivityEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? fileName,
    Value<DateTime>? timestamp,
    Value<bool>? success,
    Value<String?>? detail,
    Value<int>? rowid,
  }) {
    return ActivityEventsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      timestamp: timestamp ?? this.timestamp,
      success: success ?? this.success,
      detail: detail ?? this.detail,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (success.present) {
      map['success'] = Variable<bool>(success.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityEventsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('fileName: $fileName, ')
          ..write('timestamp: $timestamp, ')
          ..write('success: $success, ')
          ..write('detail: $detail, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultFoldersTable extends VaultFolders
    with TableInfo<$VaultFoldersTable, VaultFolderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, parentId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultFolderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultFolderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultFolderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VaultFoldersTable createAlias(String alias) {
    return $VaultFoldersTable(attachedDatabase, alias);
  }
}

class VaultFolderRow extends DataClass implements Insertable<VaultFolderRow> {
  final String id;
  final String name;

  /// Null means a top-level folder.
  final String? parentId;
  final DateTime createdAt;
  const VaultFolderRow({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VaultFoldersCompanion toCompanion(bool nullToAbsent) {
    return VaultFoldersCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      createdAt: Value(createdAt),
    );
  }

  factory VaultFolderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultFolderRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VaultFolderRow copyWith({
    String? id,
    String? name,
    Value<String?> parentId = const Value.absent(),
    DateTime? createdAt,
  }) => VaultFolderRow(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    createdAt: createdAt ?? this.createdAt,
  );
  VaultFolderRow copyWithCompanion(VaultFoldersCompanion data) {
    return VaultFolderRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultFolderRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, parentId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultFolderRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.createdAt == this.createdAt);
}

class VaultFoldersCompanion extends UpdateCompanion<VaultFolderRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const VaultFoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultFoldersCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<VaultFolderRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultFoldersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? parentId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return VaultFoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultFoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultTagsTable extends VaultTags
    with TableInfo<$VaultTagsTable, VaultTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultTagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $VaultTagsTable createAlias(String alias) {
    return $VaultTagsTable(attachedDatabase, alias);
  }
}

class VaultTagRow extends DataClass implements Insertable<VaultTagRow> {
  final String id;
  final String name;
  const VaultTagRow({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  VaultTagsCompanion toCompanion(bool nullToAbsent) {
    return VaultTagsCompanion(id: Value(id), name: Value(name));
  }

  factory VaultTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultTagRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  VaultTagRow copyWith({String? id, String? name}) =>
      VaultTagRow(id: id ?? this.id, name: name ?? this.name);
  VaultTagRow copyWithCompanion(VaultTagsCompanion data) {
    return VaultTagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultTagRow(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultTagRow && other.id == this.id && other.name == this.name);
}

class VaultTagsCompanion extends UpdateCompanion<VaultTagRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rowid;
  const VaultTagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultTagsCompanion.insert({
    required String id,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<VaultTagRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultTagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return VaultTagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultTagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultFileTagsTable extends VaultFileTags
    with TableInfo<$VaultFileTagsTable, VaultFileTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultFileTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [fileId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_file_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultFileTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fileId, tagId};
  @override
  VaultFileTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultFileTagRow(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $VaultFileTagsTable createAlias(String alias) {
    return $VaultFileTagsTable(attachedDatabase, alias);
  }
}

class VaultFileTagRow extends DataClass implements Insertable<VaultFileTagRow> {
  final String fileId;
  final String tagId;
  const VaultFileTagRow({required this.fileId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<String>(fileId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  VaultFileTagsCompanion toCompanion(bool nullToAbsent) {
    return VaultFileTagsCompanion(fileId: Value(fileId), tagId: Value(tagId));
  }

  factory VaultFileTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultFileTagRow(
      fileId: serializer.fromJson<String>(json['fileId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileId': serializer.toJson<String>(fileId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  VaultFileTagRow copyWith({String? fileId, String? tagId}) => VaultFileTagRow(
    fileId: fileId ?? this.fileId,
    tagId: tagId ?? this.tagId,
  );
  VaultFileTagRow copyWithCompanion(VaultFileTagsCompanion data) {
    return VaultFileTagRow(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultFileTagRow(')
          ..write('fileId: $fileId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fileId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultFileTagRow &&
          other.fileId == this.fileId &&
          other.tagId == this.tagId);
}

class VaultFileTagsCompanion extends UpdateCompanion<VaultFileTagRow> {
  final Value<String> fileId;
  final Value<String> tagId;
  final Value<int> rowid;
  const VaultFileTagsCompanion({
    this.fileId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultFileTagsCompanion.insert({
    required String fileId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       tagId = Value(tagId);
  static Insertable<VaultFileTagRow> custom({
    Expression<String>? fileId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultFileTagsCompanion copyWith({
    Value<String>? fileId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return VaultFileTagsCompanion(
      fileId: fileId ?? this.fileId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultFileTagsCompanion(')
          ..write('fileId: $fileId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultCollectionsTable extends VaultCollections
    with TableInfo<$VaultCollectionsTable, VaultCollectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultCollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultCollectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultCollectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultCollectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VaultCollectionsTable createAlias(String alias) {
    return $VaultCollectionsTable(attachedDatabase, alias);
  }
}

class VaultCollectionRow extends DataClass
    implements Insertable<VaultCollectionRow> {
  final String id;
  final String name;
  final DateTime createdAt;
  const VaultCollectionRow({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VaultCollectionsCompanion toCompanion(bool nullToAbsent) {
    return VaultCollectionsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory VaultCollectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultCollectionRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VaultCollectionRow copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) => VaultCollectionRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  VaultCollectionRow copyWithCompanion(VaultCollectionsCompanion data) {
    return VaultCollectionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultCollectionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultCollectionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class VaultCollectionsCompanion extends UpdateCompanion<VaultCollectionRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const VaultCollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultCollectionsCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<VaultCollectionRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultCollectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return VaultCollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultCollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultCollectionFilesTable extends VaultCollectionFiles
    with TableInfo<$VaultCollectionFilesTable, VaultCollectionFileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultCollectionFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [collectionId, fileId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_collection_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultCollectionFileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collectionId, fileId};
  @override
  VaultCollectionFileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultCollectionFileRow(
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      )!,
    );
  }

  @override
  $VaultCollectionFilesTable createAlias(String alias) {
    return $VaultCollectionFilesTable(attachedDatabase, alias);
  }
}

class VaultCollectionFileRow extends DataClass
    implements Insertable<VaultCollectionFileRow> {
  final String collectionId;
  final String fileId;
  const VaultCollectionFileRow({
    required this.collectionId,
    required this.fileId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection_id'] = Variable<String>(collectionId);
    map['file_id'] = Variable<String>(fileId);
    return map;
  }

  VaultCollectionFilesCompanion toCompanion(bool nullToAbsent) {
    return VaultCollectionFilesCompanion(
      collectionId: Value(collectionId),
      fileId: Value(fileId),
    );
  }

  factory VaultCollectionFileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultCollectionFileRow(
      collectionId: serializer.fromJson<String>(json['collectionId']),
      fileId: serializer.fromJson<String>(json['fileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collectionId': serializer.toJson<String>(collectionId),
      'fileId': serializer.toJson<String>(fileId),
    };
  }

  VaultCollectionFileRow copyWith({String? collectionId, String? fileId}) =>
      VaultCollectionFileRow(
        collectionId: collectionId ?? this.collectionId,
        fileId: fileId ?? this.fileId,
      );
  VaultCollectionFileRow copyWithCompanion(VaultCollectionFilesCompanion data) {
    return VaultCollectionFileRow(
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultCollectionFileRow(')
          ..write('collectionId: $collectionId, ')
          ..write('fileId: $fileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(collectionId, fileId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultCollectionFileRow &&
          other.collectionId == this.collectionId &&
          other.fileId == this.fileId);
}

class VaultCollectionFilesCompanion
    extends UpdateCompanion<VaultCollectionFileRow> {
  final Value<String> collectionId;
  final Value<String> fileId;
  final Value<int> rowid;
  const VaultCollectionFilesCompanion({
    this.collectionId = const Value.absent(),
    this.fileId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultCollectionFilesCompanion.insert({
    required String collectionId,
    required String fileId,
    this.rowid = const Value.absent(),
  }) : collectionId = Value(collectionId),
       fileId = Value(fileId);
  static Insertable<VaultCollectionFileRow> custom({
    Expression<String>? collectionId,
    Expression<String>? fileId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collectionId != null) 'collection_id': collectionId,
      if (fileId != null) 'file_id': fileId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultCollectionFilesCompanion copyWith({
    Value<String>? collectionId,
    Value<String>? fileId,
    Value<int>? rowid,
  }) {
    return VaultCollectionFilesCompanion(
      collectionId: collectionId ?? this.collectionId,
      fileId: fileId ?? this.fileId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultCollectionFilesCompanion(')
          ..write('collectionId: $collectionId, ')
          ..write('fileId: $fileId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultSmartAlbumsTable extends VaultSmartAlbums
    with TableInfo<$VaultSmartAlbumsTable, VaultSmartAlbumRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultSmartAlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryFilterMeta = const VerificationMeta(
    'categoryFilter',
  );
  @override
  late final GeneratedColumn<String> categoryFilter = GeneratedColumn<String>(
    'category_filter',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _favoritesOnlyMeta = const VerificationMeta(
    'favoritesOnly',
  );
  @override
  late final GeneratedColumn<bool> favoritesOnly = GeneratedColumn<bool>(
    'favorites_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorites_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    categoryFilter,
    favoritesOnly,
    tagId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_smart_albums';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultSmartAlbumRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_filter')) {
      context.handle(
        _categoryFilterMeta,
        categoryFilter.isAcceptableOrUnknown(
          data['category_filter']!,
          _categoryFilterMeta,
        ),
      );
    }
    if (data.containsKey('favorites_only')) {
      context.handle(
        _favoritesOnlyMeta,
        favoritesOnly.isAcceptableOrUnknown(
          data['favorites_only']!,
          _favoritesOnlyMeta,
        ),
      );
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VaultSmartAlbumRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultSmartAlbumRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      categoryFilter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_filter'],
      ),
      favoritesOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorites_only'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VaultSmartAlbumsTable createAlias(String alias) {
    return $VaultSmartAlbumsTable(attachedDatabase, alias);
  }
}

class VaultSmartAlbumRow extends DataClass
    implements Insertable<VaultSmartAlbumRow> {
  final String id;
  final String name;

  /// [FileCategory.name], or null for "any category".
  final String? categoryFilter;
  final bool favoritesOnly;

  /// Must carry this tag, or null for "any tag".
  final String? tagId;
  final DateTime createdAt;
  const VaultSmartAlbumRow({
    required this.id,
    required this.name,
    this.categoryFilter,
    required this.favoritesOnly,
    this.tagId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || categoryFilter != null) {
      map['category_filter'] = Variable<String>(categoryFilter);
    }
    map['favorites_only'] = Variable<bool>(favoritesOnly);
    if (!nullToAbsent || tagId != null) {
      map['tag_id'] = Variable<String>(tagId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VaultSmartAlbumsCompanion toCompanion(bool nullToAbsent) {
    return VaultSmartAlbumsCompanion(
      id: Value(id),
      name: Value(name),
      categoryFilter: categoryFilter == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryFilter),
      favoritesOnly: Value(favoritesOnly),
      tagId: tagId == null && nullToAbsent
          ? const Value.absent()
          : Value(tagId),
      createdAt: Value(createdAt),
    );
  }

  factory VaultSmartAlbumRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultSmartAlbumRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      categoryFilter: serializer.fromJson<String?>(json['categoryFilter']),
      favoritesOnly: serializer.fromJson<bool>(json['favoritesOnly']),
      tagId: serializer.fromJson<String?>(json['tagId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'categoryFilter': serializer.toJson<String?>(categoryFilter),
      'favoritesOnly': serializer.toJson<bool>(favoritesOnly),
      'tagId': serializer.toJson<String?>(tagId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VaultSmartAlbumRow copyWith({
    String? id,
    String? name,
    Value<String?> categoryFilter = const Value.absent(),
    bool? favoritesOnly,
    Value<String?> tagId = const Value.absent(),
    DateTime? createdAt,
  }) => VaultSmartAlbumRow(
    id: id ?? this.id,
    name: name ?? this.name,
    categoryFilter: categoryFilter.present
        ? categoryFilter.value
        : this.categoryFilter,
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    tagId: tagId.present ? tagId.value : this.tagId,
    createdAt: createdAt ?? this.createdAt,
  );
  VaultSmartAlbumRow copyWithCompanion(VaultSmartAlbumsCompanion data) {
    return VaultSmartAlbumRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      categoryFilter: data.categoryFilter.present
          ? data.categoryFilter.value
          : this.categoryFilter,
      favoritesOnly: data.favoritesOnly.present
          ? data.favoritesOnly.value
          : this.favoritesOnly,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultSmartAlbumRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryFilter: $categoryFilter, ')
          ..write('favoritesOnly: $favoritesOnly, ')
          ..write('tagId: $tagId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, categoryFilter, favoritesOnly, tagId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultSmartAlbumRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.categoryFilter == this.categoryFilter &&
          other.favoritesOnly == this.favoritesOnly &&
          other.tagId == this.tagId &&
          other.createdAt == this.createdAt);
}

class VaultSmartAlbumsCompanion extends UpdateCompanion<VaultSmartAlbumRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> categoryFilter;
  final Value<bool> favoritesOnly;
  final Value<String?> tagId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const VaultSmartAlbumsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryFilter = const Value.absent(),
    this.favoritesOnly = const Value.absent(),
    this.tagId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultSmartAlbumsCompanion.insert({
    required String id,
    required String name,
    this.categoryFilter = const Value.absent(),
    this.favoritesOnly = const Value.absent(),
    this.tagId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<VaultSmartAlbumRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? categoryFilter,
    Expression<bool>? favoritesOnly,
    Expression<String>? tagId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (categoryFilter != null) 'category_filter': categoryFilter,
      if (favoritesOnly != null) 'favorites_only': favoritesOnly,
      if (tagId != null) 'tag_id': tagId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultSmartAlbumsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? categoryFilter,
    Value<bool>? favoritesOnly,
    Value<String?>? tagId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return VaultSmartAlbumsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      tagId: tagId ?? this.tagId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryFilter.present) {
      map['category_filter'] = Variable<String>(categoryFilter.value);
    }
    if (favoritesOnly.present) {
      map['favorites_only'] = Variable<bool>(favoritesOnly.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultSmartAlbumsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryFilter: $categoryFilter, ')
          ..write('favoritesOnly: $favoritesOnly, ')
          ..write('tagId: $tagId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultSyncStatesTable extends VaultSyncStates
    with TableInfo<$VaultSyncStatesTable, VaultSyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultSyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localFileIdMeta = const VerificationMeta(
    'localFileId',
  );
  @override
  late final GeneratedColumn<String> localFileId = GeneratedColumn<String>(
    'local_file_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logicalIdMeta = const VerificationMeta(
    'logicalId',
  );
  @override
  late final GeneratedColumn<String> logicalId = GeneratedColumn<String>(
    'logical_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latestVersionIdMeta = const VerificationMeta(
    'latestVersionId',
  );
  @override
  late final GeneratedColumn<String> latestVersionId = GeneratedColumn<String>(
    'latest_version_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _knownVersionIdsJsonMeta =
      const VerificationMeta('knownVersionIdsJson');
  @override
  late final GeneratedColumn<String> knownVersionIdsJson =
      GeneratedColumn<String>(
        'known_version_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _vectorJsonMeta = const VerificationMeta(
    'vectorJson',
  );
  @override
  late final GeneratedColumn<String> vectorJson = GeneratedColumn<String>(
    'vector_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _lastPublishedRevisionIdMeta =
      const VerificationMeta('lastPublishedRevisionId');
  @override
  late final GeneratedColumn<String> lastPublishedRevisionId =
      GeneratedColumn<String>(
        'last_published_revision_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastPublishedAtMeta = const VerificationMeta(
    'lastPublishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPublishedAt =
      GeneratedColumn<DateTime>(
        'last_published_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isConflictMeta = const VerificationMeta(
    'isConflict',
  );
  @override
  late final GeneratedColumn<bool> isConflict = GeneratedColumn<bool>(
    'is_conflict',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_conflict" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    localFileId,
    logicalId,
    latestVersionId,
    knownVersionIdsJson,
    vectorJson,
    lastPublishedRevisionId,
    lastPublishedAt,
    isConflict,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultSyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_file_id')) {
      context.handle(
        _localFileIdMeta,
        localFileId.isAcceptableOrUnknown(
          data['local_file_id']!,
          _localFileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localFileIdMeta);
    }
    if (data.containsKey('logical_id')) {
      context.handle(
        _logicalIdMeta,
        logicalId.isAcceptableOrUnknown(data['logical_id']!, _logicalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_logicalIdMeta);
    }
    if (data.containsKey('latest_version_id')) {
      context.handle(
        _latestVersionIdMeta,
        latestVersionId.isAcceptableOrUnknown(
          data['latest_version_id']!,
          _latestVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('known_version_ids_json')) {
      context.handle(
        _knownVersionIdsJsonMeta,
        knownVersionIdsJson.isAcceptableOrUnknown(
          data['known_version_ids_json']!,
          _knownVersionIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('vector_json')) {
      context.handle(
        _vectorJsonMeta,
        vectorJson.isAcceptableOrUnknown(data['vector_json']!, _vectorJsonMeta),
      );
    }
    if (data.containsKey('last_published_revision_id')) {
      context.handle(
        _lastPublishedRevisionIdMeta,
        lastPublishedRevisionId.isAcceptableOrUnknown(
          data['last_published_revision_id']!,
          _lastPublishedRevisionIdMeta,
        ),
      );
    }
    if (data.containsKey('last_published_at')) {
      context.handle(
        _lastPublishedAtMeta,
        lastPublishedAt.isAcceptableOrUnknown(
          data['last_published_at']!,
          _lastPublishedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_conflict')) {
      context.handle(
        _isConflictMeta,
        isConflict.isAcceptableOrUnknown(data['is_conflict']!, _isConflictMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localFileId};
  @override
  VaultSyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultSyncStateRow(
      localFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_id'],
      )!,
      logicalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logical_id'],
      )!,
      latestVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latest_version_id'],
      ),
      knownVersionIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}known_version_ids_json'],
      )!,
      vectorJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vector_json'],
      )!,
      lastPublishedRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_published_revision_id'],
      ),
      lastPublishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_published_at'],
      ),
      isConflict: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_conflict'],
      )!,
    );
  }

  @override
  $VaultSyncStatesTable createAlias(String alias) {
    return $VaultSyncStatesTable(attachedDatabase, alias);
  }
}

class VaultSyncStateRow extends DataClass
    implements Insertable<VaultSyncStateRow> {
  final String localFileId;
  final String logicalId;
  final String? latestVersionId;
  final String knownVersionIdsJson;
  final String vectorJson;
  final String? lastPublishedRevisionId;
  final DateTime? lastPublishedAt;
  final bool isConflict;
  const VaultSyncStateRow({
    required this.localFileId,
    required this.logicalId,
    this.latestVersionId,
    required this.knownVersionIdsJson,
    required this.vectorJson,
    this.lastPublishedRevisionId,
    this.lastPublishedAt,
    required this.isConflict,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_file_id'] = Variable<String>(localFileId);
    map['logical_id'] = Variable<String>(logicalId);
    if (!nullToAbsent || latestVersionId != null) {
      map['latest_version_id'] = Variable<String>(latestVersionId);
    }
    map['known_version_ids_json'] = Variable<String>(knownVersionIdsJson);
    map['vector_json'] = Variable<String>(vectorJson);
    if (!nullToAbsent || lastPublishedRevisionId != null) {
      map['last_published_revision_id'] = Variable<String>(
        lastPublishedRevisionId,
      );
    }
    if (!nullToAbsent || lastPublishedAt != null) {
      map['last_published_at'] = Variable<DateTime>(lastPublishedAt);
    }
    map['is_conflict'] = Variable<bool>(isConflict);
    return map;
  }

  VaultSyncStatesCompanion toCompanion(bool nullToAbsent) {
    return VaultSyncStatesCompanion(
      localFileId: Value(localFileId),
      logicalId: Value(logicalId),
      latestVersionId: latestVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(latestVersionId),
      knownVersionIdsJson: Value(knownVersionIdsJson),
      vectorJson: Value(vectorJson),
      lastPublishedRevisionId: lastPublishedRevisionId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPublishedRevisionId),
      lastPublishedAt: lastPublishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPublishedAt),
      isConflict: Value(isConflict),
    );
  }

  factory VaultSyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultSyncStateRow(
      localFileId: serializer.fromJson<String>(json['localFileId']),
      logicalId: serializer.fromJson<String>(json['logicalId']),
      latestVersionId: serializer.fromJson<String?>(json['latestVersionId']),
      knownVersionIdsJson: serializer.fromJson<String>(
        json['knownVersionIdsJson'],
      ),
      vectorJson: serializer.fromJson<String>(json['vectorJson']),
      lastPublishedRevisionId: serializer.fromJson<String?>(
        json['lastPublishedRevisionId'],
      ),
      lastPublishedAt: serializer.fromJson<DateTime?>(json['lastPublishedAt']),
      isConflict: serializer.fromJson<bool>(json['isConflict']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localFileId': serializer.toJson<String>(localFileId),
      'logicalId': serializer.toJson<String>(logicalId),
      'latestVersionId': serializer.toJson<String?>(latestVersionId),
      'knownVersionIdsJson': serializer.toJson<String>(knownVersionIdsJson),
      'vectorJson': serializer.toJson<String>(vectorJson),
      'lastPublishedRevisionId': serializer.toJson<String?>(
        lastPublishedRevisionId,
      ),
      'lastPublishedAt': serializer.toJson<DateTime?>(lastPublishedAt),
      'isConflict': serializer.toJson<bool>(isConflict),
    };
  }

  VaultSyncStateRow copyWith({
    String? localFileId,
    String? logicalId,
    Value<String?> latestVersionId = const Value.absent(),
    String? knownVersionIdsJson,
    String? vectorJson,
    Value<String?> lastPublishedRevisionId = const Value.absent(),
    Value<DateTime?> lastPublishedAt = const Value.absent(),
    bool? isConflict,
  }) => VaultSyncStateRow(
    localFileId: localFileId ?? this.localFileId,
    logicalId: logicalId ?? this.logicalId,
    latestVersionId: latestVersionId.present
        ? latestVersionId.value
        : this.latestVersionId,
    knownVersionIdsJson: knownVersionIdsJson ?? this.knownVersionIdsJson,
    vectorJson: vectorJson ?? this.vectorJson,
    lastPublishedRevisionId: lastPublishedRevisionId.present
        ? lastPublishedRevisionId.value
        : this.lastPublishedRevisionId,
    lastPublishedAt: lastPublishedAt.present
        ? lastPublishedAt.value
        : this.lastPublishedAt,
    isConflict: isConflict ?? this.isConflict,
  );
  VaultSyncStateRow copyWithCompanion(VaultSyncStatesCompanion data) {
    return VaultSyncStateRow(
      localFileId: data.localFileId.present
          ? data.localFileId.value
          : this.localFileId,
      logicalId: data.logicalId.present ? data.logicalId.value : this.logicalId,
      latestVersionId: data.latestVersionId.present
          ? data.latestVersionId.value
          : this.latestVersionId,
      knownVersionIdsJson: data.knownVersionIdsJson.present
          ? data.knownVersionIdsJson.value
          : this.knownVersionIdsJson,
      vectorJson: data.vectorJson.present
          ? data.vectorJson.value
          : this.vectorJson,
      lastPublishedRevisionId: data.lastPublishedRevisionId.present
          ? data.lastPublishedRevisionId.value
          : this.lastPublishedRevisionId,
      lastPublishedAt: data.lastPublishedAt.present
          ? data.lastPublishedAt.value
          : this.lastPublishedAt,
      isConflict: data.isConflict.present
          ? data.isConflict.value
          : this.isConflict,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultSyncStateRow(')
          ..write('localFileId: $localFileId, ')
          ..write('logicalId: $logicalId, ')
          ..write('latestVersionId: $latestVersionId, ')
          ..write('knownVersionIdsJson: $knownVersionIdsJson, ')
          ..write('vectorJson: $vectorJson, ')
          ..write('lastPublishedRevisionId: $lastPublishedRevisionId, ')
          ..write('lastPublishedAt: $lastPublishedAt, ')
          ..write('isConflict: $isConflict')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localFileId,
    logicalId,
    latestVersionId,
    knownVersionIdsJson,
    vectorJson,
    lastPublishedRevisionId,
    lastPublishedAt,
    isConflict,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultSyncStateRow &&
          other.localFileId == this.localFileId &&
          other.logicalId == this.logicalId &&
          other.latestVersionId == this.latestVersionId &&
          other.knownVersionIdsJson == this.knownVersionIdsJson &&
          other.vectorJson == this.vectorJson &&
          other.lastPublishedRevisionId == this.lastPublishedRevisionId &&
          other.lastPublishedAt == this.lastPublishedAt &&
          other.isConflict == this.isConflict);
}

class VaultSyncStatesCompanion extends UpdateCompanion<VaultSyncStateRow> {
  final Value<String> localFileId;
  final Value<String> logicalId;
  final Value<String?> latestVersionId;
  final Value<String> knownVersionIdsJson;
  final Value<String> vectorJson;
  final Value<String?> lastPublishedRevisionId;
  final Value<DateTime?> lastPublishedAt;
  final Value<bool> isConflict;
  final Value<int> rowid;
  const VaultSyncStatesCompanion({
    this.localFileId = const Value.absent(),
    this.logicalId = const Value.absent(),
    this.latestVersionId = const Value.absent(),
    this.knownVersionIdsJson = const Value.absent(),
    this.vectorJson = const Value.absent(),
    this.lastPublishedRevisionId = const Value.absent(),
    this.lastPublishedAt = const Value.absent(),
    this.isConflict = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultSyncStatesCompanion.insert({
    required String localFileId,
    required String logicalId,
    this.latestVersionId = const Value.absent(),
    this.knownVersionIdsJson = const Value.absent(),
    this.vectorJson = const Value.absent(),
    this.lastPublishedRevisionId = const Value.absent(),
    this.lastPublishedAt = const Value.absent(),
    this.isConflict = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localFileId = Value(localFileId),
       logicalId = Value(logicalId);
  static Insertable<VaultSyncStateRow> custom({
    Expression<String>? localFileId,
    Expression<String>? logicalId,
    Expression<String>? latestVersionId,
    Expression<String>? knownVersionIdsJson,
    Expression<String>? vectorJson,
    Expression<String>? lastPublishedRevisionId,
    Expression<DateTime>? lastPublishedAt,
    Expression<bool>? isConflict,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localFileId != null) 'local_file_id': localFileId,
      if (logicalId != null) 'logical_id': logicalId,
      if (latestVersionId != null) 'latest_version_id': latestVersionId,
      if (knownVersionIdsJson != null)
        'known_version_ids_json': knownVersionIdsJson,
      if (vectorJson != null) 'vector_json': vectorJson,
      if (lastPublishedRevisionId != null)
        'last_published_revision_id': lastPublishedRevisionId,
      if (lastPublishedAt != null) 'last_published_at': lastPublishedAt,
      if (isConflict != null) 'is_conflict': isConflict,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultSyncStatesCompanion copyWith({
    Value<String>? localFileId,
    Value<String>? logicalId,
    Value<String?>? latestVersionId,
    Value<String>? knownVersionIdsJson,
    Value<String>? vectorJson,
    Value<String?>? lastPublishedRevisionId,
    Value<DateTime?>? lastPublishedAt,
    Value<bool>? isConflict,
    Value<int>? rowid,
  }) {
    return VaultSyncStatesCompanion(
      localFileId: localFileId ?? this.localFileId,
      logicalId: logicalId ?? this.logicalId,
      latestVersionId: latestVersionId ?? this.latestVersionId,
      knownVersionIdsJson: knownVersionIdsJson ?? this.knownVersionIdsJson,
      vectorJson: vectorJson ?? this.vectorJson,
      lastPublishedRevisionId:
          lastPublishedRevisionId ?? this.lastPublishedRevisionId,
      lastPublishedAt: lastPublishedAt ?? this.lastPublishedAt,
      isConflict: isConflict ?? this.isConflict,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localFileId.present) {
      map['local_file_id'] = Variable<String>(localFileId.value);
    }
    if (logicalId.present) {
      map['logical_id'] = Variable<String>(logicalId.value);
    }
    if (latestVersionId.present) {
      map['latest_version_id'] = Variable<String>(latestVersionId.value);
    }
    if (knownVersionIdsJson.present) {
      map['known_version_ids_json'] = Variable<String>(
        knownVersionIdsJson.value,
      );
    }
    if (vectorJson.present) {
      map['vector_json'] = Variable<String>(vectorJson.value);
    }
    if (lastPublishedRevisionId.present) {
      map['last_published_revision_id'] = Variable<String>(
        lastPublishedRevisionId.value,
      );
    }
    if (lastPublishedAt.present) {
      map['last_published_at'] = Variable<DateTime>(lastPublishedAt.value);
    }
    if (isConflict.present) {
      map['is_conflict'] = Variable<bool>(isConflict.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultSyncStatesCompanion(')
          ..write('localFileId: $localFileId, ')
          ..write('logicalId: $logicalId, ')
          ..write('latestVersionId: $latestVersionId, ')
          ..write('knownVersionIdsJson: $knownVersionIdsJson, ')
          ..write('vectorJson: $vectorJson, ')
          ..write('lastPublishedRevisionId: $lastPublishedRevisionId, ')
          ..write('lastPublishedAt: $lastPublishedAt, ')
          ..write('isConflict: $isConflict, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VaultFilesTable vaultFiles = $VaultFilesTable(this);
  late final $ActivityEventsTable activityEvents = $ActivityEventsTable(this);
  late final $VaultFoldersTable vaultFolders = $VaultFoldersTable(this);
  late final $VaultTagsTable vaultTags = $VaultTagsTable(this);
  late final $VaultFileTagsTable vaultFileTags = $VaultFileTagsTable(this);
  late final $VaultCollectionsTable vaultCollections = $VaultCollectionsTable(
    this,
  );
  late final $VaultCollectionFilesTable vaultCollectionFiles =
      $VaultCollectionFilesTable(this);
  late final $VaultSmartAlbumsTable vaultSmartAlbums = $VaultSmartAlbumsTable(
    this,
  );
  late final $VaultSyncStatesTable vaultSyncStates = $VaultSyncStatesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vaultFiles,
    activityEvents,
    vaultFolders,
    vaultTags,
    vaultFileTags,
    vaultCollections,
    vaultCollectionFiles,
    vaultSmartAlbums,
    vaultSyncStates,
  ];
}

typedef $$VaultFilesTableCreateCompanionBuilder =
    VaultFilesCompanion Function({
      required String id,
      required String originalName,
      required String extension,
      required String mimeType,
      required int sizeBytes,
      Value<String?> originalPath,
      Value<String?> originalContentUri,
      Value<String?> originalRelativePath,
      Value<String?> originalTreeUri,
      Value<String?> originalTreeRelativePath,
      required DateTime importedAt,
      Value<DateTime?> fileModifiedAt,
      Value<DateTime?> originalCreatedAt,
      Value<DateTime?> originalAccessedAt,
      Value<String?> originalMetadataJson,
      required String category,
      required String status,
      required String encryptedFileName,
      required String fileSaltBase64,
      required String noncePrefixBase64,
      Value<String> sha256Hash,
      Value<bool> originalDeleted,
      Value<bool> isFavorite,
      Value<DateTime?> lastOpenedAt,
      Value<int?> playbackPositionMs,
      Value<String?> thumbnailFileName,
      Value<String?> thumbnailNoncePrefixBase64,
      Value<DateTime?> deletedAt,
      Value<String?> folderId,
      Value<int> rowid,
    });
typedef $$VaultFilesTableUpdateCompanionBuilder =
    VaultFilesCompanion Function({
      Value<String> id,
      Value<String> originalName,
      Value<String> extension,
      Value<String> mimeType,
      Value<int> sizeBytes,
      Value<String?> originalPath,
      Value<String?> originalContentUri,
      Value<String?> originalRelativePath,
      Value<String?> originalTreeUri,
      Value<String?> originalTreeRelativePath,
      Value<DateTime> importedAt,
      Value<DateTime?> fileModifiedAt,
      Value<DateTime?> originalCreatedAt,
      Value<DateTime?> originalAccessedAt,
      Value<String?> originalMetadataJson,
      Value<String> category,
      Value<String> status,
      Value<String> encryptedFileName,
      Value<String> fileSaltBase64,
      Value<String> noncePrefixBase64,
      Value<String> sha256Hash,
      Value<bool> originalDeleted,
      Value<bool> isFavorite,
      Value<DateTime?> lastOpenedAt,
      Value<int?> playbackPositionMs,
      Value<String?> thumbnailFileName,
      Value<String?> thumbnailNoncePrefixBase64,
      Value<DateTime?> deletedAt,
      Value<String?> folderId,
      Value<int> rowid,
    });

class $$VaultFilesTableFilterComposer
    extends Composer<_$AppDatabase, $VaultFilesTable> {
  $$VaultFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extension => $composableBuilder(
    column: $table.extension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalContentUri => $composableBuilder(
    column: $table.originalContentUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalRelativePath => $composableBuilder(
    column: $table.originalRelativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalTreeUri => $composableBuilder(
    column: $table.originalTreeUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalTreeRelativePath => $composableBuilder(
    column: $table.originalTreeRelativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fileModifiedAt => $composableBuilder(
    column: $table.fileModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get originalCreatedAt => $composableBuilder(
    column: $table.originalCreatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get originalAccessedAt => $composableBuilder(
    column: $table.originalAccessedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalMetadataJson => $composableBuilder(
    column: $table.originalMetadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedFileName => $composableBuilder(
    column: $table.encryptedFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileSaltBase64 => $composableBuilder(
    column: $table.fileSaltBase64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noncePrefixBase64 => $composableBuilder(
    column: $table.noncePrefixBase64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get originalDeleted => $composableBuilder(
    column: $table.originalDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playbackPositionMs => $composableBuilder(
    column: $table.playbackPositionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailFileName => $composableBuilder(
    column: $table.thumbnailFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailNoncePrefixBase64 => $composableBuilder(
    column: $table.thumbnailNoncePrefixBase64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultFilesTable> {
  $$VaultFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extension => $composableBuilder(
    column: $table.extension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalContentUri => $composableBuilder(
    column: $table.originalContentUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalRelativePath => $composableBuilder(
    column: $table.originalRelativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalTreeUri => $composableBuilder(
    column: $table.originalTreeUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalTreeRelativePath => $composableBuilder(
    column: $table.originalTreeRelativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fileModifiedAt => $composableBuilder(
    column: $table.fileModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get originalCreatedAt => $composableBuilder(
    column: $table.originalCreatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get originalAccessedAt => $composableBuilder(
    column: $table.originalAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalMetadataJson => $composableBuilder(
    column: $table.originalMetadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedFileName => $composableBuilder(
    column: $table.encryptedFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileSaltBase64 => $composableBuilder(
    column: $table.fileSaltBase64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noncePrefixBase64 => $composableBuilder(
    column: $table.noncePrefixBase64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get originalDeleted => $composableBuilder(
    column: $table.originalDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playbackPositionMs => $composableBuilder(
    column: $table.playbackPositionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailFileName => $composableBuilder(
    column: $table.thumbnailFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailNoncePrefixBase64 => $composableBuilder(
    column: $table.thumbnailNoncePrefixBase64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultFilesTable> {
  $$VaultFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extension =>
      $composableBuilder(column: $table.extension, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalContentUri => $composableBuilder(
    column: $table.originalContentUri,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalRelativePath => $composableBuilder(
    column: $table.originalRelativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalTreeUri => $composableBuilder(
    column: $table.originalTreeUri,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalTreeRelativePath => $composableBuilder(
    column: $table.originalTreeRelativePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fileModifiedAt => $composableBuilder(
    column: $table.fileModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get originalCreatedAt => $composableBuilder(
    column: $table.originalCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get originalAccessedAt => $composableBuilder(
    column: $table.originalAccessedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalMetadataJson => $composableBuilder(
    column: $table.originalMetadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get encryptedFileName => $composableBuilder(
    column: $table.encryptedFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileSaltBase64 => $composableBuilder(
    column: $table.fileSaltBase64,
    builder: (column) => column,
  );

  GeneratedColumn<String> get noncePrefixBase64 => $composableBuilder(
    column: $table.noncePrefixBase64,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get originalDeleted => $composableBuilder(
    column: $table.originalDeleted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playbackPositionMs => $composableBuilder(
    column: $table.playbackPositionMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailFileName => $composableBuilder(
    column: $table.thumbnailFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailNoncePrefixBase64 => $composableBuilder(
    column: $table.thumbnailNoncePrefixBase64,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);
}

class $$VaultFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultFilesTable,
          VaultFileRow,
          $$VaultFilesTableFilterComposer,
          $$VaultFilesTableOrderingComposer,
          $$VaultFilesTableAnnotationComposer,
          $$VaultFilesTableCreateCompanionBuilder,
          $$VaultFilesTableUpdateCompanionBuilder,
          (
            VaultFileRow,
            BaseReferences<_$AppDatabase, $VaultFilesTable, VaultFileRow>,
          ),
          VaultFileRow,
          PrefetchHooks Function()
        > {
  $$VaultFilesTableTableManager(_$AppDatabase db, $VaultFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> originalName = const Value.absent(),
                Value<String> extension = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String?> originalPath = const Value.absent(),
                Value<String?> originalContentUri = const Value.absent(),
                Value<String?> originalRelativePath = const Value.absent(),
                Value<String?> originalTreeUri = const Value.absent(),
                Value<String?> originalTreeRelativePath = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<DateTime?> fileModifiedAt = const Value.absent(),
                Value<DateTime?> originalCreatedAt = const Value.absent(),
                Value<DateTime?> originalAccessedAt = const Value.absent(),
                Value<String?> originalMetadataJson = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> encryptedFileName = const Value.absent(),
                Value<String> fileSaltBase64 = const Value.absent(),
                Value<String> noncePrefixBase64 = const Value.absent(),
                Value<String> sha256Hash = const Value.absent(),
                Value<bool> originalDeleted = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<int?> playbackPositionMs = const Value.absent(),
                Value<String?> thumbnailFileName = const Value.absent(),
                Value<String?> thumbnailNoncePrefixBase64 =
                    const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultFilesCompanion(
                id: id,
                originalName: originalName,
                extension: extension,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                originalPath: originalPath,
                originalContentUri: originalContentUri,
                originalRelativePath: originalRelativePath,
                originalTreeUri: originalTreeUri,
                originalTreeRelativePath: originalTreeRelativePath,
                importedAt: importedAt,
                fileModifiedAt: fileModifiedAt,
                originalCreatedAt: originalCreatedAt,
                originalAccessedAt: originalAccessedAt,
                originalMetadataJson: originalMetadataJson,
                category: category,
                status: status,
                encryptedFileName: encryptedFileName,
                fileSaltBase64: fileSaltBase64,
                noncePrefixBase64: noncePrefixBase64,
                sha256Hash: sha256Hash,
                originalDeleted: originalDeleted,
                isFavorite: isFavorite,
                lastOpenedAt: lastOpenedAt,
                playbackPositionMs: playbackPositionMs,
                thumbnailFileName: thumbnailFileName,
                thumbnailNoncePrefixBase64: thumbnailNoncePrefixBase64,
                deletedAt: deletedAt,
                folderId: folderId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String originalName,
                required String extension,
                required String mimeType,
                required int sizeBytes,
                Value<String?> originalPath = const Value.absent(),
                Value<String?> originalContentUri = const Value.absent(),
                Value<String?> originalRelativePath = const Value.absent(),
                Value<String?> originalTreeUri = const Value.absent(),
                Value<String?> originalTreeRelativePath = const Value.absent(),
                required DateTime importedAt,
                Value<DateTime?> fileModifiedAt = const Value.absent(),
                Value<DateTime?> originalCreatedAt = const Value.absent(),
                Value<DateTime?> originalAccessedAt = const Value.absent(),
                Value<String?> originalMetadataJson = const Value.absent(),
                required String category,
                required String status,
                required String encryptedFileName,
                required String fileSaltBase64,
                required String noncePrefixBase64,
                Value<String> sha256Hash = const Value.absent(),
                Value<bool> originalDeleted = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<int?> playbackPositionMs = const Value.absent(),
                Value<String?> thumbnailFileName = const Value.absent(),
                Value<String?> thumbnailNoncePrefixBase64 =
                    const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultFilesCompanion.insert(
                id: id,
                originalName: originalName,
                extension: extension,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                originalPath: originalPath,
                originalContentUri: originalContentUri,
                originalRelativePath: originalRelativePath,
                originalTreeUri: originalTreeUri,
                originalTreeRelativePath: originalTreeRelativePath,
                importedAt: importedAt,
                fileModifiedAt: fileModifiedAt,
                originalCreatedAt: originalCreatedAt,
                originalAccessedAt: originalAccessedAt,
                originalMetadataJson: originalMetadataJson,
                category: category,
                status: status,
                encryptedFileName: encryptedFileName,
                fileSaltBase64: fileSaltBase64,
                noncePrefixBase64: noncePrefixBase64,
                sha256Hash: sha256Hash,
                originalDeleted: originalDeleted,
                isFavorite: isFavorite,
                lastOpenedAt: lastOpenedAt,
                playbackPositionMs: playbackPositionMs,
                thumbnailFileName: thumbnailFileName,
                thumbnailNoncePrefixBase64: thumbnailNoncePrefixBase64,
                deletedAt: deletedAt,
                folderId: folderId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultFilesTable,
      VaultFileRow,
      $$VaultFilesTableFilterComposer,
      $$VaultFilesTableOrderingComposer,
      $$VaultFilesTableAnnotationComposer,
      $$VaultFilesTableCreateCompanionBuilder,
      $$VaultFilesTableUpdateCompanionBuilder,
      (
        VaultFileRow,
        BaseReferences<_$AppDatabase, $VaultFilesTable, VaultFileRow>,
      ),
      VaultFileRow,
      PrefetchHooks Function()
    >;
typedef $$ActivityEventsTableCreateCompanionBuilder =
    ActivityEventsCompanion Function({
      required String id,
      required String type,
      required String fileName,
      required DateTime timestamp,
      Value<bool> success,
      Value<String?> detail,
      Value<int> rowid,
    });
typedef $$ActivityEventsTableUpdateCompanionBuilder =
    ActivityEventsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> fileName,
      Value<DateTime> timestamp,
      Value<bool> success,
      Value<String?> detail,
      Value<int> rowid,
    });

class $$ActivityEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityEventsTable> {
  $$ActivityEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get success => $composableBuilder(
    column: $table.success,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivityEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityEventsTable> {
  $$ActivityEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get success => $composableBuilder(
    column: $table.success,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivityEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityEventsTable> {
  $$ActivityEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get success =>
      $composableBuilder(column: $table.success, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);
}

class $$ActivityEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivityEventsTable,
          ActivityEventRow,
          $$ActivityEventsTableFilterComposer,
          $$ActivityEventsTableOrderingComposer,
          $$ActivityEventsTableAnnotationComposer,
          $$ActivityEventsTableCreateCompanionBuilder,
          $$ActivityEventsTableUpdateCompanionBuilder,
          (
            ActivityEventRow,
            BaseReferences<
              _$AppDatabase,
              $ActivityEventsTable,
              ActivityEventRow
            >,
          ),
          ActivityEventRow,
          PrefetchHooks Function()
        > {
  $$ActivityEventsTableTableManager(
    _$AppDatabase db,
    $ActivityEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<bool> success = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivityEventsCompanion(
                id: id,
                type: type,
                fileName: fileName,
                timestamp: timestamp,
                success: success,
                detail: detail,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String fileName,
                required DateTime timestamp,
                Value<bool> success = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivityEventsCompanion.insert(
                id: id,
                type: type,
                fileName: fileName,
                timestamp: timestamp,
                success: success,
                detail: detail,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivityEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivityEventsTable,
      ActivityEventRow,
      $$ActivityEventsTableFilterComposer,
      $$ActivityEventsTableOrderingComposer,
      $$ActivityEventsTableAnnotationComposer,
      $$ActivityEventsTableCreateCompanionBuilder,
      $$ActivityEventsTableUpdateCompanionBuilder,
      (
        ActivityEventRow,
        BaseReferences<_$AppDatabase, $ActivityEventsTable, ActivityEventRow>,
      ),
      ActivityEventRow,
      PrefetchHooks Function()
    >;
typedef $$VaultFoldersTableCreateCompanionBuilder =
    VaultFoldersCompanion Function({
      required String id,
      required String name,
      Value<String?> parentId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$VaultFoldersTableUpdateCompanionBuilder =
    VaultFoldersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> parentId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$VaultFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $VaultFoldersTable> {
  $$VaultFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultFoldersTable> {
  $$VaultFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultFoldersTable> {
  $$VaultFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$VaultFoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultFoldersTable,
          VaultFolderRow,
          $$VaultFoldersTableFilterComposer,
          $$VaultFoldersTableOrderingComposer,
          $$VaultFoldersTableAnnotationComposer,
          $$VaultFoldersTableCreateCompanionBuilder,
          $$VaultFoldersTableUpdateCompanionBuilder,
          (
            VaultFolderRow,
            BaseReferences<_$AppDatabase, $VaultFoldersTable, VaultFolderRow>,
          ),
          VaultFolderRow,
          PrefetchHooks Function()
        > {
  $$VaultFoldersTableTableManager(_$AppDatabase db, $VaultFoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultFoldersCompanion(
                id: id,
                name: name,
                parentId: parentId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> parentId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => VaultFoldersCompanion.insert(
                id: id,
                name: name,
                parentId: parentId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultFoldersTable,
      VaultFolderRow,
      $$VaultFoldersTableFilterComposer,
      $$VaultFoldersTableOrderingComposer,
      $$VaultFoldersTableAnnotationComposer,
      $$VaultFoldersTableCreateCompanionBuilder,
      $$VaultFoldersTableUpdateCompanionBuilder,
      (
        VaultFolderRow,
        BaseReferences<_$AppDatabase, $VaultFoldersTable, VaultFolderRow>,
      ),
      VaultFolderRow,
      PrefetchHooks Function()
    >;
typedef $$VaultTagsTableCreateCompanionBuilder =
    VaultTagsCompanion Function({
      required String id,
      required String name,
      Value<int> rowid,
    });
typedef $$VaultTagsTableUpdateCompanionBuilder =
    VaultTagsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> rowid,
    });

class $$VaultTagsTableFilterComposer
    extends Composer<_$AppDatabase, $VaultTagsTable> {
  $$VaultTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultTagsTable> {
  $$VaultTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultTagsTable> {
  $$VaultTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$VaultTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultTagsTable,
          VaultTagRow,
          $$VaultTagsTableFilterComposer,
          $$VaultTagsTableOrderingComposer,
          $$VaultTagsTableAnnotationComposer,
          $$VaultTagsTableCreateCompanionBuilder,
          $$VaultTagsTableUpdateCompanionBuilder,
          (
            VaultTagRow,
            BaseReferences<_$AppDatabase, $VaultTagsTable, VaultTagRow>,
          ),
          VaultTagRow,
          PrefetchHooks Function()
        > {
  $$VaultTagsTableTableManager(_$AppDatabase db, $VaultTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultTagsCompanion(id: id, name: name, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => VaultTagsCompanion.insert(id: id, name: name, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultTagsTable,
      VaultTagRow,
      $$VaultTagsTableFilterComposer,
      $$VaultTagsTableOrderingComposer,
      $$VaultTagsTableAnnotationComposer,
      $$VaultTagsTableCreateCompanionBuilder,
      $$VaultTagsTableUpdateCompanionBuilder,
      (
        VaultTagRow,
        BaseReferences<_$AppDatabase, $VaultTagsTable, VaultTagRow>,
      ),
      VaultTagRow,
      PrefetchHooks Function()
    >;
typedef $$VaultFileTagsTableCreateCompanionBuilder =
    VaultFileTagsCompanion Function({
      required String fileId,
      required String tagId,
      Value<int> rowid,
    });
typedef $$VaultFileTagsTableUpdateCompanionBuilder =
    VaultFileTagsCompanion Function({
      Value<String> fileId,
      Value<String> tagId,
      Value<int> rowid,
    });

class $$VaultFileTagsTableFilterComposer
    extends Composer<_$AppDatabase, $VaultFileTagsTable> {
  $$VaultFileTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultFileTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultFileTagsTable> {
  $$VaultFileTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultFileTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultFileTagsTable> {
  $$VaultFileTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$VaultFileTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultFileTagsTable,
          VaultFileTagRow,
          $$VaultFileTagsTableFilterComposer,
          $$VaultFileTagsTableOrderingComposer,
          $$VaultFileTagsTableAnnotationComposer,
          $$VaultFileTagsTableCreateCompanionBuilder,
          $$VaultFileTagsTableUpdateCompanionBuilder,
          (
            VaultFileTagRow,
            BaseReferences<_$AppDatabase, $VaultFileTagsTable, VaultFileTagRow>,
          ),
          VaultFileTagRow,
          PrefetchHooks Function()
        > {
  $$VaultFileTagsTableTableManager(_$AppDatabase db, $VaultFileTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultFileTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultFileTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultFileTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fileId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultFileTagsCompanion(
                fileId: fileId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => VaultFileTagsCompanion.insert(
                fileId: fileId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultFileTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultFileTagsTable,
      VaultFileTagRow,
      $$VaultFileTagsTableFilterComposer,
      $$VaultFileTagsTableOrderingComposer,
      $$VaultFileTagsTableAnnotationComposer,
      $$VaultFileTagsTableCreateCompanionBuilder,
      $$VaultFileTagsTableUpdateCompanionBuilder,
      (
        VaultFileTagRow,
        BaseReferences<_$AppDatabase, $VaultFileTagsTable, VaultFileTagRow>,
      ),
      VaultFileTagRow,
      PrefetchHooks Function()
    >;
typedef $$VaultCollectionsTableCreateCompanionBuilder =
    VaultCollectionsCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$VaultCollectionsTableUpdateCompanionBuilder =
    VaultCollectionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$VaultCollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $VaultCollectionsTable> {
  $$VaultCollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultCollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultCollectionsTable> {
  $$VaultCollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultCollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultCollectionsTable> {
  $$VaultCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$VaultCollectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultCollectionsTable,
          VaultCollectionRow,
          $$VaultCollectionsTableFilterComposer,
          $$VaultCollectionsTableOrderingComposer,
          $$VaultCollectionsTableAnnotationComposer,
          $$VaultCollectionsTableCreateCompanionBuilder,
          $$VaultCollectionsTableUpdateCompanionBuilder,
          (
            VaultCollectionRow,
            BaseReferences<
              _$AppDatabase,
              $VaultCollectionsTable,
              VaultCollectionRow
            >,
          ),
          VaultCollectionRow,
          PrefetchHooks Function()
        > {
  $$VaultCollectionsTableTableManager(
    _$AppDatabase db,
    $VaultCollectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultCollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultCollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultCollectionsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => VaultCollectionsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultCollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultCollectionsTable,
      VaultCollectionRow,
      $$VaultCollectionsTableFilterComposer,
      $$VaultCollectionsTableOrderingComposer,
      $$VaultCollectionsTableAnnotationComposer,
      $$VaultCollectionsTableCreateCompanionBuilder,
      $$VaultCollectionsTableUpdateCompanionBuilder,
      (
        VaultCollectionRow,
        BaseReferences<
          _$AppDatabase,
          $VaultCollectionsTable,
          VaultCollectionRow
        >,
      ),
      VaultCollectionRow,
      PrefetchHooks Function()
    >;
typedef $$VaultCollectionFilesTableCreateCompanionBuilder =
    VaultCollectionFilesCompanion Function({
      required String collectionId,
      required String fileId,
      Value<int> rowid,
    });
typedef $$VaultCollectionFilesTableUpdateCompanionBuilder =
    VaultCollectionFilesCompanion Function({
      Value<String> collectionId,
      Value<String> fileId,
      Value<int> rowid,
    });

class $$VaultCollectionFilesTableFilterComposer
    extends Composer<_$AppDatabase, $VaultCollectionFilesTable> {
  $$VaultCollectionFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultCollectionFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultCollectionFilesTable> {
  $$VaultCollectionFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultCollectionFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultCollectionFilesTable> {
  $$VaultCollectionFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);
}

class $$VaultCollectionFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultCollectionFilesTable,
          VaultCollectionFileRow,
          $$VaultCollectionFilesTableFilterComposer,
          $$VaultCollectionFilesTableOrderingComposer,
          $$VaultCollectionFilesTableAnnotationComposer,
          $$VaultCollectionFilesTableCreateCompanionBuilder,
          $$VaultCollectionFilesTableUpdateCompanionBuilder,
          (
            VaultCollectionFileRow,
            BaseReferences<
              _$AppDatabase,
              $VaultCollectionFilesTable,
              VaultCollectionFileRow
            >,
          ),
          VaultCollectionFileRow,
          PrefetchHooks Function()
        > {
  $$VaultCollectionFilesTableTableManager(
    _$AppDatabase db,
    $VaultCollectionFilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultCollectionFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultCollectionFilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$VaultCollectionFilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> collectionId = const Value.absent(),
                Value<String> fileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultCollectionFilesCompanion(
                collectionId: collectionId,
                fileId: fileId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collectionId,
                required String fileId,
                Value<int> rowid = const Value.absent(),
              }) => VaultCollectionFilesCompanion.insert(
                collectionId: collectionId,
                fileId: fileId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultCollectionFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultCollectionFilesTable,
      VaultCollectionFileRow,
      $$VaultCollectionFilesTableFilterComposer,
      $$VaultCollectionFilesTableOrderingComposer,
      $$VaultCollectionFilesTableAnnotationComposer,
      $$VaultCollectionFilesTableCreateCompanionBuilder,
      $$VaultCollectionFilesTableUpdateCompanionBuilder,
      (
        VaultCollectionFileRow,
        BaseReferences<
          _$AppDatabase,
          $VaultCollectionFilesTable,
          VaultCollectionFileRow
        >,
      ),
      VaultCollectionFileRow,
      PrefetchHooks Function()
    >;
typedef $$VaultSmartAlbumsTableCreateCompanionBuilder =
    VaultSmartAlbumsCompanion Function({
      required String id,
      required String name,
      Value<String?> categoryFilter,
      Value<bool> favoritesOnly,
      Value<String?> tagId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$VaultSmartAlbumsTableUpdateCompanionBuilder =
    VaultSmartAlbumsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> categoryFilter,
      Value<bool> favoritesOnly,
      Value<String?> tagId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$VaultSmartAlbumsTableFilterComposer
    extends Composer<_$AppDatabase, $VaultSmartAlbumsTable> {
  $$VaultSmartAlbumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryFilter => $composableBuilder(
    column: $table.categoryFilter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favoritesOnly => $composableBuilder(
    column: $table.favoritesOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultSmartAlbumsTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultSmartAlbumsTable> {
  $$VaultSmartAlbumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryFilter => $composableBuilder(
    column: $table.categoryFilter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favoritesOnly => $composableBuilder(
    column: $table.favoritesOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultSmartAlbumsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultSmartAlbumsTable> {
  $$VaultSmartAlbumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get categoryFilter => $composableBuilder(
    column: $table.categoryFilter,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get favoritesOnly => $composableBuilder(
    column: $table.favoritesOnly,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$VaultSmartAlbumsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultSmartAlbumsTable,
          VaultSmartAlbumRow,
          $$VaultSmartAlbumsTableFilterComposer,
          $$VaultSmartAlbumsTableOrderingComposer,
          $$VaultSmartAlbumsTableAnnotationComposer,
          $$VaultSmartAlbumsTableCreateCompanionBuilder,
          $$VaultSmartAlbumsTableUpdateCompanionBuilder,
          (
            VaultSmartAlbumRow,
            BaseReferences<
              _$AppDatabase,
              $VaultSmartAlbumsTable,
              VaultSmartAlbumRow
            >,
          ),
          VaultSmartAlbumRow,
          PrefetchHooks Function()
        > {
  $$VaultSmartAlbumsTableTableManager(
    _$AppDatabase db,
    $VaultSmartAlbumsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultSmartAlbumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultSmartAlbumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultSmartAlbumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> categoryFilter = const Value.absent(),
                Value<bool> favoritesOnly = const Value.absent(),
                Value<String?> tagId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultSmartAlbumsCompanion(
                id: id,
                name: name,
                categoryFilter: categoryFilter,
                favoritesOnly: favoritesOnly,
                tagId: tagId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> categoryFilter = const Value.absent(),
                Value<bool> favoritesOnly = const Value.absent(),
                Value<String?> tagId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => VaultSmartAlbumsCompanion.insert(
                id: id,
                name: name,
                categoryFilter: categoryFilter,
                favoritesOnly: favoritesOnly,
                tagId: tagId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultSmartAlbumsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultSmartAlbumsTable,
      VaultSmartAlbumRow,
      $$VaultSmartAlbumsTableFilterComposer,
      $$VaultSmartAlbumsTableOrderingComposer,
      $$VaultSmartAlbumsTableAnnotationComposer,
      $$VaultSmartAlbumsTableCreateCompanionBuilder,
      $$VaultSmartAlbumsTableUpdateCompanionBuilder,
      (
        VaultSmartAlbumRow,
        BaseReferences<
          _$AppDatabase,
          $VaultSmartAlbumsTable,
          VaultSmartAlbumRow
        >,
      ),
      VaultSmartAlbumRow,
      PrefetchHooks Function()
    >;
typedef $$VaultSyncStatesTableCreateCompanionBuilder =
    VaultSyncStatesCompanion Function({
      required String localFileId,
      required String logicalId,
      Value<String?> latestVersionId,
      Value<String> knownVersionIdsJson,
      Value<String> vectorJson,
      Value<String?> lastPublishedRevisionId,
      Value<DateTime?> lastPublishedAt,
      Value<bool> isConflict,
      Value<int> rowid,
    });
typedef $$VaultSyncStatesTableUpdateCompanionBuilder =
    VaultSyncStatesCompanion Function({
      Value<String> localFileId,
      Value<String> logicalId,
      Value<String?> latestVersionId,
      Value<String> knownVersionIdsJson,
      Value<String> vectorJson,
      Value<String?> lastPublishedRevisionId,
      Value<DateTime?> lastPublishedAt,
      Value<bool> isConflict,
      Value<int> rowid,
    });

class $$VaultSyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $VaultSyncStatesTable> {
  $$VaultSyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localFileId => $composableBuilder(
    column: $table.localFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logicalId => $composableBuilder(
    column: $table.logicalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latestVersionId => $composableBuilder(
    column: $table.latestVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get knownVersionIdsJson => $composableBuilder(
    column: $table.knownVersionIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vectorJson => $composableBuilder(
    column: $table.vectorJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastPublishedRevisionId => $composableBuilder(
    column: $table.lastPublishedRevisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPublishedAt => $composableBuilder(
    column: $table.lastPublishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isConflict => $composableBuilder(
    column: $table.isConflict,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultSyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultSyncStatesTable> {
  $$VaultSyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localFileId => $composableBuilder(
    column: $table.localFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logicalId => $composableBuilder(
    column: $table.logicalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latestVersionId => $composableBuilder(
    column: $table.latestVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get knownVersionIdsJson => $composableBuilder(
    column: $table.knownVersionIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vectorJson => $composableBuilder(
    column: $table.vectorJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastPublishedRevisionId => $composableBuilder(
    column: $table.lastPublishedRevisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPublishedAt => $composableBuilder(
    column: $table.lastPublishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isConflict => $composableBuilder(
    column: $table.isConflict,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultSyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultSyncStatesTable> {
  $$VaultSyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localFileId => $composableBuilder(
    column: $table.localFileId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get logicalId =>
      $composableBuilder(column: $table.logicalId, builder: (column) => column);

  GeneratedColumn<String> get latestVersionId => $composableBuilder(
    column: $table.latestVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get knownVersionIdsJson => $composableBuilder(
    column: $table.knownVersionIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vectorJson => $composableBuilder(
    column: $table.vectorJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastPublishedRevisionId => $composableBuilder(
    column: $table.lastPublishedRevisionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPublishedAt => $composableBuilder(
    column: $table.lastPublishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isConflict => $composableBuilder(
    column: $table.isConflict,
    builder: (column) => column,
  );
}

class $$VaultSyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultSyncStatesTable,
          VaultSyncStateRow,
          $$VaultSyncStatesTableFilterComposer,
          $$VaultSyncStatesTableOrderingComposer,
          $$VaultSyncStatesTableAnnotationComposer,
          $$VaultSyncStatesTableCreateCompanionBuilder,
          $$VaultSyncStatesTableUpdateCompanionBuilder,
          (
            VaultSyncStateRow,
            BaseReferences<
              _$AppDatabase,
              $VaultSyncStatesTable,
              VaultSyncStateRow
            >,
          ),
          VaultSyncStateRow,
          PrefetchHooks Function()
        > {
  $$VaultSyncStatesTableTableManager(
    _$AppDatabase db,
    $VaultSyncStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultSyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultSyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultSyncStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localFileId = const Value.absent(),
                Value<String> logicalId = const Value.absent(),
                Value<String?> latestVersionId = const Value.absent(),
                Value<String> knownVersionIdsJson = const Value.absent(),
                Value<String> vectorJson = const Value.absent(),
                Value<String?> lastPublishedRevisionId = const Value.absent(),
                Value<DateTime?> lastPublishedAt = const Value.absent(),
                Value<bool> isConflict = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultSyncStatesCompanion(
                localFileId: localFileId,
                logicalId: logicalId,
                latestVersionId: latestVersionId,
                knownVersionIdsJson: knownVersionIdsJson,
                vectorJson: vectorJson,
                lastPublishedRevisionId: lastPublishedRevisionId,
                lastPublishedAt: lastPublishedAt,
                isConflict: isConflict,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localFileId,
                required String logicalId,
                Value<String?> latestVersionId = const Value.absent(),
                Value<String> knownVersionIdsJson = const Value.absent(),
                Value<String> vectorJson = const Value.absent(),
                Value<String?> lastPublishedRevisionId = const Value.absent(),
                Value<DateTime?> lastPublishedAt = const Value.absent(),
                Value<bool> isConflict = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultSyncStatesCompanion.insert(
                localFileId: localFileId,
                logicalId: logicalId,
                latestVersionId: latestVersionId,
                knownVersionIdsJson: knownVersionIdsJson,
                vectorJson: vectorJson,
                lastPublishedRevisionId: lastPublishedRevisionId,
                lastPublishedAt: lastPublishedAt,
                isConflict: isConflict,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultSyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultSyncStatesTable,
      VaultSyncStateRow,
      $$VaultSyncStatesTableFilterComposer,
      $$VaultSyncStatesTableOrderingComposer,
      $$VaultSyncStatesTableAnnotationComposer,
      $$VaultSyncStatesTableCreateCompanionBuilder,
      $$VaultSyncStatesTableUpdateCompanionBuilder,
      (
        VaultSyncStateRow,
        BaseReferences<_$AppDatabase, $VaultSyncStatesTable, VaultSyncStateRow>,
      ),
      VaultSyncStateRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VaultFilesTableTableManager get vaultFiles =>
      $$VaultFilesTableTableManager(_db, _db.vaultFiles);
  $$ActivityEventsTableTableManager get activityEvents =>
      $$ActivityEventsTableTableManager(_db, _db.activityEvents);
  $$VaultFoldersTableTableManager get vaultFolders =>
      $$VaultFoldersTableTableManager(_db, _db.vaultFolders);
  $$VaultTagsTableTableManager get vaultTags =>
      $$VaultTagsTableTableManager(_db, _db.vaultTags);
  $$VaultFileTagsTableTableManager get vaultFileTags =>
      $$VaultFileTagsTableTableManager(_db, _db.vaultFileTags);
  $$VaultCollectionsTableTableManager get vaultCollections =>
      $$VaultCollectionsTableTableManager(_db, _db.vaultCollections);
  $$VaultCollectionFilesTableTableManager get vaultCollectionFiles =>
      $$VaultCollectionFilesTableTableManager(_db, _db.vaultCollectionFiles);
  $$VaultSmartAlbumsTableTableManager get vaultSmartAlbums =>
      $$VaultSmartAlbumsTableTableManager(_db, _db.vaultSmartAlbums);
  $$VaultSyncStatesTableTableManager get vaultSyncStates =>
      $$VaultSyncStatesTableTableManager(_db, _db.vaultSyncStates);
}
