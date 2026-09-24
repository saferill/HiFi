import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/player/now_playing_screen.dart';
import '../../presentation/screens/album_screen.dart';
import '../../presentation/screens/browse_screen.dart';
import '../../presentation/screens/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: <RouteBase>[
          // Artist pages, mood categories and "more from shelf" pages are all
          // the same browse response, so one route covers them.
          GoRoute(
            path: 'browse/:browseId',
            name: 'browse',
            builder: (context, state) => BrowseScreen(
              browseId: state.pathParameters['browseId'] ?? '',
              params: state.uri.queryParameters['params'],
            ),
          ),
          GoRoute(
            path: 'album/:browseId',
            name: 'album',
            builder: (context, state) => AlbumScreen(
              browseId: state.pathParameters['browseId'] ?? '',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/now-playing',
        name: 'nowPlaying',
        builder: (context, state) => const NowPlayingScreen(),
      ),
    ],
  );
});
