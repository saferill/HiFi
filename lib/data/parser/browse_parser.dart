import '../../domain/entities/browse.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/song.dart';
import 'renderer_utils.dart';

/// Parses a `browse` response into [BrowsePage].
///
/// Handles the Home feed (`FEmusic_home`), Moods & Genres categories
/// (`FEmusic_moods_and_genres_category`), Charts (`FEmusic_charts`) and the
/// "more from this shelf" pages, all of which share the same shelf renderers.
/// Ported from SimpMusic's `HomeParser` / `MoodsGenresParser`.
BrowsePage parseBrowsePage(Map<String, dynamic> rawJson) {
  try {
    final shelves = _findShelves(rawJson);
    if (shelves == null) return const BrowsePage();

    final sections = <BrowseSection>[];
    for (final shelf in shelves) {
      final map = asMap(shelf);
      if (map == null) continue;

      final section = _parseShelf(map);
      if (section != null && !section.isEmpty) {
        sections.add(section);
      }
    }

    return BrowsePage(title: _pageTitle(rawJson), sections: sections);
  } catch (_) {
    // A schema change should degrade to an empty page, never crash the screen.
    return const BrowsePage();
  }
}

String? _pageTitle(Map<String, dynamic> rawJson) {
  final singleColumn = dig(rawJson, <String>[
    'contents',
    'singleColumnBrowseResultsRenderer',
  ]);
  if (singleColumn != null) {
    final title = digValue(singleColumn, <String>[
      'tabs',
    ]);
    final tabs = asList(title);
    if (tabs != null) {
      for (final tab in tabs) {
        final text = runsToText(
          digValue(tab, <String>['tabRenderer', 'title']),
        );
        if (text != null) return text;
        final endpointTitle = asMap(tab)?['tabRenderer']?['title'];
        if (endpointTitle is String && endpointTitle.isNotEmpty) {
          return endpointTitle;
        }
      }
    }
    return null;
  }

  final header = dig(rawJson, <String>[
    'contents',
    'twoColumnBrowseResultsRenderer',
  ]);
  if (header != null) {
    return runsToText(digValue(header, <String>[
      'tabs',
    ])) ??
        _twoColumnTitle(rawJson);
  }
  return null;
}

String? _twoColumnTitle(Map<String, dynamic> rawJson) =>
    runsToText(digValue(rawJson, <String>[
      'header',
      'musicHeaderRenderer',
      'title',
    ]));

/// Locates the list of shelves, tolerating both single- and two-column layouts.
List<dynamic>? _findShelves(Map<String, dynamic> rawJson) {
  final candidates = <List<String>>[
    <String>[
      'contents',
      'singleColumnBrowseResultsRenderer',
      'tabs',
    ],
    <String>[
      'contents',
      'twoColumnBrowseResultsRenderer',
      'tabs',
    ],
  ];

  for (final path in candidates) {
    final tabs = asList(digValue(rawJson, path));
    if (tabs == null) continue;

    for (final tab in tabs) {
      final sectionList = asList(digValue(tab, <String>[
        'tabRenderer',
        'content',
        'sectionListRenderer',
        'contents',
      ]));
      if (sectionList != null) return sectionList;
    }
  }

  // A continuation response carries shelves directly.
  return asList(digValue(rawJson, <String>[
    'continuationContents',
    'sectionListContinuation',
    'contents',
  ]));
}

BrowseSection? _parseShelf(Map<String, dynamic> shelf) {
  for (final key in shelf.keys) {
    final body = asMap(shelf[key]);
    if (body == null) continue;

    switch (key) {
      case 'musicCarouselShelfRenderer':
      case 'musicImmersiveCarouselShelfRenderer':
        return _parseCarousel(body);
      case 'musicShelfRenderer':
      case 'musicPlaylistShelfRenderer':
        return _parseListShelf(body);
      case 'gridRenderer':
        return _parseGrid(body);
      case 'musicResponsiveListItemRenderer':
        final song = parseListSong(body);
        return song == null
            ? null
            : BrowseSection(songs: <Song>[song]);
      case 'musicTwoRowItemRenderer':
        return _sectionFromTwoRow(body);
    }
  }
  return null;
}

BrowseSection _parseCarousel(Map<String, dynamic> body) {
  final header = dig(body, <String>[
    'header',
    'musicCarouselShelfBasicHeaderRenderer',
  ]);

  final moreBrowseId = digValue(header, <String>[
    'moreContentButton',
    'buttonRenderer',
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ]);
  final moreParams = digValue(header, <String>[
    'moreContentButton',
    'buttonRenderer',
    'navigationEndpoint',
    'browseEndpoint',
    'params',
  ]);

  return _sectionFromItems(
    title: runsToText(digValue(header, <String>['title', 'runs'])),
    items: asList(body['contents']),
    moreBrowseId: moreBrowseId is String ? moreBrowseId : null,
    moreParams: moreParams is String ? moreParams : null,
  );
}

