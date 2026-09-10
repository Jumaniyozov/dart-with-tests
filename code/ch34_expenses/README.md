# expenses

A command-line expense tracker, grown one study at a time across Book II of
*Learn Dart with Tests*.

```console
$ expenses add 4.20 food flat white
2026-09-10  £4.20  food  flat white

$ expenses budget food 60.00
food: £60.00

$ expenses list 2026-09
```

## What this package offers

`lib/expenses.dart` is the whole public surface. Everything under `lib/src/` is
private to the package and free to change without a major version.

- `Money`, `Category`, `Day`, `Period` — values that check themselves.
- `Expense`, `Limit`, `Budget`, `Verdict` — the domain, including the one rule
  no single object can check.
- `Report` — grouping, ordering and totalling.
- `Store`, `InMemoryStore`, `FileStore` — where expenses are kept.
- `run` — one command, start to finish, answering an `Outcome` rather than
  printing.

## Installing

```console
$ dart pub add expenses
```

## Licence

MIT. See `LICENSE`.
