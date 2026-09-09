// #region cast
// Run this to see what a private constructor does not close.
import 'package:ch23_expenses/src/pence.dart';

void main() {
  print('through the factory: ${Pence.fromValue(1250).value}');
  print('through the cast   : ${(-1 as Pence).value}');
}
// #endregion cast
