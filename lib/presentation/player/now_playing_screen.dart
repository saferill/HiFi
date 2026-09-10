import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'player_controller.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  double? _dragValue;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final playerNotifier = ref.read(playerControllerProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final song = playerState.currentSong;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('Tidak ada lagu yang sedang diputar'),
        ),
      );
    }

    final totalSeconds = playerState.duration.inMilliseconds / 1000.0;
    final currentSeconds = playerState.position.inMilliseconds / 1000.0;
    final maxSlider = totalSeconds > 0 ? totalSeconds : 1.0;
    final currentSlider = _dragValue ?? (currentSeconds.clamp(0.0, maxSlider));

    final hasPrevious = playerState.currentIndex > 0;
    final hasNext =
        (playerState.currentIndex + 1 < playerState.queue.length) ||
        playerState.isRadioEnabled;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Column(
          children: [
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
                children: [
                  Text(
                    'Track ${playerState.currentIndex + 1} of ${playerState.queue.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (playerState.isRadioEnabled) ...[
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              const Spacer(),
              // Large Thumbnail with Hero transition
              Center(
                child: Hero(
                  tag: 'player_artwork_${song.videoId}',
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.78,
                    height: MediaQuery.of(context).size.width * 0.78,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.2),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: song.thumbnailUrl.isNotEmpty
                          ? Image.network(
                              song.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.music_note_rounded,
                                  size: 80,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.music_note_rounded,
                                size: 80,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Song Info
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      song.artist,
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
              // Seekbar Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.surfaceContainerHighest,
                  thumbColor: colorScheme.primary,
                ),
                child: Slider(
                  value: currentSlider.clamp(0.0, maxSlider),
                  min: 0.0,
                  max: maxSlider,
                  onChanged: (val) {
                    setState(() {
                      _dragValue = val;
                    });
                  },
                  onChangeEnd: (val) {
                    playerNotifier
                        .seek(Duration(milliseconds: (val * 1000).round()));
                    setState(() {
                      _dragValue = null;
                    });
                  },
                ),
              ),
              // Time row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(
                        _dragValue != null
                            ? Duration(
                                milliseconds: (_dragValue! * 1000).round())
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
              // Controls row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shuffle Button
                  IconButton(
                    iconSize: 26,
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: playerState.isShuffleEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    tooltip: playerState.isShuffleEnabled
                        ? 'Shuffle Aktif'
                        : 'Acak Antrean',
                    onPressed: playerNotifier.toggleShuffle,
                  ),
                  // Previous Button
                  IconButton(
                    iconSize: 38,
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      color: hasPrevious
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    onPressed: hasPrevious ? playerNotifier.playPrevious : null,
                  ),
                  // Play/Pause Button
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: playerState.isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : IconButton(
                            iconSize: 36,
                            icon: Icon(
                              playerState.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: colorScheme.onPrimary,
                            ),
                            onPressed: playerNotifier.togglePlayPause,
                          ),
                  ),
                  // Next Button
                  IconButton(
                    iconSize: 38,
                    icon: Icon(
                      Icons.skip_next_rounded,
                      color: hasNext
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    onPressed: hasNext ? playerNotifier.playNext : null,
                  ),
                  // Infinite Autoplay / Radio Mode Toggle
                  IconButton(
                    iconSize: 26,
                    icon: Icon(
                      Icons.all_inclusive_rounded,
                      color: playerState.isRadioEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    tooltip: playerState.isRadioEnabled
                        ? 'Autoplay Radio Aktif'
                        : 'Autoplay Radio Mati',
                    onPressed: playerNotifier.toggleRadioMode,
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
}
