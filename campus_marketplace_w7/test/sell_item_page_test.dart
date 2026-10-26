import 'package:campus_marketplace_w7/screens/sell_item_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('disables AI analysis and explains it is unavailable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SellItemPage()));

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'AI ไม่พร้อมใช้งาน'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('ปิดการใช้งาน AI ชั่วคราว'), findsOneWidget);
  });
}
