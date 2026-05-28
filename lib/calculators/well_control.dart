import 'dart:math' as math;

const double ppgGradientFactor = 0.052;
const double barrelCapacityFactor = 1029.4;
const double ppgPerSg = 8.33;

class WellControlInputs {
  const WellControlInputs({
    required this.holeSizeIn,
    required this.casingIdIn,
    required this.currentMudWeightPpg,
    required this.holeMdFt,
    required this.holeTvdFt,
    required this.casingShoeMdFt,
    required this.casingShoeTvdFt,
    required this.sidppPsi,
    required this.sicpPsi,
    required this.pitGainBbl,
    required this.lotFitEmwPpg,
    required this.mudWeightDuringFitPpg,
    required this.drillPipeOdIn,
    required this.drillCollarOdIn,
    required this.drillCollarLengthFt,
    required this.slowCirculatingPressurePsi,
    required this.surfaceToBitStrokes,
    required this.gasGradientPsiPerFt,
    required this.safetyMarginPsi,
    required this.pressureIncrementPsi,
  });

  factory WellControlInputs.sample() {
    return const WellControlInputs(
      holeSizeIn: 9.25,
      casingIdIn: 9.438,
      currentMudWeightPpg: 18.1,
      holeMdFt: 14796,
      holeTvdFt: 14354,
      casingShoeMdFt: 14773,
      casingShoeTvdFt: 14335,
      sidppPsi: 730,
      sicpPsi: 2600,
      pitGainBbl: 15,
      lotFitEmwPpg: 19.3,
      mudWeightDuringFitPpg: 19.3,
      drillPipeOdIn: 5.5,
      drillCollarOdIn: 6.5,
      drillCollarLengthFt: 51.86,
      slowCirculatingPressurePsi: 280,
      surfaceToBitStrokes: 1200,
      gasGradientPsiPerFt: 0.1,
      safetyMarginPsi: 100,
      pressureIncrementPsi: 100,
    );
  }

  final double holeSizeIn;
  final double casingIdIn;
  final double currentMudWeightPpg;
  final double holeMdFt;
  final double holeTvdFt;
  final double casingShoeMdFt;
  final double casingShoeTvdFt;
  final double sidppPsi;
  final double sicpPsi;
  final double pitGainBbl;
  final double lotFitEmwPpg;
  final double mudWeightDuringFitPpg;
  final double drillPipeOdIn;
  final double drillCollarOdIn;
  final double drillCollarLengthFt;
  final double slowCirculatingPressurePsi;
  final double surfaceToBitStrokes;
  final double gasGradientPsiPerFt;
  final double safetyMarginPsi;
  final double pressureIncrementPsi;
}

class KillSheetResult {
  const KillSheetResult({
    required this.formationPressurePsi,
    required this.presentHydrostaticPsi,
    required this.killMudWeightPpg,
    required this.killMudWeightSg,
    required this.initialCirculatingPressurePsi,
    required this.finalCirculatingPressurePsi,
    required this.pressureDropPsi,
    required this.dropPerHundredStrokesPsi,
    required this.pressureSchedule,
  });

  final double formationPressurePsi;
  final double presentHydrostaticPsi;
  final double killMudWeightPpg;
  final double killMudWeightSg;
  final double initialCirculatingPressurePsi;
  final double finalCirculatingPressurePsi;
  final double pressureDropPsi;
  final double dropPerHundredStrokesPsi;
  final List<PressureStep> pressureSchedule;
}

class PressureStep {
  const PressureStep({required this.strokes, required this.pressurePsi});

  final int strokes;
  final double pressurePsi;
}

class KickToleranceResult {
  const KickToleranceResult({
    required this.maaspPsi,
    required this.lotFitTestPressurePsi,
    required this.fracturePressureAtShoePsi,
    required this.hydrostaticAtShoePsi,
    required this.annularCapacityAroundDpBblPerFt,
    required this.annularCapacityAroundDcBblPerFt,
    required this.maxInfluxHeightFt,
    required this.kickToleranceAroundDpBbl,
    required this.kickToleranceMixedBbl,
    required this.maxKillMudWeightNoInfluxPpg,
    required this.mudWeightIncreaseAvailablePpg,
  });

