/// Who decides a [Reason]: the core from the model, or the plugin's adapter
/// from the syntax tree.
enum Owner { core, adapter }

/// Why an action is not offered. The README has one row per value.
enum Reason {
  noFields(Owner.core, 'the class has no field that this action can use'),
  noBuilder(Owner.core, 'no public constructor covers every field'),
  mutableClass(Owner.core, 'a field is not final'),
  typeParameterField(Owner.core, 'a field has a type parameter type'),
  nestedCollection(Owner.core, 'a collection holds a collection'),
  nonStringMapKey(Owner.core, 'a map key is not String'),
  customToString(Owner.adapter, 'toString is hand-written'),
  notConvertible(
    Owner.adapter,
    'the constructor cannot move into the class header',
  ),
  publicNameTaken(
    Owner.adapter,
    'the class already has a member with the public name',
  ),
  notAClass(
    Owner.adapter,
    'the cursor is in an enum, a mixin or an extension type',
  );

  const Reason(this.owner, this.message);

  final Owner owner;

  /// Why the action is greyed out, as the VS Code menu shows it.
  final String message;
}

/// What a generator returns.
sealed class Outcome {}

final class Generated(
  final List<Member> members, {

  /// Library URIs that the members need, such as `package:collection`.
  final List<String> imports = const [],
}) implements Outcome;

final class NotOffered(final Reason reason) implements Outcome;

/// One generated class member.
final class Member(
  /// The member name, used to find an existing member: `toString`, `==`,
  /// `hashCode`, `_unset`, `copyWith`, `toJson`, `fromJson` or a getter name.
  final String name,

  /// Unformatted Dart source. The plugin formats it after insertion.
  final String code,
);
