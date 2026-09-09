class Song {
  final String videoId;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final String? duration;

  const Song({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    this.duration,
  });

  @override
  String toString() {
    return 'Song(videoId: $videoId, title: $title, artist: $artist, duration: $duration, thumbnail: $thumbnailUrl)';
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
