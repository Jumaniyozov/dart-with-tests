// Stage 2: the name is cleaned before use. `final` because it is computed
// once and never changes afterwards.
// #region tag
const hashPrefix = '#';

String tag(String name) {
  final cleaned = name.trim().toLowerCase();
  return '$hashPrefix$cleaned';
}
// #endregion tag
