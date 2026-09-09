import 'package:ch03_variables/tags.dart';

// #region timing
/// The compiler can work out `30 * 2` on its own, so `maxTagLength` is stored
/// in the program as 60. Nothing is computed when the program runs.
const maxTagLength = 30 * 2;

/// The clock only exists while the program is running, so the year cannot be
/// stored in the program ahead of time. `final` computes it once, on the line
/// where it is written, and then leaves it alone.
String stamp(String name) {
  final now = DateTime.now();
  return '${tag(name)} @ ${now.year}';
}
// #endregion timing
