import 'package:generate_core/generate_core.dart';
import 'package:test/test.dart';

final intType = PrimitiveType('int');
final stringType = PrimitiveType('String');
final noteType = PrimitiveType('String?', isNullable: true);

/// A class whose builder is the unnamed constructor, taking every field in
/// order.
ClassModel modelOf(
  String type,
  List<FieldModel> fields, {
  bool named = false,
}) => ClassModel(
  type,
  fields,
  ConstructorModel(type.split('<').first, [
    for (final f in fields) ParamModel(f.name, f.type, isNamed: named),
  ]),
);

/// The code of every generated member, joined. Fails when not offered.
String codeOf(Outcome outcome) => switch (outcome) {
  Generated(:final members) => members.map((m) => m.code).join('\n'),
  NotOffered(:final reason) => fail('not offered: $reason'),
};

/// The reason, or `null` when the outcome is generated code.
Reason? reasonOf(Outcome outcome) => switch (outcome) {
  NotOffered(:final reason) => reason,
  Generated() => null,
};
