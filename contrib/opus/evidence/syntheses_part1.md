# C1: synthesis verification (5 syntheses, read-only)

Repo /home/claude/rcbailey12/voidsworn at HEAD d5d0227. Nothing in the repo was modified. Paths below are relative to the repo root. Review files are under contrib/. Code line numbers were checked with sed/grep at HEAD.

## Proof of reading

| File | Lines | Last non-empty line (first 40 chars) |
|---|---|---|
| muse/reviews/asymmetry_synthesis.md | 130 | `- Any owner playtest outcome (the Chorus` |
| muse/reviews/asymmetry_decision.md | 48 | `5. Deathless reanimate: Opus to report w` |
| deepseek/reviews/asymmetry_briefs_deepseek_draft.md | 194 | `End of briefs.` |
| qwen/reviews/asymmetry_briefs_qwen38max_draft.md | 197 | `End of briefs. All five decisions are th` |
| muse/reviews/difficulty_dial_synthesis.md | 80 | `Opus reports, in one pass: (1) does an e` |
| deepseek/reviews/difficulty_dial_deepseek_draft.md | 46 | `- Long-term default notch - notch 3 is a` |
| qwen/reviews/difficulty_dial_qwen38max_draft.md | 160 | `- The exact statistical confidence requi` |
| muse/reviews/onboarding_synthesis.md | 69 | `Opus verifies the merged top 5 (Fixes 1-` |
| deepseek/reviews/onboarding_lens_deepseek.md | 715 | `newShip(), derive(), changeShip(), chang` |
| qwen/reviews/onboarding_lens_qwen38max.md | 218 | `End of lens.` |
| muse/reviews/kit_spec_synthesis.md | 60 | `Opus runs the measurement pass first, be` |
| deepseek/reviews/kit_spec_deepseek_draft.md | 1136 | `End of draft.` |
| qwen/reviews/kit_spec_qwen38max_draft.md | 210 | `===== END OF SPECIFICATION TEXT =====` |
| muse/reviews/torpedo_boarding_synthesis.md | 66 | `Opus maps the merged proposal onto exist` |
| deepseek/reviews/torpedo_boarding_deepseek_draft.md | 257 | `10. Damage-model mismatch: if the curren` |
| qwen/reviews/torpedo_boarding_qwen38max_draft.md | 167 | `End of proposals. Both deliverables are ` |

How much I read: all of the syntheses, asymmetry_decision.md and both asymmetry legs. For the long legs (onboarding DeepSeek 715 lines, kit DeepSeek 1136 lines, torpedo and difficulty Qwen), I grepped for each claim the synthesis attributes to them and read the matching passages.

---

## 1. asymmetry_synthesis.md + asymmetry_decision.md

Verdict: the code claims are accurate and the citations are exact. Two leg-attribution slips. Three recommendations are now superseded by owner rulings.

Code claims verified at HEAD (OBSERVED): data.js:96-98 reanimate:true on scythe/jackal/harvester, and the boss data.js:99 has no flag. battle.js:702 gives 30% HP at 20% chance for enemies and 35% for the player. battle.js:314 applies h_undying to enemy non-boss ships (and also non-squadron, which the synthesis leaves out). The pyre boon is data.js:431. Nekhet is data.js:230. Avenge is battle.js:704, player side only. Its only source is data.js:187 (.15). canOrder brace is battle.js:795, inside the function that starts at 790. AI brace is at battle.js:1137 and 1141. The cost formula is data.js:329, and cp1 rounds to 70. Repair paths are at campaign_run.js:3. Admiral costs are 0/30/45/80, six of each (data.js:202-233). There are 33 base hulls plus 12 variants, 45 in total (data.js:334-346).

