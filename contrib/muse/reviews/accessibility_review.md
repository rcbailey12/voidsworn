# Accessibility review: chair synthesis (Job 7, brief muse_2026-10-26c)

Scope: the Godot build's accessibility surface as evidenced in the Job 7 pack (settings system, HUD and title code, board colours, fx API contract, look code), judged against WCAG 2.x criteria and the Xbox Accessibility Guidelines and Game Accessibility Guidelines by topic. Four blind inputs: DeepSeek, Qwen, Gemini Argon, and the Rey audit, all filed in this repo. This synthesis sets its own bar where the legs calibrated differently, and says so.

A note on citations: the three model legs cited guideline numbers from memory, and their numbering does not agree with each other. The Rey audit opened its sources and its numbering is the most reliable of the four, but the chair has not independently re-verified every number either. This synthesis therefore cites WCAG success criteria (1.4.1, 1.4.3, 1.4.4, 2.1.1, 2.2.1, 2.3.1, 2.3.2, 2.4.7), on which all four inputs agree, and guideline topics rather than XAG numbers.

## Verdicts by area

| Area | DeepSeek | Qwen | Argon | Rey | Chair |
|---|---|---|---|---|---|
| Colour-blind readability | PARTIAL | PARTIAL | PARTIAL | PARTIAL (board FAIL) | PARTIAL |
| Flashing | PARTIAL | PASS | PARTIAL | PARTIAL | PARTIAL |
| Text size and contrast | FAIL | PARTIAL | FAIL | FAIL | FAIL |
| Input remapping | FAIL (absent) | NOT PRESENT | FAIL (absent) | NOT PRESENT (FAIL) | NOT PRESENT |
| Hold-vs-toggle / burden | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARTIAL |
| Captions | FAIL (absent) | PARTIAL (absent) | PARTIAL (absent) | NOT PRESENT | NOT PRESENT |
| Motion comfort | PARTIAL | PASS | PASS (in area 6) | PARTIAL | PARTIAL, the strongest area after flashing |
| Speed / difficulty | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARTIAL |

Overall: PARTIAL, with one cheap FAIL (text) and one structural absence (remapping). The comfort and safety settings are built like someone read the guidelines; the reading and input foundations are not yet at that standard.

## Where the legs disagreed, and the chair's ruling

1. Flashing, PASS vs PARTIAL. Qwen passed the area on the strength of the cap and reduce mode. The other three held at PARTIAL because rendered compliance (luminance swing, red saturation, flashing area) is unmeasured: the pack contains a count contract, not measurements. Chair: PARTIAL. A contract document is not a measured pass, and the fx implementation audit (fx_implementation_review.md) has since shown from the fx code that the counted cap binds only the gated subset of emitters, which settles the question against a clean PASS on its own.

2. The merge window argument. DeepSeek and Argon both argued the 0.12 s salvo merge window can let more physical flashes through than the count suggests. The fx audit establishes from code that flash_ok enforces the cap of 3 counted per rolling second regardless of spacing; the merge window decides which flashes draw at full brightness inside that cap, not how many counted flashes occur. The residual photosensitivity risk is real but lives elsewhere: in the ungated bright emitters the fx audit catalogued (battery muzzle core, event lights, torpedo fireball, death flame train), and in unmeasured luminance and area. The legs' underlying worry was right; its mechanism was wrong. The 0.12 vs 0.33 s disagreement itself is a spec reconciliation item, handled in the fx synthesis.

