1. ITEM VERDICTS

1. KEEP. Repo hygiene protects the rules oracle and visual constants that ship feel depends on. A drifted constant is a silent feel regression, and this catches it before cutover.¹

2. KEEP. This is the one tool that guards visual quality directly. It also produces the screenshots the campaign visual review is blocked on. The manual blessing and per-environment goldens are the right guardrails. Screenshot diffing catches rendering regressions unit tests cannot.⁶⁷

3. KEEP. Asset provenance and LOD bakeoff caution keep ship quality honest. Generating gen/ in the build stops "it looks different on my machine" from becoming a feel defect.

4. KEEP. Canonical headless export means the build everyone screenshots and playtests is the same build. No feel connection beyond consistency, but cheap.

5. KEEP. Atomic saves matter for a roguelite. A torn save after a 40-minute battle is a fun killer. Split settings prevents resolution changes from being synced by Steam later.

6. REORDER: before Steam, not before cutover. Adopt GdUnit4 only if the screenshot suite needs its scene runner to reach battle states. The v6.2.x line is built on Godot 4.7 stable, MIT licensed, and has input simulation and fuzzing. But the custom parity harness stays the rules authority. This is not a cutover blocker.⁵⁴

7. KEEP. Music credits and a loudness target before the first track lands. The absence of music content is a feel gap; this is the cheapest way to unblock it without feeling like licensing overhead.

8. KEEP. Agents writing Godot 3 idioms into 4.7 is a feel risk because it burns iteration time that should go to battle feel. Exact-source lookup is the strongest single workflow pattern in the addendum.

9. KEEP. Verification-before-completion is a direct counter to false completion claims. No feel connection on its own, but it protects the time budget for feel work.

10. KEEP. Path-scoped rules and worktree isolation are low-cost. They prevent parallel helpers from colliding in the shell that drives battle.

11. KEEP. A linter gate over hand-written shell is report-first and never touches parity-mirrored files. This is hygiene, not feel. Call it out as such. It is cheap and worth keeping.

12. REORDER: later, after cutover. The single-threaded differential is a diagnostic for a threading finding, not a feel item. Run it when the finding bites, not before the gate.

13. KEEP. A frame-budget benchmark at 20-ship carrier scale is a direct guard on spectacle. If the frame budget caps battle scale, the owner needs to know before the effects pass, not after. Commit monitor readouts per change.

14. KEEP. Steam integration and CI build-and-inspect before Steam is the correct gate. Cloud saves must wait for item 5. No feel connection beyond avoiding a broken launch.

15. KEEP. Localisation scaffolding English-only is a before-Steam checklist item that costs almost nothing now and cannot be retrofitted cheaply after 1,500+ strings. No feel connection.

16. KEEP. Captions routed to the existing battle log are an accessibility and feel win. The battle log already exists; this is inventory work, not plugin work.

17. KEEP. Capsule checklist is a shipping task with zero feel trade. Codesigning only when a public demo exists. This belongs before Steam, not before cutover.

18. DROP before cutover. Re-evaluate later with a trigger. An editor/runtime MCP bridge is not a feel or fun item. It is a live-state convenience. The security and context-cost risks are real. Do not let it crowd the cutover.

19. REORDER: later, after item 1 and after cutover. A generated repo map attacks re-reading cost, but a stale map recreates the drift class. Mechanise regeneration first, then generate it. No feel connection before then.

20. REORDER: later, in their own passes when the fx work reaches them. AreaLight3D, DrawableTexture2D, and Control offset transforms are potential damage-mark and lighting wins. They belong with the big effects pass, not before cutover.

Items with no feel connection: 4, 9, 10, 11, 14, 15, 17, 18, 19. Keep or drop them on engineering grounds, not on this lens. Do not pad them into feel arguments.

2. WHAT IS MISSING FOR CINEMATIC FEEL

1. Battle cut-ins and a cinematic camera layer.
What: short, authored or semi-authored camera moves triggered by critical events: first salvo, torpedo impact, system critical, capital-ship destruction. Think a 2 to 4 second push-in, not a full cutscene.
Reference: Sins of a Solar Empire 2. Reviewers specifically praise the seamless zoom from grand strategic view down to a single capital ship's turret tracking and firing. That zoom is the camera language Voidsworn needs, translated to a turn-based cadence.¹
Effort: medium.
Gate: before cutover, because the camera rig and event hooks need to exist before the effects pass is authored against them.

2. Destruction spectacle with persistent aftermath.
What: a capital-ship death is not a particle burst and a fade. It is a multi-stage break-up, a drifting wreck, and a board-able or salvage-able hulk that persists for the rest of the battle.
Reference: EVE Online. Destroyed ships leave wrecks that persist, can be looted and salvaged, and the loss is permanent and consequential. The wreck is the visual receipt of the decision.
Effort: medium to large.
Gate: before cutover for the wreck persistence model. The VFX itself belongs in the big effects pass.

