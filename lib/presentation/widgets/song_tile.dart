import 'package:flutter/material.dart';

import '../../domain/entities/song.dart';
import 'artwork.dart';

/// One track row, shared by search results, album pages and browse shelves.
///
/// The subtitle is assembled from whatever the response actually carried —
/// duration, album credit and an explicit marker are all optional — instead of
/// assuming every row has the same shape.
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.isSelected = false,
    this.isPlaying = false,
    this.trailing,
    this.showAlbum = true,
  });

  final Song song;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isPlaying;
  final Widget? trailing;
  final bool showAlbum;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.25),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Artwork(url: song.thumbnailUrl, size: 52),
      title: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? colorScheme.primary : null,
              ),
            ),
          ),
          if (song.isExplicit) ...<Widget>[
            const SizedBox(width: 6),
            _ExplicitLabel(color: colorScheme.onSurfaceVariant),
          ],
        ],
      ),
      subtitle: Text(
        _subtitle(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.8)
              : colorScheme.onSurfaceVariant,
        ),
      ),
      trailing:
          trailing ??
          (isSelected ? NowPlayingIndicator(isPlaying: isPlaying) : null),
    );
  }

  String _subtitle() {
    final parts = <String>[
      song.artist,
      if (showAlbum && song.album != null) song.album!.name,
      if (song.duration != null && song.duration!.isNotEmpty) song.duration!,
    ];
    return parts.join(' • ');
  }
}

class _ExplicitLabel extends StatelessWidget {
  const _ExplicitLabel({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        'E',
        style: TextStyle(
          fontSize: 9,
          height: 1.1,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
