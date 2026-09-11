# Expense tracker

The domain built across Books II and III, studies 23–40. Book I has no domain: each of
its studies is an independent toy, so this file starts at study 23.

Where prose and code disagree about a word, this file decides. Rationale lives in
`docs/adr/0003-book-ii-ordered-by-when-it-runs.md`, not here.

## Language

**Money**:
A non-negative amount of pence. Zero is money; a negative amount is not.
_Avoid_: Amount, Price, Cost, Cash

**Category**:
A label a person chooses for their spending. Not drawn from a fixed list, and two
spellings that mean the same thing are the same category.
_Avoid_: Tag, Bucket, Type, Kind

**Day**:
A calendar day, the same everywhere on Earth. Not a moment in time.
_Avoid_: Date, DateTime, Timestamp, Instant

**Expense**:
Money out — an amount, a category, a day and a note. It has identity: two coffees for
the same amount on the same day are two expenses, not one counted twice.
_Avoid_: Transaction, Entry, Purchase, Item, Spend

**Transaction** is on that list and study 39's title uses the word anyway, which is
worth one sentence rather than an exception. There it means SQLite's — `BEGIN`,
`COMMIT`, `ROLLBACK`, a unit of work a database either applies or does not. It is
never a thing the tracker records, and nothing in the domain is ever called one.

**Store**:
What holds expenses.
_Avoid_: Ledger (a ledger is double-entry and this is not), Repository, Database, Log

  *Database* stays on that list and `SqliteStore` does not break it: the domain word
  for what holds expenses is still Store, and a database is one of the things a Store
  can be. Book III has three of them and no reader has to know which is behind a
  `Tracker`.

**Budget**:
A spending limit for one category over one period.
_Avoid_: Limit, Cap, Allowance, Target

**Period**:
The stretch a budget covers: one calendar month, made of days.
_Avoid_: Month, Range, Interval, Window

**Report**:
A view computed from expenses — totals, groupings, comparisons against budgets. Always
computed, never stored.
_Avoid_: Summary, Statement, Overview

**Tracker**:
Everything the program can be asked to do, said in the words above. It holds a Store,
**asks** what day it is, and is **told** whether it is alone; it answers in Expenses,
Budgets and Verdicts — never in exit codes, status codes or text meant for a person. Both
edges call it; neither is named in it. (It held the day until study 38, which is the study
about what holding costs.)
_Avoid_: Service, Manager, Facade, Controller, UseCase, Interactor

  **Alone is not a domain word and does not get an entry**, which ADR 0005's *one new
  term* rule is the reason for. It is a capability the edge hands over, like the clock
  before it, and the tracker knows no more about what it does than it knows about which
  calendar the day came from. If it ever needs a noun, something has leaked.

## Deliberately absent

- **Income**, and therefore **Balance**. The tracker records money out only.
- **Refund**. A negative expense is unrepresentable by design; if refunds are ever
  added, they need their own term rather than a negative Money.
- **Account**. There is one person and one store. Study 40 does not change that: two
  writers here are two *programs* — the server and the command line — rather than two
  people, and the shared key study 37 added authenticates a caller for the same reason.
