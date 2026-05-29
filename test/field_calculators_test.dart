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

    test('matches Bits & LCM workbook sample calculations', () {
      final results = _calculateDefaults('bits-lcm');

      expect(_result(results, 'Total flow area'), '1.491');
      expect(_result(results, 'Nozzle pressure drop'), '278');
      expect(_result(results, 'Hydraulic horsepower'), '81.1');
      expect(_result(results, 'LCM advisory'), 'Reduce max particle size');
    });

    test('matches Hole Cleaning workbook sample status', () {
      final results = _calculateDefaults('hole-cleaning');

      expect(_result(results, 'Annular area'), '0.0537');
      expect(_result(results, 'Annular velocity'), '177');
      expect(_result(results, 'Critical flow rate'), '156');
      expect(_result(results, 'Hole cleaning status'), 'GOOD');
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
