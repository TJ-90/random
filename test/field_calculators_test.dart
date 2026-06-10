import 'package:drillcalc/calculators/field_calculators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('field calculators', () {
    test('includes calculators for the remaining workbook tabs', () {
      final titles = fieldCalculators.map((calculator) => calculator.title);

      expect(titles, contains('Bits & LCM'));
      expect(titles, contains('Hole Cleaning'));
      expect(titles, contains('Pipe Stretch'));
      expect(titles, contains('Mud Mixing'));
      expect(titles, contains('Balanced Plug'));
      expect(titles, contains('Cementing Calculator'));
      expect(titles, contains('Thickening Time'));
      expect(fieldCalculators.length, greaterThanOrEqualTo(26));
    });

    test('uses the corrected bit nozzle pressure-drop formula (TFA squared)', () {
      // The workbook's Bits & LCM tab computed MW*Q^2/(10858*TFA), which is
      // wrong; the standard formula divides by TFA^2 (as the workbook's own
      // Bingham tab does). Corrected value for the sample inputs is ~186 psi,
      // not the workbook's 278 psi.
      final results = _calculateDefaults('bits-lcm');

      expect(_result(results, 'Total flow area'), '1.491');
      expect(_result(results, 'Nozzle pressure drop'), '186');
      expect(_result(results, 'Hydraulic horsepower'), '54.4');
      expect(_result(results, 'HSI'), '0.77');
      expect(_result(results, 'LCM advisory'), 'Reduce max particle size');
    });

    test('matches Hole Cleaning workbook sample status', () {
      final results = _calculateDefaults('hole-cleaning');

      expect(_result(results, 'Annular area'), '0.0537');
      expect(_result(results, 'Annular velocity'), '177');
      expect(_result(results, 'Critical flow rate'), '156');
      expect(_result(results, 'Hole cleaning status'), 'GOOD');
      expect(_result(results, 'Max safe ROP at this flow'), '73.1');
      expect(_result(results, 'Cuttings concentration'), '0.00');
    });

    test('reports optimum BIT pressure drops, not parasitic losses', () {
      // For parasitic losses Pc = K*Q^m the optimum bit pressure drop is
      // m/(m+2)*Pmax (impact force) and m/(m+1)*Pmax (bit HHP). The workbook
      // reported the complementary parasitic losses under these labels.
      final results = _calculateDefaults('fasdrill');

      expect(_result(results, 'Optimum bit drop for impact force'), '2168');
      expect(_result(results, 'Optimum bit drop for HHP'), '2927');
    });

    test('liner cementation uses previous casing ID for the overlap', () {
      final results = _calculateDefaults('liner-cementation');

      expect(_result(results, 'Open-hole annular capacity'), '0.0226');
      expect(_result(results, 'Overlap annular capacity'), '0.0389');
      expect(_result(results, 'Slurry volume (incl shoe track)'), '117.4');
      expect(_result(results, 'Cement sacks'), '559');
      expect(_result(results, 'Displacement (DP + liner)'), '364.8');
    });

    test('casing hydraulic force reports the workbook force balance', () {
      final results = _calculateDefaults('casing-hydraulic-force');

      expect(_result(results, 'Casing piston area (OD)'), '72.8');
      expect(_result(results, 'Casing air weight'), '564.0');
      expect(_result(results, 'Buoyancy factor'), '0.809');
      expect(_result(results, 'Buoyed casing weight'), '456.2');
      expect(_result(results, 'Upward hydraulic force'), '109.1');
      expect(_result(results, 'Net force (down +ve)'), '347.0');
      expect(_result(results, 'Pressure to lift casing'), '6270');
    });

    test('matches cementing and thickening workbook samples', () {
      final cementing = _calculateDefaults('cementing-calculator');
      final thickening = _calculateDefaults('thickening-time');

      expect(_result(cementing, 'Lead slurry volume'), '155.4');
      expect(_result(cementing, 'Tail slurry volume'), '173.2');
      expect(_result(cementing, 'Total slurry volume'), '328.6');
      expect(_result(cementing, 'Strokes to displace'), '7454');
      expect(_result(thickening, 'Safe working time'), '79');
      expect(_result(thickening, 'Job verdict'), 'DANGER - redesign slurry');
      expect(_result(thickening, 'Extra annular pressure'), '56.9');
    });

    test(
      'exposes workbook input trace and formula notes for every calculator',
      () {
        for (final calculator in fieldCalculators) {
          final values = {
            for (final input in calculator.inputs) input.id: input.defaultValue,
          };
          final inputTrace = workbookInputTrace(calculator, values);
          final formulaNotes = workbookFormulaNotes(calculator);

          expect(inputTrace.first.label, 'Source sheet');
          expect(inputTrace.first.value, isNotEmpty);
          expect(inputTrace.length, calculator.inputs.length + 1);
          expect(formulaNotes, isNotEmpty);
        }
      },
    );

    test('every calculator survives all-zero inputs without NaN/Infinity', () {
      for (final calculator in fieldCalculators) {
        final values = {for (final input in calculator.inputs) input.id: 0.0};
        final results = calculator.calculate(values);

        for (final result in results) {
          expect(
            result.value,
            isNot('ERR'),
            reason: '${calculator.id} -> ${result.label}',
          );
        }
      }
    });

    test('exposes corrected formula details for the fixed tabs', () {
      final bits = fieldCalculatorById('bits-lcm');
      final cementing = fieldCalculatorById('cementing-calculator');
      final liner = fieldCalculatorById('liner-cementation');

      expect(
        _formula(bits, 'Nozzle pressure drop'),
        contains('10858 * TFA^2'),
      );
      expect(
        _formula(cementing, 'Displacement'),
        'insideVolume - shoeTrackVolume - underDisplacement',
      );
      expect(
        _formula(liner, 'Overlap annulus'),
        contains('prevCasingId^2 - linerOd^2'),
      );
    });
  });
}

List<FieldCalculatorResult> _calculateDefaults(String id) {
  final calculator = fieldCalculatorById(id);
  final values = {
    for (final input in calculator.inputs) input.id: input.defaultValue,
  };
  return calculator.calculate(values);
}

String _result(List<FieldCalculatorResult> results, String label) {
  return results.firstWhere((result) => result.label == label).value;
}

String _formula(FieldCalculatorDefinition definition, String label) {
  return workbookFormulaNotes(
    definition,
  ).firstWhere((result) => result.label == label).value;
}
