import 'package:flutter/material.dart';

/// Album art with a placeholder while loading and a fallback when the URL has
/// no image behind it.
///
/// Every list in this app shows artwork at a different size, so the sizes live
/// here instead of being repeated per call site.
class Artwork extends StatelessWidget {
  const Artwork({
    super.key,
    required this.url,
    this.size = 56,
    this.radius = 8,
    this.fallbackIconSize,
  });

  final String url;
  final double size;
  final double radius;
  final double? fallbackIconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: url.isEmpty
              ? _Fallback(
                  size: fallbackIconSize ?? size * 0.4,
                  color: colorScheme.onSurfaceVariant,
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _Fallback(
                    size: fallbackIconSize ?? size * 0.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.music_note_rounded, size: size, color: color);
  }
}

/// The accent bar drawn under a paused/playing track in a list.
class NowPlayingIndicator extends StatelessWidget {
  const NowPlayingIndicator({super.key, this.isPlaying = true});

  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Icon(
      isPlaying ? Icons.graphic_eq_rounded : Icons.pause_rounded,
      color: color,
      size: 20,
    );
  }
}


