import 'dart:math';

enum Shape { circle, square }

class Circle {
  final double radius;

  const Circle(this.radius);

  double get area => pi * radius * radius;
}
