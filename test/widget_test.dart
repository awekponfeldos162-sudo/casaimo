import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casaimo/main.dart';

void main() {
  testWidgets('CasaImo app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CasaImoApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
