import 'media_item.dart';

class Song {
  const Song({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    this.duration,
    this.album,
    this.isExplicit = false,
    this.setVideoId,
  });

  final String videoId;
  final String title;
  final String artist;
  final String thumbnailUrl;

  /// Human readable length as InnerTube spelled it, e.g. `3:24`.
  final String? duration;

  /// Album credit line. Null for radio mixes and music videos.
  final Album? album;

  final bool isExplicit;

  /// `playlistSetVideoId`, needed to add/remove a track inside a playlist.
  final String? setVideoId;

  /// The same length in seconds, parsed.
  ///
  /// Derived rather than stored: every parser builds a [Song] from an
  /// InnerTube duration string, and a stored field only creates a way for
  /// the two to disagree.
  int? get durationSeconds => parseDuration(duration);

  /// Parses `m:ss`, `h:mm:ss` and plain `12:34` into seconds.
  static int? parseDuration(String? text) {
    if (text == null) return null;
    final parts = text.trim().split(':');
    if (parts.isEmpty || parts.length > 3) return null;

    var seconds = 0;
    for (final part in parts) {
      final value = int.tryParse(part.trim());
      if (value == null) return null;
      seconds = seconds * 60 + value;
    }
    return seconds;
  }

  Song copyWith({
    String? videoId,
    String? title,
    String? artist,
    String? thumbnailUrl,
    String? duration,
    Album? album,
    bool? isExplicit,
    String? setVideoId,
  }) {
    return Song(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      album: album ?? this.album,
      isExplicit: isExplicit ?? this.isExplicit,
      setVideoId: setVideoId ?? this.setVideoId,
    );
  }

  @override
  String toString() {
    return 'Song(videoId: $videoId, title: $title, artist: $artist, '
        'duration: $duration, album: ${album?.name}, thumbnail: $thumbnailUrl)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song &&
          runtimeType == other.runtimeType &&
          videoId == other.videoId &&
          title == other.title &&
          artist == other.artist;

  @override
  int get hashCode => videoId.hashCode ^ title.hashCode ^ artist.hashCode;
}
