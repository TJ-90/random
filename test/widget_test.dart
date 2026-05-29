import 'package:drillcalc/main.dart';
import 'package:drillcalc/calculators/field_calculators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the calculator library shell', (tester) async {
    await tester.pumpWidget(const DrillCalcApp());

    expect(find.text('DrillCalc Field'), findsOneWidget);
    expect(
      find.text(
        '${fieldCalculators.length + 1} of ${fieldCalculators.length + 1} calculators ready',
      ),
      findsOneWidget,
    );
    expect(find.text('Well Control'), findsWidgets);
    expect(find.text('Bits & LCM'), findsOneWidget);
    expect(find.text('Cementing Calculator'), findsOneWidget);
    expect(find.text('Thickening Time'), findsOneWidget);
  });

  testWidgets('opens the existing well-control calculator from the hub', (
    tester,
  ) async {
    await tester.pumpWidget(const DrillCalcApp());

    await tester.tap(find.text('Well Control').last);
    await tester.pumpAndSettle();

    expect(find.text('Workbook-based well control'), findsOneWidget);
    expect(find.text('Kill Sheet', skipOffstage: false), findsOneWidget);
    expect(find.text('Kick Tolerance', skipOffstage: false), findsOneWidget);
    expect(find.text('Pump strokes', skipOffstage: false), findsOneWidget);
    expect(find.text('3066', skipOffstage: false), findsOneWidget);
  });

  testWidgets('opens a calculator with workbook input and formula details', (
    tester,
  ) async {
    await tester.pumpWidget(const DrillCalcApp());

    await tester.enterText(find.byType(TextField).first, 'Bits');
    await tester.pump();
    await tester.tap(find.text('Bits & LCM'));
    await tester.pumpAndSettle();

    expect(find.text('Workbook Inputs', skipOffstage: false), findsOneWidget);
    expect(find.text('Formula Detail', skipOffstage: false), findsOneWidget);
    expect(find.text('Source sheet', skipOffstage: false), findsOneWidget);
    expect(
      find.text('Nozzle pressure drop', skipOffstage: false),
      findsWidgets,
    );
  });

  testWidgets('renders the first frame on a phone viewport', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DrillCalcApp());
    await tester.pump();

    expect(find.text('DrillCalc Field'), findsOneWidget);
    expect(find.text('Well Control'), findsWidgets);
    expect(find.text('Hydraulics'), findsWidgets);
    expect(
      find.text('Search calculators, categories, or field tasks'),
      findsOneWidget,
    );
  });
}
