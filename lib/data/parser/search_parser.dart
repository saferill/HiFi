import '../../domain/entities/song.dart';

List<Song> parseSearchResults(Map<String, dynamic> rawJson) {
  final songs = <Song>[];
  final seenVideoIds = <String>{};

  void addSong(Song song) {
    if (song.videoId.isNotEmpty &&
        song.title.isNotEmpty &&
        !seenVideoIds.contains(song.videoId)) {
      seenVideoIds.add(song.videoId);
      songs.add(song);
    }
  }

  try {
    final sections = (rawJson['contents']?['tabbedSearchResultsRenderer']?['tabs']
            as List?)?[0]?['tabRenderer']?['content']?['sectionListRenderer']
        ?['contents'] as List?;

    if (sections == null) return songs;

    for (final section in sections) {
      if (section is! Map<String, dynamic>) continue;

      // 1. Top result card (musicCardShelfRenderer)
      if (section.containsKey('musicCardShelfRenderer')) {
        final card = section['musicCardShelfRenderer'] as Map<String, dynamic>;
        final cardSong = _parseCardShelf(card);
        if (cardSong != null) {
          addSong(cardSong);
        }
      }

      // 2. Direct musicShelfRenderer
      if (section.containsKey('musicShelfRenderer')) {
        final shelf = section['musicShelfRenderer'] as Map<String, dynamic>;
        final items = shelf['contents'] as List?;
        if (items != null) {
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              final song = _parseListItem(item);
              if (song != null) addSong(song);
            }
          }
        }
      }

      // 3. itemSectionRenderer (may contain direct list items or nested musicShelfRenderer)
      if (section.containsKey('itemSectionRenderer')) {
        final itemSection = section['itemSectionRenderer'] as Map<String, dynamic>;
        final innerContents = itemSection['contents'] as List?;
        if (innerContents != null) {
          for (final inner in innerContents) {
            if (inner is! Map<String, dynamic>) continue;

            if (inner.containsKey('musicShelfRenderer')) {
              final shelf = inner['musicShelfRenderer'] as Map<String, dynamic>;
              final items = shelf['contents'] as List?;
              if (items != null) {
                for (final item in items) {
                  if (item is Map<String, dynamic>) {
                    final song = _parseListItem(item);
                    if (song != null) addSong(song);
                  }
                }
              }
            } else if (inner.containsKey('musicResponsiveListItemRenderer')) {
              final song = _parseListItem(inner);
              if (song != null) addSong(song);
            }
          }
        }
      }
    }
  } catch (_) {
    // Gracefully handle malformed responses without crashing
  }

  return songs;
}

Song? _parseCardShelf(Map<String, dynamic> card) {
  try {
    final titleRuns = card['title']?['runs'] as List?;
    final title = titleRuns?.isNotEmpty == true
        ? (titleRuns![0]['text'] as String? ?? '')
        : '';

    String videoId = '';
    if (titleRuns?.isNotEmpty == true) {
      videoId = titleRuns![0]['navigationEndpoint']?['watchEndpoint']?['videoId']
              as String? ??
          '';
    }
    if (videoId.isEmpty) {
      final buttons = card['buttons'] as List?;
      if (buttons != null) {
        for (final btn in buttons) {
          final cmd = btn['buttonRenderer']?['command'] ??
              btn['buttonRenderer']?['navigationEndpoint'];
          final id = cmd?['watchEndpoint']?['videoId'] as String?;
          if (id != null && id.isNotEmpty) {
            videoId = id;
            break;
          }
        }
      }
    }

    String artist = '';
    String? duration;
    final subtitleRuns = card['subtitle']?['runs'] as List?;
    if (subtitleRuns != null) {
      for (final run in subtitleRuns) {
        final text = (run['text'] as String? ?? '').trim();
        if (text.isEmpty ||
            text == '•' ||
            _isTypeBadge(text) ||
            _isAudienceOrViews(text)) {
          continue;
        }
        if (text.contains(':') && RegExp(r'^\d+:\d+').hasMatch(text)) {
          duration = text;
        } else if (artist.isEmpty) {
          artist = text;
        }
      }
    }

    final thumbnails = card['thumbnail']?['musicThumbnailRenderer']?['thumbnail']
        ?['thumbnails'] as List?;
    final thumbnailUrl = (thumbnails != null && thumbnails.isNotEmpty)
        ? (thumbnails.last['url'] as String? ?? '')
        : '';

    if (videoId.isNotEmpty && title.isNotEmpty) {
      return Song(
        videoId: videoId,
        title: title,
        artist: artist.isNotEmpty ? artist : 'Unknown Artist',
        thumbnailUrl: thumbnailUrl,
        duration: duration,
      );
    }
  } catch (_) {}
  return null;
}