3. Text, FAIL vs PARTIAL. Qwen scored text PARTIAL; the other three FAIL. The agreed facts: battle HUD body text is 14-15 px at 1080p against an 18 px PC guideline floor, the scaling floor takes the help line to about 7 px, there is no user text-size control, and the controls help line (#7d7768) computes to roughly 3.1:1 to 4.2:1 against every plausible background in the pack, under the 4.5:1 bar (WCAG 1.4.3). Chair: FAIL. When the line that teaches the controls is the worst offender on both size and contrast, PARTIAL understates it.

4. Fix ranking. The legs agree on the fix set and differ only on order. Chair order below puts the FAIL with the one-hook fix first, then the two-line focus fix only Argon caught, then the structural work.

## Ranked fixes (chair order)

1. **Text scale, base sizes, and the help line colour.** Add a user text scale multiplying inside the existing s(v) hook (present in both hud.gd and title.gd), raise base sizes toward the 18 px floor, raise or rethink the 0.6 clamp floor, and move the controls help line (hud.gd line 470) and the muted log category (line 542) from #7d7768 to BONE2 #b3aa95, which already passes at about 5.96:1 to 7.82:1 on the pack's backgrounds. Highest value per effort in the audit: one function, one settings entry, one colour change.
2. **Restore menu button focus.** title.gd sets Control.FOCUS_NONE and an empty focus stylebox on every title and settings button (lines 100, 116), which blocks keyboard and controller menu navigation outright (WCAG 2.1.1, 2.4.7). FOCUS_ALL plus a visible focus border is a two-line change with an outsized effect. Argon catch; no other leg saw it. In the same pass, persist slider changes on value change, not only on drag_ended.
3. **Second channels on board zones, and crests in battle.** Exit green and guard red sit at about 1.46:1 and 1.23:1 composited, a red-green pair carrying opposite meanings by hue alone (WCAG 1.4.1). Add icons or short labels and an edge pattern difference per zone type. Separately, the faction crest shapes in crest.gd are a genuine second channel that currently lives in the career UI; draw the crest on the selected ship panel and ship markers so it works at the moment of identification.
4. **InputMap actions and a rebind list.** No [input] section, no InputMap use, no gamepad references anywhere in the pack. Define named actions, convert the fixed key checks, store overrides through the existing settings save flow, expose a basic rebind list in the existing panel, and make the help line read from live bindings. Medium effort, and it is the feature the guidelines treat as basic. While there: the help line omits four documented keys (X ram, G board, Space hurry, V firing arcs, from FEATURES.md); document them.
5. **Toggle-drag camera and keyboard orbit/zoom.** Orbit is right-drag only, a sustained hold-and-move. Add a click-to-latch drag toggle and keyboard orbit and zoom keys beside the existing WASD pan, T, F, and Home. The turn-based core, the two-click Command confirm, and the absence of timers or chords already earn this area its PARTIAL; orbit is the exposed piece.
6. **A rendered photosensitivity measurement pass.** Capture the busiest salvo and a capital death, measure luminance swing, red saturation, and flashing area against WCAG 2.3.1, and record the numbers beside the fx API section 8 contract. The design looks right; what is missing is proof. This also closes the area question the fx audit cannot answer from code.
7. **Speed and timing small items.** Add a slower-than-normal speed option (only Normal and Fast 0.45 exist), lengthen the 3.0 s title toast, and widen Enemy AI beyond Veteran and Standard or state plainly what Standard changes. Consider defaulting AI to Standard.
8. **Captions: inventory first.** No caption or subtitle system exists, and no spoken content is evidenced in the pack. If any sound cue carries gameplay information alone (faction music is an identification channel), route it to the existing battle log or a caption line. Build a captions system only if spoken content arrives.

## Strengths worth stating

- Reduce flashing is wired end to end (settings dictionary, panel toggle, live pass into fx) and its degraded forms are designed, not just dimmed. Shake is positional only, short, scalable to Off, and halved again in reduce mode. Follow and cut-in controls cover the other motion sources.
- Sound and music have separate toggles and sliders, settings persist, and the in-battle menu can change options mid-battle, including AI level.
- The crest shape set is a real non-colour identification channel, already built; it is placed in the wrong UI for battle, which is a placement fix, not a build.

## Open questions for Opus

1. Can a keyboard-only path complete a full activation today (pick a destination hex and a target without the mouse)? All four inputs mark this UNSURE; the answer decides whether fix 4 is remapping only or remapping plus a targeting path.
2. Do zone hexes carry icons or labels in the current build, and does the R-key threat map encode danger by colour alone? Pack-level UNSURE on both.
3. Does the campaign UI use the blackletter face at small sizes anywhere? The pack shows it only at 110 px and 30 px.
4. Is any gameplay information carried by audio alone (beyond faction music identity)?
5. Does hud.gd recompute the scale factor k on window resize? Title computes it once in _ready; the HUD side is UNSURE.

## Not checked

- Rendered frames (no screenshots or captures in the pack); all contrast figures are computed from palette values, not measured from pixels.
- godot/fx internals for this job (covered by the fx implementation audit, which this synthesis cross-references for the flash mechanism).
- The campaign UI's own text sizes beyond what the pack quoted.
