# Blind Rey writer leg: UI, menu, and campaign map red team

Written from PACK.md alone. No other sources. Chair hypotheses
in pack section 10 are tested, not repeated; where this leg
agrees with one, the agreement is argued from the inventory,
not quoted from the hypothesis.

## 1. Verdict

THE STACK HOLDS ONLY WITH REPLACEMENTS.

The stack exists and functions: the frozen JS build is the
currently playable game, and parts of the port are deliberate
(the lore-anchored face change TY1, the shared body face TY2,
the ported flagship convention IC3, the lore-tied crests IC6).
But of 64 gates, 0 are MEASURED, 0 are DERIVED, 5 are
ANCHORED, and 59 are ASSUMED, and the two builds silently
disagree on at least six values (HD5, HD7, HD9, HD11, HD13,
TY3). The port's one anchored colour item carries rounding
drift in two channels (HD10), which is the fingerprint of
transcription by eye; the disagreements that matter (HD7 at
67 percent) sit exactly where a value had to be re-derived
rather than copied. Three structural absences (AC1, AC2, MN8)
bind every player and were never chosen. Nothing found
requires a redesign; every failure is settleable by captures
the project already has scheduled, one consolidated
specification, one scripted constant diff, and a small number
of owner rulings. That is why the verdict is not DOES NOT
HOLD: the screens work, the failures are unmeasured values
and unrecorded decisions, not broken concepts.

The three items the verdict most depends on:

- HD1 (the HUD scaling law). One formula denominates every
  size in the Godot battle HUD, keyed to a 1080 design point
  the owner does not play at (floor 1440p, goal 4K), with
  clamp bounds that have no stated source. If the design
  point or the clamps are wrong, every HUD screen is wrong
  by the same factor at once. No other item has this blast
  radius.
- HD7 (nameplate geometry). The largest single numeric
  disagreement in the pack (bar 54 px shipped against s(90)
  in the port) sits on the element attached to every ship in
  every battle, and pack section 3 (X3) shows the
  plate-to-ship proportion inverts as the player zooms,
  which the owner does routinely (standard radius, zoom in
  for effects). One of the two builds is showing plates at a
  size nobody chose, at the game's core readability ratio.
- AC1 (no colour-vision support). The absence that binds the
  most players with zero measurement behind it. IFF (HD10),
  danger bands (MP8), and hull-low state (HD9) all speak
  colour first, and the game's own route lines (MP4) prove
  redundant encoding is possible in this codebase. If AC1
  were settled, the verdict would soften; as it stands, an
  entire player class reads the battle through a channel the
  project has never tested.

## 2. Game dev lens

