# Nemesis assignment design draft: chair synthesis (issue #103, for #45)

Chair: Rey. Inputs: DeepSeek leg and Qwen leg (both writers, filed under legs/), Argon review leg (reviews and ideas only, R81), the evidence pack's verified grounding from current main, FINDINGS R62/R63, the Job 7 progression synthesis steps 6, 7 and 11, the Job 9 faction review's drafted pairings, and the chair's own enumeration over seeds (section 5). Issue #45's ruling governs: no faction gets one permanent Nemesis hunter; assignments are symmetric across the set and variable, chosen by story point, with all drafted hunter options in play.

## Verdict: GO

The design below is ready for Opus to turn into build issues. It keeps the shipped Nemesis machinery recognisable, changes only the assignment shape and the commander container, and proves its symmetry by enumeration rather than by assertion.

## 1. The chosen mechanism

At run start, draw one hunter faction for each story point from the five non-player factions, with no consecutive repeats:

- SP1: uniform draw from the five non-player factions (probability 1/5 each).
- SP2: uniform draw from the five minus the SP1 hunter (probability 1/4 each of the remaining).
- SP3: uniform draw from the five minus the SP2 hunter (probability 1/4 each of the remaining).

The assignment is computed once at run start and stored as RUN.nemAssign = [H1, H2, H3] (name suggested; Opus owns the final field name). There is no cross-run balancing state; each run is independent.

Marginals are exact, not approximate: for every player faction and every story point, every non-player faction has probability exactly 1/5, and the player's own faction has probability 0. The no-consecutive-repeat constraint changes only the joint distribution, not the marginals. Expected hunts per faction across the full 6 x 3 set are exactly 3 for every faction, which the chair's enumeration confirms (section 5).

The decisive property of this mechanism, and the reason it wins over the alternative below, is the SP1 return: the SP1 hunter returns at SP3 with probability 1/4. That is what keeps the behaviour packages' return fiction alive inside a run. The Glasswright package says the duellist returns "with the same four elite ships upgraded"; the Hullbreaker package says he returns richer; the Eclipse package says he returns once after death in sector 3. A mechanism that guarantees three distinct hunters per run kills all of that within-run return behaviour and leaves the packages' return verbs with nothing to attach to until a later run.

## 2. Commander identity and persistence under rotation

One commander per hunter faction per run, created lazily when that faction is first drawn, using the existing newNemesis(fac) identity logic (campaign_run.js:250): name from the faction's pre/post pools (never an ADMIRALS name), title, persona, two strength traits, portrait id nem_<faction>_1..6, two weaknesses from NEM_WEAK (data.js:428), scars and epithets on survival. The container is a registry keyed by faction (RUN.nems in the DeepSeek leg's naming); the active commander for sector k is the registry entry for RUN.nemAssign[k-1].

State attaches per commander, not per run and not per campaign:

- Weaknesses and their revealed set: per commander. nemReveal (campaign_run.js:271) reveals on the active commander.
- Adaptations: per commander, per run. nemAdapt (campaign_run.js:300) runs for the commander active in the sector, on sector advance (campaign_run.js:576), reading that commander's own seen data. Commanders and their adaptations reset at run start, exactly as shipped today; nothing in #45 asks for cross-run Nemesis accumulation, and the campaign's meta-progression spine is admiral leveling and renown (R62), not hunters compounding across runs.
- Scars and epithets: per commander, per run. An escaped SP1 commander who returns at SP3 carries his scars; a commander met once and not redrawn keeps no cross-run state.
- Lessons (Job 7 step 7 debrief teaching): per commander. This answers the #71 debrief design's revisit trigger directly: lessons were hunter-specific, and the hunter under this design is the commander at that story point, not the run as a whole. The lesson text may name the faction package (the behaviour is what the player must learn), but the key is the commander, so a lost meeting against a Chorus commander teaches that commander's feed pattern, and the same faction's next commander teaches anew.

Sector 3 deciding fight: the SP3 commander is the one whose flagship death ends him (campaign_run.js:244-249 header comment). SP1 and SP2 commanders not drawn at SP3 are simply absent; if beaten earlier they escaped and do not return within the run. If the SP3 commander is the same as SP1, his SP1 escape is followed by the SP3 return and death, which is the strongest single arc this design produces.

The clock (NEM_CLOCK = 4, data.js:427) stays a single run-level accelerant. Its pace is read from the active commander's faction beh.clock (data.js:443-470: Eclipse 0.5, Crusade 1.5, others 1.0), and nemStrike (campaign_run.js:284) fires the active commander's strike. A strike brings the sector's assigned meeting forward inside the sector; it never changes the hunter and never creates an extra meeting.

## 3. The matrix: player faction by story point

Every non-self cell has the same five hunters at probability 1/5 each; the player's own faction has probability 0. The no-consecutive-repeat constraint is a joint restriction on the row, not a marginal change: Pr(H2 = H1) = 0, Pr(H3 = H2) = 0, Pr(H3 = H1) = 1/4.

