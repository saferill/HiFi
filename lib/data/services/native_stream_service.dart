import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nativeStreamServiceProvider = Provider<NativeStreamService>((ref) {
  return NativeStreamService();
});

class NativeStreamService {
  static const _channel = MethodChannel('com.hifi.app/stream');

  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      developer.log(
        'NativeStreamService.getAudioStreamUrl for $videoId',
        name: 'NativeStreamService',
      );
      final result = await _channel.invokeMethod<String>(
        'getStreamUrl',
        {'videoId': videoId},
      );
      developer.log(
        'NativeStreamService resolved URL for $videoId: $result',
        name: 'NativeStreamService',
      );
      return result;
    } catch (e, stack) {
      developer.log(
        'NativeStreamService error: $e',
        name: 'NativeStreamService',
        error: e,
        stackTrace: stack,
      );
      // ignore: avoid_print
      print('[NativeStreamService] Error getting stream URL for $videoId: $e');
      return null;
    }
  }
}
