import 'package:ch03_variables/tags.dart';
import 'package:test/test.dart';

void main() {
  group('tag', () {
    test('lowercases the name', () {
      expect(tag('Dart'), '#dart');
    });

    test('trims surrounding whitespace', () {
      expect(tag('  Dart  '), '#dart');
    });

    test('calls a blank name untitled', () {
      expect(tag('   '), '#untitled');
      expect(tag(''), '#untitled');
    });
  });

  group('lengthOf', () {
    test('counts every character', () {
      expect(lengthOf('dart'), 4);
    });

    test('counts nothing in an empty string', () {
      expect(lengthOf(''), 0);
    });
  });
}
