import 'package:ch15_money/money.dart';

void main() {
  print(Money(250).format());
  print(Money(-250).format());
  print(Money(-5).format());
  print(Money(0).format());
  print(Money(250).plus(Money(180)));
  print(Split.fromPence(1234).amount.format());
  print(Split(3, 50).amount.format());
}
