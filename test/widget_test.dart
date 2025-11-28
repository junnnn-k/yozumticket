// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:yozumticket/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const YozumTicketApp());

    // Verify that the app starts
    expect(find.byType(YozumTicketApp), findsOneWidget);
  });
}
