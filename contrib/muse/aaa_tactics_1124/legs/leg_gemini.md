# Leg: Gemini on Hydrogen (the Flash seat), issue 2060

Gate record: signed in with the saved Google login, no phone tap or code needed. Model picker verified on "Everyday help - 4 Hydrogen" before pasting and still on Hydrogen after generation. Brief pasted as plain text, no file attached. Chat: "Faction Command Sets and Deployment Design", https://gemini.google.com/app/98fa99e2e6b6ded8

Response verbatim:

Question 1: Faction Command Sets
Structural Approach

Keep four distinct commands per faction (24 total), rather than one signature command with four variants. Because per-admiral riders already act as variants on a base effect, collapsing to one base command per faction reduces build variety across runs. Giving each faction four bespoke commands tied to its battle rule preserves run-to-run discovery while keeping the existing three-tier charge-and-hold scaling (roughly +25% to +35% value per tier, hitting baseline template power at Tier 3).

1. Sunward Crusade (Voidsworn)

Theme: Broadside momentum, formation overlap, and slow, crushing fire lines.

Vex - Broadside Salvo: Every ship fires a free volley using only its side batteries (lances and prow guns do not fire), counting as having moved 2 hexes this round so "Line of battle" triggers automatically. Reuses: barrage free attack, Line of battle movement check. Tier scaling: Tier 1 fires at -20% damage; Tier 2 at full damage; Tier 3 at +20% damage.

Malek - Lance Alignment: All lance and torpedo weapons reload at once, and every ship gains +1 turn (rotation) and +25% damage on frontal/prow weapons this round. Reuses: hunt reload and damage boost, surge turn bonus. Tier scaling: +15% / +25% / +35% damage.

Ashgrove - Escort Screen: Every launch ship deploys an extra fighter wing if there is room, and all active wings act as Brace cover (reducing incoming damage by 25%) for any friendly ship in their hex. Reuses: scramble wing spawn, Brace damage reduction rule. Tier scaling: Wing damage reduction scales 15% / 25% / 35%.

Thale - Phalanx Lock: All ships enter Brace immediately without spending movement, and the adjacent-ally cover rule of "Line of battle" extends to 2 hexes and refills 50% of shields on braced ships. Reuses: iron shield refill and damage reduction, Brace state. Tier scaling: Shield refill scales 30% / 50% / 75%.

New rules flagged: Ashgrove's wing-as-cover check (checking if a friendly squadron occupies the target's hex during damage resolution).

Balance argument: Vex trades full-arsenal barrage for guaranteed broadside bonuses; Malek narrows hunt to frontal weapons in exchange for a free turn to line them up; Thale swaps raw iron shield fill for team-wide Brace mitigation that rewards tight positioning.

2. Meridian Directorate (Hegemony)

Theme: Command-network amplification, focus fire, and precision shield stripping.

Kassar - Networked Volley: Every ship within 3 hexes of the command ship fires a free volley at the target currently marked by the command ship (or the nearest valid target if none is marked), inheriting full "Synchronized fire" bonuses. Reuses: barrage free attack, Synchronized fire range and aim/damage buff. Tier scaling: Tier 1 hits up to 2 ships; Tier 2 hits up to 4 ships; Tier 3 hits all synced ships.

Vorn - Ion Overload: All ion weapons reload at once; this round, shield damage dealt by synced ships spills over to hull at 50% efficiency instead of stopping when shields hit zero. Reuses: hunt reload, standard damage routing. Tier scaling: Spillover scales 25% / 50% / 75%.

Reyes - Relay Drones: Every launch ship deploys an extra drone wing if there is room; friendly drone wings extend the command ship's 3-hex "Synchronized fire" aura around themselves and strike again this round. Reuses: scramble wing spawn and extra strike, Synchronized fire radius check. Tier scaling: Extra strike damage scales +0% / +25% / +50%.

Maren - Capacitor Shunt: Redistribute all remaining fleet shield points evenly across synced ships, then restore 40% of max shields to each synced ship and grant +1 back-away movement. Reuses: iron shield refill, Synchronized fire back-away rule. Tier scaling: Shield restore scales 20% / 40% / 60%.

