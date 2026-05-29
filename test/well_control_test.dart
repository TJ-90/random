import 'package:drillcalc/calculators/well_control.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WellControlCalculator', () {
    final calculator = WellControlCalculator(WellControlInputs.sample());

    test('calculates kill sheet values from workbook sample inputs', () {
      final result = calculator.killSheet();

      expect(result.presentHydrostaticPsi, closeTo(13510.0, 0.1));
      expect(result.formationPressurePsi, closeTo(14240.0, 0.1));
      expect(result.killMudWeightPpg, closeTo(19.08, 0.01));
      expect(result.initialCirculatingPressurePsi, closeTo(1010, 0.1));
      expect(result.finalCirculatingPressurePsi, closeTo(295.1, 0.1));
      expect(result.dropPerHundredStrokesPsi, closeTo(23.3, 0.1));
      expect(result.pressureSchedule.first.strokes, 0);
      expect(result.pressureSchedule.first.pressurePsi, closeTo(1010, 0.1));
      expect(result.pressureSchedule[1].pressurePsi, closeTo(986.7, 0.1));
    });

    test('calculates kick tolerance envelope', () {
      final result = calculator.kickTolerance();

      expect(result.maaspPsi, closeTo(894.5, 0.1));
      expect(result.annularCapacityAroundDpBblPerFt, closeTo(0.05373, 0.00001));
      expect(result.annularCapacityAroundDcBblPerFt, closeTo(0.04208, 0.00001));
      expect(result.maxInfluxHeightFt, closeTo(1063.3, 0.1));
      expect(result.kickToleranceAroundDpBbl, closeTo(57.1, 0.1));
      expect(result.maxKillMudWeightNoInfluxPpg, closeTo(19.27, 0.01));
    });

    test('matches workbook influx analysis with stabilized SICP input', () {
      final result = calculator.influxAnalysis();

      expect(result.bottomHolePressurePsi, closeTo(14240.0, 0.1));
      expect(result.killMudWeightPpg, closeTo(19.08, 0.01));
      expect(result.influxType, 'GAS KICK');
      expect(result.influxHeightFt, closeTo(0, 0.01));
      expect(result.influxGradientPsiPerFt, closeTo(0, 0.01));
      expect(result.influxDensityPpg, closeTo(0, 0.01));
      expect(
        result.recommendedAction,
        'W&W or Drillers - GAS: max casing pr during kill',
      );
      expect(result.canCirculateSafely, isFalse);
    });

    test('calculates volumetric method guidance', () {
      final result = calculator.volumetricMethod();

      expect(result.maaspPsi, closeTo(894.5, 0.1));
      expect(result.maxAllowableSicpPsi, closeTo(794.5, 0.1));
      expect(result.nextBleedStartPressurePsi, closeTo(2800, 0.1));
      expect(result.hasOperatingWindow, isFalse);
      expect(result.volumeToBleedOpenHoleBbl, closeTo(5.7, 0.1));
    });
  });
}
