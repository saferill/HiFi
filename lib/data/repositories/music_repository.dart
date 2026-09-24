import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/innertube_client.dart';
import '../../domain/entities/browse.dart';
import '../../domain/entities/search_suggestion.dart';
import '../../domain/entities/song.dart';
import '../parser/album_parser.dart';
import '../parser/browse_parser.dart';
import '../parser/radio_parser.dart';
import '../parser/search_parser.dart';
import '../parser/search_suggestion_parser.dart';
import '../services/stream_service.dart';

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  return MusicRepository(
    innertubeClient: ref.watch(innertubeClientProvider),
    streamService: ref.watch(streamServiceProvider),
  );
});

/// Search results for a query. Empty queries short-circuit without a request.
final searchSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, query) async {
  if (query.trim().isEmpty) {
    return const <Song>[];
  }
  return ref.watch(musicRepositoryProvider).searchSongs(query);
});

/// Typeahead suggestions for the search box.
final searchSuggestionsProvider =
    FutureProvider.family<List<SearchSuggestion>, String>((ref, input) async {
  if (input.trim().isEmpty) {
    return const <SearchSuggestion>[];
  }
  return ref.watch(musicRepositoryProvider).getSearchSuggestions(input);
});

/// A browse page — Home, Charts, Moods & Genres, or a "more from shelf" page.
///
/// Keyed on `browseId` plus `params` because the same `browseId` returns
/// different shelves for different `params` (every mood tile shares
/// `FEmusic_moods_and_genres_category`).
final browsePageProvider =
    FutureProvider.family<BrowsePage, BrowseRequest>((ref, request) async {
  return ref.watch(musicRepositoryProvider).getBrowsePage(
        request.browseId,
        params: request.params,
        countryCode: request.countryCode,
      );
});

/// The full track list behind an album or playlist card.
final albumPageProvider =
    FutureProvider.family<AlbumPageResult?, String>((ref, browseId) async {
  return ref.watch(musicRepositoryProvider).getAlbumPage(browseId);
});

class BrowseRequest {
  const BrowseRequest({required this.browseId, this.params, this.countryCode});

  final String browseId;
  final String? params;
  final String? countryCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrowseRequest &&
          browseId == other.browseId &&
          params == other.params &&
          countryCode == other.countryCode;

  @override
  int get hashCode => Object.hash(browseId, params, countryCode);

  @override
  String toString() => 'BrowseRequest($browseId, $params, $countryCode)';
}

/// Well-known YouTube Music browse ids.
///
/// Stable API values rather than user-facing strings — the same ones SimpMusic
/// sends from its `HomeRepositoryImpl`.
class BrowseIds {
  const BrowseIds._();

  static const String home = 'FEmusic_home';
  static const String charts = 'FEmusic_charts';
  static const String newReleases = 'FEmusic_new_releases';
  static const String moodsAndGenres = 'FEmusic_moods_and_genres';
  static const String moodCategory = 'FEmusic_moods_and_genres_category';
}

class MusicRepository {
  MusicRepository({
    required this.innertubeClient,
    required this.streamService,
  });

  final InnertubeClient innertubeClient;
  final StreamService streamService;

  Future<List<Song>> searchSongs(
    String query, {
    String? params,
    String? continuation,
  }) async {
    final rawJson = await innertubeClient.search(
      query,
      params: params,
      continuation: continuation,
    );
    return parseSearchResults(rawJson);
  }

  Future<List<SearchSuggestion>> getSearchSuggestions(String input) async {
    final rawJson = await innertubeClient.getSearchSuggestions(input);
    return parseSearchSuggestions(rawJson);
  }

  Future<BrowsePage> getBrowsePage(
    String browseId, {
    String? params,
    String? countryCode,
  }) async {
    final rawJson = await innertubeClient.browse(
      browseId: browseId,
      params: params,
      countryCode: countryCode,
    );
    return parseBrowsePage(rawJson);
  }

  Future<AlbumPageResult?> getAlbumPage(String browseId) async {
    final rawJson = await innertubeClient.browse(browseId: browseId);
    return parseAlbumPage(rawJson);
  }

  Future<RadioResult> getRadioTracks(
    String videoId, {
    String? playlistId,
    String? continuation,
  }) async {
    final rawJson = await innertubeClient.getWatchNext(
      videoId: videoId,
      playlistId: playlistId,
      continuation: continuation,
    );
    return parseRadioResponse(rawJson);
  }

  Future<String?> getAudioStreamUrl(String videoId) {
    return streamService.getAudioStreamUrl(videoId);
  }
}
