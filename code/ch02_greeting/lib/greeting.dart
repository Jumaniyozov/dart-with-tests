// Greetings in a few languages.
//
// The language is a String here because it keeps this chapter short. It is
// the wrong type for the job — Study 6 replaces it with an enum.

// #region prefixes
const englishHelloPrefix = 'Hello, ';
const spanishHelloPrefix = 'Hola, ';
const frenchHelloPrefix = 'Bonjour, ';
// #endregion prefixes

// #region hello
/// Returns a greeting for [name] in [language].
///
/// An empty [name] greets the world. An unknown [language] falls back to
/// English.
String hello(String name, {String language = 'English'}) {
  final who = name.isEmpty ? 'world' : name;
  return '${_prefix(language)}$who';
}
// #endregion hello

// #region prefix
String _prefix(String language) => switch (language) {
  'Spanish' => spanishHelloPrefix,
  'French' => frenchHelloPrefix,
  _ => englishHelloPrefix,
};
// #endregion prefix
