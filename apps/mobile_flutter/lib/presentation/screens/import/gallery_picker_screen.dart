import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';

import '../../../application/import/picked_file.dart';

/// The vault's own photos/videos grid, backed directly by `photo_manager`
/// (MediaStore) instead of Android's Photo Picker — the Photo Picker never
/// grants delete access to what it returns, which defeats "mover el
/// archivo a la bóveda". This one requires READ_MEDIA_IMAGES/VIDEO, but in
/// exchange the vault can reliably delete originals after import.
///
/// Presented like a real gallery: everything on the device (newest first),
/// grouped under date headers (Hoy / Ayer / fecha), with album browsing,
/// video durations, and an ordered multi-selection.
class GalleryPickerScreen extends StatefulWidget {
  const GalleryPickerScreen({super.key});

  @override
  State<GalleryPickerScreen> createState() => _GalleryPickerScreenState();
}

enum _TypeFilter { all, image, video }

/// A run of assets that share the same calendar day, rendered under one header.
class _Section {
  _Section({required this.dayKey, required this.label, required this.assets});

  final DateTime dayKey;
  final String label;
  final List<AssetEntity> assets;
}

class _GalleryPickerScreenState extends State<GalleryPickerScreen> {
  static const _pageSize = 120;
  static const _columns = 4;

  bool _loading = true;
  bool _permissionDenied = false;
  AssetPathEntity? _path;
  final List<AssetEntity> _assets = [];
  List<_Section> _sections = [];
  // Order-preserving so each selected tile can show its pick number.
  final List<String> _selected = [];
  final _scrollController = ScrollController();
  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool _preparing = false;
  _TypeFilter _filter = _TypeFilter.all;
  AssetPathEntity? _selectedAlbum;

  RequestType get _requestType => switch (_filter) {
        _TypeFilter.all => RequestType.common,
        _TypeFilter.image => RequestType.image,
        _TypeFilter.video => RequestType.video,
      };

