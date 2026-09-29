class Box {
  final int width;
  final int height;
  final int depth;

  const Box(this.width, this.height, this.depth);

  int get volume => width * height * depth;

  @override
  String toString() => 'Box(width: $width, depth: $depth)';
}
