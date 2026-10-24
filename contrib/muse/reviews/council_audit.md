# Council audit: five lenses, one game

Commissioned by the owner, Oct 23, 2026: a full council audit of Voidsworn, red team and adversarial, from five seats: a sci-fi nerd on the universe and theming, a gamer on fun and complexity, a software engineer on architecture and tooling, a QA checker on bugs, and a designer on effects, graphics and art direction.

Basis: repo main at commit 4fa29bd ("Add files via upload"). Method: each lens read the repo independently, in full where its brief demanded, with code claims tied to file:line and exact quotes, marked OBSERVED or INFERRED. The QA lens additionally re-verified six headline findings from the earlier review series against current code. The chair (this synthesis) spot-checked the load-bearing claims from each lens against the files before writing: the borrowed-vocabulary counts, the flak block in canFire, the shield colour contradiction at fx3d.js:2-3, the texture release fix, and the unknownId helper at core.js:73 all check out as reported. Full lens reports are filed alongside this one in contrib/muse/reviews/council/ (scifi.md, gamer.md, engineer.md, qa.md, designer.md). Read them for the evidence; this file is the verdict.

## Overall verdict: GO WITH CONDITIONS

Four of five lenses returned GO WITH CONDITIONS independently. The fifth, the sci-fi seat, returned the harshest verdict of the series: a likeable collage, not yet a universe. The chair's reading: both are true at once, and that is the audit in one sentence. The machine is real (the battle engine, the save hardening, the telemetry, the review discipline itself). The identity is unfinished in every medium simultaneously: the fiction cannot say what its gods are, the fleet is one finished ship and thirty-five intentions, the vocabulary is partly other people's, and a new player is handed roughly thirty-four systems before their first interesting decision. Nothing the council found is fatal. Almost everything it found is the same finding wearing five costumes: Voidsworn grows by adding, and it has not yet had its consolidation passes. The conditions below are those passes.

## Where the council agrees

### C1. The core is genuinely good, and every lens found its own proof

The gamer: fire on the move, shield facings, telegraphed rams and boss Commands are a real tactics core, not a demo. The QA checker, sent into the least-reviewed files expecting rot, found sfx.js, meshopt3d.js and tbot3.js clean and defensive, and verified the migrateMeta backfill math against the live grants (no double counting). The engineer credits the build guards, the seeded node replays, the error reporter and a telemetry system good enough that the gamer could price animation downtime and win rates from the game's own harness. The designer credits FAC3D's per-faction material animation, the layered damage presentation and the planet shader. The sci-fi seat, the harshest, still names Chorus, the Deathless and the Corsairs as original voices worth keeping. A council convened to be adversarial does not manufacture this paragraph; the game earns it.

### C2. Identity is the unfinished layer in every medium at once

Four lenses, working independently, arrived at the same structure: a shared skeleton wearing unfinished skin.