  // Every real gallery app sorts newest-first; without this, the plugin
  // falls back to the MediaStore provider's natural (insertion/_id) order,
  // which is why the unsorted grid looked "wrong" compared to any other
  // gallery.
  FilterOptionGroup get _sortNewestFirst => FilterOptionGroup(
        orders: const [OrderOption(type: OrderOptionType.createDate, asc: false)],
      );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final state = await PhotoManager.requestPermissionExtend();
    // `.limited` (Android 14+ "select photos") still grants usable access —
    // only a hard denial should show the permission-needed screen.
    if (!state.hasAccess) {
      if (!mounted) return;
      setState(() {
        _permissionDenied = true;
        _loading = false;
      });
      return;
    }
    await _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _assets.clear();
      _sections = [];
      _page = 0;
      _hasMore = true;
    });
    final selectedAlbum = _selectedAlbum;
    AssetPathEntity? path;
    if (selectedAlbum != null) {
      path = selectedAlbum;
    } else {
      final paths = await PhotoManager.getAssetPathList(
        type: _requestType,
        onlyAll: true,
        filterOption: _sortNewestFirst,
      );
      path = paths.isEmpty ? null : paths.first;
    }
    if (path == null) {
      if (!mounted) return;
      setState(() {
        _path = null;
        _loading = false;
      });
      return;
    }
    _path = path;
    final assets = await _path!.getAssetListPaged(page: 0, size: _pageSize);
    if (!mounted) return;
    setState(() {
      _assets.addAll(assets);
      _rebuildSections();
      _hasMore = assets.length == _pageSize;
      _loading = false;
    });
  }

  void _setFilter(_TypeFilter filter) {
    if (filter == _filter) return;
    // Switching Todo/Fotos/Videos while inside a specific album could leave
    // a stale album entity queried under the old type — simplest to just
    // return to "all albums" of the new type instead.
    setState(() {
      _filter = filter;
      _selectedAlbum = null;
    });
    _loadFirstPage();
  }

  Future<void> _pickAlbum() async {
    final albums = await PhotoManager.getAssetPathList(
      type: _requestType,
      hasAll: false,
      filterOption: _sortNewestFirst,
    );
    if (!mounted) return;
    final chosen = await showModalBottomSheet<_AlbumChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AlbumGridSheet(albums: albums),
    );
    if (chosen == null) return;
    setState(() => _selectedAlbum = chosen.showAll ? null : chosen.album);
    _loadFirstPage();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _path == null) return;
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 600) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    _page++;
    final more = await _path!.getAssetListPaged(page: _page, size: _pageSize);
    if (!mounted) return;
    setState(() {
      _assets.addAll(more);
      _rebuildSections();
      _hasMore = more.length == _pageSize;
      _loadingMore = false;
    });
  }

  /// Buckets the (already newest-first) asset list into per-day sections.
  void _rebuildSections() {
    final sections = <_Section>[];
    for (final asset in _assets) {
      final date = asset.createDateTime;
      final key = DateTime(date.year, date.month, date.day);
      if (sections.isEmpty || sections.last.dayKey != key) {
        sections.add(_Section(dayKey: key, label: _sectionLabel(date), assets: [asset]));
      } else {
        sections.last.assets.add(asset);
      }
    }
    _sections = sections;
  }

  String _sectionLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (date.year == now.year) return DateFormat("d 'de' MMMM", 'es').format(date);
    return DateFormat("d 'de' MMMM 'de' y", 'es').format(date);
  }

  void _toggle(AssetEntity asset) {
    setState(() {
      if (!_selected.remove(asset.id)) _selected.add(asset.id);
    });
  }

  void _clearSelection() => setState(() => _selected.clear());

  Future<void> _confirm() async {
    setState(() => _preparing = true);
    final byId = {for (final a in _assets) a.id: a};
    // Import in the order the user picked them (skipping any id no longer
    // present); `?` drops nulls from the list.
    final selectedAssets = [
      for (final id in _selected) ?byId[id],
    ];

    final picked = <PickedFile>[];
    for (final asset in selectedAssets) {
      final file = await asset.file;
      if (file == null) continue;
      final title = await asset.titleAsync;
      picked.add(PickedFile(
        path: file.path,
        name: title.isNotEmpty ? title : p.basename(file.path),
        size: await file.length(),
        galleryAssetId: asset.id,
        galleryRelativePath: asset.relativePath,
      ));
    }

    if (!mounted) return;
    Navigator.of(context).pop(picked);
  }

  @override
  Widget build(BuildContext context) {
    final selecting = _selected.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        leading: selecting
            ? IconButton(icon: const Icon(Icons.close), tooltip: 'Quitar selección', onPressed: _clearSelection)
            : null,
        title: Text(
          selecting ? '${_selected.length} seleccionado(s)' : _selectedAlbum?.name ?? 'Galería',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_album_outlined),
            tooltip: 'Álbumes',
            onPressed: _pickAlbum,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<_TypeFilter>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: _TypeFilter.all, label: Text('Todo')),
                  ButtonSegment(value: _TypeFilter.image, label: Text('Fotos'), icon: Icon(Icons.photo_outlined)),
                  ButtonSegment(value: _TypeFilter.video, label: Text('Videos'), icon: Icon(Icons.videocam_outlined)),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => _setFilter(s.first),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_preparing)
            const ColoredBox(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: !selecting || _preparing
          ? null
          : FloatingActionButton.extended(
              onPressed: _confirm,
              icon: const Icon(Icons.lock_outline),
              label: Text('Importar (${_selected.length})'),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_library_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'La app necesita acceso a fotos y videos para mostrar la galería.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: PhotoManager.openSetting, child: const Text('Abrir ajustes')),
            ],
          ),
        ),
      );
    }
    if (_assets.isEmpty) {
      final message = switch (_filter) {
        _TypeFilter.all => 'No hay fotos ni videos en el dispositivo.',
        _TypeFilter.image => 'No hay fotos en el dispositivo.',
        _TypeFilter.video => 'No hay videos en el dispositivo.',
      };
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 44, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
    }

    final slivers = <Widget>[];
    for (final section in _sections) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
            child: Text(
              section.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final asset = section.assets[index];
                final order = _selected.indexOf(asset.id);
                return _AssetTile(
                  asset: asset,
                  selectionNumber: order < 0 ? null : order + 1,
                  onTap: () => _toggle(asset),
                );
              },
              childCount: section.assets.length,
            ),
          ),
        ),
      );
    }
    slivers.add(
      SliverToBoxAdapter(
        child: SizedBox(
          height: _loadingMore ? 64 : 24,
          child: _loadingMore ? const Center(child: CircularProgressIndicator()) : null,
        ),
      ),
    );

    return CustomScrollView(controller: _scrollController, slivers: slivers);
  }
}

