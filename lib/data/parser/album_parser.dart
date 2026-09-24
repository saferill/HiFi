import '../../domain/entities/media_item.dart';
import '../../domain/entities/song.dart';
import 'browse_parser.dart' show parseListSong;
import 'renderer_utils.dart';

/// Result of opening an album or playlist page.
class AlbumPageResult {
  const AlbumPageResult({
    required this.album,
    required this.songs,
    this.continuationToken,
    this.description,
  });

  final AlbumItem album;
  final List<Song> songs;

  /// Present when the track list is long enough for YouTube to page it.
  final String? continuationToken;
  final String? description;

  bool get isEmpty => songs.isEmpty;
}

/// Parses the `browse` response for an album (`MPREb…`) or playlist (`VL…`)
/// page. Ported from SimpMusic's `AlbumPage` / `PlaylistPage`.
AlbumPageResult? parseAlbumPage(Map<String, dynamic> rawJson) {
  try {
    final shelf = _findFirstShelf(rawJson, <String>[
      'musicPlaylistShelfRenderer',
      'musicShelfRenderer',
    ]);
    if (shelf == null) return null;

    final songs = <Song>[];
    for (final item in asList(shelf['contents']) ?? const <dynamic>[]) {
      final renderer = asMap(item)?['musicResponsiveListItemRenderer'];
      final song = parseListSong(asMap(renderer) ?? <String, dynamic>{});
      if (song != null) songs.add(song);
    }

    final header = _findHeader(rawJson);
    final title = runsToText(digValue(header, <String>['title', 'runs'])) ??
        runsToText(digValue(shelf, <String>['title', 'runs']));
    if (title == null) return null;

    final browseId = _headerBrowseId(rawJson) ?? '';
    final playlistId = shelf['playlistId'];
    final thumbnail = bestThumbnailUrl(
          dig(
            header,
            <String>['thumbnail', 'musicThumbnailRenderer', 'thumbnail'],
          ),
        ) ??
        (songs.isEmpty ? '' : songs.first.thumbnailUrl);

    final subtitleRuns = asList(digValue(header, <String>['subtitle', 'runs']));
    final artists = parseArtists(subtitleRuns);

    return AlbumPageResult(
      album: AlbumItem(
        browseId: browseId,
        playlistId: playlistId is String ? playlistId : null,
        title: title,
        artists: artists,
        year: _yearFromHeader(subtitleRuns),
        thumbnailUrl: thumbnail,
        isExplicit: hasExplicitBadge(header?['subtitleBadges']),
      ),
      songs: songs,
      continuationToken: _continuationToken(shelf),
      description: runsToText(
        digValue(header, <String>['description', 'runs']),
      ),
    );
  } catch (_) {
    return null;
  }
}

/// Depth-first search for the first map carrying [key].
///
/// Album and playlist responses nest the track shelf under either `tabs` or
/// `secondaryContents` depending on which client asked, so walking the tree is
/// more robust than pinning one path.
Map<String, dynamic>? _findFirstShelf(
  Object? node,
  List<String> keys, {
  int depth = 0,
}) {
  if (depth > 24) return null;

  if (node is Map<String, dynamic>) {
    for (final key in keys) {
      final match = asMap(node[key]);
      if (match != null && asList(match['contents']) != null) return match;
    }
    for (final value in node.values) {
      final found = _findFirstShelf(value, keys, depth: depth + 1);
      if (found != null) return found;
    }
    return null;
  }

  if (node is List) {
    for (final entry in node) {
      final found = _findFirstShelf(entry, keys, depth: depth + 1);
      if (found != null) return found;
    }
  }
  return null;
}

Map<String, dynamic>? _findHeader(Map<String, dynamic> rawJson) {
  const headerKeys = <String>[
    'musicDetailHeaderRenderer',
    'musicResponsiveHeaderRenderer',
    'musicImmersiveHeaderRenderer',
    'musicVisualHeaderRenderer',
  ];
  for (final key in headerKeys) {
    final header = asMap(rawJson['header']?[key]);
    if (header != null) return header;
  }
  return asMap(rawJson['header']);
}

String? _headerBrowseId(Map<String, dynamic> rawJson) {
  final candidates = <List<String>>[
    <String>[
      'header',
      'musicDetailHeaderRenderer',
      'title',
      'runs',
    ],
    <String>[
      'header',
      'musicResponsiveHeaderRenderer',
      'title',
      'runs',
    ],
  ];
  for (final path in candidates) {
    final runs = asList(digValue(rawJson, path));
    if (runs == null) continue;
    for (final run in runs) {
      final browseId = digValue(run, <String>[
        'navigationEndpoint',
        'browseEndpoint',
        'browseId',
      ]);
      if (browseId is String && browseId.isNotEmpty) return browseId;
    }
  }
  return null;
}

String? _continuationToken(Map<String, dynamic> shelf) {
  final continuations = asList(shelf['continuations']);
  if (continuations == null || continuations.isEmpty) return null;

  final first = asMap(continuations.first);
  final next = asMap(first?['nextContinuationData']) ??
      asMap(first?['nextRadioContinuationData']);
  final token = next?['continuation'];
  return token is String && token.isNotEmpty ? token : null;
}

int? _yearFromHeader(List<dynamic>? subtitleRuns) {
  for (final run in subtitleRuns ?? const <dynamic>[]) {
    final text = asMap(run)?['text'];
    if (text is! String) continue;
    final trimmed = text.trim();
    if (RegExp(r'^(19|20)\d{2}$').hasMatch(trimmed)) {
      return int.tryParse(trimmed);
    }
  }
  return null;
}
