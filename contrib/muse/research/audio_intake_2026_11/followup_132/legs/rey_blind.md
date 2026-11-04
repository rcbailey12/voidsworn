# Blind Rey leg: issue #132, browser SFX table synth strip

Written from PACK.md alone, before reading any other leg. Method note and
honest limitation up front: the pack quotes full cues.json layer objects for
only three of the 26 affected items (hit_glass, ui_enemy, and the added layer
of wreck), plus the death_crack variant. For the other entries the pack gives
the mechanism, the gap classification (append vs exact-minus-syn vs replace),
and the set names. So my independent check has two tiers: (1) the
transcription rule and the special cases are re-derived from first
principles and checked exactly; (2) the numeric values in the rest of the
chair's table are checked for internal consistency against everything the
pack states (style rule, set names, counts), and the binding numeric check
remains the chair's real-render diff (protocol step 2). Where a conclusion
rests on pack description rather than quoted data, I say so.

## 1. Re-derivation from the render mechanism

The transform (render_synth.js:32, as described in the pack) is:

- MAP layer with an s key -> {s, g: layer.g or 1, r: layer.r or 1,
  d: layer.d or 0, pj: layer.pj or null}
- MAP layer without an s key -> {syn: 1, g}

Inverting it (cues.json layer -> MAP source) gives the transcription rule:
write s always; write g only if g != 1; write r only if r != 1; write d only
if d != 0; never write pj, which is exact only if today's cues.json layer
has pj null. This is the chair's stated style rule, and it is the unique
minimal inverse of the transform. Two consequences worth stating:

- The inverse is not unique in general (writing g:1 explicitly would render
  identically), but the minimal form is the right choice: it matches the
  existing MAP house style as described, and minimal diffs are easier for
  Opus to review.
- The pj assumption is the one place the inverse can silently fail: if any
  of the 26 cues.json layers carried a non-null pj, a pj-less MAP entry
  would render pj null and mismatch. The pack asserts all 26 are null. The
  one fully quoted non-MAP layer in the pack (the death_crack variant,
  pj:0) proves pj:0 exists in cues.json generally, so this assertion is
  doing real work. It is fully covered by protocol step 2, which diffs
  complete layer objects, so the risk is verified away post-edit rather
  than trusted. Acceptable, but the delivery record should not claim the
  transcription was exact until that diff has run.

Numeric formatting is not a risk: values such as .45, 1.15 and .05 parse to
the identical IEEE754 double whether they appear in JSON or in JS source,
so a transcribed value renders back numerically equal.

## 2. Entry-by-entry check of the chair's table

Counts first. The pack's gap section lists 24 hybrids; the chair's table
lists those same 24 (gun_shell, gun_las, gun_needle, gun_plasma, gun_rail,
salvo_tail, lance, lance_ion, lance_dark, lance_choir, torp, torp_heavy,
torp_star, hit, hit_las, hit_plasma, hit_rail, hit_glass, hit_ion, shield,
shield_break, boom_s, sting_win, sting_loss), plus wreck, plus ui_enemy:
26 entries. That matches the pack's "all 26 items" pj claim and the
measured "25 differ in MAP, plus one missing MAP entry" shape (24 hybrids +
wreck = 25 diffs; ui_enemy is the missing entry). Consistent.

Set-name cross-check. The gap section names 21 appended upgrade sets. Every
one appears in the chair's table as the final layer of the right cue:
shellBang (gun_shell), laserLR (gun_las), needleTick (gun_needle),
plasmaShot (gun_plasma), railStrike (gun_rail), salvoBoom (salvo_tail),
lanceLR (lance), ionField (lance_ion), darkLance (lance_dark), choirBell
(lance_choir), torpLaunch (torp), heavyPlate (torp_heavy), starShimmer
(torp_star), hullTick (hit), lasSear (hit_las), plasmaHit (hit_plasma),
railHit (hit_rail), ionZap (hit_ion), shieldShimmer (shield), shieldShatter
(shield_break), boomCrunch (boom_s). The remaining two of the pack's "23 new
sets" are hitGlass (hit_glass) and wreckSettle (wreck): 21 + 2 = 23, which
matches the browser playback section's count exactly.