New rules flagged: Vorn's shield-to-hull spillover math and Reyes's mobile sync-radius anchor on drone wings.

Balance argument: All four commands depend on keeping the command ship alive and ships within 3 hexes. They match baseline template output when synced, but drop sharply in value if the enemy breaks the formation or snipes the flagship.

3. Ashfall Hullbreakers (Corsair)

Theme: Reckless gap-closing, point-defense saturation, and boarding chaos.

Grax - Full Burn: Every ship gains +3 movement, cannot be slowed by terrain or engine damage this round, and gains +50% ramming damage while cutting ram recoil in half. Reuses: surge movement buff, existing ram recoil rider logic. Tier scaling: Movement scales +2 / +3 / +4.

Sable - Saturation Barrage: All rocket pods reload at once and fire double salvos this round (overwhelming enemy point defense by volume), dealing +20% damage. Reuses: hunt reload and damage modifier, Close in rocket salvo logic. Tier scaling: Damage scales +10% / +20% / +35%.

Mott - Breach Pods: Every launch ship deploys an extra assault wing if there is room; all squadrons immediately make a boarding attack against adjacent enemy ships instead of a normal weapon strike. Reuses: scramble spawn and extra activation, Close in boarding resolution. Tier scaling: Boarding strength bonus scales +10% / +25% / +40%.

Vesh - Scrap Patch: Every ship repairs 20% hull and patches damaged sections, gaining an extra 10% hull repair for each enemy ship within 2 hexes (scavenging debris in close range). Reuses: restore hull heal and section patch, range check. Tier scaling: Base heal scales 10% / 20% / 30%.

New rules flagged: Mott's squadron-triggered boarding action (allowing wings to execute boarding combat rather than standard fighter attacks).

Balance argument: Hullbreakers lack lances and heavy shields, so their commands front-load mobility and point-blank burst. Vesh's heal starts weaker than restore (20% vs 25%) and only beats it when brawling at knife-fighting range.

4. The Chorus (Chorus)

Theme: Sacrificial bio-mass, mid-combat regeneration, and swarm synergy.

Voice - Spine Storm: Every ship fires a free bio-weapon volley; each hit strips 10% armor/hull resistance and triggers a minor "Feed" heal (3% hull) on the firing ship. Reuses: barrage free attack, Feed heal logic. Tier scaling: Heal per hit scales 1% / 3% / 5%.

Razormaw - Frenzy Spores: Every ship gains +2 movement, +1 turn, and deals +35% damage this round, but takes 10% of its current hull as self-damage at round end unless it scored a kill. Reuses: surge mobility, hunt damage buff, Feed kill check. Tier scaling: Damage scales +20% / +35% / +50%.

Matriarch - Brood Surge: Every launch ship spawns an extra bio-wing (ignoring normal wing caps by +1 per carrier), and all wings strike again with +40% damage. Reuses: scramble spawn and extra strike. Tier scaling: Damage scales +20% / +40% / +60%.

Mending - Flesh Knit: Every ship immediately triggers its "Feed" regeneration twice, patches all destroyed sections, and gains +35% hull damage reduction this round (replacing the useless shield refill of iron). Reuses: restore section patch, iron hull damage reduction, Feed tick. Tier scaling: Hull damage reduction scales 20% / 35% / 50%.

New rules flagged: Matriarch temporarily exceeding the carrier wing cap by 1.

Balance argument: Chorus has zero shields, so Mending replaces iron with hull damage reduction and double Feed ticks. Razormaw combines surge and hunt offense but balances it with self-damage if the player fails to secure a kill.

5. The Glasswrights (Ithar)

Theme: Untouched shield resets, hit-and-run repositioning, and beam precision.

Vaelen - Refracted Beam: Every ship fires a free beam volley; beam shots gain +25% damage if the firing ship currently has 100% shields. Reuses: barrage free attack, shield percentage check. Tier scaling: Full-shield bonus scales +15% / +25% / +40%.

