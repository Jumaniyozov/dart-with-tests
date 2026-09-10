// Study 30 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// All three are calendar arithmetic. Not one of them needs to know what time
// it is, and the third is the only one allowed to build a `DateTime` at all.

import 'package:ch30_expenses/expenses.dart';

/// 1. The month after this one.
///
///    December 2026 is followed by January 2027, which is the only line of
///    this anybody gets wrong.
///
///    `Duration(days: 30)` is not a month and there is no arithmetic on
///    instants that will help you here. Two integers and a carry.
Period nextMonth(Period period) => throw UnimplementedError('1');

/// 2. How many days a period covers.
///
///    28, 29, 30 or 31, and which one depends on the month and sometimes on
///    the year. [Day.lastDayOf] already knows; the point of this one is that
///    the answer is a property of the calendar and not of a clock.
///
///    `Period(2026, 2)` is 28. `Period(2024, 2)` is 29. `Period(1900, 2)` is
///    28, because a hundredth year is not a leap year unless it is also a
///    four-hundredth.
int daysIn(Period period) => throw UnimplementedError('2');

/// 3. The last day of the month that somebody was at work.
///
///    The last day of [period] that is not a Saturday or a Sunday. For
///    September 2026 that is Wednesday the 30th; for February 2026 the 28th
///    is a Saturday, so the answer is Friday the 27th.
///
///    This is the one place in the study where building a `DateTime` is the
///    right move, because a weekday is genuinely not something a year, a month
///    and a day can be asked for on their own. Build it, read `weekday`, and
///    hand back a [Day] — the instant does not escape this function.
///
///    `DateTime.saturday` and `DateTime.sunday` are the constants to compare
///    against. Do not count backwards with a `Duration`.
Day lastWorkingDayOf(Period period) => throw UnimplementedError('3');