Style-rule consistency. I checked every layer in the chair's table against
the minimal-inverse rule: no layer writes g:1, r:1, d:0 or any pj; every
non-default value the table shows is written (including the easy-to-miss
ones: needleTick r:1.15, ionField r:1.1, heavyPlate r:.85, shieldShimmer
r:.9, lance_choir incumbent r:1.5, salvo_tail incumbent d:.05). No entry
contradicts the rule.

Special cases, stated explicitly as required:

- hit_glass: MATCHES, and it is the sharpest entry in the table. Today's
  cues.json is quoted in full: [{s:'hitGlass',g:.35,r:1}] (with d and pj
  covered by the pack's general claim). Minimal inverse: {s:'hitGlass',
  g:.35} (r is 1, omitted). Renders back to {s:'hitGlass',g:.35,r:1,d:0,
  pj:null}. The chair's entry is exactly this. Note what the entry does:
  the incumbent shieldHit layer disappears entirely, not just the syn
  layer. That is correct per the pack's REPLACE rule from #101, and any
  leg that "fixes" this entry by keeping shieldHit would break the render
  match. The chair's table survives this check.
- sting_win: MATCHES by the pack's classification. Today's layers are
  exactly MAP minus the syn layer, no upgrade layer, so the target is the
  bare incumbent [{s:'victory'}], which renders [{s:'victory',g:1,r:1,
  d:0,pj:null}]. The chair's entry is exactly this.
- sting_loss: MATCHES by the same classification. Chair entry
  [{s:'enemyTurn',r:.8}]: r written (.8 != 1), g omitted (1). Renders
  [{s:'enemyTurn',g:1,r:.8,d:0,pj:null}].
- ui_enemy: MATCHES exactly, and this one is fully verifiable from the
  pack because the target cues.json layer is quoted in full:
  [{s:'enemyTurn',g:.6,r:1,d:0,pj:null}]. Minimal inverse:
  {s:'enemyTurn',g:.6}. The chair's entry renders to the quoted layer
  field for field. It also mirrors ui_alert, which the pack states as the
  #101 wiring intent.
- wreck: MATCHES. The pack quotes MAP as [{s:'scrape'}] and the added
  cues.json layer in source form as {s:'wreckSettle',g:.25}; the chair's
  entry [{s:'scrape'},{s:'wreckSettle',g:.25}] is the minimal inverse of
  MAP-plus-that-layer. Renders [{s:'scrape',...defaults},
  {s:'wreckSettle',g:.25,r:1,d:0,pj:null}].

For the remaining 21 entries, my derivation reproduces the chair's table
structurally (incumbent layers with the syn layer removed, the named
upgrade set appended last, minimal-inverse style) and I found no internal
inconsistency; the per-entry numerics stand or fall with protocol step 2,
as noted in section 1. Net: the chair's table survived my check with no
corrections. No differing MAP block is included, because there is no
difference to include.

## 3. Option ruling: A (pure MAP transcription)

Option A. Reasons, against the pack's three tests:

