# Blind Rey leg: destruction, physics feel, and camera red team

Evidence: PACK.md only (sections 1 to 8). No other sources used.
Fx audit items E3 to E7, E13, E33, A7, A17, A19 are used as
given and not re-derived. Settled rulings (breakable by design,
deaths space-real, Dead Star background only, movement spec
under issue 210) are treated as facts, not items.

## 1. Verdict

THE GATES HOLD ONLY WITH REPLACEMENTS.

The design intents underneath these stacks are mostly sound
and several are owner-ruled (R88 space-real deaths, the ram
intent line in PF4, the reaction shape answering the R50
complaint in PF2). What does not hold is the numbers'
authority: 36 of the 40 inventoried items are ASSUMED or
ANCHORED (OBSERVED, PACK section 2), the MEASURED column is
zero, and under the Nov 6 ground rule assumed and anchored
numeric gates stop binding. The stacks therefore hold as
design intent and as the four DERIVED items' arithmetic, and
fail as binding numeric law. The replacements are mostly
cheap and mostly already built (probes exist, PACK section
6 H8): paired captures, one Monte Carlo, a handful of Opus
runs to state facts nobody has stated.

The three items the verdict most depends on:

- CM1 (the 170-unit camera radius, ANCHORED). One ported
  default denominates the readability math of two adopted
  standards and appears a second time as a floor in the JS
  overview formula (CM9). If the owner does not actually play
  at 170, every readability conclusion built on it is wrong
  by the ratio, multiplicatively. This is the anchor pattern
  in its purest form and the single highest-leverage fix in
  the pack.
- DS7 (the capital freeze, ASSUMED). In physics mode the
  showcase capital deaths produce frozen pieces while frigate
  pieces tumble. The spectacle order the whole DS14 constant
  set exists to buy is inverted by one implementation flag,
  invisibly to every per-constant review. If this is wrong,
  the most expensive deaths in the game are the least
  physical ones.
- PF9 (the gravity well ghost). A settled owner ruling (Dead
  Star background only, no gravity mechanics) has live code
  against it in the frozen build and a verified fx hook in
  the port, with the Godot rules state unverified. Gates
  cannot be said to hold in a project where a ruled-out
  mechanic may ship by inheritance; every other ruling's
  authority is only as good as its code check, and this is
  the one place the record shows a ruling and code pointing
  in opposite directions.

## 2. Game dev lens

DS1. OBSERVED (PACK 3, DS1): the cap is denominated in wreck
count, not in any metric the engine charges (nodes, draw
calls, ms), and no measurement says when it binds. INFERRED:
a 20-ship board wiped completely yields 20 battle wrecks,
under the 24 cap, so the cap binds only if set-piece wrecks
(DS12) share the same list or battles run longer than one
board; whether set-piece wrecks count against it is NOT IN
PACK. The cap's real cost is not performance, it is the DS2
mismatch (rules hex blocks after the visual is freed).

DS2. OBSERVED (PACK 3, DS2): binds gameplay directly and in
the right denomination (hexes blocking movement and line of
fire), permanently and uncapped. The 0.7 size threshold has
no derivation, and which weight classes fall above or below
0.7 is NOT IN PACK, so the split between deaths that leave
terrain and deaths that leave nothing cannot be evaluated
from the pack. Cost if wrong: late-battle congestion in big
fights, compounding DS1.

DS3. OBSERVED (PACK 3, DS3): no performance bind; the bind
is epistemic. Godot cools at 14.0 s, JS disposes at 22 s and
stops burning at 25 s. INFERRED arithmetic: the tails differ
by a factor of about 1.6 to 1.8 for the same event, so owner
rulings about death feel describe different phenomena
depending on the build played. Battle round duration, the
denominator that would say whether any of these tails is
long or short, is NOT IN PACK.

DS4. OBSERVED (PACK 3, DS4): the clearest mis-denomination
in the pack. The 360 cap reads as a visual cap (fx E5) but
the engine charges it as physics step cost: 360 Jolt rigid
bodies with mutual collision. No physics step timing exists
anywhere in the record (PACK section 7, item 8). If the step
binds before rendering does in a multi-death frame, the
issue 207 scene gate work will attribute frame cost to the
wrong system.

DS5. OBSERVED (PACK 3, DS5): two unrelated spawn formulas
for the same event; the Godot formula yields 13 loose pieces
at weight 3 (pack's figure), the JS formula scales with hull
length into faction batches capped at 320 with shift()
eviction of older debris. Neither formula is derived from
either build's cap. In a multi-death frame the gap between
spawn rate and cap decides whose debris silently evaporates,
which is a gameplay-adjacent fairness point (earlier deaths
lose their evidence) as well as a look point.

DS6. OBSERVED (PACK 3, DS6): damp 0.0 linear and angular
means the physics integrates the spawn kick forever; tumble
is uniform random -6 to 6 rad/s per axis, about one
revolution per second on a single axis at the top of the
range. No performance bind; the bind is that there is no
decaying state in the system at all, so the first second's
energy is the whole battle's energy (pack's wording, and
the physics follows from damp 0 by definition). JS
fragments are slower (1.6 to 4.2 units/s) than Godot kicks
(2.0 to 6.0), another cross-build divergence.

DS7. OBSERVED (PACK 3, DS7): capital pieces are frozen
rigid bodies in physics mode; frigate pieces are not.
INFERRED: frozen bodies cost approximately nothing in the
physics step, so the freeze may be an unrecorded performance
decision; unfreezing capitals adds the largest bodies in the
game to the step with no measurement behind either state.
Piece mass (triangles / 400, floor 5.0) is a third definition
of ship weight alongside PF1 and PF10 (PACK section 6, H5,
confirmed against the item texts). Gameplay bind: none
direct; the cost lands on spectacle, which for this game is
a primary system, not decoration.

DS8. OBSERVED (PACK 3, DS8): four hand-set separation
speeds; the main piece at 0.7 units/s barely clears the
wreck centre. INFERRED arithmetic: at 0.7 units/s the main
piece moves about 1 unit in the first 1.4 seconds, roughly
the drift-and-cool beat for big hulls (1.6 s, DS14), so the
main piece has barely separated when the beat ends.
split_width at hull length x 0.04 scales the seam gap with
hull size; see the DS13 designer entry for where that
collides with a fixed 1-unit standard.

DS9. OBSERVED (PACK 3, DS9): exactly two secondaries on
capitals, 0.08 s after staged cuts, against an uncapped JS
cook-off. The Godot count denominates flash events, which
is what fx E6 budgets, so the two are coupled: the JS regime
in the frozen build spends against a budget its own code
never counted. No gameplay bind; the bind is flash budget
pressure and the cross-build split again.

DS10. OBSERVED (PACK 3, DS10): DERIVED, arithmetic stated
in code. The gameplay fact is the boundary: without the
chainBoom boon, a death damages nobody, so death positioning
carries no tactical weight outside one boon build. That is
a real bind, correctly denominated (hexes, flat damage,
rounds of burn), and it interacts with the Hegemony
flagship-anchor ruling: formations matter, but a flagship
dying inside its own formation is physically silent to it.

DS11. OBSERVED (PACK 3, DS11): ASSUMED by absence. No
performance bind. Gameplay: fire is a per-ship timer
everywhere it exists, so a burning ship is a hazard only to
itself; parking a burning ship in a formation is free. The
absence also means no spread constant exists to be wrong,
which is the one virtue of the current state.

DS12. OBSERVED (PACK 3, DS12): placement constants (up to 7
graveyard spots, at least 3 hexes apart) denominated in
hexes, the right unit for board design, but chosen with no
recorded weighing. Set-piece SOLID hexes block movement and
line of fire; the climb-over/dive-under rule (battle.js
427) softens movement blocking for ships that cannot stop
on a wreck hex. INFERRED: since wrecks cannot be targeted
or shot in any rule read, a wreck on a firing line is
permanent, unclearable cover; that is a strong tactical
rule hiding inside a presentation-adjacent item.

