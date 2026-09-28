import 'package:flutter_test/flutter_test.dart';
import 'package:nova_delivery/main.dart';

void main() {
  testWidgets('Nova Delivery opens the Arabic premium home', (tester) async {
    await tester.pumpWidget(const Nova());
    expect(find.text('نوفا ديليفري'), findsOneWidget);
    expect(find.text('مطاعم حقيقية حولك'), findsOneWidget);
  });
}

// CI trigger: premium Nova UI build
