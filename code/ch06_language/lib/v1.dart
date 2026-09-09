// Stage 1: study 2's version. The language is a String, so every string is
// allowed and only three of them mean anything.
// #region hello
String hello(String name, {String language = 'English'}) {
  final who = name.trim().isEmpty ? 'world' : name.trim();
  final prefix = switch (language) {
    'Spanish' => 'Hola, ',
    'French' => 'Bonjour, ',
    _ => 'Hello, ',
  };
  return '$prefix$who';
}
// #endregion hello