3. Pre-battle and post-battle presentation.
What: a mission briefing or fleet lineup before the first turn, and a debrief after the last: losses, scars, Nemesis lines, salvage. This is where Star Wars film drama lives: the pilots before the trench run, the medal ceremony after.
Reference: Star Wars films. The drama is carried by the briefing and the aftermath as much as the dogfight. Sins 2 gets this partly through capital-ship level-ups and titan customization, which make ships feel like characters before and after battle.¹
Effort: small to medium.
Gate: before Steam. It is content and UI, not core battle code. But it should start before cutover if the Nemesis lines are going to land, because the Nemesis memory is already tracked richly and spoken through very few lines.

4. Sound design as a first-class battle system.
What: not an ambient bed and not music. Weapon-specific impact sounds, a low-frequency hull groan on criticals, a distinct torpedo launch and travel sound, a silence beat before a capital ship dies. Sound is the cheapest cinematic multiplier in a turn-based game because it does not fight the frame budget.
Reference: Sins 2 and Star Wars. The Star Wars feel is carried by the sound of a Star Destroyer's turbolasers and the TIE fighter screech as much as by the image.
Effort: small to medium.
Gate: before cutover for the event hooks and the mix bus. Content can land later.

5. Ship presence at rest: idle animation and readable silhouette.
What: capital ships that breathe, not T-pose statues between turns. Slow turret tracking, running lights, engine glow, a subtle drift. The ship must read as high quality from the default camera, not only in a close-up.
Reference: Sins 2. The capital-ship turret tracking is called out as the detail that sells the scale. Voidsworn's per-weapon marks reference already exists, but generic scorch decals today are partial. Ship presence at rest is the other half of the same problem.¹
Effort: small.
Gate: before cutover for the animation hooks. The art content belongs in the effects pass.

6. Battle log as a drama surface, not only a captions sink.
What: the battle log already exists. Route critical events through it with filmic language and pacing: "Turrets one and two offline. Hull integrity at forty percent." This is free cinematic feel.
Reference: BattleTech's appeal is partly the board-game record of the fight. A log that reads like a damage report is genre-correct.
Effort: small.
Gate: before cutover, because item 16 is already routing captions there.

3. WHAT IS MISSING FOR FUN AND BALANCE

1. Playtest instrumentation that records decisions, not just outcomes.
What gets measured: every choice the player makes in a battle, per turn: which ship activated, which weapon targeted which subsystem, which card or ability was offered and declined, how long the decision took, and whether the player reversed a choice. This is the decision-density metric.
Decision it changes: whether a turn has enough meaningful choices or is padded by forced moves. BattleTech's 45-minute missions are the cautionary tale: weight without decision density becomes plodding.
Reference: Slay the Spire. Mega Crit built a metric server to track every decision a player made, including card pick rates, what a card was chosen over, and damage taken by card users. They then used patterns in that data to decide what to make more fun, not just more balanced.³⁸
Effort: medium.
Gate: before cutover, because the event schema should be in the battle code from the start, not retrofitted.

2. Battle-length and time-to-first-meaningful-decision telemetry.
What gets measured: wall-clock time per battle, per turn, and per decision; number of turns with zero state change; time spent in menus or camera transitions versus time spent deciding. The target is not "short battles." The target is "no dead turns."
Decision it changes: where to cut animation or camera time without cutting drama, and whether the settled larger fleet size is costing more in pacing than it buys in spectacle.
Reference: Slay the Spire's average run is about 17 minutes, with route challenge density held within a tight band. That is a deliberate pacing target, not an accident.
Effort: small to medium.
Gate: before cutover for the hooks. The dashboard itself can come later.

3. A tuning dashboard that the owner can drive without reading code.
What gets measured: the levers already exist: per-admiral win rates, boss matrices, faction matchups, Nemesis adaptation rates. The dashboard exposes them as live sliders or preset toggles in a debug build, not as a JSON edit and a re-run.
Decision it changes: the owner's playtest becomes a tuning session, not a bug report. He can feel a change in the same session rather than waiting for a 19,500-battle simulation to confirm what he already felt.
Reference: Slay the Spire's data-driven approach worked because the team could act on patterns quickly and intuitively, not because the data was exhaustive. The dashboard is the speed layer.³⁸
Effort: medium.
Gate: before cutover, because it depends on item 1's event schema and item 4's version stamping.

4. Replay and spectator tools for the owner's travel playtests.
What gets measured: a deterministic replay of a battle that the owner can scrub, slow down, and annotate. While he is travelling, automated checks stand in for his playtests, but a replay lets him review a battle after the fact and mark the exact moment the fun died or the feel landed.
Decision it changes: which specific frame or turn a feel verdict applies to. "The torpedo impact felt weak" becomes a timestamped observation, not a vague note.
Reference: no single reference game owns this. But BattleTech's speed options and close-up animation toggle show that players and designers both need control over presentation pacing to judge feel.
Effort: medium to large.
Gate: before Steam, not before cutover. It is a review tool, not a build tool.

