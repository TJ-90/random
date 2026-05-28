import 'package:drillcalc/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the well-control MVP shell', (tester) async {
    await tester.pumpWidget(const DrillCalcApp());

    expect(find.text('DrillCalc Field'), findsOneWidget);
    expect(find.text('Well control MVP'), findsOneWidget);
    expect(find.text('Kill Sheet', skipOffstage: false), findsOneWidget);
    expect(find.text('Kick Tolerance', skipOffstage: false), findsOneWidget);
  });
}
