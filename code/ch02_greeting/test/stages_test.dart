// Proves every intermediate stage shown in the chapter really compiles and
// behaves as printed. Not shown in the book.
import 'package:ch02_greeting/v1.dart' as v1;
import 'package:ch02_greeting/v2.dart' as v2;
import 'package:ch02_greeting/v3.dart' as v3;
import 'package:test/test.dart';

void main() {
  test('stage 1 greets the world', () {
    expect(v1.hello(), 'Hello, world');
  });

  test('stage 2 greets by name', () {
    expect(v2.hello('Islom'), 'Hello, Islom');
  });

  test('stage 3 uses the named prefix', () {
    expect(v3.hello('Islom'), 'Hello, Islom');
    expect(v3.englishHelloPrefix, 'Hello, ');
  });
}
