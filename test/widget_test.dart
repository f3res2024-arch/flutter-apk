import 'package:flutter_test/flutter_test.dart';
import 'package:nova_delivery/main.dart';

void main() {
  testWidgets('Nova Delivery starts on the customer home screen', (tester) async {
    await tester.pumpWidget(const Nova());
    expect(find.text('Nova Delivery'), findsOneWidget);
    expect(find.text('جوعان؟ 😋'), findsOneWidget);
  });
}
