import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/song.dart';
import '../widgets/artwork.dart';
import 'player_controller.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  /// Non-null while the user is dragging the seek bar, so the thumb follows the
  /// finger instead of snapping back to the reported position.
  double? _dragValue;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final notifier = ref.read(playerControllerProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final song = playerState.currentSong;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Tidak ada lagu yang sedang diputar')),
      );
    }

    final totalSeconds = playerState.duration.inMilliseconds / 1000.0;
    final currentSeconds = playerState.position.inMilliseconds / 1000.0;
    final maxSlider = totalSeconds > 0 ? totalSeconds : 1.0;
    final currentSlider = _dragValue ?? currentSeconds.clamp(0.0, maxSlider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Column(
          children: <Widget>[
            Text(
              playerState.isRadioEnabled
                  ? 'PLAYING FROM INFINITE RADIO'
                  : 'PLAYING FROM QUEUE',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (playerState.queue.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Track ${playerState.currentIndex + 1} of '
                    '${playerState.queue.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (playerState.isRadioEnabled) ...<Widget>[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.all_inclusive_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                  ],
                ],
              ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: playerState.isRadioEnabled
                ? 'Autoplay radio on'
                : 'Autoplay radio off',
            icon: Icon(
              Icons.all_inclusive_rounded,
              color: playerState.isRadioEnabled
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.38),
            ),
            onPressed: notifier.toggleRadioMode,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: <Widget>[
              const Spacer(),
              Center(
                child: Hero(
                  tag: 'player_artwork_${song.videoId}',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.2),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Artwork(
                      url: song.thumbnailUrl,
                      size: MediaQuery.of(context).size.width * 0.78,
                      radius: 24,
                      fallbackIconSize: 80,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _artistLine(song),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.surfaceContainerHighest,
                  thumbColor: colorScheme.primary,
                ),
                child: Slider(
                  value: currentSlider.clamp(0.0, maxSlider),
                  max: maxSlider,
                  onChanged: (val) => setState(() => _dragValue = val),
                  onChangeEnd: (val) {
                    notifier.seek(
                      Duration(milliseconds: (val * 1000).round()),
                    );
                    setState(() => _dragValue = null);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      _formatDuration(
                        _dragValue != null
                            ? Duration(
                                milliseconds: (_dragValue! * 1000).round(),
                              )
                            : playerState.position,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDuration(playerState.duration),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                    iconSize: 26,
                    tooltip: playerState.isShuffleEnabled
                        ? 'Shuffle on'
                        : 'Shuffle queue',
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: playerState.isShuffleEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    onPressed: notifier.toggleShuffle,
                  ),
                  IconButton(
                    iconSize: 38,
                    tooltip: 'Previous',
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      color: playerState.hasPrevious
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    onPressed:
                        playerState.hasPrevious ? notifier.playPrevious : null,
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: playerState.isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : IconButton(
                            iconSize: 36,
                            tooltip: playerState.isPlaying ? 'Pause' : 'Play',
                            icon: Icon(
                              playerState.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: colorScheme.onPrimary,
                            ),
                            onPressed: notifier.togglePlayPause,
                          ),
                  ),
                  IconButton(
                    iconSize: 38,
                    tooltip: 'Next',
                    icon: Icon(
                      Icons.skip_next_rounded,
                      color: playerState.hasNext
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    onPressed:
                        playerState.hasNext ? () => notifier.playNext() : null,
                  ),
                  IconButton(
                    iconSize: 26,
                    tooltip: playerState.repeatMode.label,
                    icon: Icon(
                      _repeatIcon(playerState.repeatMode),
                      color: playerState.repeatMode == PlaybackRepeat.off
                          ? colorScheme.onSurface.withValues(alpha: 0.38)
                          : colorScheme.primary,
                    ),
                    onPressed: notifier.cycleRepeatMode,
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  String _artistLine(Song song) {
    final album = song.album?.name;
    if (album == null || album.isEmpty) return song.artist;
    return '${song.artist} • $album';
  }

  IconData _repeatIcon(PlaybackRepeat mode) => switch (mode) {
        PlaybackRepeat.one => Icons.repeat_one_rounded,
        _ => Icons.repeat_rounded,
      };
}
