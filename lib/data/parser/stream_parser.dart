import 'dart:developer' as developer;

String? extractAudioStreamUrl(Map<String, dynamic> playerJson) {
  try {
    final streamingData = playerJson['streamingData'] as Map<String, dynamic>?;
    if (streamingData == null) {
      developer.log('No streamingData found in player response', name: 'StreamParser');
      return null;
    }

    final adaptiveFormats = streamingData['adaptiveFormats'] as List?;
    if (adaptiveFormats == null || adaptiveFormats.isEmpty) {
      developer.log('No adaptiveFormats found in streamingData', name: 'StreamParser');
      return null;
    }

    // Filter audio formats
    final audioFormats = adaptiveFormats
        .whereType<Map<String, dynamic>>()
        .where((format) {
          final mimeType = (format['mimeType'] as String? ?? '').toLowerCase();
          return mimeType.contains('audio/');
        })
        .toList();

    if (audioFormats.isEmpty) {
      developer.log('No audio formats found in adaptiveFormats', name: 'StreamParser');
      return null;
    }

    // Sort by bitrate descending to get highest quality
    audioFormats.sort((a, b) {
      final bitrateA = (a['bitrate'] as num?)?.toInt() ?? 0;
      final bitrateB = (b['bitrate'] as num?)?.toInt() ?? 0;
      return bitrateB.compareTo(bitrateA);
    });

    final bestFormat = audioFormats.first;
    final directUrl = bestFormat['url'] as String?;

    if (directUrl != null && directUrl.isNotEmpty) {
      developer.log(
        'Direct audio stream URL found (bitrate: ${bestFormat['bitrate']}, mime: ${bestFormat['mimeType']})',
        name: 'StreamParser',
      );
      return directUrl;
    }

    // Check signatureCipher or cipher
    final signatureCipher = (bestFormat['signatureCipher'] as String?) ??
        (bestFormat['cipher'] as String?);

    if (signatureCipher != null && signatureCipher.isNotEmpty) {
      // ignore: avoid_print
      print('STREAM_NEEDS_CIPHER_DECODE: $signatureCipher');
      developer.log(
        'STREAM_NEEDS_CIPHER_DECODE: $signatureCipher',
        name: 'StreamParser',
      );
      return null;
    }
  } catch (e, stack) {
    developer.log('Error extracting audio stream URL', name: 'StreamParser', error: e, stackTrace: stack);
  }

  return null;
}
