import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/parser/album_parser.dart';
import '../../data/repositories/music_repository.dart';
import '../../domain/entities/song.dart';
import '../player/player_controller.dart';
import '../widgets/artwork.dart';
import '../widgets/song_tile.dart';

/// Track list behind an album or playlist card.
class AlbumScreen extends ConsumerWidget {
  const AlbumScreen({super.key, required this.browseId});

  final String browseId;

  /// The album name is only known once the response lands, so the bar falls
  /// back until then instead of holding a null.
  String _titleOf(AsyncValue<AlbumPageResult?> value) => value.when(
        data: (result) => result?.album.title ?? 'Album',
        loading: () => 'Album',
        error: (error, stack) => 'Album',
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumPageProvider(browseId));

    return Scaffold(
      appBar: AppBar(title: Text(_titleOf(albumAsync))),
      body: albumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _AlbumError(
          error: error,
          onRetry: () => ref.invalidate(albumPageProvider(browseId)),
        ),
        data: (result) {
          if (result == null || result.songs.isEmpty) {
            return const Center(child: Text('No tracks on this release'));
          }

          final songs = result.songs;
          return CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _AlbumHeader(
                  result: result,
                  onPlayAll: () => ref
                      .read(playerControllerProvider.notifier)
                      .playQueue(songs, 0),
                  onShuffle: () {
                    final notifier = ref.read(
                      playerControllerProvider.notifier,
                    );
                    final shuffled = List<Song>.of(songs)..shuffle();
                    notifier.playQueue(shuffled, 0);
                    if (!ref.read(playerControllerProvider).isShuffleEnabled) {
                      notifier.toggleShuffle();
                    }
                  },
                ),
              ),
              SliverList.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  final isCurrent = ref.watch(
                    playerControllerProvider.select(
                      (s) => s.currentSong?.videoId == song.videoId,
                    ),
                  );

                  return SongTile(
                    song: song,
                    showAlbum: false,
                    isSelected: isCurrent,
                    isPlaying: ref.watch(playerControllerProvider).isPlaying,
                    onTap: () => ref
                        .read(playerControllerProvider.notifier)
                        .playQueue(songs, index),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader({
    required this.result,
    required this.onPlayAll,
    required this.onShuffle,
  });

  final AlbumPageResult result;
  final VoidCallback onPlayAll;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final album = result.album;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Artwork(url: album.thumbnailUrl, size: 140, radius: 12),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      album.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      album.artistLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _metaLine(result),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              FilledButton.icon(
                onPressed: onPlayAll,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onShuffle,
                icon: const Icon(Icons.shuffle_rounded),
                label: const Text('Shuffle'),
              ),
            ],
          ),
          if (result.description != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              result.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _metaLine(AlbumPageResult result) {
    final parts = <String>[
      if (result.album.year != null) '${result.album.year}',
      if (result.album.isSingle) 'Single',
      '${result.songs.length} tracks',
    ];
    return parts.join(' • ');
  }
}

class _AlbumError extends StatelessWidget {
  const _AlbumError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load this release',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
