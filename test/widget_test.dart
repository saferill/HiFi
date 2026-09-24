import 'package:app/core/theme/app_theme.dart';
import 'package:app/data/repositories/music_repository.dart';
import 'package:app/presentation/screens/home_screen.dart';
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
        // uniformly across Riverpod majors, and inference already knows it.
        overrides: [musicRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  Finder navDestination(String label) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );

  testWidgets('opens on the browse tab and loads the home shelves',
      (WidgetTester tester) async {
    final repository = await pumpShell(tester);

    expect(repository.browseCalls, 1);
    expect(find.text('Quick picks'), findsOneWidget);
    expect(find.text('New releases'), findsOneWidget);
    expect(find.text('Moods & genres'), findsOneWidget);
    // The browse tab shows album art, not the search field.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('shows a mood tile and an album card from the response',
      (WidgetTester tester) async {
    await pumpShell(tester);

    expect(find.text('Chill'), findsOneWidget);
    expect(find.text('Mercury - Act 1'), findsOneWidget);
    expect(find.text('Bones'), findsOneWidget);
    expect(find.text('Enemy'), findsOneWidget);
  });

  testWidgets('switching to the search tab shows the search field',
      (WidgetTester tester) async {
    await pumpShell(tester);

    await tester.tap(navDestination('Search'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search songs, artists, albums...'), findsOneWidget);
    expect(
      find.text('Search for music on YouTube Music'),
      findsOneWidget,
    );
  });

  testWidgets('submitting a query renders the results', (WidgetTester tester) async {
    final repository = await pumpShell(tester);

    await tester.tap(navDestination('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'imagine dragons');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(repository.searchCalls, 1);
    expect(repository.lastQuery, 'imagine dragons');
    expect(find.text('Bones'), findsOneWidget);
    // The subtitle assembles artist and length.
    expect(find.text('Imagine Dragons • 2:46'), findsOneWidget);
    // The explicit marker is rendered for flagged tracks.
    expect(find.text('E'), findsOneWidget);
  });

  testWidgets('a failing repository shows the browse error state, not a crash',
      (WidgetTester tester) async {
    await pumpShell(
      tester,
      repository: FakeMusicRepository(failure: Exception('offline')),
    );

    expect(find.text('Could not load this page'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
  });
}
