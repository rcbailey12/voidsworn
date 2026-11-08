Blind Rey leg (writer): environment and backdrop red team
Evidence: PACK.md only. All section citations are to the pack.

1. VERDICT

THE STACK HOLDS ONLY WITH REPLACEMENTS.

The tally is the worst of the three stacks audited under this
program (OBSERVED, pack section 2): 74 items, MEASURED 1,
DERIVED 2, ANCHORED 1, ASSUMED 70. The single measured item
(AS11) is a test fixture, not the game. The stack does not
collapse, because most of its numbers are buildable defaults
and several settlements are already queued inside issues 139,
140, and 100. But three failure modes run through it, and each
has a named carrier:

AS1 (the backdrop rock angular cap, section 5): a composition
preference (no rock wider than 0.05 rad) promoted into a code
assert that fails builds. It is the scale ceiling of the whole
sky: PL8's 4.4x margin compounds it, and AS8 shows the largest
backdrop form (mountains, raw size to 220) is in practice
sized by this cap, not by its own range (a 220-unit rock at 900
units subtends about 0.24 rad, roughly five times the cap).
The owner's R88 playtest verdict that asteroids look hollow,
as if seen from inside, has a candidate single numeric root
here: a sky in which nothing may loom reads as a shell
(OBSERVED for the cap, the assert, and the AS8 interaction,
pack sections 5 AS1, AS8 and 4 PL8; INFERRED for the causal
link to R88, resting on H1 and the pack's own candidate
reading).

ST5 (the removed ceiling that still asserts, section 7): the
owner removed the tri half of the station ceiling on Nov 6,
2026, and station_kit.py line 949 still asserts it on every
detail export. This is the one item where the record
contradicts a settled ruling in live code. The next station
build (issue 199, position 2 in the queue) can fail its own
kit check for a ceiling that no longer exists, and the failure
will read as a quality problem (OBSERVED, pack sections 1.2
and 7 ST5).

BD18 (the quality tier table, section 6): three tiers with no
measured frame cost per tier anywhere in the record, yet at
least five content decisions hang on them (NB12 fog lights,
NB13 quality ladder, AS3 field reduction, BD13 wisps, PL13 sky
bake ladder). If the tier costs are upside down, the ladder
misallocates on every machine below max, and every hanger item
inherits the error (OBSERVED, pack sections 6 BD18 and the
hanger items cited there).

Close behind the hinges: AS14 and BD16 (two adopted documents
disagreeing with each other and with the code, the H2 pattern),
and BD10 (the region table that silently multiplies most of
the pack's numbers per region).

2. GAME DEV LENS

NB1. OBSERVED (pack section 3, NB1). The bands bind no frame
budget directly; they decide how much gas crosses ship height
(y 0 to 3), which is fill and overdraw the engine charges per
pixel at 4K. Wrong bands pay volume cost for gas that reads
flat, or starve the band where ships actually fly.
NB2. OBSERVED (pack section 3, NB2). Alphas and density
parameters are denominated in material terms, not in the
overdraw the engine charges; at 4K a too-heavy patch eats the
board and the ships behind it, which is a frame cost and a
readability cost in the same number.
NB3. OBSERVED (pack section 3, NB3). Mask constants bind edge
quality, not frame cost in any priced way; a hard edge at the
battle camera undoes issue 139's volume work in play, because
edges are where a player first reads gas as decals.
NB4. OBSERVED (pack section 3, NB4). The colour stops and
channel caps bind no performance; they bind whether faction
identity can read through gas in a real battle. The caps are a
guard against a mauve failure, never re-measured after
adoption, so the game may be paying identity range for a
failure that no longer threatens.
NB5. OBSERVED (pack section 3, NB5). One global weight
denominates faction pull for every nebula, storm, and faction;
no per-map variation exists. In gameplay terms the dead star
sector and a home sector are forced to the same identity
range, whatever the map needs.
NB6. OBSERVED (pack section 3, NB6). The fixed violet family
binds variety, not performance. If the family itself is the
sameness behind the R88 low fidelity verdict, every volume
gain in issue 139 is spent inside the wrong constant.
NB7. ANCHORED item. OBSERVED (pack section 3, NB7). The 0.7
densest-point cap is one external game's practice promoted to
a rule; it is denominated in alpha, not in any measured
readability outcome in this game. Too high and hulls drown
(the failure R82 Q2 was written against); too low and gas
never feels entered, which is a gameplay read, not a cosmetic
one, because nebula hexes are terrain.
NB8. OBSERVED (pack section 3, NB8). Multipliers on a base
drift rate that is itself unnumbered anywhere in the record:
the motion spec cannot be built to or checked, so shipped
motion in a real battle is whatever each builder invented.
Motion binds no frame budget; it binds whether gas feels
alive during the minutes a battle lasts.
NB9. OBSERVED (pack section 3, NB9). Layer count is
construction cost per patch and fill cost per frame; the 3 to
4x filament frequency ratio sets texture scale. Neither was
swept, so issue 139 inherits both the cost and the look
unexamined.
NB10. OBSERVED (pack section 3, NB10). Storm stops sit far
darker than the nebula family with no derivation in the
record. In play, a storm too dark to read is terrain a player
cannot respect; the cost is tactical, not just visual.
NB11. OBSERVED (pack section 3, NB11). Between-bolt activity
is most of a storm's screen time. The item mixes units (12
units) and hexes (1 to 2) with no conversion stated, so the
spec is not denominated consistently enough to build against
in a real map.
NB12. OBSERVED (pack section 3, NB12). Lights in fog are
rationed to max tier by an unmeasured ladder; the ruling
spends the game's most atmospheric interaction on a cost fear.
If max tier costs little, high and low tiers are denied it for
nothing; the denomination error is that tier membership, not
milliseconds, is doing the gating, and milliseconds are the
only binding currency under the Nov 6 rulings (pack section
1.2).
NB13. OBSERVED (pack section 3, NB13). The protection ranking
(cut puffs and bolt lights first, never the ramp or cores) has
no per-element cost table behind it. A quality ladder ranked
without prices can cut the expensive elements and protect the
cheap ones; the error shows up exactly where the ladder
exists to help, on weaker machines.
PL1. OBSERVED (pack section 4, PL1). Placement ranges bind no
performance; they are composition law. The elevation band
keeps every backdrop planet below the horizon on every map,
so every battle is framed the same way, which players read as
repetition.
PL2. OBSERVED (pack section 4, PL2). Angular size bands bind
the planet's share of every frame. Too small is wallpaper,
too large fights the battle for the eye; and the band feeds
PL8, so it also caps the rocks (see AS1).
PL3. OBSERVED (pack section 4, PL3). Spin at 0.002 to 0.006
rad per second is visible only over minutes; nobody has
watched it. It binds nothing measurable, and its error cost
is a frozen-feeling sky in long battles, unpriced either way.
PL4. OBSERVED (pack section 4, PL4). Eight looks across six
kinds is the whole sky variety budget for a campaign. It binds
no frame cost; it binds how soon a player has seen everything
the backdrop can show, and issue 140 raises fidelity inside
this count without questioning it.
PL5. OBSERVED (pack section 4, PL5). Moon margins are
collision avoidance for the composition; too wide scatters
moons into unrelated dots, too tight reads as a diagram. The
scale cue the backdrop depends on is set by unsheeted edges.
PL6. OBSERVED (pack section 4, PL6). A 65/35 barren majority
and a 0.8 to 1.1 tint band cap how distinct moons can ever
look; most moons a player sees are grey rock by distribution,
not by art failure.
PL7. OBSERVED (pack section 4, PL7). Rings on exactly 2 of 8
looks rations the strongest silhouette in the backdrop by
table default. Ring rendering cost at the 4K camera is not in
the record; the ration is not denominated in anything.
PL8. OBSERVED (pack section 4, PL8). The 4.4x margin is a
composition preference enforced by an assert, so a preference
fails builds. With AS1 it sets the sky's whole scale ladder;
too strict, and rocks can never feel near, which is one
reading of the R88 hollow verdict.
PL9. DERIVED item. OBSERVED (pack section 4, PL9). The radius
arithmetic is sound on the ruled hex geometry, but the 1.5
multiplier and 78 percent sink are assumed inputs. The
play-area planet is the one environment object ships fight
directly over; its cap height (about 11 units) and chord
(about 63) decide whether a battle reads as over a world.
PL10. OBSERVED (pack section 4, PL10). The 96 by 48 sphere is
the planet the camera gets closest to; silhouette faceting at
close zoom is a mesh failure no bake can hide. The count was
never chosen against the bake resolution or the zoom.
PL11. OBSERVED (pack section 4, PL11). The procedural-only
route is the ceiling on planet quality. R88's demand for much
higher terrain planet quality postdates the ruling, and no
head-to-head against a textured build exists at the current
standard; if the bake cannot reach the bar, issue 140
discovers it one build at a time.
PL12. OBSERVED (pack section 4, PL12). The 20 second wait cap
against a measured 6 to 9 second bake (fx E23) leaves headroom
today; issue 140's richer bake spends it. A cap that expires
mid-bake ships a battle with an unfinished sky, and the
24-bake cache decides how often a campaign pays at all.
Neither is priced on a cold profile.
PL13. OBSERVED (pack section 4, PL13). The low tier halves
sky resolution twice over with no capture at 1440p, the
owner's floor resolution. The low tier is where the weaker-PC
promise lives; nobody has seen the game it shows.
PL14. OBSERVED (pack section 4, PL14). Giants unchanged is a
standing constraint whose basis is absence of complaint.
After issue 140 the sky has two quality classes; if the
giants read a generation behind, the rule preserves the gap
permanently, and no sheet compares them.

