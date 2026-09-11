## 2.0.0

A major version, for a removal nobody would have noticed: `bin/by_hand.dart` is
gone. It existed so study 35 could compare a hand-rolled `dart:io` server with
`package:shelf`, and `dart run ch35_expenses:by_hand` was a thing a caller could
do. Removing it is a breaking change in exactly the sense study 34 defined, and
`test/surface_test.dart` now holds `bin/` to the same list the barrel is held to.

- **Added** — `Tracker`, exported. Every use case the tracker has, in the
  domain's own vocabulary, with no exit code and no `Outcome` anywhere near it.
- **Changed** — the server answers the expenses as `application/json`, using the
  `toJson` study 29 wrote for the file.
- **Removed** — `bin/by_hand.dart`.

Nothing under `lib/src/` that was offered before has moved. The command line is
byte-identical in behaviour and its tests were not edited.

## 1.1.0

A second entrypoint. Nothing the barrel offers has moved, which is what makes
this a minor version rather than a major one.

- `bin/serve.dart` answers HTTP on port 8080, over the same `Store` the command
  line writes to.
- `bin/by_hand.dart` is the same server without `package:shelf`, kept because
  the comparison is the study.
- Depends on `shelf: ^1.4.2`. No type of its own is in this package's public
  surface, and `test/surface_test.dart` asserts it.

## 1.0.0

First version with a number, which is the first version that promises anything.

- `lib/expenses.dart` is the public surface; everything under `lib/src/` is not.
- Every public member outside a primary constructor carries a doc comment.
- `test/`, `exercises/` and this book's own scaffolding are excluded from the
  published archive by `.pubignore`.
