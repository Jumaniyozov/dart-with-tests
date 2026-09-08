// Stage 3: the prefix is a named constant, not a magic string.
// #region hello
const englishHelloPrefix = 'Hello, ';

String hello(String name) => '$englishHelloPrefix$name';
// #endregion hello