Thorne - Phase Slip: Every ship gains +2 movement, enemy fire loses 25 accuracy against you this round, and ships can slip away after firing at zero movement cost. Reuses: surge movement and enemy accuracy penalty, Prism charge slip-away rule. Tier scaling: Accuracy penalty scales -15 / -25 / -35.

Aelith - Prism Drones: Every launch ship deploys an extra wing if there is room; all squadrons fire a synchronized beam strike (+40% damage) and return to dock immediately, protecting them from counter-fire. Reuses: scramble spawn and extra strike. Tier scaling: Damage scales +20% / +40% / +60%.

Mirelle - Mirror Overcharge: Immediately trigger "Prism charge" as if every ship were untouched (refilling shields to 100%), and grant +15% evasion this round. (Replaces iron without using Brace, which Glasswrights cannot do.) Reuses: iron shield refill, Prism charge full-restore logic, surge evasion. Tier scaling: Shield refill scales 60% / 80% / 100%.

New rules flagged: Aelith's instant post-strike squadron recall.

Balance argument: Glasswrights have fragile hulls and cannot Brace, so Mirelle and Thorne lean heavily into avoiding hull hits altogether. Once shields break, Vaelen's damage bonus turns off, keeping their burst conditional on clean positioning.

6. Eclipse (Deathless)

Theme: Temporal folding, armor-piercing null bursts, and wreck resurrection.

Sekhmar - Null Salvo: Every ship fires a free volley; null weapons ignore 100% of target armor and Brace damage reduction during this volley. Reuses: barrage free attack, armor-pierce flag. Tier scaling: Tier 1 ignores 50% armor; Tier 2 ignores 75%; Tier 3 ignores 100%.

Anuket - Fold Ambush: All weapons reload at once, and every ship may immediately fold-jump up to 3 hexes (passing through obstacles and ships) before firing with +25% damage. Reuses: hunt reload and damage buff, Archive restore fold-drive movement. Tier scaling: Fold range scales 2 / 3 / 4 hexes.

Khepra - Ablative Shroud: Every ship gains 45% hull damage reduction this round and immune status against critical hits and system damage. (Replaces iron shield refill for a shieldless hull-tanking faction.) Reuses: iron hull damage reduction. Tier scaling: Damage reduction scales 30% / 45% / 60%.

Nekhet - Archive Surge: Immediately trigger "Archive restore" on up to two eligible fallen ships at 50% hull (instead of waiting for next round at 35%), and repair 15% hull on all living ships. Reuses: Archive restore resurrection logic, restore hull heal. Tier scaling: Tier 1 restores 1 ship at 35%; Tier 2 restores 1 ship at 50%; Tier 3 restores 2 ships at 50%.

New rules flagged: Khepra's critical/system-damage immunity flag and Nekhet's multi-ship immediate archive trigger.

Balance argument: Eclipse lacks shields and relies on expensive, durable frames. Khepra provides a pure hull-tank equivalent to iron, while Nekhet trades restore's broad team heal for tempo-swinging mid-round ship reassembly.

Least-sure decision: Giving Eclipse's Nekhet a two-ship resurrection at Tier 3. In late-game boss or elite encounters, bringing back two heavy hulls mid-round could stall a fight or swing action economy too hard compared to a standard 25% restore heal.

Biggest risk: Power creep from stacking battle rules onto free-action commands (such as Vex getting automatic "Line of battle" triggers on a free barrage). If command numbers are tuned equal to old templates before factoring in the automatic battle-rule bonus, the new commands will outperform the PR 2038 baseline by 10% to 15%.

Question 2: Deployment Step

Metric | A: None (Keep as is) | B: Place-in-zone step | C: Formation pick
Player value | Low. Players are stuck with bad initial spawns (e.g., carriers in front, brawlers in back). | High. Lets players set up faction synergies (Sunward lines, Meridian 3-hex sync bubbles, Corsair flanks) before turn 1. | Medium. Solves obvious spawn errors quickly, but removes tactical agency for specific terrain or enemy layouts.
AI handling | Zero work. Existing spawn logic stays intact. | Low work if asymmetric: AI uses its existing pre-placed spawn logic while the player places inside a fixed back-rank zone. | Low work. AI either keeps current spawns or picks from the same 3-4 formation templates based on fleet composition.
Teaching load | Zero. No new UI or phase to explain. | Low. A highlighted hex zone with drag-and-drop or click-to-swap ships is intuitive in any hex tactics game. | Low-Medium. Requires naming and explaining what each formation preset does and why a player would pick it.
Build cost (agent runs) | 0 runs. | 2 to 3 runs (new pre-round state in combat state machine, zone highlight overlay, click-to-swap input handler, "Start Battle" button). | 3 to 4 runs (formation data schemas, layout solver for variable fleet sizes/hex obstacles, selection modal UI, preview ghosting).

