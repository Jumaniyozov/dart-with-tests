import 'package:ch22_feed/feed.dart';

/// One feed, asked for its total twice.
Future<void> main() async {
  final feed = feedOf([700, 250, 1000], []);
  print(await totalOf(feed));
  print(await totalOf(feed));
}
