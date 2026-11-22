---
paths:
  - "godot/{scenes/battle,rules,fx,world,render,bench,audio,music}/**"
  - "docs/playbooks/{effects,deaths_and_hits,scale,sound}.md"
---

Read the [effects playbook](../../docs/playbooks/effects.md) for battle effects and the [sound playbook](../../docs/playbooks/sound.md) for audio.

## 6. Battle look

6.1 **Judge everything at the battle camera (camera 170, the radius Ryan plays at) at true pixel size, before any close-up.**
Why: review sheets were made closer than the camera can go (R157); Ryan plays at the standard radius and zooms in for effects
(R123). Set: Board (R157, R160); camera harness Ryan (R123c). Ids: R157a, program-02, skill-sv-01.

6.2 **Comfort is protected for everyone.** At most three big flashes a second, "big" by the W3C guideline's combined area in a
10 degree window, worked from a stated screen (default 32 inch at 24 inches); a reduce flashing option that keeps sizes and
softens the rise and fall. Tune inside the counter; never quote a strictness figure without doing the arithmetic. Why: WCAG
2.3.1 photosensitivity; Ryan: "Count by area" (R193). Set: Ryan (R187, R193); Board (R187b). Ids: R49d, R187b, uispec-04,
plan-08.

6.3 **Every explosion is route B: flash plus hot core.** Why: Ryan: "Far right in both for sure." (R170). Set: Ryan, Nov 10.

6.4 **Flame flashes and snuffs out: no flame over 0.70 s, no hot core at full heat over 0.25 s; this cap is for flame only.**
Sparks, debris, gas and cooling embers live longer, so hits throw things and leave marks. Why: fire looked wrong for space and
deaths felt sudden (R88); the cap had been applied to everything, so nothing was thrown (R193: "Flame only"). Set: Ryan (R88,
R158, R193). Ids: R88b, R158a, effects-03, deaths-02.

6.5 **Wrecks look blown apart, never sliced**: uneven pieces, no straight line across the hull, a missing bite where the core
went, ragged scorched rims, fragments between. A lance kill may stay cleaner along the beam. Why: "It's like straight lines and
even halves. It doesn't feel like an explosion or major hit happened." (R186). Set: Ryan, Nov 11. Ids: R186, deaths-05,
deaths-09, deaths-11.

6.6 **The kill moment holds and slows on cruiser, capital and flagship kills** (the camera stays through the core flash, a
short skippable slow beat). Why: "just do big ships and flagship for slow mo" (R73); "Hold and slow" (R193). Set: Ryan (R73,
R193); replaces the Board's R123 "the camera is never taken for a capital death". Ids: R73a, R123a, deaths-04, uispec-05.

6.7 **Effects start on the ship** (a hard point, a breach anchor or the hit surface), never at a box corner or in empty space.
Why: "random thrusters or smoke popped up away from the ship itself? it looks all wrong" (R150). Set: Ryan (R150); method
Board (R153). Built: the attach point service in godot/fx/fx_hull.gd (authored point, else surface ray, else skipped and
counted), checked by godot/fx/test/attach_check.gd (issue 370). Ids: R150b, R153, effects-05.

6.8 **Hits are weighty and readable at the battle camera**: mass-scaled shudder and kicks corrected by thrusters, damage on the
hull itself with per-weapon marks, wounds that cool to scars, thrown matter big enough to read at camera 170; light on
neighbouring hulls stays faint until the counter measures lit area. Why: "a simple cartoonish push back. It doesn't feel
weighty, cinematic or accurate." (R50); "it's just an orange shape with weird smoke, the actual underlying ship looks the same"
(R39); "Merge, then push harder" (R208). Set: Ryan (R39, R43, R50, R208). Ids: R39, R43, R50a, R208.

6.9 **No flat lines for fire or hits**: weapon fire and hits are baked sims (flipbooks), sparks are small glowing points with
curved, slowing trails. Why: "It looks so simple and like Microsoft paint." (R146). Set: Ryan, Nov 9. Ids: R146, R90a.

