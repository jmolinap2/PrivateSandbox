import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/application/playback/playback_use_case.dart';
import 'package:mobile_flutter/application/providers.dart';
import 'package:mobile_flutter/domain/entities/file_category.dart';
import 'package:mobile_flutter/domain/entities/import_status.dart';
import 'package:mobile_flutter/domain/entities/vault_file.dart';
import 'package:mobile_flutter/domain/repositories/vault_repository.dart';
import 'package:mobile_flutter/infrastructure/encryption/key_manager.dart';
import 'package:mobile_flutter/infrastructure/platform/system_channel.dart';
import 'package:mobile_flutter/media_engine/abstractions/video_engine.dart';
import 'package:mobile_flutter/presentation/navigation/route_observers.dart';
import 'package:mobile_flutter/presentation/screens/viewer/video_player_screen.dart';

void main() {
  late _FakeVideoEngine engine;

  setUp(() {
    engine = _FakeVideoEngine();
  });

  Future<void> pumpPlayer(
    WidgetTester tester, {
    required Size size,
    List<VaultFile> queue = const [],
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final file = _videoFile('one');
    var engineCount = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playbackUseCaseProvider.overrideWithValue(_FakePlayback()),
          videoEngineFactoryProvider.overrideWithValue(
            () => engineCount++ == 0 ? engine : _FakeVideoEngine(),
          ),
          vaultRepositoryProvider.overrideWithValue(_FakeVaultRepository()),
          systemChannelProvider.overrideWithValue(_FakeSystemChannel()),
        ],
        child: MaterialApp(
          navigatorObservers: [vaultRouteObserver],
          home: VideoPlayerScreen(file: file, queue: queue),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('portrait player exposes playback and seek controls', (
    tester,
  ) async {
    await pumpPlayer(tester, size: const Size(390, 844));

    expect(find.byKey(const ValueKey('fake-video-surface')), findsOneWidget);
    expect(find.byTooltip('Retroceder 10 segundos'), findsOneWidget);
    expect(find.byTooltip('Adelantar 10 segundos'), findsOneWidget);
    expect(find.byTooltip('Pausar'), findsOneWidget);

    tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.forward_10))
        .onPressed!();
    await tester.pump();
    await tester.pump();
    expect(engine.seekTargets.last, const Duration(seconds: 10));

    tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.replay_10))
        .onPressed!();
    await tester.pump();
    await tester.pump();
    expect(engine.seekTargets.last, Duration.zero);
  });

  testWidgets(
    'landscape player keeps controls usable and exposes queue navigation',
    (tester) async {
      final first = _videoFile('one');
      final second = _videoFile('two');
      await pumpPlayer(
        tester,
        size: const Size(844, 390),
        queue: [first, second],
      );

      expect(find.byTooltip('Retroceder 10 segundos'), findsOneWidget);
      expect(find.byTooltip('Adelantar 10 segundos'), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);

      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.skip_next))
          .onPressed!();
      await tester.pump();
      await tester.pump();
      expect(find.text('two.mp4'), findsOneWidget);
    },
  );
}

VaultFile _videoFile(String id) => VaultFile(
  id: id,
  originalName: '$id.mp4',
  extension: 'mp4',
  mimeType: 'video/mp4',
  sizeBytes: 1024,
  originalPath: null,
  importedAt: DateTime(2026),
  fileModifiedAt: null,
  category: FileCategory.video,
  status: ImportStatus.completed,
  encryptedFileName: '$id.bin',
  fileSaltBase64: '',
  noncePrefixBase64: '',
  sha256Hash: '',
  originalDeleted: false,
);

class _FakePlayback extends PlaybackUseCase {
  _FakePlayback() : super(KeyManager());

  @override
  Future<File> decryptToTemp(VaultFile file) async => File('${file.id}.mp4');

  @override
  Future<void> cleanupTemp(File file) async {}
}

class _FakeVideoEngine extends ChangeNotifier implements VideoEngine {
  var _isPlaying = false;
  var _position = Duration.zero;
  final seekTargets = <Duration>[];

  @override
  VideoEngineValue get value => VideoEngineValue(
    isInitialized: true,
    isPlaying: _isPlaying,
    isCompleted: false,
    position: _position,
    duration: const Duration(minutes: 2),
    aspectRatio: 16 / 9,
  );

  @override
  Widget buildSurface() => const ColoredBox(
    key: ValueKey('fake-video-surface'),
    color: Colors.black,
  );

  @override
  Future<void> initialize(File file) async {}

  @override
  Future<void> pause() async {
    _isPlaying = false;
    notifyListeners();
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
    notifyListeners();
  }

  @override
  Future<void> seekTo(Duration position) async {
    _position = position;
    seekTargets.add(position);
    notifyListeners();
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {}

  @override
  Future<void> setVolume(double volume) async {}
}

class _FakeSystemChannel extends SystemChannel {
  @override
  Future<void> clearScreenBrightness() async {}

  @override
  Future<double> getScreenBrightness() async => 0.5;

  @override
  Future<void> setScreenBrightness(double level) async {}
}

class _FakeVaultRepository implements VaultRepository {
  @override
  Future<void> completeImport({
    required String id,
    required String sha256Hash,
    required bool originalDeleted,
  }) async {}
  @override
  Future<void> deleteFile(String id) async {}
  @override
  Future<VaultFile?> getById(String id) async => null;
  @override
  Future<List<VaultFile>> getInterruptedImports() async => const [];
  @override
  Future<bool> hasStoredFiles() async => false;
  @override
  Future<void> insertFile(VaultFile file) async {}
  @override
  Future<void> markImportVerified({
    required String id,
    required String sha256Hash,
  }) async {}
  @override
  Future<void> moveFileToFolder(String id, String? folderId) async {}
  @override
  Future<void> moveToTrash(String id) async {}
  @override
  Future<void> recordOpened(String id, {int? playbackPositionMs}) async {}
  @override
  Future<void> restoreFromTrash(String id) async {}
  @override
  Future<void> setFavorite(String id, bool isFavorite) async {}
  @override
  Future<void> setThumbnail(
    String id, {
    required String fileName,
    required String noncePrefixBase64,
  }) async {}
  @override
  Stream<List<VaultFile>> watchFiles() => const Stream.empty();
  @override
  Stream<List<VaultFile>> watchFilesInFolder(String? folderId) =>
      const Stream.empty();
  @override
  Stream<List<VaultFile>> watchTrashedFiles() => const Stream.empty();
}
