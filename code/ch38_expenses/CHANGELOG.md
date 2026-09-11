## 4.0.0

A major version for a parameter that became a function. `Tracker` takes a
`Day Function()` instead of a `Day`, because a server that runs for days cannot
be told once what day it is. Study 28 said a signature is a promise about time;
`Day today` promised that the day never changes.

- **Changed** — `Tracker(Store store, Day Function() today)`. Every read of the
  day now says, in one pair of parentheses, that it is asking. `run` still takes
  a `Day` and hands over `() => today`, because a command reads the clock once
  and is finished before it could be wrong — so `test/command_test.dart` was not
  edited for a third study.
- **Added** — `HoldingStore`, exported. It reads what it wraps once and holds on
  until a number it was given changes. It has never heard of a file: what a
  cache needs is a cheap way to ask whether the answer moved, not the thing it
  is caching.
- **Added** — `bin/holding.dart`, which is `bin/serve.dart` with the file's
  length read once at startup instead of asked for. It exists so that one page
  can show what that costs, the way study 35's `bin/by_hand.dart` did, and it
  will go the same way.
- **Changed** — `bin/serve.dart` serves from a `HoldingStore` over a `FileStore`
  and asks the file for its length on every read. A `stat` instead of a read.

## 3.0.0

A major version for a field. `Breach` carries the `Limit` it broke as well as
how far over the expense went, and the field list of a primary constructor is
its parameter list — so every place a `Breach` is built has to say which limit.
`test/surface_test.dart` is byte-identical to study 36's and noticed none of it:
the barrel offers the same twelve libraries and `bin/` the same two programs. A
contract test protects exactly the surface it was written about.

- **Changed** — `Breach(Money over, Limit limit)`. The budget had the limit in
  hand when it made the decision; handing it over saves the only two callers
  that wanted it a second read of the store.
- **Changed** — the command line's refusal message is assembled from the
  breach alone. Not one character of it moved, which is why
  `test/command_test.dart` was not edited.
- **Added** — an HTTP surface. `GET /expenses` (with `month` and `limit`),
  `POST /expenses`, `GET /budgets`, `GET /budgets/<category>`, every answer a
  JSON document and every refusal the same shape.
- **Added** — `expensesApi`, a `Pipeline` of two middleware over the routes: a
  shared key, and a fault handler that answers one fixed sentence and reports
  everything else to a function handed in from `bin/`.
- **Added** — `bin/serve.dart` reads `EXPENSES_KEY` from the environment and
  refuses to start without one.
- Depends on `shelf_router: ^1.1.4`. No type of its own is in this package's
  public surface, and `test/surface_test.dart` asserts it.

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
