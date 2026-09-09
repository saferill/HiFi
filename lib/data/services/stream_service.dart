import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final streamServiceProvider = Provider<StreamService>((ref) {
  final service = StreamService();
  ref.onDispose(service.dispose);
  return service;
});

class StreamService {
  final YoutubeExplode _yt;

  StreamService({YoutubeExplode? yt}) : _yt = yt ?? YoutubeExplode();

  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      developer.log('Fetching stream manifest for videoId: $videoId', name: 'StreamService');
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;

      if (audioStreams.isEmpty) {
        developer.log('No audioOnly streams found for $videoId', name: 'StreamService');
        return null;
      }

      final bestAudioStream = audioStreams.withHighestBitrate();
      final streamUrl = bestAudioStream.url.toString();

      developer.log(
        'Audio stream URL resolved for $videoId (bitrate: ${bestAudioStream.bitrate}, container: ${bestAudioStream.container.name})',
        name: 'StreamService',
      );
      return streamUrl;
    } catch (e, stack) {
      // ignore: avoid_print
      print('=== STREAM SERVICE EXCEPTION ===');
      // ignore: avoid_print
      print('Exception Type: ${e.runtimeType}');
      // ignore: avoid_print
      print('Exception Details: $e');
      developer.log(
        'Failed to get audio stream URL for $videoId (Type: ${e.runtimeType}): $e',
        name: 'StreamService',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}
