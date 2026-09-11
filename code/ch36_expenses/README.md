# expenses

An expense tracker with two edges — a command line and an HTTP server — grown
one study at a time across Books II and III of *Learn Dart with Tests*.

```console
$ expenses add 4.20 food flat white
2026-09-10  £4.20  food  flat white

$ expenses budget food 60.00
food: £60.00

$ expenses list 2026-09
```

```console
$ dart run bin/serve.dart
listening on http://localhost:8080

$ curl -s http://localhost:8080/
[{"day":"2026-09-11","pence":420,"category":"food","note":"flat white"}]
```

## What this package offers

`lib/expenses.dart` is the whole public surface. Everything under `lib/src/` is
private to the package and free to change without a major version.

- `Money`, `Category`, `Day`, `Period` — values that check themselves.
- `Expense`, `Limit`, `Budget`, `Verdict` — the domain, including the one rule
  no single object can check.
- `Report` — grouping, ordering and totalling.
- `Store`, `InMemoryStore`, `FileStore` — where expenses are kept.
- `Tracker` — every use case the tracker has, in the domain's own words. This
  is what both edges call.
- `run` — one command line, start to finish, answering an `Outcome` rather than
  printing. The terminal's edge, and only the terminal's.

The server is **not** offered. It hands back a `shelf` `Handler`, and a
dependency's type in a public API makes that dependency's promises part of
yours. `Tracker` is what a caller wanting the same behaviour should reach for.

## Installing

```console
$ dart pub add expenses
```

## Licence

MIT. See `LICENSE`.
