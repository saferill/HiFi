import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/parser/radio_parser.dart';
import '../../data/repositories/music_repository.dart';
import '../../data/services/native_stream_service.dart';
import '../../data/services/stream_service.dart';
import '../../domain/entities/song.dart';

/// What happens when a track ends.
enum PlaybackRepeat {
  /// Advance to the next track, falling through to the radio when the queue
  /// runs out.
  off,

  /// Advance, and wrap back to the first track at the end of the queue.
  all,

  /// Replay the current track forever.
  one,
}

extension PlaybackRepeatLabel on PlaybackRepeat {
  String get label => switch (this) {
    PlaybackRepeat.off => 'Repeat off',
    PlaybackRepeat.all => 'Repeat queue',
    PlaybackRepeat.one => 'Repeat track',
  };
}

class PlayerState {
  const PlayerState({
    this.currentSong,
    this.queue = const <Song>[],
    this.currentIndex = -1,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.isLoading = false,
    this.isShuffleEnabled = false,
    this.isRadioEnabled = true,
    this.repeatMode = PlaybackRepeat.off,
    this.isLoadingMoreQueue = false,
    this.continuationToken,
    this.errorMessage,
  });

  final Song? currentSong;
  final List<Song> queue;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isLoading;
  final bool isShuffleEnabled;
  final bool isRadioEnabled;
  final PlaybackRepeat repeatMode;
  final bool isLoadingMoreQueue;
  final String? continuationToken;
  final String? errorMessage;

  /// Tracks left after the current one.
  int get songsRemaining =>
      currentIndex < 0 ? 0 : queue.length - 1 - currentIndex;

  bool get hasPrevious => currentIndex > 0;

  bool get hasNext => currentIndex + 1 < queue.length || isRadioEnabled;

