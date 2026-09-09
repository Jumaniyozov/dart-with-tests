import 'package:characters/characters.dart';

// #region truncate
/// Cuts [text] down to [width] characters, marking the cut with an ellipsis.
///
/// Counts what a reader calls a character, so an emoji or an accented letter
/// is never left half-written.
String truncate(String text, int width) {
  final letters = text.characters;
  if (letters.length <= width) return text;

  final kept = StringBuffer();
  var count = 0;
  for (final letter in letters) {
    if (count == width) break;
    kept.write(letter);
    count++;
  }
  return '$kept…';
}
// #endregion truncate

// #region widths
/// The three ways to ask how long [text] is, which rarely agree.
///
/// Returns storage units, code points, and characters — in that order.
String widths(String text) =>
    '${text.length} ${text.runes.length} ${text.characters.length}';
// #endregion widths