AS1. OBSERVED (pack section 5, AS1). The 0.05 rad cap is
denominated in angle, which is the right currency for backdrop
size, but the value was adopted as a strictness preference
with no sweep behind 0.05 rather than 0.08 or 0.12, and the
assert promotes it to a build failure. It caps every rock in
the sky, including AS8's mountains, which have no other
ceiling. In a real battle it decides whether anything can
loom; the R88 hollow verdict is its candidate price.
AS2. OBSERVED (pack section 5, AS2). The per-kind count table
is the environment's population law, and counts are what the
engine actually charges for in nodes and draw. The belt's 420
deep rocks against open's 110 is a 4x richness decision with
no density sweep behind it for any map kind.
AS3. OBSERVED (pack section 5, AS3). The 0.6x low-quality
multiplier spends or saves rock counts against a tier whose
frame cost has never been measured (BD18). Either low tier
cuts 40 percent of the field for nothing, or cuts it and still
misses its target for reasons elsewhere.
AS4. OBSERVED (pack section 5, AS4). The edge distribution
formula, with the 6 percent large-rock roll as the only
mechanism that can put a big rock at the frame, decides
whether every battle's border reads as rubble, a ring, or
noise. The roll rate was never judged on a sheet.
AS5. OBSERVED (pack section 5, AS5). The near band sits
entirely below the far band (y -140 to -90 against -40 to 12);
that vertical layering is the parallax the backdrop depends
on (BD15). Wrong bands flatten the field into a ring at board
level, and no capture examines the layering.
AS6. OBSERVED (pack section 5, AS6). The deep field is most of
the visible rocks in most battles; its depth fraction (0.35 to
0.85 of distance) is the mid-ground parallax law and appears
in no research document. If it is wrong, the sky has no middle
distance, which compounds AS1's shell problem.
AS7. OBSERVED (pack section 5, AS7). Sigma 170 and the
600-unit centre exclusion are the belt's whole composition,
and the belt map is issue 139's showcase capture map, so these
numbers sit behind those sheets unexamined. A wrong sigma
reads as a wall or a smear in the game's most-sheeted
environment.
AS8. OBSERVED (pack section 5, AS8). The mountain range (raw
70 to 220, scaled by distance over 1600) is silently
subordinate to AS1: 220 units at 900 subtends about 0.24 rad,
about five times the cap. The record shows no awareness of
the interaction, so the backdrop's only monumental form is
sized by an assert written for a different purpose.
AS9. OBSERVED (pack section 5, AS9). Crystals are the only
environment feature with no design document at all; four code
numbers govern them entirely. Twelve clusters may be a
signature or a rounding error, and in a real battle nobody
can tell which, because nothing ever judged the count.
AS10. OBSERVED (pack section 5, AS10). Five fields, five spin
laws, no common motion standard. Players read relative motion,
so the inconsistency itself is the artefact: the same rock
reads alive in one field and dead in another.
AS11. MEASURED item. OBSERVED (pack section 5, AS11). The
fixture is a counted baseline and settles itself. Its spin top
(0.1792 rad per second) is faster than every shipped field
range and the AS14 debris cap, so the test scene and the game
disagree about how fast rocks may turn; quoting the fixture
as game behaviour would be the only error available here.
AS12. OBSERVED (pack section 5, AS12). Debris hexes are
gameplay terrain: they block and shelter. Per-hex rock density
is both the look and the readability signal for cover, and the
counts were never swept, so the signal's strength is unjudged
in the battles where it matters.
AS13. OBSERVED (pack section 5, AS13). The 55 percent hero
piece chance is the whole authored presence of wrecks in a
debris field. Hero pieces are what make a field read as a
graveyard rather than a quarry; an unjudged coin flip rations
the graveyard maps' identity.
AS14. OBSERVED (pack section 5, AS14). Two adopted
specifications disagree by a factor of about 2 to 3 on small
rock tumble: the code's cap (0.10 / max(1, scale)) against the
terrain synthesis's periods (small rocks 20 to 40 seconds,
which convert to 0.157 to 0.314 rad per second). The code
obeys the lower one. In a real battle, debris motion is
governed by whichever document a builder happened to
implement, and review cannot catch it because both values are
the spec somewhere.
AS15. OBSERVED (pack section 5, AS15). Ambient dust is the
cheapest depth cue in the game and the first thing cut at low
quality (counts divided by 3). An unjudged count either wastes
the cue or pays for motes nobody sees at 4K; the dust never
spawning above y -25 over the board is a shipped boundary no
sheet examines.
AS16. OBSERVED (pack section 5, AS16). The spec's size
structure (20 percent large, wreck pieces 6 to 9 units) has
no counterpart in the shipped code, whose scale range tops at
3.8 (AS13). Issue 100 will implement the spec against code
that already implements something else, and the difference
will be adjudicated by eye without anyone knowing it exists.
AS17. OBSERVED (pack section 5, AS17). Blockers are the rocks
nearest the action, denominated in units at board distance
while the backdrop fields use angular law (AS1): two size
currencies for rocks in one game. Blocker size against ship
length is the most-read scale comparison in a battle, set by
an unswept 13 to 15 unit range.
AS18. DERIVED item. OBSERVED (pack section 5, AS18). The 8.66
cap is sound arithmetic on the ruled hex geometry (half of
the 17.32 flat width), but the half-width input is a pick, and
AS16's spec allows wreck pieces to 9 units, crossing the cap
by 0.34 units at exactly the size that matters most. The two
adopted documents cannot both be built.
BD1. OBSERVED (pack section 6, BD1). The sky is the largest
single surface in every frame and half of every screenshot.
The 4096 bake was never compared against another resolution
at the 4K camera; too small caps the whole game's perceived
resolution, too large pays memory and bake time (PL12) for
invisible texels.
BD2. OBSERVED (pack section 6, BD2). Two step regimes that do
not obviously agree: the loader's per-tier 48/40/26 and the
bake shader's uniform 40 inside a 64-iteration cap. If the
shader ignores the loader, a tier dial is dead and future
tuning turns it in vain; too few steps band the sky's
gradients in play.
BD3. OBSERVED (pack section 6, BD3). The radiance bake size
(256) has no stated role check in the record: what consumes
it at this size is not shown. Scene ambience rides on a number
nobody has varied.
BD4. OBSERVED (pack section 6, BD4). Lamp count scales with
the region nebula factor (2 + round(factor times 4)), a
coupling no research document describes. Sky lamps are the
environment's light on ships, so scene lighting varies by
region table accident rather than art direction, battle to
battle.
BD5. OBSERVED (pack section 6, BD5). Galaxies are rationed by
an inverse formula against nebula cover (up to 5, fewer as
gas rises). Nebula maps, the showcase maps, can be left with
the emptiest deep sky by construction.
BD6. OBSERVED (pack section 6, BD6). Thresholds at 0.955,
0.985, 0.994 sit so close to 1.0 that small changes swing star
density enormously, and no density count exists anywhere in
the record. Star density is the backdrop's base texture: too
dense fights the ships as noise, too sparse reads as
emptiness, and the current point was inherited, never counted.
BD7. OBSERVED (pack section 6, BD7). The galaxy band is the
sky's main structure; its widths (core 0.17, wide 0.42, rift
0.06) were never sheeted at alternatives. Against PL1's planet
placement band, the band decides most compositions in the
game.
BD8. OBSERVED (pack section 6, BD8). Two documents govern star
dimming (this 0.15 floor and fx E18's percentage targets)
with no stated relationship. A builder can satisfy either and
miss the other, so the R82 Q2 contract (gas dims stars and sky
only) is enforced by two unconnected numbers.
BD9. OBSERVED (pack section 6, BD9). A 1.45 saturation push in
the bake is a global grade with no before and after in the
record. It interacts with NB4's channel caps untraced; the
grade may be the real author of the mauve and brown failures
the caps were written to prevent, in which case builds keep
fixing the wrong number.
BD10. OBSERVED (pack section 6, BD10). The region table is
the single point where most of this pack's numbers meet: it
feeds AS2 counts, BD4 lamps, BD5 galaxies, BD6 stars, dust.
Its per-region values were never sheeted region by region. One
off value does not break one map; it tilts a sixth of the
campaign's sky.
BD11. OBSERVED (pack section 6, BD11). A yaw range of plus or
minus 0.35 rad means near-identical sky orientation every
battle; its purpose is unrecorded, and its interaction with
the band crossing PL1's planet zone was never checked.
BD12. OBSERVED (pack section 6, BD12). The bake march shell
(0.55 to 1.6) bounds where sky nebula density can exist. Too
thin and the baked gas flattens into a dome painting, which
issue 139's volume work cannot fix, because this is the sky,
not the patches.
BD13. OBSERVED (pack section 6, BD13). Wisps are large, faint,
below the board, gain 0.06, off at low quality. No capture
isolates their contribution: either a whole subsystem pays
draw and fill for nothing, or the board's underside depth,
which the downward battle camera actually sees, is carried by
a 0.06-gain afterthought.
BD14. OBSERVED (pack section 6, BD14). Backdrop fog albedo
(0.42, 0.44, 0.5) is a grey-blue grade applied to everything
distant, in every shot. No document discusses the colour as a
choice; a wrong grey here gets attributed to everything else.
BD15. OBSERVED (pack section 6, BD15). The interim dressing
formula is still the shipped backdrop path, and its
multipliers are anchored on board bounds, so the dressing
rescales itself whenever the board does. Interim scaffolding
that ships is the design, with a hidden coupling nobody
decided.
BD16. OBSERVED (pack section 6, BD16). Shipped zone tints
(0.075, 0.065, 0.065) are roughly half the specified tints
(0.16, 0.12, 0.13), and R82 Q3's ruling (tint reduced, faint
tint kept) covers both readings, so spec and code disagree by
2x under one ruling. Zone tints are how a player reads terrain
type at a glance in a battle; the AS14 pattern in miniature.
BD17. OBSERVED (pack section 6, BD17). The board look
multiplies every other judgement in this pack: gas edge 0.9 in
the cine default against 0.3 in the living look means sheets
and play may be judged in different games from the same build,
and research captures do not always record which look they
were taken in.
BD18. OBSERVED (pack section 6, BD18). The tier table is the
load-bearing structure under NB12, NB13, AS3, BD13, and PL13,
and no tier has a measured frame cost anywhere in the record.
The tiers are denominated in feature lists, not in the
milliseconds that are the project's only binding currency
(pack section 1.2).
BD19. OBSERVED (pack section 6, BD19). A dozen unmeasured
constants decide the campaign's signature location. Issue 100
builds them all at once, so if the well reads as a screensaver
instead of subtle dread, the miss cannot be attributed to any
one constant. R82 Q4 ruled only the qualitative point.
ST1. OBSERVED (pack section 7, ST1). The additions-only
doctrine freezes the R94 shapes, and R109's complaint (super
plain, just like regular shapes) is a complaint about exactly
the shapes frozen. If the plainness lives in the locked
primitives, additions can only decorate the problem, at full
detail-pass cost per attempt, starting with issue 199.
ST2. OBSERVED (pack section 7, ST2). The 2-unit proud floor:
2 units at the battle camera (about 170 units out) is about 1
percent of frame height (INFERRED arithmetic from the pack's
own figures, section 7 ST2). If the floor is below the
readability threshold where stations are judged, the whole
detail pass is invisible at judgement distance; too high and
stations grow spikes by rule.
ST3. OBSERVED (pack section 7, ST3). Exact-equality asserts
(length exactly 46, dorsal tops exactly [4.5, 5.0, 4.0, 6.5],
crossbeam exactly 9, skyline z at least 15) verify the present
faithfully but forbid any future silhouette improvement by
construction. The approval of one moment's shapes has become
permanent geometry law.
ST4. OBSERVED (pack section 7, ST4). The design target (about
20k triangles, 0.35 ms) was set over a baseline never counted;
no triangle count or timing of the current stations exists in
the record. Issue 199's done-when aims well under a ceiling
derived from this target, so an uncounted baseline steers the
one station job currently queued.
ST5. OBSERVED (pack section 7, ST5 and section 1.2). The
owner removed the tri half of this ceiling on Nov 6, 2026;
the line 949 assert still enforces 40k (fleet) or 45k
(refinery) on every detail export. The first build that
crosses 40k fails its own kit check for a ceiling that no
longer exists, and a builder who silently edits the assert
buries a ruling inside a code change.
ST6. OBSERVED (pack section 7, ST6). The tall element bans
protect the approved silhouettes' read, but tall is given no
number anywhere, so the ban's boundary is each reviewer's
private judgement. Silhouette variety is the stations' known
weakness (they read as flat frames); an unnumbered ban on the
main remedy can outlive the pass it was scoped to because
nothing in its text expires it.
ST7. OBSERVED (pack section 7, ST7). The break treatment
exemption trades break fidelity for build cost on thin
members. No broken station capture exists; when a truss
actually breaks in a battle, a decal-covered shell may read
as a cheat at exactly the destruction moment the game sells.
ST8. OBSERVED (pack section 7, ST8). Board sizing and kit
sizing agree only at 46 units (5 or more hexes). The sub-5-hex
branch (22 + 4 per hex) produces stations the Blender kit
never builds; every small station in the game is unbuilt,
unshot, and unjudged.
ST9. OBSERVED (pack section 7, ST9). Exactly two station
variants for the whole game. Issue 199 deepens the same two
rather than widening the set; depth on two silhouettes may be
worth less than a third variant at half depth, and no sheet
has ever priced the trade.
ST10. OBSERVED (pack section 7, ST10). STATION_KIT.md still
describes an issue 61 proxy gate; the kit has since carried
issues 183, 195, and 199. Stale kit documentation is how
stale asserts (ST5) survive: the document that would explain
the assert no longer describes the kit that contains it.

