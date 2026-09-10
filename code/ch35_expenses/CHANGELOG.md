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
