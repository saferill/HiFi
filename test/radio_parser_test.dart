// ignore_for_file: avoid_print
import 'package:app/data/network/innertube_client.dart';
import 'package:app/data/parser/radio_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseRadioResponse parses live YouTube Music radio results', () async {
    final client = InnertubeClient();

    // Testing radio for Imagine Dragons - Bones (TO-_3tck2tg)
    final rawJson = await client.getWatchNext(videoId: 'TO-_3tck2tg');
    expect(rawJson, isNotEmpty);

    final radioResult = parseRadioResponse(rawJson);
    print('Radio songs count: ${radioResult.songs.length}');
    print(
      'Continuation token: ${radioResult.continuationToken != null ? "Present" : "None"}',
    );

    expect(radioResult.songs, isNotEmpty);
    for (final song in radioResult.songs.take(5)) {
      print(
        'Radio Song: ${song.title} by ${song.artist} (${song.videoId}) [${song.duration}]',
      );
      expect(song.videoId, isNotEmpty);
      expect(song.title, isNotEmpty);
    }
  });
}
