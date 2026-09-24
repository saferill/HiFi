import 'package:app/domain/entities/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Song.parseDuration', () {
    test('parses m:ss', () {
      expect(Song.parseDuration('3:24'), 204);
      expect(Song.parseDuration('0:59'), 59);
    });

    test('parses h:mm:ss', () {
      expect(Song.parseDuration('1:02:33'), 3753);
    });

    test('tolerates surrounding whitespace', () {
      expect(Song.parseDuration(' 4:41 '), 281);
    });

    test('returns null for anything that is not a duration', () {
      expect(Song.parseDuration(null), isNull);
      expect(Song.parseDuration(''), isNull);
      expect(Song.parseDuration('Song'), isNull);
      expect(Song.parseDuration('1:2:3:4'), isNull);
    });
  });

  group('Song equality', () {
    const song = Song(
      videoId: 'abc',
      title: 'Title',
      artist: 'Artist',
      thumbnailUrl: 'https://example.com/a.jpg',
    );

    test('compares by videoId, title and artist', () {
      expect(
        song,
        const Song(
          videoId: 'abc',
          title: 'Title',
          artist: 'Artist',
          thumbnailUrl: 'https://example.com/other.jpg',
        ),
      );
      expect(
        song,
        isNot(
          const Song(
            videoId: 'abc',
            title: 'Title',
            artist: 'Other Artist',
            thumbnailUrl: '',
          ),
        ),
      );
    });

    test('copyWith keeps untouched fields', () {
      final updated = song.copyWith(duration: '3:24', isExplicit: true);
      expect(updated.videoId, 'abc');
      expect(updated.thumbnailUrl, 'https://example.com/a.jpg');
      expect(updated.duration, '3:24');
      expect(updated.isExplicit, isTrue);
    });
  });
}