  final double maaspPsi;
  final double lotFitTestPressurePsi;
  final double fracturePressureAtShoePsi;
  final double hydrostaticAtShoePsi;
  final double annularCapacityAroundDpBblPerFt;
  final double annularCapacityAroundDcBblPerFt;
  final double? maxInfluxHeightFt;
  final double? kickToleranceAroundDpBbl;
  final double? kickToleranceMixedBbl;
  final double maxKillMudWeightNoInfluxPpg;
  final double mudWeightIncreaseAvailablePpg;
}

class InfluxAnalysisResult {
  const InfluxAnalysisResult({
    required this.bottomHolePressurePsi,
    required this.killMudWeightPpg,
    required this.mudWeightIncreaseRequiredPpg,
    required this.influxHeightFt,
    required this.influxGradientPsiPerFt,
    required this.influxDensityPpg,
    required this.influxType,
    required this.maaspCurrentMudPsi,
    required this.maaspKillMudPsi,
    required this.canCirculateSafely,
    required this.recommendedAction,
  });

  final double bottomHolePressurePsi;
  final double killMudWeightPpg;
  final double mudWeightIncreaseRequiredPpg;
  final double influxHeightFt;
  final double influxGradientPsiPerFt;
  final double influxDensityPpg;
  final String influxType;
  final double maaspCurrentMudPsi;
  final double maaspKillMudPsi;
  final bool canCirculateSafely;
  final String recommendedAction;
}

class VolumetricMethodResult {
  const VolumetricMethodResult({
    required this.bottomHolePressurePsi,
    required this.maaspPsi,
    required this.openHoleAnnularCapacityBblPerFt,
    required this.casedHoleAnnularCapacityBblPerFt,
    required this.hydrostaticPerBblOpenHolePsi,
    required this.hydrostaticPerBblCasedHolePsi,
    required this.volumeToBleedOpenHoleBbl,
    required this.volumeToBleedCasedHoleBbl,
    required this.maxAllowableSicpPsi,
    required this.nextBleedStartPressurePsi,
    required this.firstBleedTargetPsi,
    required this.hasOperatingWindow,
  });

  final double bottomHolePressurePsi;
  final double maaspPsi;
  final double openHoleAnnularCapacityBblPerFt;
  final double casedHoleAnnularCapacityBblPerFt;
  final double hydrostaticPerBblOpenHolePsi;
  final double hydrostaticPerBblCasedHolePsi;
  final double volumeToBleedOpenHoleBbl;
  final double volumeToBleedCasedHoleBbl;
  final double maxAllowableSicpPsi;
  final double nextBleedStartPressurePsi;
  final double firstBleedTargetPsi;
  final bool hasOperatingWindow;
}

class WellControlCalculator {
  const WellControlCalculator(this.inputs);

  final WellControlInputs inputs;

  KillSheetResult killSheet() {
    final hydrostatic = hydrostaticPressure(
      inputs.currentMudWeightPpg,
      inputs.holeTvdFt,
    );
    final formationPressure = hydrostatic + inputs.sidppPsi;
    final killMudWeight =
        inputs.currentMudWeightPpg +
        inputs.sidppPsi / (ppgGradientFactor * inputs.holeTvdFt);
    final initialCirculatingPressure =
        inputs.slowCirculatingPressurePsi + inputs.sidppPsi;
    final finalCirculatingPressure =
        inputs.slowCirculatingPressurePsi *
        killMudWeight /
        inputs.currentMudWeightPpg;
    final pressureDrop = initialCirculatingPressure - finalCirculatingPressure;
    final dropPerHundredStrokes = inputs.surfaceToBitStrokes <= 0
        ? 0.0
        : pressureDrop * 100 / inputs.surfaceToBitStrokes;

    return KillSheetResult(
      formationPressurePsi: formationPressure,
      presentHydrostaticPsi: hydrostatic,
      killMudWeightPpg: killMudWeight,
      killMudWeightSg: killMudWeight / ppgPerSg,
      initialCirculatingPressurePsi: initialCirculatingPressure,
      finalCirculatingPressurePsi: finalCirculatingPressure,
      pressureDropPsi: pressureDrop,
      dropPerHundredStrokesPsi: dropPerHundredStrokes,
      pressureSchedule: _pressureSchedule(
        initialPressure: initialCirculatingPressure,
        finalPressure: finalCirculatingPressure,
        dropPerHundredStrokes: dropPerHundredStrokes,
      ),
    );
  }

