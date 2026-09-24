import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../player/player_controller.dart';
import 'artwork.dart';

/// The bar that sits above the bottom navigation while something is playing.
///
/// It carries a progress line as well as the controls: without it the only way
/// to tell where you are in a track is to open the full player.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final notifier = ref.read(playerControllerProvider.notifier);
    final song = playerState.currentSong;
    if (song == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.pushNamed('nowPlaying'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ProgressLine(
                position: playerState.position,
                duration: playerState.duration,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: <Widget>[
                    Hero(
                      tag: 'player_artwork_${song.videoId}',
                      child: Artwork(url: song.thumbnailUrl, size: 44),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
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
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (playerState.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    else ...<Widget>[
                      IconButton(
                        tooltip: 'Previous',
                        icon: const Icon(Icons.skip_previous_rounded),
                        onPressed: notifier.playPrevious,
                      ),
                      IconButton.filledTonal(
                        tooltip: playerState.isPlaying ? 'Pause' : 'Play',
                        icon: Icon(
                          playerState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        onPressed: notifier.togglePlayPause,
                      ),
                      IconButton(
                        tooltip: 'Next',
                        icon: const Icon(Icons.skip_next_rounded),
                        onPressed: playerState.hasNext
                            ? () => notifier.playNext()
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.position, required this.duration});

  final Duration position;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds;
    final value = total <= 0
        ? 0.0
        : (position.inMilliseconds / total).clamp(0.0, 1.0);

    return LinearProgressIndicator(
      value: value,
      minHeight: 2,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
