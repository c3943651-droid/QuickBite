import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/router_harness.dart';

void main() {
  testWidgets('diagnostico inset', (tester) async {
    await pumpRouter(tester, sessionFor('cliente'));
    await settle(tester);
    final mq = tester.widget<MediaQuery>(find.byType(MediaQuery).first);
    final data = mq.data;
    // ignore: avoid_print
    print('MQ padding=${data.padding} viewPadding=${data.viewPadding}');
    // ignore: avoid_print
    print(
      'NAV rect=${tester.getRect(find.byType(NavigationBar))} dpr=${tester.view.devicePixelRatio}',
    );
  });
}
