import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/repositories/music_repository.dart';
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
  StreamSubscription<PlayerStateStreamEvent>? _subscription;

  @override
  PlayerState build() {
    _audioPlayer = AudioPlayer();

    _audioPlayer.playerStateStream.listen((playerState) {
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
    developer.log('playSong requested: ${song.title} (${song.videoId})', name: 'PlayerController');

    state = state.copyWith(
      currentSong: song,
      isLoading: true,
      clearError: true,
    );

    try {
      final repository = ref.read(musicRepositoryProvider);
      final streamUrl = await repository.getAudioStreamUrl(song.videoId);

      if (streamUrl == null || streamUrl.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isPlaying: false,
          errorMessage: 'STREAM_NEEDS_CIPHER_DECODE (No direct audio stream URL)',
        );
        developer.log(
          'Failed to play ${song.title}: STREAM_NEEDS_CIPHER_DECODE',
          name: 'PlayerController',
        );
        return;
      }

      developer.log('Loading audio stream: $streamUrl', name: 'PlayerController');
      await _audioPlayer.setUrl(streamUrl);
      await _audioPlayer.play();

      state = state.copyWith(
        isLoading: false,
        isPlaying: true,
        clearError: true,
      );
    } catch (e, stack) {
      developer.log('Error playing song ${song.title}', name: 'PlayerController', error: e, stackTrace: stack);
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        errorMessage: 'Playback error: $e',
      );
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

typedef PlayerStateStreamEvent = dynamic;
