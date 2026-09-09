# Book II ships twelve snapshots of one program

Book II grows a single expense tracker across studies 23–34. It ships as **twelve
packages**, `code/ch23_expenses/` through `code/ch34_expenses/`, each holding the whole
program as it stands at the end of that study. Study 24's package is study 23's package
plus one slice.

Anyone opening `code/` will see twelve near-identical copies and want to know why the
program is not simply grown in place. It is not a preference.

## Growing in place is mechanically impossible here

Fumadocs' `<include cwd>` reads the **working tree at build time**. It has no access to
git history, and there is no build step that could give it one.

- Study 23's page includes `lib/src/money.dart`. Write study 30 and that file has grown
  six more members. Study 23's prose now describes a file the reader cannot have.
- Study 23's `all.txt` says `+7: All tests passed!`. By study 34 the same command prints
  a much larger number. The transcript is stale, and `OUTLINE.md` already treats printed
  counts as claims that must match a real run.
- `#region` markers do not rescue it. The region body still moves, and the file title on
  the page still names a file whose current contents are different.

A snapshot's includes and transcripts are frozen on the day they are captured and can
never drift, because nothing later writes to that package.

## The layout this forces

Two constraints fall out, and both were measured rather than assumed.

**Imports inside `lib/` are relative.** A snapshot's package name contains its study
number, so `import 'package:ch23_expenses/…'` would change in every file in every study
and no file would ever be identical to its predecessor. Relative imports inside a
package's own `lib/` carry no package name and so do not move. Verified against
`code/analysis_options.yaml`: `always_use_package_imports` is not in
`package:lints/recommended.yaml`. Only `avoid_relative_lib_imports`, which forbids
reaching into *another* package's lib, and `implementation_imports`, which forbids
importing another package's `lib/src/`. Neither is triggered.

**`bin/` and `test/` must use `package:` imports** — they cannot reach `lib/` any other
way without tripping `avoid_relative_lib_imports` — so those files differ between
snapshots by the package name alone. The check below normalises it.

Verified by copying a package and renaming `ch23_expenses` to `ch24_expenses`: every
file under `lib/` byte-identical, `bin/expenses.dart` differing by one line.

## The check that keeps the copies honest

Each package carries a `SLICE` file naming the files that study adds or changes.
`code/tool/check_slices.dart` asserts both directions:

- every file **not** named in `SLICE` is identical to the previous study's copy, after
  normalising the package name;
- every file named in `SLICE` genuinely differs.

The second half matters as much as the first: it catches a manifest that has gone stale,
which is the same defect as a challenge intro claiming three tests when there are seven.

`SLICE` is also the list of what the study adds, so the prose has something to be
checked against. That makes it a claim in the same family as the challenge count and the
orphan-region rule, rather than a private note to the writer.

## Considered options

- **One package grown in place.** Cleanest reader model, no duplication. Rejected for
  the reason above: it breaks includes and transcripts for every study except the last.
- **A stable domain package with per-study packages depending on it.** Would give a
  genuine cross-package import early. Rejected: the domain is precisely the thing that
  grows every study, so it cannot be the stable part.
- **A chain of path dependencies**, each study depending on the previous. Avoids
  duplication and keeps a real `import`. Rejected: a twelve-deep dependency chain is
  fragile, and "study 30 depends on study 29 depends on study 28" is not a shape any
  reader's own project will ever have.
- **Discipline instead of a check.** Rejected on this repository's own evidence: the
  Book I audits found four false claims and every one was a sentence written from
  memory rather than from a run.

## Consequences

**The workspace grows from 22 packages to 34.** `code/pubspec.yaml` lists each one.
Resolution stays trivial because they share the workspace lock.

**A retroactive fix costs twelve edits.** Correcting a bug in study 23's `Money` means
applying it to every later snapshot. This is the real price of the layout, and the check
turns it from a silent risk into a loud failure: fix one and the next
`check_slices` run names every package that disagrees.

**`diff ch23_expenses ch24_expenses` is the study's slice**, exactly. That is a usable
artifact for a reader who wants to see what changed without reading prose, and it cannot
be faked.

**Book III (studies 35–39) inherits this decision.** Its packages continue the pattern
and carry the domain forward by copy, not by dependency. "Reusing the CLI's domain
package", as `PRODUCT.md` puts it, is a narrative claim about the code being the same
code — not a `pubspec.yaml` edge.
