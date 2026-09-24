import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'youtube_client.dart';

final innertubeClientProvider = Provider<InnertubeClient>((ref) {
  return InnertubeClient();
});

/// Thrown when InnerTube answers with an HTTP error or an unusable body after
/// every candidate client has been tried.
class InnertubeException implements Exception {
  const InnertubeException(this.message, {this.endpoint, this.clientName});

  final String message;
  final String? endpoint;
  final String? clientName;

  @override
  String toString() {
    final where = <String>[
      if (endpoint != null) endpoint,
      if (clientName != null) clientName,
    ].join('/');
    return where.isEmpty ? message : 'InnertubeException($where): $message';
  }
}

/// Thin transport for YouTube Music's InnerTube API.
///
/// Mirrors the request shapes of SimpMusic's `Ytmusic` class
/// (https://github.com/maxrave-dev/core, `kotlinYtmusicScraper/Ytmusic.kt`):
/// the same endpoints, the same body models, and the same habit of retrying
/// with a different [YouTubeClient] when one of them answers badly.
///
/// This class deliberately does no parsing — it hands back raw JSON so the
/// parsers under `lib/data/parser/` stay unit-testable against fixtures.
class InnertubeClient {
  InnertubeClient({Dio? dio, YouTubeLocale? locale})
      : _dio = dio ?? _createDefaultDio(),
        _locale = locale ?? const YouTubeLocale();

  static const String _baseUrl = 'https://music.youtube.com/youtubei/v1/';

  final Dio _dio;
  YouTubeLocale _locale;

  /// Echoed back by InnerTube in `responseContext` on the first response and
  /// expected on every later one. Without it some browse shelves come back
  /// empty for an anonymous session.
  String? visitorData;

  YouTubeLocale get locale => _locale;

  set locale(YouTubeLocale value) => _locale = value;

