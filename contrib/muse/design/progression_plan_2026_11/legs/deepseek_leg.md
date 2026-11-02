1. Headline

Build the effect-pool cap first, then the Glasswrights/Saro tree as the one playable progression slice, then rebuild the debrief so every death visibly names what the next run inherits. The player should feel the run-4 leak close: a loss buys a tree pick, a core-sync step, a Nemesis lesson, or a story change, not only a currency total. The biggest risk is doing the tree before the debrief: a beautiful tree the player cannot see at the moment he decides whether to run again will not fix the loop.

2. The player loop on one page

A run starts at the haven. You pick an admiral as an early style choice, not a shop purchase. That admiral brings a Command, a starting fleet shape, and a lineage: the XP and skill choices that admiral's line carries forward. You see the sector map. Event nodes hide their reward labels; fights and havens always offer a free exit. You choose a route, fight hex fleet battles, pick protocols that feed the Lattice cores, and earn Heat XP for the admiral you flew plus a smaller faction shadow pool. Heat is the pressure you choose: it pays XP, but it also makes the run harder. A Nemesis hunter meets you once per sector; the meeting is mandatory, the sector clock only makes it come sooner. Its adaptations are hidden during the run and shown on the debrief. Losing is normal. Run 1 should be near impossible. A high loss rate is expected, not a failure.

A run ends in victory or loss. The debrief is the inheritance screen. It shows what the next generation carries: doctrine bought, lineage XP, the next tree pick in reach, the core-sync tier, what the Nemesis learned, and the story line taken. A victory also ends a campaign arc and starts the next generation with a new admiral line; it does not erase doctrine. A loss does not erase progress: the run's XP, renown, and story learning carry into the next run. A run's only dead end is the moment the player cannot name what the next run will change.

Between runs, five tracks carry over, in player words.

Doctrine is the faction's unlocked battle rules and protocols, bought with renown; renown is also the respec currency.

Lineage is the admiral's line: XP, the four fixed trunk perks, then branch picks and a capstone, then capstone-adjacent skill choices at later tiers.

Core sync is the Lattice clock: protocols tick favour, tier-ups land at 4, 12, and 25 protocols per core, and a debrief line announces the next tier.

The Nemesis is the hunter's memory: a lost meeting still teaches a weakness on the debrief; a win or intel event removes one.

Story is the faction's learning line and admiral spotlights, taken one beat at a time.

You start the next run because the debrief showed you a specific thing you just bought: a new tree skill, a new protocol, a new Nemesis weakness, or a story beat you want to finish. A run that only adds currency, with no new pick, tier, lesson, or beat in reach, is the leak to fix first.

3. Reconciled design

1. Loop repairs: stack all three in the chair's order. Build the debrief screen first, then the Heat gate after the first loss, then the content ladder that changes world conditions and Nemesis behaviour. R62 wants a high loss rate and a near-impossible run 1; the screen is what makes a loss legible, the gate starts the difficulty climb while the first win is still ahead, and content keeps later runs from being only numbers. Cost: more build steps and a sequencing dependency. The Heat gate also changes who can earn the ruled +2 admiral / +1 shadow XP and when, so Q13 overflow routing must be tested with the gate.

2. Mastery pooling: keep it per admiral, not per faction. The lineage fiction and the tree design both assume an admiral's line owns its progress. R62's generation reset says only lineage survives a generation change, which is incompatible with pooling by faction. Use shadow XP at 25 percent for benched admirals of the flown faction, and the named-heir debrief choice at double shadow rate. Cost: slower catch-up than faction pooling, and the 25 percent is a flagged tuning guess; telemetry must check it. Do not pool per faction.

3. Elite and boss double-count: keep it as intentional weighting, and lock it with a test. No ruling authorizes removing it, and keeping it preserves the researched traces. The cost is that elite and boss runs stay the fastest mastery path, so the pacing traces already researched stay valid but also stay fast. Do not change the weighting without a new ruling and new traces.

4. Dead admiral shop: schedule cleanup, not a shop. Admirals are ruled to be early style choices. Remove the purchase handlers at campaign_meta.js:143-144, replace the locked-card text with a style-choice line, and delete or gate the unreachable toggle. Cost: a small cleanup task and a text change; leaving it risks players hunting for a shop that does not exist.

5. Core sync: make it a clock and a debrief line, not a spendable currency. It is the third track beside doctrine and lineage. R62's inheritance fiction needs it announced where the player decides to run again, and no ruling authorizes a fourth currency. Cost: a debrief line and a meter; spending would reopen the closed economy (R63) and add a new sink.

