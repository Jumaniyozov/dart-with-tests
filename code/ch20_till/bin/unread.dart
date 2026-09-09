import 'package:ch20_till/till.dart';

/// A till roll with one line nobody can read, and nobody to catch it.
void main() {
  print(totalOf(['12.34', '0.50']));
  print(totalOf(['12.34', 'twelve', '0.50']));
}