HD1. The law binds everything and is denominated in window
height, not in anything the player pays; the player pays in
readability at 1440p and 4K, where k is 1.33 and 2.0 and no
capture has ever judged the result. A wrong design point is
a uniform error across the whole HUD. (OBSERVED, section 4;
INFERRED on cost from section 1.6 resolutions.)
HD2. 15 base is the reading size for every battle decision;
it binds information density, not frame cost. Wrong by one
step and every panel is either cramped or starved. The JS
agreement is nominal (fixed px against scaled s), so the two
builds diverge as resolution rises. (OBSERVED, section 4.)
HD3. No performance bind; the bind is hierarchy: the top bar
is read first in every battle, and the two builds put
different contents at different sizes, so the port is
silently a different battle screen. (OBSERVED, section 4.)
HD4. Binds gameplay directly: at fleets near 20 ships,
roster height decides whether fleet state is glanceable or
scrolled mid-battle; scrolling during a real-time-with-pause
fight is an input tax paid under pressure. (OBSERVED,
section 4; INFERRED on the input tax.)
HD5. A 24 px disagreement at the shared design height is
roughly two characters per weapon row; the panel carries hit
chances and orders, so the cost is truncated decision text
in one build. No engine cost either way. (OBSERVED,
section 4.)
HD6. The one HUD item with a real engine cost: the port's
uncapped rich-text log grows layout and memory cost across a
long battle, and the builds diverge in what of the fight
stays readable. Whether the port's underlying array is
capped is NOT IN PACK (pack section 11). (OBSERVED,
section 4.)
HD7. Binds the core battle read: plate size against ship
size at the zoom the player is actually using. A fixed pixel
plate on a variable-scale board (X3) cannot be right at both
of the owner's working zooms unless judged at both.
(OBSERVED, sections 4 and 3.)
HD8. Binds a targeting input: shield state feeds engagement
decisions. Pips read as discrete charges, a bar reads as a
fraction; the two builds teach two different shield models,
so a player crossing builds re-learns a combat read.
(OBSERVED, section 4; INFERRED on the re-learning cost.)
HD9. Gameplay cost near zero, which is itself the finding:
a threshold differing by 0.01 between builds has never been
felt, so neither value has ever been tested by being
noticed. It binds nothing and proves the drift pattern.
(OBSERVED, section 4.)
HD10. No gameplay cost; the values are anchored to the CSS
variables and the drift is one step in two channels,
sub-visible. Its dev value is diagnostic: it shows how the
port was made. (OBSERVED, section 4.)
HD11. The banner is battle punctuation at round boundaries;
nearly double size in the playable build against the port
means the two builds pace the same event at two volumes. No
input cost. (OBSERVED, section 4.)
HD12. Damage numbers are the densest simultaneous text in a
salvo; 19 px at the design point is denominated for 1080
while the owner plays at 1440p and 4K. Whether the port has
floating text at all is NOT IN PACK (section 11).
(OBSERVED, section 4.)
HD13. Tooltip width decides whether weapon and order
explanations are read or skipped mid-decision; 330 against
300 is another near-miss pair. No engine bind. (OBSERVED,
section 4.)
HD14. Binds input surface: developer buttons (report, copy
report, diagnostics) occupy the same bar as battle controls
in the playable build, so misclick surface and visual noise
sit on the game's main screen; the port removed them without
a recorded decision, which is a product change smuggled in
as a port. (OBSERVED, section 4.)
HD15. The JS backdrop blur is the HUD's only
backdrop-dependent cost and legibility risk: over a bright
nebula the glass panel's contrast changes, a failure mode
invisible in the dark captures the project usually judges.
The port's flat fill does not have this failure. (OBSERVED,
section 4; INFERRED on the contrast failure.)
MN1. Three sizing laws for one title; the JS vw law makes
the frozen build's title a function of window width while
the port's is a fit-to-width shrink. No gameplay bind; the
first screen's size is unjudged at the owner's resolutions
either way. (OBSERVED, section 5.)
MN2. Binds real input flow: shake, speed, and quality are
mid-battle decisions in the playable build and title-only in
the port. A player who cannot reach a comfort setting
mid-battle pays for the architecture in every uncomfortable
battle. (OBSERVED, section 5.)
MN3. Defaults are the game most players play. Quality "max"
as default interacts with the issue 207 scene gate, which
has not run, so the default currently promises a performance
tier nobody has measured. The fullscreen default also
contradicts the shipped window mode until applied.
(OBSERVED, section 5; the 207 interaction rests on
section 1.6.)
MN4. Tier naming binds nothing mechanically, but it is the
vocabulary the 207 benchmark results will be discussed in;
three naming sets plus a phone reference in a PC-only game
guarantee confusion in that conversation. (OBSERVED,
section 5 and section 1.6.)
MN5. The Fast value 0.45 is oddly precise for an unmeasured
constant; battle pace is a feel input and the choice's two
values have never been compared on a capture. Motion
parameters are fenced (F3); the choice surface is not.
(OBSERVED, section 5.)
MN6. The cut-in default decides how often the game
interrupts the player's own framing. The destruction audit
ruled the camera is otherwise never taken (pack F-adjacent,
section 5), so this default is the one standing exception,
and the interaction has never been stated in one place.
(OBSERVED, section 5.)
MN7. No gameplay bind; the end card is where battle results
are read, and its scale schism with HD11 and MN1 means the
port closes every battle quieter than the playable build.
(OBSERVED, section 5.)
MN8. Binds the game's core loop: the debrief is where a
roguelike teaches why a run was lost, and the run-learning
design depends on that teaching. An unspecified paragraph
inside other screens is the weakest carrier; the cost is
paid in repeat losses the player cannot diagnose.
(OBSERVED, section 5; INFERRED on the learning cost from the
pack's own statement of the design's dependence.)
MN9. Minor: neither build states what loading must show.
Load time cost is NOT IN PACK; the presentation gate is an
absence of a requirement, not a measured failure.
(OBSERVED, section 5.)
MN10. Two maintained campaign presentations double every
future campaign UI change and guarantee the drift pattern of
HD5 and HD9 repeats on the map. Which presentation a player
actually gets is NOT IN PACK (host code unread, section 11).
(OBSERVED, section 5.)
MN11. No bind; its dev interest is that the only screen
naming the fonts is the credits, making it an accidental
typography document. (OBSERVED, section 5.)
MN12. Disabled choices dimmed to 50 percent opacity with no
colour or label change is the campaign's only disabled rule;
event choices are story decisions, so a state the player
cannot read is a decision input degraded at exactly the
campaign's decision points. (OBSERVED, section 5.)
MP1. The SVG frame constants (1400 px cap, 230 px reserve)
have no source, but the form is superseded by MP6; the live
cost is only as today's playable baseline. (OBSERVED,
section 6.)
MP2. Node radius against a 900-unit viewBox sets click
targets and visual weight together; the boss at 26 is only
37 percent larger than a normal node, a weak size signal for
the map's most important stop. The pulse has no off switch
(see AC7). (OBSERVED, section 6.)
MP3. Two label colours exist outside the palette variables;
the Nemesis tag is the map's highest-stakes label and its
red was never approved by any palette decision. Cost: a
signal colour that nothing else in the game shares, so its
meaning is carried by position alone. (OBSERVED, section 6.)
MP4. The map's one redundant encoding: done, reachable, and
locked differ by colour, width, and dash together. This is
the proof inside the playable build that the project can
encode state without colour alone (compare AC1).
(OBSERVED, section 6.)
MP5. Column count 7 is the campaign's real pacing skeleton,
more load-bearing than any visual constant here; the pack
states it is out of this audit's gift to re-derive, and this
leg agrees: it is a campaign design constant, inventoried so
its presentation consequences are visible. (OBSERVED,
section 6.)
MP6. The largest presentation divergence in the pack: the
campaign's home screen changed medium. Six constants are the
entire written design record of a lit 3D orrery replacing a
flat diagram whose encodings (MP2 to MP4) players have
learned; whether the scene teaches itself is unmeasured.
(OBSERVED, section 6.)
MP7. Flight time 2.4 s is paid on every move of every run.
Too long reads as loading, too short makes the map
weightless; it has never been compared at two values.
(OBSERVED, section 6.)
MP8. Danger bands steer route choice, the campaign's
hardest repeated decision. The estimate is derived from real
fleet-budget numbers, but the cut points (0.8, 1.05, 1.4)
are assumed: a fight at 1.04 reads Even and at 1.06 reads
Hard, so mis-set cuts systematically mislabel decisions at
the boundary, which is where routing is decided.
(OBSERVED, section 6.)
MP9. The map toggle lives outside the settings dictionary,
so two controls can disagree about the same scene and
nothing records which wins; the map's 3D cost is then
invisible to the issue 207 benchmark family. An unreviewable
quality path is a dev-process failure, not just a UI one.
(OBSERVED, section 6.)
MP10. The port's legend drops icon chips to text only, a
quiet downgrade: node-type lookup goes from recognition to
reading on the screen where route planning happens.
(OBSERVED, section 6.)
MP11. The preview is where route decisions are actually
made; its colour semantics (what gilt means, what blood
means) are nowhere written, and one of its colours is
another one-off outside the palette. An unwritten code is
re-derived by every new player from scratch. (OBSERVED,
section 6.)
MP12. Station props are lerped toward neutral greys by
factors recorded only in comments (0.85, 0.4). Faction
identity on the map is being muted by an unrecorded amount,
so a colour gate binds without ever having been stated as
one. (OBSERVED, section 6.)
TY1. The face schism binds brand, not gameplay: the playable
game and its replacement present two different display
faces, and no document states when the player-facing change
happens. The Godot side is anchored in a recorded lore
decision; the JS side is the frozen incumbent. (OBSERVED,
section 7.)
TY2. The one clean typographic item: same body face both
builds, anchored. The only dev note is the fallback
difference (browser fallback stack against the port's file
load), which is a robustness note, not a gate failure.
(OBSERVED, section 7.)
TY3. Four base sizes (15, 16, 17, 18) across screens, each
locally plausible, never stated as a system. A player
crossing from battle to campaign crosses a size boundary
every time; sizes are also non-comparable across screens for
every other judgement in this pack. (OBSERVED, section 7.)
TY4. Three copies of the scaling law with two different
ceilings (2.2, 2.5, 2.2). Latent at 4K (k is 2.0 in all
three) but live in any taller or windowed arrangement, and
structurally wrong: a law that should exist once exists
three times. (OBSERVED, section 7.)
TY5. Height-only scaling denominates type by the wrong axis
for width-driven layouts: at 4K the 15 base renders at 30,
and no capture judges text at that size against the board it
labels. The failure appears only away from the design point.
(OBSERVED, section 7.)
TY6. 10 px text carries gameplay information (which map,
which orders) at the design point. Below comfortable reading
for a substantial share of players, and there is no minimum
size rule anywhere: the floor is wherever each implementer
stopped. (OBSERVED, section 7.)
TY7. The entire control scheme (about 30 inputs) is one
paragraph at 12 in the port, a 12 px block in the JS build.
No grouping or progressive disclosure. Control learning is
gameplay: inputs the player never finds are mechanics the
game does not have. (OBSERVED, section 7; INFERRED on the
last clause.)
TY8. The teaching cards are the tutorial; their density
decides whether new players learn the loop. One shared off
switch couples two systems: dismissing battle tips also
kills campaign teaching, a settings coupling nobody chose
on the record. (OBSERVED, section 7.)
TY9. The shrink floor at 12 interacts with MN1: a long title
on a narrow window stops shrinking and overflows or wraps by
other means. A floor denominated in points inside a scaled
system is a mixed-unit gate. (OBSERVED, section 7;
INFERRED on the mixed-unit point.)
TY10. JS line heights are stated (1.4, 1.45); the Godot
side's line spacing was not located, so the port takes an
engine and font default nobody chose. Condensed faces at
default spacing are a known tight read; the builds may
already differ invisibly. (OBSERVED, section 7, including
the stated gap.)
IC1. Two unrelated icon systems for the same node types, so
no icon survives the cutover: node-type recognition learned
in the playable build resets to zero in the port. That is a
gameplay cost (route reading speed) disguised as an art
change. (OBSERVED, section 8.)
IC2. The reward badge's size against the node (10 against
19) and its patron colour source are unrecorded; the badge
is a route-choice input (where the payout is), so its
legibility is a decision input. The patron colour table is
NOT IN PACK (section 11). (OBSERVED, section 8.)
IC3. The flagship marker convention is ported deliberately
and identically in meaning: anchored. The dev note is
mechanism: CSS injection in JS against a character baked
into the port's name strings, where it leaks anywhere the
string is reused, including logs. (OBSERVED, section 8.)
IC4. Elite marking exists on JS plates and was not located
in the port's plate builder. Elites are a pre-engagement
difficulty signal; if the port dropped it, it dropped a
combat read, and the player pays in misjudged engagements.
Whether it is absent or merely unlocated is stated as a gap
in the pack. (OBSERVED, section 8.)
IC5. Same pattern as IC4 for the Targeted tag: focus-fire
state is core battle information, present in JS, unlocated
in the port. Its red is a third one-off red. (OBSERVED,
section 8.)
IC6. Crests are anchored to the lore bible and approved;
the risk is structural: two implementations (campaign and
career) plus a three-step fallback chain, all recorded
nowhere but a file header. Duplicated identity art drifts
like every duplicated constant in this pack. (OBSERVED,
section 8.)
IC7. No rule states where faction colour may appear in UI
or how much of a screen it may claim. In battle, faction
identity rides on ship models alone; whether UI should
reinforce it is an open design question masquerading as a
settled one. Motif ownership is fenced (F4); colour usage
is not imagery and is in scope. (OBSERVED, section 8.)
IC8. The port signals enemy and AI state in a lavender
family that exists nowhere in the JS palette, with no stated
rule that purple means enemy; it sits close to the
Glasswrights and Hegemony glows (IC7), so the newest signal
colour in the game risks confusion with faction identity.
(OBSERVED, section 8.)
AC1. The most consequential absence in the pack. IFF (HD10)
is green against lavender, danger bands (MP8) and hull-low
(HD9) speak colour first, and roughly 1 in 12 male players
reads red-green distinctions poorly (pack figure, section
9). The game already proves redundant encoding is possible
(MP4). The cost is paid by exactly the players least able to
report it clearly. (OBSERVED, section 9.)
AC2. No text or UI scale setting exists; the only size
lever is window size through the height law. Reading comfort
is a separate axis from render resolution, and the game
cannot adjust it at all. The 1440p floor and 4K goal say
nothing about it. (OBSERVED, section 9.)
AC3. The toggle exists; only its default (off) is the gate
here, the cap being fenced (F2). Default-off means the
players the toggle exists for meet the unmitigated game
first, in the biggest salvos, before finding the setting;
the fx audit's worst-case salvo test has never run, so the
exposure is unmeasured as well as defaulted. (OBSERVED,
section 9.)
AC4. Shake steps (1.0, 0.5, 0.0) and the Full default have
no capture or playtest behind them. Amplitude itself is a
destruction item (CM7); the choice surface is unjudged.
(OBSERVED, section 9.)
AC5. The sharpest small finding in the pack: the title
screen enforces keyboard focus with a WCAG citation, the JS
build draws a focus outline, and the battle theme, on the
most keyboard-driven screen in the game (about 30 keys,
TY7), sets the focus stylebox to empty. Keyboard players
cannot see where they are on the main screen. (OBSERVED,
section 9.)
AC6. The settings panel is not the whole settings surface:
the map quality toggle lives outside it, unpersisted, with
unstated precedence (MP9). Anyone auditing options from the
panel audits a subset and believes it is the whole.
(OBSERVED, section 9.)
AC7. No reduce-motion control covers UI animation: an
indefinitely repeating map pulse, ambient drones, and
floating text all animate outside every motion setting,
which govern battle choreography only. Ambient peripheral
motion is exactly the category motion-sensitive players
need a switch for. (OBSERVED, section 9.)

