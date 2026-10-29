Chair note: filed verbatim from the DeepSeek DeepThink run of Oct 29, 2026 (toggles verified on; first chat attempt hung in generation and was abandoned, second chat completed), except em dashes and en dashes in the model's text are normalized to hyphens. The report's list numbering runs continuously (findings numbered 3-12, designer questions 6-8) as rendered; preserved as-is.

1. Proof of reading

Read: EVIDENCE PACK title line; THE COMMISSIONER'S QUESTION; CHAIR CENSUS; WHAT TO JUDGE; data.js 1-60 (W, ARC_NAME, KIND_NAME, FAC_WNAMES, WTRAITS, FAC_WTRAIT, nameWeapons); battle.js 531-536 torpedo travel rules.

Overall verdict: DUPLICATES WITH PAINT - there is an exact flak/gsentry clone plus several same-kind near-clones; faction traits are mechanically real, but they do not fix base-table duplication.

2. Findings

3. [BLOCKER] READ - flak and gsentry are the same gun under two names: both are `shots:3,dmg:3,r:2,opt:2,acc:80,fall:10,vsSq:3,vsCap:.6`, same kind `flak`. No trait distinguishes them. This is not a decision; it is a duplicate entry.

4. [FIX] READ numbers; INFERRED arc - turret and turbo are nearly identical batteries: turret is `shots:2,dmg:8`, turbo is `shots:2,dmg:9`, with the same `r:5,opt:3,acc:74,fall:8,crit:5`. If "Dorsal turret" / `T:'Turret (all arcs)'` means the turret is all-arc, the fixed turbo pays only +2 total damage for losing all-arc. That is not enough compensation for the facing constraint.

5. [FIX] READ - hbattery dominates battery on the table: same `r:5,opt:3,acc:72,fall:8`, but hbattery has `shots:5,dmg:7,crit:6` versus battery `shots:4,dmg:6,crit:5`. With no cost or mount restriction in the pack, they are the same job with a strictly bigger version.

6. [FIX] READ - autocannon and laser are a rounding-error pair: total damage 15 vs 14, both `r:4,acc:80,fall:8,crit:5`; only shot count 3 vs 2 and optimal range 2 vs 3 differ. The one-liners are both "light/accurate short-mid battery."

7. [FIX] READ/INFERRED - the torpedo trio does not create three clear jobs: torp is `dmg:42,r:6,acc:64,pierce:.3`, startorp is `dmg:38,r:5,acc:66,pierce:.4`, and both share `cd:2,evMult:2`; htorp is just `2x34` of the same pattern. The travel rules add complexity, but the entries differ mainly by small sidegrade numbers.

8. [FIX] READ/INFERRED - point defense as a system is undercut by duplication: flak and gsentry are identical, and spores is only `3x4,acc78` versus `3x3,acc80` with the same `vsSq:3,vsCap:.6`. The anti-squadron role is real, but the table does not earn complexity with two identical PD guns.

9. [FIX] READ/INFERRED - ion cannot be judged as a special system from this pack: it has `ion:2.5` on a `1x12` lance, but no shield rules are included. Its job is statable only as "shield-interaction lance"; whether that is a decision or a black box is not testable here.

10. [NOTE] READ/INFERRED - doom is not clearly a distinct heavy gun: `dmg:40,cd:2` averages 20 per turn, exactly lance's `dmg:20`; it has worse `r:5,opt:4,acc:78` but higher `crit:12` and `pierce:.6`. The cooldown creates alpha timing, not a clearly different role.

11. [NOTE] READ - faction traits are not just paint for many guns. Example: Voidsworn autocannon gets `las` (fall halved, acc+4), while Corsair autocannon gets `scrap` (shots+1,acc-12,crit+3). Same base gun becomes a different decision. But renames without traits, such as the many flak names, are paint.

12. [NOTE] READ - the facing economy cannot be fully audited from this pack: it gives mount counts but not per-hull arcs, mount costs, or weapon availability by arc. Only the turret/turbo pair is judgeable, and then only under the INFERRED assumption that turret is the all-arc mount.

13. Explicit checks

1. ROLE CLARITY

All 22 non-squadron weapons have statable one-line jobs from base `W`; none is unreadable. The problem is collision, not opacity.

