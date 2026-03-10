import 'package:alarms_oss/src/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders sprint 1 shell', (tester) async {
    await tester.pumpWidget(const AlarmApp());

    expect(find.text('alarms-oss'), findsOneWidget);
    expect(find.text('Sprint 1 focus'), findsOneWidget);
  });
}
