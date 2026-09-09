import 'package:ch18_range/range.dart';
import 'package:test/test.dart';

void main() {
  test('one Range works for numbers', () {
    expect(Range(100, 500).contains(250), isTrue);
    expect(Range(100, 500).contains(50), isFalse);
  });

  test('and the same one works for words', () {
    expect(Range('ant', 'cat').contains('bee'), isTrue);
    expect(Range('ant', 'cat').contains('dog'), isFalse);
  });
}