BrowseSection _parseListShelf(Map<String, dynamic> body) {
  return _sectionFromItems(
    title: runsToText(digValue(body, <String>['title', 'runs'])),
    items: asList(body['contents']),
  );
}

BrowseSection _parseGrid(Map<String, dynamic> body) {
  final moods = <MoodGenre>[];
  for (final item in asList(body['items']) ?? const <dynamic>[]) {
    final renderer = asMap(item)?['musicNavigationButtonRenderer'];
    final mood = _parseMoodButton(asMap(renderer));
    if (mood != null) moods.add(mood);
  }

  return BrowseSection(
    title: runsToText(digValue(body, <String>[
      'header',
      'gridHeaderRenderer',
      'title',
      'runs',
    ])),
    moods: moods,
  );
}

MoodGenre? _parseMoodButton(Map<String, dynamic>? renderer) {
  if (renderer == null) return null;

  final browseEndpoint = dig(renderer, <String>[
    'clickCommand',
    'browseEndpoint',
  ]);
  final browseId = browseEndpoint?['browseId'];
  final params = browseEndpoint?['params'];
  final title = runsToText(digValue(renderer, <String>['buttonText', 'runs']));

  if (browseId is! String || browseId.isEmpty || title == null) return null;

  final stripe = digValue(renderer, <String>['solid', 'leftStripeColor']);

  return MoodGenre(
    title: title,
    browseId: browseId,
    params: params is String ? params : '',
    stripeColor: stripe is num ? stripe.toInt() : null,
  );
}

BrowseSection? _sectionFromTwoRow(Map<String, dynamic> renderer) {
  final album = parseTwoRowAlbum(renderer);
  if (album != null) {
    return BrowseSection(albums: <AlbumItem>[album]);
  }
  final playlist = parseTwoRowPlaylist(renderer);
  if (playlist != null) {
    return BrowseSection(playlists: <PlaylistItem>[playlist]);
  }
  final artist = parseTwoRowArtist(renderer);
  if (artist != null) {
    return BrowseSection(artists: <ArtistItem>[artist]);
  }
  final song = parseTwoRowSong(renderer);
  if (song != null) {
    return BrowseSection(songs: <Song>[song]);
  }
  return null;
}

BrowseSection _sectionFromItems({
  String? title,
  List<dynamic>? items,
  String? moreBrowseId,
  String? moreParams,
}) {
  final songs = <Song>[];
  final albums = <AlbumItem>[];
  final playlists = <PlaylistItem>[];
  final artists = <ArtistItem>[];

  for (final item in items ?? const <dynamic>[]) {
    final map = asMap(item);
    if (map == null) continue;

    final twoRow = asMap(map['musicTwoRowItemRenderer']);
    if (twoRow != null) {
      final album = parseTwoRowAlbum(twoRow);
      if (album != null) {
        albums.add(album);
        continue;
      }
      final playlist = parseTwoRowPlaylist(twoRow);
      if (playlist != null) {
        playlists.add(playlist);
        continue;
      }
      final artist = parseTwoRowArtist(twoRow);
      if (artist != null) {
        artists.add(artist);
        continue;
      }
      final song = parseTwoRowSong(twoRow);
      if (song != null) songs.add(song);
      continue;
    }

    final listRow = asMap(map['musicResponsiveListItemRenderer']);
    if (listRow != null) {
      final song = parseListSong(listRow);
      if (song != null) songs.add(song);
    }
  }

  return BrowseSection(
    title: title,
    songs: songs,
    albums: albums,
    playlists: playlists,
    artists: artists,
    moreBrowseId: moreBrowseId,
    moreParams: moreParams,
  );
}

/// A carousel card for an album. Returns null when the card is not an album,
/// which is how the caller dispatches on card type.
AlbumItem? parseTwoRowAlbum(Map<String, dynamic> renderer) {
  final pageType = twoRowPageType(renderer);
  if (pageType != 'MUSIC_PAGE_TYPE_ALBUM' &&
      pageType != 'MUSIC_PAGE_TYPE_AUDIOBOOK') {
    return null;
  }

  final browseId = digValue(renderer, <String>[
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ]);
  final title = firstRunText(digValue(renderer, <String>['title', 'runs']));
  if (browseId is! String || browseId.isEmpty || title == null) return null;

  final subtitleRuns = asList(digValue(renderer, <String>['subtitle', 'runs']));
  final artists = parseArtists(subtitleRuns);
  final year = _extractYear(subtitleRuns);
  final playlistId = _playButtonPlaylistId(renderer);

  return AlbumItem(
    browseId: browseId,
    playlistId: playlistId,
    title: title,
    artists: artists,
    year: year,
    isSingle: _isSingle(runsToText(subtitleRuns)),
    thumbnailUrl: twoRowThumbnail(renderer) ?? '',
    isExplicit: hasExplicitBadge(renderer['subtitleBadges']),
  );
}

