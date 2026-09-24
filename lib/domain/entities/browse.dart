import 'media_item.dart';
import 'song.dart';

/// One shelf of a browse response, modelled on SimpMusic's `BrowseResult.Item`
/// (`kotlinYtmusicScraper/pages/BrowseResult.kt`).
///
/// A shelf is homogeneous in practice — YouTube Music puts songs in one
/// carousel, albums in another — but the renderer is the same either way, so
/// every list is carried and only the non-empty ones are rendered.
class BrowseSection {
  const BrowseSection({
    this.title,
    this.songs = const <Song>[],
    this.albums = const <AlbumItem>[],
    this.playlists = const <PlaylistItem>[],
    this.artists = const <ArtistItem>[],
    this.moods = const <MoodGenre>[],
    this.moreBrowseId,
    this.moreParams,
  });

  final String? title;
  final List<Song> songs;
  final List<AlbumItem> albums;
  final List<PlaylistItem> playlists;
  final List<ArtistItem> artists;
  final List<MoodGenre> moods;

  /// Where the shelf's "More" button leads, when it has one.
  final String? moreBrowseId;
  final String? moreParams;

  bool get isEmpty =>
      songs.isEmpty &&
      albums.isEmpty &&
      playlists.isEmpty &&
      artists.isEmpty &&
      moods.isEmpty;
}

class BrowsePage {
  const BrowsePage({this.title, this.sections = const <BrowseSection>[]});

  final String? title;
  final List<BrowseSection> sections;

  bool get isEmpty => title == null && sections.every((s) => s.isEmpty);

  /// Every track on the page, in shelf order. Used to start a queue straight
  /// from Home without a second request.
  List<Song> get allSongs => <Song>[
    for (final section in sections) ...section.songs,
  ];
}
