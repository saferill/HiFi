import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../player/player_controller.dart';
import '../widgets/mini_player.dart';
import 'browse_screen.dart';
import 'search_screen.dart';

/// Which tab the shell is showing.
class HomeTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final homeTabProvider = NotifierProvider<HomeTabNotifier, int>(
  HomeTabNotifier.new,
);

/// The app shell: a Browse tab, a Search tab, and the mini player.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(homeTabProvider);
    final playerState = ref.watch(playerControllerProvider);
    final theme = Theme.of(context);

    // Surface playback failures once, rather than silently doing nothing.
    ref.listen<PlayerState>(playerControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message == null || message == previous?.errorMessage) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: theme.colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(selectedTab == 0 ? 'HiFi' : 'Search')),
      body: IndexedStack(
        index: selectedTab,
        children: const <Widget>[BrowseScreen(), SearchScreen()],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (playerState.currentSong != null)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: MiniPlayer(),
            ),
          NavigationBar(
            selectedIndex: selectedTab,
            onDestinationSelected: (index) =>
                ref.read(homeTabProvider.notifier).select(index),
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search_rounded),
                label: 'Search',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