PlaylistItem? parseTwoRowPlaylist(Map<String, dynamic> renderer) {
  final pageType = twoRowPageType(renderer);
  if (pageType != 'MUSIC_PAGE_TYPE_PLAYLIST') return null;

  final browseId = digValue(renderer, <String>[
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ]);
  final title = firstRunText(digValue(renderer, <String>['title', 'runs']));
  if (browseId is! String || browseId.isEmpty || title == null) return null;

  final subtitleRuns = asList(digValue(renderer, <String>['subtitle', 'runs']));
  final credits = parseArtists(subtitleRuns);

  return PlaylistItem(
    id: browseId,
    title: title,
    author: credits.isEmpty ? null : credits.first,
    songCountText: _extractSongCount(subtitleRuns),
    thumbnailUrl: twoRowThumbnail(renderer) ?? '',
  );
}

ArtistItem? parseTwoRowArtist(Map<String, dynamic> renderer) {
  final pageType = twoRowPageType(renderer);
  if (pageType != 'MUSIC_PAGE_TYPE_ARTIST' &&
      pageType != 'MUSIC_PAGE_TYPE_USER_CHANNEL') {
    return null;
  }

  final browseId = digValue(renderer, <String>[
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ]);
  final title = firstRunText(digValue(renderer, <String>['title', 'runs']));
  if (browseId is! String || browseId.isEmpty || title == null) return null;

  return ArtistItem(
    id: browseId,
    title: title,
    thumbnailUrl: twoRowThumbnail(renderer) ?? '',
    subscribers: runsToText(digValue(renderer, <String>['subtitle', 'runs'])),
  );
}

/// A carousel card for a single track or music video.
Song? parseTwoRowSong(Map<String, dynamic> renderer) {
  final watchEndpoint = dig(renderer, <String>[
    'navigationEndpoint',
    'watchEndpoint',
  ]);

  String? videoId = watchEndpoint?['videoId'] as String?;
  if (videoId == null || videoId.isEmpty) {
    videoId = digValue(renderer, <String>[
      'thumbnailOverlay',
      'musicItemThumbnailOverlayRenderer',
      'content',
      'musicPlayButtonRenderer',
      'playNavigationEndpoint',
      'watchEndpoint',
      'videoId',
    ]) as String?;
  }

  final title = firstRunText(digValue(renderer, <String>['title', 'runs']));
  if (videoId == null || videoId.isEmpty || title == null) return null;

  final subtitleRuns = asList(digValue(renderer, <String>['subtitle', 'runs']));
  final artists = parseArtists(subtitleRuns);
  final duration = _extractDuration(subtitleRuns);

  return Song(
    videoId: videoId,
    title: title,
    artist: artists.isEmpty ? 'Unknown Artist' : artists.first.name,
    thumbnailUrl: twoRowThumbnail(renderer) ?? '',
    duration: duration,
    durationSeconds: durationToSeconds(duration),
    album: _extractAlbumCredit(subtitleRuns),
    isExplicit: hasExplicitBadge(renderer['subtitleBadges']),
  );
}

/// A list row (`musicResponsiveListItemRenderer`) as a track.
Song? parseListSong(Map<String, dynamic> renderer) {
  final flexColumns = asList(renderer['flexColumns']);
  if (flexColumns == null || flexColumns.isEmpty) return null;

  final title = firstRunText(digValue(flexColumns.first, <String>[
    'musicResponsiveListItemFlexColumnRenderer',
    'text',
    'runs',
  ]));
  if (title == null) return null;

  final videoId = _listRowVideoId(renderer, flexColumns);
  if (videoId == null || videoId.isEmpty) return null;

  final subtitleRuns = asList(
    flexColumns.length > 1
        ? digValue(flexColumns[1], <String>[
            'musicResponsiveListItemFlexColumnRenderer',
            'text',
            'runs',
          ])
        : null,
  );
  final artists = parseArtists(subtitleRuns);
  final duration = _durationFromListRow(renderer, subtitleRuns);
  final setVideoId = renderer['playlistItemData']?['playlistSetVideoId'];

  return Song(
    videoId: videoId,
    title: title,
    artist: artists.isEmpty ? 'Unknown Artist' : artists.first.name,
    thumbnailUrl: listItemThumbnail(renderer) ?? '',
    duration: duration,
    durationSeconds: durationToSeconds(duration),
    album: _extractAlbumCredit(subtitleRuns),
    isExplicit: hasExplicitBadge(renderer['badges']),
    setVideoId: setVideoId is String ? setVideoId : null,
  );
}