Pick: Option B (Simple place-in-zone step), implemented asymmetrically where the enemy fleet is already visible on the board and the player swaps/places their ships within a 2-to-3-hex-deep starting zone before clicking "Engage."

Strongest argument against it: It adds 15 to 30 seconds of pre-battle friction to every single node in a roguelite run, and once a player finds their optimal faction setup (e.g., always clustering Meridian ships in a tight ball around the flagship), they will repeat the exact same manual drag-and-drop every fight.

Least-sure decision: Allowing the player to see the exact enemy layout before placing ships. Seeing the enemy setup makes placement much more tactical, but it lets veteran players hard-counter enemy torpedo lanes or flankers on turn zero, potentially inflating Veteran win rates above the 42.0% target.

Biggest risk: Map generation edge cases where asteroids or terrain blocks overlap the player's deployment zone, trapping large ships or leaving fewer valid hexes than ships in a swarm fleet.

Question 3: Called Shots Interaction

Commands should split cleanly into targeted volleys (which honor called shots) and autonomous/area effects (which ignore or override them):

Free-volley commands honor the shooter's active called shot: Vex (Broadside Salvo), Kassar (Networked Volley), Voice (Spine Storm), Vaelen (Refracted Beam), and Sekhmar (Null Salvo) trigger standard weapon attacks from each ship. If a ship has a priority section set in its target bar (Weapons, Midship, or Engines), its free volley should route damage to that section and pay the normal called-shot trade-off cost. However, Kassar's Networked Volley should have all synced ships inherit the command ship's selected priority section when firing at the marked target, turning Meridian into a coordinated system-crippling faction.

Squadrons, rockets, and rams override called shots: Mott (Breach Pods), Sable (Saturation Barrage), Grax (Full Burn), and all carrier wing strikes should ignore the player's called-shot selection and use their normal hit distribution. Rockets and swarm wings represent saturation damage rather than precision fire, and letting multi-hit rocket salvos or boarding pods stack +15 crit and forced system damage onto a single section would instantly shred engines or weapons in one activation.

Combo ruling (Sekhmar + Called Shots): Sekhmar's Null Salvo ignores armor and Brace mitigation, while called shots add +15 crit and force system damage. Allow them to combine, but cap system damage from a single free volley to one system disable per target per round so Sekhmar cannot strip both Weapons and Engines off a boss cruiser in a single unanswerable burst.

Least-sure decision: Making Kassar's Networked Volley share the command ship's called-shot target section across the whole fleet. It creates a strong thematic payoff, but if every synced ship hits Engines at once, it could trivialize boss fights by permanently immobilizing targets on round 2 or 3.

Biggest risk: UI state confusion during free volleys. Because commands fire across the entire fleet at once, players may not realize which priority section each individual ship had selected from the previous turn, leading to wasted called-shot trade-off penalties on ships firing at poor angles.

Strongest Objection to This Brief

The brief assumes each faction needs 4 unique commands (24 new abilities) to make factions feel distinct, while simultaneously asking to preserve a tight PR 2038 balance window (within 3 percentage points of the mean across both difficulties). Designing, implementing, and tuning 24 brand-new abilities alongside a new deployment step and a new called-shots system at the same time will almost certainly break the PR 2038 balance equilibrium and require a massive follow-up balance pass. A cleaner approach would be one signature command per faction (6 total, scaled by tier) while keeping the existing per-admiral riders to differentiate the 4 admirals per faction. That cuts build and tuning surface area by 75% while still making every faction play around its unique battle rule.
