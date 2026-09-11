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
$ EXPENSES_KEY=a-shared-key dart run bin/serve.dart
listening on http://localhost:8080

$ curl -s -H 'authorization: Bearer a-shared-key' http://localhost:8080/expenses
[{"day":"2026-09-11","pence":420,"category":"food","note":"flat white"}]
```

## What it answers over HTTP

Every request carries `authorization: Bearer <EXPENSES_KEY>`, which
authenticates a **caller** and not a person — this program has no accounts.
Every answer is a JSON document, and every refusal has a `problem` in it.

| | |
| --- | --- |
| `GET /expenses` | everything recorded; `?month=YYYY-MM` and `?limit=N` narrow it |
| `POST /expenses` | `{"pence": 450, "category": "food", "note": "tea"}`, and `"acknowledged": true` to record one over budget |
| `GET /budgets` | every budget in force this month |
| `GET /budgets/<category>` | one of them |

`401` nobody said who is asking · `400` the request could not be read ·
`409` a budget refused it · `404` no such path, or no such budget ·
`500` this program is wrong, and it will not say more than that.

## What this package offers

`lib/expenses.dart` is the whole public surface. Everything under `lib/src/` is
private to the package and free to change without a major version.

- `Money`, `Category`, `Day`, `Period` — values that check themselves.
- `Expense`, `Limit`, `Budget`, `Verdict` — the domain, including the one rule
  no single object can check.
- `Report` — grouping, ordering and totalling.
- `Store`, `InMemoryStore`, `FileStore` — where expenses are kept.
- `HoldingStore` — a `Store` that reads what it wraps once and holds on until a
  number it was given changes. The server serves through one; the command line
  does not, because it exits.
- `Tracker` — every use case the tracker has, in the domain's own words. This
  is what both edges call. It takes a `Day Function()`, not a `Day`: a server
  outlives a day and has to ask.
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
