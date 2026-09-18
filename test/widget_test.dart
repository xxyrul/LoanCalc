import 'package:flutter_test/flutter_test.dart';
import 'package:loan_calc/main.dart';

void main() {
  testWidgets('LoanCalc smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LoanCalcApp());
    expect(find.text('Loan'), findsOneWidget);
    expect(find.text('Calc'), findsOneWidget);
  });
}
