// A stale generated toString is replaced.
// @regenerate toString
class const Point(final int x, final int y) {
  @override
  String toString() => 'Point(x: $x, y: $y)';
}

// A hand-written toString is domain text.
// @not toString customToString
class const Label(final String text) {
  @override
  String toString() => text;
}

// Hand-written text that starts with the class name, as in darty ch15.
// @not toString customToString
class const Money(final int pence) {
  String format() => '${pence ~/ 100} pounds';

  @override
  String toString() => 'Money(${format()})';
}

// Only the selected fields.
// @generate toString select left..right
class const Triple(final int left, final int right, final int extra) {
  @override
  String toString() => 'Triple(left: $left, right: $right)';
}

// @not toString noFields
class Empty {}

// @not toString notAClass
enum Size { small, large }

// A plain header parameter is not a field. A selection of only that
// parameter asks for the whole class.
// @generate toString select seed..seed
class Dice(int seed, final int sides) {
  final int first = seed % sides;

  @override
  String toString() => 'Dice(sides: $sides, first: $first)';
}

// The cursor on a body field asks for the whole class.
// @generate toString at y
class Point3 {
  final int x;
  final int y;

  Point3(this.x, this.y);

  @override
  String toString() => 'Point3(x: $x, y: $y)';
}

// A long toString splits into adjacent strings.
// @generate toString
class const Address(
  final String street,
  final String city,
  final String postcode,
  final String country,
) {
  @override
  String toString() =>
      'Address(street: $street, city: $city, postcode: $postcode, '
      'country: $country)';
}

// A selection of only a late field leaves toString nothing to show.
// @not toString noFields select cache..cache
class Lazy {
  final int n;
  late final String cache = '$n';

  Lazy(this.n);
}

// @not toString notAClass
mixin Named {}

// @not toString notAClass
extension type Meters(double value) {}

// A comment follows the last member. toString goes after the comment.
// @generate toString
class Closing {
  final int x = 0;
  // More fields go here.

  @override
  String toString() => 'Closing(x: $x)';
}
