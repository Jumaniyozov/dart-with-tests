import 'package:ch14_command/command.dart';
import 'package:test/test.dart';

void main() {
  test('reads a typed line into a command', () {
    expect(parse('add 250'), (Verb.add, 250));
  });

  test('a line that is not a command reads as nothing', () {
    expect(parse('fly'), isNull);
  });
}
