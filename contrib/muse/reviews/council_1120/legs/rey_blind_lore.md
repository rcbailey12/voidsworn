# Blind Rey leg: sci-fi lore seat, council audit 1120

Evidence: godot/story/ at round 8 (outlines.md rewritten Oct 31 to
lore round 8, R59), the story data files, the incorporation record
(review_incorporation.md, R45), and the in-game text visible in the
pack (playtest build 25adec31: title, flagship pick, sector maps,
battle voice lines in the traces, victory, promotions and defeat
screens). The earlier X21 flags are checked against the current text,
not the originals.

## Status of the X21 flags

- Sadist rival with no memory of the player: FIXED on paper. The
  rival data now carries a memory pool ("7 ways you beat him"),
  scar lines and beat 3 hails keyed to how earlier beats went
  (godot/story/data/rival_lines.json, outlines.md Table B). In the
  pack's two runs the nemesis appears only as a dossier and a hunt
  clock; no run reaches a rematch, so the memory system is still
  unproven in play evidence. The fix exists; the pack cannot show
  it landing.
- Dead flag branches: FIXED. The incorporation record verifies every
  Beat 1 flag now has its own Beat 2 bracket and Beat 3 echo.
- Too many weakness reveals: addressed in the round 8 rewrite
  structure (one reveal economy per arc in the outlines); not
  visible in the pack either way.
- Factions that blur: FIXED in the outlines (see finding 3 for the
  in-play residue).
- 40k echoes: see finding 2; reduced, not gone.

## Findings, worst first

1. The fiction the player actually meets in the first hour is a
   fraction of the fiction that exists. The pack's two runs surface:
   one admiral voice line per battle ("Hold the line. Let them come
   to the broadsides", trace seed-10), a contact line, a nemesis
   dossier card, hunt clock, and the end cards. The six arcs, the
   rival's calling cards and the Chronicle callbacks (outlines.md)
   are all downstream of systems a Battle 1 to 2 player never sees.
   That is normal for a roguelite, but the gap matters because the
   game's title-screen promise ("Every hull you lose stays lost,
   and so does its captain") is a fiction promise, and the first
   hour pays it only through the lifepod line on the victory screen.
   Fix: pull one arc beat forward. A single Beat 1 card before the
   second battle (the outlines already have them at sector I) would
   put the player's faction want on screen inside the first hour.

2. 40k echoes persist in the Sunward surface vocabulary. The
   flagship pick screen offers "Aspect of the Ram / Spear /
   Admiral", the fleet is a "crusade" to a Hollow Sun, the nemesis
   is a "High Nadir", captains are promoted to Commander, and the
   flagship is a cathedral-spired Vigil-class. Individually each is
   defensible; together, in the first three screens a new player
   sees, the Sunward read as the Imperium with the serial numbers
   filed off. The outlines' Sunward want (an oath, a siphon, a dawn
   horn) is more original than the vocabulary that introduces it.
   Fix: rename one of the three first-hour terms (the aspect names
   are the cheapest) into the game's own register, the way "Cold
   Reckoning" and "Everwatch" already are.

3. Faction wants are distinct in the outlines and invisible in
   play. outlines.md gives each faction a different object at the
   Hollow Sun (oath and siphon, Registry Order 41, Rook's trail,
   eating the sun, the last lens, a homecoming). In the pack, the
   Hegemony want nothing visible beyond "5 ships on the scanners"
   and the Hullbreakers are a stat block and a voice in the log.
   The enemy's want is the cheapest drama there is: one line in the
   Engagement panel ("They are here for the relay. Hold it and
   their sector claim dies") would do what the legend's flee rule
   already does for mechanics. Fix: an enemy-want line on the
   battle intro card, written per faction from the outlines' own
   wants table.

4. Two admiral name registers collide in the same fleet. The player
   admiral is "Admiral Roderic Vex" in both runs, the nemesis is
   "High Nadir Essvane" (seed 10) or "Line Admiral Konrad Steiner"
   (seed 121). Vex, Essvane, Steiner: three different naming
   languages (short invented, title-plus-invented, plain Germanic)
   with no visible rule for who gets which. The ship names are
   better (Vigilant Ash, Everwatch, Cold Reckoning, Bright Censure,
   Ashen Vigil, Dawn of Cinders are one voice). Fix: a one-line
   naming rule in the story README (which register belongs to which
   faction and rank), then a pass over the 24 admiral names to fit
   it. The data supports it; the pattern just is not stated.

5. The defeat line is the best writing in the pack, and it exposes
   the victory screen by comparison. Defeat (seed121 t040): "The
   line is broken. Add my name to the wall, under the others."
   Victory (seed10 t022) leads with bookkeeping ("3 enemy ships
   destroyed in 7 rounds. +44 credits") and keeps its one great
   line (the lifepod captain) in a ticker at the bottom edge where
   it can be missed. Fix: promote one fiction line into the victory
   card body, the way defeat already does. The material exists in
   the voice pools; it is placement, not writing.

6. "Cores", "signals" and "protocols" are load-bearing fiction
   terms that the fiction never introduces. The aspect screen's
   cores line (seed10 t001) assumes all three. In the outlines the
   rival system is the game's memory engine and its best original
   idea; in the game it arrives as unexplained vocabulary at the
   first decision screen. Fix: the rival's first calling card (the
   data exists, outlines.md Table A) should precede or accompany
   the first mention of cores, so the term lands attached to a
   person, not a list.

7. Tone holds. One voice throughout the visible text: terse,
   naval, unsentimental, no quips. The Chorus discipline from the
   earlier review (short lines, no song vocabulary in prose) is
   intact in the current outlines. Recorded as a finding because
   councils should say what not to touch: do not let later content
   passes loosen this.

## Good, keep

- The title tagline. "Every hull you lose stays lost, and so does
  its captain" is the whole game in one sentence, and the victory
  screen's lifepod line pays it off mechanically.
- The nemesis dossier with a hunt clock on the sector map: the
  rival is present as a promise from the first map, which is
  exactly how a memory system should be advertised.
- Captain consequences with names: promotions, experience and the
  wounded captain taking the next hull give the roster a memory
  the player can feel without a cutscene.
- The six wants table in outlines.md. Six genuinely different
  objects of desire; the setting's spine is sound.
- Ship naming. One register, evocative, no franchise echoes.
