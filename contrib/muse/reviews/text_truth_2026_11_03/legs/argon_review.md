Argon review leg, issue #88, run 2026-11-03 from the main chat. Gates: model picker showed 4 Argon with Thinking level High and the prompt bar read Argon High before sending; the prompt bar still read Argon High after sending. PACK.md, deepseek.md and qwen.md were attached to the send message itself. Reviews only per R81.

Chair screening: USED: the h_feast overstatement catch (DeepSeek marked a text CERTAIN that its fx-only view could not support; chair code verification then cleared the text entirely), and the three missed-candidate prompts (Malek passive and Command, "every 2 turns" texts, FX_CAPS stacking), each closed by the chair with direct code reads in the synthesis. NOT ADOPTED: the TIPS:select false-positive call (the chair keeps the fix, reasons in the synthesis), and the h_feast template warning (the boon text is a function interpolating boonPct, not a bracket placeholder, and no fix was needed). Argon's repeated UNVERIFIED grades where the chair has since verified from code reflect its pack-only view; the synthesis carries the verified dispositions. The verbatim review follows.

---

1. Real Mismatches vs. UNVERIFIED Among Flagged Items

ABILITIES:reload - "Torpedo tubes are ready to fire again immediately." (DeepSeek: AMBIGUOUS; missed by Qwen)

Status against PACK.md facts: Valid flag (AMBIGUOUS / UNVERIFIED for exact fix). PACK.md explicitly points out that a cd 2 weapon sets its cooldown on firing and decrements once at round start, and that a launched torpedo stays in flight until the start of the firing side's next turn ("a salvo in flight is not a loaded tube"). PACK.md also notes under Method that "a text that says 'immediately' when the code waits a turn is not" acceptable. Because PACK.md does not include the reload branch of useAbility in battle.js, whether reload only resets cooldown for a future turn or cannot refire a tube whose salvo is currently in flight remains UNVERIFIED from PACK.md alone.

ADMIRALS:khepra - "Your ships take 50% less hull damage this round. Gets stronger each round you hold it." (DeepSeek: AMBIGUOUS; missed by Qwen)

Status against PACK.md facts: Valid internal-consistency flag (AMBIGUOUS / UNVERIFIED). DeepSeek notes that Khepra shares cmd.id: "iron" with Thale, Maren, and Mirelle, whose texts state "40% less hull damage". Because PACK.md does not provide the iron Command implementation in battle.js, which percentage (40% vs. 50%) and whether the hold-scaling clause exists in code are UNVERIFIED.

BOONS:h_board - "and a failed boarding always sabotages a system." (DeepSeek: CERTAIN; missed by Qwen)

Status against PACK.md facts: Valid mismatch against the record's fx object ({boardPct:.25*m}) per PACK.md's rule to audit BOONS text against the record's fx function. However, whether battle.js checks the boon ID h_board directly outside sumFx is UNVERIFIED without battle.js.

BOONS:h_feast - "its carrier gains a spare wing and repairs [X]% hull." (DeepSeek: CERTAIN; missed by Qwen)

Status against PACK.md facts: UNVERIFIED (overstated as CERTAIN by DeepSeek). While the record's fx object is {feast:.05*m} with no separate spare-wing key, feast is a bespoke effect key rather than a generic stat modifier; whether the feast handler in battle.js grants a spare wing alongside hull repair whenever fx.feast > 0 is UNVERIFIED from PACK.md.

2. False Positives and Misread Code Facts

WTRAITS:spines - "hull hits strip 3 armor points, up to 15" (Qwen: AMBIGUOUS; DeepSeek: properly placed in UNVERIFIED)

Why it is a false positive: Qwen misread w.shred=.03 as contradicting "3 armor points". In PACK.md, FX_CAPS lists armor: 1 alongside percentage-scale keys (hpPct: 2, shPct: 2, regenPct: 2, armor: 1, dmgPct: 2), showing that armor is represented as a decimal fraction where 0.01 equals 1 armor point. The up to 15 cap (0.15) is UNVERIFIED without the shred implementation in battle.js, not a mismatch.

TIPS:select - "Or Brace: the ship stays put, takes less damage, and does not take the +10, but it cannot move or fire again this turn." (DeepSeek: CERTAIN)

Why it is a false positive: DeepSeek flagged this against ORDERS:brace ("The ship can move first, but can't brace after it has fired, and bracing ends its turn."). In context, TIPS:select is contrasting moving with staying stationary ("stays put ... and does not take the +10") and explaining that once Brace is used, the ship "cannot move or fire again this turn" (which matches "bracing ends its turn"). PACK.md's Brace fact (battle.js:1062) covers only the hull damage multiplier, so turn-action ordering in code is UNVERIFIED from PACK.md.

TIPS:c_tree and CARDS:c_tree - "each point of Heat gives +2 experience to the admiral you fly and +1 to your faction's shared pool" (DeepSeek: AMBIGUOUS; Qwen: UNVERIFIED)

Why it is a likely false positive (UNVERIFIED): DeepSeek pitted a data.js HEAT code comment ("each level adds 10% renown") against the tutorial card text. PACK.md explicitly notes that the Nov 2 update added "shadow XP, teaching cards"; "+2 experience to the admiral you fly and +1 to your faction's shared pool" describes shadow XP, and code comments in data.js are not chair-verified code facts. Because PACK.md provides no Heat/XP implementation fact, this is UNVERIFIED (as Qwen categorized it) rather than a confirmed mismatch.

