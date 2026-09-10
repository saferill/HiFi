import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/services/stream_service.dart';
import '../../domain/entities/song.dart';

class PlayerState {
  final Song? currentSong;
  final bool isPlaying;
  final bool isLoading;
  final String? errorMessage;

  const PlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.isLoading = false,
    this.errorMessage,
  });

  PlayerState copyWith({
    Song? currentSong,
    bool? isPlaying,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);

class PlayerController extends Notifier<PlayerState> {
  late final AudioPlayer _audioPlayer;
  StreamSubscription<dynamic>? _subscription;

  @override
  PlayerState build() {
    _audioPlayer = AudioPlayer();

    _subscription = _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      final isBuffering = processingState == ProcessingState.buffering ||
          processingState == ProcessingState.loading;

      state = state.copyWith(
        isPlaying: isPlaying && processingState != ProcessingState.completed,
        isLoading: isBuffering,
      );
    });

    ref.onDispose(() {
      _subscription?.cancel();
      _audioPlayer.dispose();
    });

    return const PlayerState();
  }

  Future<void> playSong(Song song) async {
    // ignore: avoid_print
    print('[PlayerController] playSong START');
    developer.log('playSong START', name: 'PlayerController');
    // ignore: avoid_print
    print('[PlayerController] playSong requested: ${song.title} (${song.videoId})');
    developer.log('playSong requested: ${song.title} (${song.videoId})', name: 'PlayerController');

    state = state.copyWith(
      currentSong: song,
      isLoading: true,
      clearError: true,
    );

    try {
      final streamService = ref.read(streamServiceProvider);
      final streamUrl = await streamService.getAudioStreamUrl(song.videoId);

      if (streamUrl == null || streamUrl.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isPlaying: false,
          errorMessage: 'Gagal mendapatkan audio stream untuk "${song.title}"',
        );
        // ignore: avoid_print
        print('[PlayerController] Failed to play ${song.title}: streamUrl is null');
        developer.log(
          'Failed to play ${song.title}: streamUrl is null',
          name: 'PlayerController',
        );
        return;
      }

      // ignore: avoid_print
      print('[PlayerController] Loading audio stream via just_audio: $streamUrl');
      developer.log('Loading audio stream via just_audio: $streamUrl', name: 'PlayerController');
      await _audioPlayer.setUrl(
        streamUrl,
        headers: {
          'User-Agent':
              'com.google.android.apps.youtube.music/7.16.53 (Linux; U; Android 11) gzip',
        },
      );
      // ignore: avoid_print
      print('[PlayerController] setUrl completed, calling play()');
      await _audioPlayer.play();
      // ignore: avoid_print
      print('[PlayerController] play() completed');

      state = state.copyWith(
        isLoading: false,
        isPlaying: true,
        clearError: true,
      );
    } catch (e, stack) {
      // ignore: avoid_print
      print('[PlayerController] Error playing song ${song.title}: $e');
      developer.log('Error playing song ${song.title}', name: 'PlayerController', error: e, stackTrace: stack);
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        errorMessage: 'Playback error: $e',
      );
    } finally {
      // ignore: avoid_print
      print('[PlayerController] playSong END, isPlaying=${state.isPlaying}');
      developer.log('playSong END, isPlaying=${state.isPlaying}', name: 'PlayerController');
    }
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    state = const PlayerState();
  }
}
