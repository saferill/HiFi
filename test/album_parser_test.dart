import 'package:app/data/parser/album_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/innertube_fixtures.dart';

void main() {
  group('parseAlbumPage', () {
    late AlbumPageResult result;

    setUp(() {
      result = parseAlbumPage(albumBrowseResponse())!;
    });

    test('reads the header into an AlbumItem', () {
      expect(result.album.browseId, 'MPREb_9nqEki4ZLQ4');
      expect(result.album.title, 'Mercury - Act 1');
      expect(result.album.artists.single.name, 'Imagine Dragons');
      expect(result.album.artists.single.id, 'UCB0JSO6d5ysH2Mmqz5I9rIw');
      expect(result.album.year, 2021);
      expect(result.album.thumbnailUrl, contains('mercury'));
      expect(result.description, 'Fifth studio album.');
    });

    test('keeps the album playlist id used to queue the whole record', () {
      expect(result.album.playlistId, 'OLAK5uy_kMercury');
    });

    test('parses the track list in order, with durations and set ids', () {
      expect(result.songs.map((s) => s.title).toList(),
          <String>['My Life', 'Enemy']);

      final myLife = result.songs.first;
      expect(myLife.videoId, 'TO-_3tck2tg');
      expect(myLife.duration, '3:44');
      expect(myLife.durationSeconds, 224);
      expect(myLife.setVideoId, 'set-1');
      expect(myLife.artist, 'Imagine Dragons');

      expect(result.songs[1].isExplicit, isTrue);
      expect(result.songs[1].setVideoId, 'set-2');
    });

    test('exposes the continuation token for long track lists', () {
      expect(result.continuationToken, 'album-page-2');
    });

    test('returns null when there is no track shelf to read', () {
      expect(parseAlbumPage(<String, dynamic>{}), isNull);
      expect(
        parseAlbumPage(<String, dynamic>{
          'header': <String, dynamic>{},
        }),
        isNull,
      );
    });
  });
}
