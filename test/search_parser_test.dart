// ignore_for_file: avoid_print
import 'package:app/data/network/innertube_client.dart';
import 'package:app/data/parser/search_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseSearchResults parses live YouTube Music search results', () async {
    final client = InnertubeClient();
    final json = await client.search('Imagine Dragons Bones');
    final songs = parseSearchResults(json);

    expect(songs, isNotEmpty);
    print('Parsed songs count: ${songs.length}');
    for (final song in songs.take(5)) {
      print('Song: $song');
      expect(song.videoId, isNotEmpty);
      expect(song.title, isNotEmpty);
      expect(song.artist, isNotEmpty);
      expect(song.thumbnailUrl, isNotEmpty);
    }
  });
}
