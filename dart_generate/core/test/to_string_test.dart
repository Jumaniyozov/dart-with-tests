import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('lists every field that is not late', () {
    final model = modelOf('Payment', [
      FieldModel('pence', intType),
      FieldModel('to', stringType),
      FieldModel('label', stringType, isLate: true, hasInitializer: true),
    ]);
    expect(
      codeOf(generateToString(model)),
      "@override\nString toString() => 'Payment(pence: \$pence, to: \$to)';",
    );
  });

  test('keeps only the selected fields', () {
    final model = modelOf('Pair', [
      FieldModel('left', intType),
      FieldModel('right', intType),
    ]);
    expect(
      codeOf(generateToString(model, only: {'right'})),
      contains(r"'Pair(right: $right)'"),
    );
  });

  test('braces a name with a dollar sign', () {
    final model = modelOf('Odd', [FieldModel(r'a$b', intType)]);
    expect(codeOf(generateToString(model)), contains(r"'Odd(a$b: ${a$b})'"));
  });

  test('splits a long text into adjacent literals after a comma', () {
    final model = modelOf('Expense', [
      for (final name in ['amount', 'kind', 'day', 'rate', 'note', 'tip'])
        FieldModel(name, stringType),
      FieldModel('acknowledged', stringType),
    ]);
    expect(
      codeOf(generateToString(model)),
      "@override\nString toString() => "
      "'Expense(amount: \$amount, kind: \$kind, day: \$day, rate: \$rate, '\n"
      "'note: \$note, tip: \$tip, acknowledged: \$acknowledged)';",
    );
  });

  test('noFields', () {
    expect(
      reasonOf(generateToString(ClassModel('Empty', [], null))),
      Reason.noFields,
    );
  });
}
