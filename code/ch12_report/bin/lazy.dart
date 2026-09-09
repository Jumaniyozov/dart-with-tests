void main() {
  const entries = [100, -50, 200];

  final doubled = entries.map((entry) {
    print('  ...doubling $entry');
    return entry * 2;
  });
  print('the chain is built, and nothing above has run yet');

  print('first: ${doubled.first}');
  print('all:   ${doubled.toList()}');
}
