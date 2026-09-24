import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final searchSongsProvider = FutureProvider.family<List<Song>, String>((
  ref,
  query,
) async {
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

  MusicRepository({required this.innertubeClient, required this.streamService});

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