String? _listRowVideoId(
  Map<String, dynamic> renderer,
  List<dynamic> flexColumns,
) {
  final direct = renderer['playlistItemData']?['videoId'];
  if (direct is String && direct.isNotEmpty) return direct;

  final fromEndpoint = digValue(renderer, <String>[
    'navigationEndpoint',
    'watchEndpoint',
    'videoId',
  ]);
  if (fromEndpoint is String && fromEndpoint.isNotEmpty) return fromEndpoint;

  final fromOverlay = digValue(renderer, <String>[
    'overlay',
    'musicItemThumbnailOverlayRenderer',
    'content',
    'musicPlayButtonRenderer',
    'playNavigationEndpoint',
    'watchEndpoint',
    'videoId',
  ]);
  if (fromOverlay is String && fromOverlay.isNotEmpty) return fromOverlay;

  final fromTitleRun = digValue(flexColumns.first, <String>[
    'musicResponsiveListItemFlexColumnRenderer',
    'text',
    'runs',
  ]);
  final runs = asList(fromTitleRun);
  if (runs != null && runs.isNotEmpty) {
    final fromRun = digValue(runs.first, <String>[
      'navigationEndpoint',
      'watchEndpoint',
      'videoId',
    ]);
    if (fromRun is String && fromRun.isNotEmpty) return fromRun;
  }
  return null;
}

String? _extractDuration(List<dynamic>? subtitleRuns) {
  for (final run in subtitleRuns ?? const <dynamic>[]) {
    final text = asMap(run)?['text'];
    if (text is! String) continue;
    final trimmed = text.trim();
    if (RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(trimmed)) return trimmed;
  }
  return null;
}

String? _durationFromListRow(
  Map<String, dynamic> renderer,
  List<dynamic>? subtitleRuns,
) {
  final fixed = digValue(renderer, <String>[
    'fixedColumns',
  ]);
  final columns = asList(fixed);
  if (columns != null && columns.isNotEmpty) {
    final text = runsToText(digValue(columns.first, <String>[
      'musicResponsiveListItemFixedColumnRenderer',
      'text',
      'runs',
    ]));
    if (text != null && RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(text)) {
      return text;
    }
  }
  return _extractDuration(subtitleRuns);
}

Album? _extractAlbumCredit(List<dynamic>? subtitleRuns) {
  final runs = asList(subtitleRuns);
  if (runs == null) return null;

  for (final run in runs) {
    final browseId = digValue(run, <String>[
      'navigationEndpoint',
      'browseEndpoint',
      'browseId',
    ]);
    if (browseId is! String || !browseId.startsWith('MPRE')) continue;

    final text = asMap(run)?['text'];
    if (text is String && text.trim().isNotEmpty) {
      return Album(name: text.trim(), id: browseId);
    }
  }
  return null;
}

int? _extractYear(List<dynamic>? subtitleRuns) {
  for (final run in subtitleRuns ?? const <dynamic>[]) {
    final text = asMap(run)?['text'];
    if (text is! String) continue;
    final trimmed = text.trim();
    if (RegExp(r'^(19|20)\d{2}$').hasMatch(trimmed)) {
      return int.tryParse(trimmed);
    }
  }
  return null;
}

String? _extractSongCount(List<dynamic>? subtitleRuns) {
  for (final run in subtitleRuns ?? const <dynamic>[]) {
    final text = asMap(run)?['text'];
    if (text is! String) continue;
    final trimmed = text.trim();
    if (RegExp(r'\d+\s*(songs?|tracks?)', caseSensitive: false)
        .hasMatch(trimmed)) {
      return trimmed;
    }
  }
  return null;
}

bool _isSingle(String? subtitleText) {
  if (subtitleText == null) return false;
  final lower = subtitleText.toLowerCase();
  return lower.contains('single') || lower.contains('ep');
}

/// Playlist id from the card's play button. The 2026 web schema moved this from
/// `watchPlaylistEndpoint` to `watchEndpoint`, so both are read.
String? _playButtonPlaylistId(Map<String, dynamic> renderer) {
  final playEndpoint = dig(renderer, <String>[
    'thumbnailOverlay',
    'musicItemThumbnailOverlayRenderer',
    'content',
    'musicPlayButtonRenderer',
    'playNavigationEndpoint',
  ]);
  if (playEndpoint == null) return null;

  final fromPlaylist = playEndpoint['watchPlaylistEndpoint']?['playlistId'];
  if (fromPlaylist is String && fromPlaylist.isNotEmpty) return fromPlaylist;

  final fromWatch = digValue(playEndpoint, <String>[
    'watchEndpoint',
    'playlistId',
  ]);
  return fromWatch is String && fromWatch.isNotEmpty ? fromWatch : null;
}