5. Difficulty presentation that separates fleet size from admiral behaviour.
What gets measured: what the player is told about difficulty, and what actually changes. The data already shows enemy admirals ranging boss win rates from 38 to 98 percent. Fleet size ramps by run. Those are two different difficulty axes and the player currently sees neither clearly.
Decision it changes: whether the player can choose "more ships" or "smarter admiral" as distinct challenges, and whether the hidden admiral variable is doing too much work.
Reference: BattleTech's difficulty curve begins easy and ramps without speed bumps, but its slowness is a known pain point. Voidsworn's admiral variable is richer; it should be surfaced, not hidden, because a hidden 98-percent boss is a fun killer.
Effort: small.
Gate: before Steam, because it is a presentation and UI decision. But the telemetry from item 2 should be in place before cutover so the split is data-backed.

4. RISKS

1. Process crowding out the effects pass.
The addendum is almost entirely process. Items 1 through 13 are all before cutover, and if they all land first, the big effects pass that the owner is actually waiting for gets pushed. The screenshot suite and the frame benchmark are worth it. The MCP bridge and the repo map are not.
Guardrail: adopt only items 1, 2, 3, 4, 5, 7, 8, 9, 13, and 16 before cutover. Everything else is before Steam or later. Put the effects pass on the calendar before item 18 is even discussed.

2. The screenshot suite freezing an art style too early.
Per-environment goldens and manual blessing are the right mechanics, but a suite blessed before the per-weapon damage marks are implemented will lock in generic scorch decals as the baseline. The same-day audit already says the damage marks are partial against the reference.
Guardrail: bless the v1 shot list with a written note that the damage-mark goldens are provisional and will be re-blessed after the effects pass. Do not let a passing screenshot suite become an argument that the current marks are acceptable. The owner's eye is the verdict, not the diff.⁶⁷

3. A frame budget capping spectacle before the effects exist.
Item 13 is a benchmark at 20-ship carrier scale. If it is treated as a hard cap before the VFX pass, it will trim the very spectacle the owner asked for. Sins 2's spectacle is expensive; Voidsworn's 20-ship board is not Sins 2's hundred-ship board, but the capital-ship moments still cost frames.
Guardrail: run the benchmark as a report, not a gate, until the effects pass is authored. Set the budget after the owner has seen the full-effects battle, not before. A frame target set before the spectacle exists is a target for the wrong game.

4. A hidden difficulty variable that the tooling makes more hidden, not less.
The admiral win-rate spread is a fun risk that the addendum does not address. A dashboard that only exposes aggregate win rates can launder a 98-percent boss into a "balanced" average.
Guardrail: the dashboard in missing item 3 must show per-admiral distributions, not means. No difficulty tuning decision is made on an average that hides the tail.

5. THE ONE THING

Add a cinematic event director: a small, data-driven system that triggers camera moves, sound stings, and battle-log lines on defined battle events, and give it to the owner as a tuning panel before cutover.

Why this one: every other missing feel item depends on it. Battle cut-ins are an event director with a camera track. Destruction spectacle is an event director with a break-up sequence. Sound design is an event director with a stinger. The battle log as drama surface is an event director with a text line. Right now these would each be built separately, and the owner would tune them by editing code. A single event director turns the owner's playtest into the tuning loop for all four at once. It is also the cheapest way to buy the Star Wars film drama the owner named: drama is timing, and timing is an event system.

It is medium effort, it belongs before cutover because the battle code needs to emit the events from the start, and it is the one addition that makes the addendum's existing frame benchmark and screenshot suite more useful rather than more restrictive. The benchmark can budget the director's camera moves; the screenshots can bless the director's staged moments.

Overall verdict

The addendum serves the game the owner described only if it is read as two lists, not one. The first list is the feel guard: hygiene for the rules and constants, a screenshot suite with manual blessing, asset provenance, a canonical build, atomic saves, a music credits schema, exact API lookup, and a frame benchmark. Those are worth the cutover time because they protect the battle feel the owner is actually buying. The second list is workflow comfort: the MCP bridge, the repo map, the linter, the localisation scaffolding, the capsule checklist, the threading differential. Those are real work, but they belong before Steam or later, and adopting them before cutover would push the effects pass that the owner is waiting for. The single change I would insist on is this: reorder the addendum so the effects pass and the cinematic event director are on the cutover side of the line, and move items 12, 18, and 19 behind them. The tooling is not the product. The tooling is only worth what it protects, and what it should protect first is the twenty seconds where a capital ship dies and the player feels it.