- Frozen-browser rule. The browser build takes break fixes only. A is one
  MAP edit in one file and spends zero effort on the browser build itself;
  its browser side effects are passive consequences, not browser work. B
  is a browser content upgrade (transcoding 128 files into the frozen
  build's sample bank) dressed as a fix, and C is new browser-preserving
  machinery. Both spend on the frozen build what the rule says not to
  spend.
- #101 intent. #101 decided these cues are recorded-only. A makes the
  source say exactly that, everywhere the source speaks. C deliberately
  keeps a syn layer in MAP forever to preserve a browser blend that #101
  already ruled out on the shipping side; that is preserving a
  ruled-against behaviour with a permanent marker. B overshoots the
  intent: #101 registered the new sets in the Godot clip index and
  completed without adding them to sfx_data.js, so browser sample parity
  was already implicitly out of scope (INFERRED from the pack's facts:
  sfx_data.js contains none of the new sets, and #101 is closed).
- Maintenance cost for Opus. A leaves MAP as the plain, honest source of
  cues.json layers: what you read is what renders. C leaves a lying MAP
  (a {syn:1} layer that is not one in the render) plus a convention in
  render_synth.js that a future editor can "clean up" and silently change
  one side or the other; that hazard recurs forever to protect a one-time
  browser delta. B leaves the largest diff and the worst failure mode:
  a chair-side regeneration of a generated data file, in a format owned
  by a PC-side tool (tools/pc/sfx_dl.bat), where one format slip corrupts
  the whole sample bank instead of 26 cue entries.

The honest cost of A, stated so the synthesis does not have to discover
it: in the browser the 24 hybrids lose the synth blend they currently mix
(they still play their incumbent recorded layers), and the appended layers
are silent because the frozen build never received those samples. Both
deltas point in the #101 direction and neither can break playback: a
recorded layer resolves for every hybrid except hit_glass (see section 6),
and sfx.js:81 keeps rendering the synth bank as a whole-cue fallback for
any cue whose samples are incomplete.

Option B rejected: cost and corruption risk on a frozen build, for parity
nobody asked for. Option C rejected: permanent convention and a source
that no longer matches, to preserve behaviour already ruled against.

## 4. wreck ruling: include it

Include wreck in the fix. Three reasons:

1. The chair's own verification protocol (step 2) diffs layers for all 67
   cues and requires the diff to be empty. wreck is a MAP cue whose layers
   differ today. Excluding wreck makes the headline verification fail on
   an unscoped technicality, or forces the diff to be quietly scoped.
   Including it makes the protocol pass as written, which is cleaner
   evidence for Opus and for the PR checks.
2. It is the identical class of defect found by the identical measurement:
   a re-render silently drops a layer that exists in today's cues.json.
   The issue's one-line brief is "make the source match"; wreck is source
   not matching.
3. The marginal risk is nil: one appended recorded layer in the same edit,
   no new mechanism, no new file.

The counter-argument is scope discipline (the fixed block's done-when
names only the 24, the variant and ui_enemy). It loses because the
done-when's purpose clause is the reproduction test, and because the chair
already plans to flag the scope call in the delivery record, which keeps
Opus informed. Flag it, include it.

## 5. death_crack carry-over: CONFIRMED

Confirmed, on the pack's description of render_synth.js:52-53. The chain:

1. The render's new table is built from SFX.CUES and SFX.MAP. death_crack
   is in neither, so it is not in the new table.
2. The merge step carries over whole any previous cues.json cue that is
   not in the new table.
3. Therefore death_crack, including variants.ithar with its recorded-only
   layers, survives a re-render byte-for-byte as a cues.json entry, and no
   syn layer can reappear in the variant, because nothing in the variant
   is regenerated.

Two supporting observations. First, the variant's layer carries pj:0,
which the MAP path in chair style never writes (default null); the variant
could not be reproduced through MAP even in principle, which is further
evidence it lives only via carry-over, and a reason nobody should try to
"fix" the variant by moving death_crack into MAP. Second, the same logic
covers board_grapple, which is why protocol step 3 names both. The
confirmation does rest on the pack's reading of lines 52-53; protocol step
3 converts that from trust into measurement after the edit, which is the
right shape. The done-when is satisfied for the variant, and the delivery
record should say plainly that the variant needed no edit and why.

One pre-existing property the delivery record should also state (not a
#132 change, not a blocker): carry-over depends on the render running
against a tree that already has today's cues.json. A render run in a fresh
tree without cues.json would drop death_crack and board_grapple entirely.
That is true today and remains true after this fix; naming it protects
Opus from a future surprise.

## 6. Risks and corrections the pack missed

1. CORRECTION to the pack's Option A description: the synth bank does NOT
   survive for every cue. The pack says the bank "is still rendered as a
   whole-cue fallback (sfx.js:81 renders it unless MAP is all-recorded AND
   every sample is present, which the missing new sets prevent)". True for
   the 21 append cues, hit_glass and wreck (a new set is missing, so the
   condition fails and the bank renders). NOT true for sting_win,
   sting_loss and ui_enemy: their post-edit MAP entries reference only
   incumbent sets (victory, enemyTurn) that ARE in sfx_data.js, so MAP
   becomes all-recorded with every sample present and sfx.js:81 stops
   rendering the browser synth bank for exactly those three cues. Playback
   is unaffected (the samples are in the same file the bank would fall
   back from), and ui_enemy lands in the same state ui_alert already lives
   in today, so there is live precedent. But the delivery record should
   state the bank behaviour accurately per cue instead of repeating the
   blanket claim.
2. hit_glass is the sharpest browser delta under A, sharper than the
   pack's general "lose the synth blend" framing. Today in the browser,
   hit_glass plays shieldHit plus synth. After the edit, hitGlass is not
   in sfx_data.js, so NO recorded layer resolves; per _layers as described,
   the cue falls back to its synth bank alone (which still renders, per
   item 1). So hit_glass in the browser goes from recorded-plus-synth to
   synth-only: the one cue that loses a recorded layer it currently plays,
   not just a blend. Acceptable under the frozen-browser rule and the #101
   REPLACE decision, but it should be named in the delivery record as the
   worst-case browser consequence, not averaged into the general claim.
3. salvo_tail is the most audible routine browser delta. The pack names
   the salvo scheduler connection; spelling out the consequence: in the
   browser, salvo_tail is fired by the scheduler under broadsides (per
   play() referencing cue.salvo), so its synth append disappearing is not
   a rare-cue change, it recurs in every sustained broadside. The
   transcription itself is unaffected (salvo is a CUES field; layers are
   data; the incumbent d:.05 is preserved). Aligned with #101 intent;
   name it, do not fix it.
4. spj line (sfx.js:333) check, as the pack requested: it assigns spj on
   SFX.CUES entries (including ui_enemy) after MAP is defined, and nothing
   in this job edits CUES, so the line is untouched and still makes sense.
   Adding a MAP entry for ui_enemy does not interact with it: the render
   takes cue-level fields from CUES and layers from MAP independently.
   If the browser's _layers defaults a layer's pj from cue.spj (not stated
   in the pack; INFERRED), ui_enemy's recorded layer would take the same
   jitter ui_alert's identical layer already takes today. Precedent-safe
   either way. No edit needed.
5. Protocol improvement: the step 2 diff should compare parsed JSON layer
   arrays, not raw file text. A regenerated cues.json can differ in key
   order and number formatting (0.5 vs .5) from today's hand-touched file
   with zero actual layer differences; a raw text diff would false-alarm
   and could send the chair hunting a phantom. The done-when's "show the
   diff is empty" should be a parsed-layers diff.
6. Claim discipline for the delivery record: the render rebuilds entries
   for all MAP/CUES cues from source, so a re-render could also change
   non-layer fields of those cues if today's cues.json was hand-tuned
   anywhere else. Out of scope for the done-when, but the PR text must
   claim only "re-render reproduces today's cues.json layers", never
   "reproduces cues.json". The pack's protocol is scoped correctly; this
   is a warning about the summary sentence, not the protocol.
7. gun_ defer interaction, checked and cleared: the render raises defer
   on gun_ cues from CUES fields after building the table. Five gun_ cues
   are in this edit (gun_shell, gun_las, gun_needle, gun_plasma, gun_rail),
   but defer is cue-level and d is layer-level; the MAP edits touch
   neither CUES nor the defer inputs, so the raise reproduces identically
   and cannot contaminate the layer diff.

## Verdict summary

- Chair's target MAP: survives my check, no corrections; special cases
  hit_glass, sting_win, sting_loss, ui_enemy and wreck each confirmed
  explicitly above.
- Option pick: A (pure MAP transcription).
- wreck: include, flagged as a scope call in the delivery record.
- death_crack ithar variant: carry-over reading CONFIRMED; no edit exists
  or is needed; state the fresh-tree caveat in the delivery record.
- Corrections for the chair to fold in: per-cue synth bank behaviour
  (item 1), hit_glass browser degradation named plainly (item 2), parsed
  JSON diff in the verification (item 5), and layer-only claim wording
  (item 6).
