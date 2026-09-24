/// Shared accessors for InnerTube renderer JSON.
///
/// InnerTube's schema is deeply nested and changes often, so every read here is
/// defensive: a missing or wrongly-typed node yields null rather than throwing.
/// The parser tests in `test/` feed these fixtures straight from recorded
/// responses.
library;

import '../../domain/entities/media_item.dart';

Map<String, dynamic>? asMap(Object? value) =>
    value is Map<String, dynamic> ? value : null;

List<dynamic>? asList(Object? value) => value is List ? value : null;

/// Walks a chain of keys and returns the last node as a map.
Map<String, dynamic>? dig(Object? root, List<String> keys) {
  Object? node = root;
  for (final key in keys) {
    node = asMap(node)?[key];
  }
  return asMap(node);
}

Object? digValue(Object? root, List<String> keys) {
  Object? node = root;
  for (var i = 0; i < keys.length; i++) {
    final map = asMap(node);
    if (map == null) return null;
    node = map[keys[i]];
  }
  return node;
}

List<dynamic>? digList(Object? root, List<String> keys) =>
    asList(digValue(root, keys));

/// Concatenates a `runs` array into one string, dropping empty entries.
String? runsToText(Object? runs) {
  final list = asList(runs);
  if (list == null) return null;
  final buffer = StringBuffer();
  for (final run in list) {
    final text = asMap(run)?['text'];
    if (text is String) buffer.write(text);
  }
  final result = buffer.toString().trim();
  return result.isEmpty ? null : result;
}

/// Text of the first run only — used for titles, where the rest of the runs are
/// usually a suffix like " • Official Video".
String? firstRunText(Object? runs) {
  final list = asList(runs);
  if (list == null || list.isEmpty) return null;
  final text = asMap(list.first)?['text'];
  return text is String && text.trim().isNotEmpty ? text.trim() : null;
}

/// Largest available thumbnail URL, which is what the artwork widgets want.
String? bestThumbnailUrl(Object? thumbnailsNode) {
  final thumbnails = asList(digValue(thumbnailsNode, <String>['thumbnails']));
  if (thumbnails == null || thumbnails.isEmpty) return null;

  Map<String, dynamic>? best;
  var bestArea = -1;
  for (final entry in thumbnails) {
    final thumb = asMap(entry);
    if (thumb == null) continue;
    final width = (thumb['width'] as num?)?.toInt() ?? 0;
    final height = (thumb['height'] as num?)?.toInt() ?? 0;
    final area = width * height;
    if (area >= bestArea) {
      bestArea = area;
      best = thumb;
    }
  }

  final url = best?['url'];
  return url is String && url.isNotEmpty ? url : null;
}

/// Reads `thumbnailRenderer.musicThumbnailRenderer`, the wrapper used by
/// carousel cards.
String? twoRowThumbnail(Object? renderer) => bestThumbnailUrl(
  dig(renderer, <String>[
    'thumbnailRenderer',
    'musicThumbnailRenderer',
    'thumbnail',
  ]),
);

/// Reads `thumbnail.musicThumbnailRenderer`, the wrapper used by list rows.
String? listItemThumbnail(Object? renderer) => bestThumbnailUrl(
  dig(renderer, <String>['thumbnail', 'musicThumbnailRenderer', 'thumbnail']),
);

/// Reads a bare `thumbnail.thumbnails`, used by playlist panel rows.
String? bareThumbnail(Object? renderer) =>
    bestThumbnailUrl(dig(renderer, <String>['thumbnail']));

bool hasExplicitBadge(Object? badges) {
  final list = asList(badges);
  if (list == null) return false;
  for (final badge in list) {
    final iconType = digValue(badge, <String>[
      'musicInlineBadgeRenderer',
      'icon',
      'iconType',
    ]);
    if (iconType == 'MUSIC_EXPLICIT_BADGE') return true;
  }
  return false;
}

/// Splits `runs` into the media credit entries and the metadata entries.
///
/// InnerTube interleaves "•" separators with artists and, on some shelves, a
/// view count or subscriber line. The renderer also puts the browse endpoint on
/// the artist runs, so the id comes for free.
List<Artist> parseArtists(Object? runs) {
  final list = asList(runs);
  if (list == null) return const <Artist>[];

  final artists = <Artist>[];
  for (final run in list) {
    final map = asMap(run);
    if (map == null) continue;

    final text = map['text'];
    if (text is! String) continue;
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed == '•' || trimmed == '&' || trimmed == ',') {
      continue;
    }
    if (isMetadataText(trimmed)) continue;

    final browseId = digValue(map, <String>[
      'navigationEndpoint',
      'browseEndpoint',
      'browseId',
    ]);

    artists.add(
      Artist(
        name: trimmed,
        id: browseId is String && browseId.isNotEmpty ? browseId : null,
      ),
    );
  }
  return artists;
}

/// True for the non-credit lines InnerTube mixes into subtitles: view counts,
/// subscriber counts, release years and type badges.
///
/// Subtitles interleave credits with metadata — "Imagine Dragons • 2021" — and
/// a bare four-digit run is always the release year, never an artist.
bool isMetadataText(String text) {
  final lower = text.toLowerCase();
  if (lower.endsWith('views') ||
      lower.endsWith('plays') ||
      lower.endsWith('subscribers') ||
      lower.contains('monthly audience')) {
    return true;
  }
  if (RegExp(r'^(19|20)\d{2}$').hasMatch(text)) {
    return true;
  }
  const badges = <String>{
    'song',
    'video',
    'album',
    'single',
    'ep',
    'playlist',
    'artist',
    'profile',
    'episode',
    'podcast',
  };
  return badges.contains(lower);
}

/// The `pageType` YouTube uses to classify a browse card.
String? twoRowPageType(Object? renderer) {
  final pageType = digValue(renderer, <String>[
    'navigationEndpoint',
    'browseEndpoint',
    'browseEndpointContextSupportedConfigs',
    'browseEndpointContextMusicConfig',
    'pageType',
  ]);
  return pageType is String ? pageType : null;
}
