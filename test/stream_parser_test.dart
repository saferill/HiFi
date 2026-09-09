// ignore_for_file: avoid_print
import 'package:app/data/network/innertube_client.dart';
import 'package:app/data/parser/stream_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Test getPlayerInfo and stream parsing across multiple videoIds', () async {
    final client = InnertubeClient();

    // Test multiple popular song videoIds
    final testVideoIds = [
      {'id': 'TO-_3tck2tg', 'title': 'Imagine Dragons - Bones'},
      {'id': 'JGwWNGJdvx8', 'title': 'Ed Sheeran - Shape of You'},
      {'id': 'YQHsXMglC9A', 'title': 'Adele - Hello'},
      {'id': 'fJ9rUzIMcZQ', 'title': 'Queen - Bohemian Rhapsody'},
      {'id': 'kJQP7kiw5Fk', 'title': 'Luis Fonsi - Despacito'},
    ];

    var directUrlCount = 0;
    var cipherCount = 0;

    for (final item in testVideoIds) {
      final videoId = item['id']!;
      final title = item['title']!;

      print('\nTesting player info for: $title ($videoId)...');
      final playerJson = await client.getPlayerInfo(videoId);

      final streamingData = playerJson['streamingData'] as Map<String, dynamic>?;
      print('  streamingData present: ${streamingData != null}');
      if (streamingData != null) {
        final formats = streamingData['adaptiveFormats'] as List? ?? [];
        print('  adaptiveFormats count: ${formats.length}');

        final audioFormats = formats.whereType<Map<String, dynamic>>().where((f) {
          final mime = (f['mimeType'] as String? ?? '').toLowerCase();
          return mime.contains('audio/');
        }).toList();

        print('  audioFormats count: ${audioFormats.length}');
        for (var i = 0; i < audioFormats.length && i < 2; i++) {
          final af = audioFormats[i];
          final hasUrl = af.containsKey('url') && (af['url'] as String? ?? '').isNotEmpty;
          final hasCipher = af.containsKey('signatureCipher') || af.containsKey('cipher');
          print('    format $i: mime=${af['mimeType']}, bitrate=${af['bitrate']}, hasDirectUrl=$hasUrl, hasCipher=$hasCipher');
        }
      }

      final streamUrl = extractAudioStreamUrl(playerJson);
      if (streamUrl != null && streamUrl.isNotEmpty) {
        directUrlCount++;
        print('  -> SUCCESS: Direct audio URL extracted: ${streamUrl.substring(0, 50)}...');
      } else {
        cipherCount++;
        print('  -> NEEDS CIPHER OR NULL');
      }
    }

    print('\n=== SUMMARY OF STREAM PARSER TEST ===');
    print('Total tested: ${testVideoIds.length}');
    print('Direct URLs: $directUrlCount');
    print('Cipher required: $cipherCount');
  });
}