6. Playtest switch: earliest technical flip after Step 7; recommended flip after Step 16. After the tree slice, respec, mastery lock, shadow XP, debrief rebuild, and core-sync line pass their tests, owner could flip R69 off and see normal locked progression with a readable debrief. Do not flip it before the debrief rebuild, or the owner will see locked progression without the screen that explains it. The recommended flip waits for telemetry and Nemesis measurement, so the owner sees pacing and Nemesis rates, not only locked trees.

Further flags: the locked admiral cards pointing at a nonexistent shop contradict the ruled style-choice design. The debrief in the shipped flow does not yet name inheritance, so it cannot close the run-4 leak. The Heat gate in the shipped flow is not yet tied to first loss, so Heat XP is available too early. No other contradictions with shipped code or rulings were found in the pack.

4. Build order

Step 1 — Effect-pool cap at sumFx. Files: core.js:171, core.js:217, new cap table (inference: data/effect_caps). Adds a data-driven per-effect cap at sumFx, applied once per battle, with a cap table the designer can tune. Test: a battle with stacked effects does not exceed the cap. Owner sees the cap as a single number, not a code change.

Step 2 — Glasswrights Saro tree vertical slice. Files: new Glasswrights tree data seeded by Saro's worked tree (inference: data/trees/glasswrights_saro), new tree screen scene/script, campaign_meta save fields. Adds Saro's Branch A plus capstone at 75/110/160/230 XP, one pick per tier, unchosen skill locks, and persistence into a run. Test: a fresh save can spend XP on Saro through Branch A and the capstone, then see the chosen effects in a run. Owner sees Saro's tree with real picks and locked alternatives.

Step 3 — Between-run respec pricing. Files: tree screen, campaign_meta save fields. Adds respec only between runs, first line respec 25 renown, +10 per additional line, capped at 75 renown. Test: respec is blocked mid-run, allowed between runs, and priced 25/35/45 up to 75. Owner sees respec priced on the tree screen.

Step 4 — Mastery elite/boss weighting lock. Files: mastery XP function (inference: campaign_meta), test fixture. Adds an explicit "elite/boss double-count" flag and a test that locks the researched traces. Test: a run-5 and run-10 trace match the researched values with double-count on. Owner sees no player-visible change, only a locked rule.

Step 5 — Per-admiral shadow XP and heir naming. Files: mastery/campaign_meta save fields, debrief choice hook. Adds 25 percent shadow XP for benched admirals of the flown faction; a named heir earns double shadow XP while benched. Test: flying Saro advances a benched Glasswright at 25 percent, and heir naming doubles that shadow rate. Owner sees benched admirals progress on the debrief.

Step 6 — Debrief inheritance rebuild. Files: post-run summary screen, campaign_run save read. Adds a "what you carry" panel naming renown, doctrine, lineage XP, next tree pick, core-sync tier, Nemesis lesson, and story beat. Test: a lost run's debrief names at least one inherited item in each track. Owner sees the debrief as the inheritance screen.

Step 7 — Core-sync debrief line. Files: debrief screen, core-sync data. Adds core-sync meter and next-tier line to the inheritance panel. Test: picking protocols moves the meter and the debrief names the next tier. Owner sees sync progress on the debrief.

Step 8 — Heat gate after first loss. Files: gate/unlock logic, Heat payout path. Adds Heat availability after the first loss and preserves Q13 +2 admiral / +1 shadow routing with overflow in shadow XP. Test: a fresh save has no Heat before first loss; after first loss Heat pays the ruled XP. Owner sees Heat open after the first loss, not before.

Step 9 — Nemesis clash-check verification. Files: campaign_run.js:293 (nemAdapt), test fixture. Adds a verification test that an adaptation may only fire on a clash, not on any battle. Test: a non-clash battle does not trigger an adaptation; a clash does. Owner sees Nemesis adaptations only after a clash.

Step 10 — Nemesis loss-debrief teaching. Files: debrief screen, Nemesis data. Adds Q5's guaranteed weakness teaching on a lost meeting. Test: a lost Nemesis meeting always teaches a weakness on the debrief. Owner sees a weakness lesson after every lost meeting.

Step 11 — Nemesis meeting fiction and UI language. Files: nemNodeIs, meeting UI. Adds "mandatory once per sector; the clock only makes it sooner" language and a meeting banner. Test: a sector without a meeting shows the banner; a sector clock does not skip the meeting. Owner sees the meeting as mandatory, not optional.

Step 12 — Dead admiral-shop cleanup. Files: campaign_meta.js:143-144, locked-card text UI, unreachable toggle. Adds removal of purchase handlers, replacement locked-card text, and gating of the toggle. Test: no purchase handler fires for a locked admiral; the card shows style-choice text. Owner sees no shop, only style choices.

