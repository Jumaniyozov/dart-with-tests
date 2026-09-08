import 'package:ch02_greeting/greeting.dart';
import 'package:test/test.dart';

void main() {
  test('greets a person in English by default', () {
    expect(hello('Islom'), 'Hello, Islom');
  });
}