Player | SP1 (1/5 each) | SP2 (1/5 each) | SP3 (1/5 each)
Glasswrights | Hullbreakers, Crusade, Hegemony, Chorus, Eclipse | same five | same five
Hullbreakers | Glasswrights, Crusade, Hegemony, Chorus, Eclipse | same five | same five
Sunward Crusade | Glasswrights, Hullbreakers, Hegemony, Chorus, Eclipse | same five | same five
Hegemony | Glasswrights, Hullbreakers, Crusade, Chorus, Eclipse | same five | same five
Chorus | Glasswrights, Hullbreakers, Crusade, Hegemony, Eclipse | same five | same five
Eclipse | Glasswrights, Hullbreakers, Crusade, Hegemony, Chorus | same five | same five

Against the Job 9 draft, the defect is gone: Hegemony hunts (it never did in the draft), Eclipse hunts exactly as often as every other faction (it hunted twice in the draft), and every ordered pair of distinct factions is reachable at every story point (probability 1/5 per cell, and 3/5 of appearing at least once in a run). No pairing is fixed and no pairing is impossible.

## 4. What this changes and what it does not

Behaviour packages: unchanged. All six NEM_FAC[fac].beh packages (data.js:443-470) stay attached to their hunter faction wherever it appears, per #45: Hullbreaker raids, Glasswright duels and returns upgraded, Chorus grows from the player's losses anywhere, Eclipse never retreats and returns once after death in sector 3 only, Crusade duels the flagship and chalks names, Hegemony reinforces in round 3. The packages were never the redesign problem; the assignment shape was.

Job 7 step 6 (clash check): unchanged in rule, extended in scope. The blocked-set logic in nemAdapt (campaign_run.js:300) still prevents an adaptation from directly countering a REVEALED weakness; it now runs per commander on that commander's own revealed set, and the tests at contrib/opus/tools/nemesis_clash_tests.js gain per-commander cases. The check is not duplicated into telemetry.

Job 7 step 7 (mandatory meeting and teaching): the once-per-sector meeting stands, enforced at nemNodeIs (campaign_run.js:296) with the active commander resolved from RUN.nemAssign; the meeting language names the assigned commander and owns the mandatory status, with the clock as accelerant only. Debrief teaching on a lost meeting attaches to the commander met (section 2), which is the #71 revisit trigger resolved.

Job 7 step 11 (telemetry): nemSignature (campaign_run.js:273) keeps its event schema and per-commander capped list, now tagged with the commander's faction; the escape counter is per run (it counts commanders who escaped, at most two per run: SP1 and SP2), and the compounding counter is per commander where the behaviour is commander-specific (Chorus growth is the example). The two counters are not merged and neither duplicates the clash check.

Run 5 finale: no special rule. The run 5 finale meeting is the SP3 meeting of that run under the same draw (chair pick, owner question Q4). A special arch-nemesis rule would add a code path and a documented symmetry exception for narrative closure the accumulated campaign already provides.

## 5. Chair enumeration over seeds

The chair ran both candidate mechanisms in Python (a faithful draw simulation, not the game code): 20,000 runs per player faction, 120,000 runs per mechanism.

Chosen mechanism (no consecutive repeats): hunts per faction across the full set, out of 360,000 slots, were Glasswrights 60,051, Hullbreakers 60,052, Crusade 59,919, Hegemony 60,113, Chorus 59,906, Eclipse 59,959, against an expected 60,000 each. The largest deviation of any single matrix cell from its 0.200 probability was 0.0054. Per run, 74.9% of runs presented three distinct hunters and 25.1% presented two, with the SP1 hunter returning at SP3, matching the analytic 1/4 return rate. The symmetry requirement is met within sampling noise.

Alternative mechanism (without replacement, the Qwen leg): also met the symmetry target (hunts 59,710 to 60,258 against 60,000 expected; largest cell deviation 0.0062), and every run presented exactly three distinct hunters. It was not chosen, for the reason in section 1: it guarantees the deciding fight is against a stranger and leaves the packages' return verbs with nothing to do inside a run.

## 6. Build issues Opus can file, sequenced

