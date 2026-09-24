import 'package:app/data/parser/radio_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/innertube_fixtures.dart';

void main() {
  group('parseRadioResponse', () {
    test('reads the watch-next playlist panel into the radio queue', () {
      final result = parseRadioResponse(radioResponse());

      expect(result.songs, hasLength(2));
      expect(result.songs.map((s) => s.videoId).toList(), <String>[
        'TO-_3tck2tg',
        'D9G1VOjN_84',
      ]);
    });

    test('parses title, byline, length and artwork of each track', () {
      final first = parseRadioResponse(radioResponse()).songs.first;

      expect(first.title, 'Bones');
      expect(first.artist, 'Imagine Dragons');
      expect(first.duration, '2:46');
      expect(first.durationSeconds, 166);
      expect(first.thumbnailUrl, contains('bones'));
    });

    test('falls back to shortBylineText when longBylineText is absent', () {
      final second = parseRadioResponse(radioResponse()).songs.last;
      expect(second.artist, 'Imagine Dragons');
      expect(second.title, 'Enemy');
    });

    test('exposes the radio continuation token', () {
      final result = parseRadioResponse(radioResponse());
      expect(result.continuationToken, 'radio-page-2');
    });

    test('returns an empty result for a malformed payload', () {
      final result = parseRadioResponse(<String, dynamic>{});
      expect(result.songs, isEmpty);
      expect(result.continuationToken, isNull);
    });
  });
}
