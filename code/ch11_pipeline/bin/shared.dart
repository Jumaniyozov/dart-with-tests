import 'package:ch11_pipeline/v1.dart';

void main() {
  final steps = feeSteps([10, 20]);
  print('built ${steps.length} steps');
  print('the first one on 100p gives ${steps.first(100)}');
}
