// Stage 1: the obvious version. `length` and `substring` both count UTF-16
// code units, which is not what a reader means by "characters".
// #region truncate
String truncate(String text, int width) =>
    text.length <= width ? text : '${text.substring(0, width)}…';
// #endregion truncate