Song? _parseListItem(Map<String, dynamic> item) {
  try {
    final renderer = item['musicResponsiveListItemRenderer'] as Map<String, dynamic>? ??
        (item.containsKey('flexColumns') ? item : null);

    if (renderer == null) return null;

    // 1. Extract videoId
    String videoId = renderer['playlistItemData']?['videoId'] as String? ?? '';

    if (videoId.isEmpty) {
      videoId = renderer['navigationEndpoint']?['watchEndpoint']?['videoId']
              as String? ??
          '';
    }

    if (videoId.isEmpty) {
      final overlay = renderer['overlay']?['musicItemThumbnailOverlayRenderer']
          ?['content']?['musicPlayButtonRenderer']?['playNavigationEndpoint']
          ?['watchEndpoint'];
      videoId = overlay?['videoId'] as String? ?? '';
    }

    if (videoId.isEmpty) {
      final doubleTap = renderer['doubleTapCommand']?['watchEndpoint']?['videoId']
          as String?;
      videoId = doubleTap ?? '';
    }

    // 2. Extract title & flexColumns info
    final flexColumns = renderer['flexColumns'] as List?;
    if (flexColumns == null || flexColumns.isEmpty) return null;

    String title = '';
    final titleRuns = flexColumns[0]?['musicResponsiveListItemFlexColumnRenderer']
        ?['text']?['runs'] as List?;
    if (titleRuns != null && titleRuns.isNotEmpty) {
      title = titleRuns[0]['text'] as String? ?? '';
      if (videoId.isEmpty) {
        videoId = titleRuns[0]['navigationEndpoint']?['watchEndpoint']?['videoId']
                as String? ??
            '';
      }
    }

    String artist = '';
    String? duration;

    for (var i = 1; i < flexColumns.length; i++) {
      final runs = flexColumns[i]?['musicResponsiveListItemFlexColumnRenderer']
          ?['text']?['runs'] as List?;
      if (runs == null) continue;

      for (final run in runs) {
        final text = (run['text'] as String? ?? '').trim();
        if (text.isEmpty || text == '•' || _isTypeBadge(text) || _isAudienceOrViews(text)) {
          continue;
        }

        if (text.contains(':') && RegExp(r'^\d+:\d+').hasMatch(text)) {
          duration = text;
        } else if (artist.isEmpty && !_isSeparator(text)) {
          artist = text;
        }
      }
    }

    // 3. Extract thumbnail
    final thumbnails = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']
        ?['thumbnails'] as List?;
    String thumbnailUrl = '';
    if (thumbnails != null && thumbnails.isNotEmpty) {
      thumbnailUrl = thumbnails.last['url'] as String? ?? '';
    }

    if (videoId.isNotEmpty && title.isNotEmpty) {
      return Song(
        videoId: videoId,
        title: title,
        artist: artist.isNotEmpty ? artist : 'Unknown Artist',
        thumbnailUrl: thumbnailUrl,
        duration: duration,
      );
    }
  } catch (_) {}
  return null;
}

bool _isTypeBadge(String text) {
  const badges = {
    'Song',
    'Video',
    'Album',
    'Single',
    'EP',
    'Playlist',
    'Artist',
    'Profile',
    'Episode',
    'Podcast',
  };
  return badges.contains(text);
}

bool _isAudienceOrViews(String text) {
  final lower = text.toLowerCase();
  return lower.endsWith('views') ||
      lower.endsWith('plays') ||
      lower.contains('monthly audience') ||
      lower.contains('subscribers') ||
      lower.contains('songs');
}

bool _isSeparator(String text) {
  return text == '•' || text == '&' || text == ',' || text == '/';
}
