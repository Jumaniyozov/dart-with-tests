import 'package:test/test.dart';

import 'challenges.dart';

void main() {
  group('challenge 1 — one line of the listing', () {
    test('reads each kind differently', () {
      expect(line(Question('ada', 'when?')), 'ada asks: when?');
      expect(line(Reply('grace', 'soon', 7)), 'grace replies to 7');
      expect(line(Closed('alan', 'spam')), 'alan closed: spam');
    });
  });

  group('challenge 2 — how long it may wait', () {
    test('gives each kind its own window', () {
      expect(slaHours(Question('ada', 'when?')), 24);
      expect(slaHours(Reply('grace', 'soon', 7)), 72);
      expect(slaHours(Closed('alan', 'spam')), 0);
    });

    test('and hurries for a vip without hurrying replies to one', () {
      expect(slaHours(Question('vip', 'when?')), 4);
      expect(slaHours(Reply('vip', 'soon', 7)), 72);
    });
  });

  group('challenge 3 — which queue it joins', () {
    test('the values already carry what they were given', () {
      expect(Priority.urgent.label, 'Urgent');
      expect(Priority.normal.maxQueue, 50);
    });

    test('a tight queue is one that holds fewer than ten', () {
      expect(Priority.urgent.isTight, isTrue);
      expect(Priority.normal.isTight, isFalse);
    });

    test('and every message lands in one of them', () {
      expect(Priority.of(Question('vip', 'when?')), Priority.urgent);
      expect(Priority.of(Reply('ada', 'soon', 7)), Priority.urgent);
      expect(Priority.of(Question('ada', 'when?')), Priority.normal);
      expect(Priority.of(Closed('alan', 'spam')), Priority.normal);
    });
  });
}
