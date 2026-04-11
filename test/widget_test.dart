import 'package:flutter_test/flutter_test.dart';
import 'package:petualang/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const PetualangApp());
    expect(find.byType(PetualangApp), findsOneWidget);
  });
}
