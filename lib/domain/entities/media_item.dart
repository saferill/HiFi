/// Media entities for browse results, modelled on SimpMusic's `YTItem`
/// hierarchy (`kotlinYtmusicScraper/models/YTItem.kt`).
library;

class Artist {
  const Artist({required this.name, this.id});

  final String name;

  /// YouTube Music channel id (`UC…`). Null when the renderer gave no link,
  /// which happens for "Various Artists" style credits.
  final String? id;

  @override
  String toString() => 'Artist($name${id == null ? '' : ', $id'})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artist && name == other.name && id == other.id;

  @override
  int get hashCode => Object.hash(name, id);
}

class Album {
  const Album({required this.name, required this.id});

  final String name;
  final String id;

  @override
  String toString() => 'Album($name, $id)';
}

/// An album as it appears in a browse shelf. Distinct from [Album], which is
/// just the credit line attached to a song.
class AlbumItem {
  const AlbumItem({
    required this.browseId,
    required this.title,
    required this.thumbnailUrl,
    this.playlistId,
    this.artists = const <Artist>[],
    this.year,
    this.isSingle = false,
    this.isExplicit = false,
  });

  final String browseId;

  /// The `RDAMPL…` id used to play the whole album as one queue.
  final String? playlistId;
  final String title;
  final List<Artist> artists;
  final int? year;
  final bool isSingle;
  final String thumbnailUrl;
  final bool isExplicit;

  String get artistLabel => artists.isEmpty
      ? 'Unknown Artist'
      : artists.map((a) => a.name).join(', ');

  @override
  String toString() => 'AlbumItem($browseId, $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumItem &&
          browseId == other.browseId &&
          title == other.title;

  @override
  int get hashCode => Object.hash(browseId, title);
}

class PlaylistItem {
  const PlaylistItem({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.author,
    this.songCountText,
  });

  /// Playlist id, usually prefixed with `VL`.
  final String id;
  final String title;
  final Artist? author;
  final String? songCountText;
  final String thumbnailUrl;

  @override
  String toString() => 'PlaylistItem($id, $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistItem && id == other.id && title == other.title;

  @override
  int get hashCode => Object.hash(id, title);
}

class ArtistItem {
  const ArtistItem({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.subscribers,
  });

  final String id;
  final String title;
  final String thumbnailUrl;
  final String? subscribers;

  @override
  String toString() => 'ArtistItem($id, $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistItem && id == other.id && title == other.title;

  @override
  int get hashCode => Object.hash(id, title);
}

/// A Moods & Genres tile. These are not media items — they are buttons whose
/// only job is to carry the `browseId`/`params` pair of a category page.
class MoodGenre {
  const MoodGenre({
    required this.title,
    required this.browseId,
    required this.params,
    this.stripeColor,
  });

  final String title;
  final String browseId;
  final String params;

  /// Left stripe colour as a packed ARGB int, or null when absent.
  final int? stripeColor;

  @override
  String toString() => 'MoodGenre($title, $browseId)';
}
