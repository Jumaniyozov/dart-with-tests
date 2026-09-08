// Chapter 2 challenges.
//
// Each function below throws. Run `dart test exercises/` to see them fail,
// then make them pass one at a time. Do not edit the tests.

/// 1. Return a farewell: `goodbye('Islom')` is `'Goodbye, Islom'`.
///    An empty name says goodbye to the world.
String goodbye(String name) {
  throw UnimplementedError('challenge 1');
}

/// 2. Add German to [hello]: `hello('Islom', language: 'German')`
///    is `'Hallo, Islom'`. Everything else must keep working.
String hello(String name, {String language = 'English'}) {
  throw UnimplementedError('challenge 2');
}

/// 3. Ignore surrounding whitespace in the name:
///    `hello('  Islom  ')` is `'Hello, Islom'`, and a name that is only
///    whitespace greets the world.
String helloTrimmed(String name, {String language = 'English'}) {
  throw UnimplementedError('challenge 3');
}
