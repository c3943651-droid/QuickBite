import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('QuickBite app renders placeholder home', (tester) async {
    await tester.pumpWidget(const QuickBiteApp());

    expect(find.text('QuickBite'), findsWidgets);
  });
}