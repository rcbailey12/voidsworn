VOIDSWORN CHECK PACK
====================

What this is: mechanical checks for the game code that need no AI and no
judgement calls. Cross-references, duplicate names, dead content, and drift
between the build and the smoke test. Run it after any content change
(renaming a hull, adding a boon, touching a reskin table) and before you
publish a build.

How to run it:
1. Put RUN_CHECKS.bat and checks.js in the voidsworn folder, the same folder
   that holds data.js, core.js and build.py.
2. Double-click RUN_CHECKS.bat.
3. Read the window. The full report is also saved as checks_report.txt in
   the same folder.

How to read the report:
- FAIL means almost certainly a real problem: a broken reference, a duplicate
  name that silently overrides another, a boon whose own text function throws.
  Fix these before publishing.
- CHECK means eyeball it. Some are real (a reskin that renames nothing), some
  are known noise (the undeclared-call list includes CSS words caught inside
  text templates).
- ok means that section passed clean.

What it checks today:
- All 18 build files present.
- Duplicate top-level names across the build files (build.py only checks
  function names; this one also catches const, let, var and class).
- Em dashes in the game files (your house rule: none, ever).
- smoke.py versus build.py file lists (drift means the smoke test silently
  skips files).
- Data integrity, by loading the real tables the same way the sim harness
  does: every hull's faction, weapons and ability exist; every variant's base
  hull exists; every admiral's starting fleet exists; every boon executes its
  own text and effect functions without throwing; every event's named outcome
  has a handler; reskin tables point at real items and actually rename them.
- Call sites whose name has no visible declaration (candidates only, for
  spotting typos).

First run on the Oct 23, 2026 code (repo commit eca489e): 0 FAIL, 15 CHECK.
The CHECKs were the smoke.py drift (4 build files untested: meshopt3d.js,
gfx3d.js, vfx3d.js, wfx3d.js), 13 reskins that rename nothing, and the
undeclared-call candidate list.

checks.js is plain Node with no dependencies. If you want another check
added (a new table cross-referenced, a new rule), ask Rey and it goes in.