3. DOMAIN DESIGNER LENS

NB1. OBSERVED (pack section 3, NB1). The bands are the
nebula's vertical architecture: whether gas reads as a volume
the battle sits inside or as flat decals under it. The shipped
set matches neither the specified set nor any ruling, so the
single most structural choice in gas craft is an orphan.
NB2. OBSERVED (pack section 3, NB2). These four numbers are
most of what low fidelity means for gas. Too light and patches
read as smoke decals; too heavy and the board and ships drown.
They buy density craft and tax everything behind the patch,
and they were kept without a sweep when the shading around
them was replaced.
NB3. OBSERVED (pack section 3, NB3). Edges are where billboard
gas betrays itself. Feather and texel values decide whether a
patch has a boundary a painter would accept; a blobby edge
taxes every interior improvement issue 139 makes.
NB4. OBSERVED (pack section 3, NB4). The ramp is the nebula's
palette, and the channel caps are its taste guard. They buy
protection against mud; they tax faction identity, because
c_lit can only ever travel halfway toward a faction colour
inside capped channels. Every nebula on every map inherits
the compromise.
NB5. OBSERVED (pack section 3, NB5). A single dial position
sets the identity range of all gas in the game. It buys
consistency; it taxes place, because a dead star sector and a
home sector cannot be given different skies.
NB6. OBSERVED (pack section 3, NB6). One violet family for
every nebula is a sameness decision at the palette level. No
alternative family was ever sheeted, so the craft question
(would a second family buy more atmosphere than any shader
work) has never been put to the eye.
NB7. OBSERVED (pack section 3, NB7). This is the readability
contract between terrain and ships: hulls stay crisp, gas
dims only sky. It buys the R82 Q2 promise. Its price, if the
anchored 0.7 is too low, is gas that never feels entered, a
volume you fly beside rather than through.
NB8. OBSERVED (pack section 3, NB8). Motion is the difference
between a living volume and a backdrop prop; the breathing
oscillation and layer multipliers are pure craft. Multipliers
on an unnumbered base tax the craft itself, because no two
builders can produce the same sky from the spec.
NB9. OBSERVED (pack section 3, NB9). Four layers is a
composition: haze, body, wisps, veil each do a different
painterly job, and the filament frequency ratio is the
texture grain of the whole. Neither was swept, so the
composition is inherited, not chosen.
NB10. OBSERVED (pack section 3, NB10). The storm stops are far
darker than the nebula family they share maps with, with no
defending text. They buy menace; they tax legibility, and a
storm that vanishes against the sky fails as terrain design
before it fails as art.
NB11. OBSERVED (pack section 3, NB11). Between bolts is the
storm's resting face, most of its screen time. Filaments,
sheet glow, and the shield tick are what make a storm feel
electrically alive instead of merely dark; unjudged, they are
the R88 complaint in storm form.
NB12. OBSERVED (pack section 3, NB12). Light inside gas is
the single most atmospheric interaction the environment owns.
Rationing it to one tier by cost fear taxes the look on every
other machine; the density pulse at high tier gets the same
treatment one rung down.
NB13. OBSERVED (pack section 3, NB13). The protection rule is
a craft ranking: it says the ramp and glow cores are the soul
and puffs are expendable. That may be right, but it was ranked
without prices, so low tier's look is decided by an unexamined
opinion about which elements carry the scene.
PL1. OBSERVED (pack section 4, PL1). Placement is composition
law. One azimuth side, one below-horizon elevation band, for
every battle in the game: the framing repeats long before the
art does, and players feel it as sameness without naming it.
PL2. OBSERVED (pack section 4, PL2). Angular size is the
planet's presence. The band edges were adopted as framing
doctrine but never judged; too small is wallpaper, too large
steals every screenshot from the battle it backgrounds.
PL3. OBSERVED (pack section 4, PL3). Spin buys a living sky at
almost no cost. A range nobody has watched for a full minute
cannot be said to buy anything; it may be set below the
threshold of perception entirely.
PL4. OBSERVED (pack section 4, PL4). Variety is a count before
it is a quality. Eight looks is the game's whole planetary
vocabulary; raising the fidelity of a too-small set (PL11,
PL14) perfects the repetition instead of ending it.
PL5. OBSERVED (pack section 4, PL5). Moons are the backdrop's
main scale cue, the thing that tells the eye how far the
planet is. Margins set by collision avoidance rather than by
looking tax that cue in both directions.
PL6. OBSERVED (pack section 4, PL6). A 65 percent barren
majority is a palette decision disguised as a distribution.
It buys coherence; it taxes memory, because most moons a
player recalls will be the same grey rock.
PL7. OBSERVED (pack section 4, PL7). Ringed planets are the
strongest silhouette any space backdrop can field. Rationing
them to a quarter of looks spends or starves the game's best
postcard by table default.
PL8. OBSERVED (pack section 4, PL8). The 4.4x margin is a
tidiness rule for the scale ladder. It buys a guarantee that
planets always dominate rocks; it taxes nearness, because a
rock can never be allowed to feel close, and nearness is
depth.
PL9. OBSERVED (pack section 4, PL9). The play-area planet's
cap is the ground of the battle in the most literal sense:
an 11-unit-high, 63-unit-wide world surface under the fight.
The sink and multiplier decide how much of a battle reads as
taking place over a world. Chosen inputs, derived output.
PL10. OBSERVED (pack section 4, PL10). Faceting at close zoom
is the kind of flaw that makes a whole scene read cheap in
one glance. The segment count buys silhouette smoothness, the
craft basic this planet most needs, and it was never checked
at the zoom it serves.
PL11. OBSERVED (pack section 4, PL11). The procedural-only
route buys a coherent, art-directable planet pipeline and
excludes the shortcut of photo textures. It taxes the ceiling:
if the bake cannot reach much higher quality (R88), the
route, not the builders, is the limit, and it was ruled before
that bar existed.
PL12. OBSERVED (pack section 4, PL12). The cache and wait
numbers buy nothing artistic directly; they tax the look
indirectly, because a battle that starts under an unfinished
sky shows the player the scaffolding, and a small cache makes
campaign skies repeat their bake behaviour.
PL13. OBSERVED (pack section 4, PL13). The ladder decides what
the sky looks like for players on lower settings, and nobody
has sheeted it at the floor resolution. A look nobody has seen
cannot be said to be a look the project chose.
PL14. OBSERVED (pack section 4, PL14). Leaving the giants
unchanged buys schedule focus for the complained-about kinds.
It taxes sky coherence: two quality classes in one backdrop
read as two games, and the giants are the largest objects in
the sky, so the gap shows at the greatest size.
AS1. OBSERVED (pack section 5, AS1). The cap buys tidiness:
no rock ever upstages. It taxes depth absolutely, because
looming is the strongest nearness cue a backdrop has, and the
cap forbids it at every distance, in every field, forever.
The hollow, seen-from-inside quality the owner named is what
a sky with its nearness cue removed feels like (INFERRED,
resting on H1 and the pack's candidate reading).
AS2. OBSERVED (pack section 5, AS2). Counts are richness. The
table buys per-kind character (a dense belt, a sparse open
map); it taxes credibility where the ratios were never looked
at, because a 4x density jump between map kinds will read as
inconsistency if it reads as anything unplanned.
AS3. OBSERVED (pack section 5, AS3). The 0.6x cut buys low
tier a frame budget at the price of the field's richness,
which is the field's whole craft contribution. Cutting the
look to pay for an unmeasured tier taxes the wrong side of
the trade until the tier is priced.
AS4. OBSERVED (pack section 5, AS4). The edge field is the
frame of every battle painting. Its distribution decides
whether the frame reads as rubble, a ring, or noise; the 6
percent big-rock roll is the only drama in it, and it was
never looked at.
AS5. OBSERVED (pack section 5, AS5). Height banding buys the
feeling of a place around the board rather than a ring at its
level. The near band sitting wholly below the far band is a
bold layering choice; unexamined, it may read as a floor of
rocks rather than a surround.
AS6. OBSERVED (pack section 5, AS6). Depth fraction is the
parallax law, and parallax is the backdrop's main claim to
being a place. The deep field is most of what a player sees;
its middle distance was set by formula, not by looking.
AS7. OBSERVED (pack section 5, AS7). Sigma is the belt's
brushstroke: too tight a wall, too loose a smear. The
600-unit centre exclusion buys a clean stage; it also means
the belt can never threaten the battle's space, which is a
drama decision made by a clearance value.
AS8. OBSERVED (pack section 5, AS8). Mountains are the
backdrop's only monumental form, the one place the sky can be
sublime. A cap that silently shrinks them to mid-size rocks
taxes the entire environment's sense of scale, and no sheet
ever showed a mountain at its authored size.
AS9. OBSERVED (pack section 5, AS9). Crystals could be a
signature (the one jewel in a rock sky) or visual noise. With
no design document, there is no intent for the numbers to
serve; the craft question (what are crystals for) precedes
every constant.
AS10. OBSERVED (pack section 5, AS10). Consistent motion is a
world's believability. Five spin laws buy nothing over one law
with per-field ranges; they tax coherence, because relative
motion is what the eye actually reads.
AS11. OBSERVED (pack section 5, AS11). The fixture buys the
pipeline a known population to test against. As craft it is
silent; its faster spin range hints the game fields may be
set deader than the project's own test taste, a hint, not a
finding (INFERRED, resting on the AS10 and AS14 comparisons).
AS12. OBSERVED (pack section 5, AS12). Debris density is
terrain storytelling: a debris hex should look like the cover
it is. Counts set by code rather than by the spec's size
structure (AS16) tax that read in both directions, clutter or
emptiness.
AS13. OBSERVED (pack section 5, AS13). Hero wreck pieces are
the difference between a graveyard and a quarry. A coin flip
ration buys variety cheaply; it taxes identity, because the
maps whose whole mood is aftermath get their defining object
by chance.
AS14. OBSERVED (pack section 5, AS14). Tumble rate is the
debris field's tempo. The two adopted standards describe two
different fields, one stately and one noticeably busier; the
code ships the statelier. Craft cannot be reviewed against a
spec that disagrees with itself.
AS15. OBSERVED (pack section 5, AS15). Dust is atmosphere at
its cheapest: drifting motes give the eye near-field motion
and scale. Counts per map kind buy that depth; cutting them
by 3 at low tier removes the cue exactly where depth is
already thinnest.
AS16. OBSERVED (pack section 5, AS16). The size structure is
a real piece of craft: a fifth large, a few wrecks clearly
larger, sub-clumps, a tan haze. It buys a debris field that
reads as a place. The code implementing different numbers
means the craft exists on paper only.
AS17. OBSERVED (pack section 5, AS17). The blocker hero rock
is the scale anchor beside the ships, the comparison every
player makes unconsciously. Its size buys mass and threat; an
unswept range means the anchor was placed without being
looked at next to a ship.
AS18. OBSERVED (pack section 5, AS18). The cap buys debris
that stays believable inside one hex. Its 0.34-unit collision
with AS16's wreck sizes is small arithmetic with a large
craft stake: the largest, most-read piece in the field is
exactly the one the two documents fight over.

BD1. OBSERVED (pack section 6, BD1). Sky resolution is the
canvas size of half of every frame. It buys perceived
resolution for the whole game; an undersized bake taxes every
screenshot, and the size was never tested against the 4K
camera it serves.
BD2. OBSERVED (pack section 6, BD2). March steps are gradient
quality: banding in a nebula sky is the artefact players read
as cheap before anything else. Two disagreeing step regimes
mean the craft dial may not even be connected.
BD3. OBSERVED (pack section 6, BD3). The radiance bake feeds
the scene's ambient light, the wash that ties ships to sky.
An unexamined size taxes that tie in both directions, washed
or starved, with no capture to say which.
BD4. OBSERVED (pack section 6, BD4). Sky lamps are the
environment's key light on the ships. A formula rations them
by region gas; it buys a coupling nobody art-directed, and
scene lighting becomes a table accident rather than a look.
BD5. OBSERVED (pack section 6, BD5). Galaxies are the deep
sky's landmarks, the far points that make space feel deep.
Rationing them inversely to gas taxes the showcase maps,
whose skies are otherwise the richest, by leaving their depth
empty.
BD6. OBSERVED (pack section 6, BD6). Star density is the
backdrop's base texture, under everything. Thresholds this
touchy, uncounted, mean the base texture of the entire game
is an inheritance, not a choice.
BD7. OBSERVED (pack section 6, BD7). The band is the sky's
composition, its milky way. Widths never sheeted mean the
largest structure in the game's visuals was placed by
default.
BD8. OBSERVED (pack section 6, BD8). Dimming is how gas sits
in front of the sky convincingly. Two unconnected regimes tax
the illusion: stars can stay too bright through gas (pasted
on) or vanish (hole in the sky), depending on which number a
build happens to honour.
BD9. OBSERVED (pack section 6, BD9). A 45 percent saturation
push is a strong grade to leave unexamined. It may be doing
the palette's heavy lifting, or fighting NB4's caps in every
bake; either way the nebula colour failures have an unnamed
suspect.
BD10. OBSERVED (pack section 6, BD10). The region table is
the game's unseen art director. Six regions are the campaign's
variety skeleton; values never sheeted region by region mean
the skeleton was never looked at as a whole, only inherited
per feature.
BD11. OBSERVED (pack section 6, BD11). Yaw buys composition
variety in principle; at plus or minus 0.35 rad it buys almost
none, so the sky's orientation, like PL1's framing, repeats.
An unrecorded purpose cannot be weighed against widening it.
BD12. OBSERVED (pack section 6, BD12). The shell is the baked
sky's depth range. Too thin and the sky's gas is a dome
painting, the exact flatness the volume work exists to cure,
one layer further out.
BD13. OBSERVED (pack section 6, BD13). Wisps below the board
serve the downward camera's depth. A gain of 0.06 may be
subliminal craft or pure waste; the craft question is real
and nobody has isolated the answer with one capture.
BD14. OBSERVED (pack section 6, BD14). Fog albedo is a colour
grade over everything distant. A grey-blue chosen by default
tints every planet, rock, and station at range; the
environment's distance colour was never chosen as colour.
BD15. OBSERVED (pack section 6, BD15). Interim dressing that
ships is the design, and this design rescales itself with the
board. It buys a serviceable ring quickly; it taxes intent,
because no sheet ever judged the result as the game's chosen
backdrop.
BD16. OBSERVED (pack section 6, BD16). Zone tints are the
board's legend, drawn on the terrain itself. At half the
specified strength they may be elegantly faint or simply
illegible; the 2x disagreement means the project cannot say
which it shipped on purpose.
BD17. OBSERVED (pack section 6, BD17). The look presets are
the final grade every environment number passes through
before judgement. Unsheeted parameter values, and captures
that do not record the look, tax every other item's
settlement, because two judgements may be of two different
games.
BD18. OBSERVED (pack section 6, BD18). The tiers decide what
the environment is allowed to be on most machines. Max keeps
volumetric haze and SSAO; low cuts them entirely. Those are
craft decisions priced in nothing; the ladder's shape, not
any single feature, is the look of the game below max.
BD19. OBSERVED (pack section 6, BD19). The dead star well is
the signature set piece: lensing ring, ripples, infalling
dust, an amber light. Its dozen constants buy dread if they
land and a screensaver if they do not, and they were written
in one pass with no built reference to tune against.
ST1. OBSERVED (pack section 7, ST1). Additions only buys
silhouette protection: the approved shape cannot be lost. It
taxes the cure for the shapes' own plainness (R109), because
if the primitives are the problem, the doctrine forbids the
fix and permits only decoration.
ST2. OBSERVED (pack section 7, ST2). The proud floor buys
silhouette over surface noise, the right instinct for stations
judged at 170 units. Unsheeted, the floor may sit below
visibility, in which case the detail pass pays full price for
texture the battle camera cannot see.
ST3. OBSERVED (pack section 7, ST3). Frozen dimensions buy
fidelity to an approved moment. They tax all future craft:
a better skyline found tomorrow fails the build, so the kit's
taste is permanently the taste of the approval day.
ST4. OBSERVED (pack section 7, ST4). A design target buys an
ambition anchor for the detail pass. Set over an uncounted
baseline, it may anchor far under what the stations could
carry visually; the target taxes richness it was meant to
enable.
ST5. OBSERVED (pack section 7, ST5). The stale assert buys
nothing artistically. It taxes the detail pass at the moment
it succeeds: the first station rich enough to cross 40k
triangles is failed by the kit, teaching builders to design
down to a dead ceiling.
ST6. OBSERVED (pack section 7, ST6). The tall bans buy the
approved read of two silhouettes. With tall unnumbered, they
tax silhouette variety, the stations' known weakness, by an
amount each reviewer invents; the craft cost is unmeasurable
because the rule is.
ST7. OBSERVED (pack section 7, ST7). The exemption buys build
economy on thin members. It taxes the destruction moment: a
truss that breaks into a decal shell spends the credibility
the breakable-by-design rule (R98) buys everywhere else.
ST8. OBSERVED (pack section 7, ST8). The sizing formula buys
continuity with the kit at exactly one size. Every smaller
station is craft nobody has seen; the game's station set is,
in effect, one judged size and a formula's guesses.
ST9. OBSERVED (pack section 7, ST9). Two variants buy depth of
finish on what exists. They tax recognition and place: every
station in a campaign is one of two silhouettes, and no craft
spent on them can change that count.
ST10. OBSERVED (pack section 7, ST10). Stale documentation
buys nothing. It taxes every station job's starting point,
because the kit's own description misstates what the kit is
for, and a builder's first picture of the work is three jobs
out of date.

4. AGENT LEAD LENS

NB1. OBSERVED (pack section 3, NB1). The shipped bands hide in
code constants; the spec's four bands hide in a synthesis. A
review cannot tell which set a build used without reading
code, so the item wastes runs at review time: sheets get
argued against the wrong bands. Settlement is cheap and
already specified (one Codex run plus one owner review round).
NB2. OBSERVED (pack section 3, NB2). Four constants in material
setup, no sweep artefact exists to review against. Any future
density complaint restarts tuning from zero because no sheet
records what was tried.
NB3. OBSERVED (pack section 3, NB3). Enforceable only on edge
close-ups, which the pack folds into the issue 139 sheet run
at no extra run. Until those sheets exist, mask quality is
unreviewable and will be re-argued per patch (per-asset
adjudication).
NB4. OBSERVED (pack section 3, NB4). The caps are reviewable
only if a ramp sheet at relaxed caps exists; it does not. The
pipeline currently enforces taste by constant, which no sheet
can overturn, so the caps will outlive their evidence by
default.
NB5. OBSERVED (pack section 3, NB5). A single named constant
(line 37) is the most enforceable form a dial can take; the
pipeline failure is that its one review (the E17 settlement)
has not run, so the dial's position is unjudged rather than
unenforceable.
NB6. OBSERVED (pack section 3, NB6). An owner ruling with no
comparison sheet behind it cannot be revisited cheaply later:
any future sameness complaint pays for the first alternative
sheet then. One owner review round buys the comparison now,
while issue 139 is already sheeting patches.
NB7. OBSERVED (pack section 3, NB7). The anchored cap is
enforceable as a number and unreviewable as a claim: no sheet
in the pipeline tests hull crispness inside gas at densities
around it. The crater: an external citation in a synthesis is
doing the work a capture should do.
NB8. OBSERVED (pack section 3, NB8). Not buildable as written:
a spec whose base value does not exist forces every builder
to invent it, and the invention is invisible to review. This
is the pack's clearest wasted-runs item in the nebula set,
because divergent bases surface only as unexplainable
differences between builds.
NB9. OBSERVED (pack section 3, NB9). The structure is buildable
(issue 139 carries it) but its two load values were never
variant-tested, so the volume build locks them in at full
construction cost; changing either after 139 costs a rebuild,
not a retune.
NB10. OBSERVED (pack section 3, NB10). Shipped constants with
no research defence: a reviewer has nothing to check a storm
sheet against except taste, so storm look will be adjudicated
per build. One lifted variant in the 139 run converts taste
into a recorded pick.
NB11. OBSERVED (pack section 3, NB11). The mixed denomination
(units beside hexes, no conversion) makes the item
unenforceable as written: a reviewer cannot verify a 12-unit
boost radius against a hex-denominated sheet without a
conversion the spec does not give. The 139 recording round is
already bought; the checklist use costs nothing extra.
NB12. OBSERVED (pack section 3, NB12). The settlement is
already directed (issue 207's effects isolation run, one Opus
run) and this item only names the fog case inside it. Until
that run lands, every tier discussion in issues 139 and 100
argues from an unmeasured ladder and will be re-argued after.
NB13. OBSERVED (pack section 3, NB13). Shared settlement with
NB12 at no extra run. The pipeline risk is sequencing: issue
100 carries the ladder as a build task before the cost table
that should order it exists, so the ladder may be built
unpriced and rebuilt priced.
PL1. OBSERVED (pack section 4, PL1). Placement ranges are code
constants a sheet can judge in one existing run; until sheeted,
every map review silently accepts the framing. No extra build
is needed, which makes the continued absence a scheduling
failure, not a cost problem.
PL2. OBSERVED (pack section 4, PL2). Shares PL1's sheet run.
The pipeline point is leverage: this one judgement also
unlocks PL8's margin question, because the margin is defined
against this size.
PL3. OBSERVED (pack section 4, PL3). A 60-second capture folded
into an existing recording round is nearly free; the item's
cost is that nobody has spent it, so spin remains a constant
no review has ever seen move.
PL4. OBSERVED (pack section 4, PL4). The contact sheet is one
script build (one-time) plus one owner review round, and it is
the variety baseline for PL5, PL6, PL7, and later PL14. High
settlement leverage per run spent; without it, four items get
adjudicated per map instead.
PL5. OBSERVED (pack section 4, PL5). Folds into PL4's sheet at
no extra run (margins at both extremes). Zero marginal cost;
the only waste is if the PL4 sheet is taken without the moon
variants and the question returns later at full price.
PL6. OBSERVED (pack section 4, PL6). Same shared settlement as
PL5. A distribution is the cheapest kind of gate to judge,
because one contact sheet shows the whole population at once.
PL7. OBSERVED (pack section 4, PL7). One ringed variant in the
issue 140 run. The pipeline point: 140 is already rebuilding
planet looks, so the marginal cost of the variant is at its
lowest now and rises after 140 closes.
PL8. OBSERVED (pack section 4, PL8). An assert is the most
enforceable and least reviewable form of gate: it cannot be
argued with on a sheet, only obeyed or deleted in code. Its
settlement sheet (relaxes to 3x and 2x) shares AS1's question
and should share AS1's run, or the pipeline pays twice to
learn one thing about scale.
PL9. OBSERVED (pack section 4, PL9). The formula is buildable
and its inputs are two named constants; sheeting two sink
depths inside the 140 run prices the assumption at one owner
review round. Until then, every play-area battle is composed
on unjudged inputs.
PL10. OBSERVED (pack section 4, PL10). Folds into 140's close
zoom sheets at no extra run. The waste mode is familiar: if
the sheets are taken for texture only and nobody checks the
silhouette, faceting ships and returns as a new finding.
PL11. OBSERVED (pack section 4, PL11). The route is enforceable
(it scopes issue 140) and self-testing: 140's before and after
sheets are the evidence, at one owner review round. The
pipeline risk is only that the trigger (after sheets miss the
bar) needs the owner to say so on the record, or the route
question returns informally forever.
PL12. OBSERVED (pack section 4, PL12). Cold bake timing is
already required in issue 140's done-when, so the settlement
is bought; what is missing is any record connecting the timing
to the 20 second cap and the cache size, so the numbers will
need a second pass to become a judgement.
PL13. OBSERVED (pack section 4, PL13). One low-tier capture at
1440p inside the 139 sheet run. Cheap; the waste if skipped is
that the low tier's whole look ships unreviewed and the first
judgement happens in a player's screenshot, not a review.
PL14. OBSERVED (pack section 4, PL14). Costs one owner review
round on the PL4 sheet retaken after 140. The sequencing is
the pipeline fact: the settlement cannot run until 140 lands,
so the constraint should be recorded as expiring at that
sheet, or it will persist by inertia.

AS1. OBSERVED (pack section 5, AS1). The assert makes the gate
perfectly enforceable and perfectly unreviewable: builds fail,
sheets cannot appeal. Its settlement (three caps sheeted, one
Codex run plus one owner review round) is the highest-leverage
run in the pack, because AS8 and PL8 both settle inside it.
AS2. OBSERVED (pack section 5, AS2). Counts are trivially
buildable and sheetable; the sweep (0.6x, 1x, 1.6x on two map
kinds, one Codex run) is one run that also carries AS4, AS6,
AS9, and AS15 at no extra build cost. The current waste is
that richness complaints have no sheet to land on.
AS3. OBSERVED (pack section 5, AS3). Settlement shared with
the NB12 per-tier cost table (one Opus run) if fields are
included in it. The pipeline must name fields in that run
explicitly, or this multiplier survives unpriced by omission.
AS4. OBSERVED (pack section 5, AS4). No separate settlement
cost: the edge field is visible on every AS2 sweep sheet. The
review discipline is to judge the distribution on those
sheets by name, or it stays unjudged inside a settled item.
AS5. OBSERVED (pack section 5, AS5). One side-view capture
folded into the AS1 sweep. The item's pipeline lesson is that
 judgement artefacts must be specified per item (a side view,
here), or top-down sheets settle items they cannot show.
AS6. OBSERVED (pack section 5, AS6). Folds into the AS2 density
sheets. A formula with no research document behind it is
reviewable only on captures; the sheets are the document it
never had.
AS7. OBSERVED (pack section 5, AS7). Sigma variants (120, 240)
ride the AS2 run; the centre exclusion can be judged on the
same sheets. Because the belt is 139's showcase map, leaving
these unjudged contaminates 139's own sheets, which will be
read as shader verdicts on numbers that are actually belt
composition.
AS8. OBSERVED (pack section 5, AS8). Settles inside AS1's run
at no extra cost (the mountain sheet is the deciding capture).
The pipeline failure to record is the interaction itself: two
items in two build functions, one silently capping the other,
discovered by a pack, not by any build or review.
AS9. OBSERVED (pack section 5, AS9). Twelve versus 24 clusters
folds into the AS2 run. With no design document, the sheet is
also the feature's first specification; skipping it leaves a
shipped feature that no document in the project describes.
AS10. OBSERVED (pack section 5, AS10). One 30-second capture
across two fields, folded into the AS14 settlement. Cheap;
the waste it prevents is per-field motion re-tuning each time
a field is touched, against five private standards.
AS11. OBSERVED (pack section 5, AS11). A counted fixture is
the pipeline's friend: it is the comparison baseline for AS10
and AS14 at zero cost. The only discipline needed is citation
hygiene (fixture, not field), which costs nothing.
AS12. OBSERVED (pack section 5, AS12). Debris hexes at both
count bands sheet inside the issue 100 run (one owner review
round). The pipeline point is ordering: 100 also builds
AS16's spec, so the count judgement and the spec
reconciliation (AS16) must land together or 100 adjudicates
them separately by accident.
AS13. OBSERVED (pack section 5, AS13). Graveyard sheets at 55
and 100 percent hero chance ride the issue 100 run. A coin
flip is unreviewable in a single build (any one field may
look right by chance), so the two-variant sheet is the only
form of review this item can ever get.
AS14. OBSERVED (pack section 5, AS14). The settlement is
documentation plus one sheet: reconcile the two adopted
documents into one motion figure (one Opus run) and sheet
debris at both rates (one owner review round). Until then,
every debris build is simultaneously compliant and
non-compliant, the worst state a spec can be in.
AS15. OBSERVED (pack section 5, AS15). Half-count capture folds
into the AS2 run at no extra build. Dust is also cut by AS3's
tier logic and PL13's ladder logic in different places, so
the review should record the count per tier on the sheet, or
the three cuts compound invisibly.
AS16. OBSERVED (pack section 5, AS16). One reconciliation pass
(one Opus run) listing spec versus code per value, before
issue 100 runs. This is the pack's cheapest insurance: without
it, 100's builder implements one document, its reviewer reads
the other, and the difference burns a full build-review cycle.
AS17. OBSERVED (pack section 5, AS17). One battle sheet at two
blocker sizes on an existing run (one owner review round).
The dual size currency (units here, angles in AS1) should be
recorded in the same pass, or the next rock system invents a
third.
AS18. OBSERVED (pack section 5, AS18). Shares AS16's
reconciliation run. Two adopted documents disagreeing by 0.34
units is a one-line fix in a reconciliation and a build
failure or a silent violation without one.
BD1. OBSERVED (pack section 6, BD1). One Codex run (two bake
resolutions sheeted at 4K) plus one owner review round settles
the largest surface in the game, and the same run carries
BD2, BD3, BD9, BD12, and BD14 as bake-parameter variants.
Highest artefact leverage in the backdrop set.
BD2. OBSERVED (pack section 6, BD2). The loader and shader step
counts disagree on paper; whether the loader value reaches
the shader is NOT IN PACK (the pack says the two do not
obviously agree). The BD1 run's banding comparison settles the
quality question; a code read settles the wiring, and the leg
prices only the sheet side: folded into BD1, one owner review
round.
BD3. OBSERVED (pack section 6, BD3). The A/B folds into BD1. A
constant whose consumer is undocumented is a pipeline smell:
if nothing reads the radiance bake at this size, the number
is dead weight in every future bake discussion.
BD4. OBSERVED (pack section 6, BD4). Sheeting two region lamp
counts folds into an existing run. The coupling to BD10 means
this item should be judged on the BD10 contact sheet's
regions, or lamp counts get tuned per complaint instead of
per region.
BD5. OBSERVED (pack section 6, BD5). Folds into BD1's sky
sheets. The inverse formula is enforceable in code and
invisible in review unless a nebula-heavy sky is sheeted with
its galaxy count stated; sheets should carry the count.
BD6. OBSERVED (pack section 6, BD6). The settlement is a count
before it is a sheet: one script build (one-time) to report
stars per steradian at the battle camera, plus one owner
review round on a relaxed threshold set. The pack's H3 pattern
in pure form: an uncounted inheritance running the base
texture of the game.
BD7. OBSERVED (pack section 6, BD7). Folds into BD1's sheets;
band widths are bake parameters, so the marginal cost is
variant bakes in a run already bought. Judgement should name
the band against PL1's planet placement on the same sheet.
BD8. OBSERVED (pack section 6, BD8). The E18 settlement (density
sweep with star brightness sampled) settles this item if the
floor is named in it: one script annotation on an existing
run. The pipeline fix is naming, not building; two regimes
become one document of record.
BD9. OBSERVED (pack section 6, BD9). One bake pair (1.45,
1.15) folds into BD1. Until it runs, nebula colour work (NB4)
risks fixing the caps while the grade pushes the other way,
which is how a pipeline burns two builds on one failure.
BD10. OBSERVED (pack section 6, BD10). The six-region contact
sheet (one script build, one-time, plus one owner review
round) is the cheapest high-coverage settlement in the pack:
one artefact judges the table that feeds AS2, BD4, BD5, BD6,
and dust at once. Every region-level complaint before this
sheet exists is adjudicated blind.
BD11. OBSERVED (pack section 6, BD11). Visible on the BD10
contact sheet at no extra cost. The pipeline should record
the yaw's purpose in the same pass, or the range stays a
magic number future builders are afraid to touch.
BD12. OBSERVED (pack section 6, BD12). A bake parameter, folds
into BD1's comparison. Shell variants are cheap inside a bake
run and expensive as a standalone question later.
BD13. OBSERVED (pack section 6, BD13). One capture with wisps
off, folded into an existing run. This is the model settlement
for faint systems: a single off-capture converts an invisible
contribution into a kept or cut decision with evidence.
BD14. OBSERVED (pack section 6, BD14). Warmed and cooled albedo
sheets fold into BD1. A global grade judged once, cheaply,
instead of being re-litigated inside every other item's
colour complaints.
BD15. OBSERVED (pack section 6, BD15). One Codex run (interim
dressing against world.gd fields on the same map) plus one
owner review round. The word interim in a shipped file is a
pipeline debt marker: until the comparison runs, the project
does not know which of its two backdrop systems it ships.
BD16. OBSERVED (pack section 6, BD16). A documentation
settlement (one Opus run) reconciles spec text to shipped
values, or a sheet at both strengths if the chair prefers. The
R82 Q3 ruling covering both readings is what let the 2x gap
survive; the reconciliation must record which value is the
decision, not just fix the text.
BD17. OBSERVED (pack section 6, BD17). The process settlement
costs no run: state the look on every future sheet. Plus one
cine versus living side by side on a nebula map (one owner
review round). Until the process fix lands, every other
settlement in this pack carries an unrecorded multiplier.
BD18. OBSERVED (pack section 6, BD18). Settlement is the issue
207 benchmark run per tier with the environment on (one Opus
run; the effects-off isolation run names the environment
share). It is already directed; this audit's contribution is
the list of five hangers that must stop citing tier cost as a
reason until it lands.
BD19. OBSERVED (pack section 6, BD19). Issue 100's before and
after stills, reviewed constant by constant (one owner review
round); variants cost one Codex run if the first build
misses. Building a dozen constants at once is a pipeline
choice; the constant-by-constant review list is what makes
the build attributable afterwards.
ST1. OBSERVED (pack section 7, ST1). Issue 199's sheets are
the test in progress, so the doctrine currently costs nothing
extra. The pipeline decision is what happens on a miss: the
pack prices one comparison build with the doctrine relaxed
(one Codex run plus one owner review round). Pre-agreeing
that fallback now prevents a miss from becoming a deadlock
between the doctrine and the complaint that motivated the job.
ST2. OBSERVED (pack section 7, ST2). Additions at 2 and 4
units proud fold into the issue 199 run (one owner review
round). Marginal cost is at its lowest inside 199; after 199,
the same question costs a full station build to ask.
ST3. OBSERVED (pack section 7, ST3). Conversion of exact
equalities to reported values is one Opus run, one-time, and
it keeps the R94 shapes as the default build, so nothing the
owner approved is lost. Exact asserts are free to keep and
expensive to keep forever: every future station idea pays a
build failure to be considered.
ST4. OBSERVED (pack section 7, ST4). One unattended count and
timing of both current stations (one script build, one-time)
is the cheapest settlement in the pack relative to what it
unblocks: issue 199's brief stops aiming at an uncounted
baseline. Under the Nov 6 rulings the target already stands
as assumed reporting only; the count is what converts it.
ST5. OBSERVED (pack section 7, ST5). One Opus run converts or
removes the assert, folding into issue 208's settlement
program. This is the only item in the pack where the fix is
already fully decided by a standing ruling; every day it
stays live, the kit can fail a build the owner has already
approved in principle.
ST6. OBSERVED (pack section 7, ST6). Judging the 199 sheets
with the bans' scope stated on them costs one owner review
round and one line of expiry in the issue 208 settlement. An
unnumbered, unexpiring ban is unenforceable in review and
unremovable by evidence, the worst combination a rule can
have.
ST7. OBSERVED (pack section 7, ST7). The settlement rides the
first station break test in the destruction work (one owner
review round on that capture). No standalone run is justified;
the pipeline point is to put the capture on that job's list
now, or the exemption ships untested by omission.
ST8. OBSERVED (pack section 7, ST8). One capture of a 3-hex
station folded into an existing run (one owner review round).
Cheap; the alternative is that a whole size class of stations
is discovered by players rather than by review.
ST9. OBSERVED (pack section 7, ST9). The pack itself routes
this to the legs' owner questions: it is a direction
decision, not a build. Cost is one owner review round to
decide. The pipeline waste it prevents is issue 199 spending
its full depth budget before the breadth question is asked.
ST10. OBSERVED (pack section 7, ST10). One documentation pass
(one Opus run, one-time) against the current kit. Documentation
drift is the mechanism that preserved ST5; fixing the doc in
the same pass as the assert converts two findings into one
run.

5. DISPOSITION TABLE

Format per row: disposition; replacement approach where the
disposition is RE-DERIVE or REPLACE; cost in agent terms with
one-time and recurring stated separately. Under the pack
section 10 ground rule, no row below proposes a fresh fixed
cap; where a number survives, it survives as a reported build
parameter or a default until the named measurement settles it.

NB1 | REPLACE | The shipped band set stops binding as the
unexamined default of record; replaced by the winner of a
two-band-set comparison (shipped bands against the terrain
spec's bands) under the issue 139 volume shader, sheeted at
battle and close camera. Cost: One-time: 1 Codex run + 1 owner
review round. Recurring: none.
NB2 | RE-DERIVE | Three-step alpha and density sweep on one
patch under the new shader; the winning step is recorded on
the sheet, not as a new fixed gate. Cost: One-time: 1 Codex
run + 1 owner review round. Recurring: none.
NB3 | RE-DERIVE | Edge close-ups at two feather and texel
settings inside the issue 139 sheet run; owner's eye decides.
Cost: One-time: no extra run (rides NB2 and issue 139 sheets);
1 owner review round shared with issue 139. Recurring: none.
NB4 | RE-DERIVE | Ramp sheeted with the channel caps relaxed
in steps on a warm and a cool faction sky; caps survive only
at the step the owner picks. Cost: One-time: 1 owner review
round on an existing sheet run. Recurring: none.
NB5 | RE-DERIVE | Rides the fx E17 settlement (three weights
on a warm faction sky); the same round answers whether the
winner stays global or becomes per-region via BD10. Cost:
One-time: 1 owner review round (shared with E17). Recurring:
none.
NB6 | RE-DERIVE | The fixed-family rule stops binding until
sheeted: same patch in the violet family and one alternative
family under the volume shader. Cost: One-time: 1 owner
review round. Recurring: none.
NB7 | REPLACE | The EVE-anchored 0.7 cap is removed as a
binding gate (no measurement in this game earned it); the
qualitative R82 Q2 rule (hulls crisp, gas dims sky only)
stays, and density becomes a reported parameter settled by a
ship-in-patch sheet at three centre densities judged for hull
crispness. Any future numeric cap must name that sheet series
as its earning measurement. Cost: One-time: 1 Codex run + 1
owner review round. Recurring: none.
NB8 | REPLACE | Multipliers on an unnumbered base are replaced
by one consolidated nebula and storm motion specification
that numbers the base drift rate and states each layer's
rate, judged against the issue 139 recordings with one
flattened variant. Cost: One-time: 1 Opus run (spec) + 1 owner
review round. Recurring: none.
NB9 | RE-DERIVE | One patch at two layer counts sheeted in
the issue 139 run before the volume build locks the
structure. Cost: One-time: no extra run beyond the variant
build inside issue 139; 1 owner review round shared with
issue 139. Recurring: none.
NB10 | RE-DERIVE | Storm sheets at the shipped stops and one
lifted variant in the issue 139 run. Cost: One-time: 1 owner
review round. Recurring: none.
NB11 | RE-DERIVE | The issue 139 10-second storm recording is
reviewed against these values as a checklist; the units and
hexes denomination mix is corrected in the NB8 spec pass.
Cost: One-time: 1 owner review round; spec text fix shared
with NB8's Opus run. Recurring: none.
NB12 | RE-DERIVE | Per-tier fog light cost measured inside
the issue 207 benchmark's effects isolation run; until it
lands, tier gating stands as a feature flag, not a cost
claim. Cost: One-time: 1 Opus run (already directed; this
names the fog case). Recurring: none.
NB13 | RE-DERIVE | Same per-tier cost table as NB12 prices
each ladder element; the protection ranking binds only after
it is priced. Cost: One-time: shared with NB12's Opus run.
Recurring: none.
PL1 | RE-DERIVE | One map sheeted at three placements outside
the current bands on an existing run. Cost: One-time: 1 owner
review round. Recurring: none.
PL2 | RE-DERIVE | Same sheet run as PL1, planets at both band
edges and one step beyond. Cost: One-time: 1 owner review round
shared with PL1. Recurring: none.
PL3 | RE-DERIVE | One 60-second capture at the top of the
range, folded into the issue 139 recording round. Cost:
One-time: 1 owner review round shared with that round.
Recurring: none.
PL4 | RE-DERIVE | Contact sheet of all 8 looks at the battle
camera; the sheet is the variety baseline for PL5, PL6, PL7,
and PL14. Cost: One-time: 1 script build + 1 owner review
round. Recurring: none.
PL5 | RE-DERIVE | Moons at both margin extremes on the PL4
contact sheet. Cost: One-time: no extra run; owner review
round shared with PL4. Recurring: none.
PL6 | RE-DERIVE | Judged on the PL4 contact sheet. Cost:
One-time: owner review round shared with PL4. Recurring: none.
PL7 | RE-DERIVE | The exactly-2 ration stops binding as a
rule; one ringed variant sheeted at the battle camera in the
issue 140 run and the count follows the owner's eye. Cost:
One-time: 1 owner review round. Recurring: none.
PL8 | REPLACE | The 4.4x margin assert is converted to a
reported ratio on sheets (it can no longer fail a build);
the margin itself is settled on AS1's sweep sheets with the
margin relaxed to 3x and 2x, judged for whether rocks read as
near objects. A fresh margin, if any, must name that sheet
series as its earning measurement. Cost: One-time: shared
with AS1's Codex run + owner review round; assert conversion
shared with ST5's Opus run. Recurring: none.
PL9 | RE-DERIVE | The derived radius formula keeps; its two
assumed inputs (1.5 multiplier, 78 percent sink) settle on a
battle sheeted at two sink depths in the issue 140 run. Cost:
One-time: 1 owner review round. Recurring: none.
PL10 | RE-DERIVE | Close-zoom capture checked for faceting,
folded into issue 140's close zoom sheets. Cost: One-time: no
extra run; owner review round shared with issue 140.
Recurring: none.
PL11 | KEEP | Owner route ruling with its own evidence
trigger: issue 140's before and after sheets are the test,
and the route question returns only if those sheets miss the
owner's bar. Cost: One-time: 1 owner review round (the 140
judgement itself). Recurring: none.
PL12 | RE-DERIVE | Cold-start bake timing on a storm and a
planet map, reported in issue 140's done-when (already
required); cache size and wait cap stand as engineering
defaults until that timing exists. Cost: One-time: no extra
run. Recurring: none.
PL13 | RE-DERIVE | One low-tier sky capture at 1440p in the
issue 139 sheet run. Cost: One-time: 1 owner review round.
Recurring: none.
PL14 | REPLACE | The giants-unchanged constraint is replaced
by a dated judgement: the PL4 contact sheet retaken after
issue 140, judged for whether the giants still sit in the
same sky; the constraint expires at that sheet unless the
owner renews it there. Cost: One-time: 1 owner review round
on the retaken sheet. Recurring: none.
AS1 | REPLACE | The 0.05 rad assert is converted to a reported
build parameter (it can no longer fail a build); the cap
value itself is settled by belt and mountain sheets at 0.05,
0.09, and 0.14 rad judged for looming against clutter. Any
fresh cap must name that sheet series as its earning
measurement. Cost: One-time: 1 Codex run + 1 owner review
round; assert conversion shared with ST5's Opus run.
Recurring: none.
AS2 | RE-DERIVE | Belt and graveyard maps sheeted at 0.6x, 1x,
and 1.6x counts; winning densities recorded per map kind on
the sheets. Cost: One-time: 1 Codex run + 1 owner review
round. Recurring: none.
AS3 | RE-DERIVE | The 0.6x multiplier stands as a default
until the per-tier cost table (NB12 settlement, fields
explicitly included) prices it. Cost: One-time: shared with
NB12's Opus run. Recurring: none.
AS4 | RE-DERIVE | Judged by name on the AS2 sweep sheets (the
edge field is visible on every map). Cost: One-time: owner
review round shared with AS2. Recurring: none.
AS5 | RE-DERIVE | One side-view capture of the field, folded
into the AS1 cap sweep. Cost: One-time: owner review round
shared with AS1. Recurring: none.
AS6 | RE-DERIVE | Judged on the AS2 density sheets. Cost:
One-time: owner review round shared with AS2. Recurring: none.
AS7 | RE-DERIVE | Belt sheets at sigma 120 and 240 in the AS2
run; centre exclusion judged on the same sheets. Cost:
One-time: owner review round shared with AS2. Recurring: none.
AS8 | REPLACE | The mountain range stops being silently
subordinate: until AS1 settles, mountain size is reported as
its effective capped value on sheets, and the mountain sheet
inside AS1's sweep is the deciding capture for both items.
Cost: One-time: shared with AS1's Codex run + owner review
round. Recurring: none.
AS9 | RE-DERIVE | One capture with clusters at 12 and at 24,
folded into the AS2 run; the winning sheet also becomes the
feature's first design record. Cost: One-time: owner review
round shared with AS2. Recurring: none.
AS10 | RE-DERIVE | One 30-second capture across two fields,
folded into the AS14 settlement; per-field ranges are then
recorded against one motion standard. Cost: One-time: owner
review round shared with AS14. Recurring: none.
AS11 | KEEP | Measured fixture; kept as the comparison
baseline for AS10 and AS14, cited as a fixture and never as
game behaviour. Cost: none.
AS12 | RE-DERIVE | One debris hex sheeted at both count bands
in the issue 100 run. Cost: One-time: 1 owner review round.
Recurring: none.
AS13 | RE-DERIVE | Graveyard sheets at hero chance 55 and 100
percent in the issue 100 run. Cost: One-time: 1 owner review
round (shared round with AS12 inside issue 100). Recurring:
none.
AS14 | REPLACE | The two conflicting adopted tumble standards
are replaced by one consolidated motion figure of record; the
reconciliation states the conversion it used, and debris is
sheeted at both rates before the figure binds. Cost: One-time:
1 Opus run + 1 owner review round. Recurring: none.
AS15 | RE-DERIVE | One capture with dust at shipped counts and
at half, folded into the AS2 run, with the count per tier
recorded on the sheet. Cost: One-time: owner review round
shared with AS2. Recurring: none.
AS16 | REPLACE | The spec-versus-code conflict is replaced by
one reconciliation pass listing spec against code per value,
completed before issue 100 runs; the reconciled text is the
single document of record for debris structure. Cost:
One-time: 1 Opus run. Recurring: none.
AS17 | RE-DERIVE | One battle sheet with a blocker at 13 to 15
and at 20 units, judged against the ships beside it, on an
existing run. Cost: One-time: 1 owner review round.
Recurring: none.
AS18 | RE-DERIVE | The derived cap keeps; its half-width input
is settled inside the AS16 reconciliation, which must state
which document governs wreck sizes at the top end. Cost:
One-time: shared with AS16's Opus run. Recurring: none.

