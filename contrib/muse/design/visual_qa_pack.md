# Visual QA pack: screenshot specification for Voidsworn

Status: specification Opus may use or set aside. It is not a task order and it sets no sequence or dates. It exists because the owner judges visual work by screenshots, so the screenshots themselves need a standard: same conditions, same shots, same checks, same verdict record, every time.

Rules this pack enforces come from the existing design documents, not from new invention:

- Colour law (art direction): cyan means shields, nothing else is cyan, and shields are nothing else. Gold is rationed to patrons and Command UI only. Selection ring is white. Flagship marker is a faction-coloured chevron. FAC3D is the single colour source.
- Silhouette grammars (art direction): Voidsworn vertical cathedral, Hegemony pure wedge, Corsair mandatory asymmetry, Chorus radial knot with no straight edges, Ithar dart plus vertical fins (never horizontal wings), Deathless ribcage and spine.
- Background cap (art direction): no background pixel inside the board area may exceed 40 percent of the luminance of an unlit hull facet.
- Kit acceptance (ship kit work order): two shots per hull at battle zoom on a desktop frame, one lit against its home plate, one flat-black silhouette sheet. A hull that cannot be told apart from another hull of its faction, or that a viewer assigns to the wrong faction, sends the manifest back.
- Craft rules (graphics craft): fixed exposure per region, never auto-adapted; bloom threshold raised until background plates stop glowing; MSAA on desktop; trails deliberate, never accidental; screen shake short with a reduce toggle; photosensitivity cap of three flashes per second; a reduce-flash setting.

## 1. Capture setup: identical conditions, every batch

A screenshot that cannot be compared to the last batch is decoration. Before any shot in a batch:

- Wait for shader compilation to finish. Force synchronous compilation before a screenshot, or wait on scene readiness, so no shot catches a half-compiled material.
- Fix exposure per region. Never capture with auto exposure enabled: an exposure shift that changes which ships read is a gameplay bug, and it also makes two batches incomparable.
- Use the production pipeline settings for the tier being shot: ACES tone mapping on, bloom at the shipped threshold and weight, the desktop anti-aliasing mode (MSAA samples).
- Capture the desktop frame for every subject. Under the Oct 24, 2026 PC-only ruling there is no phone frame and no phone acceptance check. A shot passes or fails on desktop alone.
- Capture in game, never in Blender. A Blender render is not proof. The in-game screenshot and the flat-black silhouette sheet are the acceptance tests.
- Record the build identifier and the tier with the batch. A shot without a build tag cannot be re-checked.

## 2. Screenshot capture list

### 2a. Per hull (every hull, every tier)

1. Lit hero: hull at battle zoom, lit, against its home plate, three-quarter view, engines on. This is the kit acceptance shot (a).
2. Silhouette sheet: the hull rendered flat black, small, in a grid with every other hull of its faction. This is the kit acceptance shot (b).
3. Top-down board view: the hull on the hex board at the zoom the player actually fights at, beside one same-class hull of a different faction.
4. Damage states: the hull at heavy damage and at near destruction, showing its faction damage language (Voidsworn ember cracks, Hegemony blue coolant jets, Corsair shed donor panel, Chorus bile and knitting wound, Ithar dark sail panels, Deathless lost rib segment).
5. Shield hit: the hull taking a hit, showing the cyan ripple in its faction shape (Hegemony hexagons, Voidsworn arch segments, Chorus blistered, Ithar smooth gradient, Deathless cracked glass, Corsair patchy and flickering).
6. Weapon fire: the hull firing its signature weapon, showing muzzle character and projectile or beam colour.
7. Engine view: stern view, engines running, showing plume character (Corsair dirty flicker versus Hegemony clean, as specified).

### 2b. Per effect (every effect family, both tiers)

1. Beam: full travel from muzzle to impact, one frame mid-flight and one frame at impact.
2. Shield hit: per faction, as in 2a.5, plus one frame showing the ripple after the hit fades.
3. Explosion and destruction: the full destruction sequence for one hull per faction, showing that no two factions die alike (Voidsworn burning inward, Hegemony white flash and clean halves, Corsair coming apart at the welds, Chorus deflating with late pod bursts, Ithar shattering sails first, Deathless going dark stern to prow).
4. Engine trail: a ship under full movement, showing the trail as a deliberate designed element, not a smear.
5. Muzzle flash and charge: a Voidsworn lance charging (rising ember flare) and a Hegemony ion shot firing instantly, side by side in the batch, so the timing contrast is visible.
6. Simultaneous effects: a frame with at least three effect families active at once, for the overdraw and flash checks.