- Fiction (sci-fi): the six patrons who drive every run, Kharon, Vyre, the Hunger Below, Astra, Rook and the Ember Choir, are never explained anywhere in the game. Gods, aliens, AIs: the text never says, yet they grant the boons, take the favour and pick the Chosen. Under that silence, the vocabulary is partly verbatim borrowing (counts verified by the chair in data.js): wraithbone x3, turbolaser, astropath x3, gauss flayer x2, shuriken, hyperdrive motivator, durasteel, archeotech, auspex, cogitator x13. Some of that is homage; some of it is another studio's trademark used as a weapon name, which is a legal exposure as well as an artistic one.
- Factions (sci-fi and designer, independently): all six factions share one class ladder, one admiral cost curve (0/30/45/80) and a rotating Command pool, with reskin tables that sometimes change nothing (the Corsair autocannon is still called Autocannon). On screen it is the same story: Voidsworn and Corsair are both dark hulls with red-orange glow and they are the sector 1 pairing; gfx3d.js:221 compensates for "the black fleets" with a 1.7x rim. Six civilizations, one silhouette family.
- Art (designer): the only art direction brief in the repo is a blank template with every field empty. Direction currently lives in code comments, backlog lines and per-screenshot reactions. And the most visible art fact in the game is the queue: 1 finished ship of 36, with plain_parts.md having already proved the detail pass cannot dress the big plain parts of the other thirty-five.
- Colour truth (designer): faction colour has two sources that disagree, data.js FACTIONS vs ships3d.js FAC3D (Voidsworn trim #c8501f vs #9c3a1c), so the UI and the 3D scene are painting the same fleet from different swatches. The shield language contradicts itself in adjacent lines (fx3d.js:2 "cyan is always shields", fx3d.js:3 shields wear their faction's colour), so a Voidsworn ship shows orange shields in 3D and cyan shield pips in its own nameplate at the same moment.

The chair's synthesis of C2: the patrons are the keystone. One paragraph deciding what they are would discipline the fiction, the glyph language, the aspect screen and half the boon text at a stroke. It is the cheapest high-leverage writing in the project.

### C3. Review debt: the findings pipeline has no closing half

The QA lens re-verified six headline findings from the Oct 22 review series against current code (4fa29bd):

| Prior finding | Status today |
|---|---|
| Intercept objectives cannot be lost by escapes (battle_rules) | STILL PRESENT |
| End turn double-activation, no busy latch (ui) | STILL PRESENT |
| Retreat modal keyboard hole (independent_audit) | STILL PRESENT |
| navLights forcing computeWorldMatrix(true) per ship per frame (effects_world) | STILL PRESENT |
| End card min-width 420px overflowing phones (ui) | STILL PRESENT |
| Veteran threat scoring LOS-blind (enemy_ai) | PARTIALLY FIXED (after-move term gated; in-range term and standard evalThreat still blind) |
| AI hull textures never released (ship_loading) | FIXED (aiTexReleaseAll at ships3d.js:963, called from disposeAllViews) |

One fixed, one partial, five untouched. This is not an accusation: the same week produced the space_3d design work and three other reviews, and the fixed item proves the loop can close. But the pattern is structural. Reviews are commissioned, written to a protocol and pushed; fixes have no equivalent forcing function, no open-findings list that survives between sessions, and no gate. The council's judgement: Voidsworn does not have a bug problem, it has a findings-evaporation problem, and it will compound with every new review (including this one) until the open list lives somewhere with the same status as BACKLOG.md.

### C4. The new player is the council's biggest worry

The gamer counted the learning bill: roughly 34 systems and 10+ resources, with faction, admiral, aspect, patrons and sector condition all decided before battle one, taught by 8 battle-local tips and a help text of about 1,500 words. The difficulty curve the player meets is a speed bump then a wall: the owner's own logged playtests won sector 1 four from four with no losses, and the game's own sim (run by the gamer lens: fuzz 20 with zero exceptions; campaign 10) shows 100% sector 1 battle wins averaging 3.1 rounds against a 40% win rate at the sector 2 elite. There is no player-facing difficulty dial: AI level is buried in Settings and Heat is locked until a first victory (campaign_meta.js:86), so the player who bounces off the wall has no legal way to soften it, and the player who cruises has no way to raise it. The sci-fi seat's version of the same complaint: the fiction front-loads unexplained terms exactly where the systems front-load unexplained mechanics. The designer's version: the UI wears the Voidsworn gothic costume for all six factions, so even the chrome teaches the wrong faction identity. Three lenses, one first hour.

### C5. The seams are where it breaks, and the seams are invisible by construction

The QA lens's new findings live almost entirely between systems, not inside them:

1. N1 (HIGH): unknownId (core.js:73) guards relics, modules and perks, but a renamed hull template throws in derive() (core.js:164) and a stale admiral id throws in the run summary (campaign_meta.js:196). Because saneRun never checks id membership, a content rename can brick a campaign into a boot loop. This is a save-bricking class waiting for the next rename, and ship renames are literally the current work programme.
2. N2 (MEDIUM): the flagship aspect dies silently when the flagship is lost outside a victory, because derive() gates it on RUN.flagUid (core.js:165) and neither the retreat path (campaign3d.js:89) nor shipyard selling (campaign_run.js:181) reassigns it. Only wins repair it.
3. N3 (MEDIUM): every settings write goes through Persist.saveLocal() with no stamp and no push, so a second device's newer stamped save silently reverts all local settings, including the accessibility toggles (reduce flashing, reduce shake).
4. N4 (MEDIUM): reportError (campaign3d.js:5) stops reporting permanently after the first 5 errors of a session, and throttled frame errors share that budget, so a serious late error gets neither telemetry nor the "saved at the last node" toast.
5. N5 (LOW-MEDIUM): death-sequence setTimeouts (fx3d.js:472-473) capture only a position, with no battle identity check, so a killing blow's delayed explosions can land on the reward or title screen.

The engineer explains why the seams are where the bodies are: the shipped behaviour is not findable from the definition site. build.py:8 concatenates 18 files into one global scope; five mutable singletons (G at roughly 1,705 references, B at roughly 1,325, RUN, META, SETUP) couple everything; and 20+ monkey patches of the form `const _x = x; x = function` (four in campaign3d.js alone, eight in perf3d.js) rewrite behaviour far from where a reader looks for it. The build guards, good as they are, guard the last failure: the duplicate check covers function names but not const/let/class, nothing parses the CSS (the unclosed #app{ at head.html:138 is still live), smoke.py checks a different 14-file list than the 18-file build, and test builds use local Babylon while publish uses the CDN build. The sim harness, the project's best testing asset, evals only 3 files plus hand stubs and builds its own short RUN literals bypassing runDefaults()/normalizeRun, so balance can drift from the shipped game with no failure raised.

### C6. Dead systems are teaching the player wrong lessons

From the gamer lens, verified by the chair where cheap to check: Resolve accrues to a cap of 5 and is spent nowhere the player can reach. Three of the four Orders (full, lock, helm) are implemented in battle.js (around :790) with no button and no ORDERS entry, so the one visible Order teaches the player the row is decorative. Flak is listed as a gun but canFire hard-blocks it against ships (battle.js, verified: `if(u.dead||t.dead||u.side===t.side||u.braced||w.k==='flak') return false`), which is defensible as an anti-craft weapon but is nowhere told to the player. A resource that does nothing, buttons that do not exist and a gun that silently refuses are worse than their absence: they teach the player to stop trusting the interface. The dominant strategy the numbers currently reward is focus fire into the 65% CP rout threshold with torpedo alpha early (raw EV about 26.9, and its cooldown never lands inside a 3.1-round sector 1 fight), and aim stacking (auspex, +10 aim, 80cr) strictly beats crit stacking (cogitator, +10% crit, 75cr) at near-identical prices.

## Where the council disagrees

- Sequencing. The engineer says do BACKLOG 4c first (split the giant files, publish the system map, replace monkey patches with a hook registry) before any new feature system. The designer says sign the one-page art direction before ship 2, because ship 2 is where drift becomes 36 hulls of drift. The gamer says fix difficulty and onboarding first, because players bounce off the first hour long before architecture matters to them. The chair's ruling: these are compatible if ordered by blast radius. The save-brick class (QA N1) and the review-debt sweep are days of work and protect everything else. The patron paragraph and the art direction page are one page each and gate the expensive programmes (career/story, the 36-hull queue). The 4c split comes before the next feature SYSTEM (altitude bands, career mode), not before the one-page decisions. Difficulty and the sim gate are cheap once the sim harness is trusted, and the sim harness fix is part of 4c. Nobody's first priority is wrong; doing any of them third is fine, doing any of them never is not.
- The sci-fi seat's verdict is the lone near-NO. The chair does not average it away: judged purely as a fictional universe, Voidsworn is a collage with an unexplained core, and no amount of engineering fixes that. Judged as a game in active development, the collage is what a universe looks like before its codex pass. The disagreement is really about timing: the sci-fi seat is warning that the codex pass gets harder with every content addition, and on that point the chair sides with the sci-fi seat. Write the paragraph now, while the game is still small enough to retrofit.

## The chair's top 10, ranked

1. Fix the save-bricking id class before the next content rename ships: extend the unknownId pattern and saneRun validation to hull templates, admirals and aspects (QA N1).
2. Review-debt sweep: close the five verified-still-open findings (Intercept escape win, endActivation latch, retreat keyboard hole, navLights matrix forcing, end card width) in one patch, and keep a standing verified-open list in HANDOFF.md so findings stop evaporating (all lenses, via QA verification).
3. Difficulty: flatten sector 1 up and the sector 2 elite spike down, put a plain difficulty pick on the admiral screen, unlock Heat from run one, and add a campaign-shape sim gate (bot vs veteran AI, target win bands per cell) to the publish checks (gamer).
4. Wire or cut the dead systems: give Resolve a spend or remove it, surface or remove the three hidden Orders, and state flak's role on its card (gamer).
5. Animation downtime budget: elite and boss fights currently carry 99 to 135 seconds of pure animation wait by the sim's own clock; fix the alternating-mode tail batch that runs all remaining enemies in one block (gamer).
6. The patron paragraph: decide what the six patrons are, why they watch all six factions and what a boon and being Chosen mean; publish it as codex text; then purge or replace the verbatim borrowed terms, wraithbone first (sci-fi).
7. One-page art direction, signed: per faction a silhouette rule, palette swatches with roles, material rule, lighting mood and glow behaviour, plus global rules for gold, shield colour and backdrop brightness; merge FAC3D and FACTIONS into one colour source (designer).
8. Seam fixes: reassign the flagship aspect on retreat and on shipyard sale (QA N2), and persist settings through the stamped save path so a second device cannot silently revert accessibility toggles (QA N3).
9. BACKLOG 4c before the next feature system: split the five worst files, publish the one-page system map with singleton ownership, and replace wrapper patches with an explicit hook registry in core.js (engineer).
10. Onboarding pass: teach in battle one through contextual tips, and defer or default the pre-battle decision stack (faction, admiral, aspect, patrons, sector condition) so the first interesting choice is a tactical one (gamer, sci-fi, designer).

## Per-lens verdicts, one line each

- Sci-fi nerd: a likeable collage, not yet a universe; its best original voices are drowned out by verbatim borrowings and an unexplained patron core, over a shared Imperial-fleet skeleton.
- Gamer: GO WITH CONDITIONS; the battle core is genuinely fun, the game around it overloads new players, mis-shapes difficulty, taxes animation time and hides dead systems on screen.
- Engineer: GO WITH CONDITIONS, structural not cosmetic; one person plus AI can still change this codebase, but only because the load order, patch order and state map live in the owner's head and handoff docs, not in the code.
- QA: GO WITH CONDITIONS; the least-reviewed files themselves are clean and defensive, the risk is in the seams, and one finding is a save-bricking class that should be fixed before the next content rename ships.
- Designer: GO WITH CONDITIONS; strong visual ingredients, no governing art direction; at screenshot distance the game reads as dark space tactics with orange and blue glow, not six civilizations at war.

## Not checked

The council read code, data and docs; it did not play the shipped build on the owner's Pixel (the gamer's numbers come from the game's own sim harness, the designer's from code and pipeline docs, not from fresh device screenshots). No lens audited the Python ship-generation tools (c19_kit.py, detail_lib) beyond the pipeline docs and the prior plain_parts finding. Multi-device cloud save behaviour (QA N3) is reasoned from the stamp logic, not reproduced across two devices. Balance claims rest on the sim's bot playing both sides; human play may break differently. The legal exposure note on borrowed terms is an auditor's flag, not legal advice.
