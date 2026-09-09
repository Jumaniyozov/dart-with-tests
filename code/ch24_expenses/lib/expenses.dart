// #region barrel
/// The expense tracker's public face.
///
/// The `library;` line under this comment is what the comment is attached to.
/// Without it the analyzer says the doc comment is dangling — a comment about
/// a library, in a file that never said it was one.
library;

/// Two exports now, and the choice is the same one study 23 made: these are
/// what this package offers. The files under `lib/src/` that nothing exports
/// are its own business.
export 'src/command.dart';
export 'src/money.dart';

// #endregion barrel