### 2c. Per background plate (every plate, both tiers)

1. Plate alone: the full plate with no ships and no UI, so the four layers read cleanly.
2. Plate with ships: the same plate with one fleet of each of two factions on the board, at fighting zoom, for the luminance cap check.
3. Plate with UI: the same plate with the full HUD visible, for the legibility check.
4. Plate at phone width: dropped. Under the Oct 24, 2026 PC-only ruling there is no phone frame; the plate with ships shot is captured on desktop only.

### 2d. Full battle (one battle per batch, both tiers)

1. Turn start: the board at rest, both fleets visible, HUD visible.
2. Mid-volley: at least three ships firing, shields hit, damage numbers visible.
3. Capital kill: the kill frame and one frame after, showing destruction, HUD fade behaviour, and flash count.
4. Command activation: a Command firing, showing the camera push-in and the Command UI state.
5. Victory and defeat: the end screens, showing that HUD and backdrop still read after the battle state changes.
6. Boss arrival: if the batch includes a boss, the arrival frame showing the push-in and the boss read.

## 3. Per-shot checklists

Check every applicable item on every shot. A check is either observed or it is not; do not mark a check from memory of a previous batch.

### All shots

- The shot was taken in game, at the shipped pipeline settings, with exposure fixed, after shader compilation finished.
- Nothing in the shot is a placeholder, a stand-in, or a superseded asset (no aft-pointing Confessor lance, no wet-navy battleship defender, no superseded portrait version).
- The build tag and tier are recorded with the shot.

### Hull shots

- Silhouette: the hull reads as its faction from outline alone, in flat black, at the size it appears in game. If faction and class do not read from the silhouette alone, the hull fails regardless of texture quality.
- Faction at a glance: on the lit hero shot, a viewer who has never seen the hull names the faction in under three seconds.
- Colour law: no cyan anywhere except shields, shield hits and shield UI pips. No gold anywhere except patrons and Command UI. Selection ring is white. Flagship marker is a faction-coloured chevron.
- Grammar: the hull obeys its faction grammar (Voidsworn vertical, Hegemony wedge line unbroken, Corsair asymmetrical, Chorus no straight edge longer than a plate, Ithar fins vertical, Deathless ribs exposed). Guns face forward or sideways, never backward.
- Damage language: the damage state shown matches the faction's specified language, and damage is readable at fighting zoom, not only at hero zoom.
- Shield shape: the ripple shape matches the faction, and the ripple reads at battle zoom.

### Effect shots

- Faction character: the effect matches its specified muzzle, projectile and timing character (Voidsworn slow ember charge, Hegemony instant and clinical, Corsair dirty wobble, Chorus pulsing globs, Ithar hair-thin beam, Deathless silent green line).
- Bloom sanity: beams, engine glows, explosions and shield flashes bloom. Background plates do not bloom. Nothing clips to flat white except a Hegemony death flash, which is specified to do so.
- Trails: every trail visible is a deliberate designed trail. No accidental smear reads as motion ghosting.
- Overdraw: in the simultaneous effects shot, frame rate holds when looking directly at the effects. If it drops when effects fill the screen and recovers when zooming out, the batch is flagged for fill rate, not particle count.
- Flash count: no more than three flashes in any one-second window across all simultaneous effects, and no full-screen strobe for a capital kill. The reduce-flash setting, if present, is shown working in a second capture of the same event.

### Background plate shots

- Luminance cap: no background pixel inside the board area exceeds 40 percent of the luminance of an unlit hull facet. Check by sampling, not by eye alone: sample the brightest board-area pixel against an unlit facet in the same shot.
- Ship separation: the faintest ship colour in the shot still reads against the brightest background pixel in its region, on the desktop frame.
- Layer discipline: the four layers read (far gradient, one mid feature, near particulate, starfield), and the mid feature does not compete with the ships for attention.
- Region seasoning: where a plate is seasoned for a home faction, the tint is a whisper, not a repaint. A Hegemony belt and a Deathless belt are cousins, not clones.
- UI legibility: with the HUD visible, every HUD element reads against the plate. If any element needs a scrim or a colour change, that is a finding, not a styling preference.

### Battle shots

- Board readability at fighting zoom: every ship's faction and rough damage state read without selecting it.
- HUD behaviour: the HUD fades during capital kills and boss arrivals and returns cleanly. No HUD element is lost, duplicated or left faded after the event.
- Camera behaviour: push-ins are slow (about 1.2 seconds for a Command or boss arrival) and never fire during the player's own aiming or targeting. Shake is short, decays, scales with the event, and is absent during targeting.
- UI motion: button presses acknowledge within about 100 ms. Animations run under 300 ms and are interruptible. No layout animation stutters the frame.
- Accessibility: the reduce-flash setting and the motion reduction toggle, if present, are each shown working in a second capture of the same event.

