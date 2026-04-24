import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:circle_hub/app.dart';

void main() {
  testWidgets('App smoke test — renders without exception', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CircleHubApp()),
    );
    expect(find.byType(CircleHubApp), findsOneWidget);
  });
}
