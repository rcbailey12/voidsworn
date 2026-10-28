Chair synthesis: admirals audit (Oct 27 program item 4). Four blind legs on the same pack pinned to 68b42ce406286eb95ea7df6aaf3f683c1231b51d: DeepSeek (not coherent enough to sign off, BLOCKER tags on Grax and the Matriarch/Aelith pair), Qwen (FAIL, two BLOCKERs), Argon (FAIL, seven BLOCKER tags over five unique issues), and Rey (this chair's own leg). Admiral data was verified line by line at the pin (data.js 200 to 275, NEM_FAC 460 to 475), and strength claims were screened against the item 7 bossmatrix seed-42 measurements, with the caveat stated in finding 6.

OVERALL VERDICT: FAIL on identity, PASS on function. No BLOCKER survives chair review. Eight FIXes, all in one family: the roster's text and packaging do not make 24 admirals read as 24 distinct people, even though all 24 play inside the measured band (bossmatrix 55% to 85%, matching the G-13 claim). This is a roster-polish audit, not a balance audit.

TOP FINDINGS

1. Duplicate passives (FIX, three-leg convergent, Argon's mapping is the complete one). Three verbatim repeats: Thale = Maren ({hpPct:.15, shPct:.1}, both cost 80, same iron text); the carrier package {sqPct:.25, hangar:1, sqHp:.25} three times over (Matriarch 0, Aelith 0, Mott 45); Nekhet's {hullRegenPct:.04} at cost 0 repeated on Mending at cost 45. DeepSeek and Qwen each found the Matriarch/Aelith pair only; the trio and the Thale/Maren pair complete the set.

2. The hunt split (FIX, three-leg convergent). Command id 'hunt' carries two texts: Malek and Sable include the torpedo reload clause, Vorn and Anuket/Ostrel do not. If behaviour keys off the id, one pair's card lies; if off the text, the id is decoration. Opus to answer which.

3. Vorn (FIX, three-leg convergent). Doctrine "Interdiction", kit of aim/crit and a plain damage Command; nothing interdicts. Directly against Ryan's standing rule that admirals match their abilities, and adjacent to the bible 3.8 avoid word his own hull was renamed away from.

4. Grax (FIX, DeepSeek and Argon at BLOCKER, chair holds FIX). Doctrine "Ram and board" with no ram or board effect in his own kit. Softer than Vorn because the Corsair kit around him supplies both verbs and surge enables the close; the defect is the admiral's card promising what the admiral does not bring.

5. Khepra (FIX, chair-added). The shared iron Command text promises a shield refill to the one fleet in the game with no shields on any hull. The other legs circled this (DeepSeek as doctrine colour, Argon's four-way framing); the sharp form is the chair's: half of Seveth's Command text is inert for his own fleet, every time.

6. Card accuracy family (FIX). Hidden sqHp:.25 on all five carrier admirals, unmentioned in any text (three-source convergence across two audits). Vaelen's fleet-wide aim:10 described as a lance bonus. Kassar's damage effect described as accuracy ("hits 5% lighter" against dmgPct:-.05). One direction hides power, the others mislabel it; all three are the same fix pass over the admiral cards.

7. Chorus Nemesis voice (FIX, Argon-only, quote-backed). Nemesis lines for the Chorus speak in first person singular against bible 1.3's "we" rule, the patient persona borrows an Eclipse immortality claim, and behaviour text uses "his" for a neuter Chorus. Converges with the text audit's pronoun findings.

WHAT DISSOLVED OR DOWNGRADED

- Qwen's Interdictor BLOCKER does not survive: at the pin the hull's display name is already "Cordon destroyer" (data.js:75) with variant "Cordon column escort" (data.js:567); the rollout rename is applied and h_interdictor survives only as an internal id, and ids never change. Qwen's pack slice did not include HULLS and its own Not Checked flags the gap. Residue NOTE, agreed by the other legs at that weight: Vorn's doctrine display word remains.
- Qwen's CAP_LAST BLOCKER downgrades to NOTE: the overlap is real (all ten Voidsworn Nemesis post names appear in CAP_LAST) but breaches neither operative clause of rule 1.4.3, and Ryan's full-audit Q6 ruling tolerates related overlap. The heading of the rule promises more than its clauses; a clarification for Opus, not a data defect.
- Every cost-band power verdict from the external legs fails against measurement: Reyes and Voice, called weak, measure at the band top (85%); Sekhmar, called the outlier, measures at the floor (55%). Caveat carried in the Rey leg: bossmatrix measures playing against an admiral, and cost is a renown unlock price, so this screens claims rather than settling them. The package arithmetic underneath (the carrier sqPct ladder ashgrove .4, mott .25, reyes .1) is accurate and stays as a consistency NOTE. The Mending/Nekhet cost split survives reversed as a question for Opus.
- 'Eclipse-prime' in the Nemesis titles is tension, not violation: Ryan's Q9 ruling offered the term himself. Plain 'Nadir' beside it is already ruled for removal (rollout Q4).

NOTES CARRIED

Nemesis title pool items ('Duelist' extra in the Ithar pool, 'High Nadir' reusing a boss element), Corin as a Glasswright example name on a Hegemony admiral, the bible-internal Mending Throng formula tension, scarBy.fled entries for factions that never flee, and Argon's epithet-absence family (accurate as text observation; its extension of Ryan's matching rule from design to names is Argon's reading, not the rule as recorded). One clean negative result is worth keeping on record: no Nemesis pool combination can assemble an admiral's full name (Qwen's check).

LEG WEIGHTS

Argon was the strongest leg here: the complete duplicate mapping, the hidden sqHp in full, the Chorus voice catch. DeepSeek found the structural pairs early and its Grax doctrine point was real, sharpened by the chair into the Khepra form. Qwen ran the audit's only systematic negative test (name assembly) and its two BLOCKERs both dissolved on pin-state facts its pack slice did not cover, which is a pack-design lesson for the chair, not a model failure: future packs should include the HULLS lines for any audit touching admiral fleets.

QUESTIONS FOR RYAN

None. The duplicate passives, the hunt split and the doctrine mismatches are roster decisions for Opus within the recorded design rules (including your admiral-ability matching rule); the one ruling-adjacent item, plain 'Nadir', was already decided in the rollout rulings and sits in the item 9 pack.
