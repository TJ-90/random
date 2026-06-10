import 'dart:math' as math;

import 'well_control.dart';

typedef FieldCalculatorFormula =
    List<FieldCalculatorResult> Function(Map<String, double> values);

class FieldCalculatorDefinition {
  const FieldCalculatorDefinition({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.inputs,
    required this.calculate,
  });

  final String id;
  final String title;
  final String category;
  final String summary;
  final List<FieldCalculatorInput> inputs;
  final FieldCalculatorFormula calculate;
}

class FieldCalculatorInput {
  const FieldCalculatorInput({
    required this.id,
    required this.label,
    required this.unit,
    required this.defaultValue,
    this.fractionDigits,
  });

  final String id;
  final String label;
  final String unit;
  final double defaultValue;
  final int? fractionDigits;

  String get formattedDefault {
    if (fractionDigits != null) {
      return defaultValue.toStringAsFixed(fractionDigits!);
    }
    if (defaultValue == defaultValue.roundToDouble()) {
      return defaultValue.toStringAsFixed(0);
    }
    return defaultValue.toString();
  }
}

class FieldCalculatorResult {
  const FieldCalculatorResult({
    required this.label,
    required this.value,
    this.unit = '',
    this.tone = FieldCalculatorTone.neutral,
  });

  final String label;
  final String value;
  final String unit;
  final FieldCalculatorTone tone;

  String get displayValue => unit.isEmpty ? value : '$value $unit';
}

enum FieldCalculatorTone { neutral, ok, warning, danger }

List<FieldCalculatorDefinition> get fieldCalculators => _fieldCalculators;

FieldCalculatorDefinition fieldCalculatorById(String id) {
  return _fieldCalculators.firstWhere((calculator) => calculator.id == id);
}

List<FieldCalculatorResult> workbookInputTrace(
  FieldCalculatorDefinition definition,
  Map<String, double> values,
) {
  return [
    FieldCalculatorResult(
      label: 'Source sheet',
      value: workbookSourceSheet(definition),
    ),
    for (final input in definition.inputs)
      _num(
        input.label,
        values[input.id] ?? input.defaultValue,
        input.unit,
        digits: input.fractionDigits ?? _inputTraceDigits(input.defaultValue),
      ),
  ];
}

List<FieldCalculatorResult> workbookFormulaNotes(
  FieldCalculatorDefinition definition,
) {
  final formulas = _workbookFormulaNotes[definition.id];
  if (formulas == null) {
    return const [
      FieldCalculatorResult(
        label: 'Formula model',
        value: 'Workbook formulas ported as live Dart calculations',
      ),
    ];
  }

  return [
    for (final formula in formulas.entries)
      FieldCalculatorResult(label: formula.key, value: formula.value),
  ];
}

String workbookSourceSheet(FieldCalculatorDefinition definition) {
  return _workbookSourceSheets[definition.id] ?? definition.title;
}

