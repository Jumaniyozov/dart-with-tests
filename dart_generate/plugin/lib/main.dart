import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/assists.dart';

/// The entry point that the analysis server loads.
final plugin = DartGeneratePlugin();

final class DartGeneratePlugin extends Plugin {
  @override
  String get name => 'dart_generate';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerAssist(GenerateToString.new)
      ..registerAssist(GenerateEquality.new)
      ..registerAssist(GenerateCopyWith.new)
      ..registerAssist(GenerateJson.new)
      ..registerAssist(GenerateGetter.new)
      ..registerAssist(ConvertToPrimaryConstructor.new);
  }
}
