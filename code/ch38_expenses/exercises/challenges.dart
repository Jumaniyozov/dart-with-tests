// Study 38 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three are about holding something and knowing when to stop. One is the
// question a cache asks, one is a cache that answers it differently from the
// one this study shipped, and one is the single line of `bin/serve.dart` that
// has to touch a disk to answer it at all.

import 'dart:io';

import 'package:ch38_expenses/expenses.dart';

/// 1. The question [HoldingStore] asks, on its own.
///
///    Answer a function that answers `true` when [version] has moved since the
///    last time it was called, and `false` when it has not.
///
///    Two cases decide the shape. **The first call has nothing to compare
///    against**, and the useful answer there is `true` — a cache that has never
///    read anything has to read. And a version that goes *down* has changed:
///    the number is a stamp, not a clock, and a file that got shorter is a file
///    somebody rewrote.
///
///    A closure over a local is all this needs. `int?` is how you say *nothing
///    yet* without picking a number that means it, which is
///    `HoldingStore._read`'s reason too.
bool Function() changed(int Function() version) =>
    throw UnimplementedError('1');

/// 2. A cache that makes the opposite bet from this study's.
///
///    Answer a [Store] that wraps [inner], **holds the limits for ever**, and
///    never holds the expenses. Reads of `limits` go through once; reads of
///    `all` go through every time. Writes go straight through, both of them.
///
///    That is not a silly policy: somebody sets a budget a few times a year and
///    spends money every day, so the two halves of this [Store] have different
///    answers to *how likely is it that this changed?* It is still a bet, and
///    naming which bet you are making is the whole of 38.2.
///
///    You will need a class. `implements Store` and delegate — study 27 is why
///    that is four short members and not a framework.
Store limitsHeld(Store inner) => throw UnimplementedError('2');

/// 3. The one line of `bin/serve.dart` that has to touch a disk.
///
///    Answer a function giving the number of bytes in [file], and `0` when
///    there is no such file.
///
///    `File.lengthSync` does **not** answer `0` for a file that is not there —
///    measured, it throws a `PathNotFoundException`, which is a
///    `FileSystemException`, which would arrive at a request as a `500`. A
///    store with no file behind it is not an error: `FileStore` answers an
///    empty list for one, so `0` is the true version of that answer.
///
///    Ask before doing, which is 26.3's shape and is now the third time this
///    program has needed it at an edge.
int Function() lengthOf(File file) => throw UnimplementedError('3');