## 3. Graphic designer lens

HD1. A scaling law is a type system whether it is treated as
one or not. Height-only scaling with unstated clamps means
the relationship between text and board is an accident of
window geometry, not a designed proportion. Who pays: every
player, at every resolution except the 1080 design point.
HD2. 15 as base with 14 for buttons and rich text is a
plausible hierarchy on paper, but it is a hierarchy nobody
composed: it is the theme default wearing the clothes of a
system. One step either way changes the density of the whole
screen.
HD3. The top bar is the game's masthead in battle. Two
builds, two hierarchies: in one the game's name is the
largest thing, in the other the round state is. Neither was
specified; the port's quieter bar may even be better, but
better by accident is still accident.
HD4. Roster geometry is information design: fixed against
fitted heights give two different answers to how much of the
fleet is present at a glance. Presence is the design value;
a roster you must scroll is a list, not an instrument.
HD5. Panel width is a text measure decision. 316 against 340
is the difference between weapon rows that breathe and rows
that truncate; truncation at the decision panel taxes the
returning player (who knows what is cut) less than the
first-time player (who does not know anything is).
HD6. The log is the battle's narrative record. 13.5 px in
one build, 13 in the other, capped against uncapped: the
record's typography and its memory of the fight differ
between builds, so the story of a battle is typeset two
ways.
HD7. The nameplate is the most-designed object in the game
whether anyone designed it or not: bar, name, rings, on every
ship. 54 against 90 is not a refinement, it is two different
compositions of the same element, and the plate-to-ship
proportion is the battle's core visual ratio.
HD8. Pips against a bar is a genuine design fork: discrete
charges read as state you count, a continuous bar reads as
a quantity you estimate. Both are defensible systems; having
one in each build is not a system at all, it is two games
teaching two shield models.
HD9. A warning threshold is a colour decision: below it, the
roster speaks alarm. 0.35 against 0.34 buys nothing and
proves the colour system has no single author. The design
cost is zero; the evidence value is high.
HD10. The IFF pair (green friend, lavender foe) is one of
the few real colour decisions in the stack, and it is
anchored to the palette. The one-step rounding drift is
invisible and forgivable; what it fingerprints (copying by
eye) is not.
HD11. The round banner is punctuation: 84 px blackletter is
a shout, 46 pt display is an announcement. The game's
rhythm of emphasis differs between builds at every round
boundary, the most repeated ceremonial moment in a battle.
HD12. Floating numbers are a typographic event: bold 19 px
rising and settling. In a salvo they are the densest text on
screen, and their size relative to the ships they annotate
is the read. Unjudged at the owner's resolutions.
HD13. Tooltip width is measure again: 330 reads as a glance,
much narrower reads as a paragraph. 330 against 300 is the
same near-miss signature as HD9, in the element that carries
explanations.
HD14. Developer buttons in the battle bar are a design
statement no designer made: the shipped game's main screen
tells every player it is a debug build. The port's deletion
is also a statement nobody made. The screen's identity
(player product against workshop tool) is undecided.
HD15. Glass with blur against flat fill is two material
languages. The JS glass depends on what is behind it, so its
legibility is scenery-dependent; the Godot flat panel is
duller and more predictable. Predictability over bright
scenery is a readability value the dark captures never test.
MN1. The title is the game's cover. Three sizing laws, one
of them width-driven, means the cover recomposes itself with
the window in the frozen build and shrink-fits in the port.
A cover should be the most controlled composition in the
game; it is currently the least.
MN2. Settings placement is information architecture. A
battle bar of toggles and a title panel of fifteen controls
are two different theories of where decisions live; the
player learns one and the port teaches the other.
MN3. Defaults are the design most players experience;
designing the option space and never the default set is
designing for the minority who change settings. The
fullscreen contradiction is a small broken promise on the
first screen.
MN4. Tier names are labels in the design system: Ultra,
High, Medium against Max, High, Low against a two-state map
control. Three vocabularies for one decision reads as three
products. The phone reference in a PC-only game is a label
from a product that no longer exists.
MN5. 0.45 is a number that looks tuned and is not. False
precision is a design tell: it claims a measurement the
record does not hold.
MN6. Cut-in labels (Key moments, Every attack, Off) are
honest labels for a real choice; the default is the design
decision, and it sets the game's interruption rhythm.
Paired with the never-take-camera ruling, Key moments is
either coherent or the exception that eats the rule, and no
document says which.
MN7. The end card is the battle's last impression and shares
the face and scale schism: 64 px blackletter against 34
display. A game should not change accent between its first
screen and its last.
MN8. The debrief has no design at all, and it shows: the
screen that carries the run-learning message is a gilt
paragraph inside other screens. No hierarchy, no stats
structure, no what-changed presentation. This is the pack's
clearest case of an important surface with zero design
system behind it.
MN9. A single centred line on the void is at least a
composition; the port's load screen is unjudged either way.
Loading is dead time the design has not claimed.
MN10. Two campaign presentations means two design languages
for the same home screen, each with its own sizes. Whichever
the player gets, the other is a maintenance tax and a drift
source.
MN11. Credits as the only font document is an accident that
happens to be useful: the licence lines are the typography
record because nothing else wrote it down.
MN12. A bold line over a small line is a real pattern,
consistent across builds, and the two-line choice is one of
the few patterns that survived the port intact. The disabled
state breaks the pattern's contract: opacity-only dimming
at small sizes is a known readability trap, and it sits on
the campaign's story decisions.
MP1. The SVG map's frame (100 percent width, capped) is a
diagram's frame: modest, bounded, legible as a chart. As a
composition it is the baseline the 3D scene must beat, not
merely replace.
MP2. Node sizing is a weak hierarchy: boss only 37 percent
larger than a normal node undersells the map's climax. The
pulse is the map's one motion accent, well-chosen for
available; size should have carried the boss.
MP3. The Nemesis red is the map's most important colour and
it is an orphan: not the palette's blood, not its warning
red. One-off colours at high-stakes positions are how a
palette stops meaning anything. The muted label blue above
nodes has the same orphan status at lower stakes.
MP4. Travelled, reachable, locked in colour, width, and
dash: this is the best-designed encoding in either build,
and it is in the frozen one. It proves the project's own
standard for state encoding, which the port should be held
to.
MP5. Seven columns is composition at the largest scale: the
map's rhythm of approach, mid-run services, late services.
Its presentation consequences (how a sector reads at once)
have never been judged as a composition.
MP6. The orrery is a scene, not a diagram: orbit radii, a
fixed camera, lit props. It may be more beautiful and less
legible at once. Six constants are not a visual language;
the SVG's encodings were. The design question is whether the
scene re-expresses the language or abandons it.
MP7. Flight time is the map's tempo. 2.4 s between stops is
the difference between a journey and a teleport; as a design
value it is pure feel and has never been felt at two values.
MP8. Four danger colours are a designed scale and the best
colour system on the map; their cut points are where the
design meets the truth. A colour scale whose boundaries
mislabel is worse than no scale, because it is believed.
MP9. Two quality controls for one scene is an architecture
smell the player experiences as inconsistency: the same map
can be dressed two ways depending on which door they used.
Design systems need one door.
MP10. Icon chips to text-only is a downgrade in kind, not
degree: recognition replaced by reading. Legends exist to
make the map glanceable; a text legend makes the player
study the key instead of the map.
MP11. The preview's gilt and blood code is a real semantic
system (reward in gilt, threat in blood) that exists only
in practice. Unwritten semantics drift; the one-off reward
grey is the drift already happening.
MP12. Muted station props are a deliberate aesthetic
(restraint, no purple cast) executed as comments and lerp
factors. Restraint is a legitimate design position; an
unrecorded amount of it is not a position, it is a residue.
TY1. Blackletter against Michroma is two brands: gothic
romance against technical modern. The lore round chose the
port's; the playable game still wears the other. A brand
change this large should land as an event (cutover), not
leak as a discrepancy.
TY2. Barlow Semi Condensed on both sides is the stack's one
typographic continuity, and it is a good one: condensed,
technical, readable at small sizes. It is the proof the two
builds can agree when a choice is actually made.
TY3. Four base sizes is not a scale, it is four local
decisions. A type scale is the cheapest design system there
is, and its absence is why every size in this pack must be
judged screen by screen instead of once.
TY4. Two ceilings (2.2, 2.5) is a system disagreeing with
itself in a constant. At the owner's resolutions it happens
not to bite; design systems are judged by whether they can
bite, not whether they currently do.
TY5. Height-only scaling produces type sized by an axis the
reader does not experience. Readers experience text against
the board and the window's width; a system blind to width
will crowd or strand text in arrangements nobody composed.
TY6. A design system without a floor has no floor. 10 px
gameplay text is not a style choice, it is the absence of
one; the player with low vision pays for every implementer's
stopping point.
TY7. Thirty inputs in one paragraph is the help screen
declining to be designed. Chunking and grouping are the
entire craft here, and none was applied in either build.
TY8. Teaching cards are editorial design: one idea per card,
written to be finished. Several dense sentences per card is
a manual wearing a card's shape. The shared off switch is
an editorial coupling: two publications, one unsubscribe.
TY9. A shrink floor of 12 stops the MN1 title law mid-fall:
below it, the composition gives up and overflows. Floors are
system values and belong in the shared law, not in a helper.
TY10. Line height is half of readability and the port's half
is an engine default. 1.4 against unstated is the quietest
disagreement in the pack and the kind that makes two builds
feel different without anyone naming why.
IC1. Glyphs inside nodes against 3D props per stop type:
the glyph system is a language (small, repeatable,
legend-able), the prop system is a diorama. Languages
survive translation; dioramas must be re-learned. The port
chose the diorama without recording the trade.
IC2. A patron sigil badge (colour circle, glyph letter,
star for rare) is a compact, well-formed mark: three
channels in 10 px of radius. Its proportions against the
node were never composed, but the mark itself is a system.
IC3. A gilt star before the flagship's name is a clean,
minimal mark, identical in meaning in both builds. The
port's string-baked star is a craft error in implementation,
not in design: the mark is right, its carrier is wrong.
IC4. Elite marking in gilt suffix is a quiet, consistent
signal in the JS build. Its absence (or unlocated status) in
the port removes a word from the plate's vocabulary; plates
are a language and this is a missing word.
IC5. The Targeted tag is well-formed as a mark (uppercase,
letter-spaced, on a dark red ground) and its red is still an
orphan. A tag that means focus fire deserves a palette home
and a guaranteed seat in the port.
IC6. The crest set is the strongest identity work in the
pack: six distinct, lore-true marks in faction colours,
specified in the file header like a brand sheet. Two
implementations of a logo set is a brand risk, full stop.
IC7. Faction colour is the game's identity palette, and the
battle HUD declines to use it: identity rides on ship models
while the interface speaks only friend and foe. Whether that
restraint is the design or the default is the open question;
the map (crests, looks) already voted yes, the HUD voted
nothing.
IC8. The lavender AI family is a new colour language
introduced by the port without a palette entry, a stated
meaning, or distance from the faction glows it neighbours.
New signal colours are brand decisions; this one arrived as
constants.
AC1. Colour-only IFF is the stack's largest design debt.
The fix is a design pattern the game already owns (MP4:
encode state three ways). Who pays: the colour-vision
deficient player, on every targeting decision, in silence.
AC2. No scale setting means the design's sizes are
take-it-or-leave-it at every vision level. A scale control
is the standard courtesy of PC interfaces; its absence reads
as the design never having considered readers as a variable.
AC3. A safety control defaulting to off is a design stance:
the unmitigated presentation is the intended first
experience. For the players it protects, that ordering is
the whole issue.
AC4. Three shake steps is a reasonable ladder; Full as the
default makes maximum motion the designed experience.
Reduced at 0.5 is a guess wearing a fraction.
AC5. Invisible focus is a broken affordance on the game's
main screen, in a project that elsewhere cites WCAG by
number. The design system contains both the rule and its
violation, separated by screen.
AC6. A settings surface with a hidden annex (the map toggle)
is architecture the player cannot form a model of. Options
that cannot be found cannot be designed for.
AC7. Ambient motion with no off switch is the map's
atmosphere imposed on every nervous system equally. Motion
is a design material; consent over it is part of the design.

