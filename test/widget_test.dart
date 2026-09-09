import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HiFi search screen renders search bar and placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HiFiApp(),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search songs, artists, albums...'), findsOneWidget);
    expect(find.text('Search for music on YouTube Music'), findsOneWidget);
  });
}
