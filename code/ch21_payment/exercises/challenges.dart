// Study 21 challenges.
//
// Run `dart test exercises/` to see them fail, then make them pass one at a
// time. Do not edit the tests.
//
// Two functions are given, because all three challenges need something slow
// to wait for.

/// Given. A slow answer that records when it starts and when it ends.
Future<int> slow(String name, int value, List<String> log) async {
  log.add('$name start');
  await Future<void>.delayed(const Duration(milliseconds: 5));
  log.add('$name end');
  return value;
}

/// Given. A job that fails, but only after it has waited.
Future<int> failing() async {
  await Future<void>.delayed(const Duration(milliseconds: 1));
  throw StateError('the job could not finish');
}

/// 1. Every job's answer, added up, with all the waiting done at once.
///
///    `totalOf` is handed jobs rather than futures so that *you* decide when
///    each one starts. Three slow jobs must all have started before any of
///    them finishes.
Future<int> totalOf(List<Future<int> Function()> jobs) {
  throw UnimplementedError('challenge 1');
}

/// 2. Runs [job] and says what happened, whatever happens.
///
///    `'ok 7'` when it answers 7. `'failed: the job could not finish'` when it
///    throws a [StateError] — the message is `error.message`. Either way the
///    last thing in [log] is `'done'`.
Future<String> attempt(Future<int> Function() job, List<String> log) {
  throw UnimplementedError('challenge 2');
}

/// 3. This one is already written, and already wrong.
///
///    It answers `'ok'` for a job that fails. Nothing is missing from the
///    `try`, and the `on` clause names the right type. Read 21.3 and fix the
///    one word that is not there.
Future<String> report(Future<int> Function() job) async {
  try {
    job();
    return 'ok';
  } on StateError {
    return 'failed';
  }
}
