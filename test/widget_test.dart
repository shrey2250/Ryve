import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryve/main.dart';

void main() {
  testWidgets('RyveApp smoke test initializes properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RyveApp(),
      ),
    );

    expect(find.byType(RyveApp), findsOneWidget);
  });
}