  KickToleranceResult kickTolerance() {
    final maasp = maaspPsi(
      lotFitEmwPpg: inputs.lotFitEmwPpg,
      mudWeightPpg: inputs.currentMudWeightPpg,
      casingShoeTvdFt: inputs.casingShoeTvdFt,
    );
    final lotFitTestPressure = math
        .max(
          0,
          (inputs.lotFitEmwPpg - inputs.mudWeightDuringFitPpg) *
              ppgGradientFactor *
              inputs.casingShoeTvdFt,
        )
        .toDouble();
    final fracturePressure = hydrostaticPressure(
      inputs.lotFitEmwPpg,
      inputs.casingShoeTvdFt,
    );
    final hydrostaticAtShoe = hydrostaticPressure(
      inputs.currentMudWeightPpg,
      inputs.casingShoeTvdFt,
    );
    final dpCapacity = annularCapacity(inputs.holeSizeIn, inputs.drillPipeOdIn);
    final dcCapacity = annularCapacity(
      inputs.holeSizeIn,
      inputs.drillCollarOdIn,
    );
    final denominator =
        ppgGradientFactor * inputs.currentMudWeightPpg -
        inputs.gasGradientPsiPerFt;
    final maxInfluxHeight = denominator <= 0 ? null : maasp / denominator;
    final toleranceDp = maxInfluxHeight == null
        ? null
        : maxInfluxHeight * dpCapacity;
    final toleranceMixed = maxInfluxHeight == null
        ? null
        : mixedAnnularVolume(
            heightFt: maxInfluxHeight,
            lowerSectionLengthFt: inputs.drillCollarLengthFt,
            lowerCapacityBblPerFt: dcCapacity,
            upperCapacityBblPerFt: dpCapacity,
          );

    final maxKillMudWeightNoInflux =
        inputs.lotFitEmwPpg * inputs.casingShoeTvdFt / inputs.holeTvdFt;

    return KickToleranceResult(
      maaspPsi: maasp,
      lotFitTestPressurePsi: lotFitTestPressure,
      fracturePressureAtShoePsi: fracturePressure,
      hydrostaticAtShoePsi: hydrostaticAtShoe,
      annularCapacityAroundDpBblPerFt: dpCapacity,
      annularCapacityAroundDcBblPerFt: dcCapacity,
      maxInfluxHeightFt: maxInfluxHeight,
      kickToleranceAroundDpBbl: toleranceDp,
      kickToleranceMixedBbl: toleranceMixed,
      maxKillMudWeightNoInfluxPpg: maxKillMudWeightNoInflux,
      mudWeightIncreaseAvailablePpg:
          maxKillMudWeightNoInflux - inputs.currentMudWeightPpg,
    );
  }

