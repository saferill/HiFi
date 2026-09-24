import 'package:app/data/parser/browse_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/innertube_fixtures.dart';

void main() {
  group('parseBrowsePage', () {
    test('reads the page title from the selected tab', () {
      final page = parseBrowsePage(homeBrowseResponse());
      expect(page.title, 'Home');
    });

    test('returns every shelf in order, skipping empty ones', () {
      final page = parseBrowsePage(homeBrowseResponse());

      expect(page.sections.map((s) => s.title).toList(), <String?>[
        'Quick picks',
        'New releases',
        'Moods & genres',
        'Mixed for you',
      ]);
      expect(page.sections.every((s) => !s.isEmpty), isTrue);
    });

    test('parses square watch cards as songs', () {
      final quickPicks = parseBrowsePage(homeBrowseResponse()).sections.first;

      expect(quickPicks.songs, hasLength(2));
      final bones = quickPicks.songs.first;
      expect(bones.videoId, 'TO-_3tck2tg');
      expect(bones.title, 'Bones');
      expect(bones.artist, 'Imagine Dragons');
      expect(bones.thumbnailUrl, contains('bones'));
      // The "2022" run is a release year, not an artist credit.
      expect(bones.artist, isNot(contains('2022')));

      // Explicit badge on the second card.
      expect(quickPicks.songs[1].videoId, 'D9G1VOjN_84');
      expect(quickPicks.songs[1].isExplicit, isTrue);
      expect(quickPicks.songs.first.isExplicit, isFalse);
    });

    test('parses album cards with their playlist id and artist credit', () {
      final newReleases = parseBrowsePage(homeBrowseResponse()).sections[1];

      expect(newReleases.albums, hasLength(1));
      final album = newReleases.albums.single;
      expect(album.browseId, 'MPREb_9nqEki4ZLQ4');
      expect(album.title, 'Mercury - Act 1');
      expect(album.artists.single.name, 'Imagine Dragons');
      expect(album.artists.single.id, 'UCB0JSO6d5ysH2Mmqz5I9rIw');
      expect(album.year, 2021);
      expect(album.playlistId, 'OLAK5uy_kMercury');

      // The shelf's "More" button target is kept.
      expect(newReleases.moreBrowseId, 'FEmusic_new_releases');
      expect(newReleases.moreParams, 'ggM8SgQIBxAB');
    });

    test('parses mood tiles as buttons carrying browseId and params', () {
      final moods = parseBrowsePage(homeBrowseResponse()).sections[2];

      expect(moods.moods, hasLength(2));
      final chill = moods.moods.first;
      expect(chill.title, 'Chill');
      expect(chill.browseId, 'FEmusic_moods_and_genres_category');
      expect(chill.params, 'ggMPOg1uX1JOQWZR');
      expect(chill.stripeColor, isNotNull);
      expect(moods.songs, isEmpty);
      expect(moods.albums, isEmpty);
    });

    test('parses list rows, reading the duration from fixedColumns', () {
      final mixed = parseBrowsePage(homeBrowseResponse()).sections[3];

      expect(mixed.songs, hasLength(1));
      final despacito = mixed.songs.single;
      expect(despacito.videoId, 'kJQP7kiw5Fk');
      expect(despacito.title, 'Despacito');
      expect(despacito.artist, 'Luis Fonsi');
      expect(despacito.duration, '4:41');
      expect(despacito.durationSeconds, 281);
      // "Vida" is linked with an MPRE browse id, so it is the album credit.
      expect(despacito.album?.name, 'Vida');
      expect(despacito.album?.id, 'MPREb_xyzVida');
    });

    test('collects every track on the page via allSongs', () {
      final page = parseBrowsePage(homeBrowseResponse());
      expect(page.allSongs.map((s) => s.videoId).toList(), <String>[
        'TO-_3tck2tg',
        'D9G1VOjN_84',
        'kJQP7kiw5Fk',
      ]);
    });

    test('degrades to an empty page instead of throwing', () {
      expect(parseBrowsePage(<String, dynamic>{}).sections, isEmpty);
      expect(
        parseBrowsePage(<String, dynamic>{'contents': 'not a map'}).sections,
        isEmpty,
      );
      expect(
        parseBrowsePage(<String, dynamic>{
          'contents': <String, dynamic>{
            'singleColumnBrowseResultsRenderer': <String, dynamic>{
              'tabs': 'not a list',
            },
          },
        }).sections,
        isEmpty,
      );
    });
  });
}
