import 'package:flutter_test/flutter_test.dart';
import 'package:study_monitor/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const StudyMonitorApp());
    expect(find.text('Study'), findsOneWidget);
  });
}