## 4. Agent lead lens

HD1. One formula in one function is the most enforceable
shape a gate can have, and the screenshot job already
verifies the implementation after resize (ui_shots.gd, per
the pack). What no run verifies is the values: the capture
round that judges them rides the already-commissioned
calibration sitting, so the measurement is free. Model
enforcement, unmeasured values.
HD2. Three constants in the theme construction; trivially
buildable, judged in the same capture round as HD1. No
separate run should ever be spent here.
HD3. Enforceability is a side-by-side capture, which the HD1
round already produces. The waste risk is adjudicating the
two bars separately from the spec that must unify them.
HD4. One full-fleet capture settles it; the cost is inside
the HD1 round. Left alone, roster geometry will be
re-litigated per screen that embeds a roster.
HD5. A constant diff catches this class mechanically: 340
against 316 is exactly what a scripted comparison of the two
builds' UI constants reports without an owner round. Human
adjudication per near-miss is the waste this pack exists to
stop.
HD6. The only item needing its own run: a long-battle soak
plus line count, one Codex run, also answers whether the
port's array is capped without reading 4,707 lines by hand.
Recurring cost if unfixed: every long battle in the port
pays growing layout cost, and every log review compares two
different records.
HD7. The diff flags it (54 against 90 is not a rounding
error), the calibration sitting judges it at both of the
owner's zooms. Two settlements, both already scheduled
infrastructure. No new machinery.
HD8. Not machine-checkable: pips against bar is a semantics
choice. It costs one owner question inside the HD7 round
and one spec line. Cheap, but only if asked while the owner
is looking at plates anyway.
HD9. The diff's type specimen: two near-identical constants,
no decision. Settlement cost is one line in the consolidated
specification. If the programme takes nothing else from this
audit, the diff plus spec pattern is the takeaway.
HD10. Keep as evidence, spend nothing. Its rounding drift is
the calibration data for how far eye-transcription drifts on
values that were available exactly; it calibrates suspicion
of every other ported constant.
HD11. Capture-round item; the banner will be in the HD3
frame anyway. Zero marginal cost if the round is run as one
round, real cost if each schism item gets its own.
HD12. Rides the fx E6 settlement round (issue 210), which
already captures salvos with flash logging. Any separate UI
salvo run would be a duplicate spend.
HD13. Diff-flagged, capture-judged, spec-recorded: the
standard pipeline, no special cost.
HD14. Settlement is a ruling, not a build: one owner
question, then one Opus run to apply it per build. The
deadline is real: once the port's UI is treated as final,
separating the surfaces becomes a redesign instead of a
decision. Highest leverage-per-cost item in the pack.
HD15. One extra frame in the HD1 round (panels over the
brightest nebula patch). The failure it tests cannot be
found any other way, because every existing capture habit in
the project shoots dark scenes.
MN1. Three laws, three files. The title captures ride the
HD1 round's resolutions; the unification is spec work. The
recurring waste if left: every future title-adjacent screen
invents a fourth law.
MN2. Architecture decisions are the most expensive kind to
reverse after they are baked into a main loop. Settlement is
a ruling applied inside the specification run; the cost of
deferral is the port hardening around title-only settings.
MN3. One owner review round after the issue 207 benchmark,
re-ruling the defaults as one block, exactly as the pack
prices it. Sequencing matters: ruling defaults before 207
reports would price the quality default blind.
MN4. One naming pass inside the specification run. Cheap,
and it pays out in every future benchmark conversation;
three vocabularies is a recurring tax on communication, not
a one-time confusion.
MN5. Judged in the owner's calibration play at no extra run.
A standalone speed capture round would be waste.
MN6. One spec line recording the interaction with the
never-take-camera ruling, after the issue 212 S-A captures
exist. Sequenced, not standalone.
MN7. Same frame as HD3 and HD11 in the capture round. The
schism items must be settled as a set (face plus scale
system) or the spec will re-litigate them per screen.
MN8. The largest single build in the settlement programme:
one Opus run drafting a debrief specification against the
existing text, plus one owner review round on a mock
capture. It is also the only settlement that creates a
surface rather than correcting a constant, so it should be
scoped as a specification, not a screen build, to keep the
run bounded.
MN9. Folds into the MN8 run at no extra cost, as the pack
prices it. Any standalone loading work is waste.
MN10. One Opus read of the host file answers which
presentation ships and when. Until that read exists, every
campaign UI settlement in this pack is priced against a
surface that may be a scaffold. Read first, then rule.
MN11. No run. Recorded so the typography pass inherits the
font facts from the one screen that states them.
MN12. Judged on event screens inside the campaign capture
round (MP6 settlements). No standalone cost; the waste risk
is forgetting to include an event screen in that round's
shot list.
MP1. No spend: superseded by MP6, kept as baseline record.
Spending a run on the SVG frame would be auditing the past.
MP2. Baseline values for the MP6 comparison; they cost
nothing because the comparison needs a baseline anyway.
MP3. Palette consolidation inside the specification run:
each one-off colour is adopted on the record or replaced by
a palette value. One pass, recurring benefit: the palette
becomes a checkable artifact instead of a habit.
MP4. No spend; name it in the specification as the encoding
standard the port is held to. Its settlement value is as a
precedent, not a change.
MP5. No spend in this audit; recorded so the MP6 captures
are judged with the pacing skeleton in view. Re-deriving a
campaign design constant from a UI audit would be scope
creep with a run attached.
MP6. The campaign's settlement centrepiece: one Codex run
for side-by-side captures of the same sector in both forms,
one owner review round. Several other items (MP7, MP10,
MP12, IC1, MN12) ride this round; priced once here, they
must not be priced again elsewhere.
MP7. Two flight times inside the MP6 captures; the marginal
cost is one extra capture in a run already happening.
MP8. The pack's best-priced settlement: a one-time script
build running the Monte Carlo of band labels against
measured bot outcomes on the existing campaign sim harness.
Data first, no owner round for the data; labels re-ruled on
the result. This is the model settlement for assumed
thresholds: measure, then set.
MP9. One Opus read states the precedence; the fix folds into
the MN4 naming pass and the specification. Until then the
map's cost is invisible to the 207 benchmark family, which
is a measurement hole in a programme that runs on
measurement.
MP10. Judged in the MP6 round at no extra run; restoration
of chips, if the owner rules it, is spec work.
MP11. Palette and semantics consolidation inside the
specification run; same pass as MP3, so the campaign's
colour code is written once, in one place.
MP12. One unmuted variant frame in the MP6 run. The lerp
factors then either earn their values on the capture or get
replaced by a stated rule in the spec.
TY1. Settlement is a recorded confirmation (cutover is the
change point), one line in the specification. The risk is
not cost but silence: an unrecorded brand change will be
rediscovered as a bug report after cutover.
TY2. No spend. The clean item; cite it in the spec as the
shared body face so the agreement becomes a rule instead of
a coincidence.
TY3. One base-size rule in the specification, judged on
captures already priced (HD1 and MP6 rounds). Recurring
waste if left: every new screen picks a fifth base size.
TY4. One Opus run consolidates three copies of the law into
one shared function; clamp values re-ruled in the HD1 round.
This is the structural fix the whole TY domain hangs on:
after it, HD1's law exists once and every screen inherits
judged values instead of local ones.
TY5. One small-window frame added to the HD1 round's shot
list. Marginal cost near zero; without it the round judges
only the resolutions that flatter the law.
TY6. A minimum-size rule in the specification, with the HD1
captures as evidence. The rule must be stated as a floor
the pipeline can check (a script can scan stylesheets and
theme constants for sub-floor sizes), which converts a
judgement into an enforceable gate at script cost.
TY7. One Opus run restructures the help text (grouped,
chunked) after the owner's read in the capture round. Text
work is cheap; the waste would be restructuring before the
owner reads the current block on a capture.
TY8. No standalone run: judged through the playtest
checklist route (issue 202's successor captures), as the
pack prices it. Splitting the shared off switch is a spec
line in the same pass.
TY9. Folds into the TY4 consolidation run; the floor becomes
a stated property of the shared law. No separate spend.
TY10. One spec line after the HD1 captures. The Godot
default should be measured (rendered samples at the theme's
sizes) rather than assumed, inside the same round.
IC1. Judged in the MP6 round with a recognition pass (the
owner names each stop type from the capture), which converts
an art question into a measurement at no extra run.
IC2. The MP6 round judges the badge; the patron colour table
read folds into the specification run. Small, bounded.
IC3. One spec line moves the marker from string content to
presentation in the port's convention. Trivial cost,
prevents a recurring leak into logs and saves.
IC4. Verified in the HD7 capture round (elite plates shot in
both builds). If absent in the port, restoration is spec
work; if present but unlocated, the round closes the gap
with evidence instead of a search.
IC5. Same round, same pattern as IC4. The two items share
one shot list entry: plates showing elite and targeted
states, both builds.
IC6. One Opus run only if the two copies differ; the run
starts with a diff of the two crest implementations, which
is script-cheap, and stops there if they match. Correctly
priced in the pack; do not commission the consolidation
blind.
IC7. One owner question plus the MP6 captures. This is a
direction decision, and direction decisions are the ones
that cannot be settled by a run; the captures inform, the
owner rules.
IC8. Palette consolidation in the specification run, same
pass as MP3 and MP11. The family's meaning (purple signals
enemy and AI state) is either written into the palette as a
rule or the colours are replaced; either outcome is one
pass.
AC1. One-time script build: a CVD simulation pass over the
existing UI captures (the HD1 and MP6 rounds produce them),
then an owner ruling on any redundant encodings shown
failing. Sequencing is the whole craft here: the simulation
must run on captures that exist anyway, or it becomes a
standalone programme. Most consequential test in the pack,
priced at one script build.
AC2. One owner ruling on scope; if in scope, one Opus run
implements a scale setting against the consolidated TY4
function. Quoting the implementation before the TY4
consolidation would price it against three laws instead of
one.
AC3. Folds into the MN3 defaults ruling after issue 207.
No separate run; the exposure question (default off) is a
one-line ruling inside a block already being re-ruled.
AC4. Judged in the owner's calibration play (issue 212),
where shake is on the table anyway. No standalone cost.
AC5. One stylebox inside the specification run: the
cheapest fix in the pack, and the one with a standards
citation already in the project's own code (the title
screen's WCAG comment) to copy from.
AC6. Settled by the MP9 Opus read; the settings surface
becomes whole as a side effect. No separate spend.
AC7. Folds into the AC2 ruling as its second half, per the
pack's own pricing. If ruled in, wiring existing ambient
motion to a switch is spec-run work; if ruled out, the
absence becomes a decision on the record, which is the
other acceptable outcome.

