/// A class as the generators see it.
///
/// The plugin builds it from resolved elements. Tests build it by hand.
final class ClassModel(
  /// The type as written inside the class, for example `Range<T>`.
  final String type,

  /// Non-static fields: the class's own, plus inherited fields that a
  /// constructor takes through `super.` parameters.
  final List<FieldModel> fields,

  /// The constructor that copyWith and fromJson call, or `null` if none
  /// qualifies. See [chooseBuilder].
  final ConstructorModel? builder,
) {
  /// The class name without type arguments, for example `Range`.
  String get name => type.split('<').first;
}

final class FieldModel(
  final String name,
  final TypeModel type, {
  final bool isFinal = true,
  final bool isLate = false,
  final bool hasInitializer = false,
});

final class ConstructorModel(
  /// The text that calls it: `Expense`, `Money.fromPence` or `Money._`.
  final String call,
  final List<ParamModel> params, {
  final bool isPublic = true,

  /// `false` for a generative constructor of an abstract class.
  final bool isCallable = true,
});

final class ParamModel(
  /// The parameter name: `pence` for `super.pence`, `_count` for `this._count`.
  final String name,
  final TypeModel type, {
  final bool isNamed = false,
  final bool isRequired = true,
  final String? defaultValue,

  /// Whether a field has this name and its type is assignable to [type].
  final bool fitsField = true,
}) {
  // A required parameter has no default value.
  this : assert(!isRequired || defaultValue == null);
}

/// A field or parameter type, sorted by what the JSON rules do with it.
sealed class TypeModel(
  /// The type as written, with `?` when it is nullable: `List<Money>?`.
  final String code, {

  /// Whether the type can hold `null`. This is `true` for `String?`,
  /// `dynamic` and a type parameter with a nullable bound.
  final bool isNullable = false,
}) {
  /// [code] without a trailing `?`.
  String get base =>
      code.endsWith('?') ? code.substring(0, code.length - 1) : code;
}

/// `int`, `String`, `bool` and `num`: JSON carries them as they are.
final class PrimitiveType(super.code, {super.isNullable}) extends TypeModel;

/// JSON can write `1` for a `double`, so fromJson reads a `num`.
final class DoubleType(super.code, {super.isNullable}) extends TypeModel;

/// `Object`, `Object?` and `dynamic`: any JSON value fits.
final class PassthroughType(super.code, {super.isNullable}) extends TypeModel;

final class DateTimeType(super.code, {super.isNullable}) extends TypeModel;

final class EnumType(super.code, {super.isNullable}) extends TypeModel;

final class ListType(super.code, final TypeModel element, {super.isNullable})
    extends TypeModel;

final class SetType(super.code, final TypeModel element, {super.isNullable})
    extends TypeModel;

final class MapType(
  super.code,
  final TypeModel key,
  final TypeModel value, {
  super.isNullable,
}) extends TypeModel;

final class TypeParameterModel(super.code, {super.isNullable})
    extends TypeModel;

/// Any other type. JSON calls its `toJson()` and `fromJson`.
final class OtherType(super.code, {super.isNullable}) extends TypeModel;

/// Picks the builder: the first constructor that is public, can be called,
/// has only parameters that fit a field, and covers every field except `late`
/// fields with an initializer. The unnamed constructor goes first, then named
/// constructors in declaration order.
ConstructorModel? chooseBuilder(
  List<FieldModel> fields,
  List<ConstructorModel> constructors,
) {
  final needed = [
    for (final f in fields)
      if (!(f.isLate && f.hasInitializer)) f.name,
  ];
  final ordered = [
    ...constructors.where((c) => !c.call.contains('.')),
    ...constructors.where((c) => c.call.contains('.')),
  ];
  for (final c in ordered) {
    if (!c.isPublic || !c.isCallable) continue;
    if (!c.params.every((p) => p.fitsField)) continue;
    final names = {for (final p in c.params) p.name};
    if (needed.every(names.contains)) return c;
  }
  return null;
}

/// The name a caller uses: `count` for the private `_count`.
String publicName(String name) =>
    name.startsWith('_') ? name.substring(1) : name;
