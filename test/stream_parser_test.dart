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

      expect(url, isNull);
    });

    test('returns null when the format is ciphered, not a broken URL', () {
      final url = extractAudioStreamUrl(
        playerWith(<Map<String, dynamic>>[
          audioFormat(bitrate: 256000, cipher: 's=abc&url=https%3A%2F%2Fex'),
        ]),
      );

      expect(url, isNull);
    });

    test('returns null for a payload with no streaming data', () {
      expect(extractAudioStreamUrl(<String, dynamic>{}), isNull);
      expect(
        extractAudioStreamUrl(<String, dynamic>{
          'streamingData': <String, dynamic>{'adaptiveFormats': <dynamic>[]},
        }),
        isNull,
      );
    });
  });
}
