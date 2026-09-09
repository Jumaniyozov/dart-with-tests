import 'package:ch05_label/label.dart';
import 'package:test/test.dart';

void main() {
  test('cuts a long label and marks the cut', () {
    expect(truncate('Hello world', 5), 'Hello…');
  });
}
