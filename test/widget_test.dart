import 'package:app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HiFi renders correctly smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HiFiApp(),
      ),
    );

    expect(find.text('HiFi'), findsOneWidget);
  });
}
