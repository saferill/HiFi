import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/music_repository.dart';
import '../../domain/entities/browse.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/song.dart';
import '../player/player_controller.dart';
import '../widgets/artwork.dart';

/// A YouTube Music browse page — Home, Charts, a mood category or a
/// "more from this shelf" page. All of them are the same renderer tree, so one
/// screen serves them all; only the [browseId] differs.
class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({
    super.key,
    this.browseId = BrowseIds.home,
    this.params,
    this.countryCode,
    this.title,
  });

  final String browseId;
  final String? params;
  final String? countryCode;

  /// Falls back to the title YouTube returns for the page.
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = BrowseRequest(
      browseId: browseId,
      params: params,
      countryCode: countryCode,
    );
    final pageAsync = ref.watch(browsePageProvider(request));

    return pageAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _BrowseError(
        error: error,
        onRetry: () => ref.invalidate(browsePageProvider(request)),
      ),
      data: (page) {
        if (page.sections.isEmpty) {
          return const _EmptyBrowse();
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(browsePageProvider(request)),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: page.sections.length,
            itemBuilder: (context, index) => _Section(
              section: page.sections[index],
              onPlaySong: (songs, startIndex) => ref
                  .read(playerControllerProvider.notifier)
                  .playQueue(songs, startIndex),
            ),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.section, required this.onPlaySong});

  final BrowseSection section;

  /// Starts the shelf as a queue at the tapped track.
  final void Function(List<Song> queue, int startIndex) onPlaySong;

  @override
  Widget build(BuildContext context) {
    if (section.moods.isNotEmpty) {
      return _MoodGrid(moods: section.moods, title: section.title);
    }

    final songs = section.songs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (section.title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              section.title!,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: <Widget>[
              for (var i = 0; i < songs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _SongCard(
                    song: songs[i],
                    onTap: () => onPlaySong(songs, i),
                  ),
                ),
              for (final album in section.albums)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _AlbumCard(album: album),
                ),
              for (final playlist in section.playlists)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _PlaylistCard(playlist: playlist),
                ),
              for (final artist in section.artists)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _ArtistCard(artist: artist),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoodGrid extends StatelessWidget {
  const _MoodGrid({required this.moods, this.title});

  final List<MoodGenre> moods;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[for (final mood in moods) _MoodChip(mood: mood)],
          ),
        ),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.mood});

  final MoodGenre mood;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // YouTube sends the left stripe colour as a packed ARGB value.
    final stripe = mood.stripeColor == null
        ? colorScheme.primary
        : Color(mood.stripeColor!);

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          'browse',
          pathParameters: <String, String>{'browseId': mood.browseId},
          queryParameters: <String, String>{'params': mood.params},
        ),
        child: SizedBox(
          width: 150,
          height: 56,
          child: Row(
            children: <Widget>[
              Container(width: 6, height: double.infinity, color: stripe),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    mood.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongCard extends ConsumerWidget {
  const _SongCard({required this.song, required this.onTap});

  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = ref.watch(
      playerControllerProvider.select(
        (s) => s.currentSong?.videoId == song.videoId,
      ),
    );

    return _Card(
      title: song.title,
      subtitle: song.artist,
      imageUrl: song.thumbnailUrl,
      isHighlighted: isCurrent,
      onTap: onTap,
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album});

  final AlbumItem album;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: album.title,
      subtitle: album.artistLabel,
      imageUrl: album.thumbnailUrl,
      onTap: () => context.pushNamed(
        'album',
        pathParameters: <String, String>{'browseId': album.browseId},
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist});

  final PlaylistItem playlist;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: playlist.title,
      subtitle: playlist.author?.name ?? 'Playlist',
      imageUrl: playlist.thumbnailUrl,
      onTap: () => context.pushNamed(
        'album',
        pathParameters: <String, String>{'browseId': playlist.id},
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({required this.artist});

  final ArtistItem artist;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: artist.title,
      subtitle: artist.subscribers ?? 'Artist',
      imageUrl: artist.thumbnailUrl,
      circular: true,
      onTap: () => context.pushNamed(
        'browse',
        pathParameters: <String, String>{'browseId': artist.id},
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
    this.circular = false,
    this.isHighlighted = false,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;
  final bool circular;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 140,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Artwork(url: imageUrl, size: 140, radius: circular ? 70 : 12),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isHighlighted ? theme.colorScheme.primary : null,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseError extends StatelessWidget {
  const _BrowseError({required this.error, required this.onRetry});

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
              'Could not load this page',
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

class _EmptyBrowse extends StatelessWidget {
  const _EmptyBrowse();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.album_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing to show here',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