BD1 | RE-DERIVE | One sky baked at 4096 and 8192 wide,
sheeted at 4K; the run also carries the BD2, BD3, BD9, BD12,
and BD14 bake variants. Cost: One-time: 1 Codex run + 1 owner
review round. Recurring: none.
BD2 | RE-DERIVE | One bake at 26 and 64 steps compared for
banding, folded into the BD1 run; the loader-versus-shader
disagreement is recorded as a finding of that run. Cost:
One-time: owner review round shared with BD1. Recurring: none.
BD3 | RE-DERIVE | A/B capture at 256 and 512, folded into the
BD1 run. Cost: One-time: owner review round shared with BD1.
Recurring: none.
BD4 | RE-DERIVE | One battle sheeted under two region lamp
counts, folded into an existing run and judged per region on
the BD10 contact sheet. Cost: One-time: 1 owner review round.
Recurring: none.
BD5 | RE-DERIVE | Judged on the BD1 sky sheets with galaxy
counts stated per sheet. Cost: One-time: owner review round
shared with BD1. Recurring: none.
BD6 | RE-DERIVE | Star density counted (stars per steradian
at the battle camera) plus one sheet at a relaxed threshold
set. Cost: One-time: 1 script build + 1 owner review round.
Recurring: none.
BD7 | RE-DERIVE | Band widths judged on the BD1 sheets
against PL1's planet placement. Cost: One-time: owner review
round shared with BD1. Recurring: none.
BD8 | RE-DERIVE | Settled inside the fx E18 settlement (density
sweep capture with star brightness sampled) with this 0.15
floor named in it, so one document governs star dimming.
Cost: One-time: 1 script annotation on an existing run.
Recurring: none.
BD9 | RE-DERIVE | One bake at saturation 1.45 and at 1.15,
sheeted side by side, folded into the BD1 run; judged before
any further NB4 cap work. Cost: One-time: owner review round
shared with BD1. Recurring: none.
BD10 | RE-DERIVE | Six-region contact sheet at the battle
camera; per-region values stand or fall region by region on
that one artefact. Cost: One-time: 1 script build + 1 owner
review round. Recurring: none.
BD11 | RE-DERIVE | Judged on the BD10 contact sheet, with the
yaw's purpose recorded in the same pass. Cost: One-time:
owner review round shared with BD10. Recurring: none.
BD12 | RE-DERIVE | Shell variants folded into the BD1 bake
comparison. Cost: One-time: owner review round shared with
BD1. Recurring: none.
BD13 | RE-DERIVE | One capture with wisps off, folded into an
existing run; if the contribution is invisible, the subsystem
is cut or kept by that evidence, not by its gain constant.
Cost: One-time: 1 owner review round. Recurring: none.
BD14 | RE-DERIVE | One sheet at a warmed and a cooled albedo,
folded into the BD1 run. Cost: One-time: owner review round
shared with BD1. Recurring: none.
BD15 | REPLACE | The interim dressing stops being the silent
shipped path: replaced by an explicit decision after one
capture comparing the interim dressing against the world.gd
fields on the same map; whichever path wins is recorded as
the design, and the loser's coupling to board bounds is
documented. Cost: One-time: 1 Codex run + 1 owner review
round. Recurring: none.
BD16 | REPLACE | The 2x spec-versus-code disagreement is
replaced by one document of record: the reconciliation states
which tint strength is the decision (the shipped values,
unless the owner picks otherwise in the round), and the other
text is corrected to match. R82 Q3's qualitative ruling
(tint reduced, faint tint kept) is untouched. Cost: One-time:
1 Opus run. Recurring: none.
BD17 | REPLACE | The unrecorded-judgement condition is
replaced by a process rule: every sheet and capture states
its board look, effective immediately, plus one cine versus
living side by side on a nebula map to judge the defaults
against each other. The owner's cine default pick itself
stands. Cost: One-time: 1 owner review round; the process
rule costs no run. Recurring: none.
BD18 | RE-DERIVE | The issue 207 benchmark runs per tier with
the environment on; the effects-off isolation run names the
environment share. Until it lands, NB12, NB13, AS3, BD13, and
PL13 keep their feature flags but lose tier cost as a stated
reason. Cost: One-time: 1 Opus run (already directed).
Recurring: none.
BD19 | RE-DERIVE | Issue 100's before and after stills
reviewed constant by constant against this list; no constant
binds beyond the owner's read of those stills. Cost: One-time:
1 owner review round; variants 1 Codex run if the first build
misses. Recurring: none.
ST1 | RE-DERIVE | The additions-only doctrine stands for
issue 199 as a hypothesis with a named test (the 199 sheets);
it stops binding as permanent law. If the sheets miss the
owner's bar, one comparison build with the doctrine relaxed
on one station decides whether the plainness lives in the
locked shapes. Cost: One-time: 1 owner review round on the
199 sheets; contingent 1 Codex run + 1 owner review round if
they miss. Recurring: none.
ST2 | RE-DERIVE | One station sheeted with additions at 2 and
4 units proud, folded into the issue 199 run. Cost: One-time:
1 owner review round. Recurring: none.
ST3 | REPLACE | Exact-equality asserts are converted to
reported values; the R94 shapes remain the default build, so
nothing the owner approved is lost, and a future silhouette
improvement is judged on a sheet instead of failing a build.
Cost: One-time: 1 Opus run. Recurring: none.
ST4 | RE-DERIVE | One unattended count and timing of both
current stations converts the target from assumed reporting
into a measured baseline. Cost: One-time: 1 script build.
Recurring: none.
ST5 | REPLACE | The line 949 tri assert is removed or
converted to a reported value, implementing the owner's Nov 6
removal; folds into issue 208's settlement program. Cost:
One-time: 1 Opus run (shared with ST3's conversion pass).
Recurring: none.
ST6 | RE-DERIVE | The bans are judged on the issue 199 sheets
with their scope stated on the sheets (this pass only), and
an expiry line is added in the issue 208 settlement so they
cannot outlive the pass by inertia. Cost: One-time: 1 owner
review round. Recurring: none.
ST7 | RE-DERIVE | One broken-truss capture from the first
station break test, folded into the destruction work when it
runs; the exemption stands or falls on that capture. Cost:
One-time: 1 owner review round. Recurring: none.
ST8 | RE-DERIVE | One capture of a 3-hex station, folded into
an existing run. Cost: One-time: 1 owner review round.
Recurring: none.
ST9 | RE-DERIVE | Settled by owner direction (owner question
3 below) before issue 199 spends its full depth budget: depth
on two variants against a third variant at half depth,
decided on the record. Cost: One-time: 1 owner review round
to decide. Recurring: none.
ST10 | RE-DERIVE | One documentation pass over STATION_KIT.md
against the current kit, run in the same pass as ST5's assert
fix. Cost: One-time: 1 Opus run. Recurring: none.

Disposition tally: KEEP 2 (PL11, AS11), REPLACE 14 (NB1,
NB7, NB8, PL8, PL14, AS1, AS8, AS14, AS16, BD15, BD16, BD17,
ST3, ST5), RE-DERIVE 58 (the remaining rows), DROP 0. No DROP is proposed: every
gate in this stack protects something a sheet, a count, or a
reconciliation can price, and the ground rule's remedy for an
unearned gate is to stop it binding, which RE-DERIVE and
REPLACE both do. The asserts that fail builds (AS1, PL8, ST5,
and ST3's equalities) lose that power under REPLACE, which is
where this stack's DROP-equivalent force lands.

6. OWNER QUESTIONS

Q1. Should rocks be allowed to loom? The angular cap (AS1)
and its 4.4x planet margin (PL8) currently forbid any backdrop
rock from ever feeling near, and they are the chair's and this
leg's candidate root of your hollow-asteroids verdict. Pick:
YES, run the cap sweep (0.05, 0.09, 0.14) and let the sheets
decide, accepting some cluttered sheets as the price of the
test. Stakes: if looming is the missing depth cue, no other
environment job can buy it while the cap stands, because the
cap forbids the experiment itself.

Q2. Is sameness a bigger problem than fidelity right now? The
counts are 8 planet looks, 2 station variants, 1 nebula
colour family, 6 regions, and every queued job (139, 140,
199) raises fidelity inside those counts while none raises a
count. Pick: direct the contact sheets first (planet looks,
six regions), and have them answer where one added count buys
more than another fidelity pass, before the queued jobs spend
their full budgets. Stakes: if the counts are the real gate,
the entire environment queue perfects a repetition problem it
was meant to cure.

Q3. Depth or breadth on stations: should issue 199 finish
deepening the two existing station variants, or should part
of its budget buy a third variant at shallower finish? Pick:
third variant, at the cost of some 199 depth, because stations
are the smallest variety count in the game (2) and your R109
complaint was about sameness of shapes as much as surface.
Stakes: every station a player ever meets is one of two
silhouettes; depth cannot change that, and 199 is the last
cheap moment to change it before its budget is spent.

7. NOT CHECKED

- The current build's actual appearance, everywhere (pack
  section 9, item 1). Every judgement here is about constants,
  documents, and asserts, not about a single capture this leg
  has seen. No Godot project was run for this leg.
- Whether the loader's sky march step values (BD2) actually
  reach the bake shader. The pack states the two regimes do
  not obviously agree; the wiring itself is NOT IN PACK.
- Whether issue 139's or 140's branches have already moved any
  inventoried constant (pack section 9, item 5). This leg
  inventories main, as the pack does.
- Rock field constants that might live only in world_rocks.gd
  or blocker_visuals.gd and are absent from the pack inventory
  (pack section 9, item 3). If they exist, they are an
  inventory gap, and this leg does not invent them.
- The enginetest asteroids.json file itself, line by line
  (pack section 9, item 4); AS11's figures are taken as the
  pack carries them.
- The fx audit items cross-referenced in pack section 1.4
  (E14 to E23) on their own merits. They are treated as
  settled inventory here, per the pack's instruction, and are
  not re-audited.
- STATION_KIT.md beyond its framing text (pack section 9,
  item 6); ST10's staleness is taken as the pack states it.
- Any per-tier frame cost, anywhere. None exists in the pack;
  BD18's settlement is the issue 207 benchmark, which has not
  run.
