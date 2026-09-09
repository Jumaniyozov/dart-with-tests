import 'dart:async';

/// Four lines, printed in an order the source does not read in.
void main() {
  print('1 straight line');
  unawaited(Future<void>(() => print('4 event queue')));
  scheduleMicrotask(() => print('3 microtask queue'));
  print('2 straight line');
}
