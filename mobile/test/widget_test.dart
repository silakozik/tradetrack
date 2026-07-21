import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('TradeTrackApp builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const TradeTrackApp());
    await tester.pump();

    expect(find.byType(TradeTrackApp), findsOneWidget);
  });
}