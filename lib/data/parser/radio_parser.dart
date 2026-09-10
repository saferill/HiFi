import '../../domain/entities/song.dart';

class RadioResult {
  final List<Song> songs;
  final String? continuationToken;

  const RadioResult({
    required this.songs,
    this.continuationToken,
  });
}

RadioResult parseRadioResponse(Map<String, dynamic> rawJson) {
  final songs = <Song>[];
  final seenVideoIds = <String>{};
  String? continuationToken;

  void addSong(Song song) {
    if (song.videoId.isNotEmpty &&
        song.title.isNotEmpty &&
        !seenVideoIds.contains(song.videoId)) {
      seenVideoIds.add(song.videoId);
      songs.add(song);
    }
  }

  try {
    // 1. Check for continuation response first
    final continuationContents =
        rawJson['continuationContents']?['playlistPanelContinuation'];
    if (continuationContents != null &&
        continuationContents is Map<String, dynamic>) {
      final items = continuationContents['contents'] as List?;
      if (items != null) {
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            final song = _parsePlaylistPanelVideoItem(item);
            if (song != null) addSong(song);
          }
        }
      }
      continuationToken = _extractContinuationToken(continuationContents);
      return RadioResult(songs: songs, continuationToken: continuationToken);
    }

    // 2. Initial watch next response
    final contents = rawJson['contents']
        ?['singleColumnMusicWatchNextResultsRenderer']?['tabbedRenderer']
        ?['watchNextTabbedResultsRenderer']?['tabs'] as List?;

    if (contents != null && contents.isNotEmpty) {
      for (final tab in contents) {
        if (tab is! Map<String, dynamic>) continue;
        final tabRenderer = tab['tabRenderer'] as Map<String, dynamic>?;
        final musicQueue = tabRenderer?['content']?['musicQueueRenderer']
            as Map<String, dynamic>?;
        final playlistPanel = musicQueue?['content']?['playlistPanelRenderer']
            as Map<String, dynamic>?;

        if (playlistPanel != null) {
          final items = playlistPanel['contents'] as List?;
          if (items != null) {
            for (final item in items) {
              if (item is Map<String, dynamic>) {
                final song = _parsePlaylistPanelVideoItem(item);
                if (song != null) addSong(song);
              }
            }
          }
          continuationToken = _extractContinuationToken(playlistPanel);
          break;
        }
      }
    }
  } catch (_) {
    // Fallback if schema changes
  }

  return RadioResult(songs: songs, continuationToken: continuationToken);
}

Song? _parsePlaylistPanelVideoItem(Map<String, dynamic> item) {
  try {
    final videoRenderer =
        item['playlistPanelVideoRenderer'] as Map<String, dynamic>?;
    if (videoRenderer == null) return null;

    final videoId = videoRenderer['videoId'] as String? ?? '';
    if (videoId.isEmpty) return null;

    final titleRuns = videoRenderer['title']?['runs'] as List?;
    String title = 'Unknown Title';
    if (titleRuns != null && titleRuns.isNotEmpty) {
      title = titleRuns[0]?['text'] as String? ?? 'Unknown Title';
    }

    final bylineRuns = (videoRenderer['longBylineText']?['runs'] ??
        videoRenderer['shortBylineText']?['runs']) as List?;
    String artist = 'Unknown Artist';
    if (bylineRuns != null && bylineRuns.isNotEmpty) {
      artist = bylineRuns[0]?['text'] as String? ?? 'Unknown Artist';
    }

    final duration =
        videoRenderer['lengthText']?['runs']?[0]?['text'] as String?;

    String thumbnailUrl = '';
    final thumbnails = videoRenderer['thumbnail']?['thumbnails'] as List?;
    if (thumbnails != null && thumbnails.isNotEmpty) {
      final lastThumb = thumbnails.last as Map<String, dynamic>?;
      thumbnailUrl = lastThumb?['url'] as String? ?? '';
    }

    return Song(
      videoId: videoId,
      title: title,
      artist: artist,
      duration: duration,
      thumbnailUrl: thumbnailUrl,
    );
  } catch (_) {
    return null;
  }
}

String? _extractContinuationToken(Map<String, dynamic> panel) {
  try {
    final continuations = panel['continuations'] as List?;
    if (continuations != null && continuations.isNotEmpty) {
      final first = continuations[0] as Map<String, dynamic>?;
      final nextContinuation = first?['nextRadioContinuationData'] ??
          first?['nextContinuationData'];
      if (nextContinuation is Map<String, dynamic>) {
        return nextContinuation['continuation'] as String?;
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}
