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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    originalName,
    extension,
    mimeType,
    sizeBytes,
    originalPath,
    importedAt,
    fileModifiedAt,
    category,
    status,
    encryptedFileName,
    fileSaltBase64,
    noncePrefixBase64,
    sha256Hash,
    originalDeleted,
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
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      fileModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}file_modified_at'],
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
  final DateTime importedAt;
  final DateTime? fileModifiedAt;
  final String category;
  final String status;
  final String encryptedFileName;
  final String fileSaltBase64;
  final String noncePrefixBase64;
  final String sha256Hash;
  final bool originalDeleted;
  const VaultFileRow({
    required this.id,
    required this.originalName,
    required this.extension,
    required this.mimeType,
    required this.sizeBytes,
    this.originalPath,
    required this.importedAt,
    this.fileModifiedAt,
    required this.category,
    required this.status,
    required this.encryptedFileName,
    required this.fileSaltBase64,
    required this.noncePrefixBase64,
    required this.sha256Hash,
    required this.originalDeleted,
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
    map['imported_at'] = Variable<DateTime>(importedAt);
    if (!nullToAbsent || fileModifiedAt != null) {
      map['file_modified_at'] = Variable<DateTime>(fileModifiedAt);
    }
    map['category'] = Variable<String>(category);
    map['status'] = Variable<String>(status);
    map['encrypted_file_name'] = Variable<String>(encryptedFileName);
    map['file_salt_base64'] = Variable<String>(fileSaltBase64);
    map['nonce_prefix_base64'] = Variable<String>(noncePrefixBase64);
    map['sha256_hash'] = Variable<String>(sha256Hash);
    map['original_deleted'] = Variable<bool>(originalDeleted);
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
      importedAt: Value(importedAt),
      fileModifiedAt: fileModifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(fileModifiedAt),
      category: Value(category),
      status: Value(status),
      encryptedFileName: Value(encryptedFileName),
      fileSaltBase64: Value(fileSaltBase64),
      noncePrefixBase64: Value(noncePrefixBase64),
      sha256Hash: Value(sha256Hash),
      originalDeleted: Value(originalDeleted),
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
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      fileModifiedAt: serializer.fromJson<DateTime?>(json['fileModifiedAt']),
      category: serializer.fromJson<String>(json['category']),
      status: serializer.fromJson<String>(json['status']),
      encryptedFileName: serializer.fromJson<String>(json['encryptedFileName']),
      fileSaltBase64: serializer.fromJson<String>(json['fileSaltBase64']),
      noncePrefixBase64: serializer.fromJson<String>(json['noncePrefixBase64']),
      sha256Hash: serializer.fromJson<String>(json['sha256Hash']),
      originalDeleted: serializer.fromJson<bool>(json['originalDeleted']),
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
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'fileModifiedAt': serializer.toJson<DateTime?>(fileModifiedAt),
      'category': serializer.toJson<String>(category),
      'status': serializer.toJson<String>(status),
      'encryptedFileName': serializer.toJson<String>(encryptedFileName),
      'fileSaltBase64': serializer.toJson<String>(fileSaltBase64),
      'noncePrefixBase64': serializer.toJson<String>(noncePrefixBase64),
      'sha256Hash': serializer.toJson<String>(sha256Hash),
      'originalDeleted': serializer.toJson<bool>(originalDeleted),
    };
  }

  VaultFileRow copyWith({
    String? id,
    String? originalName,
    String? extension,
    String? mimeType,
    int? sizeBytes,
    Value<String?> originalPath = const Value.absent(),
    DateTime? importedAt,
    Value<DateTime?> fileModifiedAt = const Value.absent(),
    String? category,
    String? status,
    String? encryptedFileName,
    String? fileSaltBase64,
    String? noncePrefixBase64,
    String? sha256Hash,
    bool? originalDeleted,
  }) => VaultFileRow(
    id: id ?? this.id,
    originalName: originalName ?? this.originalName,
    extension: extension ?? this.extension,
    mimeType: mimeType ?? this.mimeType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    originalPath: originalPath.present ? originalPath.value : this.originalPath,
    importedAt: importedAt ?? this.importedAt,
    fileModifiedAt: fileModifiedAt.present
        ? fileModifiedAt.value
        : this.fileModifiedAt,
    category: category ?? this.category,
    status: status ?? this.status,
    encryptedFileName: encryptedFileName ?? this.encryptedFileName,
    fileSaltBase64: fileSaltBase64 ?? this.fileSaltBase64,
    noncePrefixBase64: noncePrefixBase64 ?? this.noncePrefixBase64,
    sha256Hash: sha256Hash ?? this.sha256Hash,
    originalDeleted: originalDeleted ?? this.originalDeleted,
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
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      fileModifiedAt: data.fileModifiedAt.present
          ? data.fileModifiedAt.value
          : this.fileModifiedAt,
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
          ..write('importedAt: $importedAt, ')
          ..write('fileModifiedAt: $fileModifiedAt, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('encryptedFileName: $encryptedFileName, ')
          ..write('fileSaltBase64: $fileSaltBase64, ')
          ..write('noncePrefixBase64: $noncePrefixBase64, ')
          ..write('sha256Hash: $sha256Hash, ')
          ..write('originalDeleted: $originalDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    originalName,
    extension,
    mimeType,
    sizeBytes,
    originalPath,
    importedAt,
    fileModifiedAt,
    category,
    status,
    encryptedFileName,
    fileSaltBase64,
    noncePrefixBase64,
    sha256Hash,
    originalDeleted,
  );
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
          other.importedAt == this.importedAt &&
          other.fileModifiedAt == this.fileModifiedAt &&
          other.category == this.category &&
          other.status == this.status &&
          other.encryptedFileName == this.encryptedFileName &&
          other.fileSaltBase64 == this.fileSaltBase64 &&
          other.noncePrefixBase64 == this.noncePrefixBase64 &&
          other.sha256Hash == this.sha256Hash &&
          other.originalDeleted == this.originalDeleted);
}