TIPS:c_clock and CARDS:c_clock - "Every jump moves the clock at the top." (DeepSeek: AMBIGUOUS)

Why it is UNVERIFIED rather than a verified mismatch: DeepSeek relied on a NEM_CLOCK comment in data.js rather than a chair-verified fact in PACK.md. Without campaign clock code in PACK.md, whether jumps, wins, or loud choices advance the clock is UNVERIFIED.

3. Candidates in Scope Missed by Both Legs Against PACK.md Facts

Checking the PACK.md code facts section against the texts quoted in PACK.md and the two reports surfaces the following missed candidates:

ADMIRALS:malek Command (Hunter's salvo) - "torpedoes reload at once and every ship deals +30 percent damage this round" (quoted in PACK.md)

Contradiction / risk against PACK.md facts: Neither leg flagged Malek's Command despite DeepSeek flagging ABILITIES:reload ("Torpedo tubes are ready to fire again immediately.") for the exact same conflict with PACK.md's torpedo and cooldown rules (launched torpedoes remain in flight until the start of the firing side's next turn, and "a salvo in flight is not a loaded tube").

ADMIRALS:malek Passive - "torpedoes reload a turn faster and +50 percent damage on rear-arc hits" (quoted in PACK.md)

Contradiction / risk against PACK.md facts: PACK.md explicitly quotes Malek's passive and instructs legs to audit all 24 admirals "against the record's fx and, where the pack gives no implementation fact, against the text's own internal claims plus the cooldown and torpedo rules above". Neither leg reported whether Malek's fx in data.js actually contains keys supporting both a 1-turn torpedo cooldown reduction (torpCd: 1) and a +50% rear-arc damage bonus, or whether the rear-arc claim is missing from fx / UNVERIFIED.

Any cd 2 weapon/torpedo/ability text claiming "every 2 turns" (quoted in PACK.md)

Contradiction against PACK.md facts: PACK.md explicitly states under Cooldown semantics: "So a cd 2 weapon fires, skips two round starts, and fires again on the third turn... A text that says "every 2 turns" about a cd 2 item is wrong; "every third turn" or no timing claim is right." Neither DeepSeek nor Qwen flagged any text matching "every 2 turns", indicating both legs likely missed the cd 2 description (such as on torp/htorp descriptions, tutorial tips, or abilities) that prompted this specific rule in PACK.md (UNVERIFIED exact table ID without data.js and tips_browser.txt attached to this leg).

Brace shield-damage omission / "takes less damage" claims (TIPS:select: "Or Brace: the ship stays put, takes less damage...", plus ORDERS:brace and Voidsworn cover doctrine)

Contradiction / risk against PACK.md facts: PACK.md states under Brace (battle.js:1062): "base brace is 40 percent less hull damage; relic bracePlus can deepen it to the 0.15 floor (85 percent less). The Voidsworn cover rule uses the same multiplier for a ship covered by a bracing neighbour. Brace does not reduce shield damage." If ORDERS:brace, Voidsworn's cover doctrine text, or bracePlus relic texts claim a ship takes "40% less damage" (all damage) rather than hull damage, both legs missed it (TIPS:select says "takes less damage", which is broad, though any explicit percentage claim omitting "hull" in data.js is UNVERIFIED here without data.js attached).

4. Additional Risks and Ideas for Chair Screening

Missing FX_CAPS stacking audit across both legs: PACK.md gives the complete FX_CAPS table (core.js:175 to :191) and instructs legs to check whether any text promises unlimited stacking of a capped effect where the cap is reachable from available sources (or mark it AMBIGUOUS with the arithmetic). Neither DeepSeek nor Qwen reported any FX_CAPS arithmetic or flagged any stacking text (e.g., bracePlus capped at 0.45 / 85% reduction floor, cdMod capped at 3 with abilityCd floored at 1, hullRegenPct capped at 0.25, ev/aim/crit capped at 50).

Risk in DeepSeek's proposed fixes for BOONS:h_board and BOONS:h_feast: BOONS:h_feast uses a template placeholder ("repairs [X]% hull") so the UI can interpolate the rarity-scaled value (Common x1, Rare x1.5, Epic x2). DeepSeek's proposed text replaces [X]% with static prose ("5% hull at Common, rising with rarity"), which would break dynamic number display if data.js boons rely on [X] substitution.

Incomplete coverage and truncation in Qwen's report: Qwen's output truncated mid-table at LINEAGE_TREES (all, audited only ~10 of 15 browser TIPS, audited only 13 of 14 ABILITIES, failed to mark ABILITIES:nova as UNVERIFIED (which PACK.md explicitly required if the nova block could not be verified), and audited several out-of-scope tables (SECTOR_CONDS, NODE_MODS, WING_STANCES, WING_PERKS) while missing core in-scope tables (ORDERS, FAVOUR_TIERS, BOONS).

Missing data.js Chorus Feed section noted by DeepSeek: DeepSeek noted under UNVERIFIED that FEED_KILL, FEED_NEAR, FEED_R, FEED_CAP, and the Chorus Feed doctrine text (data.js:485 to :490) were not present in its attached data.js. Verify whether the attached data.js snapshot was from an older branch or if the Chorus Feed constants live in another file before running export scripts.
