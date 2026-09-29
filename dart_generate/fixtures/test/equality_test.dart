import 'package:fixtures/equality.dart';
import 'package:test/test.dart';

void main() {
  test('an inherited field takes part in == and hashCode', () {
    expect(Payment(3, 'bob'), Payment(3, 'bob'));
    expect(Payment(3, 'bob').hashCode, Payment(3, 'bob').hashCode);
    expect(Payment(3, 'bob'), isNot(Payment(4, 'bob')));
  });

  test('a list field compares by content', () {
    expect(Tagged('a', ['x']), Tagged('a', ['x']));
    expect(Tagged('a', ['x']).hashCode, Tagged('a', ['x']).hashCode);
    expect(Tagged('a', ['x']), isNot(Tagged('a', ['y'])));
  });

  test('a selection leaves the other fields out', () {
    expect(Span(1, 2, 3), Span(1, 2, 4));
  });
}
