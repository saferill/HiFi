import 'package:app/data/parser/search_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/innertube_fixtures.dart';

void main() {
  group('parseSearchResults', () {
    test('parses the top result card and the song shelf together', () {
      final songs = parseSearchResults(searchResponse());

      expect(songs, hasLength(2));
      expect(songs.map((s) => s.videoId).toList(),
          <String>['TO-_3tck2tg', 'D9G1VOjN_84']);
    });

    test('reads title, artist, duration and artwork of the top result', () {
      final top = parseSearchResults(searchResponse()).first;

      expect(top.title, 'Bones');
      expect(top.artist, 'Imagine Dragons');
      expect(top.duration, '2:46');
      expect(top.durationSeconds, 166);
      expect(top.thumbnailUrl, contains('bones'));
      // "Song" is a type badge and must not be mistaken for an artist.
      expect(top.artist, isNot('Song'));
    });

    test('keeps the first credit of a multi-credit subtitle', () {
      final enemy = parseSearchResults(searchResponse()).last;

      expect(enemy.title, 'Enemy');
      expect(enemy.artist, 'Imagine Dragons');
      expect(enemy.duration, '3:53');
      expect(enemy.thumbnailUrl, contains('enemy'));
    });

    test('never returns the same video twice', () {
      final json = searchResponse();
      final shelf = ((json['contents'] as Map<String, dynamic>)[
              'tabbedSearchResultsRenderer'] as Map<String, dynamic>)['tabs'] as List;
      final sectionList = ((shelf.first as Map<String, dynamic>)['tabRenderer']
          as Map<String, dynamic>)['content'];
      final contents =
          (sectionList as Map<String, dynamic>)['sectionListRenderer']
              as Map<String, dynamic>;
      // Duplicate the shelf so the second copy repeats videoIds.
      (contents['contents'] as List)..add((contents['contents'] as List)[1]);

      final songs = parseSearchResults(json);
      expect(songs, hasLength(2));
    });

    test('returns an empty list for a malformed payload', () {
      expect(parseSearchResults(<String, dynamic>{}), isEmpty);
      expect(
        parseSearchResults(<String, dynamic>{'contents': 'nope'}),
        isEmpty,
      );
    });
  });
}
