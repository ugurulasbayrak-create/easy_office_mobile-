import 'package:flutter_test/flutter_test.dart';
import 'package:easy_office_mobile/main.dart';

void main() {
  testWidgets('Easy Office smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EasyOfficeMobileApp());
    expect(find.text('Easy Office'), findsOneWidget);
  });
}
