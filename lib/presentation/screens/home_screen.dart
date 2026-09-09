import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/music_repository.dart';
import '../../domain/entities/song.dart';
import '../player/player_controller.dart';

class ActiveSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final activeSearchQueryProvider =
    NotifierProvider<ActiveSearchQueryNotifier, String>(ActiveSearchQueryNotifier.new);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      ref.read(activeSearchQueryProvider.notifier).setQuery(trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuery = ref.watch(activeSearchQueryProvider);
    final searchAsync = currentQuery.isEmpty
        ? null
        : ref.watch(searchSongsProvider(currentQuery));
    final playerState = ref.watch(playerControllerProvider);

    final theme = Theme.of(context);

    // Listen for player errors to show a snackbar
    ref.listen<PlayerState>(playerControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Container(
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: _onSearchSubmitted,
            decoration: InputDecoration(
              hintText: 'Search songs, artists, albums...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (text) {
              setState(() {});
            },
          ),
        ),
      ),
      body: currentQuery.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search for music on YouTube Music',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : searchAsync!.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load search results',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () {
                          ref.invalidate(searchSongsProvider(currentQuery));
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (songs) {
                if (songs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No songs found for "$currentQuery"',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: songs.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    final isCurrentSong = playerState.currentSong?.videoId == song.videoId;

                    return _SongListTile(
                      song: song,
                      isSelected: isCurrentSong,
                      onTap: () {
                        ref.read(playerControllerProvider.notifier).playSong(song);
                      },
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: playerState.currentSong != null
          ? _MiniPlayer(
              playerState: playerState,
              onTogglePlay: () {
                ref.read(playerControllerProvider.notifier).togglePlayPause();
              },
            )
          : null,
    );
  }
}

class _SongListTile extends StatelessWidget {
  final Song song;
  final bool isSelected;
  final VoidCallback onTap;

  const _SongListTile({
    required this.song,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 52,
          height: 52,
          color: theme.colorScheme.surfaceContainerHighest,
          child: song.thumbnailUrl.isNotEmpty
              ? Image.network(
                  song.thumbnailUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.music_note,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                )
              : Icon(
                  Icons.music_note,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        song.duration != null && song.duration!.isNotEmpty
            ? '${song.artist} • ${song.duration}'
            : song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.8)
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.graphic_eq_rounded,
              color: theme.colorScheme.primary,
            )
          : null,
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  final PlayerState playerState;
  final VoidCallback onTogglePlay;

  const _MiniPlayer({
    required this.playerState,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    final song = playerState.currentSong;
    if (song == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 44,
                height: 44,
                color: theme.colorScheme.surfaceContainerHighest,
                child: song.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        song.thumbnailUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.music_note),
                      )
                    : const Icon(Icons.music_note),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (playerState.isLoading)
              const SizedBox(
                width: 36,
                height: 36,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else
              IconButton.filledTonal(
                icon: Icon(
                  playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: onTogglePlay,
              ),
          ],
        ),
      ),
    );
  }
}
