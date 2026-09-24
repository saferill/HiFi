import 'package:app/core/theme/app_theme.dart';
import 'package:app/data/repositories/music_repository.dart';
import 'package:app/presentation/screens/browse_screen.dart';
import 'package:app/presentation/screens/home_screen.dart';
import 'package:app/presentation/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/fake_music_repository.dart';

void main() {
  /// Pumps the app shell against a repository that answers from memory, so
  /// these tests never touch the network.
  Future<FakeMusicRepository> pumpShell(
    WidgetTester tester, {
    FakeMusicRepository? repository,
  }) async {
    final fake = repository ?? FakeMusicRepository();
    await tester.pumpWidget(
      ProviderScope(
        // No explicit type argument: the `Override` type is not exported
        // by every Riverpod major, and inference already knows it.
        overrides: [musicRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  Finder navDestination(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  /// The shell keeps both tabs alive in an [IndexedStack], so the same title
  /// can exist twice in the tree. Every content assertion is scoped to the tab
  /// it belongs to.
  Finder inBrowse(String text) =>
      find.descendant(of: find.byType(BrowseScreen), matching: find.text(text));

  Finder inSearch(String text) =>
      find.descendant(of: find.byType(SearchScreen), matching: find.text(text));

  Future<void> goToSearch(WidgetTester tester) async {
    await tester.tap(navDestination('Search'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the browse tab and loads the home shelves', (
    WidgetTester tester,
  ) async {
    final repository = await pumpShell(tester);

    expect(repository.browseCalls, 1);
    expect(inBrowse('Quick picks'), findsOneWidget);
    expect(inBrowse('New releases'), findsOneWidget);
    expect(inBrowse('Moods & genres'), findsOneWidget);
    // The browse tab shows album art, not the search field.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('renders mood tiles, album cards and tracks from the response', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);

    expect(inBrowse('Chill'), findsOneWidget);
    expect(inBrowse('Mercury - Act 1'), findsOneWidget);
    expect(inBrowse('Imagine Dragons'), findsWidgets);
    expect(inBrowse('Bones'), findsOneWidget);
    expect(inBrowse('Enemy'), findsOneWidget);
  });

  testWidgets('switching to the search tab shows the search field', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester);
    await goToSearch(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(inSearch('Search songs, artists, albums...'), findsOneWidget);
    expect(inSearch('Search for music on YouTube Music'), findsOneWidget);
  });

  testWidgets('submitting a query renders the results', (
    WidgetTester tester,
  ) async {
    final repository = await pumpShell(tester);
    await goToSearch(tester);

    await tester.enterText(find.byType(TextField), 'imagine dragons');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(repository.searchCalls, 1);
    expect(repository.lastQuery, 'imagine dragons');
    expect(inSearch('Bones'), findsOneWidget);
    // The subtitle assembles artist and length from what the response carried.
    expect(inSearch('Imagine Dragons • 2:46'), findsOneWidget);
    // The explicit marker is rendered for flagged tracks only.
    expect(inSearch('E'), findsOneWidget);
  });

  testWidgets(
    'a failing repository shows the browse error state, not a crash',
    (WidgetTester tester) async {
      await pumpShell(
        tester,
        repository: FakeMusicRepository(failure: Exception('offline')),
      );

      expect(inBrowse('Could not load this page'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BrowseScreen),
          matching: find.widgetWithText(FilledButton, 'Retry'),
        ),
        findsOneWidget,
      );
    },
  );
}
