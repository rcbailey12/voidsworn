# The campaign oracle, pinned

Nov 8 2026, issue 27 (progression step 11): re-copied campaign_run.js and
campaign_meta.js for per run XP earnings by line in the F1 play log. Each
finished run writes one run_xp event: the flown line's payout plus each
benched line of the same faction with its shadow share. No Nemesis counter
was added; the play log report reads the #122 run_end record. Re-exported
campaign tables; their checksums are unchanged.

Nov 8 2026, issue 24: re-copied campaign_run.js and campaign_meta.js for the
Nemesis teaching loop (the lost meeting's lesson recorded per commander with
its taught flag, the run debrief's Nemesis lesson row, and the map and meeting
line that name the once-per-sector meeting as certain). Re-exported campaign
tables; their checksums are unchanged.

Nov 8 2026, issue 246: re-copied core.js for the loss back-fill. A profile
saved before the Heat gate has no losses count; migrateMeta counts its
run_end entries that were neither a win nor abandoned, writes the count only
when above 0 so old fixtures stay unchanged, and Heat opens on the next load.
Re-exported campaign tables; their checksums are unchanged.

Nov 8 2026, issue 26: re-copied campaign_meta.js for Heat after the first loss
and the R63 Heat XP payout. Re-exported both table sets; their checksums are
unchanged. The R69 playtest default stays on.

Nov 4 2026, issue 134 (R88): re-copied battle.js, data.js and ui3d.js where held.
Player carriers replace lost wings automatically, opening wings use the shared
squadron AI, and launch controls and teaching text are removed. Stats unchanged.
Re-exported both table sets; goldens regenerate from these pinned sources.

Nov 3 2026, issue 22: re-copied campaign_meta.js and campaign_run.js for
saved per-run core sync progress, tier announcements and debrief inheritance.
Re-exported both table sets; their checksums are unchanged. No battle rule
or R69 playtest default changed.

Nov 3 2026, issue 110: re-copied data.js, battle.js, campaign_run.js and
campaign3d.js for all five beat 3 rewards, free core offers, and consumption
of next-battle modifiers on entry. Re-exported campaign tables.

Nov 3 2026, issue 55: re-copied data.js, campaign_run.js and campaign_meta.js
for the six approved beat 3 decisions, spotlights and debrief learning lines.
Mending Throng uses the name required by the issue. Re-exported campaign tables.

Nov 3 2026, issue 21: re-copied campaign_meta.js for the paid inheritance
receipt and debrief links. Campaign and rules tables were re-exported and
keep their existing checksums. No combat rule or playtest default changed.

Nov 2 2026, issue 20: re-copied core.js and campaign_meta.js for per-line
shadow XP, debrief heirs and capped XP routing. Re-exported campaign tables.
The R69 playtest default stays on in the Godot UI.

Nov 2 2026, issue 18: re-copied core.js from this checkout for the shared
FX_CAPS table and final-total ceilings in sumFx. Re-exported campaign tables.

Nov 2 2026, onboarding follow-up: re-copied core.js, battle.js, campaign3d.js
and campaign_meta.js from this checkout. RUN.teachingGate controls teaching
factions, the first map preview and battle overrides. Profile adapters enable
it only with tips on and fewer than two finished runs. Bots and parity default
off, including teaching-history bookkeeping. Re-exported tables are unchanged.

Nov 2 2026, uncommitted onboarding task: re-copied `core.js`, `battle.js`,
`campaign3d.js` and `ui3d.js` from this checkout. The first two teaching fights,
their preview faction, open edge feature, arrival schedule and approved TIPS
copy are included. Campaign tables were re-exported. No balance tables changed.

These are the game's JS files, copied unchanged, that the campaign parity test runs against:

- All seven files from main **cf278dd** (Nov 1 2026: stream B step 14, the Daybreak at speed 2 and the boss objective table, plus R1's follow-ups: admiral ownership, the Legacy tab, display strings). Before that **e3bff1e** (Nov 1 2026: stream B step 13, the R1 rules fix batch 53531b2 plus the Hullbreaker blurb string; port_notes step 13). Before that **8e81d75** (Nov 1 2026: stream B step 9b, the RAMP sector 2 budget in battle.js: grow 1.2/1.24, thin .67/.62, boss escorts .5/.6; the last rules change). Before that **f770e06** (Oct 31 2026: stream B step 12, the rename map sections 16 and 17 strings, on top of step 11, the campaign battle-start fix (5a99602), and step 10, the lore round 8 strings, R59; display strings only, no rule or number changed; it also carries steps 5 to 9: pass 3 tuning, the admiral band, skirmish lists and the RAMP easing). Before that: d8b47c6 (steps 0 to 4).
- No local edits: the `campaign3d.js` line 56 comment that swallowed `prepBattle()` (patched here until now) is fixed at the source in 5a99602.
- `ui3d.js` is presentation; only two of its tables are evaluated: `FNAMES` (ship names for non-Voidsworn fleets, which the browser's `shipName` uses) and `TIPS` (the battle onboarding tips, exported for the battle UI).
- History: b71c8d7 / 29d431c (the first port), then c7b1a78, then c88567c, then d8b47c6, then f770e06 (strings 90aaf85, the battle-start fix 5a99602, strings step 12), then 8e81d75 (RAMP step 9b), then e3bff1e (step 13, R1).

The parity harness and the campaign table exporter read these files, not the live ones at the repo root, so stream B can change the JS rules during the sprint without breaking the campaign port's golden test.

**Catching up:** when stream B changes a campaign rule, port the change to `godot/campaign/`, re-copy the six files from the new commit, run `node godot/campaign/test/node/export_campaign.js` to refresh `godot/campaign/data/campaign_tables.json`, run the parity test, and update the commit numbers above.

Nov 3 2026, issue 88: re-copied data.js and ui3d.js for the text truth pass (one boon text corrected, two tutorial card texts corrected). No rules or numbers changed. Re-exported tables.

Nov 8 2026, issue 121: re-copied data.js, core.js, battle.js and campaign_run.js (the run clock RUN.nemClock and RUN.nemStrike, per-commander adaptation, lessons and NEM_VOICE). Re-exported tables.

Nov 8 2026, issue 122: re-copied core.js, campaign_meta.js and campaign_run.js (the run escape counter RUN.nemEscapes, the Chorus compounding counter telemetry, nemSignature tagged by the commander who acted, the Nemesis panel data nemPanelData, the run_end Nemesis record, the clock-full message through nemSay). Re-exported campaign tables; their checksum is unchanged (no data.js change).
