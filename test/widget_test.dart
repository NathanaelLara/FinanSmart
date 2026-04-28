import 'package:finansmart_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FinanSmart splash renders correctly', (tester) async {
    await tester.pumpWidget(const FinansmartApp());
    expect(find.text('FinanSmart'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();
  });
}
