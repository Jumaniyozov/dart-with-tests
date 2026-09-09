// Stage 2: the set of languages is now closed, and the compiler knows it.
// #region enum
enum Language { english, spanish, french }
// #endregion enum

// #region hello
String prefixFor(Language language) => switch (language) {
  .english => 'Hello, ',
  .spanish => 'Hola, ',
  .french => 'Bonjour, ',
};

String hello(String name, {Language language = .english}) {
  final who = name.trim().isEmpty ? 'world' : name.trim();
  return '${prefixFor(language)}$who';
}
// #endregion hello