  InfluxAnalysisResult influxAnalysis() {
    final kill = killSheet();
    final dcCapacity = annularCapacity(
      inputs.holeSizeIn,
      inputs.drillCollarOdIn,
    );
    final dpCapacity = annularCapacity(inputs.holeSizeIn, inputs.drillPipeOdIn);
    final influxHeight = influxHeightFromVolume(
      volumeBbl: inputs.pitGainBbl,
      lowerSectionLengthFt: inputs.drillCollarLengthFt,
      lowerCapacityBblPerFt: dcCapacity,
      upperCapacityBblPerFt: dpCapacity,
    );

    final mudHydrostaticAboveInflux = hydrostaticPressure(
      inputs.currentMudWeightPpg,
      math.max(0, inputs.holeTvdFt - influxHeight).toDouble(),
    );
    final influxHydrostatic = inputs.pitGainBbl <= 0 || influxHeight <= 0
        ? 0.0
        : kill.formationPressurePsi -
              inputs.sicpPsi -
              mudHydrostaticAboveInflux;
    final influxGradient = influxHeight <= 0
        ? 0.0
        : influxHydrostatic / influxHeight;
    final influxDensity = influxGradient / ppgGradientFactor;
    final maaspCurrent = maaspPsi(
      lotFitEmwPpg: inputs.lotFitEmwPpg,
      mudWeightPpg: inputs.currentMudWeightPpg,
      casingShoeTvdFt: inputs.casingShoeTvdFt,
    );
    final maaspKill = maaspPsi(
      lotFitEmwPpg: inputs.lotFitEmwPpg,
      mudWeightPpg: kill.killMudWeightPpg,
      casingShoeTvdFt: inputs.casingShoeTvdFt,
    );
    final type = classifyInflux(influxGradient, inputs.pitGainBbl);

    return InfluxAnalysisResult(
      bottomHolePressurePsi: kill.formationPressurePsi,
      killMudWeightPpg: kill.killMudWeightPpg,
      mudWeightIncreaseRequiredPpg:
          kill.killMudWeightPpg - inputs.currentMudWeightPpg,
      influxHeightFt: influxHeight,
      influxGradientPsiPerFt: influxGradient,
      influxDensityPpg: influxDensity,
      influxType: type,
      maaspCurrentMudPsi: maaspCurrent,
      maaspKillMudPsi: maaspKill,
      canCirculateSafely: inputs.sicpPsi < maaspCurrent,
      recommendedAction: _recommendedAction(type),
    );
  }

  VolumetricMethodResult volumetricMethod() {
    final kill = killSheet();
    final maasp = maaspPsi(
      lotFitEmwPpg: inputs.lotFitEmwPpg,
      mudWeightPpg: inputs.currentMudWeightPpg,
      casingShoeTvdFt: inputs.casingShoeTvdFt,
    );
    final openHoleCapacity = annularCapacity(
      inputs.holeSizeIn,
      inputs.drillPipeOdIn,
    );
    final casedHoleCapacity = annularCapacity(
      inputs.casingIdIn,
      inputs.drillPipeOdIn,
    );
    final hydroPerBblOpenHole = openHoleCapacity <= 0
        ? 0.0
        : inputs.currentMudWeightPpg * ppgGradientFactor / openHoleCapacity;
    final hydroPerBblCasedHole = casedHoleCapacity <= 0
        ? 0.0
        : inputs.currentMudWeightPpg * ppgGradientFactor / casedHoleCapacity;
    final maxAllowableSicp = maasp - inputs.safetyMarginPsi;
    final nextBleedStart =
        inputs.sicpPsi + inputs.safetyMarginPsi + inputs.pressureIncrementPsi;

    return VolumetricMethodResult(
      bottomHolePressurePsi: kill.formationPressurePsi,
      maaspPsi: maasp,
      openHoleAnnularCapacityBblPerFt: openHoleCapacity,
      casedHoleAnnularCapacityBblPerFt: casedHoleCapacity,
      hydrostaticPerBblOpenHolePsi: hydroPerBblOpenHole,
      hydrostaticPerBblCasedHolePsi: hydroPerBblCasedHole,
      volumeToBleedOpenHoleBbl: hydroPerBblOpenHole <= 0
          ? 0.0
          : inputs.pressureIncrementPsi / hydroPerBblOpenHole,
      volumeToBleedCasedHoleBbl: hydroPerBblCasedHole <= 0
          ? 0.0
          : inputs.pressureIncrementPsi / hydroPerBblCasedHole,
      maxAllowableSicpPsi: maxAllowableSicp,
      nextBleedStartPressurePsi: nextBleedStart,
      firstBleedTargetPsi: inputs.sicpPsi + inputs.safetyMarginPsi,
      hasOperatingWindow: nextBleedStart < maxAllowableSicp,
    );
  }

