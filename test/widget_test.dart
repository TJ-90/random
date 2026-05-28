import 'package:drillcalc/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the well-control MVP shell', (tester) async {
    await tester.pumpWidget(const DrillCalcApp());

    expect(find.text('DrillCalc Field'), findsOneWidget);
    expect(find.text('Well control MVP'), findsOneWidget);
    expect(find.text('Kill Sheet', skipOffstage: false), findsOneWidget);
    expect(find.text('Kick Tolerance', skipOffstage: false), findsOneWidget);
  });

  testWidgets('renders the first frame on a phone viewport', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DrillCalcApp());
    await tester.pump();

    expect(find.text('DrillCalc Field'), findsOneWidget);
    expect(find.text('Well Data'), findsOneWidget);
    expect(find.text('Kill mud', skipOffstage: false), findsOneWidget);
  });
}
