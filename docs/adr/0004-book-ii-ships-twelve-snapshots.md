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

**This was chosen for a mechanical reason and turns out to be the published advice.**
Effective Dart's *Usage* page carries "PREFER relative import paths"
(`dart.dev/effective-dart/usage#prefer-relative-import-paths`), checked while writing
study 23. So the layout does not ask the reader to learn a convention invented for this
book's build; it asks them to do the recommended thing, which happens also to make the
snapshots comparable. Had the two disagreed, the book would have followed the guideline
and the check would have had to normalise more.

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

**A retroactive fix costs one edit per snapshot from the bug onwards.** Correcting a bug
in study 23's `Money` means applying it to every later snapshot. This is the real price of
the layout.

**Amended while writing studies 30-32, which paid it three times.** A false attribution in
a `#run` doc comment spanned three snapshots; a machine-dependent test spanned one; an
inverted sentence in `Report.of` spanned two. So the price is not hypothetical, and the
number is not twelve — it is *however many snapshots exist from the mistake onwards*,
which is why a defect found early is cheap and one found late is not.

The guard was measured rather than assumed: reverting the doc-comment fix in
`ch29_expenses` alone made `check_slices` report `ch28_expenses -> ch29_expenses: changed
but not in SLICE — lib/src/command.dart`. A half-applied retroactive fix is exactly the
shape this check was built for, and it holds.

**And the check is narrower than this record first claimed.** `check_slices` compares a
file only when the study's `SLICE` does *not* name it. For a file the study does change,
any difference is expected, so a fix applied to one snapshot and not the next is
invisible to it. Measured: `penceFrom` was fixed in `ch24_expenses` and `ch25_expenses`
together, and reverting one of them left `check_slices` reporting that all three packages
agree.

What caught it was `tool/check_regions.dart`, which compares each `#region` against the
previous snapshot's copy: the diverged `parse` region showed up as changed and unshown.
So the honest statement is that the two checks cover different halves — `check_slices`
guards files a study leaves alone, `check_regions` guards regions inside files it
touches — and a divergence inside a region the study both changes and shows is caught by
neither, which is correct, because a shown change is a deliberate one.

**`diff ch23_expenses ch24_expenses` is the study's slice**, exactly. That is a usable
artifact for a reader who wants to see what changed without reading prose, and it cannot
be faked.

**Book III (studies 35–39) inherits this decision.** Its packages continue the pattern
and carry the domain forward by copy, not by dependency. "Reusing the CLI's domain
package", as `PRODUCT.md` puts it, is a narrative claim about the code being the same
code — not a `pubspec.yaml` edge.

**Amended while outlining Book III: the range is 35–40, and the decision held under a
test this record did not anticipate.** Book III bought a sixth study (ADR 0005), so the
numbers above are wrong and the reasoning is not. The test was this: `PRODUCT.md` says
the API reuses the CLI's domain package, and the obvious reading of that is a second
package with a `path:` dependency on the first. This record rules that out, and the
alternative turned out to be strictly better — `ch35_expenses` is `ch34_expenses` plus a
server, the CLI keeps working, and `check_slices` therefore *proves* every domain file is
untouched. The narrative claim became a checkable one, which is what this layout is for.

**All twelve exist, and the layout held.** `ch23_expenses` through `ch34_expenses` are
written, and `check_slices` reports twelve packages agreeing with their manifests. The
retroactive-fix price this record warned about was paid three times, all of them recorded
above; studies 33 and 34 added none, because both changed only the newest snapshot.

**One consequence this record did not anticipate: what a snapshot ships.** Study 34 ran
`dart pub publish --dry-run`, which builds the archive it would upload and prints it. Study
33's package would have shipped `SLICE`, `exercises/` and all of `test/` — 33 KB, of which
about fifteen is this book's own scaffolding rather than the program. `.pubignore` takes it
to 18 KB. `SLICE` is a manifest this layout invented; it exists to keep twelve copies
honest, and it is not something a reader downloading the package would ever want. Any later
book whose packages are meant to be read as packages should carry one.

**And the naming has a visible cost, measured rather than argued.** `pub` wants
`lib/<package name>.dart`, and these packages are named for their study number while their
barrel is named for the program. `dart pub publish --dry-run` reports that as a warning and
exits 65 on account of it. Measured on the identical code in a package named `expenses`:
0 warnings, exit 0. Study 34 states this rather than renaming the barrel, because
`lib/ch34_expenses.dart` is not a filename any reader should copy — but it is the one place
where the snapshot layout is visible to a tool rather than only to someone reading `code/`.