class VaultFilesCompanion extends UpdateCompanion<VaultFileRow> {
  final Value<String> id;
  final Value<String> originalName;
  final Value<String> extension;
  final Value<String> mimeType;
  final Value<int> sizeBytes;
  final Value<String?> originalPath;
  final Value<DateTime> importedAt;
  final Value<DateTime?> fileModifiedAt;
  final Value<String> category;
  final Value<String> status;
  final Value<String> encryptedFileName;
  final Value<String> fileSaltBase64;
  final Value<String> noncePrefixBase64;
  final Value<String> sha256Hash;
  final Value<bool> originalDeleted;
  final Value<int> rowid;
  const VaultFilesCompanion({
    this.id = const Value.absent(),
    this.originalName = const Value.absent(),
    this.extension = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.fileModifiedAt = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
    this.encryptedFileName = const Value.absent(),
    this.fileSaltBase64 = const Value.absent(),
    this.noncePrefixBase64 = const Value.absent(),
    this.sha256Hash = const Value.absent(),
    this.originalDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultFilesCompanion.insert({
    required String id,
    required String originalName,
    required String extension,
    required String mimeType,
    required int sizeBytes,
    this.originalPath = const Value.absent(),
    required DateTime importedAt,
    this.fileModifiedAt = const Value.absent(),
    required String category,
    required String status,
    required String encryptedFileName,
    required String fileSaltBase64,
    required String noncePrefixBase64,
    this.sha256Hash = const Value.absent(),
    this.originalDeleted = const Value.absent(),
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
    Expression<DateTime>? importedAt,
    Expression<DateTime>? fileModifiedAt,
    Expression<String>? category,
    Expression<String>? status,
    Expression<String>? encryptedFileName,
    Expression<String>? fileSaltBase64,
    Expression<String>? noncePrefixBase64,
    Expression<String>? sha256Hash,
    Expression<bool>? originalDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalName != null) 'original_name': originalName,
      if (extension != null) 'extension': extension,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (originalPath != null) 'original_path': originalPath,
      if (importedAt != null) 'imported_at': importedAt,
      if (fileModifiedAt != null) 'file_modified_at': fileModifiedAt,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (encryptedFileName != null) 'encrypted_file_name': encryptedFileName,
      if (fileSaltBase64 != null) 'file_salt_base64': fileSaltBase64,
      if (noncePrefixBase64 != null) 'nonce_prefix_base64': noncePrefixBase64,
      if (sha256Hash != null) 'sha256_hash': sha256Hash,
      if (originalDeleted != null) 'original_deleted': originalDeleted,
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
    Value<DateTime>? importedAt,
    Value<DateTime?>? fileModifiedAt,
    Value<String>? category,
    Value<String>? status,
    Value<String>? encryptedFileName,
    Value<String>? fileSaltBase64,
    Value<String>? noncePrefixBase64,
    Value<String>? sha256Hash,
    Value<bool>? originalDeleted,
    Value<int>? rowid,
  }) {
    return VaultFilesCompanion(
      id: id ?? this.id,
      originalName: originalName ?? this.originalName,
      extension: extension ?? this.extension,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      originalPath: originalPath ?? this.originalPath,
      importedAt: importedAt ?? this.importedAt,
      fileModifiedAt: fileModifiedAt ?? this.fileModifiedAt,
      category: category ?? this.category,
      status: status ?? this.status,
      encryptedFileName: encryptedFileName ?? this.encryptedFileName,
      fileSaltBase64: fileSaltBase64 ?? this.fileSaltBase64,
      noncePrefixBase64: noncePrefixBase64 ?? this.noncePrefixBase64,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      originalDeleted: originalDeleted ?? this.originalDeleted,
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
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (fileModifiedAt.present) {
      map['file_modified_at'] = Variable<DateTime>(fileModifiedAt.value);
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
          ..write('importedAt: $importedAt, ')
          ..write('fileModifiedAt: $fileModifiedAt, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('encryptedFileName: $encryptedFileName, ')
          ..write('fileSaltBase64: $fileSaltBase64, ')
          ..write('noncePrefixBase64: $noncePrefixBase64, ')
          ..write('sha256Hash: $sha256Hash, ')
          ..write('originalDeleted: $originalDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VaultFilesTable vaultFiles = $VaultFilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [vaultFiles];
}

typedef $$VaultFilesTableCreateCompanionBuilder =
    VaultFilesCompanion Function({
      required String id,
      required String originalName,
      required String extension,
      required String mimeType,
      required int sizeBytes,
      Value<String?> originalPath,
      required DateTime importedAt,
      Value<DateTime?> fileModifiedAt,
      required String category,
      required String status,
      required String encryptedFileName,
      required String fileSaltBase64,
      required String noncePrefixBase64,
      Value<String> sha256Hash,
      Value<bool> originalDeleted,
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
      Value<DateTime> importedAt,
      Value<DateTime?> fileModifiedAt,
      Value<String> category,
      Value<String> status,
      Value<String> encryptedFileName,
      Value<String> fileSaltBase64,
      Value<String> noncePrefixBase64,
      Value<String> sha256Hash,
      Value<bool> originalDeleted,
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

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fileModifiedAt => $composableBuilder(
    column: $table.fileModifiedAt,
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

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fileModifiedAt => $composableBuilder(
    column: $table.fileModifiedAt,
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

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fileModifiedAt => $composableBuilder(
    column: $table.fileModifiedAt,
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
                Value<DateTime> importedAt = const Value.absent(),
                Value<DateTime?> fileModifiedAt = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> encryptedFileName = const Value.absent(),
                Value<String> fileSaltBase64 = const Value.absent(),
                Value<String> noncePrefixBase64 = const Value.absent(),
                Value<String> sha256Hash = const Value.absent(),
                Value<bool> originalDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultFilesCompanion(
                id: id,
                originalName: originalName,
                extension: extension,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                originalPath: originalPath,
                importedAt: importedAt,
                fileModifiedAt: fileModifiedAt,
                category: category,
                status: status,
                encryptedFileName: encryptedFileName,
                fileSaltBase64: fileSaltBase64,
                noncePrefixBase64: noncePrefixBase64,
                sha256Hash: sha256Hash,
                originalDeleted: originalDeleted,
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
                required DateTime importedAt,
                Value<DateTime?> fileModifiedAt = const Value.absent(),
                required String category,
                required String status,
                required String encryptedFileName,
                required String fileSaltBase64,
                required String noncePrefixBase64,
                Value<String> sha256Hash = const Value.absent(),
                Value<bool> originalDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultFilesCompanion.insert(
                id: id,
                originalName: originalName,
                extension: extension,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                originalPath: originalPath,
                importedAt: importedAt,
                fileModifiedAt: fileModifiedAt,
                category: category,
                status: status,
                encryptedFileName: encryptedFileName,
                fileSaltBase64: fileSaltBase64,
                noncePrefixBase64: noncePrefixBase64,
                sha256Hash: sha256Hash,
                originalDeleted: originalDeleted,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VaultFilesTableTableManager get vaultFiles =>
      $$VaultFilesTableTableManager(_db, _db.vaultFiles);
}
