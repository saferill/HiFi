/// A single search typeahead entry.
///
/// InnerTube returns suggestions in two shapes: a plain query
/// (`searchSuggestionRenderer`) and, once you have typed enough, real media
/// items (`musicResponsiveListItemRenderer`). Both collapse into this.
class SearchSuggestion {
  const SearchSuggestion({
    required this.query,
    this.videoId,
    this.isFromHistory = false,
  });

  /// Text to put in the search box when the row is tapped.
  final String query;

  /// Set when the suggestion is a specific track, so it can play directly.
  final String? videoId;

  final bool isFromHistory;

  @override
  String toString() =>
      'SearchSuggestion($query${videoId == null ? '' : ', $videoId'})';
}
