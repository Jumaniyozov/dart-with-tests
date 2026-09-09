// #region kind
/// What an entry does to the balance.
///
/// A ledger entry is an amount in pence: money in is positive, money out is
/// negative, and an entry of zero is a line someone left blank.
enum Kind { credit, debit, nothing }

Kind kindOf(int pence) {
  if (pence > 0) {
    return Kind.credit;
  } else if (pence < 0) {
    return Kind.debit;
  } else {
    return Kind.nothing;
  }
}
// #endregion kind

// #region label
/// The column heading an entry belongs under.
String labelFor(int pence) => switch (kindOf(pence)) {
  .credit => 'in',
  .debit => 'out',
  .nothing => 'nil',
};
// #endregion label

// #region count
/// How many entries of each kind [entries] holds.
Map<Kind, int> countByKind(List<int> entries) {
  var credits = 0;
  var debits = 0;
  var nothings = 0;

  for (final entry in entries) {
    switch (kindOf(entry)) {
      case Kind.credit:
        credits++;
      case Kind.debit:
        debits++;
      case Kind.nothing:
        nothings++;
    }
  }

  return {Kind.credit: credits, Kind.debit: debits, Kind.nothing: nothings};
}
// #endregion count

// #region total
/// The balance, added up by walking the list one index at a time.
int total(List<int> entries) {
  var balance = 0;
  for (var i = 0; i < entries.length; i++) {
    balance += entries[i];
  }
  return balance;
}
// #endregion total

// #region totalin
/// The same balance, asking for the entries instead of for their positions.
int totalIn(List<int> entries) {
  var balance = 0;
  for (final entry in entries) {
    balance += entry;
  }
  return balance;
}
// #endregion totalin

// #region overdraft
/// The position of the entry that first takes the balance below zero,
/// or `-1` when it never goes below.
int firstOverdraft(List<int> entries) {
  var balance = 0;
  var found = -1;

  for (var i = 0; i < entries.length; i++) {
    balance += entries[i];
    if (balance < 0) {
      found = i;
      break;
    }
  }

  return found;
}
// #endregion overdraft

// #region credits
/// The total of the money coming in, ignoring everything else.
int creditsIn(List<int> entries) {
  var balance = 0;
  for (final entry in entries) {
    if (entry <= 0) continue;
    balance += entry;
  }
  return balance;
}
// #endregion credits

// #region digits
/// How wide a column must be to hold [pence] written out. Zero needs one.
int digitsIn(int pence) {
  assert(pence >= 0, 'a negative amount has no column width');

  var left = pence;
  var digits = 0;
  do {
    digits++;
    left ~/= 10;
  } while (left > 0);
  return digits;
}
// #endregion digits

// #region shared
/// The first amount in [mine] that also appears in [theirs], or nothing.
int? firstShared(List<int> mine, List<int> theirs) {
  int? shared;

  outer:
  for (final entry in mine) {
    for (final other in theirs) {
      if (entry == other) {
        shared = entry;
        break outer;
      }
    }
  }

  return shared;
}
// #endregion shared