### Known tensions: check explicitly, do not smooth over

These are open contradictions in the design documents. A batch must report on them rather than assume them resolved:

- Gold-adjacent trims (Chorus dull gold, Ithar pale gold, epic rarity) must not read as Command gold. If a viewer confuses a trim for a Command marker, that is a finding against the rationing rule, not against the viewer.
- Shield identity is carried by ripple shape, while the same documents admit glow is the first thing lost at small size. The ripple shape check must therefore be done at battle zoom.
- Plate to terrain mapping is unmapped (18 plates against five terrain kinds). Until a mapping exists, every plate shot must record which terrain kind it is claimed for, so the mapping can be built from evidence rather than asserted.

## 4. Scoring rubric

Every shot in a batch gets one grade. Grades apply to shots, not to batches: a batch can contain passes and fails at once.

- **Pass.** Every applicable check observed. The shot goes to the owner verdict loop as approved material.
- **Pass with notes.** Every load-bearing check observed (silhouette, faction at a glance, colour law, luminance cap, flash count), with one or more minor notes attached (a bloom weight to tune, a UI element that wants a scrim, a trail that wants shortening). Notes do not block the owner verdict, but they travel with the shot and must be answered in the next batch that touches the same subject.
- **Fail.** Any load-bearing check not observed, or any known-tension check that reports a confusion (gold mistaken for Command, ripple unreadable at battle zoom, a ship misassigned to a faction). A failed shot does not go to the owner as approved material.

On a fail, what gets sent back:

- The shot itself, with the failed checks named and the frame or region marked.
- The build tag and tier, so the failure is reproducible.
- For a re-check, the same shot retaken under the same conditions (same camera, same zoom, same lighting, same tier) after the fix, plus a one-line note stating what changed. A re-check taken under different conditions is not a re-check; it is a new shot and is graded as one.
- A fail on a silhouette or faction-at-a-glance check sends the manifest back, per the kit work order. A fail on a colour law or luminance cap check sends the material or plate back, not the hull geometry.

## 5. Multimodal review by external models

External models (DeepSeek and Qwen web chats, as used elsewhere in this project) are a cheap second opinion on screenshots. They are not a verdict source. Their findings are observations to verify, never verdicts, and the owner's verdict is the only verdict.

### Packaging (owner's manual-effort budget: upload plus one sentence)

- One screenshot per message, plus one sentence of context naming the subject, the tier, and the check being asked about. Example: "Voidsworn Basilica, desktop tier, silhouette readability check."
- Never batch ten screenshots into one message and ask for general impressions. One shot, one question, one check.
- Send the desktop frame.

### Reviewer prompt template

Copy this template and fill the brackets. It asks for specific, checkable observations rather than taste:

> You are reviewing a screenshot from a space tactics game for readability, not for beauty. Do not judge taste. Answer only these questions, one line each, and say "cannot tell from this shot" where the shot does not show it:
> 1. What faction is each ship in this shot, and what in the image tells you so (outline, colour, or glow)?
> 2. Is any cyan visible that is not a shield, shield hit, or shield UI element? Where?
> 3. Is any gold visible that is not a patron marker or Command UI? Where?
> 4. Can you read every ship's faction and rough damage state at this zoom without selecting anything? Which ship, if any, fails?
> 5. Does any background element compete with the ships for attention? Which one, and where?
> 6. Is anything in this shot unreadable, ambiguous, or confusing? Name the element and the confusion.
> Do not suggest redesigns. Do not praise or condemn the art direction. Report only what is observable in this shot.

### Handling external findings

- Every external finding is checked against the shot by a human (Opus or Rey) before it reaches the owner. A finding that does not survive that check is discarded with a one-line reason, not forwarded.
- A finding that survives becomes a note on the shot, graded under section 4 like any other note. It never upgrades or downgrades a grade by itself; the grade follows the checks, and the external finding is evidence for a check.
- Conflicting external opinions are reported as a conflict ("DeepSeek reads this hull as Hegemony, Qwen reads it as Ithar"), not resolved by picking the flattering one. The owner resolves conflicts, or the shot is retaken to remove the ambiguity.

## 6. Owner verdict loop

The owner (Ryan) judges by screenshots and his verdict is final. Batches go to him in groups, not as a drip feed, and verdicts are recorded so a later session does not re-litigate them.

### Batching

