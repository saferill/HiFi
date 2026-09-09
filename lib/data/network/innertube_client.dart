import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final innertubeClientProvider = Provider<InnertubeClient>((ref) {
  return InnertubeClient();
});

class InnertubeClient {
  late final Dio _dio;

  static const String _baseUrl = 'https://music.youtube.com/youtubei/v1/';
  static const String _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';

  InnertubeClient({Dio? dio}) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            queryParameters: {
              'key': _apiKey,
            },
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Visitor-Id': '',
              'Origin': 'https://music.youtube.com',
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
            responseType: ResponseType.json,
          ),
        );
  }

  Map<String, dynamic> get _defaultContext => {
        'client': {
          'clientName': 'WEB_REMIX',
          'clientVersion': '1.20240101.01.00',
          'hl': 'en',
          'gl': 'US',
        },
      };

  Future<Map<String, dynamic>> search(String query) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'search',
        data: {
          'context': _defaultContext,
          'query': query,
        },
      );

      final data = response.data ?? <String, dynamic>{};
      developer.log(
        'Innertube search success. Status: ${response.statusCode}, Keys: ${data.keys.toList()}',
        name: 'InnertubeClient',
      );
      return data;
    } on DioException catch (e) {
      developer.log(
        'Innertube search error: ${e.message}, response: ${e.response?.data}',
        name: 'InnertubeClient',
        error: e,
      );
      rethrow;
    }
  }

  // Deprecated: diganti youtube_explode_dart
  Future<Map<String, dynamic>> getPlayerInfo(String videoId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'player',
        data: {
          'context': _defaultContext,
          'videoId': videoId,
        },
      );

      final data = response.data ?? <String, dynamic>{};
      developer.log(
        'Innertube getPlayerInfo success. Status: ${response.statusCode}, videoId: $videoId',
        name: 'InnertubeClient',
      );
      return data;
    } on DioException catch (e) {
      developer.log(
        'Innertube getPlayerInfo error: ${e.message}, response: ${e.response?.data}',
        name: 'InnertubeClient',
        error: e,
      );
      rethrow;
    }
  }
}
