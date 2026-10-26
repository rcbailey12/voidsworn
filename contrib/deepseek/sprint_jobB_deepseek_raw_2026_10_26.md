# REVIEW: Job B, stream B commit beae728b (B-18, B-19, faction identity telemetry)

Trigger commit verified on GitHub main: beae728b315ad69a2ca6721c5818d012edfef60c, "Stream B: B-18 and B-19 fixes, faction identity telemetry in the sim", Oct 26 2026 06:58 CDT, by rcbailey12 and claude. Two files changed: battle.js (+2 -1), sim3d.js (+28 -14). All three code sites from the pack caveat exist in the current code: killUnit in battle.js, the roundStart helper in sim3d.js, and the FID print in the fmatrix sim.

## RANKED FINDINGS (most dangerous first)

### 1. Balance numbers are stale after B-19; no sim was re-run and none is filed. [OBSERVED]

What: B-19 changes turn-start death ordering in every sim battle loop via the new roundStart helper (sim3d.js:6), applied in sim, match, fuzz, bossCheck, bossMatrix, archMatrix, fMatrix, rsFight and chainSim. Ordering changes can move sim results even when the rules text is unchanged. The newest sim output in contrib/opus/compute/ predates the trigger commit: the b2/ folder was committed Oct 25 4:57 PM CDT and raw/ plus the CSVs Oct 24-25, while beae728b landed Oct 26 6:58 AM CDT. No FID output and no post-B-19 win rates are filed anywhere I could find.

Where: sim3d.js:6; contrib/opus/compute/ (directory listing with commit dates).

Plan item: B3 exit ("No faction runs away with win rates") and pack section 5 ("If no post-B-19 sim output exists, flag the balance numbers as stale, not wrong").

Flag: admiral band 50-90% is UNSURE. The commit message gives no win rates, and the only band numbers on record (57-89% at 96 runs per admiral, FINDINGS S6, per the pack) predate B-19.

Check to close: re-run fmatrix and bossmatrix on the post-beae728b code, file the output including the FID line in contrib/opus/compute/, and diff win rates against the B0 baseline.

### 2. roundStart does not match the game it cites: the enemy tick starts before the player tick is awaited, and B.over is not re-checked. [OBSERVED]

What: sim3d.js:6 reads `async function roundStart(){ const d1=startSideTurn('player'), d2=B.over?null:startSideTurn('enemy'); if(d1) await d1; if(d2) await d2; }`. Its comment (sim3d.js:5) says "player ticks, then enemy ticks unless the battle ended, each awaited". But d2, the enemy tick, is launched before d1 is awaited, and B.over is checked only synchronously, before the player deaths resolve. The game (ui3d.js, function nextRound) does `const dq2=startSideTurn('player'); if(dq2) await dq2; if(!B) return; if(B.over){ B.busy=false; bRefresh(); return; }`: it awaits the player tick first and returns early if the battle ended, so the enemy tick never starts. In the sim, if the player's turn-start deaths (fire, acid, the dead star) end the battle, the enemy tick has already applied its damage and queued its deaths. The final board state and the FID loss and damage stats can then diverge from the game in exactly the edge case B-19 was meant to align.

Where: sim3d.js:5 (comment), sim3d.js:6 (roundStart); ui3d.js nextRound (game reference, observed).

Plan item: B-19 ("the way the game does"). The code breaks the stated fidelity, and its comment misdescribes the code.

Check to close: make roundStart sequential (await the player tick, return if B.over, then start and await the enemy tick), then re-run the sims.

### 3. The FID faction-mechanic counters have no producer: B.fstat is never set, so sync, feed, charge and torpedo identity never reach the FID line. [OBSERVED]

What: sim3d.js:15 merges `B.fstat` into the per-faction FID record, and sim3d.js:16-17 reports feed, charge, sync, syncShots, torpLaunch, torpHit, torpDodge and revive per battle. But nothing in the sim's scope sets B.fstat: I searched data.js, core.js and battle.js for "fstat" and found zero matches in all three; sim3d.js only reads it (`B.fstat||{}`). So the merge always reads an empty object, those counters stay 0, and fidReport's `if(F[k])` never prints them. The FID line measures the generic metrics (range, damage split, regen, losses, dealt) but cannot show the faction definers from the Oct 24 rulings: Hegemony synchronized fire, Chorus feed, Ithar shield charge, torpedoes.

Where: sim3d.js:9 (fidOf initializes the keys), sim3d.js:15 (fstat merge), sim3d.js:16-17 (report).

Plan item: B3 exit ("the sim shows each faction playing differently") and the faction identity rulings (synchronized fire PRIMARY for Hegemony, feed for Chorus, shield charge for Ithar). The telemetry half that would evidence the definers is dead.

Check to close: add B.fstat producers in battle.js (increment per faction on synchronized fire, feed heals, shield charge, torpedo launch/hit/dodge, revives), re-run fmatrix, and confirm the FID line shows non-zero mechanic counts.

### 4. The commit message says "an FID line per faction"; the code prints one FID line. [OBSERVED]

What: sim3d.js:412 runs `console.log('FID '+JSON.stringify(fidReport()))`, and fidReport() returns a single object keyed by faction. So fmatrix prints one FID line containing per-faction entries, not one line per faction. The pack's caveat asked to verify "the FID lines in the fmatrix sim"; there is exactly one.