| Weapon | Job from numbers alone | Flag |
|---|---|---|
| autocannon | 3x5,r4/opt2,acc80: light short-mid multi-shot battery | near laser |
| flak | 3x3,r2,vsSq3/vsCap.6: close point defense vs squadrons | exact duplicate gsentry |
| battery | 4x6,r5/opt3,acc72: general mid-range battery | same job as hbattery |
| hbattery | 5x7,r5/opt3,acc72,crit6: heavier general battery | same job as battery |
| lance | 1x20,r7/opt6,acc82,pierce.6,crit10: long-range single-hit AP lance | distinct |
| torp | 1x42,r6,acc64,cd2,evMult2: delayed heavy torpedo | near startorp |
| turret | 2x8,r5/opt3,acc74: all-arc mid battery [INFERRED arc] | near turbo |
| laser | 2x7,r4/opt3,acc80: accurate short-mid battery | near autocannon |
| turbo | 2x9,r5/opt3,acc74: mid battery with harder hits | near turret |
| hturbo | 3x9,r6/opt4,acc72,fall7,crit6: heavy longer-range battery | mostly distinct |
| ion | 1x12,r6/opt5,acc80,ion2.5: shield-interaction lance | special undefined in pack |
| scatter | 5x5,r3/opt2,acc78,fall10,crit6: short-range many-shot brawler | distinct |
| htorp | 2x34,r6,acc60,cd2,evMult2: double heavy torpedo | heavy torpedo variant |
| tendril | 2x13,r1/opt1,acc85,pierce.5,crit12: extreme-close boarding/bio | distinct |
| bioplasma | 2x12,r4/opt3,acc74,pierce.2,crit8: mid-range bio battery | distinct |
| spores | 3x4,r2,acc78,vsSq3/vsCap.6: close PD, heavier/less accurate | variant of flak |
| pulsar | 2x12,r6/opt5,acc80,pierce.6,crit10: multi-shot prism lance | distinct from lance by shots/range |
| startorp | 1x38,r5,acc66,pierce.4,cd2,evMult2: shorter/more accurate torpedo | near torp |
| gauss | 3x6,r5/opt3,acc74,pierce.6: AP null battery | distinct |
| gsentry | 3x3,r2,acc80,vsSq3/vsCap.6: point defense | exact duplicate flak |
| doom | 1x40,r5/opt4,acc78,pierce.6,crit12,cd2: heavy cooldown lance | average equals lance |
| shard | 3x6,r4/opt2,acc80,crit6,vsSq1.6: anti-squadron/dual battery | distinct |

No weapon's job is unstatable. The same-job clusters are: flak = gsentry; battery ≈ hbattery; turret ≈ turbo; autocannon ≈ laser; torp ≈ startorp.

2. DUPLICATION

Closest same-kind pairs:

1. flak vs gsentry - exact duplicate in kind and every numeric field. Not a decision; it is the same gun twice.

2. turret vs turbo - same kind, same `r5/opt3/acc74/fall8/crit5`; only `2x8` vs `2x9`. Rounding error on numbers; if the turret is all-arc, it becomes a facing decision, but then the fixed gun is underpriced.

3. autocannon vs laser - same kind, same `r4/acc80/fall8/crit5`; total 15 vs 14, with only shot count and optimal range differing. Rounding error/sidegrade, not a distinct role.

Cross-kind: the closest is gauss vs shard (`3x6`, `r5` vs `r4`, `acc74` vs `acc80`), but gauss has `pierce:.6` while shard has `vsSq:1.6`; that is a real role split, not a duplicate.

3. FACING ECONOMY

From the numbers, fixed guns do not pay enough. The only clear comparison is turret `2x8` versus turbo `2x9`, otherwise identical. If turret is all-arc, turbo buys +2 total damage for losing all-arc; that is not a meaningful price for the constraint. At equal cost I would never take turbo over turret if the turret mount is available. turret's facing is its whole identity, and that identity is under-priced against the fixed gun. No other weapon has enough arc data in the pack to judge fixed-versus-turret tradeoffs.

4. FACTION TRAITS

Take autocannon and turret.

- autocannon: Voidsworn `las` halves falloff and adds +4 accuracy; Corsair `scrap` adds a shot, drops accuracy by 12, and adds +3 crit. That is a real decision: accurate long-range chip vs wild spray.
- turret: Voidsworn `las`, Corsair `scrap`, Ithar `needle` (`acc+6,crit+8`). The same base turret becomes an accurate turret, a wild extra-shot turret, or a precise crit turret.

So the traits are not paint; they change the decision. The renames alone are paint, and some renames - notably flak names - have no trait at all.

5. SPECIAL SYSTEMS

- Torpedoes: They earn complexity through the travel rules: launch now, strike next turn, dodge penalties by hexes from aim (`TORP_RING=[0,5,15]`), stray hit, and `TORP_WARHEAD=1.2`. The system creates positioning and alpha-timing decisions. But the three torpedo entries share the same `cd:2,evMult:2` and differ mainly by sidegrade numbers, so the complexity belongs to the system, not to each weapon. If deleted, the game loses delayed alpha and dodge play; battles become more immediate-fire.
- Ion: It does not earn its complexity from this pack. There is one ion weapon with `ion:2.5`, and no shield rules are included. If shields exist, deleting ion removes a shield-strip tool; from the pack alone, no visible system breaks.
- Point defense (flak/gsentry): The `vsSq:3,vsCap:.6` role is real, but the table undermines it with an exact duplicate and a near-variant (spores). If deleted, squadrons lose a hard counter; deleting one of the duplicates loses nothing.

4. Not checked

This pack does not let me judge: per-hull arc assignments, mount costs, ship costs, command-point budgets, availability by faction/hull; shield rules and the actual ion effect; point-defense interception formulas for torpedoes/rockets; crit/armor/falloff formulas; cooldown implementation; squadron survivability and squadron weapon full rules; whether WTRAITS stack or apply once per object; AI/fleet composition under the ~20-ship battle cap.

5. Questions for the designer

6. What are the actual arc assignments and mount costs per hull/weapon? Without them, the turret/turbo one-damage gap cannot be judged as fair or broken.

7. Is flak vs gsentry intentionally identical, or is one missing a faction trait or PD rule? The answer decides whether this is a duplicate entry or missing data.

8. What are the shield rules for ion and the point-defense interception rules for torpedoes/rockets? Those rules decide whether ion and torpedo complexity are real systems or opaque labels.
