// #region inside
// Run this to see the boundary from the inside.
import 'package:ch23_expenses/src/crowded.dart';

void main() {
  print('through the factory : ${Amount.fromPence(1250).pence}');
  print('through the backdoor: ${Backdoor.unchecked(-5).pence}');
}
// #endregion inside
