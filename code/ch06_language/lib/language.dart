// #region enum
/// The languages this greeting knows. Adding one here is a compile error
/// everywhere it is not yet handled, which is the point of an enum.
enum Language { english, spanish, french, german }
// #endregion enum

// #region prefix
String prefixFor(Language language) => switch (language) {
  .english => 'Hello, ',
  .spanish => 'Hola, ',
  .french => 'Bonjour, ',
  .german => 'Hallo, ',
};
// #endregion prefix

// #region hello
/// Greets [name] in [language]. A blank name greets the world.
String hello(String name, {Language language = .english}) {
  final who = name.trim().isEmpty ? 'world' : name.trim();
  return '${prefixFor(language)}$who';
}
// #endregion hello