6.10 **A bigger ship dies longer, not just larger; each faction breaks its own way; the flash core stays near white so a death
always reads as a death.** Why: every faction died the same faint puff (deaths_and_hits.md). Set: Board, Nov 11, from Muse's
staging table; the sizes and times are tuning values (0.4). Ids: deaths-03, deaths-10. Detail:
docs/playbooks/deaths_and_hits.md. R367 (Ryan, Nov 20 2026, decision card: "Full faction deaths"): each metal faction dies in its
own colours and break as deaths_and_hits.md "How each faction dies" describes, replacing the shared orange fire; the colours
come from faction_looks.json, the one faction colour file (Eclipse violet-white and white-gold, not green). Built for the
Glasswrights and Eclipse in issue 1399; the Crusade, Hegemony and Hullbreakers follow.

6.11 **Shields in space keep their faction colours; at rest, Rim and Gap: a faint rim in the faction edge colour on live
sides, a dark gap where a side is open, nothing else** (R246, Nov 14). Why: his Oct 24 ruling (the cyan-only rule retired) and his
Rim and Gap pick with Muse (R246). Set: Ryan (R3, R246). SUPERSEDED, kept so nobody follows it: "at rest invisible, a faint edge
glow on zoom, hover or a recent hit" (R163, ended by R246). Ids: R3a, R163a, R246, effects-04.

6.12 **Effects may spend the RTX 5080's headroom inside the scene gate, with a lower setting kept.** Set: Ryan (R88c). See
3.9.

6.13 **Plasma is light blue.** Why: his call on the damage marks reference (R46). Set: Ryan, Oct 26. Ids: R46a, lore-04.

6.14 **Normal hits mark the hull (scorch, wounds, scars); a hull opens into a real break only when a section is nearly gone or
on death.** 20 percent of a section's hull is the starting value, judged by eye. Why: cut-out holes on every hit "looked like
hollow cardboard" (Nov 1 playtest). Set: Ryan (R80, R216).

6.15 **Section damage tint may show on small ships if it reads at camera 170**; the hits pass tries it by eye on frigates (the
old ban had no reason and is retired). Set: Ryan (R80, retired R216).

6.16 **Spend death effect cost where the eye is (the tell, the break, the core flash); long cooling stays cheap.** 2 s and 14 s
are starting values. Why: deaths now run 3.5 to over 10 seconds in three beats (R186, R193). Set: Ryan (R90, R216).

6.17 **Turret guns turn to face their target when they fire; fixed side guns (casemates, broadside batteries) stay fixed.**
A turret traverses smoothly (never snaps, RULEBOOK 7.1), within its arc, and returns to rest; the gun's muzzle and its effects
start at the turned barrel. Why: today every gun is a fixed mesh (no aim code in godot/render/ship_view.gd or
godot/fx/fx_weapons.gd); turning turrets make a fight read and suit the detailed guns now being built (R217). Set: Ryan, Nov 11
(R219: "I agree with your design on turrets"). A turret may turn aft only to follow a target its rules arc lets it hit
there; at rest no gun ever points backward (4.2). Set: Ryan, Nov 12 (R222: "yes agree on your turret facing rule"). Built (issue 560): a turret is its own node in the ship's glb
(docs/ship_pipeline/HARDPOINTS.md "Turrets"; the kit marks it, tools/blender/kits/README.md); the attach point service in
godot/fx/fx_hull.gd turns it, checked by godot/render/test/turret_check.gd. Hulls exported before it keep fixed guns.

## 7. Movement

7.1 **Movement is never sudden, jerky or stop-start, and feels like space**: thrusters fire wherever a ship would need them
(braking, turning, stopping a turn, sliding). Why: "I don't want things to look jerky and the smooth call was because movement
was very stop/start and sudden. Thrusters should be involved when it makes sense on braking and turns." (R189). Set: Ryan,
Nov 11. Replaces the letter of R76 ("thruster puffs only on turns, no side-to-side shuffle"). Ids: R76a, R189a, movespec-01.