| # | Status | Basis | Where | Finding |
|---|---|---|---|---|
| 1 | STALE | OBSERVED (ruling) | asymmetry_synthesis.md:26-29 | "Do not add Ithar shield recharge now." The owner has since approved Ithar shield charge. |
| 2 | STALE | OBSERVED (ruling) | asymmetry_decision.md:16 | "Recommendation: change Hegemony least, as all three said." This conflicts with the ruling "Hegemony sync primary with flagship-anchor loss". |
| 3 | STALE | OBSERVED (ruling) | asymmetry_synthesis.md:30-33, 34-37 | Decisions 4 and 5 are framed as open ("Nothing here is a verdict until he rules"). The rulings are now in: Chorus feed is approved, and Deathless reanimate is a gate. The "staged" framing of Decision 4 needs to be re-read against the actual ruling. |
| 4 | WRONG (attribution) | OBSERVED | asymmetry_synthesis.md:107 | It lists "the framing of Chorus as the reference swarm" as Qwen's own contribution. Both legs are quoting the decision page here. DeepSeek leg :130: "Chorus becomes the reference swarm." Qwen leg :127: "Recommendation: adopt both; Chorus becomes the reference swarm". |
| 5 | WRONG (minor faithfulness) | OBSERVED | asymmetry_synthesis.md:22-23 | It calls Qwen's verdict a "flat 'approve all three in order'". Qwen itself split execution, Qwen leg :64: "Step 3 is higher-risk and benefits from being designed after the sim". |
| 6 | VERIFIED (correction stands) | OBSERVED | battle.js:704; data.js:187 | The avenge correction is right. Avenge fires only on "t.side==='player'" and heals the whole fleet, so it is not a kill-heal hook. That makes the "repurposing the existing avenge logic" line on the decision page (asymmetry_decision.md:20, Qwen leg :111, :132) wrong. |
| 7 | STALE (rule context) | OBSERVED | asymmetry_decision.md:22 | "strongest shields over the frailest hulls" is fine. Note that the shield colour law is now faction-coloured shields (fx3d.js:3 "shields wear their faction's colour"). No cyan claim appears in these two files. |
| 8 | VERIFIED | OBSERVED | data.js:126 | The prohibition "Deathless cannot launch squadrons" is already a data fact: deathless "sq:null". |

---

## 2. difficulty_dial_synthesis.md

Verdict: all the arithmetic corrections check out. However, the "open question" at the centre of the synthesis is already answered by the code. It also misstates DeepSeek's mechanism and adopts a sector ramp for sectors that do not exist.

