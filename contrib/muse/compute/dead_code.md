# Voidsworn dead-code candidates

Basis: repo HEAD 51337c2. Generated mechanically by hidden_files/compute/code_index.js (Compute Run 2). A candidate is a top-level name in the 18 build files with zero identifier references anywhere in the 20-file corpus (build files + head.html + sim3d.js) outside its own declaration. **13 candidates.**

| Name | Kind | Defined at | Also a property name (uses) | Named in a string literal |
|---|---|---|---|---|
| CMD_HOLD | const | battle.js:843 | 0 | no |
| aiFocusTarget | function | battle.js:1006 | 0 | no |
| faceToward | function | core.js:41 | 0 | no |
| KIND_NAME | const | data.js:30 | 0 | no |
| poolOK | function | fx3d.js:287 | 0 | no |
| muzzleFx | function | fx3d.js:326 | 0 | no |
| loftMesh | function | ships3d.js:92 | 0 | no |
| AIM_NAME | const | ui3d.js:642 | 0 | no |
| boltMat | function | vfx3d.js:31 | 0 | no |
| vfxFadeDispose | function | vfx3d.js:84 | 0 | no |
| volleyMuzzle | function | vfx3d.js:155 | 0 | no |
| fxBookLoad | function | wfx3d.js:79 | 0 | no |
| chargeFx | function | wfx3d.js:325 | 0 | no |

## Caveats: read before deleting anything

Zero plain-identifier references is evidence, not proof. Each of these mechanisms can reach a name this scan cannot see, and any candidate touched by one of them must be confirmed by a human (or by Opus) before removal:

- **String dispatch and dynamic lookup.** Code that builds a name at runtime (string concatenation, obj[someName], lookup tables keyed by strings from save data or the DOM) leaves no identifier token. Candidates whose name appears inside a string literal anywhere in the corpus are flagged in the table above; those are the riskiest deletions.
- **ACT[] and handler tables.** ui3d.js dispatches UI actions through the ACT object and through inline handler attributes inside template strings (for example onclick="ACT.foo()"). Those are property accesses, not top-level references; a top-level helper used only to build such handlers would still be counted here if it is referenced as an identifier, but a name colliding with a handler name (see the property-name column) deserves a second look.
- **Window and global lookups.** Code that reads a global through window[name], globalThis, or a typeof guard works even when the defining file changes; conversely a definition here may exist purely so another context (a worker, the sim harness, a bookmarklet) can find it on the global object.
- **HTML inline handlers and DOM ids.** head.html and the template strings in ui3d.js and campaign files can invoke global functions by name from markup. head.html is included in the corpus, but handler attributes generated at runtime from strings are only partially visible.
- **Babylon registration.** Classes registered with BABYLON.RegisterClass (for example the HullFx material plugin in gfx3d.js) are instantiated by Babylon from their registered string name during scene/material deserialisation, not by a JavaScript reference. Any class candidate must be checked against RegisterClass calls before deletion. None of the class definitions in the build were candidates in this run unless listed above; check the table.
- **Save data and external tools.** Names may be referenced by saved games (function names are not normally serialised, but table ids are; see referential_integrity.md), by the Python tooling in the repo, or by the owner's test scripts outside this corpus.
- **The sim harness.** sim3d.js is included in the corpus, so names used only by the harness are not candidates. The reverse also holds: a candidate here is unused by the harness too.

Recommendation: treat this list as a review queue. Confirm each candidate with a full-text search (including strings) and a check of the mechanisms above before removing it.