final List<FieldCalculatorDefinition> _fieldCalculators = [
  FieldCalculatorDefinition(
    id: 'bits-lcm',
    title: 'Bits & LCM',
    category: 'Hydraulics',
    summary: 'Nozzle TFA, bit hydraulics, and LCM pass-through check.',
    inputs: const [
      FieldCalculatorInput(
        id: 'nozzleSize',
        label: 'Nozzle size',
        unit: '32nds',
        defaultValue: 18,
      ),
      FieldCalculatorInput(
        id: 'nozzleCount',
        label: 'Number of nozzles',
        unit: 'count',
        defaultValue: 6,
        fractionDigits: 0,
      ),
      FieldCalculatorInput(
        id: 'flowRate',
        label: 'Flow rate',
        unit: 'gpm',
        defaultValue: 500,
      ),
      FieldCalculatorInput(
        id: 'mudWeight',
        label: 'Mud density',
        unit: 'ppg',
        defaultValue: 18,
      ),
      FieldCalculatorInput(
        id: 'holeDiameter',
        label: 'Hole diameter',
        unit: 'in',
        defaultValue: 9.5,
      ),
      FieldCalculatorInput(
        id: 'pumpPressure',
        label: 'Pump pressure',
        unit: 'psi',
        defaultValue: 2650,
      ),
      FieldCalculatorInput(
        id: 'lcmMaxSize',
        label: 'Max LCM particle',
        unit: 'mm',
        defaultValue: 6,
      ),
    ],
    calculate: (values) {
      final nozzleSize = _v(values, 'nozzleSize');
      final nozzleCount = _v(values, 'nozzleCount').round().clamp(0, 12);
      final flowRate = _v(values, 'flowRate');
      final mudWeight = _v(values, 'mudWeight');
      final holeDiameter = _v(values, 'holeDiameter');
      final pumpPressure = _v(values, 'pumpPressure');
      final lcmMaxSize = _v(values, 'lcmMaxSize');

      final singleNozzleArea = nozzleSize * nozzleSize / 1303.8;
      final totalFlowArea = singleNozzleArea * nozzleCount;
      // Standard bit nozzle pressure drop: MW * Q^2 / (10858 * TFA^2).
      // The source workbook (Bits & LCM B7) omitted the square on TFA,
      // which its own Bingham sheet applies correctly.
      final bitPressureDrop = totalFlowArea <= 0
          ? 0.0
          : flowRate *
                flowRate *
                mudWeight /
                (10858 * totalFlowArea * totalFlowArea);
      final hydraulicHorsepower = bitPressureDrop * flowRate / 1714;
      final hsi = holeDiameter <= 0
          ? 0.0
          : hydraulicHorsepower * 1.27 / (holeDiameter * holeDiameter);
      final hydraulicDiameter = singleNozzleArea <= 0
          ? 0.0
          : math.sqrt(4 * singleNozzleArea / math.pi);
      final maxParticleAllowedMm = hydraulicDiameter * 25.4 / 3;
      final lcmPasses = lcmMaxSize * 0.8 < maxParticleAllowedMm;
      final bitPressurePercent = pumpPressure <= 0
          ? 0.0
          : bitPressureDrop * 100 / pumpPressure;

      return [
        _num('Total flow area', totalFlowArea, 'sq in', digits: 3),
        _num('Nozzle pressure drop', bitPressureDrop, 'psi', digits: 0),
        _num('Hydraulic horsepower', hydraulicHorsepower, 'hp', digits: 1),
        _num('HSI', hsi, 'hp/sq in', digits: 2),
        _num('Bit pressure share', bitPressurePercent, '%', digits: 1),
        _num('Max particle allowed', maxParticleAllowedMm, 'mm', digits: 2),
        _text(
          'LCM advisory',
          lcmPasses ? 'Pumpable through nozzle' : 'Reduce max particle size',
          tone: lcmPasses
              ? FieldCalculatorTone.ok
              : FieldCalculatorTone.warning,
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'hole-cleaning',
    title: 'Hole Cleaning',
    category: 'Hydraulics',
    summary: 'Transport index, critical flow rate, annular velocity status.',
    inputs: const [
      FieldCalculatorInput(
        id: 'holeSize',
        label: 'Gauge hole size',
        unit: 'in',
        defaultValue: 9.25,
      ),
      FieldCalculatorInput(
        id: 'actualHoleSize',
        label: 'Actual hole size',
        unit: 'in',
        defaultValue: 9.25,
      ),
      FieldCalculatorInput(
        id: 'pipeOd',
        label: 'Drill pipe OD',
        unit: 'in',
        defaultValue: 5.5,
      ),
      FieldCalculatorInput(
        id: 'mudWeight',
        label: 'Mud weight',
        unit: 'ppg',
        defaultValue: 18.1,
      ),
      FieldCalculatorInput(
        id: 'plasticViscosity',
        label: 'Plastic viscosity',
        unit: 'cP',
        defaultValue: 19,
      ),
      FieldCalculatorInput(
        id: 'yieldPoint',
        label: 'Yield point',
        unit: 'lb/100ft2',
        defaultValue: 8,
      ),
      FieldCalculatorInput(
        id: 'holeAngle',
        label: 'Inclination',
        unit: 'deg',
        defaultValue: 34,
      ),
      FieldCalculatorInput(
        id: 'rop',
        label: 'ROP',
        unit: 'm/hr',
        defaultValue: 0,
      ),
      FieldCalculatorInput(
        id: 'flowRate',
        label: 'Flow rate',
        unit: 'gpm',
        defaultValue: 400,
      ),
    ],
    calculate: (values) {
      final holeSize = _v(values, 'holeSize');
      final actualHoleSize = _v(values, 'actualHoleSize');
      final pipeOd = _v(values, 'pipeOd');
      final mudWeight = _v(values, 'mudWeight');
      final plasticViscosity = _v(values, 'plasticViscosity');
      final yieldPoint = _v(values, 'yieldPoint');
      final holeAngle = _v(values, 'holeAngle');
      final rop = _v(values, 'rop');
      final flowRate = _v(values, 'flowRate');

      final annularArea = annularCapacity(holeSize, pipeOd);
      final annularVelocity = _safeDiv(
        24.51 * flowRate,
        holeSize * holeSize - pipeOd * pipeOd,
      );
      final rf = holeSize <= 9.875
          ? 0.75 + 0.009 * yieldPoint + 0.003 * plasticViscosity
          : holeSize <= 14
          ? 0.65 + 0.011 * yieldPoint + 0.003 * plasticViscosity
          : 0.6 + 0.012 * yieldPoint + 0.002 * plasticViscosity;
      final af = _angleFactor(holeAngle);
      final mudSg = mudWeight / ppgPerSg;
      final transportIndex = rf * af * mudSg;
      final washoutFactor = _washoutFactor(holeSize, actualHoleSize);
      final baseCfr = holeSize <= 9.875
          ? (280 + 6 * rop) * math.pow(_safeDiv(1, transportIndex), 0.6)
          : holeSize <= 14
          ? (500 + 13 * rop) * math.pow(_safeDiv(1, transportIndex), 0.6)
          : (750 + 18 * rop) * math.pow(_safeDiv(1, transportIndex), 0.6);
      final cfr = baseCfr * washoutFactor;
      final ratio = _safeDiv(flowRate, cfr);
      final status = ratio >= 1.2
          ? 'GOOD'
          : ratio >= 1.0
          ? 'ADEQUATE'
          : ratio >= 0.85
          ? 'MARGINAL'
          : 'POOR - increase GPM';
      final minVelocity = holeAngle < 30
          ? 120.0
          : holeAngle < 60
          ? 150.0
          : 180.0;
      final maxSafeRop = math
          .max(
            0,
            holeSize <= 9.875
                ? (flowRate * math.pow(transportIndex, 0.6) - 280) / 6
                : holeSize <= 14
                ? (flowRate * math.pow(transportIndex, 0.6) - 500) / 13
                : (flowRate * math.pow(transportIndex, 0.6) - 750) / 18,
          )
          .toDouble();
      // Workbook H34: cuttings generation rate vs annular flow rate, both
      // converted to cubic ft/min (ROP m/hr -> ft/min, GPM -> cu ft/min).
      final cuttingsRateCuFtMin =
          (rop * 3.281 / 60) * holeSize * holeSize * 0.7854 / 144;
      final flowRateCuFtMin = flowRate / 7.48;
      final cuttingsConcentration = _safeDiv(
        cuttingsRateCuFtMin * 100,
        flowRateCuFtMin + cuttingsRateCuFtMin,
      );

      return [
        _num('Annular area', annularArea, 'bbl/ft', digits: 4),
        _num('Annular velocity', annularVelocity, 'ft/min', digits: 0),
        _num('Transport index', transportIndex, '', digits: 2),
        _num('Critical flow rate', cfr.toDouble(), 'gpm', digits: 0),
        _num('Flow vs CFR ratio', ratio, '', digits: 2),
        _text(
          'Hole cleaning status',
          status,
          tone: ratio >= 1.0
              ? FieldCalculatorTone.ok
              : FieldCalculatorTone.warning,
        ),
        _num('Minimum annular velocity', minVelocity, 'ft/min', digits: 0),
        _num('Max safe ROP at this flow', maxSafeRop, 'm/hr', digits: 1),
        _num(
          'Cuttings concentration',
          cuttingsConcentration,
          '% (<5 ideal)',
          digits: 2,
          tone: cuttingsConcentration > 5
              ? FieldCalculatorTone.warning
              : FieldCalculatorTone.neutral,
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'loss-monitoring',
    title: 'Loss Monitoring',
    category: 'Fluids',
    summary: 'Expected versus actual returns, loss rate, and severity.',
    inputs: const [
      FieldCalculatorInput(
        id: 'pumpedVolume',
        label: 'Pumped volume',
        unit: 'bbl',
        defaultValue: 120,
      ),
      FieldCalculatorInput(
        id: 'returnedVolume',
        label: 'Returned volume',
        unit: 'bbl',
        defaultValue: 92,
      ),
      FieldCalculatorInput(
        id: 'elapsedMinutes',
        label: 'Elapsed time',
        unit: 'min',
        defaultValue: 45,
      ),
      FieldCalculatorInput(
        id: 'pitGain',
        label: 'Observed pit gain/loss',
        unit: 'bbl',
        defaultValue: -28,
      ),
    ],
    calculate: (values) {
      final pumped = _v(values, 'pumpedVolume');
      final returned = _v(values, 'returnedVolume');
      final elapsed = _v(values, 'elapsedMinutes');
      final pitGain = _v(values, 'pitGain');
      final calculatedLoss = math.max(0, pumped - returned);
      final observedLoss = math.max(0, -pitGain);
      final bestLoss = math.max(calculatedLoss, observedLoss).toDouble();
      final rate = elapsed <= 0 ? 0.0 : bestLoss * 60 / elapsed;
      final percent = pumped <= 0 ? 0.0 : bestLoss * 100 / pumped;
      final severity = rate >= 40
          ? 'Severe'
          : rate >= 15
          ? 'Moderate'
          : rate > 0
          ? 'Seepage'
          : 'No active loss';

      return [
        _num('Calculated loss', calculatedLoss.toDouble(), 'bbl', digits: 1),
        _num('Observed loss', observedLoss.toDouble(), 'bbl', digits: 1),
        _num('Loss rate', rate, 'bbl/hr', digits: 1),
        _num('Loss share', percent, '%', digits: 1),
        _text(
          'Loss severity',
          severity,
          tone: rate >= 15
              ? FieldCalculatorTone.warning
              : FieldCalculatorTone.ok,
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'pipe-stretch',
    title: 'Pipe Stretch',
    category: 'Fishing & Stuck Pipe',
    summary: 'Elastic stretch and free-point estimate from overpull.',
    inputs: const [
      FieldCalculatorInput(
        id: 'pipeOd',
        label: 'Pipe OD',
        unit: 'in',
        defaultValue: 5.5,
      ),
      FieldCalculatorInput(
        id: 'pipeId',
        label: 'Pipe ID',
        unit: 'in',
        defaultValue: 4.67,
      ),
      FieldCalculatorInput(
        id: 'freeLength',
        label: 'Free pipe length',
        unit: 'ft',
        defaultValue: 14000,
      ),
      FieldCalculatorInput(
        id: 'overpull',
        label: 'Overpull',
        unit: 'klbf',
        defaultValue: 80,
      ),
      FieldCalculatorInput(
        id: 'measuredStretch',
        label: 'Measured stretch',
        unit: 'in',
        defaultValue: 24,
      ),
    ],
    calculate: (values) {
      final od = _v(values, 'pipeOd');
      final id = _v(values, 'pipeId');
      final freeLength = _v(values, 'freeLength');
      final overpull = _v(values, 'overpull') * 1000;
      final measuredStretch = _v(values, 'measuredStretch');
      final area = math.max(0, (od * od - id * id) * math.pi / 4).toDouble();
      const modulus = 30000000.0;
      final stretch = area <= 0
          ? 0.0
          : overpull * freeLength * 12 / (modulus * area);
      final freePoint = overpull <= 0 || area <= 0
          ? 0.0
          : measuredStretch * modulus * area / (overpull * 12);
      final ruleOfThumb = freeLength * 0.75 / 1000;

      return [
        _num('Steel area', area, 'sq in', digits: 2),
        _num('Calculated stretch', stretch, 'in', digits: 1),
        _num('Rule of thumb stretch', ruleOfThumb, 'ft', digits: 1),
        _num('Free point estimate', freePoint, 'ft', digits: 0),
        _text(
          'Interpretation',
          measuredStretch > stretch * 1.25
              ? 'Measured stretch suggests deeper free point'
              : 'Measured stretch is near the modeled free length',
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'fishing-backoff',
    title: 'Fishing Stringshot & Backoff',
    category: 'Fishing & Stuck Pipe',
    summary: 'Backoff turns and neutral weight guidance for fishing jobs.',
    inputs: const [
      FieldCalculatorInput(
        id: 'freePoint',
        label: 'Free point depth',
        unit: 'ft',
        defaultValue: 9000,
      ),
      FieldCalculatorInput(
        id: 'pipeWeight',
        label: 'Pipe weight',
        unit: 'lb/ft',
        defaultValue: 28.48,
      ),
      FieldCalculatorInput(
        id: 'mudWeight',
        label: 'Mud weight',
        unit: 'ppg',
        defaultValue: 12.5,
      ),
      FieldCalculatorInput(
        id: 'turnsPerThousand',
        label: 'Backoff turns',
        unit: 'turns/1000ft',
        defaultValue: 1.25,
      ),
      FieldCalculatorInput(
        id: 'overpull',
        label: 'Working overpull',
        unit: 'klbf',
        defaultValue: 40,
      ),
    ],
    calculate: (values) {
      final freePoint = _v(values, 'freePoint');
      final pipeWeight = _v(values, 'pipeWeight');
      final mudWeight = _v(values, 'mudWeight');
      final turnsPerThousand = _v(values, 'turnsPerThousand');
      final overpull = _v(values, 'overpull');
      final buoyancy = (65.5 - mudWeight) / 65.5;
      final buoyedWeight = freePoint * pipeWeight * buoyancy / 1000;
      final leftHandTurns = freePoint * turnsPerThousand / 1000;
      final neutralWeight = buoyedWeight - overpull;

      return [
        _num('Buoyancy factor', buoyancy, '', digits: 3),
        _num('Buoyed string weight', buoyedWeight, 'klbf', digits: 1),
        _num('Approx left-hand turns', leftHandTurns, 'turns', digits: 1),
        _num('Neutral backoff weight', neutralWeight, 'klbf', digits: 1),
        _text(
          'Field note',
          neutralWeight > 0
              ? 'Set down toward neutral before firing stringshot'
              : 'Overpull exceeds modeled buoyed weight',
          tone: neutralWeight > 0
              ? FieldCalculatorTone.ok
              : FieldCalculatorTone.warning,
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'fit-calc',
    title: 'FIT Calc',
    category: 'Well Control',
    summary: 'FIT pressure, expected volume, and step-up pressure.',
    inputs: const [
      FieldCalculatorInput(
        id: 'depthTvd',
        label: 'Depth TVD',
        unit: 'ft',
        defaultValue: 13430,
      ),
      FieldCalculatorInput(
        id: 'fitEmw',
        label: 'FIT EMW',
        unit: 'ppg',
        defaultValue: 20.5,
      ),
      FieldCalculatorInput(
        id: 'mudWeight',
        label: 'Mud weight',
        unit: 'ppg',
        defaultValue: 18.5,
      ),
      FieldCalculatorInput(
        id: 'holeDiameter',
        label: 'Hole diameter',
        unit: 'in',
        defaultValue: 12.375,
      ),
      FieldCalculatorInput(
        id: 'compressibility',
        label: 'Effective compressibility',
        unit: '1/psi',
        defaultValue: 0.00000302,
        fractionDigits: 8,
      ),
      FieldCalculatorInput(
        id: 'pumpOutput',
        label: 'Pump output',
        unit: 'bbl/stk',
        defaultValue: 0.0998,
        fractionDigits: 4,
      ),
    ],
    calculate: (values) {
      final depth = _v(values, 'depthTvd');
      final fitEmw = _v(values, 'fitEmw');
      final mudWeight = _v(values, 'mudWeight');
      final holeDiameter = _v(values, 'holeDiameter');
      final compressibility = _v(values, 'compressibility');
      final pumpOutput = _v(values, 'pumpOutput');
      final holeVolume =
          depth * holeDiameter * holeDiameter / barrelCapacityFactor;
      final requiredPressure = (fitEmw - mudWeight) * depth * ppgGradientFactor;
      final expectedVolume = holeVolume * requiredPressure * compressibility;
      final strokes = pumpOutput <= 0 ? 0.0 : expectedVolume / pumpOutput;

      return [
        _num('Required pressure', requiredPressure, 'psi', digits: 0),
        _num('Hole volume', holeVolume, 'bbl', digits: 1),
        _num('Expected volume', expectedVolume, 'bbl', digits: 2),
        _num('Expected strokes', strokes, 'stk', digits: 0),
        _num(
          'Pressure per bbl pumped',
          holeVolume * compressibility <= 0
              ? 0.0
              : 1 / (holeVolume * compressibility),
          'psi/bbl',
          digits: 0,
        ),
        // Workbook rule of thumb (FIT CALC I3): funnel viscosity ~ 4 x MW.
        _num(
          'Approx funnel viscosity (rule of thumb)',
          mudWeight * 4,
          's',
          digits: 0,
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'mud-mixing',
    title: 'Mud Mixing',
    category: 'Fluids',
    summary: 'Barite, dilution, and final volume for mud weight changes.',
    inputs: const [
      FieldCalculatorInput(
        id: 'initialVolume',
        label: 'Initial mud volume',
        unit: 'bbl',
        defaultValue: 4000,
      ),
      FieldCalculatorInput(
        id: 'initialWeight',
        label: 'Initial mud weight',
        unit: 'ppg',
        defaultValue: 10.7,
      ),
      FieldCalculatorInput(
        id: 'targetWeight',
        label: 'Target mud weight',
        unit: 'ppg',
        defaultValue: 13,
      ),
      FieldCalculatorInput(
        id: 'bariteSg',
        label: 'Barite SG',
        unit: 'sg',
        defaultValue: 4.2,
      ),
      FieldCalculatorInput(
        id: 'baseFluidWeight',
        label: 'Base fluid weight',
        unit: 'ppg',
        defaultValue: 8.6,
      ),
    ],
    calculate: (values) {
      final initialVolume = _v(values, 'initialVolume');
      final initialWeight = _v(values, 'initialWeight');
      final targetWeight = _v(values, 'targetWeight');
      final bariteSg = _v(values, 'bariteSg');
      final baseFluidWeight = _v(values, 'baseFluidWeight');
      final bariteDensity = bariteSg * 350;
      final finalHeavyVolume = _safeDiv(
        initialVolume * (bariteDensity - initialWeight * 42),
        bariteDensity - targetWeight * 42,
      );
      final baritePounds = math
          .max(0, bariteDensity * (finalHeavyVolume - initialVolume))
          .toDouble();
      final bariteMt = baritePounds / 2204.0;
      final dilutionVolume = targetWeight >= initialWeight
          ? 0.0
          : _safeDiv(
              initialVolume * 42 * (initialWeight - targetWeight),
              42 * targetWeight - baseFluidWeight * 42,
            );
      final dilutionFinalWeight = dilutionVolume <= 0
          ? targetWeight
          : (initialVolume * initialWeight + dilutionVolume * baseFluidWeight) /
                (initialVolume + dilutionVolume);

      return [
        _num(
          'Final volume after weighting up',
          finalHeavyVolume,
          'bbl',
          digits: 1,
        ),
        _num('Barite to add', baritePounds, 'lb', digits: 0),
        _num('Barite to add', bariteMt, 'MT', digits: 1),
        _num('Base fluid for dilution', dilutionVolume, 'bbl', digits: 1),
        _num('Diluted mud weight', dilutionFinalWeight, 'ppg', digits: 2),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'fasdrill',
    title: 'FASDRILL',
    category: 'Hydraulics',
    summary: 'Bit pressure share, HHP, HSI, and optimized hydraulic range.',
    inputs: const [
      FieldCalculatorInput(
        id: 'flowRate',
        label: 'Flow rate',
        unit: 'gpm',
        defaultValue: 500,
      ),
      FieldCalculatorInput(
        id: 'surfacePressure',
        label: 'Surface pressure',
        unit: 'psi',
        defaultValue: 2650,
      ),
      FieldCalculatorInput(
        id: 'bitPressureDrop',
        label: 'Bit pressure drop',
        unit: 'psi',
        defaultValue: 520,
      ),
      FieldCalculatorInput(
        id: 'holeDiameter',
        label: 'Hole diameter',
        unit: 'in',
        defaultValue: 9.25,
      ),
      FieldCalculatorInput(
        id: 'maxPressure',
        label: 'Max pump pressure',
        unit: 'psi',
        defaultValue: 4500,
      ),
      FieldCalculatorInput(
        id: 'pressureExponent',
        label: 'Pressure exponent',
        unit: 'm',
        defaultValue: 1.86,
      ),
    ],
    calculate: (values) {
      final flowRate = _v(values, 'flowRate');
      final surfacePressure = _v(values, 'surfacePressure');
      final bitDrop = _v(values, 'bitPressureDrop');
      final holeDiameter = _v(values, 'holeDiameter');
      final maxPressure = _v(values, 'maxPressure');
      final exponent = math.max(0.1, _v(values, 'pressureExponent'));
      final hhp = bitDrop * flowRate / 1714;
      final hsi = holeDiameter <= 0
          ? 0.0
          : hhp / (math.pi * holeDiameter * holeDiameter / 4);
      final bitShare = surfacePressure <= 0
          ? 0.0
          : bitDrop * 100 / surfacePressure;
      // Hydraulic optimization (parasitic loss Pc = K*Q^m):
      //   max jet impact force -> bit dP = m/(m+2) * Pmax
      //   max bit HHP          -> bit dP = m/(m+1) * Pmax
      // The source workbook reported the PARASITIC losses (2/(m+2), 1/(m+1))
      // but labeled them as bit pressure drops; corrected here.
      final optimumImpactDrop = exponent / (exponent + 2) * maxPressure;
      final optimumHhpDrop = exponent / (exponent + 1) * maxPressure;

      return [
        _num('Hydraulic horsepower', hhp, 'hp', digits: 1),
        _num('HSI', hsi, 'hp/sq in', digits: 2),
        _num('Bit pressure share', bitShare, '%', digits: 1),
        _num(
          'Optimum bit drop for impact force',
          optimumImpactDrop,
          'psi',
          digits: 0,
        ),
        _num('Optimum bit drop for HHP', optimumHhpDrop, 'psi', digits: 0),
        _text(
          'Recommendation',
          bitShare < 50
              ? 'Decrease TFA'
              : bitShare > 65
              ? 'Increase TFA'
              : 'OK',
          tone: bitShare >= 50 && bitShare <= 65
              ? FieldCalculatorTone.ok
              : FieldCalculatorTone.warning,
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'step-down-fasdrill',
    title: 'Step Down FASDRILL',
    category: 'Hydraulics',
    summary:
        'Pressure schedule using pump law between reference and target flow.',
    inputs: const [
      FieldCalculatorInput(
        id: 'referenceFlow',
        label: 'Reference flow',
        unit: 'gpm',
        defaultValue: 500,
      ),
      FieldCalculatorInput(
        id: 'referencePressure',
        label: 'Reference pressure',
        unit: 'psi',
        defaultValue: 2650,
      ),
      FieldCalculatorInput(
        id: 'targetFlow',
        label: 'Target flow',
        unit: 'gpm',
        defaultValue: 350,
      ),
      FieldCalculatorInput(
        id: 'standpipeOffset',
        label: 'Static offset',
        unit: 'psi',
        defaultValue: 0,
      ),
      FieldCalculatorInput(
        id: 'exponent',
        label: 'Pressure exponent',
        unit: 'm',
        defaultValue: 1.86,
      ),
    ],
    calculate: (values) {
      final refFlow = _v(values, 'referenceFlow');
      final refPressure = _v(values, 'referencePressure');
      final targetFlow = _v(values, 'targetFlow');
      final offset = _v(values, 'standpipeOffset');
      final exponent = math.max(0.1, _v(values, 'exponent'));
      final dynamicRef = math.max(0, refPressure - offset).toDouble();
      final targetPressure =
          offset +
          dynamicRef * math.pow(_safeDiv(targetFlow, refFlow), exponent);
      final halfFlow = offset + dynamicRef * math.pow(0.5, exponent);
      final pressureDrop = refPressure - targetPressure;

      return [
        _num('Target pressure', targetPressure.toDouble(), 'psi', digits: 0),
        _num('Pressure drop', pressureDrop.toDouble(), 'psi', digits: 0),
        _num('Half-flow pressure', halfFlow.toDouble(), 'psi', digits: 0),
        _num('Flow ratio', _safeDiv(targetFlow, refFlow), '', digits: 2),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'casing-hydraulic-force',
    title: 'Casing Hydraulic Force',
    category: 'Cementing',
    summary: 'Hydraulic area, upward force, and shoe-track volume.',
    inputs: const [
      FieldCalculatorInput(
        id: 'pressure',
        label: 'Differential pressure',
        unit: 'psi',
        defaultValue: 1500,
      ),
      FieldCalculatorInput(
        id: 'casingOd',
        label: 'Casing OD',
        unit: 'in',
        defaultValue: 9.625,
      ),
      FieldCalculatorInput(
        id: 'casingId',
        label: 'Casing ID',
        unit: 'in',
        defaultValue: 8.681,
      ),
      FieldCalculatorInput(
        id: 'casingWeight',
        label: 'Casing weight',
        unit: 'ppf',
        defaultValue: 47,
      ),
      FieldCalculatorInput(
        id: 'casingLength',
        label: 'Casing length',
        unit: 'ft',
        defaultValue: 12000,
      ),
      FieldCalculatorInput(
        id: 'shoeTrackLength',
        label: 'Shoe track length',
        unit: 'ft',
        defaultValue: 80,
      ),
      FieldCalculatorInput(
        id: 'mudWeight',
        label: 'Mud weight',
        unit: 'ppg',
        defaultValue: 12.5,
      ),
    ],
    calculate: (values) {
      final pressure = _v(values, 'pressure');
      final casingOd = _v(values, 'casingOd');
      final casingId = _v(values, 'casingId');
      final casingWeight = _v(values, 'casingWeight');
      final casingLength = _v(values, 'casingLength');
      final shoeTrack = _v(values, 'shoeTrackLength');
      final mudWeight = _v(values, 'mudWeight');
      // Workbook CSG HYDRAULICING FORCE treats the casing as a piston of
      // full OD cross-section (I1 = pi * OD^2 / 4).
      final pistonArea = math.pi * casingOd * casingOd / 4;
      final metalArea = math
          .max(0, math.pi * (casingOd * casingOd - casingId * casingId) / 4)
          .toDouble();
      final airWeight = casingWeight * casingLength / 1000;
      // Workbook buoyancy factor: 1 - (MW in SG / 7.85).
      final buoyancyFactor = 1 - (mudWeight / ppgPerSg) / 7.85;
      final buoyedWeight = airWeight * buoyancyFactor;
      final upwardForce = pressure * pistonArea / 1000;
      final netForce = buoyedWeight - upwardForce;
      final liftPressure = pistonArea <= 0
          ? 0.0
          : buoyedWeight * 1000 / pistonArea;
      final shoeTrackVolume = pipeCapacity(casingId) * shoeTrack;

      return [
        _num('Casing piston area (OD)', pistonArea, 'sq in', digits: 1),
        _num('Steel area', metalArea, 'sq in', digits: 1),
        _num('Casing air weight', airWeight, 'klbf', digits: 1),
        _num('Buoyancy factor', buoyancyFactor, '', digits: 3),
        _num('Buoyed casing weight', buoyedWeight, 'klbf', digits: 1),
        _num('Upward hydraulic force', upwardForce, 'klbf', digits: 1),
        _num('Net force (down +ve)', netForce, 'klbf', digits: 1),
        _num('Pressure to lift casing', liftPressure, 'psi', digits: 0),
        _num('Shoe track volume', shoeTrackVolume, 'bbl', digits: 1),
        _text(
          'Pump-up status',
          netForce > 0
              ? 'Casing stays down at this pressure'
              : 'Pressure can hydraulically lift the casing',
          tone: netForce > 0
              ? FieldCalculatorTone.ok
              : FieldCalculatorTone.danger,
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'stuck-pipe-identification',
    title: 'Stuck Pipe Identification',
    category: 'Fishing & Stuck Pipe',
    summary:
        'Quick stuck-pipe pattern from circulation, rotation, drag, and pressure.',
    inputs: const [
      FieldCalculatorInput(
        id: 'canCirculate',
        label: 'Can circulate?',
        unit: '1 yes / 0 no',
        defaultValue: 1,
        fractionDigits: 0,
      ),
      FieldCalculatorInput(
        id: 'canRotate',
        label: 'Can rotate?',
        unit: '1 yes / 0 no',
        defaultValue: 0,
        fractionDigits: 0,
      ),
      FieldCalculatorInput(
        id: 'canMoveDown',
        label: 'Can move down?',
        unit: '1 yes / 0 no',
        defaultValue: 0,
        fractionDigits: 0,
      ),
      FieldCalculatorInput(
        id: 'overpull',
        label: 'Overpull',
        unit: 'klbf',
        defaultValue: 80,
      ),
      FieldCalculatorInput(
        id: 'pressureIncrease',
        label: 'Pump pressure increase',
        unit: 'psi',
        defaultValue: 0,
      ),
      FieldCalculatorInput(
        id: 'timeStationary',
        label: 'Time stationary',
        unit: 'min',
        defaultValue: 30,
      ),
    ],
    calculate: (values) {
      final circulate = _v(values, 'canCirculate') >= 0.5;
      final rotate = _v(values, 'canRotate') >= 0.5;
      final moveDown = _v(values, 'canMoveDown') >= 0.5;
      final overpull = _v(values, 'overpull');
      final pressureIncrease = _v(values, 'pressureIncrease');
      final stationary = _v(values, 'timeStationary');
      final differentialScore =
          (circulate ? 2 : 0) + (!rotate ? 1 : 0) + (stationary > 20 ? 1 : 0);
      final packoffScore =
          (!circulate ? 3 : 0) +
          (pressureIncrease > 300 ? 2 : 0) +
          (!moveDown ? 1 : 0);
      final keyseatScore =
          (rotate ? 1 : 0) + (!moveDown ? 1 : 0) + (overpull > 50 ? 1 : 0);
      final diagnosis =
          packoffScore >= differentialScore && packoffScore >= keyseatScore
          ? 'Packoff / bridge likely'
          : differentialScore >= keyseatScore
          ? 'Differential sticking likely'
          : 'Mechanical/keyseat sticking likely';
      final tone = packoffScore >= 4
          ? FieldCalculatorTone.danger
          : FieldCalculatorTone.warning;

      return [
        _num('Differential score', differentialScore.toDouble(), '', digits: 0),
        _num('Packoff score', packoffScore.toDouble(), '', digits: 0),
        _num('Keyseat score', keyseatScore.toDouble(), '', digits: 0),
        _text('Most likely mechanism', diagnosis, tone: tone),
        _text(
          'First response',
          diagnosis.startsWith('Packoff')
              ? 'Stop pumps if pressure rises, work down gently, consider sweep'
              : diagnosis.startsWith('Differential')
              ? 'Reduce overbalance if allowed and work torque/weight'
              : 'Work pipe opposite restriction and avoid excess overpull',
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'directional-wells',
    title: 'Directional Wells',
    category: 'Directional',
    summary: 'Minimum-curvature dogleg, TVD, northing, and easting increments.',
    inputs: const [
      FieldCalculatorInput(
        id: 'courseLength',
        label: 'Course length',
        unit: 'ft',
        defaultValue: 100,
      ),
      FieldCalculatorInput(
        id: 'inc1',
        label: 'Inclination start',
        unit: 'deg',
        defaultValue: 30,
      ),
      FieldCalculatorInput(
        id: 'inc2',
        label: 'Inclination end',
        unit: 'deg',
        defaultValue: 34,
      ),
      FieldCalculatorInput(
        id: 'az1',
        label: 'Azimuth start',
        unit: 'deg',
        defaultValue: 120,
      ),
      FieldCalculatorInput(
        id: 'az2',
        label: 'Azimuth end',
        unit: 'deg',
        defaultValue: 124,
      ),
    ],
    calculate: (values) {
      final course = _v(values, 'courseLength');
      final inc1 = _rad(_v(values, 'inc1'));
      final inc2 = _rad(_v(values, 'inc2'));
      final az1 = _rad(_v(values, 'az1'));
      final az2 = _rad(_v(values, 'az2'));
      final doglegRad = math.acos(
        (math.cos(inc2 - inc1) -
                math.sin(inc1) * math.sin(inc2) * (1 - math.cos(az2 - az1)))
            .clamp(-1.0, 1.0),
      );
      final ratioFactor = doglegRad.abs() < 0.000001
          ? 1.0
          : 2 / doglegRad * math.tan(doglegRad / 2);
      final tvd = course / 2 * (math.cos(inc1) + math.cos(inc2)) * ratioFactor;
      final north =
          course /
          2 *
          (math.sin(inc1) * math.cos(az1) + math.sin(inc2) * math.cos(az2)) *
          ratioFactor;
      final east =
          course /
          2 *
          (math.sin(inc1) * math.sin(az1) + math.sin(inc2) * math.sin(az2)) *
          ratioFactor;
      final doglegSeverity = course <= 0 ? 0.0 : _deg(doglegRad) * 100 / course;

      return [
        _num('Dogleg angle', _deg(doglegRad), 'deg', digits: 2),
        _num('Dogleg severity', doglegSeverity, 'deg/100ft', digits: 2),
        _num('TVD increment', tvd, 'ft', digits: 1),
        _num('North increment', north, 'ft', digits: 1),
        _num('East increment', east, 'ft', digits: 1),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'balanced-plug',
    title: 'Balanced Plug',
    category: 'Cementing',
    summary: 'Plug height, TOC, spacer length, displacement, and job time.',
    inputs: const [
      FieldCalculatorInput(
        id: 'plugBottom',
        label: 'Plug bottom',
        unit: 'ft',
        defaultValue: 10000,
      ),
      FieldCalculatorInput(
        id: 'plugHeight',
        label: 'Plug height',
        unit: 'ft',
        defaultValue: 485,
      ),
      FieldCalculatorInput(
        id: 'dpOd',
        label: 'DP OD',
        unit: 'in',
        defaultValue: 5.5,
      ),
      FieldCalculatorInput(
        id: 'dpCapacity',
        label: 'DP capacity',
        unit: 'bbl/ft',
        defaultValue: 0.0206,
        fractionDigits: 4,
      ),
      FieldCalculatorInput(
        id: 'holeId',
        label: 'Casing ID / hole size',
        unit: 'in',
        defaultValue: 16,
      ),
      FieldCalculatorInput(
        id: 'spacerLength',
        label: 'Spacer length',
        unit: 'ft',
        defaultValue: 295,
      ),
      FieldCalculatorInput(
        id: 'cementVolume',
        label: 'Cement volume',
        unit: 'bbl',
        defaultValue: 130,
      ),
      FieldCalculatorInput(
        id: 'pumpRate',
        label: 'Pump rate',
        unit: 'bpm',
        defaultValue: 5,
      ),
    ],
    calculate: (values) {
      final bottom = _v(values, 'plugBottom');
      final height = _v(values, 'plugHeight');
      final dpOd = _v(values, 'dpOd');
      final dpCapacity = _v(values, 'dpCapacity');
      final holeId = _v(values, 'holeId');
      final spacerLength = _v(values, 'spacerLength');
      final cementVolume = _v(values, 'cementVolume');
      final pumpRate = _v(values, 'pumpRate');
      final annularCapacity = annularCapacityFn(holeId, dpOd);
      final toc = bottom - height;
      final tos = bottom - height - spacerLength;
      final externalPlug = annularCapacity * height;
      final internalPlug = dpCapacity * height;
      final preflush = annularCapacity * spacerLength;
      final postflush = dpCapacity * spacerLength;
      final displacement = math
          .max(0, bottom * dpCapacity - internalPlug - postflush - 3)
          .toDouble();
      final totalPumpingVolume =
          preflush + externalPlug + internalPlug + postflush + displacement;
      final pumpingTime = pumpRate <= 0 ? 0.0 : totalPumpingVolume / pumpRate;

      return [
        _num('Annulus capacity', annularCapacity, 'bbl/ft', digits: 4),
        _num('TOC', toc, 'ft', digits: 0),
        _num('Top of spacer', tos, 'ft', digits: 0),
        _num('External plug volume', externalPlug, 'bbl', digits: 1),
        _num('Internal plug volume', internalPlug, 'bbl', digits: 1),
        _num('Displacement', displacement, 'bbl', digits: 1),
        _num('Modeled cement volume', cementVolume, 'bbl', digits: 1),
        _num('Pumping time', pumpingTime, 'min', digits: 1),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'wiper-plug-cementation',
    title: 'Wiper Plug Cementation',
    category: 'Cementing',
    summary: 'Displacement volume, strokes, and bump-plug volume.',
    inputs: const [
      FieldCalculatorInput(
        id: 'casingId',
        label: 'Casing ID',
        unit: 'in',
        defaultValue: 8.681,
      ),
      FieldCalculatorInput(
        id: 'floatCollarDepth',
        label: 'Float collar depth',
        unit: 'ft',
        defaultValue: 11920,
      ),
      FieldCalculatorInput(
        id: 'surfaceLineVolume',
        label: 'Surface line volume',
        unit: 'bbl',
        defaultValue: 0.5,
      ),
      FieldCalculatorInput(
        id: 'shoeTrackLength',
        label: 'Shoe track length',
        unit: 'ft',
        defaultValue: 80,
      ),
      FieldCalculatorInput(
        id: 'pumpOutput',
        label: 'Pump output',
        unit: 'bbl/stk',
        defaultValue: 0.117,
        fractionDigits: 3,
      ),
      FieldCalculatorInput(
        id: 'underDisplacement',
        label: 'Under-displacement',
        unit: 'bbl',
        defaultValue: 1,
      ),
    ],
    calculate: (values) {
      final casingId = _v(values, 'casingId');
      final floatCollar = _v(values, 'floatCollarDepth');
      final surfaceLine = _v(values, 'surfaceLineVolume');
      final shoeTrack = _v(values, 'shoeTrackLength');
      final pumpOutput = _v(values, 'pumpOutput');
      final underDisplacement = _v(values, 'underDisplacement');
      final capacity = pipeCapacity(casingId);
      final shoeTrackVolume = capacity * shoeTrack;
      final totalInside = surfaceLine + capacity * floatCollar;
      final displacement = math
          .max(0, totalInside - shoeTrackVolume - underDisplacement)
          .toDouble();
      final strokes = pumpOutput <= 0 ? 0.0 : displacement / pumpOutput;
      final bumpStrokes = pumpOutput <= 0 ? 0.0 : totalInside / pumpOutput;

      return [
        _num('Casing capacity', capacity, 'bbl/ft', digits: 4),
        _num('Shoe track volume', shoeTrackVolume, 'bbl', digits: 1),
        _num('Displacement volume', displacement, 'bbl', digits: 1),
        _num('Strokes to displace', strokes, 'stk', digits: 0),
        _num('Strokes to bump plug', bumpStrokes, 'stk', digits: 0),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'liner-cementation',
    title: 'Liner Cementation',
    category: 'Cementing',
    summary: 'Liner annulus, overlap, slurry volume, sacks, and displacement.',
    inputs: const [
      FieldCalculatorInput(
        id: 'holeDiameter',
        label: 'Hole diameter',
        unit: 'in',
        defaultValue: 8.5,
      ),
      FieldCalculatorInput(
        id: 'linerOd',
        label: 'Liner OD',
        unit: 'in',
        defaultValue: 7,
      ),
      FieldCalculatorInput(
        id: 'linerId',
        label: 'Liner ID',
        unit: 'in',
        defaultValue: 6.184,
      ),
      FieldCalculatorInput(
        id: 'prevCasingId',
        label: 'Previous casing ID',
        unit: 'in',
        defaultValue: 9.438,
      ),
      FieldCalculatorInput(
        id: 'openHoleLength',
        label: 'Open-hole length',
        unit: 'ft',
        defaultValue: 3500,
      ),
      FieldCalculatorInput(
        id: 'overlapLength',
        label: 'Liner overlap',
        unit: 'ft',
        defaultValue: 300,
      ),
      FieldCalculatorInput(
        id: 'linerTopMd',
        label: 'Liner top MD',
        unit: 'ft',
        defaultValue: 11000,
      ),
      FieldCalculatorInput(
        id: 'shoeTrackLength',
        label: 'Shoe track length',
        unit: 'ft',
        defaultValue: 80,
      ),
      FieldCalculatorInput(
        id: 'dpCapacity',
        label: 'DP capacity',
        unit: 'bbl/ft',
        defaultValue: 0.0206,
        fractionDigits: 4,
      ),
      FieldCalculatorInput(
        id: 'excess',
        label: 'OH excess',
        unit: '%',
        defaultValue: 30,
      ),
      FieldCalculatorInput(
        id: 'yield',
        label: 'Slurry yield',
        unit: 'ft3/sk',
        defaultValue: 1.18,
      ),
    ],
    calculate: (values) {
      final hole = _v(values, 'holeDiameter');
      final linerOd = _v(values, 'linerOd');
      final linerId = _v(values, 'linerId');
      final prevCasingId = _v(values, 'prevCasingId');
      final openHoleLength = _v(values, 'openHoleLength');
      final overlap = _v(values, 'overlapLength');
      final linerTop = _v(values, 'linerTopMd');
      final shoeTrack = _v(values, 'shoeTrackLength');
      final dpCapacity = _v(values, 'dpCapacity');
      final excess = _v(values, 'excess') / 100;
      final yield = _v(values, 'yield');
      final ohCapacity = annularCapacityFn(hole, linerOd);
      // The overlap annulus is liner inside the PREVIOUS casing, not the
      // open hole (legacy version reused the open-hole capacity here).
      final overlapCapacity = annularCapacityFn(prevCasingId, linerOd);
      final linerCapacity = pipeCapacity(linerId);
      final linerLength = openHoleLength + overlap;
      final slurryVolume =
          ohCapacity * openHoleLength * (1 + excess) +
          overlapCapacity * overlap +
          linerCapacity * shoeTrack;
      final sacks = yield <= 0 ? 0.0 : slurryVolume * 5.6146 / yield;
      // Workbook displacement: DP capacity down to the liner top, then
      // liner capacity from liner top to the landing collar.
      final displacement =
          dpCapacity * linerTop +
          linerCapacity * math.max(0, linerLength - shoeTrack);

      return [
        _num('Open-hole annular capacity', ohCapacity, 'bbl/ft', digits: 4),
        _num('Overlap annular capacity', overlapCapacity, 'bbl/ft', digits: 4),
        _num('Liner length', linerLength, 'ft', digits: 0),
        _num('Slurry volume (incl shoe track)', slurryVolume, 'bbl', digits: 1),
        _num('Cement sacks', sacks, 'sk', digits: 0),
        _num('Displacement (DP + liner)', displacement, 'bbl', digits: 1),
        _num(
          'Open-hole excess volume',
          ohCapacity * openHoleLength * excess,
          'bbl',
          digits: 1,
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'api-13d-power-law',
    title: 'Hydraulics API 13D Power Law',
    category: 'Hydraulics',
    summary:
        'Power-law rheology, annular velocity, and pressure loss snapshot.',
    inputs: const [
      FieldCalculatorInput(
        id: 'theta600',
        label: '600 rpm dial',
        unit: '',
        defaultValue: 59,
      ),
      FieldCalculatorInput(
        id: 'theta300',
        label: '300 rpm dial',
        unit: '',
        defaultValue: 40,
      ),
      FieldCalculatorInput(
        id: 'flowRate',
        label: 'Flow rate',
        unit: 'gpm',
        defaultValue: 500,
      ),
      FieldCalculatorInput(
        id: 'mudWeight',
        label: 'Mud weight',
        unit: 'ppg',
        defaultValue: 18.1,
      ),
      FieldCalculatorInput(
        id: 'holeDiameter',
        label: 'Hole diameter',
        unit: 'in',
        defaultValue: 9.25,
      ),
      FieldCalculatorInput(
        id: 'pipeOd',
        label: 'Pipe OD',
        unit: 'in',
        defaultValue: 5.5,
      ),
      FieldCalculatorInput(
        id: 'annulusLength',
        label: 'Annulus length',
        unit: 'ft',
        defaultValue: 4000,
      ),
    ],
    calculate: (values) {
      final theta600 = math.max(0.1, _v(values, 'theta600'));
      final theta300 = math.max(0.1, _v(values, 'theta300'));
      final flowRate = _v(values, 'flowRate');
      final mudWeight = _v(values, 'mudWeight');
      final hole = _v(values, 'holeDiameter');
      final pipeOd = _v(values, 'pipeOd');
      final length = _v(values, 'annulusLength');
      final n = 3.32 * math.log(theta600 / theta300) / math.ln10;
      final k = theta300 / math.pow(511, n);
      final velocity = _safeDiv(
        24.48 * flowRate,
        hole * hole - pipeOd * pipeOd,
      );
      final hydraulicDiameter = math.max(0.01, hole - pipeOd);
      final lossDenominator =
          math.pow(hydraulicDiameter, 3) * math.pow(hole + pipeOd, 1.8);
      final pressureLoss = lossDenominator <= 0
          ? 0.0
          : 0.0000765 *
                math.pow(flowRate, 1.82) *
                math.pow(mudWeight, 0.82) *
                math.pow(math.max(theta600 - theta300, 1), 0.18) *
                length /
                lossDenominator;

      return [
        _num('Flow behavior index n', n, '', digits: 3),
        _num('Consistency index K', k.toDouble(), '', digits: 3),
        _num('Annular velocity', velocity, 'ft/min', digits: 0),
        _num(
          'Annulus pressure loss',
          pressureLoss.toDouble(),
          'psi',
          digits: 0,
        ),
        _num(
          'Annular capacity',
          annularCapacityFn(hole, pipeOd),
          'bbl/ft',
          digits: 4,
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'bingham',
    title: 'Bingham',
    category: 'Hydraulics',
    summary: 'PV, YP, nozzle velocity, bit pressure drop, and HSI.',
    inputs: const [
      FieldCalculatorInput(
        id: 'theta600',
        label: '600 rpm dial',
        unit: '',
        defaultValue: 59,
      ),
      FieldCalculatorInput(
        id: 'theta300',
        label: '300 rpm dial',
        unit: '',
        defaultValue: 40,
      ),
      FieldCalculatorInput(
        id: 'flowRate',
        label: 'Flow rate',
        unit: 'gpm',
        defaultValue: 500,
      ),
      FieldCalculatorInput(
        id: 'mudWeight',
        label: 'Mud weight',
        unit: 'ppg',
        defaultValue: 18.1,
      ),
      FieldCalculatorInput(
        id: 'tfa',
        label: 'Total flow area',
        unit: 'sq in',
        defaultValue: 1.491,
        fractionDigits: 3,
      ),
      FieldCalculatorInput(
        id: 'holeDiameter',
        label: 'Hole diameter',
        unit: 'in',
        defaultValue: 9.25,
      ),
    ],
    calculate: (values) {
      final theta600 = _v(values, 'theta600');
      final theta300 = _v(values, 'theta300');
      final flowRate = _v(values, 'flowRate');
      final mudWeight = _v(values, 'mudWeight');
      final tfa = _v(values, 'tfa');
      final hole = _v(values, 'holeDiameter');
      final pv = theta600 - theta300;
      final yp = theta300 - pv;
      final pressureDrop = tfa <= 0
          ? 0.0
          : mudWeight * flowRate * flowRate / (10858 * tfa * tfa);
      final hhp = pressureDrop * flowRate / 1714;
      final hsi = hole <= 0 ? 0.0 : hhp / (math.pi * hole * hole / 4);
      final nozzleVelocity = tfa <= 0 ? 0.0 : 0.321 * flowRate / tfa;

      return [
        _num('Plastic viscosity', pv, 'cP', digits: 0),
        _num('Yield point', yp, 'lb/100ft2', digits: 0),
        _num('Nozzle pressure drop', pressureDrop, 'psi', digits: 0),
        _num('Nozzle velocity', nozzleVelocity, 'ft/sec', digits: 0),
        _num('HHP per sq in', hsi, 'hp/sq in', digits: 2),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'hydraulics',
    title: 'Hydraulics',
    category: 'Hydraulics',
    summary: 'System pressure, ECD, bit horsepower, and lag time.',
    inputs: const [
      FieldCalculatorInput(
        id: 'flowRate',
        label: 'Flow rate',
        unit: 'gpm',
        defaultValue: 500,
      ),
      FieldCalculatorInput(
        id: 'mudWeight',
        label: 'Mud weight',
        unit: 'ppg',
        defaultValue: 18.1,
      ),
      FieldCalculatorInput(
        id: 'surfacePressure',
        label: 'Surface pressure',
        unit: 'psi',
        defaultValue: 2650,
      ),
      FieldCalculatorInput(
        id: 'bitPressureDrop',
        label: 'Bit pressure drop',
        unit: 'psi',
        defaultValue: 520,
      ),
      FieldCalculatorInput(
        id: 'annulusPressureLoss',
        label: 'Annulus pressure loss',
        unit: 'psi',
        defaultValue: 323,
      ),
      FieldCalculatorInput(
        id: 'tvd',
        label: 'TVD',
        unit: 'ft',
        defaultValue: 14354,
      ),
      FieldCalculatorInput(
        id: 'annulusVolume',
        label: 'Annulus volume',
        unit: 'bbl',
        defaultValue: 3304,
      ),
    ],
    calculate: (values) {
      final flowRate = _v(values, 'flowRate');
      final mudWeight = _v(values, 'mudWeight');
      final surfacePressure = _v(values, 'surfacePressure');
      final bitPressure = _v(values, 'bitPressureDrop');
      final annulusLoss = _v(values, 'annulusPressureLoss');
      final tvd = _v(values, 'tvd');
      final annulusVolume = _v(values, 'annulusVolume');
      final hhp = bitPressure * flowRate / 1714;
      final ecd = tvd <= 0
          ? mudWeight
          : mudWeight + annulusLoss / (ppgGradientFactor * tvd);
      final lagTime = flowRate <= 0 ? 0.0 : annulusVolume * 42 / flowRate;
      final pressureShare = surfacePressure <= 0
          ? 0.0
          : bitPressure * 100 / surfacePressure;

      return [
        _num('Bit HHP', hhp, 'hp', digits: 1),
        _num('ECD at TVD', ecd, 'ppg', digits: 2),
        _num('Lag time', lagTime, 'min', digits: 1),
        _num('Bit pressure share', pressureShare, '%', digits: 1),
        _num(
          'Modeled system pressure',
          bitPressure + annulusLoss,
          'psi',
          digits: 0,
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'cutting-skips',
    title: 'Cutting Skips Estimator',
    category: 'Fluids',
    summary: 'Drilled cuttings volume and skip count estimate.',
    inputs: const [
      FieldCalculatorInput(
        id: 'holeDiameter',
        label: 'Hole diameter',
        unit: 'in',
        defaultValue: 12.25,
      ),
      FieldCalculatorInput(
        id: 'intervalLength',
        label: 'Interval drilled',
        unit: 'ft',
        defaultValue: 1000,
      ),
      FieldCalculatorInput(
        id: 'washout',
        label: 'Washout / excess',
        unit: '%',
        defaultValue: 10,
      ),
      FieldCalculatorInput(
        id: 'solidsExpansion',
        label: 'Cuttings bulk factor',
        unit: 'x',
        defaultValue: 1.25,
      ),
      FieldCalculatorInput(
        id: 'skipCapacity',
        label: 'Skip capacity',
        unit: 'bbl',
        defaultValue: 20,
      ),
    ],
    calculate: (values) {
      final hole = _v(values, 'holeDiameter');
      final length = _v(values, 'intervalLength');
      final washout = _v(values, 'washout') / 100;
      final bulk = _v(values, 'solidsExpansion');
      final skipCapacity = _v(values, 'skipCapacity');
      final holeVolume = pipeCapacity(hole) * length;
      final cuttingsVolume = holeVolume * (1 + washout) * bulk;
      final skips = skipCapacity <= 0 ? 0.0 : cuttingsVolume / skipCapacity;

      return [
        _num('Gauge hole volume', holeVolume, 'bbl', digits: 1),
        _num('Bulk cuttings volume', cuttingsVolume, 'bbl', digits: 1),
        _num('Estimated skips', skips, 'skips', digits: 1),
        _num('Washout allowance', holeVolume * washout, 'bbl', digits: 1),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'whipstock',
    title: 'Whipstock',
    category: 'Directional',
    summary: 'Sidetrack geometry, window angle, and projected offset.',
    inputs: const [
      FieldCalculatorInput(
        id: 'windowLength',
        label: 'Window length',
        unit: 'ft',
        defaultValue: 45,
      ),
      FieldCalculatorInput(
        id: 'rampAngle',
        label: 'Ramp angle',
        unit: 'deg',
        defaultValue: 2.5,
      ),
      FieldCalculatorInput(
        id: 'buildRate',
        label: 'Build rate',
        unit: 'deg/100ft',
        defaultValue: 8,
      ),
      FieldCalculatorInput(
        id: 'sidetrackLength',
        label: 'Sidetrack length',
        unit: 'ft',
        defaultValue: 500,
      ),
    ],
    calculate: (values) {
      final windowLength = _v(values, 'windowLength');
      final rampAngle = _v(values, 'rampAngle');
      final buildRate = _v(values, 'buildRate');
      final sidetrackLength = _v(values, 'sidetrackLength');
      final windowOffset = math.tan(_rad(rampAngle)) * windowLength;
      final addedAngle = buildRate * sidetrackLength / 100;
      final averageAngle = _rad(rampAngle + addedAngle / 2);
      final projectedOffset =
          windowOffset + math.sin(averageAngle) * sidetrackLength;
      final projectedTvd = math.cos(averageAngle) * sidetrackLength;

      return [
        _num('Window offset', windowOffset, 'ft', digits: 2),
        _num('Added inclination', addedAngle, 'deg', digits: 1),
        _num('Projected lateral offset', projectedOffset, 'ft', digits: 1),
        _num('Projected TVD gain', projectedTvd, 'ft', digits: 1),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'whipstock-fishing',
    title: 'Whipstock Fishing',
    category: 'Fishing & Stuck Pipe',
    summary: 'Retrieval overpull margin and jar energy snapshot.',
    inputs: const [
      FieldCalculatorInput(
        id: 'fishWeight',
        label: 'Fish weight',
        unit: 'klbf',
        defaultValue: 35,
      ),
      FieldCalculatorInput(
        id: 'availableOverpull',
        label: 'Available overpull',
        unit: 'klbf',
        defaultValue: 80,
      ),
      FieldCalculatorInput(
        id: 'jarStroke',
        label: 'Jar stroke',
        unit: 'in',
        defaultValue: 10,
      ),
      FieldCalculatorInput(
        id: 'dragAllowance',
        label: 'Drag allowance',
        unit: 'klbf',
        defaultValue: 15,
      ),
    ],
    calculate: (values) {
      final fishWeight = _v(values, 'fishWeight');
      final overpull = _v(values, 'availableOverpull');
      final jarStroke = _v(values, 'jarStroke');
      final drag = _v(values, 'dragAllowance');
      final margin = overpull - fishWeight - drag;
      final jarEnergy = overpull * 1000 * jarStroke / 12;

      return [
        _num('Pickup requirement', fishWeight + drag, 'klbf', digits: 1),
        _num('Overpull margin', margin, 'klbf', digits: 1),
        _num('Jar energy proxy', jarEnergy, 'ft-lbf', digits: 0),
        _text(
          'Retrieval status',
          margin >= 0 ? 'Overpull margin available' : 'Overpull margin short',
          tone: margin >= 0
              ? FieldCalculatorTone.ok
              : FieldCalculatorTone.warning,
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'squeeze-cementing-ezsv',
    title: 'Squeeze Cementing EZSV',
    category: 'Cementing',
    summary: 'Squeeze volume, cement sacks, and pressure limit check.',
    inputs: const [
      FieldCalculatorInput(
        id: 'intervalLength',
        label: 'Squeeze interval',
        unit: 'ft',
        defaultValue: 100,
      ),
      FieldCalculatorInput(
        id: 'holeDiameter',
        label: 'Hole / casing ID',
        unit: 'in',
        defaultValue: 8.681,
      ),
      FieldCalculatorInput(
        id: 'pipeOd',
        label: 'Workstring OD',
        unit: 'in',
        defaultValue: 5.5,
      ),
      FieldCalculatorInput(
        id: 'excess',
        label: 'Excess factor',
        unit: '%',
        defaultValue: 50,
      ),
      FieldCalculatorInput(
        id: 'yield',
        label: 'Slurry yield',
        unit: 'ft3/sk',
        defaultValue: 1.18,
      ),
      FieldCalculatorInput(
        id: 'plannedPressure',
        label: 'Planned squeeze pressure',
        unit: 'psi',
        defaultValue: 3900,
      ),
      FieldCalculatorInput(
        id: 'maxPressure',
        label: 'Max allowed pressure',
        unit: 'psi',
        defaultValue: 4500,
      ),
    ],
    calculate: (values) {
      final interval = _v(values, 'intervalLength');
      final hole = _v(values, 'holeDiameter');
      final pipeOd = _v(values, 'pipeOd');
      final excess = _v(values, 'excess') / 100;
      final yield = _v(values, 'yield');
      final pressure = _v(values, 'plannedPressure');
      final maxPressure = _v(values, 'maxPressure');
      final annularCapacity = annularCapacityFn(hole, pipeOd);
      final volume = annularCapacity * interval * (1 + excess);
      final sacks = yield <= 0 ? 0.0 : volume * 5.6146 / yield;

      return [
        _num('Annular capacity', annularCapacity, 'bbl/ft', digits: 4),
        _num('Squeeze slurry volume', volume, 'bbl', digits: 1),
        _num('Cement sacks', sacks, 'sk', digits: 0),
        _num('Pressure margin', maxPressure - pressure, 'psi', digits: 0),
        _text(
          'Pressure status',
          pressure <= maxPressure
              ? 'Within max pressure'
              : 'Above max pressure',
          tone: pressure <= maxPressure
              ? FieldCalculatorTone.ok
              : FieldCalculatorTone.danger,
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'actual-result-squeeze',
    title: 'Actual Result Squeeze',
    category: 'Cementing',
    summary: 'Pumped, returned, retained volume, and final pressure gradient.',
    inputs: const [
      FieldCalculatorInput(
        id: 'pumpedVolume',
        label: 'Pumped volume',
        unit: 'bbl',
        defaultValue: 45,
      ),
      FieldCalculatorInput(
        id: 'returnsVolume',
        label: 'Returns volume',
        unit: 'bbl',
        defaultValue: 8,
      ),
      FieldCalculatorInput(
        id: 'finalPressure',
        label: 'Final squeeze pressure',
        unit: 'psi',
        defaultValue: 3900,
      ),
      FieldCalculatorInput(
        id: 'depthTvd',
        label: 'Depth TVD',
        unit: 'ft',
        defaultValue: 10000,
      ),
      FieldCalculatorInput(
        id: 'mudWeight',
        label: 'Mud weight',
        unit: 'ppg',
        defaultValue: 13.2,
      ),
    ],
    calculate: (values) {
      final pumped = _v(values, 'pumpedVolume');
      final returned = _v(values, 'returnsVolume');
      final pressure = _v(values, 'finalPressure');
      final tvd = _v(values, 'depthTvd');
      final mudWeight = _v(values, 'mudWeight');
      final retained = math.max(0, pumped - returned).toDouble();
      final retainedPercent = pumped <= 0 ? 0.0 : retained * 100 / pumped;
      final finalEmw = tvd <= 0
          ? mudWeight
          : mudWeight + pressure / (ppgGradientFactor * tvd);

      return [
        _num('Retained squeeze volume', retained, 'bbl', digits: 1),
        _num('Retention', retainedPercent, '%', digits: 1),
        _num('Final EMW at depth', finalEmw, 'ppg', digits: 2),
        _num(
          'Hydrostatic pressure',
          hydrostaticPressure(mudWeight, tvd),
          'psi',
          digits: 0,
        ),
        _text(
          'Result',
          retainedPercent >= 80
              ? 'High retention'
              : retainedPercent >= 50
              ? 'Partial retention'
              : 'Low retention',
          tone: retainedPercent >= 50
              ? FieldCalculatorTone.ok
              : FieldCalculatorTone.warning,
        ),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'balanced-plug-3-case',
    title: 'Balanced Plug 3-Case',
    category: 'Cementing',
    summary: 'Open-hole/cased-hole placement case and plug height.',
    inputs: const [
      FieldCalculatorInput(
        id: 'plugVolume',
        label: 'Plug volume',
        unit: 'bbl',
        defaultValue: 450,
      ),
      FieldCalculatorInput(
        id: 'spacerVolume',
        label: 'Spacer volume',
        unit: 'bbl',
        defaultValue: 50,
      ),
      FieldCalculatorInput(
        id: 'plugBottom',
        label: 'Plug bottom',
        unit: 'ft',
        defaultValue: 10116,
      ),
      FieldCalculatorInput(
        id: 'shoeDepth',
        label: 'Casing shoe',
        unit: 'ft',
        defaultValue: 9688,
      ),
      FieldCalculatorInput(
        id: 'ohSize',
        label: 'OH size',
        unit: 'in',
        defaultValue: 16,
      ),
      FieldCalculatorInput(
        id: 'casingId',
        label: 'Casing ID',
        unit: 'in',
        defaultValue: 17.239,
      ),
      FieldCalculatorInput(
        id: 'dpOd',
        label: 'DP OD',
        unit: 'in',
        defaultValue: 5.5,
      ),
      FieldCalculatorInput(
        id: 'dpCapacity',
        label: 'DP capacity',
        unit: 'bbl/ft',
        defaultValue: 0.0206,
        fractionDigits: 4,
      ),
    ],
    calculate: (values) {
      final plugVolume = _v(values, 'plugVolume');
      final spacerVolume = _v(values, 'spacerVolume');
      final plugBottom = _v(values, 'plugBottom');
      final shoe = _v(values, 'shoeDepth');
      final ohSize = _v(values, 'ohSize');
      final casingId = _v(values, 'casingId');
      final dpOd = _v(values, 'dpOd');
      final dpCapacity = _v(values, 'dpCapacity');
      final ohAnnulus = annularCapacityFn(ohSize, dpOd);
      final casedAnnulus = annularCapacityFn(casingId, dpOd);
      final openHoleVolume =
          math.max(0, plugBottom - shoe) * pipeCapacity(ohSize);
      final remainingCement = plugVolume - openHoleVolume;
      final plugHeight =
          math.max(0, plugBottom - shoe) +
          math.max(0, remainingCement) /
              math.max(0.0001, dpCapacity + casedAnnulus);
      final toc = plugBottom - plugHeight;
      final caseText = plugVolume + spacerVolume <= openHoleVolume
          ? 'Cement and spacer in open hole'
          : plugVolume <= openHoleVolume
          ? 'Cement in open hole, spacer in casing'
          : 'Cement transitions into casing';

      return [
        _num('Open-hole volume', openHoleVolume, 'bbl', digits: 1),
        _num('OH annulus capacity', ohAnnulus, 'bbl/ft', digits: 4),
        _num('Cased annulus capacity', casedAnnulus, 'bbl/ft', digits: 4),
        _num('Height of cement plug', plugHeight, 'ft', digits: 1),
        _num('TOC', toc, 'ft', digits: 0),
        _text('Placement case', caseText),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'cementing-calculator',
    title: 'Cementing Calculator',
    category: 'Cementing',
    summary:
        'Lead/tail slurry volume, sacks, mix water, displacement, and pressure.',
    inputs: const [
      FieldCalculatorInput(
        id: 'holeDiameter',
        label: 'Hole / OH diameter',
        unit: 'in',
        defaultValue: 12.25,
      ),
      FieldCalculatorInput(
        id: 'casingOd',
        label: 'Casing OD',
        unit: 'in',
        defaultValue: 9.625,
      ),
      FieldCalculatorInput(
        id: 'casingId',
        label: 'Casing ID',
        unit: 'in',
        defaultValue: 8.681,
      ),
      FieldCalculatorInput(
        id: 'previousCasingId',
        label: 'Previous casing ID',
        unit: 'in',
        defaultValue: 12.415,
      ),
      FieldCalculatorInput(
        id: 'previousShoe',
        label: 'Previous shoe MD',
        unit: 'ft',
        defaultValue: 8500,
      ),
      FieldCalculatorInput(
        id: 'currentShoe',
        label: 'Current shoe / TD MD',
        unit: 'ft',
        defaultValue: 12000,
      ),
      FieldCalculatorInput(
        id: 'toc',
        label: 'TOC target MD',
        unit: 'ft',
        defaultValue: 8000,
      ),
      FieldCalculatorInput(
        id: 'shoeTrack',
        label: 'Shoe track length',
        unit: 'ft',
        defaultValue: 80,
      ),
      FieldCalculatorInput(
        id: 'ohExcess',
        label: 'OH excess',
        unit: '%',
        defaultValue: 50,
      ),
      FieldCalculatorInput(
        id: 'casedExcess',
        label: 'Cased excess',
        unit: '%',
        defaultValue: 0,
      ),
      FieldCalculatorInput(
        id: 'leadYield',
        label: 'Lead yield',
        unit: 'ft3/sk',
        defaultValue: 1.45,
      ),
      FieldCalculatorInput(
        id: 'leadWater',
        label: 'Lead mix water',
        unit: 'gal/sk',
        defaultValue: 7.8,
      ),
      FieldCalculatorInput(
        id: 'leadBottom',
        label: 'Lead bottom MD',
        unit: 'ft',
        defaultValue: 10000,
      ),
      FieldCalculatorInput(
        id: 'tailYield',
        label: 'Tail yield',
        unit: 'ft3/sk',
        defaultValue: 1.18,
      ),
      FieldCalculatorInput(
        id: 'tailWater',
        label: 'Tail mix water',
        unit: 'gal/sk',
        defaultValue: 5.2,
      ),
      FieldCalculatorInput(
        id: 'pumpOutput',
        label: 'Pump output',
        unit: 'bbl/stk',
        defaultValue: 0.117,
        fractionDigits: 3,
      ),
      FieldCalculatorInput(
        id: 'underDisplacement',
        label: 'Under-displacement',
        unit: 'bbl',
        defaultValue: 1,
      ),
      FieldCalculatorInput(
        id: 'friction',
        label: 'Friction allowance',
        unit: 'psi',
        defaultValue: 200,
      ),
      FieldCalculatorInput(
        id: 'bumpMargin',
        label: 'Bump margin',
        unit: 'psi',
        defaultValue: 500,
      ),
    ],
    calculate: (values) {
      final hole = _v(values, 'holeDiameter');
      final casingOd = _v(values, 'casingOd');
      final casingId = _v(values, 'casingId');
      final previousCasingId = _v(values, 'previousCasingId');
      final previousShoe = _v(values, 'previousShoe');
      final currentShoe = _v(values, 'currentShoe');
      final toc = _v(values, 'toc');
      final shoeTrack = _v(values, 'shoeTrack');
      final ohExcess = _v(values, 'ohExcess') / 100;
      final casedExcess = _v(values, 'casedExcess') / 100;
      final leadYield = _v(values, 'leadYield');
      final leadWater = _v(values, 'leadWater');
      final leadBottom = _v(values, 'leadBottom');
      final tailYield = _v(values, 'tailYield');
      final tailWater = _v(values, 'tailWater');
      final pumpOutput = _v(values, 'pumpOutput');
      final underDisplacement = _v(values, 'underDisplacement');
      final friction = _v(values, 'friction');
      final bumpMargin = _v(values, 'bumpMargin');
      final ohCap = annularCapacityFn(hole, casingOd);
      final casedCap = annularCapacityFn(previousCasingId, casingOd);
      final csgInternalCap = pipeCapacity(casingId);
      final leadOhLength = math
          .max(
            0,
            math.min(leadBottom, currentShoe) - math.max(toc, previousShoe),
          )
          .toDouble();
      final leadCasedLength = math
          .max(0, math.min(leadBottom, previousShoe) - toc)
          .toDouble();
      final leadVolume =
          leadOhLength * ohCap * (1 + ohExcess) +
          leadCasedLength * casedCap * (1 + casedExcess);
      final leadSacks = leadYield <= 0 ? 0.0 : leadVolume * 5.6146 / leadYield;
      final leadMixWater = leadSacks * leadWater / 42;
      final tailOhLength = math
          .max(
            0,
            math.min(currentShoe, currentShoe) -
                math.max(leadBottom, previousShoe),
          )
          .toDouble();
      final tailCasedLength = math
          .max(0, math.min(currentShoe, previousShoe) - leadBottom)
          .toDouble();
      final shoeTrackVolume = csgInternalCap * shoeTrack;
      final tailVolume =
          tailOhLength * ohCap * (1 + ohExcess) +
          tailCasedLength * casedCap * (1 + casedExcess) +
          shoeTrackVolume;
      final tailSacks = tailYield <= 0 ? 0.0 : tailVolume * 5.6146 / tailYield;
      final tailMixWater = tailSacks * tailWater / 42;
      final totalVolume = leadVolume + tailVolume;
      final totalSacks = leadSacks + tailSacks;
      final totalInsideVolume = csgInternalCap * currentShoe + 0.5;
      final displacement = math
          .max(0, totalInsideVolume - shoeTrackVolume - underDisplacement)
          .toDouble();
      final strokes = pumpOutput <= 0 ? 0.0 : displacement / pumpOutput;
      final bumpStrokes = pumpOutput <= 0
          ? 0.0
          : totalInsideVolume / pumpOutput;
      final surfacePressure = friction + bumpMargin;

      return [
        _num('OH annular capacity', ohCap, 'bbl/ft', digits: 4),
        _num('Cased annular capacity', casedCap, 'bbl/ft', digits: 4),
        _num('Lead slurry volume', leadVolume, 'bbl', digits: 1),
        _num('Lead sacks', leadSacks, 'sk', digits: 0),
        _num('Lead mix water', leadMixWater, 'bbl', digits: 1),
        _num('Tail slurry volume', tailVolume, 'bbl', digits: 1),
        _num('Tail sacks', tailSacks, 'sk', digits: 0),
        _num('Tail mix water', tailMixWater, 'bbl', digits: 1),
        _num('Total slurry volume', totalVolume, 'bbl', digits: 1),
        _num('Total sacks', totalSacks, 'sk', digits: 0),
        _num('Displacement volume', displacement, 'bbl', digits: 1),
        _num('Strokes to displace', strokes, 'stk', digits: 0),
        _num('Strokes to bump plug', bumpStrokes, 'stk', digits: 0),
        _num('Bump pressure snapshot', surfacePressure, 'psi', digits: 0),
      ];
    },
  ),
  FieldCalculatorDefinition(
    id: 'thickening-time',
    title: 'Thickening Time',
    category: 'Cementing',
    summary:
        'Adjusted working time, job verdict, gel pressure, and rheology check.',
    inputs: const [
      FieldCalculatorInput(
        id: 'apiThickeningTime',
        label: 'API thickening time',
        unit: 'hr',
        defaultValue: 5.5,
      ),
      FieldCalculatorInput(
        id: 'batchMixingTime',
        label: 'Batch mixing time',
        unit: 'min',
        defaultValue: 0,
      ),
      FieldCalculatorInput(
        id: 'shearFactor',
        label: 'Shear sensitivity',
        unit: '0-1',
        defaultValue: 0.7,
      ),
      FieldCalculatorInput(
        id: 'safetyMargin',
        label: 'Safety margin',
        unit: '%',
        defaultValue: 20,
      ),
      FieldCalculatorInput(
        id: 'jobDuration',
        label: 'Planned job duration',
        unit: 'hr',
        defaultValue: 5,
      ),
      FieldCalculatorInput(
        id: 'gelStrength',
        label: 'SGSD gel strength',
        unit: 'lb/100ft2',
        defaultValue: 500,
      ),
      FieldCalculatorInput(
        id: 'toc',
        label: 'TOC',
        unit: 'ft',
        defaultValue: 14668,
      ),
      FieldCalculatorInput(
        id: 'depth',
        label: 'Depth of interest',
        unit: 'ft',
        defaultValue: 14796,
      ),
      FieldCalculatorInput(
        id: 'holeDiameter',
        label: 'Hole diameter',
        unit: 'in',
        defaultValue: 9.25,
      ),
      FieldCalculatorInput(
        id: 'pipeDiameter',
        label: 'Pipe diameter',
        unit: 'in',
        defaultValue: 5.5,
      ),
      FieldCalculatorInput(
        id: 'bhct',
        label: 'BHCT',
        unit: 'F',
        defaultValue: 180,
      ),
      FieldCalculatorInput(
        id: 'dial300',
        label: '300 rpm dial',
        unit: '',
        defaultValue: 80,
      ),
      FieldCalculatorInput(
        id: 'dial200',
        label: '200 rpm dial',
        unit: '',
        defaultValue: 65,
      ),
      FieldCalculatorInput(
        id: 'dial6',
        label: '6 rpm dial',
        unit: '',
        defaultValue: 8,
      ),
    ],
    calculate: (values) {
      final apiHours = _v(values, 'apiThickeningTime');
      final batchMix = _v(values, 'batchMixingTime');
      final shear = _v(values, 'shearFactor').clamp(0, 1);
      final margin = _v(values, 'safetyMargin') / 100;
      final jobDuration = _v(values, 'jobDuration');
      final gel = _v(values, 'gelStrength');
      final toc = _v(values, 'toc');
      final depth = _v(values, 'depth');
      final hole = _v(values, 'holeDiameter');
      final pipe = _v(values, 'pipeDiameter');
      final bhct = _v(values, 'bhct');
      final dial300 = _v(values, 'dial300');
      final dial200 = _v(values, 'dial200');
      final dial6 = _v(values, 'dial6');
      final apiMinutes = apiHours * 60;
      final shearLoss = apiMinutes * shear;
      final remaining = apiMinutes - shearLoss - batchMix;
      final safeMinutes = remaining * (1 - margin);
      final safeHours = safeMinutes / 60;
      final extraPressure = (hole - pipe).abs() <= 0.0001
          ? 0.0
          : ((gel / 300) * (toc - depth) / (hole - pipe)).abs();
      final pv = dial300 - dial200;
      final yp = dial200 - pv;
      final retarder = bhct < 125
          ? 'No retarder'
          : bhct < 220
          ? 'Single retarder'
          : bhct < 350
          ? 'Blend of retarders'
          : 'Specialty blend + borax';
      final ok = jobDuration < safeHours;

      return [
        _num('API TT', apiMinutes, 'min', digits: 0),
        _num('TT lost to shear/batch', shearLoss + batchMix, 'min', digits: 0),
        _num('Safe working time', safeMinutes, 'min', digits: 0),
        _num('Safe working time', safeHours, 'hr', digits: 2),
        _text(
          'Job verdict',
          ok ? 'OK - enough working time' : 'DANGER - redesign slurry',
          tone: ok ? FieldCalculatorTone.ok : FieldCalculatorTone.danger,
        ),
        _num('Extra annular pressure', extraPressure, 'psi', digits: 1),
        _text('Retarder guidance', retarder),
        _num('Plastic viscosity', pv, 'cP', digits: 0),
        _num('Yield point', yp, 'lb/100ft2', digits: 0),
        _text(
          'Rheology check',
          dial200 < dial300 && dial6 > 5 ? 'PASS' : 'Review slurry rheology',
          tone: dial200 < dial300 && dial6 > 5
              ? FieldCalculatorTone.ok
              : FieldCalculatorTone.warning,
        ),
      ];
    },
  ),
];

const Map<String, String> _workbookSourceSheets = {
  'bits-lcm': 'Bits & LCM',
  'hole-cleaning': 'Hole Cleaning',
  'loss-monitoring': 'Loss monitoring',
  'pipe-stretch': 'Pipe Stretch calculator',
  'fishing-backoff': 'Fishing (Stringshot & backoff)',
  'fit-calc': 'FIT CALC',
  'mud-mixing': 'Mud Mixing Calculator',
  'fasdrill': 'FASDRILL',
  'step-down-fasdrill': 'STEP DOWN FASDRILL',
  'casing-hydraulic-force': 'CSG HYDRAULICING FORCE',
  'stuck-pipe-identification': 'STUCK PIPE IDENTIFICATION',
  'directional-wells': 'DIRECTIONAL WELLS',
  'balanced-plug': 'Balanced Plug',
  'wiper-plug-cementation': 'Wiper plug Cementation',
  'liner-cementation': 'Liner cementation',
  'api-13d-power-law': 'Hydraulics-API 13D Power Law',
  'bingham': 'Bingham',
  'hydraulics': 'HYDRAULICS',
  'cutting-skips': 'Cutting Skips Estimator',
  'whipstock': 'Whipstock',
  'whipstock-fishing': 'Whipstock Fishing',
  'squeeze-cementing-ezsv': 'Squeeze cementing EZSV',
  'actual-result-squeeze': 'Actual Result Squeeze',
  'balanced-plug-3-case': 'Balanced Plug 3-Case',
  'cementing-calculator': 'Cementing Calculator',
  'thickening-time': 'Thickening Time',
};

const Map<String, Map<String, String>> _workbookFormulaNotes = {
  'bits-lcm': {
    'Nozzle area': 'nozzleSize^2 / 1303.8',
    'TFA': 'singleNozzleArea * nozzleCount',
    'Nozzle pressure drop':
        'flowRate^2 * mudWeight / (10858 * TFA^2) — workbook omitted the '
            'square on TFA; corrected per standard bit hydraulics',
    'HHP': 'nozzlePressureDrop * flowRate / 1714',
    'HSI': 'HHP * 1.27 / holeDiameter^2',
    'LCM pass limit': 'nozzleDiameter * 25.4 / 3 vs maxParticle * 0.8',
  },
  'hole-cleaning': {
    'Annular area': '(holeSize^2 - pipeOd^2) / 1029.4',
    'Annular velocity': '24.51 * flowRate / (holeSize^2 - pipeOd^2)',
    'Rheology factor': 'sheet piecewise RF from PV, YP, and hole size',
    'Angle factor': 'SPE 27486 angle lookup',
    'Transport index': 'RF * AF * mudWeightSG',
    'Critical flow rate': 'base CFR * washout correction',
    'Cuttings concentration':
        'cuttingsRate / (flowRate + cuttingsRate), both in cu ft/min',
  },
  'loss-monitoring': {
    'Calculated loss': 'max(0, pumpedVolume - returnedVolume)',
    'Observed loss': 'max(0, -pitGain)',
    'Best loss estimate': 'max(calculatedLoss, observedLoss)',
    'Loss rate': 'bestLoss * 60 / elapsedMinutes',
  },
  'pipe-stretch': {
    'Steel area': 'pi * (pipeOd^2 - pipeId^2) / 4',
    'Calculated stretch': 'overpullLb * lengthFt * 12 / (30000000 * area)',
    'Free point': 'measuredStretch * 30000000 * area / (overpullLb * 12)',
    'Rule of thumb': '0.75 ft per 1000 ft of pipe',
  },
  'fishing-backoff': {
    'Buoyancy factor': '(65.5 - mudWeight) / 65.5',
    'Buoyed string weight': 'freePoint * pipeWeight * buoyancy / 1000',
    'Backoff turns': 'freePoint * turnsPerThousand / 1000',
    'Neutral weight': 'buoyedWeight - workingOverpull',
  },
  'fit-calc': {
    'Hole volume': 'depthTvd * holeDiameter^2 / 1029.4',
    'Required pressure': '(fitEmw - mudWeight) * depthTvd * 0.052',
    'Expected volume': 'holeVolume * requiredPressure * compressibility',
    'Expected strokes': 'expectedVolume / pumpOutput',
    'Pressure per bbl': '1 / (holeVolume * compressibility)',
    'Funnel viscosity rule of thumb': '4 * mudWeight (seconds, workbook I3)',
  },
  'mud-mixing': {
    'Barite density': 'bariteSG * 350',
    'Final weighted volume':
        'initialVolume * (bariteDensity - initialWeight*42) / (bariteDensity - targetWeight*42)',
    'Barite pounds': 'bariteDensity * (finalVolume - initialVolume)',
    'Dilution volume': 'mass balance against baseFluidWeight',
  },
  'fasdrill': {
    'HHP': 'bitPressureDrop * flowRate / 1714',
    'HSI': 'HHP / bitArea',
    'Bit pressure share': 'bitPressureDrop / surfacePressure',
    'Optimum bit drop (impact)':
        'm / (m + 2) * maxPressure — workbook reported the parasitic loss '
            '2/(m+2) and labeled it as bit drop; corrected',
    'Optimum bit drop (HHP)': 'm / (m + 1) * maxPressure — corrected likewise',
  },
  'step-down-fasdrill': {
    'Dynamic pressure': 'referencePressure - staticOffset',
    'Target pressure':
        'staticOffset + dynamicPressure * (targetFlow/referenceFlow)^m',
    'Pressure drop': 'referencePressure - targetPressure',
  },
  'casing-hydraulic-force': {
    'Piston area': 'pi * casingOd^2 / 4 (workbook I1)',
    'Steel area': 'pi * (casingOd^2 - casingId^2) / 4',
    'Buoyancy factor': '1 - (MW/8.33)/7.85 (workbook B12)',
    'Upward hydraulic force': 'pressure * pistonArea / 1000',
    'Pressure to lift casing': 'buoyedWeight * 1000 / pistonArea (workbook I12)',
    'Shoe track volume': 'casingId^2 / 1029.4 * shoeTrackLength',
  },
  'stuck-pipe-identification': {
    'Differential score': 'circulation + no-rotation + stationary indicators',
    'Packoff score': 'no-circulation + pressure increase + blocked movement',
    'Keyseat score': 'rotation + no down movement + overpull indicators',
    'Diagnosis': 'largest mechanism score wins',
  },
  'directional-wells': {
    'Dogleg angle': 'minimum curvature cosine formula',
    'Ratio factor': '2 / dogleg * tan(dogleg / 2)',
    'TVD increment': 'course/2 * (cos inc1 + cos inc2) * RF',
    'North/East': 'minimum curvature displacement components',
  },
  'balanced-plug': {
    'Annulus capacity': '(holeId^2 - dpOd^2) / 1029.4',
    'TOC': 'plugBottom - plugHeight',
    'Spacer top': 'plugBottom - plugHeight - spacerLength',
    'Displacement': 'plugBottom * dpCapacity - internalPlug - postFlush - 3',
  },
  'wiper-plug-cementation': {
    'Casing capacity': 'casingId^2 / 1029.4',
    'Inside volume': 'surfaceLineVolume + casingCapacity * floatCollarDepth',
    'Displacement': 'insideVolume - shoeTrackVolume - underDisplacement',
    'Strokes': 'displacement / pumpOutput',
  },
  'liner-cementation': {
    'Open-hole annulus': '(holeDiameter^2 - linerOd^2) / 1029.4',
    'Overlap annulus':
        '(prevCasingId^2 - linerOd^2) / 1029.4 — legacy version wrongly '
            'reused the open-hole capacity for the overlap',
    'Slurry volume':
        'openHoleVol * (1 + excess) + overlapVol + shoeTrackVol',
    'Sacks': 'slurryVolume * 5.6146 / slurryYield',
    'Displacement':
        'dpCap * linerTop + linerCap * (linerLength - shoeTrack) '
            '(workbook C29)',
  },
  'api-13d-power-law': {
    'Flow index n': '3.32 * log10(theta600 / theta300)',
    'Consistency K': 'theta300 / 511^n',
    'Annular velocity': '24.48 * flowRate / (hole^2 - pipeOd^2)',
    'Pressure loss': 'API 13D power-law annular pressure snapshot',
  },
  'bingham': {
    'PV': 'theta600 - theta300',
    'YP': 'theta300 - PV',
    'Nozzle pressure drop': 'mudWeight * flowRate^2 / (10858 * TFA^2)',
    'Nozzle velocity': '0.321 * flowRate / TFA',
  },
  'hydraulics': {
    'Bit HHP': 'bitPressureDrop * flowRate / 1714',
    'ECD': 'mudWeight + annulusPressureLoss / (0.052 * TVD)',
    'Lag time': 'annulusVolume * 42 / flowRate',
    'Bit pressure share': 'bitPressureDrop / surfacePressure',
  },
  'cutting-skips': {
    'Gauge hole volume': 'holeDiameter^2 / 1029.4 * intervalLength',
    'Bulk cuttings volume': 'holeVolume * (1 + washout) * bulkFactor',
    'Estimated skips': 'bulkCuttingsVolume / skipCapacity',
  },
  'whipstock': {
    'Window offset': 'tan(rampAngle) * windowLength',
    'Added inclination': 'buildRate * sidetrackLength / 100',
    'Projected offset': 'windowOffset + sin(averageAngle) * sidetrackLength',
  },
  'whipstock-fishing': {
    'Pickup requirement': 'fishWeight + dragAllowance',
    'Overpull margin': 'availableOverpull - pickupRequirement',
    'Jar energy proxy': 'overpullLb * jarStroke / 12',
  },
  'squeeze-cementing-ezsv': {
    'Annular capacity': '(holeDiameter^2 - pipeOd^2) / 1029.4',
    'Squeeze volume': 'annularCapacity * intervalLength * (1 + excess)',
    'Cement sacks': 'squeezeVolume * 5.6146 / slurryYield',
    'Pressure margin': 'maxPressure - plannedPressure',
  },
  'actual-result-squeeze': {
    'Retained volume': 'max(0, pumpedVolume - returnsVolume)',
    'Retention': 'retainedVolume / pumpedVolume',
    'Final EMW': 'mudWeight + finalPressure / (0.052 * depthTvd)',
  },
  'balanced-plug-3-case': {
    'Open-hole volume': '(plugBottom - shoeDepth) * ohSize^2 / 1029.4',
    'Remaining cement': 'plugVolume - openHoleVolume',
    'Plug height': 'open-hole height + remaining / (dpCapacity + casedAnnulus)',
    'Placement case': 'volume comparison against open-hole capacity',
  },
  'cementing-calculator': {
    'OH annular capacity': '(holeDiameter^2 - casingOd^2) / 1029.4',
    'Cased annular capacity': '(previousCasingId^2 - casingOd^2) / 1029.4',
    'Lead volume': 'leadOH*ohCap*(1+OH excess) + leadCased*casedCap',
    'Tail volume': 'tailOH*ohCap*(1+OH excess) + shoeTrackVolume',
    'Sacks': 'slurryVolume * 5.6146 / slurryYield',
    'Displacement': 'insideVolume - shoeTrackVolume - underDisplacement',
  },
  'thickening-time': {
    'API TT minutes': 'apiThickeningTimeHours * 60',
    'Shear loss': 'apiMinutes * shearSensitivity',
    'Safe working time': '(apiMinutes - shearLoss - batchMix) * (1 - margin)',
    'Gel pressure': 'abs((SGSD / 300) * (TOC - depth) / (hole - pipe))',
    'Rheology': 'PV = 300 rpm - 200 rpm; YP = 200 rpm - PV',
  },
};

FieldCalculatorResult _num(
  String label,
  double value,
  String unit, {
  required int digits,
  FieldCalculatorTone tone = FieldCalculatorTone.neutral,
}) {
  return FieldCalculatorResult(
    label: label,
    value: _format(value, digits),
    unit: unit,
    tone: tone,
  );
}

FieldCalculatorResult _text(
  String label,
  String value, {
  FieldCalculatorTone tone = FieldCalculatorTone.neutral,
}) {
  return FieldCalculatorResult(label: label, value: value, tone: tone);
}

String _format(double value, int digits) {
  if (value.isNaN || value.isInfinite) {
    return 'ERR';
  }
  return value.toStringAsFixed(digits);
}

double _v(Map<String, double> values, String id) {
  return values[id] ?? 0;
}

int _inputTraceDigits(double value) {
  if (value.abs() < 0.001 && value != 0) {
    return 8;
  }
  if (value == value.roundToDouble()) {
    return 0;
  }
  return 3;
}

double _safeDiv(double numerator, double denominator) {
  if (denominator.abs() < 0.0000001) {
    return 0;
  }
  return numerator / denominator;
}

double _rad(double degrees) => degrees * math.pi / 180;

double _deg(double radians) => radians * 180 / math.pi;

double pipeCapacity(double diameterIn) {
  return math.max(0, diameterIn * diameterIn / barrelCapacityFactor).toDouble();
}

double annularCapacityFn(double outerDiameterIn, double innerDiameterIn) {
  return annularCapacity(outerDiameterIn, innerDiameterIn);
}

double _angleFactor(double angle) {
  if (angle >= 80) return 1.0;
  if (angle >= 70) return 1.02;
  if (angle >= 65) return 1.05;
  if (angle >= 60) return 1.07;
  if (angle >= 55) return 1.10;
  if (angle >= 50) return 1.14;
  if (angle >= 45) return 1.18;
  if (angle >= 40) return 1.24;
  if (angle >= 35) return 1.31;
  if (angle >= 30) return 1.39;
  if (angle >= 25) return 1.51;
  if (angle >= 20) return 1.53;
  if (angle >= 15) return 1.55;
  if (angle >= 10) return 1.58;
  return 1.6;
}

double _washoutFactor(double gaugeHole, double actualHole) {
  if (actualHole <= gaugeHole) {
    return 1;
  }
  if (gaugeHole <= 9.875) {
    return 1 + (actualHole - gaugeHole) * (2.55 - 1) / (14 - 8.5);
  }
  if (gaugeHole <= 14) {
    return 1 + (actualHole - gaugeHole) * (1.82 - 1) / (18 - 12.25);
  }
  return 1 + (actualHole - gaugeHole) * (1.34 - 1) / (23 - 17.5);
}