## 5. Disposition table

Shared settlements named once, referenced by letter:
(A) The calibration-sitting capture round (issue 212, S-E):
HUD and title captures at 1440p, 4K, and one small windowed
size, plus panels over the brightest nebula patch and a
full-fleet roster. Already commissioned infrastructure; one
owner review round, no new run.
(B) The consolidated UI specification: one Opus run holding
the scripted two-build constant diff, the palette
consolidation, the single scale function, the base-size and
minimum-size rules, tier naming, and every one-line recording
named below.
(C) The campaign capture round: one Codex run producing
side-by-side SVG and 3D captures of the same sector, two
flight times, one unmuted variant, event screens, and a
stop-type recognition pass; one owner review round.
(D) The fx E6 settlement round (issue 210), already
commissioned, which captures salvos with flash logging.

HD1 REPLACE. The unjudged law's values are replaced by
values judged on captures: the design point and both clamp
bounds are re-ruled from settlement (A). Cost: rides (A),
one owner review round; no new run. The mechanism (one
function) is kept; only its numbers were never earned.
HD2 RE-DERIVE. Base sizes judged in settlement (A) at the
owner's resolutions and re-set there. Cost: inside (A).
HD3 REPLACE. Two top bars replaced by one specified bar
(contents and hierarchy chosen on the record) in (B),
informed by the side-by-side frame in (A). Cost: inside (A)
and (B).
HD4 RE-DERIVE. Roster geometry re-set from the full-fleet
(20 ship) roster capture in (A), both builds compared.
Cost: inside (A).
HD5 REPLACE. The pair (340 shipped, s(316) port) is replaced
by one width adopted on the record via the constant diff in
(B); the diff, not adjudication, forces the choice. Cost:
inside (B).
HD6 RE-DERIVE. The port's log behaviour is established by a
long-battle soak plus line count, and a cap decision is made
from that evidence. Cost: one Codex run (one-time); no owner
round for the data.
HD7 REPLACE. Plate size is replaced by a value judged at the
owner's two working zooms (standard radius and effects
zoom) in (A), recorded once for both builds. Cost: inside
(A).
HD8 REPLACE. Two shield encodings replaced by one: the owner
picks the encoding he reads faster on the (A) plate
captures; the loser is removed from the surviving build's
spec in (B). Cost: inside (A) and (B).
HD9 REPLACE. The 0.35 / 0.34 pair is replaced by a single
recorded threshold in (B), picked by the owner in the (A)
round. No measurement could earn this value; the owner's eye
is the settlement, per the ground rule. Cost: inside (B).
HD10 KEEP. Anchored to the CSS variables, drift sub-visible.
Kept as the calibration evidence for the diff in (B). No
cost.
HD11 REPLACE. Banner size and face are unified with the
title and end-card system in (B), judged on the (A) frames.
Cost: inside (A) and (B).
HD12 RE-DERIVE. The 19 px size is judged on the salvo
captures in (D) at the owner's resolutions and re-set there.
Cost: inside (D), no new run.
HD13 RE-DERIVE. Tooltip width judged in (A) and recorded
once in (B). Cost: inside (A) and (B).
HD14 REPLACE. The mixed player and developer surface is
replaced by a separated one, per the owner ruling in
question 1 below, applied per build. Cost: one Opus run
(one-time) after the ruling.
HD15 RE-DERIVE. Panel material judged on the bright-nebula
frame in (A); if the glass panel fails to read there, (B)
records the flat treatment as the standard. Cost: inside
(A).
MN1 REPLACE. Three title sizing laws replaced by one law in
(B), judged on 1440p and 4K title captures in (A). Cost:
inside (A) and (B).
MN2 REPLACE. The two settings architectures replaced by one
placement decision, ruled with question 1 below and applied
in (B). Cost: inside (B) after the ruling.
MN3 RE-DERIVE. The default set is re-ruled as one block
after the issue 207 benchmark reports. Cost: one owner
review round (one-time); sequencing after 207 is part of the
settlement.
MN4 REPLACE. Three tier vocabularies replaced by one naming
set in (B), tied to the 207 benchmark's reported results.
Cost: inside (B).
MN5 RE-DERIVE. The Fast value judged in the owner's
calibration play (A) and re-set or confirmed there. Cost:
inside (A).
MN6 RE-DERIVE. The cut-in default is re-judged after the
issue 212 S-A captures show death presentation, and its
interaction with the never-take-camera ruling is recorded in
(B). Cost: inside (B), sequenced after S-A.
MN7 REPLACE. End card face and scale unified with the HD11
and MN1 system in (B), judged in (A). Cost: inside (A) and
(B).
MN8 REPLACE. The absence is replaced by a named addition: a
debrief specification (what a debrief must show, in what
order, against the existing debrief text), drafted before
any screen is built. Cost: one Opus run (one-time) plus one
owner review round on a mock capture.
MN9 RE-DERIVE. Loading requirements are stated inside the
MN8 specification run. Cost: inside the MN8 run, no extra.
MN10 RE-DERIVE. The fallback's status is established by one
Opus read of the host code; if it is a development scaffold,
it leaves the maintained surface (that outcome is a DROP of
the second presentation, decided by the read plus the
owner's confirmation); if it ships, it folds into the TY4
consolidation in (B). Cost: one Opus run (the read).
MN11 KEEP. No gate binds; the credits screen's font record
is inherited by (B) as documentation. No cost.
MN12 RE-DERIVE. The disabled-state rule is judged on event
screens in (C); if the opacity-only dim fails there, (B)
records a non-opacity encoding (colour or label change) as
the standard. Cost: inside (C) and (B).
MP1 DROP. The SVG frame constants retire with the form they
size. What replaces the protection: the MP6 judged
presentation in (C) governs the campaign's home screen, and
the JS figures remain in the record as the baseline the port
was compared against. No live surface loses a protection,
because the port already replaced the form.
MP2 RE-DERIVE. Node geometry is judged as the baseline in
the (C) comparison and its encoding duties (boss emphasis,
available pulse) are re-specified for the 3D form in (B) if
the captures show them lost. Cost: inside (C) and (B).
MP3 REPLACE. The orphan colours (#ff6b5a, #7f8fa6) are
adopted into the palette on the record or replaced by
palette values, in the (B) palette consolidation. Cost:
inside (B).
MP4 KEEP. The three-way route encoding stands as the
project's own standard; (B) names it as the encoding
precedent the port is held to. No cost.
MP5 KEEP. A campaign design constant, outside this audit's
gift to re-derive (the pack's own fence, accepted here). Its
presentation consequences are judged under MP1 and MP6.
No cost.
MP6 REPLACE. The six-constant scene is replaced by a judged
presentation: (C) captures the same sector in both forms,
and (B) records the 3D map's encoding system (what carries
boss, available, reachable, danger) as a specification, not
a scene. Cost: (C), one Codex run plus one owner review
round.
MP7 RE-DERIVE. Flight time judged in (C) at two values and
re-set from the owner's read. Cost: inside (C).
MP8 RE-DERIVE. Band thresholds are re-set from measured
outcomes: a Monte Carlo of band labels against bot results
on the existing campaign sim harness. This is the one fresh
set of fixed values in this table, and the measurement that
earns it is the Monte Carlo itself. Cost: one-time script
build; no owner round for the data; labels re-ruled on the
result inside (B).
MP9 REPLACE. Two quality controls replaced by one path: an
Opus read states the precedence, then the map toggle is
brought inside the settings system or removed, recorded in
(B). Cost: one Opus run (the read) plus inside (B).
MP10 REPLACE. The text-only legend is replaced by the icon
chip legend if the (C) captures show recognition suffering;
the default expectation, from IC1's pattern, is that chips
return in (B). Cost: inside (C) and (B).
MP11 REPLACE. The preview's colour semantics (gilt, blood,
patron, the orphan grey) are written as a stated code in the
(B) palette consolidation; the grey is adopted on the record
or replaced. Cost: inside (B).
MP12 RE-DERIVE. The muting factors are judged on the (C)
captures including one unmuted variant; the surviving
amount, if any, is recorded as a stated rule in (B). Cost:
inside (C) and (B).
TY1 KEEP. The lore-anchored face decision stands; (B)
records the cutover as the change point so the schism is a
scheduled event, not a discrepancy. No cost beyond the (B)
line.
TY2 KEEP. The shared body face stands and is cited in (B) as
a rule, converting agreement into system. No cost.
TY3 REPLACE. Four base sizes replaced by one base-size rule
in (B), judged on the (A) and (C) captures. Cost: inside (B).
TY4 REPLACE. Three copies of the scaling law replaced by one
shared scale function; clamp values re-ruled in (A). Cost:
one Opus run (one-time, inside (B)'s scope) plus inside (A).
TY5 RE-DERIVE. The height-only law is judged on the (A)
captures including the small windowed size; if type crowds
or strands there, the law's replacement is specified in (B).
Cost: inside (A).
TY6 REPLACE. The absent floor is replaced by a named
addition: a minimum text size rule in (B), set from the (A)
capture evidence and checkable by script against stylesheets
and theme constants. Cost: inside (B); the check rides the
(B) diff script.
TY7 REPLACE. The single-paragraph control scheme is replaced
by a grouped, chunked help layout. Cost: one Opus run
(one-time), after the owner's read in (A).
TY8 RE-DERIVE. Card density and the shared off switch are
judged through the playtest checklist route (issue 202's
successor captures), owner-judged; splitting the off switch
is recorded in (B). Cost: no standalone run; inside (B) for
the switch line.
TY9 RE-DERIVE. The shrink floor is restated as a property of
the shared scale function in the TY4 consolidation, with its
MN1 interaction resolved there. Cost: inside (B).
TY10 RE-DERIVE. The port's line spacing is measured from
rendered samples in (A) and a line-height rule is recorded
in (B) for both builds. Cost: inside (A) and (B).
IC1 REPLACE. Two icon systems replaced by one specified
language for the port: the (C) recognition pass (owner names
each stop type from the capture) decides whether glyphs are
carried into the 3D props or the props are re-specified
until recognition matches the SVG baseline. Cost: inside
(C) and (B).
IC2 RE-DERIVE. Badge proportions judged in (C); the patron
colour table read folds into (B). Cost: inside (C) and (B).
IC3 KEEP. The flagship marker convention stands, identical
in meaning in both builds. (B) records the port's
string-content mechanism as an implementation note for the
next plate change. No cost.
IC4 REPLACE. The unlocated elite marking is replaced by a
verified one: the (A) plate round shoots elite plates in
both builds; if the port lacks the mark, it is restored as a
named addition in (B). Cost: inside (A) and (B).
IC5 REPLACE. Same settlement as IC4 for the Targeted tag:
verified in (A), restored in (B) if absent, and its red is
given a palette home in the (B) consolidation. Cost: inside
(A) and (B).
IC6 RE-DERIVE. The two crest implementations are diffed
first; consolidation into one implementation follows only if
they differ. Cost: one Opus run (one-time), scoped to stop
at the diff if the copies match.
IC7 REPLACE. The unrecorded default (faction colour absent
from battle UI by silence) is replaced by an explicit owner
ruling, question 3 below, informed by the (C) captures.
Cost: the ruling only; any application folds into (B).
IC8 REPLACE. The lavender family is adopted into the palette
on the record with a stated meaning (purple signals enemy
and AI state), with its distance from faction glows checked
on the (A) captures, or replaced by palette colours; decided
in the (B) consolidation. Cost: inside (B) and (A).
AC1 REPLACE. The absence is replaced by a named addition in
two steps: first a CVD simulation pass over the (A) and (C)
captures, then the redundant encodings the simulation shows
failing, specified in (B) on the MP4 precedent. Cost:
one-time script build (the simulation); encodings inside
(B); the owner rules on failures in the (A) and (C) review
rounds.
AC2 REPLACE. The absence is replaced by a named addition,
gated on the owner ruling in question 2 below: a UI scale
setting implemented against the consolidated TY4 function.
Cost: one Opus run (one-time) if ruled in; if ruled out,
this row converts to KEEP and the absence becomes a decision
on the record.
AC3 RE-DERIVE. The default is re-ruled inside the MN3
defaults block after issue 207. The cap itself is fenced
(F2) and untouched. Cost: inside the MN3 round.
AC4 RE-DERIVE. Steps and default judged in the owner's
calibration play (A), where shake is judged anyway (issue
212). Cost: inside (A).
AC5 REPLACE. The empty focus stylebox is replaced by a
visible focus style in the battle theme, copying the title
screen's own stated practice. Cost: inside (B). The cheapest
fix in this table.
AC6 REPLACE. The hidden settings annex is replaced by a
whole settings surface: the map toggle joins the settings
system or is removed, under the MP9 settlement. Cost: inside
the MP9 read and (B).
AC7 REPLACE. The absence is replaced by a reduce-motion
entry covering UI animation (map pulse, ambient drones,
floating text), gated on the same ruling as AC2 (question 2
below). Cost: inside (B) if ruled in; if ruled out, converts
to KEEP as a recorded decision.

Counts: KEEP 7 (HD10, MN11, MP4, MP5, TY1, TY2, IC3);
REPLACE 32; RE-DERIVE 24; DROP 1 (MP1). Total 64.

## 6. Owner questions

Q1. Does the shipped game show its developer surface?
(HD14, MN2) The playable build's battle bar carries Report a
problem, Copy report, and Diagnostics buttons, and its
battle settings carry a test-hull toggle; the port deleted
them without a decision. Pick: no. The player surface ships
clean, developer tools live behind a dev flag, and the
comfort settings (shake, flash, speed) stay reachable
mid-battle in the port's single architecture. Stakes: this
decision is free now and becomes a redesign after the port's
UI is treated as final; it also decides what every player's
battle bar looks like.

Q2. Is a player-facing UI scale setting in scope for the
port, with a reduce-motion entry decided in the same ruling?
(AC2, AC7) Pick: yes to UI scale, implemented on the
consolidated scale function (one Opus run); reduce-motion
decided alongside it rather than in a later audit. Stakes:
without a scale setting, reading comfort is set entirely by
window size, and the 1440p and 4K targets, which are render
targets, say nothing about whether the text is comfortable
to read.

Q3. Should faction colour enter the battle UI, or stay on
the ships alone? (IC7) Pick: map yes, battle plates no. The
campaign map already carries faction colour (crests, system
looks) and should keep it under a stated rule; in battle, the
friend and foe channel is never diluted, and enemy faction
is carried by crest and name, not by recolouring IFF.
Stakes: faction identity in battle currently rides on ship
models alone, while the map mutes station colours by an
unrecorded amount (MP12); ruling this once settles both
directions and stops colour identity being set by lerp
factors and silence.

## 7. Not checked

- No captures were run for this leg; every settlement above
  is priced, none is executed. This report judges from the
  pack's code record only.
- Whether the Godot port caps its underlying battle log
  array (HD6) and where its floating combat text lives
  (HD12): the pack states battle.gd was searched, not read;
  both are recorded as unlocated, not absent.
- Which campaign presentation ships and when the fallback UI
  appears (MN10): the host file was not read for the pack.
- The per-faction LOOKS table values for the 3D map (IC7):
  cited by the pack from other files, not read.
- The patron colour table behind the reward badge (IC2): not
  read for the pack.
- The JS nameplate name's full showing rules (HD7): the pack
  read the base opacity and transition, not every state class
  that raises it.
- A full diff of the duplicated stylesheet (head.html against
  the inline copy in voidsworn-3d.html): the pack spot-checked
  and matched; a divergence beyond the spots checked would
  itself be a finding this leg cannot see.
- UI constants set in Godot scene files rather than scripts:
  outside the pack's evidence.
- FINDINGS.md was not re-read for the pack; if a ruling
  already settles an inventoried item, this leg cannot see
  it and the chair catches it at screening.
- The other writer legs and the ideation leg: not seen, by
  design. Where this report's settlements resemble the chair
  hypotheses in pack section 10, the resemblance was reached
  from the inventory; the hypotheses were treated as claims
  to test, and two of them (the constant diff, the
  specification) are adopted here as settlements because the
  item-level evidence supports them, not because the chair
  proposed them.