  PlayerState copyWith({
    Song? currentSong,
    List<Song>? queue,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isLoading,
    bool? isShuffleEnabled,
    bool? isRadioEnabled,
    PlaybackRepeat? repeatMode,
    bool? isLoadingMoreQueue,
    String? continuationToken,
    String? errorMessage,
    bool clearError = false,
    bool clearContinuation = false,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      isRadioEnabled: isRadioEnabled ?? this.isRadioEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      isLoadingMoreQueue: isLoadingMoreQueue ?? this.isLoadingMoreQueue,
      continuationToken: clearContinuation
          ? null
          : (continuationToken ?? this.continuationToken),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);

class PlayerController extends Notifier<PlayerState> {
  static const String _logName = 'PlayerController';

  /// How many upcoming tracks may remain before the radio tops the queue up.
  static const int _radioRefillThreshold = 4;

  late final AudioPlayer _audioPlayer;
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  /// Incremented for every [playSong]. A response that arrives after a newer
  /// request has started is discarded, so double-tapping a track can no longer
  /// leave the audio on the first one while the UI shows the second.
  int _loadToken = 0;

  @override
  PlayerState build() {
    _audioPlayer = AudioPlayer();

    _subscriptions.add(
      _audioPlayer.playerStateStream.listen((playerState) {
        final processingState = playerState.processingState;
        final isBuffering =
            processingState == ProcessingState.buffering ||
            processingState == ProcessingState.loading;

        state = state.copyWith(
          isPlaying:
              playerState.playing &&
              processingState != ProcessingState.completed,
          isLoading: isBuffering,
        );

        if (processingState == ProcessingState.completed) {
          developer.log('Track completed, advancing', name: _logName);
          playNext(auto: true);
        }
      }),
    );

    _subscriptions.add(
      _audioPlayer.positionStream.listen((pos) {
        state = state.copyWith(position: pos);
      }),
    );

    _subscriptions.add(
      _audioPlayer.durationStream.listen((dur) {
        state = state.copyWith(duration: dur ?? Duration.zero);
      }),
    );

    ref.onDispose(() {
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _audioPlayer.dispose();
    });

    return const PlayerState();
  }

  /// Replaces the queue and starts playing the track at [startIndex].
  void playQueue(List<Song> songs, int startIndex) {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;

    state = state.copyWith(
      queue: List<Song>.unmodifiable(songs),
      currentIndex: startIndex,
      clearContinuation: true,
    );

    playSong(songs[startIndex], index: startIndex);
  }

  Future<void> playSong(Song song, {int? index}) async {
    final existingIndex = state.queue.indexWhere(
      (s) => s.videoId == song.videoId,
    );
    final newIndex =
        index ??
        (existingIndex != -1
            ? existingIndex
            : (state.queue.isEmpty ? 0 : state.queue.length));

    final updatedQueue = state.queue.isEmpty
        ? <Song>[song]
        : (existingIndex == -1 ? <Song>[...state.queue, song] : state.queue);

    state = state.copyWith(
      currentSong: song,
      queue: updatedQueue,
      currentIndex: newIndex,
      isLoading: true,
      clearError: true,
      position: Duration.zero,
      duration: Duration.zero,
    );

    final token = ++_loadToken;
    developer.log('Loading ${song.title} (${song.videoId})', name: _logName);

    try {
      final streamUrl = await _resolveStreamUrl(song.videoId);
      if (token != _loadToken) {
        developer.log(
          'Discarding stale load for ${song.videoId}',
          name: _logName,
        );
        return;
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        _fail(song, 'Gagal mendapatkan audio stream untuk "${song.title}"');
        return;
      }

      await _audioPlayer.setUrl(
        streamUrl,
        headers: <String, String>{
          'User-Agent': 'com.google.android.apps.youtube.music/7.27.52 (Linux; U; Android 11) gzip',
        },
      );
      if (token != _loadToken) return;

      await _audioPlayer.play();

      state = state.copyWith(
        isLoading: false,
        isPlaying: true,
        clearError: true,
      );

      // Top the queue up before it runs dry.
      unawaited(_checkAndFetchRadioQueue());
    } catch (e, stack) {
      developer.log(
        'Playback failed for ${song.title}',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
      if (token == _loadToken) {
        _fail(song, 'Playback error: $e');
      }
    }
  }

  void _fail(Song song, String message) {
    state = state.copyWith(
      isLoading: false,
      isPlaying: false,
      errorMessage: message,
    );
    developer.log(message, name: _logName, error: song.videoId);
  }

  /// Resolves a playable URL, preferring the native extractor and falling back
  /// to the Dart one.
  ///
  /// The two used to be competing implementations with only the native one
  /// wired up, so the app had no audio at all on platforms where the
  /// `com.hifi.app/stream` channel is not implemented. Trying both in order
  /// mirrors how SimpMusic walks its extractor chain.
  Future<String?> _resolveStreamUrl(String videoId) async {
    final native = ref.read(nativeStreamServiceProvider);
    final nativeUrl = await native.getAudioStreamUrl(videoId);
    if (nativeUrl != null && nativeUrl.isNotEmpty) {
      developer.log('Stream via native extractor', name: _logName);
      return nativeUrl;
    }

    developer.log(
      'Native extractor returned nothing for $videoId, falling back',
      name: _logName,
    );
    return ref.read(streamServiceProvider).getAudioStreamUrl(videoId);
  }

  /// Advances the queue.
  ///
  /// [auto] is set when the track ended on its own, which is what makes
  /// [PlaybackRepeat.one] meaningful — a manual "next" should still move on.
  void playNext({bool auto = false}) {
    if (auto && state.repeatMode == PlaybackRepeat.one) {
      unawaited(seek(Duration.zero));
      unawaited(_audioPlayer.play());
      return;
    }

    final nextIndex = state.currentIndex + 1;
    if (nextIndex < state.queue.length) {
      playSong(state.queue[nextIndex], index: nextIndex);
      return;
    }

    if (state.repeatMode == PlaybackRepeat.all && state.queue.isNotEmpty) {
      playSong(state.queue.first, index: 0);
      return;
    }

    if (state.isRadioEnabled && state.currentSong != null) {
      // Queue exhausted: fetch more before the silence becomes audible.
      unawaited(_fetchRadioQueueAndPlayNext());
      return;
    }

    developer.log('End of queue reached', name: _logName);
  }

  void playPrevious() {
    // Restart the track unless we are already at its start.
    if (state.position.inSeconds > 3) {
      unawaited(seek(Duration.zero));
      return;
    }

    final prevIndex = state.currentIndex - 1;
    if (prevIndex >= 0 && prevIndex < state.queue.length) {
      playSong(state.queue[prevIndex], index: prevIndex);
    } else if (state.repeatMode == PlaybackRepeat.all &&
        state.queue.isNotEmpty) {
      final lastIndex = state.queue.length - 1;
      playSong(state.queue[lastIndex], index: lastIndex);
    } else {
      unawaited(seek(Duration.zero));
    }
  }

  void toggleShuffle() {
    final newShuffleState = !state.isShuffleEnabled;

    if (newShuffleState && state.queue.isNotEmpty && state.currentIndex >= 0) {
      // Shuffle only what has not been played yet, so the current track stays
      // put and the history is preserved.
      final played = state.queue.sublist(0, state.currentIndex + 1);
      final upcoming = state.queue.sublist(state.currentIndex + 1).toList()
        ..shuffle();

      state = state.copyWith(
        isShuffleEnabled: true,
        queue: <Song>[...played, ...upcoming],
      );
      developer.log('Shuffled upcoming tracks', name: _logName);
      return;
    }

    state = state.copyWith(isShuffleEnabled: newShuffleState);
  }

  /// Cycles off → all → one → off.
  void cycleRepeatMode() {
    final next = switch (state.repeatMode) {
      PlaybackRepeat.off => PlaybackRepeat.all,
      PlaybackRepeat.all => PlaybackRepeat.one,
      PlaybackRepeat.one => PlaybackRepeat.off,
    };
    state = state.copyWith(repeatMode: next);
    developer.log('Repeat mode: ${next.label}', name: _logName);
  }

  void toggleRadioMode() {
    final newRadioState = !state.isRadioEnabled;
    state = state.copyWith(isRadioEnabled: newRadioState);
    if (newRadioState) {
      unawaited(_checkAndFetchRadioQueue());
    }
  }

  /// Appends radio tracks when the queue is running low. Never starts playback.
  Future<void> _checkAndFetchRadioQueue() async {
    if (!state.isRadioEnabled || state.isLoadingMoreQueue) return;
    final current = state.currentSong;
    if (current == null) return;
    if (state.songsRemaining > _radioRefillThreshold) return;

    state = state.copyWith(isLoadingMoreQueue: true);

    try {
      final result = await ref
          .read(musicRepositoryProvider)
          .getRadioTracks(
            current.videoId,
            continuation: state.continuationToken,
          );
      _appendRadioSongs(result);
    } catch (e, stack) {
      developer.log(
        'Failed to fetch radio tracks',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
    } finally {
      state = state.copyWith(isLoadingMoreQueue: false);
    }
  }

  /// Fetches radio tracks and immediately plays the first new one.
  Future<void> _fetchRadioQueueAndPlayNext() async {
    if (state.isLoadingMoreQueue) return;
    final current = state.currentSong;
    if (current == null) return;

    state = state.copyWith(isLoadingMoreQueue: true);

    try {
      final result = await ref
          .read(musicRepositoryProvider)
          .getRadioTracks(
            current.videoId,
            continuation: state.continuationToken,
          );
      final appended = _appendRadioSongs(result);

      if (appended > 0) {
        final nextIndex = state.queue.length - appended;
        playSong(state.queue[nextIndex], index: nextIndex);
      }
    } catch (e, stack) {
      developer.log(
        'Failed to extend the radio queue',
        name: _logName,
        error: e,
        stackTrace: stack,
      );
    } finally {
      state = state.copyWith(isLoadingMoreQueue: false);
    }
  }

  /// Adds the tracks from [result] that are not already queued.
  ///
  /// Returns how many were added so the caller knows where they start.
  int _appendRadioSongs(RadioResult result) {
    final existingIds = state.queue.map((s) => s.videoId).toSet();
    final newSongs = result.songs
        .where((s) => !existingIds.contains(s.videoId))
        .toList();

    if (newSongs.isEmpty) return 0;

    if (state.isShuffleEnabled) {
      newSongs.shuffle();
    }

    state = state.copyWith(
      queue: <Song>[...state.queue, ...newSongs],
      continuationToken: result.continuationToken,
    );
    developer.log(
      'Appended ${newSongs.length} radio tracks, queue is now '
      '${state.queue.length}',
      name: _logName,
    );
    return newSongs.length;
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
