import 'package:flutter_test/flutter_test.dart';
import 'package:kinova_mobile/api/api_client.dart';
import 'package:kinova_mobile/main.dart';

void main() {
  testWidgets('KINOVA splash shows brand CTA', (tester) async {
    await tester.pumpWidget(KinovaApp(api: ApiClient()));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ENTRER DANS LA BOUTIQUE'), findsOneWidget);
    expect(find.text('EVERYTHING YOU LOVE'), findsOneWidget);
  });
}
