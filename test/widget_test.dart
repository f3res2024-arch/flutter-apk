import 'package:flutter_test/flutter_test.dart';
import 'package:nova_delivery/main.dart';

void main() {
  testWidgets('Nova starts with role selection', (tester) async {
    await tester.pumpWidget(const Nova());
    expect(find.text('نوفا ديليفري'), findsOneWidget);
    expect(find.text('توصيل أسرع.. تجربة أفضل'), findsOneWidget);
    expect(find.text('أنا عميل'), findsOneWidget);
    expect(find.text('أنا مندوب'), findsOneWidget);
  });
}
