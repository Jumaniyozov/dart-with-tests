// Stage 2: counting code points instead of code units. Emoji survive. Anything
// built from more than one code point still does not.
// #region truncate
String truncate(String text, int width) {
  if (text.runes.length <= width) return text;

  final kept = StringBuffer();
  var count = 0;
  for (final rune in text.runes) {
    if (count == width) break;
    kept.writeCharCode(rune);
    count++;
  }
  return '$kept…';
}
// #endregion truncate
