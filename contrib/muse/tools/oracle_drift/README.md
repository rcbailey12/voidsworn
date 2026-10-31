# Oracle drift guard

A one-command check for the two kinds of silent divergence the Godot port can suffer:

1. The vendored JS oracle copies drifting away from the live game, or away from the
   commits their READMEs claim they were copied from.
2. The hand-copied render and world constants in the Godot tree drifting away from
   the browser definitions they were copied from.

Before this tool, both were audit discoveries (the Oct 30, 2026 red team audit found
three different copies of battle.js and data.js in the tree, and a set of hand-copied
constants with no comparison check at all). With the guard, both are a command anyone
can run before quoting a parity result.

## Run it

Needs Node only, no packages. From the repo clone root:

```
node contrib/muse/tools/oracle_drift/oracle_drift_guard.js
```

From anywhere else, pass the clone root:

```
node oracle_drift_guard.js /path/to/voidsworn
```

Machine-readable output (same facts, as JSON):

```
node oracle_drift_guard.js --json
```

The guard never edits anything. Exit code 0 means the run completed, even if it found
drift (it is a reporter, not a gate). Exit code 2 means the run itself failed, for
example a wrong repo root. Output is deterministic: sorted keys, no timestamps, so
two runs over the same tree produce byte-identical reports and a diff between two
reports shows exactly what drifted since the last run.

## What it checks

### (a) Vendored oracle copies

For `battle.js`, `data.js` and `core.js`, it hashes (SHA-256) the copies at the repo
root, in `godot/rules/test/oracle/` and in `godot/campaign/test/oracle/`, and compares
every pair. Identical pairs say so. Differing pairs get a line-level diff summary:
how many lines were added and removed, and the first five differing line numbers
(shown as root-line/other-line). Facts only; a difference is expected whenever the
live game has moved since a pin, and the interesting question is always how much.

### (b) README pin claims

Each oracle README names the commit its files were copied from (the rules oracle says
`cb55ec9`, the campaign oracle says `d8b47c6`). The guard extracts that claim, then,
when git is available, compares each vendored file against the actual content of that
file at the claimed commit, and against the live root file. It also checks the rules
README's secondary claim that core.js is unchanged since `d8b47c6`, and it measures
the campaign oracle's one disclosed exception: its vendored `campaign3d.js` carries a
documented line-56 fix on top of the pin, so that file is expected to differ from the
pin by exactly that fix and is marked as a disclosed exception rather than a broken
claim. Two rules-oracle files (`fnames.js`, `campaign_hooks.js`) are extracts from
other root files, not full-file copies, so they cannot be verified by file hash; the
report marks them unverifiable instead of guessing.

If git is not available, the pin-content checks report "unknown" and everything else
still runs.

### (c) Hand-copied constants

For FAC3D, AI_HULLS, CLS_LEN, FINISH, BIOMES, ROCKS and PLANETS, the guard finds the
browser definition and every Godot definition (it searches all of `godot/**/*.gd` for
`const` sites, so a second definition of the same name is surfaced, not missed) and
compares values entry by entry. Entries are reported as matched, differed (with both
values shown), browser-only or godot-only. Three wrinkles are handled explicitly:

- FINISH exists only in Godot. Its per-faction base hex duplicates the browser
  FAC3D `hull` hex, so that is what gets compared; its metal and roughness fields
  have no browser source and are listed as Godot-only fields.
- BIOMES has no `const` in the Godot tree. The values live in the `nebula` field of
  `godot/fx/faction_looks.json`, which `godot/world/world.gd` names as its source,
  so the guard compares against the JSON.
- ROCKS exists in both quantity systems: the browser `ROCK_KINDS` colour is a tint,
  the Godot `world.gd` value is an absolute albedo. The guard compares the numbers
  and prints the caveat with the table, so the known re-derivation is not mistaken
  for a fresh drift. The `ROCK_SET` and `ROCK_TINT` tables are true copies and are
  compared directly.

## How to read the report

- Start with the Summary block: vendored pairs identical vs differing, pin claims
  held vs contradicted, constant entries matched vs differed.
- A pin claim CONTRADICTED line is the loudest signal: a vendored file does not match
  the commit its README claims, which means the paperwork and the files disagree.
- A differing vendored pair is normal mid-sprint. What matters is the size (a handful
  of lines vs hundreds) and whether both suites still certify against the same game.
  The pair "rules-oracle vs campaign-oracle" is the one to watch: if those two
  differ, the two parity suites are testing two different games.
- Constant DIFFER lines on presentation tables (BIOMES, PLANETS) mean the Godot art
  no longer matches the browser art value for value. Some of that is deliberate
  re-authoring on the Godot side; the report's dated snapshots (see
  DRIFT_REPORT_2026_10_30.md) record which state was intentional as of that date, so
  a later change shows up as a new difference rather than a rediscovery.
- Browser-only FAC3D entries include the `tip` colour per faction, which has no
  counterpart in the Godot hull table. If the port ever needs tip colours, that is
  the gap this line is pointing at.

## Limits

- The guard parses the specific literal shapes these tables use today (flat maps,
  `new C3(...)`, `Color(...)`, `Vector3(...)`, nested triple arrays). If a table is
  restructured into computed values, the parser will report entries as missing rather
  than inventing values; treat a sudden "0 compared" as a parser alarm, not as proof
  the table vanished.
- It compares values, not semantics. Two tables can match numerically and still be
  used differently by the two engines, and two tables can differ numerically because
  one side deliberately re-derived the quantity (see ROCKS). The dated drift report
  carries the interpretation; this tool carries the facts.
