import 'package:ch11_pipeline/pipeline.dart';
import 'package:test/test.dart';

void main() {
  test('a pipeline of one step is just that step', () {
    expect(runPipeline(250, [addFee(50)]), 300);
  });

  test('a pipeline of no steps changes nothing', () {
    expect(runPipeline(250, []), 250);
  });
}
