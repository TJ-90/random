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
      // The schedule now closes exactly at FCP on bit-to-surface strokes.
      expect(result.pressureSchedule.last.strokes, 3066);
      expect(
        result.pressureSchedule.last.pressurePsi,
        closeTo(result.finalCirculatingPressurePsi, 0.001),
      );
    });

    test('calculates kick tolerance envelope', () {
      final result = calculator.kickTolerance();

      expect(result.maaspPsi, closeTo(894.5, 0.1));
      expect(result.annularCapacityAroundDpBblPerFt, closeTo(0.05373, 0.00001));
      expect(result.annularCapacityAroundDcBblPerFt, closeTo(0.04208, 0.00001));
      expect(result.maxInfluxHeightFt, closeTo(1063.3, 0.1));
      expect(result.kickToleranceAroundDpBbl, closeTo(57.1, 0.1));
      expect(result.kickToleranceMixedBbl, closeTo(56.5, 0.1));
      expect(result.maxKillMudWeightNoInfluxPpg, closeTo(19.27, 0.01));
    });

    test('reports no influx instead of a false gas kick at zero pit gain', () {
      // The legacy workbook (and old app) classified pit gain = 0 as a
      // "GAS KICK" because the gradient defaulted to zero.
      final result = calculator.influxAnalysis();

      expect(result.bottomHolePressurePsi, closeTo(14240.0, 0.1));
      expect(result.killMudWeightPpg, closeTo(19.08, 0.01));
      expect(result.hasInflux, isFalse);
      expect(result.influxType, 'NO INFLUX (pit gain = 0)');
      expect(result.influxHeightFt, closeTo(0, 0.01));
      expect(result.estimatedGasSurfacePressurePsi, isNull);
      expect(result.canCirculateSafely, isFalse);
    });

    test('fingerprints a gas kick from a real pit gain', () {
      final inputs = WellControlInputs.sample();
      final calculator = WellControlCalculator(
        WellControlInputs(
          holeSizeIn: inputs.holeSizeIn,
          casingIdIn: inputs.casingIdIn,
          currentMudWeightPpg: inputs.currentMudWeightPpg,
          holeMdFt: inputs.holeMdFt,
          holeTvdFt: inputs.holeTvdFt,
          casingShoeMdFt: inputs.casingShoeMdFt,
          casingShoeTvdFt: inputs.casingShoeTvdFt,
          sidppPsi: inputs.sidppPsi,
          sicpPsi: inputs.sicpPsi,
          influxAnalysisSicpPsi: 1050,
          pitGainBbl: 20,
          lotFitEmwPpg: inputs.lotFitEmwPpg,
          mudWeightDuringFitPpg: inputs.mudWeightDuringFitPpg,
          drillPipeOdIn: inputs.drillPipeOdIn,
          drillCollarOdIn: inputs.drillCollarOdIn,
          drillCollarLengthFt: inputs.drillCollarLengthFt,
          slowCirculatingPressurePsi: inputs.slowCirculatingPressurePsi,
          surfaceToBitStrokes: inputs.surfaceToBitStrokes,
          gasGradientPsiPerFt: inputs.gasGradientPsiPerFt,
          safetyMarginPsi: inputs.safetyMarginPsi,
          pressureIncrementPsi: inputs.pressureIncrementPsi,
        ),
      );

      final result = calculator.influxAnalysis();

      expect(result.hasInflux, isTrue);
      expect(result.gradientIsReliable, isTrue);
      expect(result.influxHeightFt, closeTo(383.5, 0.1));
      expect(result.influxGradientPsiPerFt, closeTo(0.1067, 0.0005));
      expect(result.influxDensityPpg, closeTo(2.05, 0.01));
      expect(result.influxType, 'GAS KICK');
      expect(result.estimatedGasSurfacePressurePsi, closeTo(770.9, 0.1));
    });

    test('calculates volumetric method guidance', () {
      final result = calculator.volumetricMethod();

      expect(result.maaspPsi, closeTo(894.5, 0.1));
      expect(result.maxAllowableSicpPsi, closeTo(794.5, 0.1));
      expect(result.nextBleedStartPressurePsi, closeTo(2800, 0.1));
      expect(result.hasOperatingWindow, isFalse);
      expect(result.volumeToBleedOpenHoleBbl, closeTo(5.7, 0.1));
      expect(result.hydrostaticPerBblOpenHolePsi, closeTo(17.52, 0.01));
    });

    test('classifies influx gradients against the reference bands', () {
      expect(classifyInflux(0.10), 'GAS KICK');
      expect(classifyInflux(0.20), 'GAS-CUT MUD/OIL');
      expect(classifyInflux(0.30), 'OIL KICK');
      // 0.46 psi/ft is saltwater per the workbook's own reference table;
      // its formula wrongly used a 0.45 boundary.
      expect(classifyInflux(0.46), 'SALTWATER KICK');
      expect(classifyInflux(0.50), 'SALTWATER / HEAVY BRINE');
    });
  });
}
