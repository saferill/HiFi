import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'youtube_client.dart';

/// Shared HTTP transport.
///
/// Everything this app talks to goes through YouTube Music's InnerTube API, so
/// the base URL and timeouts live here once instead of being rebuilt inside
/// each client. `InnertubeClient` reads this provider; tests bypass it by
/// injecting their own [Dio] with a fake adapter.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: innertubeBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
    ),
  );

  ref.onDispose(dio.close);
  return dio;
});