DS13. OBSERVED (PACK 3, DS13): DERIVED, kept by reference
per the pack's instruction. Game dev angle only: break
lines are where DS7 and DS8 physics happen, so piece count
and mass distribution (via triangles / 400 in DS7) are set
by these geometry clauses. The clauses themselves bind mesh
production, not frame cost. One cross-standard interaction
is flagged in the designer lens; no re-litigation here.

DS14. OBSERVED (PACK 3, DS14): as a set, no single constant
binds performance except slow-motion gating and shake
sourcing; the set's cost if wrong is order inversion, and
order is a system property, invisible per constant. The
paired capture the pack prescribes is the only settlement
shaped like the problem. Agree with the pack that it is the
cheapest high-information test in the DS stack.

DS15. OBSERVED (PACK 3, DS15): one convex collider per live
ship from 50 hull sample directions. INFERRED arithmetic:
50 directions over a full circle is one sample about every
7.2 degrees; on a long hull the surface between adjacent
sample directions can sit measurably inside or outside the
true hull, so debris clipping or bouncing off air are both
plausible and neither is measured. Cost side rides on DS4's
probe; accuracy side is unmeasured entirely.

PF1. OBSERVED (PACK 4, PF1): REACT_MASS [0.6, 1.0, 2.2,
5.0, 12.0] is the denominator for every hit reaction and,
through PF3's scaling, for every weapon's delivered shove.
It is denominated in class index, an internal unit, which
is legitimate for a feel parameter but means an error here
multiplies through the whole weapon set rather than showing
up in one place. Top to bottom ratio is 20 to 1 (arithmetic
from the pack's table).

PF2. OBSERVED (PACK 4, PF2): five timing tables by weight
class, designed against the R50 complaint, never A/B
captured. The pack notes capital recovery at 1.5 rad/s
leaves a kicked capital visibly recovering seconds later.
INFERRED: because the game is turn-based (rounds and
activations throughout the pack), a long recovery tail does
not cost real-time performance; it costs perceived pace and
risks being read as persistent damage during the next
activation. That interaction is the item's real gameplay
surface and no document examines it (pack's point, agreed).

PF3. OBSERVED (PACK 4, PF3): the table embeds an ordering
claim (star 6.5 shoves harder than torp 6.0; only ram 8.0
shoves harder than either) that no document argues.
INFERRED arithmetic: a critical plasma hit delivers
0.7 x 1.6 = 1.12 before class scaling, more than a
non-critical macro cannon at 1.0, so the crit multiplier can
invert the table's own ordering on any given hit. The 0.5
default for unlisted weapons is a silent gate: any future
weapon ships with an unchosen shove unless a review catches
it.

PF4. OBSERVED (PACK 4, PF4): DERIVED. The arithmetic is
fully stated and the intent line is in code ("rams hit hard
but can't one-shot a healthy ship"), enforced by the 40
percent of full hull cap. INFERRED arithmetic: at size 1,
base damage is 60 before run-up, faction, shield and armor
terms; whether the cap or the base binds on typical targets
depends on fleet hull values, which are NOT IN PACK, so the
Monte Carlo the pack prescribes is genuinely necessary
rather than decorative.

PF5. OBSERVED (PACK 4, PF5): DERIVED. Recoil asymmetry
(0.35 vs 0.5) is faction identity expressed as a physics
discount for RAM_FAC factions. ramSplash can kill
neighbours (killUnit is called), so a ram is also an area
weapon under a boon; that consequence is denominated in the
same arithmetic and rides on PF4's constants being right.

PF6. OBSERVED (PACK 4, PF6): the appetite thresholds (AI
rams when the estimate kills, or reaches 30 percent of
target hull for ramming factions, 45 percent for others)
are ASSUMED constants denominated in percent of target
hull. They decide how often the player ever sees the game's
most physical move, which makes them presentation gates as
much as AI gates (pack's point). Gameplay cost if wrong:
ram frequency in every bot and opponent battle is set by
two numbers nobody simulated.

PF7. OBSERVED (PACK 4, PF7): ASSUMED by absence, verified
across three files read for the pack. No bystander impulse
means the largest event in the game has zero physical
effect on the ships beside it. INFERRED: any future impulse
must be visual-only through the PF1 reaction path, because
a rules-side shove would fight hex occupancy (PF8); the
pack's prototype settlement implies this but does not state
it.

PF8. OBSERVED (PACK 4, PF8): ASSUMED by absence. Hex
occupancy is the correct rules denomination for a hex board
and physics ship-to-ship collision would fight it; the
current design (pass-through with altitude flavour) is
coherent at rules level. The exposure is purely visual:
interpenetration at close zoom (camera reaches 26 units,
CM2), which is a screenshot risk, not a simulation risk.

PF9. OBSERVED (PACK 4, PF9; PACK section 7, item 2): the
frozen JS implements the full well (WELL_RIM 3, WELL_PULL
5, WELL_ASSIST 6, WELL_DMG 7, killCause 'tidal'); the Godot
fx hook exists (fx.well; tidal deaths gain +3.0 velocity
toward it); whether the Godot rules port implements
wellTick is unverified. Gameplay cost if the port carries
it: a ruled-out mechanic (drag-in, tidal damage, slingshot)
is live on Dead Star maps in a build never playtested for
it. This is a correctness item, not a tuning item.

PF10. OBSERVED (PACK 4, PF10): ASSUMED constants in
ship_view.gd lines 447 to 500, including a mass parameter
clamped 0 to 1, default 0.5, unrelated to PF1's REACT_MASS.
The gameplay bind is duplication: if the issue 210 movement
spec lands without a boundary note, two systems both claim
the move's feel and the shipped behaviour follows whichever
the presentation layer kept. The spec's scope question is
issue 210's (fenced), but the boundary is unrecorded, which
is this item's finding.

PF11. OBSERVED (PACK 4, PF11): momentum inheritance exists
in three places at three scales; the JS coast cap (hex
width x coastCap 0.05, paraphrased in the pack as about a
tenth of a hex) clips any hit's slide regardless of impulse,
so in the JS build the PF1 and PF2 tables perform inside a
cap set in another file. Whether the Godot build carries an
equivalent slide cap is NOT IN PACK, which makes this a
latent H2 divergence as well as a feel constant. INFERRED:
if Godot has no cap, identical hits slide visibly further
in the port, and owner rulings from JS playtests misdescribe
the port.

PF12. OBSERVED (PACK 4, PF12; PACK section 7, item 3):
unclassified by design; the two squadron files were not
read. No gameplay assessment is possible from the pack.
The gap itself is the entry: the smallest craft class has
an unknown physics model in a pack that inventories every
other class's.

CM1. OBSERVED (PACK 5, CM1): ANCHORED. The 170.0 radius is
a ported default from the JS CamCtl (the Godot file header
says so), and 7.7 px per unit at 1080p (about 15.4 at 4K)
is computed at it and carried into the breakable synthesis
and the damage work. It denominates nothing the engine
charges; it denominates the standards. INFERRED: if the
owner's played radius is R, every readability figure in
those standards is off by a factor of R / 170; at a played
radius of 260 that is about 1.5x, enough to flip
pass/fail readability calls at the margin.

CM2. OBSERVED (PACK 5, CM2): zoom clamps 26.0 to 900.0 at
about 1.14 per notch. At 900 the whole 300 x 220 board is
backdrop; at 26 a frigate overfills the screen (pack).
Neither end has a recorded judgement and no readability
rule exists per zoom level (CM13). Performance bind: none
stated in the pack; the bind is that screenshots and play
at the ends are judged against standards computed at 170
(CM1).

CM3. OBSERVED (PACK 5, CM3): FOV 45, near 0.5, far 5000,
ported, fixed except under punch (CM6). INFERRED: "170
units" has no screen meaning independent of FOV; the pair
(radius, FOV) is the actual framing constant, and tuning
radius alone to fix a framing complaint chases half the
variable. Far plane 5000 against a 300-unit board binds
nothing.

CM4. OBSERVED (PACK 5, CM4): polar clamp 0.05 to 1.36 rad,
home 0.98; the top-down toggle goes to 0.05, about 3 degrees
off vertical (pack), so the view named top-down is oblique
on a hex board where true vertical is the tactical read.
Pan speed scales as r / 340, which at r 900 is about 2.6
units per drag unit (pack's figure), making the far zoom
end coarse to frame with. Orbit sensitivities are hand-set
and never compared.

CM5. OBSERVED (PACK 5, CM5): exponential approach rate 7.0,
1.7 while gliding; glide 1.1 s, zoom-in only; focus() snaps
with no glide; the JS controller framed shots over a
4-second window. INFERRED arithmetic: 4 / 1.1 is about
3.6, so the two builds disagree about hand-over stateliness
by more than a factor of three. Glide pulling in only is an
asymmetry a player feels on every focus change: arrivals
tighten, departures snap or drift (focus() behaviour,
OBSERVED).

CM6. OBSERVED (PACK 5, CM6): punch lives 0.6 s, summed kick
capped at 0.06 applied as fov x (1 - k), so the maximum
punch narrows FOV by 6 percent, 2.7 degrees off 45 (pack's
arithmetic). Deaths punch 0.018 (big) or 0.006, a third of
the cap or less. No performance bind; the open question is
purely perceptual and is NOT IN PACK: whether a 1 to 3
percent FOV change at battle distance registers at all.

CM7. OBSERVED (PACK 5, CM7): shipped trauma values picked
inside and outside the fx E33 ranges with no document
recording the picking. Falloff 1 / (1 + d / (120 x unit));
the pack's INFERRED figure of about 0.41 at d 170
recomputes correctly (170 / 120 = 1.42; 1 / 2.42 = 0.41),
so a death at the default radius still delivers about 40
percent of its shake. INFERRED further: amplitude is
0.06 x trauma squared, so a normal hit at trauma 0.18 gives
0.06 x 0.0324, about 0.002 in the offset formula, while a
big death at 0.45 gives about 0.012, roughly six times the
hit's amplitude; the squaring makes routine hits nearly
shake-free and concentrates all shake in deaths, a shape
nobody chose on purpose.

CM8. OBSERVED (PACK 5, CM8): hit pause depth 0.08 (8
percent of normal speed) inside a window set at 8 percent
of the punch duration, easing at lerp 0.6 per frame; death
slow motion separate at 0.48 s and speed 0.35. The fx E33
ranges (2 to 6 frames normal, 7 to 12 kills) describe a
shallower, shorter stop than a sustained 0.08 depth, and
A17's slow-motion proposals (50 to 80 percent speed) never
met the shipped 0.35 (all OBSERVED from the pack's
cross-references). Because the pause slows a shared effect
clock, one hit's pause taxes every concurrent weapon's
visuals (pack's if-wrong, mechanically entailed by a shared
clock).

CM9. OBSERVED (PACK 5, CM9): hand-over margin 0.22 leaves
the central 56 percent of the screen as the no-move band
(arithmetic: 1 minus 2 x 0.22 = 0.56, checks). The HUD-clear
fractions live in code, not in any UI standard, so a
constant owned by no standard governs how often the camera
moves on every activation. The JS overview formula's 170
floor is CM1's anchor appearing a second time as a minimum
framing radius (OBSERVED), independent corroboration of
hypothesis H1 from inside the inventory.

CM10. OBSERVED (PACK 5, CM10; PACK section 7, item 4): the
JS build runs vignette weight 2.0, stretch 0.2, and a
cinematic grade; no Godot equivalent was found in the files
read and board.gd was read only at its preload line, so the
Godot post state is unverified, not absent. The gameplay
bind is nil; the epistemic bind is total: owner screenshot
judgements across two builds may describe two different
looks, and nobody can say which build any given ruling
describes.

CM11. OBSERVED (PACK 5, CM11): ASSUMED by absence. No
directional hit cue exists in any file read. Gameplay: the
faction design is built on direction (facings, shield
quadrants, per the pack), and at the default radius much of
a 20-ship board sits at or beyond the screen edge during a
zoomed activation, so flank damage arrives via floating
text and the log, a beat late.

CM12. OBSERVED (PACK 5, CM12): ASSUMED by absence. No
kill-cam, letterboxing, or scripted death move exists; the
punch (CM6), slow motion (CM8), and glide (CM5) are the only
directed gestures and none targets a death. The fx audit
established the death as the most judged moment (E7, as
given); the camera does nothing for it. Whether that is a
deliberate RTS choice or an unmade decision is not in the
record, and that unrecorded status is the item.

CM13. OBSERVED (PACK 5, CM13): ASSUMED by absence. By the
pack's INFERRED scaling, a 41.6-unit capital is about 320 px
at radius 170 and 1080p and about 61 px at 900; the fx E10
10 px readability line silently stops applying somewhere in
between. The only camera-tied readability rule anywhere is
the asteroid and wreck hex marker (fx3d.js). So the mode
where fleet tactics actually happen, zoomed out, is the
least governed view in the game.

## 3. Domain designer lens

DS1. INFERRED: oldest-first recycling spends the wreck
budget in kill order, so the earliest deaths vanish first.
The first kill of a battle is often the narratively heaviest
(a flagship lost early, the ambush victim); a design-led
policy would retire the least significant wreck, not the
oldest. The cap number matters less than the eviction order,
and the eviction order was never designed at all (OBSERVED:
the code pops the front of the list, PACK 3, DS1).

DS2. INFERRED: permanence is good destruction design; a
battlefield that accumulates its dead is the R88 read. The
0.7 threshold splits that read by size with no stated craft
reason: below it, a death leaves no trace on the board at
all, so frigate deaths are board-events and capital deaths
are terrain-events. That split may be right, but it is
currently an accident of a decimal, not a designed contrast.

DS3. INFERRED: the cooling tail is the death's last
impression and the R88 chain explicitly asks for hot metal
glowing then cooling. Godot's 14 s against the JS 25 s
burn-out cuts that beat by nearly half; whichever the owner
judged as "right" in playtests, the other build's tail is a
different artistic statement wearing the same name.

DS4. INFERRED: 360 mutually colliding bodies is what sells
debris as physical rather than decorative; fragments that
bounce off each other read as matter. The designer's stake
is that a perf-driven cut here, made without a step
measurement, trades away the exact quality R88 bought, to
fix a cost nobody has shown exists.

DS5. INFERRED: piece count is the breakup's vocabulary. The
Godot formula's flatness (4 + weight x 3) gives a weight-3
capital 13 loose pieces, barely more than a frigate gets,
so the biggest hulls fragment the least per unit of hull.
The JS length-scaled formula at least grows with the ship.
Neither was chosen by looking at a death; the read differs
between builds for the same kill.

DS6. INFERRED: R88 asked for momentum-keeping debris. Damp
0 with tumble up to 6 rad/s per axis is not momentum-keeping,
it is energy-keeping: pieces spin at spawn violence forever,
which reads as pinwheels on small fragments. The craft
target is debris that leaves fast and settles into a slow
drift; the shipped constants cannot express the settling
half of that sentence.

DS7. OBSERVED (PACK 3, DS7) with INFERRED consequence: the
capital freeze is the single most expensive design error in
the pack if it ships as the record describes. Capital deaths
carry the largest choreography spend (DS14) and then hold
perfectly still in physics mode while a frigate's pieces
tumble past them. The eye reads motion as life; the game's
biggest deaths read as statues. Hypothesis H3 is confirmed
against the item text: the inversion is real on paper and
only a paired capture can say how it reads in motion.

DS8. INFERRED: a main piece separating at 0.7 units/s while
secondary pieces leave at 2.1 to 3.5 produces a specific read:
the hulk hangs together and sheds. That could be the correct
capital read (a wreck that drifts in place, matching the
battle.js log text the pack cites). The craft problem is
that nobody picked it as a read; it is four numbers that
happen to imply one.

DS9. INFERRED: "never a per-piece fire loop" is a real
artistic position, restraint over spectacle noise, and two
staged secondaries is a defensible choreography. But 0.08 s
after the cut is not staging a viewer can parse as staging;
the secondaries land inside the cut's own flash. The JS
cook-off errs the other way. The design space between them
(capped, spaced cook-off) is unexplored by both builds.

DS10. INFERRED: boon-gating chain damage is a legitimate
build-identity choice, and the flat, bounded arithmetic
keeps it legible. The design gap is the general case: a
capital's death being safe to stand next to undercuts the
fiction every other system is selling (mass, heat, stored
munitions). Whether silence is the design or the omission,
it should be a recorded decision because DS11 hangs off it.

DS11. INFERRED: fire that cannot spread reads as a status
icon, not a hazard. R88's venting-and-burning read is about
credible threat; a burning neighbour that can never threaten
you drains the credibility. That said, spread is also the
kind of mechanic that punishes formation play, which the
Hegemony anchor ruling rewards, so the designer's answer is
genuinely two-sided and belongs to the owner with DS10.

DS12. INFERRED: the derelict set accreted into a coherent
board language by luck: wrecks block, set pieces anchor,
graveyards flavour. The unexamined part is density. Seven
pre-placed wrecks on a graveyard map, plus battle deaths
converting to hulks (DS2), means the board's obstacle count
grows monotonically; a design pass would state a target
obstacle density per map kind, and none exists in the record.

DS13. INFERRED (flag, from pack constants): a possible
destruction consequence the standards missed. DS8's seam
read, split_width, is hull length x 0.04; CM13 gives a
capital length of 41.6 units, so a capital's seam read is
about 1.66 units, wider than D22's owner-ruled 1-unit break
clearance with reserved rim bands. On the largest hulls the
separation gap can swallow the very rim band the standard
reserves, at exactly the break line, at exactly the moment
the hot edge should read. The pack says the 169 recordings
are the standing settlement for these clauses; the flag is
checkable there. Otherwise KEEP by reference, as instructed.

DS14. INFERRED: the set is the spectacle contract stated as
numbers: more cuts, longer beat, bigger shake and punch,
slow motion, for bigger hulls. Read as a contract it is
coherent; the failures are inside it (DS7's freeze breaks
the contract's own promise). A designer reviewing constants
one at a time would approve every row and ship the inversion.

DS15. INFERRED: debris bouncing off hulls is a small,
expensive-feeling physical truth; debris clipping through a
hull edge on camera is the opposite, and it happens at close
range where deaths are watched. The 50-direction figure was
set by nobody against a shot. This is a polish item whose
wrongness is disproportionately visible relative to its cost.

PF1. INFERRED: the table's shape (steep rise, 12.0 top) is
the game's weight thesis: mass you can see. The craft risk
is the top of the table: "barely move" and "do not move" are
different reads, and at 20 times the bottom entry a capital
may cross from stately to inert, which reads as the hit not
registering rather than the ship being massive.

PF2. INFERRED: this is the most deliberately designed table
in the pack (it answers a named complaint, the R50 cartoon
push back, with onset, arrest, and critically damped
recovery). The shudder frequencies falling with mass (11 Hz
down to 4 Hz) are the right instinct for weight. The unjudged
risk is the recovery tail: a capital still settling seconds
later can read as ongoing damage, which taxes the damage
read the breach system (fx cross-references) works to keep
clean.

PF3. INFERRED: impulse ordering is weapon identity taught
through the hands: players learn what is heavy by what
shoves. Star above torp may be a deliberate fiction (a star
bolt is a lance of plasma, a torpedo is a can), but no
document argues it, and the crit inversion (plasma crit
out-shoving macro) teaches noise over identity on the hits
players remember most, the crits.

PF4. INFERRED: the 40 percent cap shapes ram drama
correctly: a ram is a finisher and a commitment, never an
opener that deletes a healthy ship, and the code comment
says the intent out loud. The run-up steps give the move a
visible wind-up economy (longer run, harder hit) that a
player can read and fear. This is the pack's best example
of an assumed-constant set wearing a stated design intent;
the constants still need the Monte Carlo to be believed.

PF5. INFERRED: recoil is what separates a collision from a
spell. Base 0.5 says the rammer visibly pays for the move;
the 0.35 discount for ramming factions is identity you can
feel (their ships are built for this) rather than a lore
line. Splash kills through a boon extend the fantasy
without making every ram an area weapon.

PF6. INFERRED: appetite thresholds are encounter design.
At 45 percent for non-ramming factions, the AI rams only
near-dead targets, so the player experiences rams as
executions; at kill-only they'd be rarer still. If the
design wants rams feared as openers, the thresholds forbid
it. The number is doing narrative work nobody assigned it.

PF7. INFERRED: the strongest single feel gap in the PF
stack. A capital dying beside your flagship should move
your flagship, if only a tremble through the PF1 table. Its
absence is the physical half of hypothesis H6: choreography
(E7) can stage the death, but the world not reacting makes
it read as a light show. The fix must denominate through
REACT_MASS so heavier bystanders move less, which also
starts paying down H5's three-mass problem.

PF8. INFERRED: pass-through with altitude flavour is the
honest choice for a hex tactics game and reads fine at
battle distance. At 26 units it will eventually produce a
screenshot of two hulls occupying the same space, and that
screenshot will be judged as a bug. A recorded decision
("pass-through is deliberate, readability over physics") is
worth more than a physics system here.

PF9. OBSERVED (PACK 4, PF9): no designer case may be made
for the well; the owner ruled it background only. The
design note is narrower: the fx hook (+3.0 velocity toward
the well on tidal deaths) means the presentation layer is
already telling a gravity story the rules layer was told
not to tell. Consistency, not reinstatement, is the ask.

PF10. INFERRED: the no-banking rule, thruster discipline
(main drive only pushing ahead, retro for braking, lateral
pairs for sidesteps), and the small settle overshoot are a
considered movement aesthetic: ships as mass, not aircraft.
The craft risk is orphaning: if the issue 210 spec rewrites
move timing while these presentation rules sit outside it,
the aesthetic survives in fragments and nobody can say
which document owns the feel of a move.

PF11. INFERRED: momentum inheritance for pieces and hulks
(death_velocity) is the correct instinct and the hulk fire
drift figures (0.45 along axis, small angular velocities)
are admirably restrained next to DS6's debris violence. The
JS coast cap is the opposite instinct: it guarantees the
board never lies, at the price of hits reading as vibration.
Two different philosophies of the same shove, one per build.

PF12. INFERRED: squadrons are where a physics model is most
visible per pixel (small craft, fast, close together). If
wings move on rails while everything else drifts and
tumbles, the contrast will read. If they have a model,
nobody has inventoried it. Either way the design record is
silent about the most numerous movers on the board.

CM1. INFERRED: 170 units at FOV 45 is the game's default
composition, the frame every screenshot and sheet assumes.
It was inherited, not composed. A composed default would be
chosen by what it shows at 4K: how much board, how large a
capital reads, how much sky. The designer's objection is
not that 170 is wrong but that no one has ever looked at
alternatives on purpose.

CM2. INFERRED: the zoom range's ends are two genres: 900 is
a map, 26 is an inspection bench. Both are legitimate; the
craft gap is that readability, framing, and even which UI
matters differ by end, and only the middle has standards.
A designer would at minimum declare which end the game is
composed for; CM13 shows that declaration was never made.

CM3. INFERRED: FOV 45 is a mild, undistorted choice; paired
with the punch channel (CM6) it is also the punch's canvas.
Treating radius as the framing variable and FOV as plumbing
is how a project tunes the wrong knob for a season.

CM4. INFERRED: the oblique "top-down" is a small dishonesty
with a real benefit: 3 degrees off vertical keeps hulls
readable as objects rather than plans. It may be the right
call. But on a hex board, players use top-down to judge
geometry, and a view that quietly is not top-down should be
a decision with a name, not a clamp value.

CM5. INFERRED: glide is the camera's manners. A 1.1 s
in-only glide with snapping focus() departures feels
decisive; the JS 4 s window feels ceremonial. For a
turn-based game where hand-overs happen every activation,
manners compound: hundreds of small whips or hundreds of
small ceremonies. Neither was ever watched side by side.

CM6. INFERRED: a 6 percent cap, with deaths spending 0.006
to 0.018, risks being a gesture below perception, polish
that exists only in code. If the paired capture shows it
does not read, the honest options are raise it until it
reads or cut it; keeping an invisible accent is the worst
branch. Doubling variant in the DS14 round settles which.

CM7. INFERRED: the falloff's flatness (about 40 percent of a
death's shake delivered at default radius) means the board's
far side constantly comments on your framing. Some of that
is good (the battle feels connected); too much and the
player's own action loses punctuation. The squared amplitude
concentrating shake in deaths is a defensible shape arrived
at by accident.

CM8. INFERRED: depth 0.08 is a very heavy stop, near freeze,
and it is applied inside a window tied to the punch
duration; on kills the separate slow motion at 0.35 speed
for 0.48 s is actually the gentler channel. The recorded
ranges (E33, A17) describe a lighter touch than the shipped
build delivers, so the shipped feel may be more staccato
than any document ever asked for, one candidate among H6's
physical explanations for "sudden, jerky".

CM9. INFERRED: the 0.22 margin says the camera tolerates
action across the central 56 percent before moving. That is
a calm camera, arguably right for a tactics game. The
HUD-clear fractions being code rather than standard means
the composition contract between UI and camera exists
nowhere a designer can review it.

CM10. INFERRED: vignette and grade are not garnish; a teal
shadow and warm highlight grade is the difference between a
render and a look. If the Godot build lost it in the port,
every "the game looks flat" judgement since has been
diagnosed in the wrong systems (paint, detail, lighting)
while the grade sat missing. Establishing the state is the
cheapest possible look investigation.

CM11. INFERRED: in a game about facings, being hit from an
unseen direction and learning it from a log line is a
broken feedback loop. The hull's own damage visuals show
where the hit landed, not where it came from. A minimal
edge cue is a standard, cheap answer; its absence being
unrecorded makes it an oversight until ruled otherwise.

CM12. INFERRED: there is a real craft position for the
status quo: an RTS camera belongs to the player, full stop,
and the death plays in the player's own framing like
everything else. There is an equally real position that the
game's signature moment deserves one directed beat. The
pack's finding is that the record holds a default, not a
decision (hypothesis H7); the designer lens cannot settle
which position is this game's, and should not pretend to.

CM13. INFERRED: standards composed at 170 silently expire
as the player zooms out, and zoomed-out is where formations,
the Hegemony's whole game, are actually read. A capital at
about 61 px still reads; a frigate at a handful of pixels is
a marker, not a ship. Declaring the tactical zoom's
readability floor is design work that belongs with CM1's
ruling, not after it.

## 4. Agent lead lens

DS1. The cap hides in code (fx_death.gd _cap_wrecks); no
job's done-when reports wreck count against it, so a review
cannot see it bind. Settlement is cheap because the
destruction_fleet_probe already exists (OBSERVED, PACK 3,
DS1): one-time script build to log the count in a worst-case
wipe, and the same run answers whether set-piece wrecks
share the list (the NOT IN PACK point in the game dev lens).
One-time cost only.

DS2. Rules code is the most enforceable kind of gate in this
project: it is covered by the port's parity harness in
principle, and the hulk rule is a single line to test
(OBSERVED: battle.js 968). The unenforceable part is the
interaction with DS1, owned by no job. The DS1 capture
reporting rules hulks beside visual wrecks closes it with
no extra run.

DS3. Two builds, two lifetimes, no owning document: the
classic wasted-run pattern, because any future death-feel
job will tune whichever build it opens. Settlement (one
death sheeted at both lifetimes in the current build, one
owner review round, shared with fx E4's settlement) is
one-time and should also delete or freeze-mark the losing
build's constants so the duplication cannot regrow.

DS4. The highest-value measurement in the pack for pipeline
purposes: extending an existing probe to report physics
step ms at 360 bodies (one-time script build) produces the
first physics cost figure the project has, and it feeds the
issue 207 scene family where it can prevent a whole
misattributed optimisation round. Uncapped testing per the
owner's rule means also reporting a doubled body count, so
the cap's replacement is a measured curve, not a new guess.

DS5. Two formulas in two codebases, no sheet compares them;
any per-asset death review adjudicates counts by taste.
The paired capture (DS14) reports counts per class and
should be the last time counts are argued without data.
Cost rides on DS14's run.

DS6. Constants-only variants (shipped vs halved tumble with
damp 0.3) are the cheapest kind of settlement: one Codex run
produces both captures, one owner review round judges them.
No tooling build needed. Until it runs, every death review
re-litigates tumble from memory.

DS7. Invisible to per-constant review by construction: the
freeze is one boolean expression in a build block. Only the
paired capture exposes it, and the same run must report the
physics step cost of unfrozen capital pieces (one-time
script build on the existing probe, shared with DS4) so the
owner's ruling prices the spectacle honestly. If the freeze
turns out to be load-bearing for the step, the ruling is a
real trade; if not, it is a free fix. Either way one round
settles it.

DS8. No separate settlement: the DS7 capture should log the
four separation speeds alongside, so the round judges them
in context. Wasted-run risk is low; the risk is a future job
tuning speeds without the freeze context and re-inverting
DS14's order.

DS9. Settlement couples to the fx E6 salvo test's flash
logging (one Codex run, shared with the fx settlement,
OBSERVED PACK 3, DS9), so the marginal cost here is one
owner review round on a two-variant capital death capture.
Process note: two secondary regimes across builds is H2
again; the ruling should name the surviving regime in the
fx record so the frozen build stops being a second source.

DS10. Nothing to build and nothing to measure: the pipeline
risk is a future job implementing a general chain rule
because the boundary was never recorded as a decision. The
settlement is one owner question (section 6) and one line
in the record. Cheapest item in the pack to close, and it
stays open forever if nobody asks.

DS11. Same shape as DS10: an absence cannot be put in a
done-when. Folding it into the DS10 question costs nothing
extra; if the owner rules spread in, its constants get set
by capture at that time (one Codex run, priced then, not
now).

DS12. Terrain builds already queued (#139, #140, #100, per
PACK 3, DS12) will inherit the placement constants; if the
owner's graveyard and colossus play round (one owner review
round, wrecks and density reported) happens after those
builds, the constants get re-litigated per map instead of
once. Sequence the play round before the terrain jobs land.

DS13. Enforceable today: the D21 to D25 clauses live in an
adopted standard with a stated verification note, and the
169 build's recordings are the standing settlement
(OBSERVED, PACK 3, DS13). The DS13 designer flag (seam read
vs 1-unit clearance) is checkable against those recordings
with no new build; one Opus run to confirm or clear it
keeps the standard honest. No other cost.

DS14. The pack's own scheduling insight, agreed: run the
paired capture once and let DS5, DS6 (variant), DS7, DS8,
and CM6 hang off the same owner review round. Piecemeal
settlement of this set would cost five rounds to buy the
same information worse. One Codex run, one owner review
round, one-time.

DS15. Collider cost reporting rides on the DS4 probe build
at no extra run cost; the accuracy side needs one
close-range death capture, which the DS6 variant run can
carry. No standalone cost. The wasted-run risk is a future
debris job rebuilding colliders to a precision nobody
specified; the capture sets the spec.

PF1. One capture set (each weight class, same weapon)
settles the table's shape; shared with PF2 and PF11 in a
single owner review round. One Codex run to stage the
captures. Until then, hit-feel reviews adjudicate a
multiplier table from memory, and PF3 work built on it may
need rework.

PF2. Same capture set as PF1, judged per class; no extra
run. The agent lead point is sequencing: PF1, PF2, and PF11
are one job wearing three item numbers, and splitting them
across jobs would triple the review rounds for the same
footage.

PF3. One firing-range capture set (each weapon kind, same
target class): one Codex run, one owner review round.
Recurring process cost, stated separately: a standing review
rule that a new weapon may not ship on the 0.5 unlisted
default; the default should fail a check rather than pass
silently. That is a check in review, no runs attached.

PF4. The Monte Carlo is a one-time script build on the
existing sim and produces outcome distributions by matchup,
which is the first evidence any ram constant has ever had.
Re-tune authority sits with Opus as a rules call. One-time
cost; the same build serves PF5 and PF6, so three items
settle for one build and one Opus run to read the results.

PF5. No extra cost beyond PF4's run (recoil outcomes
reported in the same Monte Carlo, OBSERVED PACK 4, PF5).
The pipeline risk it closes: ram-faction AI behaviour being
tuned against recoil nobody had measured.

PF6. Appetite counts come from the existing G3 campaign
harness (OBSERVED, PACK 4, PF6): the one-time script build
shared with PF4 adds ram counting, and counts then accrue
whenever the harness runs for other reasons, so the
recurring cost is nil beyond runs already happening.
Threshold changes are an Opus call on those counts.

PF7. One Codex run for the prototype impulse, one owner
review round on a formation capture with and without it.
The prototype must route through PF1's table (designer
lens) or it adds a fourth mass definition and pays H5
interest. Priced as a prototype, not a feature: if the
capture fails, the absence becomes a recorded decision and
the item closes either way.

PF8. One close-zoom formation capture, which the PF7
formation capture round can carry at no extra run cost.
If it reads badly, the fix (a presentation offset rule) is
priced then; do not pre-build a physics answer to an
unconfirmed visual problem.

PF9. One Opus run to state the Godot rules state and remove
or confirm removal of the well. This is the only item in
the pack whose settlement is a fact, not a judgement, and
it gates trust in every other ruling's code state. It
should run before any Dead Star map work (#100 family) so
terrain builders are not building on a haunted rules layer.

PF10. One Opus run to add the boundary note to the issue
210 job naming which ship_view constants the movement spec
governs, inherits, or leaves. Without it, the spec's own
settlements cannot be verified, because a reviewer cannot
tell which constants were supposed to change. This is
documentation cost that prevents a full re-audit later.

PF11. Slide distances against any cap should be reported
by the PF1 capture set (no extra run); the same footage
answers whether Godot carries the JS coast cap, closing
the NOT IN PACK gap. If the builds diverge, one line in
the fx record (shared with DS3's cleanup) stops the
divergence being rediscovered per build.

PF12. One Opus run to read two named files and state
whether a squadron physics model exists. The cheapest
closure of a known unknown in the pack. If none exists, the
scope question joins PF10's boundary note at no extra cost.

CM1. The settlement is one owner play round (a battle at
170, one pulled back) plus one Opus run to re-denominator
the affected standards at the ruled radius. Every sheet and
capture review until then is denominated at an unchosen
distance, which is a standing tax on all other visual work
in the queue, including the environment audit's sheets.
Sequence this early among the CM settlements.

CM2. No standalone cost: the owner's ends are found inside
the CM1 play round. A clamp change, if ruled, is one Opus
run. The wasted-run risk is standards work (CM13) being
scoped to radii nobody uses; CM1's ruling defines the set.

CM3. No separate test (agree with the pack): the CM1 ruling
must record the (radius, FOV) pair or the re-denominated
standards will silently re-anchor on whichever FOV the next
builder ships. One line in the Opus run that restates the
figures.

CM4. Judged inside the CM1 play round at no extra run cost.
The one item needing an explicit ruling is the top-down
floor: true vertical or deliberate oblique. Constants
re-set from that play, if at all, ride on CM1's Opus run.

CM5. One hand-over captured at both glide rates rides
inside the CM1 round's captures (one Codex run if the
captures are not already part of the play round). The
fourfold cross-build disagreement (H2) means the frozen
build's 4 s window should also be freeze-marked in the
record, shared with DS3's cleanup line.

CM6. The doubled-punch variant rides on the DS14 paired
capture at no extra run cost (OBSERVED settlement shape,
PACK 5, CM6). Agent lead note: an effect that cannot be
seen cannot be reviewed; if the capture shows the punch
does not read at either amplitude, DROP becomes the honest
disposition at that point, and this leg's RE-DERIVE below
carries that condition explicitly.

CM7. Shake logging per event against distance rides on the
DS14 round (amounts logged, one owner review round shared);
the E33 settlement absorbs the ranges themselves. The
falloff constant (120) is the part no other job owns, so
the logging must record distance per event or the data
cannot settle it later.

CM8. The E33 settlement battle carries the shipped values
as a third candidate (OBSERVED, PACK 5, CM8): one owner
review round shared with the fx settlement. No extra runs.
Until it runs, hit-feel complaints cannot be assigned
between the ranges (fx record) and the implementation
(this item), which wastes diagnosis on every feel report.

CM9. Judged from the owner's own hand-over experience in
the CM1 play round; if the fractions change, restating them
in the UI record is part of CM1's Opus run. The process
point: HUD-clear fractions should live wherever the UI
standard lives after this, so the next UI job does not
overwrite them from the layout side.

CM10. One Opus run to state the Godot post state (fact, not
judgement, like PF9). If the grade is absent, one screenshot
pair and one owner review round decide restoration. Until
the state is stated, look-related jobs across the queue are
building on an unverified foundation; sequence with PF9 as
the "state the facts" pair.

CM11. Owner direction question (section 6). If ruled in,
the cheapest prototype (edge cue toward the shooter) is one
Codex run inside the CM7 capture round. If ruled out, the
absence becomes a recorded decision and closes. Either way
the item stops being an oversight.

CM12. Owner direction question (section 6). Pricing both
branches: ruling "never take the camera" costs nothing and
closes the item permanently; ruling for a death beat makes
the prototype one Codex run (a framing glide on capital
deaths, judged in the DS14 round's format). The expensive
branch is the current one: leaving it unrecorded while
future fx jobs keep designing around an unknown.

CM13. Folds into CM1 and CM2 at no extra run cost; the
restating of which radii the standards cover rides on
CM1's Opus run. The wasted-run risk it closes: readability
work (already spent on two standards) being re-done when
someone finally plays zoomed out on camera.

## 5. Disposition table

Costs are in agent terms only. One-time and recurring costs
are stated separately. "Shared" means the run or round is
the same event as the item named; it is not a second cost.

DS1 | RE-DERIVE | Log wreck count against the cap in a
worst-case wipe on the existing destruction_fleet_probe,
including whether set-piece wrecks share the list; the cap
is then re-set from measured node cost or converted to a
reported count. One-time: one-time script build (probe
extension, shared with DS4). One owner review round, shared
with DS2. Recurring: none.

DS2 | RE-DERIVE | The permanence rule stands as design;
only the 0.7 threshold is re-derived, from the DS1 capture
reporting rules hulks beside visual wrecks. Any threshold
change is an owner ruling on that capture. One-time: no
extra run beyond DS1's; the shared owner review round.
Recurring: none.

DS3 | REPLACE | Two lifetimes replaced by one: a single
death sheeted at both values in the current build, owner
picks, and the other build's constants are deleted or
freeze-marked so the duplication cannot regrow. One-time:
one Codex run (both variants), one owner review round
(shared with the fx E4 settlement). Recurring: none.

DS4 | RE-DERIVE | Extend the existing probe to report
physics step ms at 360 bodies and at a doubled count
(uncapped, per the owner's testing rule); the cap is
replaced by that measured curve feeding the issue 207 scene
family, not by a new guessed number. One-time: one-time
script build (shared probe extension with DS1). Recurring:
none; the probe persists for future jobs.

DS5 | REPLACE | Two spawn formulas replaced by one spawn
law in the current build, set from piece counts reported
per class in the DS14 paired capture. One-time: no extra
run beyond DS14's Codex run and owner review round.
Recurring: none.

DS6 | RE-DERIVE | One death captured at shipped constants
and at halved tumble with damp 0.3; the constants that
survive are the ones the owner picks from that pair.
One-time: one Codex run, one owner review round (may share
DS14's round). Recurring: none.

DS7 | REPLACE | The freeze is replaced by unfrozen (or
drift-only) capital pieces in physics mode, unless the DS4
step measurement proves the freeze is load-bearing, in
which case the trade is put to the owner with numbers.
Judged on one capital death captured frozen and unfrozen.
One-time: one Codex run, one owner review round (shared
with DS14), probe build shared with DS4. Recurring: none.

DS8 | RE-DERIVE | The four separation speeds are judged on
the DS7 and DS14 captures with speeds logged, not in
isolation. One-time: no extra run; shared owner review
round. Recurring: none.

DS9 | RE-DERIVE | Capital death captured at exactly two
secondaries and at a capped cook-off, judged against the
flash count from the fx E6 salvo test; the surviving regime
is named in the fx record so the frozen build stops being
a second source. One-time: one Codex run (shared with the
fx E6 settlement), one owner review round. Recurring: none.

DS10 | KEEP | DERIVED: the boon mechanics and their
arithmetic stand as stated. The open boundary (silence
without the boon) is not resolved by this leg; it is put to
the owner as question 2 in section 6, and a ruling for a
general rule reopens this item at that point. Cost: none.

DS11 | REPLACE | The unrecorded absence is replaced by a
recorded ruling, taken with DS10 as owner question 2. If
spread is ruled in, its constants are set by capture at
that time. One-time: no build cost for the decision; one
Codex run only if ruled in, priced then. Recurring: none.

DS12 | RE-DERIVE | Placement constants (7 spots, 3 hexes)
re-set, if at all, from the owner playing one graveyard and
one colossus battle with wreck density reported; the
interaction set (blocking, no targeting, no in-battle
salvage) stands unless that play rules otherwise. One-time:
one owner review round. Sequence before the terrain jobs
(#139, #140, #100) land. Recurring: none.

DS13 | KEEP | DERIVED, kept by reference per the pack's
instruction: D21 to D25 and the 171 bands stand, settled by
the 169 build's recordings. The one flag (designer lens:
split_width about 1.66 units on a 41.6-unit capital vs
D22's 1-unit clearance) is checked against those recordings.
One-time: one Opus run to confirm or clear the flag.
Recurring: none.

DS14 | REPLACE | The constant set's authority is replaced
by one paired capture: capital and frigate deaths at
shipped constants, side by side, judged as a set by the
owner. Constants that survive do so as a judged set, not as
individual incumbents. One-time: one Codex run, one owner
review round (the round DS5, DS7, DS8, CM6, and CM7 hang
off). Recurring: none.

DS15 | RE-DERIVE | Collider cost reported by the DS4 probe
build; clipping judged on one close-range death capture
carried by the DS6 run. The 50-direction figure is re-set
only from that evidence. One-time: no extra runs beyond
DS4's and DS6's. Recurring: none.

PF1 | RE-DERIVE | One capture set: a ship of each weight
class hit by the same weapon, judged side by side; the
table is re-set from that footage. One-time: one Codex run
(staging), one owner review round (shared with PF2 and
PF11). Recurring: none.

PF2 | RE-DERIVE | Judged per class on the PF1 capture set,
with explicit attention to whether the capital recovery
tail reads as motion or as damage. One-time: no extra run
beyond PF1's; shared owner review round. Recurring: none.

PF3 | RE-DERIVE | One firing-range capture set: each weapon
kind against the same target class; the ordering is re-set
from that footage and the crit interaction is judged
explicitly. One-time: one Codex run, one owner review round.
Recurring: a standing review rule that a new weapon may not
ship on the 0.5 unlisted default (a check in review, no
runs attached).

PF4 | KEEP | DERIVED: the formula and its stated intent
stand as the binding rule. Its constants earn continued
authority from outcome evidence: a Monte Carlo over the
shipped fleet tables reporting ram outcomes by matchup.
One-time: one-time script build (shared with PF5 and PF6),
one Opus run to read the results. Recurring: none. If the
Monte Carlo contradicts the stated intent, this converts
to RE-DERIVE under Opus as a rules call.

PF5 | KEEP | DERIVED: stands on the same terms as PF4;
recoil outcomes are reported in the same Monte Carlo run.
One-time: no extra cost beyond PF4's shared build.
Recurring: none. Same conversion clause as PF4.

PF6 | RE-DERIVE | Appetite thresholds re-set from the PF4
Monte Carlo plus ram counts per battle from the existing
G3 campaign harness; threshold changes are an Opus call on
those counts. One-time: counting added in PF4's shared
script build. Recurring: none beyond harness runs that
already happen for other reasons.

PF7 | REPLACE | The absence is replaced by a prototyped
bystander impulse: visual-only, denominated through PF1's
REACT_MASS so it tunes with the one mass table, judged on a
capital dying inside a formation with and without it. If
the capture fails, the absence becomes a recorded decision
and the item still closes. One-time: one Codex run, one
owner review round (carries PF8's capture). Recurring: none.

PF8 | KEEP | The rules-layer pass-through stands as design.
This item is ASSUMED by absence, so per the ground rule its
binding force is replaced by the owner's eye on one
close-zoom formation capture (carried in PF7's round): if
interpenetration reads badly, this converts to REPLACE with
a presentation offset rule, priced then. One-time: no extra
run. Recurring: none.

PF9 | REPLACE | The code ghost is replaced by a verified
code state matching the ruling: one Opus run states whether
the Godot rules port implements the well, and removes it or
confirms its absence, including the fx.well hook's status.
The ruling itself (background only, no gravity mechanics)
is settled and is not a disposition. One-time: one Opus
run. Recurring: none.

PF10 | REPLACE | The unrecorded boundary is replaced by a
boundary note in the issue 210 job naming which ship_view
presentation constants the movement spec governs, inherits,
or leaves behind. The constants themselves pass to the
spec's authority. One-time: one Opus run. Recurring: none.

PF11 | RE-DERIVE | Slide distances against any cap are
reported by the PF1 capture set; the same footage states
whether the Godot build carries an equivalent of the JS
coast cap (NOT IN PACK at pack time). One-time: no extra
run beyond PF1's; shared owner review round. Recurring:
none.

PF12 | RE-DERIVE | The inventory entry itself is derived:
one Opus run reads squadron_craft.gd and squadron_wing.gd
and states whether an inertia, separation, or collision
model exists. Any further disposition follows that report;
if no model exists, the scope question joins PF10's
boundary note. One-time: one Opus run. Recurring: none.

CM1 | REPLACE | The ported default's binding force is
replaced by the owner's played radius: the owner plays one
battle at 170 and one at a pulled-back radius and rules his
actual default, and the two dependent standards are
re-denominated at the ruled radius. One-time: one owner
review round (play), one Opus run (restate the figures).
Recurring: none.

CM2 | RE-DERIVE | The owner's working ends are found inside
the CM1 play round; any clamp change rides on CM1's Opus
run. One-time: no extra run. Recurring: none.

CM3 | REPLACE | The framing default is replaced by a ruled
(radius, FOV) pair recorded as part of the CM1 settlement,
so the standards stop denominating against radius alone.
One-time: no extra run beyond CM1's. Recurring: none.

CM4 | RE-DERIVE | Judged inside the CM1 play round, with
one explicit sub-ruling: the top-down floor is either true
vertical or a deliberate, named oblique. Constants re-set
from that play, if at all, ride on CM1's Opus run.
One-time: no extra run. Recurring: none.

CM5 | RE-DERIVE | One hand-over captured at the Godot glide
rate and at the JS 4-second window's rate, judged inside
the CM1 round; the surviving rate is recorded, and the
losing build's figure is freeze-marked in the record
(shared with DS3's cleanup). One-time: one Codex run if
the play round does not already produce the captures.
Recurring: none.

CM6 | RE-DERIVE | Punch judged on the DS14 paired capture
at shipped amounts and at double; the amount that reads is
the amount that ships. If neither amplitude reads on the
footage, this converts to DROP (an invisible accent buys
nothing and its protection is not needed). One-time: no
extra run beyond DS14's. Recurring: none.

CM7 | RE-DERIVE | Amounts and the 120-unit falloff are
re-set from one battle capture with shake logged per event
against distance, inside the DS14 round; the fx E33
settlement absorbs the testing ranges themselves. One-time:
no extra run beyond DS14's and the E33 settlement's shared
owner review round. Recurring: none.

CM8 | RE-DERIVE | Settled inside the fx E33 settlement
battle (range ends played by the owner) with the shipped
values entered as a third candidate, so the implementation
and the recorded ranges are finally judged in the same
footage. One-time: one owner review round, shared with the
fx settlement. Recurring: none.

CM9 | RE-DERIVE | The margin and HUD-clear fractions are
judged from the owner's own hand-over experience in the CM1
play round; if they change, the restated fractions are
recorded with the UI standard, not only in code. One-time:
no extra run; restating rides on CM1's Opus run.
Recurring: none.

CM10 | REPLACE | The unknown is replaced by a stated fact:
one Opus run states the Godot post-processing state
(vignette, grade, board look). If the grade is absent, a
screenshot pair (JS grade vs Godot current) is judged by
the owner on restoration. One-time: one Opus run; one owner
review round only if a pair is needed. Recurring: none.

CM11 | REPLACE | The unrecorded absence is replaced by an
owner ruling (question 3, section 6). If ruled in, the
cheapest form (edge cue toward the shooter) is prototyped
inside the CM7 capture round. If ruled out, the absence
becomes a recorded decision and closes. One-time: one Codex
run only if ruled in. Recurring: none.

CM12 | REPLACE | The unrecorded default is replaced by a
recorded ruling (question 1, section 6). The branch where
the camera is never taken costs nothing and closes the item
permanently; the branch for a directed death beat prices
its prototype at one Codex run, judged in the DS14 round's
format. One-time: zero or one Codex run depending on the
ruling. Recurring: none.

CM13 | RE-DERIVE | The radii the standards must cover are
defined by the CM1 and CM2 rulings (default and ends); the
coverage statement is added to the standards as part of
CM1's Opus run. One-time: no extra run. Recurring: none.

## 6. Owner questions

1. CM12: should the camera ever be taken from you for a
capital death (a short directed framing beat), or is "the
camera is always the player's" the standing rule for this
game? Pick: the camera is never taken; the punch and slow
motion (CM6, CM8) are the death's only accents, and the
question reopens only if the DS14 paired capture shows
capital deaths reading flat in player framing. Stakes: the
game's most judged moment either plays in whatever framing
chance left it in, or costs you control of the board on
every capital death.

2. DS10, DS11, PF7: should a capital ship's death be
physically dangerous to bystanders as a general rule (blast
damage plus a shove), or should death stay silent to
neighbours outside the chainBoom boon? Pick: yes for
capitals only, prototyped and judged on the PF7 formation
capture before it binds; frigates stay silent. Stakes:
formation play, including the Hegemony flagship-anchor
game, changes the first time a flagship dies inside its own
screen; ruling no makes the current silence a decision
instead of an omission.

3. CM11: do you want a directional cue when one of your
ships is hit from off-screen or from a facing you are not
watching? Pick: yes, a minimal edge cue toward the shooter,
prototyped inside the CM7 capture round and judged there.
Stakes: in a game built on facings and shield quadrants,
learning about flank damage from the log is a beat late;
the cost is one more screen element competing with the
board.

## 7. Not checked

- No source outside PACK.md was read: no code, no issues,
  no FINDINGS text, no fx audit pack. Every file, line, and
  constant reference in this report is the pack's, taken as
  given.
- The fx audit items (E3 to E7, E13, E33, A7, A17, A19)
  were used as settled inventory and not re-derived, per
  the leg instruction.
- Whether the Godot rules port implements the gravity well
  (PF9): unverified in the pack itself (PACK section 7,
  item 2) and unverified here.
- Squadron physics (PF12): the two files were not read for
  the pack and not by this leg; nothing here states what
  they contain.
- The Godot post-processing state behind CM10: board.gd was
  read only at line 7 for the pack; the grade's presence or
  absence in the port is unknown to this report.
- Whether the Godot build carries a slide cap equivalent to
  the JS coast cap (PF11): NOT IN PACK.
- Whether set-piece wrecks count against the DS1 cap of 24:
  NOT IN PACK; the DS1 game dev entry flags the arithmetic
  tension (20 battle wrecks do not reach 24 alone) without
  resolving it.
- Which weight classes fall above or below the DS2 hulk
  threshold of size 0.7: NOT IN PACK, so the threshold's
  practical split was not evaluated.
- Fleet hull values needed to say whether PF4's base damage
  or its 40 percent cap binds on typical targets: NOT IN
  PACK; this is why the Monte Carlo is a settlement and not
  a formality.
- Battle round duration, needed to judge DS3's cooling tails
  against the game's actual tempo: NOT IN PACK.
- All perceptual questions: whether the CM6 punch reads at
  battle distance, whether DS6's tumble reads as violent or
  as pinwheels, what radius the owner actually plays at
  (CM1), whether the DS7 freeze reads as statues in motion.
  Each needs the owner in front of a capture; this report
  only prices those viewings.
- The DS13 flag's arithmetic uses the capital length of
  41.6 units as carried in CM13 and DS8's split_width
  factor of 0.04 as carried in DS8; hull data behind either
  figure was not available to this leg.
- The chair's hypotheses (PACK section 6) were tested only
  against the inventory texts in sections 3 to 5. Where this
  report agrees with one (H1 via CM9's second 170, H3 via
  DS7, H5 via the three mass definitions in DS7, PF1, PF10),
  the agreement rests on the same pack evidence the chair
  used, and no independent source was consulted.