- A batch is one subject (one hull, one effect family, one plate, or one battle) across both tiers, with all its shots and grades attached.
- A batch is sent only when every shot in it is graded. Ungraded shots do not travel.
- A batch carries a one-line summary: subject, tier, build tag, grades (how many pass, pass with notes, fail), and any known-tension reports.

### Verdict format

A verdict is one of three, per shot, recorded in the verdict log:

- **Approve.** The shot stands. The subject may proceed.
- **Approve with notes.** The shot stands, with named notes that must be answered in a later batch touching the same subject. Notes do not reopen the verdict.
- **Reject, with reason.** The shot does not stand, and the reason names the failed check or the confusion (for example: "reads as Hegemony at battle zoom" or "gold trim reads as Command"). A rejection names what must change for a re-check.

A verdict on a batch is not a verdict on the subject forever: a later batch with new evidence can supersede it, but only by naming the earlier verdict and the new evidence. Silence is not a verdict. A shot with no recorded verdict is unjudged, not approved.

### Verdict log

Record verdicts in one file, `verdicts.md`, kept alongside the screenshots (see section 7). One entry per shot:

```
date | shot file | subject | tier | build | grade | verdict | reason or notes | supersedes (if any)
```

A later session reads the log before re-shooting a subject. If a verdict exists, the new batch answers it or names why it is being reopened. Settled verdicts stay settled: a thread the owner has closed ("approve", "reject with reason and a fix delivered") does not come back wearing a new batch unless new evidence justifies reopening it.

## 7. File and naming conventions

Keep screenshots where a later session can find them without asking anyone. One folder per batch, under a single screenshots root:

```
screenshots/
  verdicts.md
  <batch-date>_<subject>_<build>/
    <subject>_<shot>_<tier>_<version>.png
    notes.md
```

Naming rules:

- `subject`: the hull code, effect family, plate name, or battle identifier, in lowercase, words separated by underscores (for example: `basilica`, `beam_voidsworn_lance`, `bg_belt`, `battle_sector2_elite`).
- `shot`: the shot type from section 2 (for example: `lit_hero`, `silhouette_sheet`, `shield_hit`, `plate_with_ships`, `capital_kill`).
- `tier`: `desktop`.
- `version`: `v1`, `v2`, and so on, incremented on every re-check of the same shot. Never overwrite a version. The verdict log points at versions, so overwriting destroys the evidence chain.
- `notes.md` in each batch folder: the batch summary (subject, tier, build tag, grades, known-tension reports, and any external model findings that survived checking, with the model named).

File format: PNG. No JPEG for acceptance shots: compression artifacts are not a check anyone should have to discount. Keep the original capture; crops for external review are copies, named with `_crop` before the version, and the original stays in the folder.

## 8. Quick reference: checks most likely to catch a real defect

If a batch is short on time, run these three first. Each one has caught a real class of defect in this project's history:

1. **Silhouette sheet at battle zoom.** A hull that reads in hero framing and not at battle zoom is the most common failure mode in the whole pack, and it is also the cheapest to test: flat black, small, in a grid, no colour to hide behind.
2. **Cyan and gold audit on a battle shot.** One frame of a real battle, checked pixel by pixel for off-law colour, catches palette drift, rarity colour collisions, and trim mistakes that hero shots hide.
3. **Luminance cap sample on a plate with ships.** A beautiful plate that eats the ships is a failed plate, and the eye alone will forgive it. Sample the brightest board-area pixel against an unlit facet; the number decides, not the impression.

## 9. Reference scoring (added Oct 24, 2026, from a technique Ryan flagged)

Score the render against the reference instead of eyeballing it alone. For each screenshot batch, score the render programmatically against the matching concept plate: palette and histogram match, light and contrast match, and the background luminance cap measurement from section 3. Record the score in the batch notes.md.

The score is a tone and lighting gate only. It cannot pass a shot on its own: silhouette readability, faction identification at a glance, and the owner's verdict are separate gates, and a high score on a wrong-looking ship is still a fail. The loop discipline that goes with it: change one thing per iteration, keep a side-by-side of render versus reference for each change, and auto-fitting a color grade (LUT) to the reference plate as a final step is a legitimate tool, not a cheat, provided the grade is recorded with the shot.

## 10. Platform note (Oct 24, 2026 ruling: PC-only)

This pack was first written phone-first and was re-tiered under Ryan's Oct 24, 2026 platform ruling: PC-only in Babylon, phone target dropped entirely. The desktop frame is the only frame. Phone frames, phone acceptance checks, and phone tier values in earlier drafts are struck. Verdicts are recorded against desktop shots only. The engine stays Babylon; a wrapper or engine migration is a separate, undecided question.
