# dart_generate

Generate actions for Dart classes in VS Code and Zed: toString, `==` and hashCode,
copyWith, toJson and fromJson, a getter for a private field, and "Convert to primary
constructor". They read classes with the real analyzer, so primary constructors and
class modifiers work.

VS Code uses the extension in `vscode/`. Zed uses the analyzer plugin in `plugin/`.
Both run the same assists, so they write the same code.

The designs are in `docs/superpowers/specs/`. The decisions are in `docs/adr/`.

## VS Code extension

To install or update the extension:

1. In `vscode/`, run `npm install` once. Then run `npm run package`.
2. Run the `code --install-extension` command that the script prints. If you use
   a VS Code profile for Dart, add `--profile` and its name, for example
   `--profile "Dart & Flutter"`. Without it, the extension goes into the default
   profile only.
3. Run "Developer: Reload Window" in each open VS Code window.

VS Code keeps one profile for each folder. To open a folder in the profile that has
the extension, run `code --profile "Dart & Flutter" <folder>` once.

After a Dart SDK upgrade, run `dart test` in `helper/`. Then build and install the
extension again. If the SDK and the helper differ in the minor version, the extension
shows a warning once.

In a Dart editor, Cmd+N opens Generate…, a menu with every action. An action that
does not apply is greyed out with its reason. toString, `==` and Generate getter… open
a field picker. The actions also appear in Cmd+. and the lightbulb.

A regenerated member replaces the old one, so the refactor preview opens first. The
change starts unticked. Tick it, then choose Apply.

A generated member that no longer covers every field gets a mark. copyWith, toJson
and fromJson get a warning, and toString and `==` get a hint. Its quick fix
regenerates the member.

If a project's `analysis_options.yaml` enables the plugin, Cmd+. shows only the
plugin's actions. Generate… still works there.

If an action fails, run "Dart Generate: Show Output". "Dart Generate: Restart
Helper" starts the helper again.

## Plugin setup

1. Add these lines to `analysis_options.yaml` in the project. Do not commit them.

   ```yaml
   plugins:
     dart_generate:
       path: /Users/islom/Projects/dart_generate/plugin
   ```

2. Run `dart analyze` in the project. The first run compiles the plugin, which took
   16 s in a test.
3. Restart the Dart analysis server in the editor.

A committed `path:` line makes `dart analyze` exit with code 4 on any machine without
that folder, so CI turns red.

After the plugin code changes, restart the Dart analysis server in each editor. A
running server keeps the plugin that it compiled at its start. The next start
compiles the new code.

Zed shows the actions in its code action menu (Cmd+.). It has no filter by kind.

## Plugin troubleshooting

1. If no action appears, run `dart analyze` in the project.
2. Look for `An error occurred while executing an analyzer plugin` in the output.
3. If an action fails, read the log. Its path is the value of `DART_GENERATE_LOG`, or
   `~/.dartServer/dart_generate.log`.

A compile error in the plugin gives exit code 0. A missing plugin path gives exit
code 4.

## Why an action is missing

Each row is one `Reason` in `core/lib/src/outcome.dart`.

| Reason | Actions | Meaning |
|---|---|---|
| `noFields` | toString, `==`, copyWith, JSON | The class has no field that the action can use. A `late` field does not count for toString and `==`. |
| `noBuilder` | copyWith, JSON | No constructor meets the four builder conditions. The builder is public. It can be called, so it is not a generative constructor of an abstract class. Each parameter names a field with an assignable type. The parameters cover every field except `late` fields with an initializer. |
| `mutableClass` | `==` | A field is not `final`. |
| `typeParameterField` | JSON | A builder parameter has a type parameter type, such as `T` or `List<T>`. |
| `nestedCollection` | JSON | A collection holds a collection, such as `List<List<int>>`. |
| `nonStringMapKey` | JSON | A map key is not `String`. |
| `customToString` | toString | The class has a toString whose body does not start with `'ClassName(` and a field label, such as `'Point(x: `. It is hand-written text, so it stays. |
| `notConvertible` | Convert to primary constructor | The class already has a primary constructor, or it does not have exactly one generative constructor. Or that constructor is `external`, or it has a name, a body, an initializer list or an annotation. Or a parameter is not `this.` or `super.`, or it is function-typed, such as `this.onTap()`. Or a moved field is `late` or has an initializer. Or some, but not all, of the variables in a declaration such as `final int a, b;` are parameters. A declaration cannot move in part. |
| `publicNameTaken` | getter | The class already has a getter or a method with the public name. |
| `notAClass` | all | The cursor is in an enum, a mixin or an extension type. |

## Known limits

- In a file with a syntax error, the formatter gives up, so the generated members are
  not indented. Format the file after you fix the error.
- Regenerate replaces the whole member, from its first annotation to its end. It keeps
  the doc comment. Other annotations are removed, such as `@useResult`, `@Deprecated`,
  or an `@override` on toJson. Add them again after you regenerate.
- Convert to primary constructor leaves a comment that ended the constructor's line in
  the class body.
