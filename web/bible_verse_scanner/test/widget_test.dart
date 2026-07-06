import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bible_verse_scanner/main.dart';

void main() {
  testWidgets('App starts and shows a loading indicator', (WidgetTester tester) async {
    await tester.pumpWidget(const BibleVerseScannerApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