Step 13 — Story beat 3 core decisions. Files: story data and story screen. Adds beat 3's core decisions and records the outcome. Test: beat 3 presents its decisions and the outcome is recorded. Owner sees beat 3's decisions in the story flow.

Step 14 — Story learning lines and admiral spotlights. Files: story data, tree/debrief display. Adds faction learning lines and admiral spotlights in the form the pack describes. Test: each faction's learning line and each admiral's spotlight appear in the story flow. Owner sees learning lines and spotlights.

Step 15 — Telemetry F1 log extension. Files: telemetry implementation, campaign save. Adds the per-battle log (ship, how picked, time to first shot, kills, losses) and per-run totals (score, renown, doctrine, lineage, sync, Nemesis). Test: a run's log contains per-battle and per-run totals. Owner sees the log in the F1 debug view.

Step 16 — Nemesis Q6 measurement. Files: telemetry reader/report. Adds escape and compounding rate reports before any caps. Test: the report computes escape and compounding rates from the log. Owner sees Nemesis rates before any cap is set.

Step 17 — Playtest-switch readiness checklist. Files: R69 switch UI. Adds a checklist that names the passing tests before the switch is flipped. Test: the switch cannot be flipped until the checklist passes. Owner sees the checklist, not just a toggle.

5. Art and sound needs

Step 2: Saro portrait; Branch A/B/C icons; locked-skill icon; capstone badge; tree-screen frame; node-pick sound.

Step 3: respec icon; renown cost badge; respec confirmation sound.

Step 5: heir crest; benched-admiral shadow-XP icon; heir-naming sound.

Step 6: inheritance panel frame; doctrine/lineage/core-sync/Nemesis/story track icons; debrief tally sound.

Step 7: core-sync meter; Lattice core tier icon; sync tick cue.

Step 8: Heat status icon; Heat-open cue.

Step 9: Nemesis adaptation silhouette; weakness-reveal icon.

Step 10: weakness-reveal sting; debrief lesson banner.

Step 11: Nemesis meeting banner; hunter portrait; sector-clock icon; meeting sting.

Step 12: replacement locked-card text style; no shop icon.

Step 13: beat 3 illustration; story-choice frame.

Step 14: faction learning-line frame; admiral spotlight portraits.

Step 15: debug telemetry overlay (minimal).

Step 16: no new art required.

6. Owner questions

Q1. Should elite and boss fights keep paying double mastery XP?

A. Keep double XP — dangerous fights stay the fast way to deepen a line; current pacing traces stay as researched.
Recommended: A.
B. Remove double XP — mastery slows everywhere; the run-5 and run-10 traces move later.
C. Decide after telemetry — no visible change now; the question returns after Step 16.

Q2. Should core sync be spendable or only a clock shown on the debrief?

A. Clock only — you see sync progress on the debrief; no new currency to manage.
Recommended: A.
B. Spendable — you can trade sync for bonuses; adds a fourth currency and reopens the closed economy (R63).
C. Hide it — less screen clutter; the run-5 decision loses its third progression signal.

Q3. When should the "everything unlocked" playtest switch first be allowed off?

A. After Step 7 — you see locked progression with tree, respec, debrief, and sync visible; telemetry is not yet in.
B. After Step 16 — you see the same but with Nemesis measurement and pacing checks passed.
Recommended: B.
C. Not in this plan — keep everything unlocked until a later phase; no player-visible change now.

Q4. How should the three loop repairs land?

A. Stack screen, then Heat gate, then content — each death first becomes legible, then the climb starts, then the world changes. Recommended: A.
B. Screen only — fastest to build; later runs may still feel like only numbers.
C. Gate first — difficulty opens earlier; losses may be less legible without the debrief.

Q5. What should a locked admiral card say now that admirals are style choices, not purchases?

A. "Choose at run start; lineage deepens this style" — clear, no dead shop. Recommended: A.
B. "Unlocked by story" — suggests story gating that does not exist yet.
C. Leave old shop text — players will look for a shop that does not exist.

7. Not checked

I did not read the shipped code beyond the pack's anchors. I took on trust the mastery XP figures (about 43 winning, 10 lost), the 25 percent shadow-XP guess, the tree thresholds, the 885 remaining renown sinks, and the telemetry/story pack descriptions. I did not verify whether nemAdapt at campaign_run.js:293 actually implements Q4; Step 9 treats that as a test to write, not a known fact. New file paths in the build order are my inference; the pack only anchors core.js:171, core.js:217, campaign_meta.js:143-144, campaign_run.js:293, and nemNodeIs. I did not audit existing art or audio, so the art list is a requirement list, not a gap audit. I did not reopen economy numbers (R63) or soften run 1 (R62).
