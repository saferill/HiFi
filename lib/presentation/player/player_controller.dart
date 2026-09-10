import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
// ignore: unused_import
import '../../data/services/stream_service.dart';
import '../../data/services/native_stream_service.dart';
import '../../domain/entities/song.dart';

class PlayerState {
  final Song? currentSong;
  final List<Song> queue;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isLoading;
  final String? errorMessage;

  const PlayerState({
    this.currentSong,
    this.queue = const [],
    this.currentIndex = -1,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isLoading = false,
    this.errorMessage,
  });

  PlayerState copyWith({
    Song? currentSong,
    List<Song>? queue,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
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
  StreamSubscription<dynamic>? _playerStateSub;
  StreamSubscription<dynamic>? _positionSub;
  StreamSubscription<dynamic>? _durationSub;

  @override
  PlayerState build() {
    _audioPlayer = AudioPlayer();

    _playerStateSub = _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      final isBuffering = processingState == ProcessingState.buffering ||
          processingState == ProcessingState.loading;

      state = state.copyWith(
        isPlaying: isPlaying && processingState != ProcessingState.completed,
        isLoading: isBuffering,
      );

      // Auto-next when song playback completes
      if (processingState == ProcessingState.completed) {
        developer.log('Song completed, auto-playing next...', name: 'PlayerController');
        playNext();
      }
    });

    _positionSub = _audioPlayer.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _durationSub = _audioPlayer.durationStream.listen((dur) {
      state = state.copyWith(duration: dur ?? Duration.zero);
    });

    ref.onDispose(() {
      _playerStateSub?.cancel();
      _positionSub?.cancel();
      _durationSub?.cancel();
      _audioPlayer.dispose();
    });

    return const PlayerState();
  }

  void playQueue(List<Song> songs, int startIndex) {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;

    state = state.copyWith(
      queue: List<Song>.unmodifiable(songs),
      currentIndex: startIndex,
    );

    playSong(songs[startIndex], index: startIndex);
  }

  Future<void> playSong(Song song, {int? index}) async {
    final newIndex = index ??
        (state.queue.isNotEmpty ? state.queue.indexWhere((s) => s.videoId == song.videoId) : -1);

    // ignore: avoid_print
    print('[PlayerController] playSong START');
    developer.log('playSong START', name: 'PlayerController');
    // ignore: avoid_print
    print('[PlayerController] playSong requested: ${song.title} (${song.videoId})');
    developer.log('playSong requested: ${song.title} (${song.videoId})', name: 'PlayerController');

    state = state.copyWith(
      currentSong: song,
      currentIndex: newIndex != -1 ? newIndex : state.currentIndex,
      isLoading: true,
      clearError: true,
      position: Duration.zero,
      duration: Duration.zero,
    );

    try {
      // Deprecated: youtube_explode_dart diganti NewPipeExtractor native
      // final streamService = ref.read(streamServiceProvider);
      // final streamUrl = await streamService.getAudioStreamUrl(song.videoId);

      final nativeStreamService = ref.read(nativeStreamServiceProvider);
      final streamUrl = await nativeStreamService.getAudioStreamUrl(song.videoId);

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

  void playNext() {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex < state.queue.length) {
      state = state.copyWith(currentIndex: nextIndex);
      playSong(state.queue[nextIndex], index: nextIndex);
    } else {
      developer.log('End of queue reached', name: 'PlayerController');
    }
  }

  void playPrevious() {
    // If played more than 3 seconds, restart current track
    if (state.position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    final prevIndex = state.currentIndex - 1;
    if (prevIndex >= 0 && prevIndex < state.queue.length) {
      state = state.copyWith(currentIndex: prevIndex);
      playSong(state.queue[prevIndex], index: prevIndex);
    } else {
      seek(Duration.zero);
    }
  }

  Future<void> seek(Duration position) async {
    state = state.copyWith(position: position);
    await _audioPlayer.seek(position);
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
