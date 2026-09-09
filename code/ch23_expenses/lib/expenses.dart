// #region barrel
/// The expense tracker's public face.
///
/// The `library;` line under this comment is what the comment is attached to.
/// Without it the analyzer says the doc comment is dangling — a comment about
/// a library, in a file that never said it was one.
library;

/// One export, and it is a decision: `Money` is what this package offers. The
/// other files under `lib/src/` are this package's business, are not exported,
/// and so nobody outside can come to depend on them.
export 'src/money.dart';

// #endregion barrel