1. Assignment data and run init: compute RUN.nemAssign at run start with the section 1 draw, seeded from the run's RNG; store it on the run. Files: campaign_run.js (run start, newNemesis area at :250), Godot mirror campaign.gd:1114 and :1802.
2. Commander registry: replace the single RUN.nem with a faction-keyed registry, lazy creation via the existing newNemesis(fac) identity logic; resolve the active commander per sector from RUN.nemAssign. Files: campaign_run.js:250, campaign.gd:1802.
3. Meeting targeting: nemNodeIs (campaign_run.js:296) uses the active commander and a per-commander met-this-sector flag; a strike brings that meeting forward, never changes the hunter.
4. Clock and strike: keep the single run clock (data.js:427); pace from the active commander's beh.clock; nemStrike (campaign_run.js:284) uses the active commander. Files: campaign_run.js:280, :284.
5. Adaptation per commander: nemAdapt (campaign_run.js:300) runs for the commander active in the sector on sector advance (campaign_run.js:576); preserve the clash check; extend contrib/opus/tools/nemesis_clash_tests.js to per-commander cases.
6. Telemetry: nemSignature (campaign_run.js:273) tags events with commander faction; add the run-level escape counter and the per-commander compounding counter (step 11).
7. Identity and lessons: weaknesses (nemReveal, campaign_run.js:271), scars, epithets and debrief lessons attach to the commander object; the debrief teaching uses the active commander.
8. UI: the Nemesis panel shows the current sector's assigned hunter and, on a return, that commander's scars and lessons; prior commanders' states remain readable.
9. Tests: a seed enumeration test reproducing section 5's numbers, per-commander clash cases, once-per-sector meeting cases, telemetry cases.
10. Godot mirror: every item above lands in the Godot port in the same pass, with rules and campaign parity re-pinned (the Job 7 review's standing rule: every campaign rule change lands in both builds together).

Sequence: 1 and 2 are the data-shape foundation, 3 to 5 the meeting and adaptation behaviour, 6 and 7 state and telemetry, 8 presentation, 9 verification, 10 the port sync (which in practice interleaves with 1 to 9, not after them).

## 7. Screening notes

DeepSeek leg: used as the primary writer. Its arithmetic is exact and its mechanism is the chair's choice. One correction in scope only: its "RUN.nemClock" naming for the run clock is a suggestion, not shipped code (the shipped code keeps the clock on the commander object); the synthesis keeps the clock as a run-level value regardless of field name. Its enumeration deferral was the pack's own division of labour, and the chair supplies it in section 5.

Qwen leg: used selectively. Its matrix and marginal arithmetic are correct, and its pool-plus-pointer code shape (RUN.nem as an active pointer) is a legitimate alternative implementation of the same registry idea; Opus may prefer it. Not adopted: (a) the without-replacement draw, because it guarantees a stranger at SP3 and kills within-run returns (section 1); (b) campaign-level adaptation persistence (CAMPAIGN.faction_adapt), because it exceeds the #45 brief and rewrites meta-progression difficulty without a ruling, and it would make the step 11 compounding counter measure something the design never asked it to; (c) lessons keyed per faction across runs, because the #71 design keyed them per hunter and the chair reads the hunter here as the commander. (b) and (c) go to Ryan as owner questions Q2 and Q3 rather than being buried.

Argon review: screened out almost in full; see the chair header on the filed leg. Its description of the DeepSeek draw is wrong, its "no two repeats" rule does not exist in #45 or the pack, its symmetry objection misreads the pack's own definition (which forbids self-hunting), and it never engages the legs' real divergences. One credit stands: both legs defer the enumeration, which the chair supplies in section 5.

## 8. Owner questions (chair picks marked)

Q1. Assignment rule.
A) No consecutive repeats; the SP1 hunter may return at SP3 (probability 1/4). CHAIR PICK.
B) Three distinct hunters per run, no returns within a run (the Qwen leg's rule).
Why: A keeps the packages' return fiction alive inside the run (Glasswright "same four elite ships upgraded", Hullbreaker returns richer). B gives a tidier spread and a guaranteed fresh deciding fight, at the cost of killing those returns.

Q2. Adaptation persistence.
A) Per commander, per run, resetting at run start (shipped scope). CHAIR PICK.
B) Per faction across the whole five-run campaign (the Qwen leg's proposal).
Why: A keeps the redesign to what #45 asked (assignment shape) and keeps difficulty per run legible; B makes hunters compound across the campaign, which is a meta-progression change nobody has ruled on, and it changes what step 11's compounding counter measures.

Q3. Lesson keying.
A) Per commander, per run (the #71 design, read through the rotation). CHAIR PICK.
B) Per faction across runs (the Qwen leg's proposal).
Why: the lesson the player needs is what this commander did to them (a Chorus commander's feed pattern in this run); keying by faction would let a lesson earned against one commander stand for a different commander with different weaknesses and adaptations. B is cheaper to display but coarser as teaching.

Q4. Run 5 finale.
A) Same SP3 draw as every run. CHAIR PICK.
B) A special arch-nemesis rule (for example the faction that hunted most across runs 1 to 4).
Why: A keeps one assignment function and the symmetry arithmetic intact; B adds a code path and a documented symmetry exception for closure the campaign arc already provides.

Q5. Clock scope.
A) One run-level clock, paced by the active commander's faction. CHAIR PICK.
B) One clock per commander.
Why: the clock is an accelerant for the sector's meeting, and the sector has exactly one assigned hunter; per-commander clocks would let an inactive commander's clock tick or stall in ways the player cannot see, and would complicate nemClockAdd for no design gain.

## Not checked

- The Godot mirror was verified for newNemesis (campaign.gd:1114, :1802) and the shared data tables only; the exact Godot line numbers for nemNodeIs, nemAdapt and nemSignature were not verified and are Opus's to pin in the build issues.
- The exact PRNG stream layout at run start (which integers the draw consumes, and whether before or after other run-start rolls) is not specified in the shipped code the chair read; Opus confirms it at build time.
- The chair's enumeration is a draw simulation, not a run of the game code; it verifies the assignment mechanism's probabilities, not the shipped RNG.
- The run 5 finale's exact meeting shape beyond R62's "finale" framing was not re-verified for this job; Q4 covers the one design choice it creates.