  List<PressureStep> _pressureSchedule({
    required double initialPressure,
    required double finalPressure,
    required double dropPerHundredStrokes,
  }) {
    if (dropPerHundredStrokes <= 0) {
      return [PressureStep(strokes: 0, pressurePsi: initialPressure)];
    }

    final steps = <PressureStep>[];
    for (
      var strokes = 0;
      strokes <= inputs.surfaceToBitStrokes;
      strokes += 100
    ) {
      final pressure = math.max(
        finalPressure,
        initialPressure - dropPerHundredStrokes * strokes / 100,
      );
      steps.add(PressureStep(strokes: strokes.round(), pressurePsi: pressure));
      if (pressure <= finalPressure) {
        break;
      }
    }
    return steps;
  }
}

double hydrostaticPressure(double mudWeightPpg, double tvdFt) {
  return mudWeightPpg * ppgGradientFactor * tvdFt;
}

double annularCapacity(double outerDiameterIn, double innerDiameterIn) {
  final area = math.pow(outerDiameterIn, 2) - math.pow(innerDiameterIn, 2);
  return math.max(0, area / barrelCapacityFactor).toDouble();
}

double maaspPsi({
  required double lotFitEmwPpg,
  required double mudWeightPpg,
  required double casingShoeTvdFt,
}) {
  return (lotFitEmwPpg - mudWeightPpg) * ppgGradientFactor * casingShoeTvdFt;
}

double mixedAnnularVolume({
  required double heightFt,
  required double lowerSectionLengthFt,
  required double lowerCapacityBblPerFt,
  required double upperCapacityBblPerFt,
}) {
  if (heightFt <= lowerSectionLengthFt) {
    return heightFt * lowerCapacityBblPerFt;
  }
  return lowerSectionLengthFt * lowerCapacityBblPerFt +
      (heightFt - lowerSectionLengthFt) * upperCapacityBblPerFt;
}

double influxHeightFromVolume({
  required double volumeBbl,
  required double lowerSectionLengthFt,
  required double lowerCapacityBblPerFt,
  required double upperCapacityBblPerFt,
}) {
  if (volumeBbl <= 0 || lowerCapacityBblPerFt <= 0) {
    return 0;
  }
  final lowerSectionVolume = lowerSectionLengthFt * lowerCapacityBblPerFt;
  if (volumeBbl <= lowerSectionVolume) {
    return volumeBbl / lowerCapacityBblPerFt;
  }
  if (upperCapacityBblPerFt <= 0) {
    return lowerSectionLengthFt;
  }
  return lowerSectionLengthFt +
      (volumeBbl - lowerSectionVolume) / upperCapacityBblPerFt;
}

String classifyInflux(double gradientPsiPerFt, double pitGainBbl) {
  if (pitGainBbl <= 0) {
    return 'No pit gain entered';
  }
  if (gradientPsiPerFt < 0.15) {
    return 'Gas kick';
  }
  if (gradientPsiPerFt < 0.25) {
    return 'Gas-cut mud or light oil';
  }
  if (gradientPsiPerFt < 0.40) {
    return 'Oil kick';
  }
  if (gradientPsiPerFt < 0.45) {
    return 'Saltwater kick';
  }
  return 'Saltwater or heavy brine';
}

String _recommendedAction(String influxType) {
  if (influxType == 'No pit gain entered') {
    return 'Enter pit gain before classifying the influx.';
  }
  if (influxType == 'Gas kick') {
    return 'Use maximum MAASP discipline and prepare for gas expansion.';
  }
  if (influxType == 'Oil kick' || influxType == 'Gas-cut mud or light oil') {
    return 'Prefer wait and weight where practical; monitor casing pressure.';
  }
  return 'Check loss risk and confirm formation strength before circulating.';
}