Arithmetic rechecked (VERIFIED, INFERRED from the legs' own inputs):
- As written: R1 1+0.22/0.05 = 5.4. R2 1-0.18/0.05 = -2.6. R3 1-0.08/0.05 = -0.6. R3 assumes k_e = 0.05, which DeepSeek never gave.
- Corrected: g = 1.44, m = 0.64, e = 0.84. DeepSeek's 0.88 is not produced by the corrected formula; it corresponds to k_e of about 0.067.
- Hull 0.90 x damage 0.95 = 0.855.
- Qwen C_admiral: Grax 1.5x0.32 = 0.48, capped to +0.30. Maren 1.5x(-0.28) = -0.42, capped to -0.30.
- Sector 2 elite: 1.5x0.13 = 0.195, so M = 0.805.
- Ramp: 0.66 / 0.62 / 0.58, floored at 0.55.
- The unit error is real. Qwen leg :78 says "Maximum admiral spread after calibration: 0.20 percentage points."

| # | Status | Basis | Where | Finding |
|---|---|---|---|---|
| 1 | STALE (answered) | OBSERVED | battle.js:122, 132-137 | Its open question "Whether an Enemy Threat Budget ... or a 'fleet power' definition already exist" (synthesis :57) is answered by the code: fleetPower() and the genEnemyFleet budget "[0,4.2,9.5,14][s]". Sector modifiers also exist: BOSS_SCALE/BOSS_DMG by sector and BOSS_FAC by faction (battle.js:125-126). The budget only scales down: "a strong fleet never meets more" (battle.js:135). |
| 2 | WRONG (faithfulness) | OBSERVED | synthesis :13 vs DeepSeek leg :28 | It records as consensus that "Grax gets threat relief". DeepSeek's mechanism is a buff to the player's side: "scaling Grax's starting fleet strength by factor g". |
| 3 | WRONG (gap) | OBSERVED | synthesis :21-26, :40 | The merged notch table uses DeepSeek's hull/damage values. The stacking rule needs M_dial, which is Qwen's "Enemy Threat Budget multiplier" (0.80/0.90/1.00/1.15/1.30, Qwen leg :40-44). That column was dropped, so M_dial is undefined for the adopted notches. |
| 4 | WRONG (scope) | OBSERVED | campaign_run.js:311 | The synthesis adopts Qwen's ramp out to "Sector 5 major: 0.58". The run ends after sector 3: "if(RUN.sector>=3){ endRun(true)". Only T_3 = 0.66 applies. |
| 5 | STALE | OBSERVED (ruling) | synthesis :26 | The ship-count offsets are "kept within -2 to +2 against ~20-ship battles". The rulings say battle size grows over a run toward about 20, with no hard cap, and difficulty may ramp with more ships. The enemy list is also capped at 8 (battle.js:144 "list.length<8"), which would limit the +1/+2 elite escorts. |
| 6 | VERIFIED (correction 4), with evidence | OBSERVED | battle.js:846; data.js:217,218,225 | The kit trims do not map to the game. Admiral commands are "ready from round 1, once per battle", so a Voice "cooldown +1 round" has nothing to act on. Maren has no "upgrade choice" field. Also, Grax costs 0 while Maren and Voice cost 80. |
| 7 | UNCHECKED risk (name clash and baseline) | OBSERVED + INFERRED | campaign3d.js:3,102; sim3d.js:8 | An "Enemy AI: Veteran/Standard" toggle already exists, and the sims default to AI 'veteran'. The dial's notch 3 "Veteran" would clash with that name. If onboarding Fix 1 (Standard AI for new players) ships, the 70% calibration baseline moves. |
| 8 | VERIFIED (weak) | INFERRED | synthesis :38 | "bracket the same answer": Qwen's 19.5% targets a 70% win rate and DeepSeek's 16% targets 65%. They bracket one another but are aiming at different targets. |

---

## 3. onboarding_synthesis.md

Verdict: every file:line it cites resolves to the code it describes. Two conclusions drawn from those lines are wrong (the AI default mechanism and "no signal"), and one fix is already in the game.

File:line checks (OBSERVED, all correct):
- campaign_meta.js:27 is `function titleScreen(){`. Its menu has Continue run, New run, Progression and How to play.
- campaign3d.js:34 adds the "3D skirmish" and "Settings" buttons.
- battle.js:993 is aiVet.
- battle.js:390 is "MOVE_BASE ... evadeAt:3,evade:5,still:10".
- ui3d.js:635 is "objective:B.obj&&B.obj.type!=='rout'", and the first column is rout (battle.js:69 "col===0?'rout'").
- ui3d.js:410 is the firingSet loop inside onBoardClick (which starts at :400).
- ui3d.js:538 is banner('Enemy turn') inside endTurn (:535).
- ui3d.js:555 is aiStep, with no banner call before :575.
- ui3d.js:618 is ACT.pick (setupBattle, then showIntro).
- ui3d.js:619 is ACT.begin, which calls selectUnit(f).
- There are 24 admirals: 4 at data.js:201-206 plus 20 more via Object.assign.

| # | Status | Basis | Where | Finding |
|---|---|---|---|---|
| 1 | WRONG (mechanism) | OBSERVED | campaign3d.js:3; synthesis :18, :41 | The real default is `let AI_LEVEL='veteran';`. AI_LEVEL is never undefined, so the Fix 1 option "or change the aiVet default" would do nothing. The fix has to go on campaign3d.js:3, or on first-run opts. |
| 2 | WRONG | OBSERVED | ui3d.js:86; DeepSeek leg :263 | It says "enemy activations arrive with no signal beyond the camera moving". In fact the top bar switches to "Enemy activation" in alternating mode. DeepSeek's own leg says "changes ... to 'Enemy activation' in the top bar". What is missing is a banner, not every signal. |
| 3 | WRONG (redundant fix) | OBSERVED | ui3d.js:626; synthesis :57 | Fix 10 says to "surface the 1-6 arming keys in the firing tip". The 'target' tip already reads "Keys 1 to 6 pick a single weapon." Qwen leg :106 notes "the tip mentions the keys". |
| 4 | VERIFIED (resolves an unknown) | OBSERVED | campaign_meta.js:13; ui3d.js:647 | touchWords returns the text unchanged when not on mobile ("if(!(... G.mobile)...) return h"). So on PC the strip reads "Tap a gold hex to move". Under the PC-only ruling that wording is a defect. |
| 5 | STALE (in-game text) | OBSERVED | ui3d.js:625; fx3d.js:3 | The move tip reads "Cyan is shields", but shields are drawn in each faction's colour. Fix 2 rewrites this tip, and the rewritten legend must drop "cyan". |
| 6 | VERIFIED | OBSERVED | battle.js:458 | motionHit gives "+R.still" when hexMoved===0 and "-R.evade" at 3+ hexes, and returns 0 when braced. It surfaces through motionNote (ui3d.js:451). |
| 7 | VERIFIED | OBSERVED | ui3d.js:630-636 | The start tip's condition is "start:true", and ACT.begin selects a ship first. So the ordering wart is real. Tips are picked by TIPS.find in array order, so they are prioritised and gated rather than fully unsequenced. |
| 8 | VERIFIED | OBSERVED | ui3d.js:13 | Alternating is the default ("alt:true"). The Classic banner path is secondary, as claimed. |

---

## 4. kit_spec_synthesis.md

Verdict: corrections 1, 2, 4, 5, 6 and 8 are VERIFIED, and 7 has correct arithmetic. Correction 3 miscounts the singleton classes. The cyan gate consensus is stale. The Qwen homoglyph claim cannot be reproduced in the filed leg.

| # | Status | Basis | Where | Finding |
|---|---|---|---|---|
| 1 | VERIFIED (corr. 1) | OBSERVED | DeepSeek leg :374-455 (parsed) | The JSON parses to 14 socketRequests, 15 modules and 6 stationOverrides. The leg's text claims "fifteen socket requests" (:457). |
| 2 | VERIFIED (corr. 2, 8) | OBSERVED | DeepSeek leg :101, :418, :431 | Capital gun_deck is "6-12", but the example has 4 gun_decks. bridge.0 is referenced twice, by keep.v1 and shield.emitter.v1. |
| 3 | WRONG (corr. 3) | OBSERVED | data.js cls tally | It says "Twelve classes, five singletons." There are 12 classes and 6 singletons: Ark, Battle-barge (c_boss data.js:82), Bio-titan, Dreadnought, Super-dreadnought and Tomb-ark. |
| 4 | VERIFIED (corr. 4, 5, 6) | OBSERVED | ships3d.js:2-8, :717, :787, :790 | FAC3D keys are hull/dark/trim/win/eng/bolt/beam/shield/tip. The code has "The old 0.3 self-light is gone" and "G.kitFill||0", and AI_HULL_YAW handles two side-on meshes. No useRightHandedSystem appears anywhere. There are 36 hull .json meshes in hulls/. |
| 5 | INFERRED caveat (corr. 4) | OBSERVED | data.js:111 | FAC3D has no glow, but FACTIONS has one ("glow:'#ff7a2a'"). The open "glow mapping" decision should take this existing field into account. |
| 6 | STALE | OBSERVED (ruling) + code | synthesis :12; fx3d.js:3 | "Cyan is a baked-result gate, not a style note ... Adopt both layers." The cyan-only rule is retired and shields are faction-coloured. The same stale premise is in Qwen leg :181 "CYAN_RESERVED_FOR_SHIELDS" and DeepSeek :457 "the only cyan-legal module". |
| 7 | VERIFIED arithmetic (corr. 7); Pack J UNCHECKABLE | OBSERVED | DeepSeek leg :1042 | 1.32 GB / 20 x 0.8 = 52.8 MB, and Qwen's ~66 MB is the same figure without the 0.8. The Pack J provenance claim was not checked. |
| 8 | UNCHECKABLE | OBSERVED | qwen kit leg (whole file) | It claims "a homoglyph defect (Cyrillic letters in an identifier)". The filed leg contains no Cyrillic. Its only non-ASCII characters are ellipsis, en dash, degree sign, plus-minus and arrow. The "stray quote" claim is VERIFIED: Qwen :46 has `"maximum": 1.0" }`, and that is where the parse fails. |

---

## 5. torpedo_boarding_synthesis.md

Verdict: the code description is accurate, with one line range a little short. The capture framing is stale given the ruling, and two characterisations of DeepSeek are unfair to it.

Line numbers (OBSERVED):
- battle.js:652 is boardTargets. The adjacency check `hdist(u,t)===1` is on :653.
- boardUnit runs from battle.js:667 to its closing brace at :682, not 667-679.
- battle.js:554 is systemDamage. The engine case is cumulative (st.engine+1, capped at speed-1). Shields and weapons go offline for 2 turns, and st.fire is set to 2.
- Crew: crewMax is set at battle.js:117, and damage reduces crew at battle.js:545 (x0.35).
- Weapons (data.js:8, :15, :20): torp is dmg 42, r6, acc 64, pierce .3, crit 15, cd 2, evMult 2. htorp is r6. startorp is r5.
- Flak is labelled "Point defense" (data.js:30).

| # | Status | Basis | Where | Finding |
|---|---|---|---|---|
| 1 | STALE | OBSERVED (ruling) | synthesis :29, :59, :66 | "the question for Ryan is not whether capture exists but whether to keep it". The owner has ruled: strip, ransom or add, with auto-scrap when the fleet is full. For context, the code today only adds captured ships: campaign3d.js:81 does "RUN.fleet.push(sh)" with no strip/ransom choice and no fleet limit. |
| 2 | VERIFIED, now settled | OBSERVED (ruling) | synthesis :31 | "keep temporary as the default" matches the "crits soft and temporary" ruling. Qwen's permanent tier (Qwen leg :49 "system is destroyed for the rest of the battle") should be rejected. |
| 3 | WRONG (minor line range) | OBSERVED | battle.js:680-682 | The cited range "boardUnit (battle.js:667-679)" leaves out the 50% sabotage roll at :680 and the log at :681. |
| 4 | WRONG (answered) | OBSERVED | battle.js:669, :371 | It says the "flag source in code is not established". The source is boardUnit itself, which sets "u.boarded=true; u.repel=true" on the boarder, and the flag is cleared at :371 ("u.repel=false"). |
| 5 | WRONG (faithfulness) | OBSERVED | DeepSeek leg :48, :69 | It says "DeepSeek used fuel; Qwen used fixed speed". DeepSeek also moves torpedoes 3 hexes a turn: "5 turns x 3 hexes = 15 hexes". On PD, DeepSeek wrote "If the repo already has ... point-defense rating, map PD to it", which means it had already proposed the flak reuse. |
| 6 | VERIFIED (incomplete) | OBSERVED | data.js:20; synthesis :56 | "current 6 versus proposed 10": startorp is r5, and DeepSeek's effective range of 15 is never mentioned. |
| 7 | STALE premise in both legs | OBSERVED (ruling) | DeepSeek leg :10; Qwen leg :13 | Both quote "around 20 ships" as a fixed scale. Under the ruling, battle size grows toward about 20 by the end of a run. |
| 8 | VERIFIED | OBSERVED | battle.js:671 | Repel works as described: defender multiplier "t.repel?2.25:1.5", with BOARD_MULT applied on both sides and CREW_MULT applied through crewMax. |

---

## Not checked
- Screening notes in the "goal hidden_files folder", which the syntheses cite. Not located.
- Pack J's provenance for the 1.32 GB figure.
- The Qwen kit leg's raw transcript, which is where the homoglyph might be.
- The full text of the DeepSeek onboarding (715 lines) and DeepSeek kit (1136 lines) legs. I only read the passages the syntheses cite.
- Roster gating mechanism (asymmetry).
- The "How to play" screen content.
- Whether reanimate appears in telemetry.
- The exact wording of the "Deathless reanimate gate" ruling. Finding 1.3 assumes it settles Decision 5.
- Rendering checks: shield colours in game, and "Tap" wording on PC. These were checked in code only.