Where: sim3d.js:412.

Plan item: none broken. Wording nit on the commit message.

Check to close: none needed.

### 5. The Voidsworn carriers conflict is on record but decided; no stream B change touches it. [OBSERVED]

What: contrib/opus/FINDINGS.md entry F22 records "Voidsworn carrier ban (price ladder)" as a Conflict ("Breaks Commodore Ashgrove, carrier doctrine, starts with a Reliquary (data.js:204)") with status DECIDED: carriers stay, priced up. The approved go-forward plan (contrib/opus/go-forward-plan.md) says "Voidsworn keep carriers, at a price premium. The proposed carrier ban would break Commodore Ashgrove, a Voidsworn admiral whose whole kit is carriers (data.js:204)." data.js confirms: ashgrove is Commodore Sera Ashgrove, fac voidsworn, "Carrier doctrine", starting fleet includes 'reliquary', and HULLS lists reliquary as a Reliquary-class carrier, fac voidsworn. The trigger commit changes only battle.js and sim3d.js, so no stream B change follows the loss list over the plan. The conflict text exists on main but is marked DECIDED in favor of the plan, so there is no live contradiction for stream B to act on.

Where: contrib/opus/FINDINGS.md (F22), contrib/opus/go-forward-plan.md, data.js (ashgrove entry, HULLS reliquary).

Plan item and ruling: B3.1 and the faction identity rulings ("The plan is the approved record"). Upheld.

Check to close: none for Job B; the registry already records the decision.

## PER-ITEM VERDICTS

### B-18: Consistent with the plan.

The bug described in the commit message is real. The old battle.js line 720 placed `if(!live()){ if(B===b0&&!B.over) try{ checkEnd(); }catch(e){} return; }` after `//` on the same line, so it was comment text and never executed. The new battle.js:721 puts the check on its own line and it now runs, restoring the intended v45 behavior ("epoch check like every other await, so a stalled battle never sees this explosion's aftermath"). The "no change in the sim, where nothing stalls" claim is plausible from the code: liveFrom (battle.js) checks that B is the same object and the epoch is unchanged, and in the sim startBattle runs only between battles while every death promise is awaited inside the battle (via roundStart and startSideTurn), so the guard is a no-op there. [INFERRED from the sequential sim loop structure; not exhaustively proven.] No ruling is broken and no B3/B4 item is affected. This restores a guard; it is not a rules change.

### B-19: Flagged (the improvement is real, but two problems stand).

The improvement is real: turn-start deaths from fire, acid, the dead star and station guns are queued by queueDeath (battle.js), which starts killUnit at once and hands back a promise, and startSideTurn returns a promise the caller awaits ("the caller awaits the returned promise so their deaths finish in order", battle.js). All round-based sim loops now await these via roundStart, and the match !alt branch's enemy tick gained its missing await; the alternating-turn loops already awaited each tick. This is harness-only, no rules change, consistent with "the JS game stays the rules oracle". Flagged for Finding 2 (roundStart's concurrency and missing B.over re-check deviate from the game and from its own comment) and Finding 1 (ordering change with no re-run, so sim numbers are stale).

### FID telemetry: Flagged (largely consistent, with gaps).

Consistent: the implemented metrics match the commit message and map onto the B3 exit criterion: range (average firing range) for engagement range; shieldPct, cutPct, hullPct for damage soaked by shields versus armour and other cuts; lossPct for losses; plus regenPerShip (hull regrown per ship) and dealtPerShip (damage dealt per ship), all in fidReport (sim3d.js:16). The install is harness-only: the applyHit, fireWeapon and startSideTurn wrappers (sim3d.js:11-13) delegate to the originals and only count, changing no rules. fidBattle runs once per battle (sim3d.js:406) and the FID line prints at the end of fMatrix (sim3d.js:412). The metrics all have player-visible counterparts (weapon ranges, shield bars and armour, hull regrown, ships lost), so the telemetry itself introduces no sim-only unreadable mechanic. Flagged for Finding 3 (the faction-definer counters are dead), Finding 4 (wording nit), and Finding 1 (no FID output filed, so the B3 exit is not yet demonstrated).

### B4: no claim, nothing to flag.

The trigger commit claims no B4 exit. Per the pack, B4 exit needs Ryan to play each item and Ryan is traveling; no B4 item is claimed as exited here.

## NOT CHECKED

- Admiral band: UNSURE. The commit message gives no win rates and I found no post-B-19 sim output; the only band numbers on record (57-89% at 96 runs per admiral, FINDINGS S6 per the pack) predate B-19. I could not verify any admiral inside or outside the 50-90% band on the new code.
- Post-B-19 sim re-run: not found. contrib/opus/compute/ tops out at Oct 25; I could not verify that the FID line prints correctly or compare win rates against the B0 baseline.
- Ryan's playtest: not checked. The B3 exit needs Ryan to play each faction once and say whether it feels like itself, and B4 exits need his play; he is traveling.
- B-18 stall plausibility beyond code reading: INFERRED from the sequential sim structure; I did not exhaustively prove B.epoch can never change mid-battle in the sim.
- Exact line numbers for ui3d.js nextRound and for the battle.js functions liveFrom, queueDeath, startSideTurn and applyHit: cited by function name (the raw page view carries no line numbers).
- I did not execute the sims (no terminal available); all behavior claims are from reading the code.
