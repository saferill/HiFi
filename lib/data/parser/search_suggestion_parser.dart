import '../../domain/entities/search_suggestion.dart';
import 'renderer_utils.dart';

/// Parses a `music/get_search_suggestions` response.
///
/// InnerTube mixes two row types in one list: plain query suggestions
/// (`searchSuggestionRenderer`) and, once the input matches a known track, real
/// media rows (`musicResponsiveListItemRenderer`). Both become
/// [SearchSuggestion]s; the media rows also carry their `videoId` so the UI can
/// play them without a second round trip.
List<SearchSuggestion> parseSearchSuggestions(Map<String, dynamic> rawJson) {
  final suggestions = <SearchSuggestion>[];
  final seen = <String>{};

  void add(SearchSuggestion suggestion) {
    final key = suggestion.query.toLowerCase();
    if (key.isEmpty || seen.contains(key)) return;
    seen.add(key);
    suggestions.add(suggestion);
  }

  try {
    final sections = asList(rawJson['contents']);
    if (sections == null) return suggestions;

    for (final section in sections) {
      final rows = asList(
        digValue(section, <String>[
          'searchSuggestionsSectionRenderer',
          'contents',
        ]),
      );
      if (rows == null) continue;

      for (final row in rows) {
        final map = asMap(row);
        if (map == null) continue;

        final suggestionRenderer = asMap(map['searchSuggestionRenderer']);
        if (suggestionRenderer != null) {
          final query = runsToText(suggestionRenderer['suggestion']?['runs']);
          if (query != null) {
            add(SearchSuggestion(query: query));
          }
          continue;
        }

        final listRenderer = asMap(map['musicResponsiveListItemRenderer']);
        if (listRenderer != null) {
          final parsed = _parseMediaRow(listRenderer);
          if (parsed != null) add(parsed);
        }
      }
    }
  } catch (_) {
    // Malformed suggestions must not break the search box.
  }

  return suggestions;
}

SearchSuggestion? _parseMediaRow(Map<String, dynamic> renderer) {
  final flexColumns = asList(renderer['flexColumns']);
  if (flexColumns == null || flexColumns.isEmpty) return null;

  final runs = asList(
    digValue(flexColumns.first, <String>[
      'musicResponsiveListItemFlexColumnRenderer',
      'text',
      'runs',
    ]),
  );
  final title = firstRunText(runs);
  if (title == null) return null;

  var videoId = renderer['playlistItemData']?['videoId'] as String?;
  videoId ??= digValue(renderer, <String>[
    'navigationEndpoint',
    'watchEndpoint',
    'videoId',
  ]) as String?;

  if ((videoId == null || videoId.isEmpty) &&
      runs != null &&
      runs.isNotEmpty) {
    videoId = digValue(runs.first, <String>[
      'navigationEndpoint',
      'watchEndpoint',
      'videoId',
    ]) as String?;
  }

  final resolved = (videoId == null || videoId.isEmpty) ? null : videoId;
  return SearchSuggestion(query: title, videoId: resolved);
}