7.2 **The main engine does the travelling.** A one-hex sidestep or back-off may slide on thrusters; a longer run turns its nose
onto the course and burns the main engine; anything flown on thrusters alone is visibly slower and gentler. Why: "for one tile
over, it tracks but not when they're going like 3-10 tiles down just almost skating on thrusters" (R195). Set: Ryan, Nov 11.

7.3 **One ship moves at a time, at a weighty pace (about twice as slow as Nov 1); longer enemy turns are accepted; cinematic is
the default with a brisk option.** Why: "I don't want to sacrifice the feel of the game/space/the ships." (R50). Set: Ryan
(R50, R64); option Board (R50d). Ids: R50b, R50d, R64a, movespec-06.

7.4 **Movement playback never changes rules results.** A LOOK change keeps the route, end hex and facing; a RULE change (route
or facing) needs Ryan's own ruling and touches the Godot rules (R405). Why: R188's frame for the audit. Set: Board, Nov 11 (R188).

7.5 **No roll into turns.** Why: nothing in space leans a ship; the audit reversed the earlier bank (movement_audit_code.md).
Set: Board, Nov 11. Id: movespec-04 (the 4 degree bank, retired).

7.6 **Flip and burn stays off for now, to be looked at again now that braking jets are on screen.** Why: left alone on the
Board's advice (R193). Set: Ryan (R64, R193). Ids: R64c, feel-02.

7.7 **Every number in contrib/opus/briefs/movement_spec.md is a tuning value chosen by eye from motion strips.** Set: Board
(R189's rewrite). Ids: R131a, R131b, movespec-02, movespec-03, movespec-05, movespec-07.

7.8 **Strike craft move like small agile craft (quick turns, short burns), still never jerky.** Why: small craft should feel
quick, inside 7.1 (R189, R195). Set: Ryan (R55, R216).

7.9 **Firing ends a non-Glasswright ship's movement for that activation: no move, turn in place or ram after it fires.**
Glasswright ships keep their post-fire move budget, and a turn after firing spends it. Admiral tree skills that hand out
movement after firing (Fleet Elsewhere, The Wall Moves) add to that same budget. A free turn granted by an admiral tree skill
(Cut and Turn, Fleet Elsewhere, Trophy Standard) still turns a ship after firing; that skill is the exception it grants (Set:
Ryan, Nov 22, R397). Why:
Ryan, "Agree no" (issue 1560 item 14) and "Yes agree on skills". Set: Ryan, Nov 22 (R396, R397). Code: canRotate and ramInfo in both rules twins.

## 8. Battle sound

8.1 **A battle sounds clean and tactical; never thin and weak, cheesy or arcade-like, harsh or annoying.** No zaps, pews,
rising whooshes or stock explosions; weight in the low and low-mid with a soft top. Why: "The sounds that I've heard from the
game so far are bad" (R163). Set: Ryan (R163, R171). Ids: R171b, program-13, sound-01, sound-03.

8.2 **Weapons stay dry; big moments get weight**: deaths, capital hits and shield breaks get tails, sub-bass, a bed for the
length of the picture, ducking under the core flash and a beat of near-silence after a capital dies. Why: "short and dry" was
built as no tails, so a ten second death had a one second sound (audit item 9); Ryan said "Go, in my order" (R193). Set:
Board's reword, Ryan's go (R187, R193). Id: sound-02.

8.3 **The gun chooses the sound of its hit**, by weapon and by what it struck. Why: one family of hit clips played whatever
fired (audit item 8). Set: Ryan's go (R193); built in issue 506.

8.4 **Variation: a cue heard often never plays the same take twice in a row; four takes is the starting count.** Set: Board
(reworded from "at least four"). Id: sound-04.

8.5 **Free and licensed sources only; music from free licensed tracks first; in battle brass and tactical percussion, a synth
drone on the map.** Why: money and licences (3.8); his picks of Muse's decision pack ("For muse picks, agreed on all counts",
R37). Set: Ryan (R37, R40). Ids: R37b, R40a, sound-05.
