import 'package:fixtures/copy_with.dart';
import 'package:test/test.dart';

void main() {
  test('copyWith goes through the validating factory', () {
    expect(() => Limit('food', 5).copyWith(category: ''), throwsArgumentError);
    expect(Limit('food', 5).copyWith(pence: 7).pence, 7);
  });

  test('copyWith clears a nullable field and keeps it by default', () {
    final deposit = Deposit(5, 'tea');
    expect(deposit.copyWith(note: null).note, isNull);
    expect(deposit.copyWith(pence: 6).note, 'tea');
    expect(deposit.copyWith(pence: 6).pence, 6);
  });

  test('copyWith clears a nullable type parameter', () {
    final box = Box<int?>(5, 1, 'n');
    expect(box.copyWith(value: null).value, isNull);
    expect(box.copyWith(note: 'm').value, 5);
  });
}
