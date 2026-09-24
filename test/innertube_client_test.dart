import 'package:app/core/network/innertube_client.dart';
import 'package:app/core/network/youtube_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/fake_http_adapter.dart';
import 'fixtures/innertube_fixtures.dart';

void main() {
  late FakeHttpAdapter adapter;
  late Dio dio;

  InnertubeClient clientWith(
    List<FakeResponse> responses, {
    YouTubeLocale locale = const YouTubeLocale(gl: 'ID', hl: 'id'),
  }) {
    adapter = FakeHttpAdapter(responses);
    dio = Dio(BaseOptions(baseUrl: 'https://music.youtube.com/youtubei/v1/'))
      ..httpClientAdapter = adapter;
    return InnertubeClient(dio: dio, locale: locale);
  }

  group('search', () {
    test('posts a WEB_REMIX context, the query and the API key', () async {
      final client = clientWith(<FakeResponse>[FakeResponse(searchResponse())]);

      final data = await client.search('imagine dragons bones');

      expect(data, isNotEmpty);
      expect(adapter.requests, hasLength(1));

      final request = adapter.requests.single;
      expect(request.path, 'search');
      expect(request.queryParameters['key'], YouTubeClient.webRemix.apiKey);
      expect(request.headers['User-Agent'], YouTubeClient.webRemix.userAgent);

      final body = adapter.requestBodies.single;
      expect(body['query'], 'imagine dragons bones');
      expect(body['context']['client']['clientName'], 'WEB_REMIX');
      expect(body['context']['client']['clientVersion'], '1.20260304.03.00');
      // Locale must come from the injected YouTubeLocale, not a hard-coded US.
      expect(body['context']['client']['gl'], 'ID');
      expect(body['context']['client']['hl'], 'id');
    });

    test('passes the filter params and the continuation through', () async {
      final client = clientWith(<FakeResponse>[FakeResponse(searchResponse())]);

      await client.search(
        'imagine dragons',
        params: 'EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D',
        continuation: 'next-page',
      );

      final body = adapter.requestBodies.single;
      expect(body['params'], 'EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D');
      expect(body['continuation'], 'next-page');
      expect(
        adapter.requests.single.queryParameters['continuation'],
        'next-page',
      );
    });
  });

  group('client fallback', () {
    test(
      'retries the next client when a response carries no contents',
      () async {
        final client = clientWith(<FakeResponse>[
          FakeResponse(<String, dynamic>{}),
          FakeResponse(searchResponse()),
        ]);

        final data = await client.search('bones');

        expect(data['contents'], isNotNull);
        expect(adapter.requests, hasLength(2));
        expect(
          adapter.requestBodies[0]['context']['client']['clientName'],
          'WEB_REMIX',
        );
        expect(
          adapter.requestBodies[1]['context']['client']['clientName'],
          'ANDROID_MUSIC',
        );
        expect(
          adapter.requests[1].queryParameters['key'],
          YouTubeClient.androidMusic.apiKey,
        );
      },
    );

    test('retries on an HTTP error too', () async {
      final client = clientWith(<FakeResponse>[
        const FakeResponse(<String, dynamic>{}, statusCode: 403),
        FakeResponse(searchResponse()),
      ]);

      await client.search('bones');

      expect(adapter.requests, hasLength(2));
    });

    test('throws InnertubeException once every client has failed', () async {
      final client = clientWith(<FakeResponse>[
        FakeResponse(<String, dynamic>{}),
      ]);

      await expectLater(
        client.search('bones'),
        throwsA(
          isA<InnertubeException>()
              .having((e) => e.endpoint, 'endpoint', 'search')
              .having(
                (e) => e.clientName,
                'clients tried',
                contains('WEB_REMIX'),
              ),
        ),
      );
      // One request per candidate client.
      expect(adapter.requests, hasLength(YouTubeClient.fallbacks.length));
    });

    test('does not retry when the caller pins a client', () async {
      final client = clientWith(<FakeResponse>[
        FakeResponse(<String, dynamic>{}),
      ]);

      await expectLater(
        client.search('bones', client: YouTubeClient.androidMusic),
        throwsA(isA<InnertubeException>()),
      );
      expect(adapter.requests, hasLength(1));
    });
  });

  group('visitorData', () {
    test(
      'is captured from the first response and sent on the next request',
      () async {
        final client = clientWith(<FakeResponse>[
          FakeResponse(searchResponse()),
          FakeResponse(searchSuggestionsResponse()),
        ]);

        await client.search('bones');
        expect(client.visitorData, 'visitor-1');
        expect(
          adapter.requests[0].headers.containsKey('X-Goog-Visitor-Id'),
          isFalse,
        );

        await client.getSearchSuggestions('bon');
        expect(adapter.requests[1].headers['X-Goog-Visitor-Id'], 'visitor-1');
        expect(
          adapter.requestBodies[1]['context']['client']['visitorData'],
          'visitor-1',
        );
      },
    );
  });

  group('endpoints', () {
    test(
      'getSearchSuggestions posts to music/get_search_suggestions',
      () async {
        final client = clientWith(<FakeResponse>[
          FakeResponse(searchSuggestionsResponse()),
        ]);

        await client.getSearchSuggestions('imagine');

        expect(adapter.requests.single.path, 'music/get_search_suggestions');
        expect(adapter.requestBodies.single['input'], 'imagine');
      },
    );

    test('browse sends the browseId, params and alt=json', () async {
      final client = clientWith(<FakeResponse>[
        FakeResponse(homeBrowseResponse()),
      ]);

      await client.browse(
        browseId: 'FEmusic_moods_and_genres_category',
        params: 'ggMPOg1uX1JOQWZR',
      );

      final request = adapter.requests.single;
      expect(request.path, 'browse');
      expect(request.queryParameters['alt'], 'json');
      expect(
        adapter.requestBodies.single['browseId'],
        'FEmusic_moods_and_genres_category',
      );
      expect(adapter.requestBodies.single['params'], 'ggMPOg1uX1JOQWZR');
    });

    test('browse sends a country formData block for charts', () async {
      final client = clientWith(<FakeResponse>[
        FakeResponse(homeBrowseResponse()),
      ]);

      await client.browse(browseId: 'FEmusic_charts', countryCode: 'ID');

      expect(
        adapter.requestBodies.single['formData']['selectedValues'],
        <String>['ID'],
      );
    });

    test(
      'getWatchNext defaults the playlist id to the video radio mix',
      () async {
        final client = clientWith(<FakeResponse>[
          FakeResponse(radioResponse()),
        ]);

        await client.getWatchNext(videoId: 'TO-_3tck2tg');

        final body = adapter.requestBodies.single;
        expect(adapter.requests.single.path, 'next');
        expect(body['videoId'], 'TO-_3tck2tg');
        expect(body['playlistId'], 'RDAMVMTO-_3tck2tg');
      },
    );
  });
}
