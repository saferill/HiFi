import 'package:app/core/network/innertube_client.dart';
import 'package:app/data/parser/album_parser.dart';
import 'package:app/data/parser/radio_parser.dart';
import 'package:app/data/repositories/music_repository.dart';
import 'package:app/data/services/stream_service.dart';
import 'package:app/domain/entities/browse.dart';
import 'package:app/domain/entities/media_item.dart';
import 'package:app/domain/entities/search_suggestion.dart';
import 'package:app/domain/entities/song.dart';

/// A [MusicRepository] that answers from memory.
///
/// Widget tests must not touch YouTube: the fixture data is fixed, and a live
/// request makes the test depend on the network and on YouTube's mood. The real
/// client and stream service are still constructed because the base class needs
/// them, but nothing in these tests reaches them — every method is overridden.
class FakeMusicRepository extends MusicRepository {
  FakeMusicRepository({
    BrowsePage? browsePage,
    List<Song>? searchResults,
    List<SearchSuggestion>? suggestions,
    AlbumPageResult? albumPage,
    this.failure,
  }) : _browsePage = browsePage ?? defaultBrowsePage(),
       _searchResults = searchResults ?? defaultSongs(),
       _suggestions = suggestions ?? defaultSuggestions(),
       _albumPage = albumPage,
       super(
         innertubeClient: InnertubeClient(),
         streamService: StreamService(),
       );

  final BrowsePage _browsePage;
  final List<Song> _searchResults;
  final List<SearchSuggestion> _suggestions;
  final AlbumPageResult? _albumPage;

  /// When set, every call throws it — used to exercise the error states.
  final Object? failure;

  int browseCalls = 0;
  int searchCalls = 0;
  String? lastQuery;

  @override
  Future<BrowsePage> getBrowsePage(
    String browseId, {
    String? params,
    String? countryCode,
  }) async {
    browseCalls++;
    if (failure != null) throw failure!;
    return _browsePage;
  }

  @override
  Future<List<Song>> searchSongs(
    String query, {
    String? params,
    String? continuation,
  }) async {
    searchCalls++;
    lastQuery = query;
    if (failure != null) throw failure!;
    return _searchResults;
  }

  @override
  Future<List<SearchSuggestion>> getSearchSuggestions(String input) async {
    if (failure != null) throw failure!;
    return _suggestions;
  }

  @override
  Future<AlbumPageResult?> getAlbumPage(String browseId) async {
    if (failure != null) throw failure!;
    return _albumPage;
  }

  @override
  Future<RadioResult> getRadioTracks(
    String videoId, {
    String? playlistId,
    String? continuation,
  }) async {
    if (failure != null) throw failure!;
    return const RadioResult(songs: <Song>[]);
  }
}

/// Artwork URLs are left empty on purpose: `Image.network` is not available in
/// widget tests, and an empty URL renders the built-in placeholder instead.
List<Song> defaultSongs() => const <Song>[
  Song(
    videoId: 'TO-_3tck2tg',
    title: 'Bones',
    artist: 'Imagine Dragons',
    thumbnailUrl: '',
    duration: '2:46',
    durationSeconds: 166,
  ),
  Song(
    videoId: 'D9G1VOjN_84',
    title: 'Enemy',
    artist: 'Imagine Dragons',
    thumbnailUrl: '',
    duration: '3:53',
    durationSeconds: 233,
    isExplicit: true,
  ),
];

List<SearchSuggestion> defaultSuggestions() => const <SearchSuggestion>[
  SearchSuggestion(query: 'imagine dragons bones'),
  SearchSuggestion(query: 'Bones', videoId: 'TO-_3tck2tg'),
];

BrowsePage defaultBrowsePage() => BrowsePage(
  title: 'Home',
  sections: <BrowseSection>[
    BrowseSection(title: 'Quick picks', songs: defaultSongs()),
    BrowseSection(
      title: 'New releases',
      albums: <AlbumItem>[
        const AlbumItem(
          browseId: 'MPREb_9nqEki4ZLQ4',
          title: 'Mercury - Act 1',
          thumbnailUrl: '',
          artists: <Artist>[
            Artist(name: 'Imagine Dragons', id: 'UCB0JSO6d5ysH2Mmqz5I9rIw'),
          ],
          year: 2021,
        ),
      ],
    ),
    BrowseSection(
      title: 'Moods & genres',
      moods: <MoodGenre>[
        const MoodGenre(
          title: 'Chill',
          browseId: 'FEmusic_moods_and_genres_category',
          params: 'ggMPOg1uX1JOQWZR',
          stripeColor: 0xFF00A0A0,
        ),
      ],
    ),
  ],
);

AlbumPageResult defaultAlbumPage() => AlbumPageResult(
  album: const AlbumItem(
    browseId: 'MPREb_9nqEki4ZLQ4',
    title: 'Mercury - Act 1',
    thumbnailUrl: '',
    artists: <Artist>[Artist(name: 'Imagine Dragons')],
    year: 2021,
  ),
  songs: defaultSongs(),
);
