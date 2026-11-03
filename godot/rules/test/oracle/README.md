# The rules oracle, pinned

Nov 3 2026, issue 110: re-copied data.js and battle.js for the beat 3
flagship and fleet damage modifiers and round 1 sync shutdown. Re-exported
rules tables; scenarios s51 to s54 cover the one-battle modifiers.

Nov 3 2026, issue 55: re-copied data.js for the approved story beat 3 table
and Mending Throng display name. Re-exported rules tables. Combat rules unchanged.

Nov 3 2026, issue 21: inheritance is in campaign_meta.js, held by the campaign
oracle only. Rules files are unchanged. Re-exported rules tables retain the
same checksum; the combat oracle needs no new source copy.

Nov 2 2026, issue 20: re-copied core.js for the saved heirs and shadowPool
profile fields. Re-exported rules tables; combat rules are unchanged.

Nov 2 2026, issue 18: re-copied core.js from this checkout for the shared
FX_CAPS table and final-total ceilings in sumFx. Re-exported rules tables.

Nov 2 2026, onboarding follow-up: re-copied core.js and battle.js from this
checkout. Teaching overrides now require cfg/RUN.teachingGate. Ordinary bot
and parity callers default off; s49 and s50 explicitly enable the gate.
Re-exported tables retain the same checksum and balance values.

Nov 2 2026, uncommitted onboarding task: re-copied `core.js` and `battle.js`
from this checkout. Teaching fight 1 uses an open field with one edge feature
and no mid-battle arrival; fight 2 schedules an enemy arrival. Scenarios s49
and s50 cover these branches. Budget, hull and weapon tables are unchanged.

These are the game's `data.js`, `core.js` and `battle.js`, copied unchanged from main cf278dd (Nov 1: stream B step 14, the Daybreak at speed 2 and the boss objective table, on top of step 13, the R1 rules fix batch 53531b2, and the R1 display-string follow-ups e3bff1e, d039a7a, d72d454; before that 8e81d75, steps 0 to 12 and 9b), plus:

- `fnames.js`, the `FNAMES` table from `ui3d.js` (lore round 8 ship names; Nov 1 R1 follow-up: the retired Hullbreaker name Last Laugh became Cold Trail, as in ui3d.js) (the browser defines it and `core.js` shipName reads it);
- `campaign_hooks.js`, `nemAdaptName` from `campaign_run.js` at e80a6a0 (unchanged since d8b47c6) (battle.js calls it when it exists, and the browser always loads it).

The parity harness runs these files, not the live ones at the repo root, so stream B can change the JS rules without breaking the port's golden test.

History: b71c8d7 (Oct 25, the sprint start), c7b1a78 (Oct 26), d8b47c6 (Oct 27), 6b1571e, 59f13a5 and bcc7e47 (Oct 27, data.js only), cb55ec9 (Oct 27, pass 3 tuning), e80a6a0 (Oct 31: step 9 RAMP, strings steps 10 and 12), 8e81d75 (Nov 1: step 9b RAMP, battle.js only), cf278dd (Nov 1: step 14, ascendant sp 2 and BOSS_ENC), e3bff1e (Nov 1: step 13, the R1 batch: cfg.noStar, the veteran mid-move brace, gsentry, boon and campaign fixes; port_notes step 13).

**Catching up:** when stream B changes the rules (`contrib/opus/compute/port_notes.md` lists each step), the change is ported to `godot/rules/` with a new golden scenario, then these files are re-copied from the new commit and this note is updated.

Nov 3 2026, issue 88: re-copied data.js and ui3d.js for the text truth pass (one boon text corrected, two tutorial card texts corrected). No rules or numbers changed. Re-exported tables.
