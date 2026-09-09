import 'package:ch03_variables/timing.dart';
import 'package:test/test.dart';

void main() {
  test('maxTagLength is folded by the compiler', () {
    expect(maxTagLength, 60);
  });

  test('stamp reads the clock at run time', () {
    expect(stamp('Dart'), '#dart @ ${DateTime.now().year}');
  });
}
