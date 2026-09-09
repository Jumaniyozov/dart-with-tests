void main() {
  final prices = <int>[250, 180];
  print('the list knows what it holds: ${prices.runtimeType}');

  final List<num> asNumbers = prices;
  print('seen as a List<num>, it is still ${asNumbers.runtimeType}');

  asNumbers.add(1.5);
  print('this line never runs');
}
