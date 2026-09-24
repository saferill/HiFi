import 'package:app/data/parser/stream_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// `extractAudioStreamUrl` is the deprecated InnerTube-based extractor kept
/// around for `player` responses that still carry a plain `url`. These cases
/// pin the behaviour the repository relies on when it falls back to it.
void main() {
  Map<String, dynamic> playerWith(List<Map<String, dynamic>> formats) =>
      <String, dynamic>{
        'streamingData': <String, dynamic>{
          'adaptiveFormats': formats,
        },
      };

  Map<String, dynamic> audioFormat({
    required int bitrate,
    String? url,
    String? cipher,
    String mimeType = 'audio/webm; codecs="opus"',
  }) {
    return <String, dynamic>{
      'mimeType': mimeType,
      'bitrate': bitrate,
      if (url != null) 'url': url,
      if (cipher != null) 'signatureCipher': cipher,
    };
  }

  group('extractAudioStreamUrl', () {
    test('picks the highest-bitrate audio format', () {
      final url = extractAudioStreamUrl(
        playerWith(<Map<String, dynamic>>[
          audioFormat(bitrate: 64000, url: 'https://example.com/low'),
          audioFormat(bitrate: 256000, url: 'https://example.com/high'),
          audioFormat(bitrate: 128000, url: 'https://example.com/mid'),
          // A video-only format must never win, however high its bitrate.
          <String, dynamic>{
            'mimeType': 'video/mp4',
            'bitrate': 4000000,
            'url': 'https://example.com/video',
          },
        ]),
      );

      expect(url, 'https://example.com/high');
    });

    test('ignores non-audio formats entirely', () {
      final url = extractAudioStreamUrl(
        playerWith(<Map<String, dynamic>>[
          <String, dynamic>{
            'mimeType': 'video/mp4',
            'bitrate': 4000000,
            'url': 'https://example.com/video',
          },
        ]),
      );

      final streamingData =
          playerJson['streamingData'] as Map<String, dynamic>?;
      print('  streamingData present: ${streamingData != null}');
      if (streamingData != null) {
        final formats = streamingData['adaptiveFormats'] as List? ?? [];
        print('  adaptiveFormats count: ${formats.length}');

        final audioFormats = formats.whereType<Map<String, dynamic>>().where((
          f,
        ) {
          final mime = (f['mimeType'] as String? ?? '').toLowerCase();
          return mime.contains('audio/');
        }).toList();

        print('  audioFormats count: ${audioFormats.length}');
        for (var i = 0; i < audioFormats.length && i < 2; i++) {
          final af = audioFormats[i];
          final hasUrl =
              af.containsKey('url') && (af['url'] as String? ?? '').isNotEmpty;
          final hasCipher =
              af.containsKey('signatureCipher') || af.containsKey('cipher');
          print(
            '    format $i: mime=${af['mimeType']}, bitrate=${af['bitrate']}, hasDirectUrl=$hasUrl, hasCipher=$hasCipher',
          );
        }
      }

      final streamUrl = extractAudioStreamUrl(playerJson);
      if (streamUrl != null && streamUrl.isNotEmpty) {
        directUrlCount++;
        print(
          '  -> SUCCESS: Direct audio URL extracted: ${streamUrl.substring(0, 50)}...',
        );
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