  static Dio _createDefaultDio() {
    return Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        responseType: ResponseType.json,
      ),
    );
  }

  Options _optionsFor(YouTubeClient client) {
    return Options(
      headers: <String, dynamic>{
        'Content-Type': 'application/json',
        'User-Agent': client.userAgent,
        'Origin': 'https://music.youtube.com',
        if (client.referer != null) 'Referer': client.referer,
        if (visitorData != null && visitorData!.isNotEmpty)
          'X-Goog-Visitor-Id': visitorData,
      },
    );
  }

  void _rememberVisitorData(Map<String, dynamic> data) {
    final seen = data['responseContext']?['visitorData'];
    if (seen is String && seen.isNotEmpty) {
      visitorData = seen;
    }
  }

  /// POSTs [body] to [path], retrying across [YouTubeClient.fallbacks] when the
  /// response looks unusable.
  ///
  /// `_looksUsable` is a predicate over the decoded body so each caller can say
  /// what "good" means for its own endpoint (`search` needs `contents`, `next`
  /// needs a playlist panel, and so on).
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> Function(YouTubeClient client) buildBody, {
    YouTubeClient? client,
    Map<String, dynamic>? queryParameters,
    bool Function(Map<String, dynamic> data)? looksUsable,
    List<YouTubeClient>? clients,
  }) async {
    final candidates = client != null
        ? <YouTubeClient>[client]
        : (clients ?? YouTubeClient.fallbacks);

    Object? lastError;

    for (final candidate in candidates) {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          path,
          data: buildBody(candidate),
          options: _optionsFor(candidate),
          queryParameters: <String, dynamic>{
            'key': candidate.apiKey,
            'prettyPrint': false,
            ...?queryParameters,
          },
        );

        final data = response.data ?? <String, dynamic>{};
        _rememberVisitorData(data);

        if (looksUsable != null && !looksUsable(data)) {
          lastError = InnertubeException(
            'response was missing the expected payload',
            endpoint: path,
            clientName: candidate.clientName,
          );
          developer.log(
            'Unusable response from $path with ${candidate.clientName}, '
            'trying next client',
            name: 'InnertubeClient',
          );
          continue;
        }

        developer.log(
          '$path ok via ${candidate.clientName}',
          name: 'InnertubeClient',
        );
        return data;
      } on DioException catch (e) {
        lastError = e;
        developer.log(
          '$path failed with ${candidate.clientName}: ${e.message}',
          name: 'InnertubeClient',
          error: e,
        );
      }
    }

    throw InnertubeException(
      'all clients failed: ${lastError is InnertubeException ? lastError.message : lastError}',
      endpoint: path,
      clientName: candidates.map((c) => c.clientName).join(','),
    );
  }

  static bool _hasContents(Map<String, dynamic> data) =>
      data['contents'] is Map<String, dynamic>;

  /// `POST search` — YouTube Music search.
  ///
  /// [params] selects a result filter (Songs / Albums / Artists / Playlists);
  /// [continuation] pages through a filtered result set.
  Future<Map<String, dynamic>> search(
    String query, {
    String? params,
    String? continuation,
    YouTubeClient? client,
  }) {
    return _post(
      'search',
      (c) => <String, dynamic>{
        'context': c.toContext(_locale, visitorData: visitorData),
        'query': query,
        if (params != null) 'params': params,
        if (continuation != null) 'continuation': continuation,
      },
      client: client,
      queryParameters: <String, dynamic>{
        if (continuation != null) ...<String, dynamic>{
          'continuation': continuation,
          'ctoken': continuation,
        },
      },
      looksUsable: _hasContents,
    );
  }

  /// `POST music/get_search_suggestions` — typeahead for the search box.
  Future<Map<String, dynamic>> getSearchSuggestions(
    String input, {
    YouTubeClient? client,
  }) {
    return _post(
      'music/get_search_suggestions',
      (c) => <String, dynamic>{
        'context': c.toContext(_locale, visitorData: visitorData),
        'input': input,
      },
      client: client,
      looksUsable: (data) => data['contents'] is List,
    );
  }

  /// `POST browse` — the endpoint behind Home, Charts, Moods & Genres,
  /// albums, playlists and artist pages. Everything is selected by
  /// [browseId] plus an optional [params] token.
  Future<Map<String, dynamic>> browse({
    String? browseId,
    String? params,
    String? continuation,
    String? countryCode,
    YouTubeClient? client,
  }) {
    return _post(
      'browse',
      (c) => <String, dynamic>{
        'context': c.toContext(_locale, visitorData: visitorData),
        if (browseId != null && browseId.isNotEmpty) 'browseId': browseId,
        if (params != null && params.isNotEmpty) 'params': params,
        if (continuation != null && continuation.isNotEmpty)
          'continuation': continuation,
        if (countryCode != null && countryCode.isNotEmpty)
          'formData': <String, dynamic>{
            'selectedValues': <String>[countryCode],
          },
      },
      client: client,
      queryParameters: <String, dynamic>{'alt': 'json'},
      looksUsable: _hasContents,
    );
  }

  /// `POST next` — the watch queue / radio panel for a video.
  Future<Map<String, dynamic>> next({
    String? videoId,
    String? playlistId,
    String? playlistSetVideoId,
    int? index,
    String? params,
    String? continuation,
    YouTubeClient? client,
  }) {
    return _post(
      'next',
      (c) => <String, dynamic>{
        'context': c.toContext(_locale, visitorData: visitorData),
        if (videoId != null) 'videoId': videoId,
        if (playlistId != null) 'playlistId': playlistId,
        if (playlistSetVideoId != null)
          'playlistSetVideoId': playlistSetVideoId,
        if (index != null) 'index': index,
        if (params != null) 'params': params,
        if (continuation != null) 'continuation': continuation,
      },
      client: client,
      looksUsable: (data) =>
          _hasContents(data) || data['continuationContents'] != null,
    );
  }

  /// Backwards-compatible alias for [next] used by the radio queue.
  ///
  /// Defaults `playlistId` to the "start a radio from this video" mix, which
  /// is what turns a single song into an endless queue.
  Future<Map<String, dynamic>> getWatchNext({
    required String videoId,
    String? playlistId,
    String? continuation,
  }) {
    return next(
      videoId: videoId,
      playlistId: playlistId ?? 'RDAMVM$videoId',
      continuation: continuation,
    );
  }

  /// `POST music/get_queue` — full metadata for a batch of video ids.
  Future<Map<String, dynamic>> getQueue({
    List<String>? videoIds,
    String? playlistId,
    YouTubeClient? client,
  }) {
    return _post(
      'music/get_queue',
      (c) => <String, dynamic>{
        'context': c.toContext(_locale, visitorData: visitorData),
        if (videoIds != null) 'videoIds': videoIds,
        if (playlistId != null) 'playlistId': playlistId,
      },
      client: client,
    );
  }

  /// `POST player` — raw player response.
  ///
  /// Deprecated for stream extraction (see `stream_service.dart`), but still
  /// the cheapest way to read a video's `videoDetails`.
  Future<Map<String, dynamic>> getPlayerInfo(
    String videoId, {
    YouTubeClient? client,
  }) {
    return _post(
      'player',
      (c) => <String, dynamic>{
        'context': c.toContext(_locale, visitorData: visitorData),
        'videoId': videoId,
      },
      client: client,
    );
  }
}
