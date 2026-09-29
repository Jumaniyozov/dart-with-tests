# A stale copyWith or JSON member gets a warning, a stale toString or `==` a hint

The VS Code extension marks a member that no longer covers every field. copyWith,
toJson and fromJson get a warning. toString, and the pair of `==` and hashCode, get a
hint. Each mark has a "Regenerate" quick fix.

## The rule

1. **Members.** toString, the pair of `==` and hashCode, copyWith, toJson and fromJson.
   `==` and hashCode count as one member, and the mark goes on `==`.
2. **Expected fields.** For toString and `==`, the fields that the generator uses when
   all fields are picked. `late` fields do not count. For copyWith and JSON, the
   fields of the builder's parameters (ADR 0003).
3. **Used fields.** The fields that the member references, by resolved element:
   - A read of the field, or of a getter of the class that reads it, such as
     `int get pence => _pence;`.
   - An argument, named or positional, whose parameter is a `this.` or `super.`
     parameter of that field.
   - A field initializer in a constructor, such as `: name = json['name'] as String`.
   - `==` and hashCode count as one member. A used field is one that both of them
     use.
4. **Stale.** An expected field that is not a used field makes the member stale. An
   action that is not available at the class gives no mark. For example,
   a mutable class gets no `==` hint, and a hand-written toString gets no toString
   hint (`customToString`).

## Why

- **copyWith and JSON always cover every field.** They take no field selection, so a
  missing field is a bug. `copyWith()` returns a copy without the field, and
  `toJson()` leaves it out, with no error.
- **toString and `==` can cover a subset on purpose.** The field picker makes a subset
  easy. A hint shows only three faint dots and stays out of the Problems panel, so a
  deliberate subset costs little. A forgotten field in `==` is the most expensive of
  these bugs, and the dots make it visible.
- **References, not text.** A comparison with regenerated text flags every member after
  any change to the generator's output. A reference test does not. For example,
  weather_cli's hand-written `fromJson` (`current_weather_model.dart:13`) passes all
  five fields as named arguments. It gets no warning, although its keys differ from
  the generated keys.

## Considered options

- **Warnings on copyWith and JSON only.** Rejected by the user: a full `==` that
  ignores a new field then gets no signal.
- **Warnings on all four members.** Rejected: every deliberate subset stays in the
  Problems panel.
- **A shape gate for `==` hints.** The gate allows a hint only on the generated shape,
  `other is T && other.a == a`. Rejected by the user. All six `==` in darty ch40
  already have that shape and cover every field, so the gate changes nothing there.
  It only misses a stale `==` in another shape, such as a block body that starts with
  `identical(this, other)`.

## Consequences

**Messages name the member and the field.** These are examples:

- `copyWith() does not cover pressure.`
- `toString() does not show pressure.`
- `==() and hashCode do not use pressure.`

**The quick fix for a hint opens the picker with all fields ticked.** The quick fix
exists to add the missing fields. Take weather_cli's `CurrentWeatherModel` with a new
`pressure` field. A full `==` gets a hint for `pressure`, and Enter in the quick fix's
picker fixes it.

**Regenerate from Generate… keeps a deliberate subset.** Its picker starts with the
fields that the member uses. Take a toString of only `temperature` and `weatherCode`.
Its hint lists the other three fields, but you do not click that quick fix. Regenerate
from Generate… starts with the two fields ticked.

**The scan runs often.** It covers visible Dart editors. Three events start it: an
editor becomes visible, 500 ms pass after the last edit, or another file changes. A
file with a syntax error keeps its previous marks, so a half-typed member does not
flicker. A superclass in another file can change the fields that `super.` parameters
bring in.

**A deliberate gap in copyWith or JSON keeps its warning.** An example is a
hand-written copyWith that leaves out `id` on purpose. The extension has no settings,
so nothing silences the warning. None of the user's repos has such a member today:
none has a copyWith, and darty's `Limit.toJson` (`budget.dart:44`) covers every field.
