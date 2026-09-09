import 'package:ch19_pence/pence.dart';

/// An extension member found by the compiler, and the same one not found by
/// the machine.
///
/// Nothing here is a type error, because there is no type to check: `total`
/// is `dynamic`, and `dynamic` switches the checking off.
void main() {
  print(1234.asMoney);

  final dynamic total = 1234;
  print(total.asMoney);
}
