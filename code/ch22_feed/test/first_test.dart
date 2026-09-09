import 'package:ch22_feed/feed.dart';
import 'package:test/test.dart';

void main() {
  test('adds up everything the till sends', () async {
    expect(await totalOf(feedOf([700, 250, 1000], [])), 1950);
  });

  test('and says the balance after each one', () async {
    expect(
      await runningTotalOf(feedOf([700, 250], [])).toList(),
      [700, 950],
    );
  });
}
