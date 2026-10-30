# Qwen red-team leg: chair open-check answers and ruled-fix spec (Oct 29, 2026)

Filed verbatim from the model report (chat.qwen.ai, run Oct 29, 2026, 8:08-8:24 PM CDT, harness measured; both model gates passed, selector and header verified as Qwen3.8-Max; an Access Verification slider was cleared under the designer's standing permission). Em dashes and typographic separators in the original are normalized to hyphens in this copy; wording is otherwise unchanged. The chair screening note lives in the goal workspace (oct29_savings_redteam_qwen_screening.md).

CHAIR ANSWERS MOSTLY HOLD

Answer-by-answer verification

1 - NOMIDFIRE: no harness sets it - CONFIRMED
Pack census lists four read-sites, zero assignments. Quote: "nothing assigns it" (census header). Chair's "pure code defect" framing is sound: the guard is dead. No reasoning beyond pack.

2 - h_board sabotage scope - CONFIRMED
Three branches visible in boardUnit. Capture: no systemDamage. Bridge-holds: two unconditional calls. Partial: rnd()<.5||(u.fx&&u.fx.boardPct). Quote: "Saboteurs: ${sy.toLowerCase()}" gated by coin-flip-or-boon. Chair's "overpromises in scope" verdict matches code.

3 - No fit-check for modules - CONFIRMED
Quote: "no fit-check hits above = chair claim." Single only:'launch' at data.js:165 shown. Absence of a guard is directly attested by the census.

4 - battery vs hbattery dominance - CONFIRMED (table) / CANNOT DECIDE (mount separation)
Table dominance is arithmetic: shots 5>4, dmg 7>6, crit 6>5, all else equal. Quote: "shots:5,dmg:7...crit:6" vs "shots:4,dmg:6...crit:5." However, the chair claims hbattery appears "only on the cathedral battleship (cp5) and the ascendant dreadnought (cp8)." The pack shows the penitent mounts battery; it does not show the cathedral or ascendant hull lines. The no-arbitrage conclusion is INFERRED, not READ.

5 - Hive wing sources - CONFIRMED
canStance accepts u.ab==='launch'||(u.fx&&u.fx.hive). core.js:214 folds fx.hive into hangar. Quote: "hangar:t.hangar?t.hangar+...+(fx.hive||0):(fx.hive||0)." Chair's reading is exact.

6 - Ceiling fill loop strands budget - CONFIRMED
Quote: "while(budget>=1 && list.length<Math.max(4,ceil) && g++<80)." Three exit conditions; ceiling can trigger with budget > 0. Mechanism is structural, not probabilistic.

7 - Godot oracle carries unlockAll - CONFIRMED
Quote: "godot/campaign/test/oracle/campaign3d.js" is the sole hit; header states "no .gd." Chair's "right-sized fix" (exclude unlock state from oracle) follows directly.

Spec review

Fix 1 - rollBoonOffer spillover
The rollRarity body is in the pack and confirms the favour mechanics the spec cites: +.12 rare, +.03 epic, tier-3 floor via Math.max(r,1). Quote: "(ft>=1?.12:0)...if(ft>=3) r=Math.max(r,1)." CONFIRMED.
However, the spec's core structural claim - "off-patron boons backfill only when that pool runs short" and "hard sequencing" - rests on the body of rollBoonOffer. The pack shows only the opening: "ensurePatrons(); const s=(RUN&&RUN.sector)||1, have=boonPatrons(), kit=fleetKit();" The sequencing, the backfill tier, and the missing-patron-argument call are not visible. CANNOT DECIDE FROM THE PACK. The duo-offer acceptance check ("duos enter separately at m=1") also has no pack evidence.

Fix 2 - nemAfterBattle loss-debrief reveal
The pack shows only the function signature and six variable assignments. Quote: "const out=[], beh=nemBeh(), P=nemPr(N), say=t=>nemSay(t,N)." The win-branch reveal, the loss-branch "drove-you-off" line, the revealed-set write, and the adaptation clash check are all absent from the pack. CANNOT DECIDE FROM THE PACK.
The spec also cites "campaign_run.js:249-251" for weakness generation ("exactly two, drawn from the seven-pool") and a "blind Rey firstrun leg" for in-battle defeat reveals. Neither appears anywhere in the pack. These are beyond the pack.

Findings

[FIX] Answer 4 mount-separation claim is INFERRED, not READ. The pack shows penitent mounts battery; it never shows cathedral or ascendant hull lines. The "no hull offers the player a choice" verdict is plausible but unverified. If a mid-tier hull mounted both, the dominance becomes a live arbitrage.

[FIX] Answer 4 CP-cost formula goes beyond pack. The chair cites "round((60cp+10)/5)5" for hull pricing. No pricing formula appears in the pack. This is an external assertion presented as code-read.

[FIX] Spec Fix 1 backfill sequencing is CANNOT DECIDE. The entire "hard sequencing" defect - the thing the fix removes - is not visible in the rollBoonOffer excerpt. Only the function's first line is quoted. The spec's two-part change (competition pool + equal rarity) is well-specified mechanically, but the current defect it corrects is taken on trust.

[FIX] Spec Fix 2 branch behavior is CANNOT DECIDE. Win-branch reveal, loss-branch silence, and the revealed-set bookkeeping are all asserted but not shown. The pack excerpt ends at let back=false;.

[NOTE] Spec Fix 2 cites a "blind Rey firstrun leg" as prior art for in-battle defeat reveals. No such leg appears in the pack. The spec's justification that the debrief reveal "extends an existing channel rather than inventing one" rests on an external reference. (INFERRED dependency.)

[NOTE] Answer 2 bridge-holds branch fires two systemDamage calls, but the boon text promises "sabotages a system" (singular). The chair flags scope overpromise; the double-sabotage on bridge-holds is a second, unflagged wording mismatch. Minor. (READ.)

[NOTE] Spec Fix 1 acceptance check (c) asserts "duo offers are unaffected (duos enter separately at m=1 by design)." No duo-offer entry path appears in the pack. The check is untestable against pack evidence alone. (INFERRED.)

[NOTE] Answer 1 "brace bypass" framing. The chair calls the NOMIDFIRE-gated path "a pure code defect." The pack shows the brace fires only inside the volleyP block, which requires midFire true. Since NOMIDFIRE is never set, midFire is always true for eligible units, so brace is reachable. The "bypass" is the absence of the NOMIDFIRE gate, not a separate bug. Wording could mislead a fixer into adding a gate rather than removing dead code. (READ.)

Not checked

Full rollBoonOffer body and its backfill/sequencing logic beyond the first line.
nemAfterBattle win and loss branch implementations past the function signature.
Nemesis weakness generation at campaign_run.js:249-251 (two-from-seven pool, trait filter).
Cathedral and ascendant hull weapon-mount definitions.
Hull-cost formula and any pricing code.
Duo-offer entry path and the m=1 design reference.
Adaptation clash check and boss-win sector-transition naming.
Any Godot .gd source beyond the presence/absence census for unlockAll.
CP and repair simulation results (chair explicitly defers these).
The "blind Rey firstrun leg" and any prior in-battle defeat-reveal precedent.

Designer questions

If a future hull mounts both battery and hbattery, does the dominance become a live balance defect, or should the table carry an explicit replaces tag now? Stakes: a one-line data comment today prevents a player-facing arbitrage the day a new hull ships; waiting means a patch under player scrutiny.

For Fix 2, should the loss-debrief weakness reveal use the same "analysts" voice as the win branch, or does the defeat context warrant a distinct, less-certain framing (e.g., "your analysts believe they've identified...")? Stakes: the spec's proposed wording is neutral; per-faction idiom is deferred. If the defeat voice reads as certain as the win voice, players may feel the loss is mechanically painless, undermining the Nemesis tension Ryan's ruling is trying to preserve.