/// One tile in the grid: thumbnail, video duration scrim, and the selected
/// state (dim + inset + rounded corners + pick-order badge).
class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.asset, required this.selectionNumber, required this.onTap});

  final AssetEntity asset;
  final int? selectionNumber;
  final VoidCallback onTap;

  String _durationLabel(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final selected = selectionNumber != null;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.all(selected ? 8 : 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(selected ? 10 : 0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: FutureBuilder<Uint8List?>(
                  future: asset.thumbnailDataWithSize(const ThumbnailSize.square(250)),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    );
                  },
                ),
              ),
              if (asset.type == AssetType.video)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          _durationLabel(asset.videoDuration),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              if (selected) ColoredBox(color: scheme.primary.withValues(alpha: 0.25)),
              Positioned(
                top: 6,
                right: 6,
                child: _SelectionBadge(number: selectionNumber),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.number});

  final int? number;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = number != null;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? scheme.primary : Colors.black26,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: selected
          ? Text(
              '$number',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }
}

class _AlbumChoice {
  const _AlbumChoice.all() : album = null, showAll = true;
  const _AlbumChoice.pick(this.album) : showAll = false;

  final AssetPathEntity? album;
  final bool showAll;
}

/// Lists every album/folder (`MediaStore` bucket) with a cover thumbnail, so
/// the user can browse the same way any other gallery app does, instead of
/// only the flat "everything mixed together" view.
class _AlbumGridSheet extends StatelessWidget {
  const _AlbumGridSheet({required this.albums});

  final List<AssetPathEntity> albums;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Álbumes', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: albums.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _AlbumTile(
                      title: 'Todos',
                      album: null,
                      onTap: () => Navigator.of(context).pop(const _AlbumChoice.all()),
                    );
                  }
                  final album = albums[index - 1];
                  return _AlbumTile(
                    title: album.name,
                    album: album,
                    onTap: () => Navigator.of(context).pop(_AlbumChoice.pick(album)),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({required this.title, required this.album, required this.onTap});

  final String title;
  final AssetPathEntity? album;
  final VoidCallback onTap;

  Future<Uint8List?> _cover() async {
    final source = album;
    if (source == null) return null;
    final assets = await source.getAssetListPaged(page: 0, size: 1);
    if (assets.isEmpty) return null;
    return assets.first.thumbnailDataWithSize(const ThumbnailSize.square(300));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final source = album;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: source == null
                    ? Center(child: Icon(Icons.photo_library_outlined, color: scheme.primary, size: 34))
                    : FutureBuilder<Uint8List?>(
                        future: _cover(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                              child: Icon(Icons.folder_outlined, color: scheme.outline, size: 34),
                            );
                          }
                          return Image.memory(snapshot.data!, fit: BoxFit.cover, width: double.infinity);
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (source != null)
            FutureBuilder<int>(
              future: source.assetCountAsync,
              builder: (context, snapshot) {
                final count = snapshot.data;
                return Text(
                  count == null ? '' : '$count',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
                );
              },
            ),
        ],
      ),
    );
  }
}
