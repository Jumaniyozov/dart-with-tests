# Expense tracker

The domain built across Books II and III, studies 23–39. Book I has no domain: each of
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

**Store**:
What holds expenses.
_Avoid_: Ledger (a ledger is double-entry and this is not), Repository, Database, Log

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
Everything the program can be asked to do, said in the words above. It holds a Store and
the day it thinks it is, and it answers in Expenses, Budgets and Verdicts — never in exit
codes, status codes or text meant for a person. Both edges call it; neither is named in it.
_Avoid_: Service, Manager, Facade, Controller, UseCase, Interactor

## Deliberately absent

- **Income**, and therefore **Balance**. The tracker records money out only.
- **Refund**. A negative expense is unrepresentable by design; if refunds are ever
  added, they need their own term rather than a negative Money.
- **Account**. There is one person and one file.
